import 'dart:async';

import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/story_logger.dart';
import '../core/episode_play_handoff.dart';
import '../core/result.dart';
import '../core/story_constants.dart';
import '../core/story_dns_preheater.dart';
import '../core/video_url_helpers.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../routes/route_args.dart';
import '../services/native_video_player_coordinator.dart';
import '../services/cloudfront_cookie_service.dart';
import '../services/playback_frame_cache_service.dart';
import '../repositories/drama_repository.dart';
import '../data/repository/story_local_repository.dart';
import 'engagement_state.dart';
import 'engagement_controller.dart';
import 'engagement_sync.dart';
import 'follow_status_store.dart';
import 'playback_engine.dart';
import 'playback_engine_listener.dart';
import 'video_feed_state.dart';
import 'feed_playback_mirror.dart';
import 'feed_persist_policy.dart';
import 'feed_overlay_hold.dart';
import 'feed_activate_telemetry_session.dart';
import 'feed_episode_metrics_session.dart';
import 'feed_slot.dart';
import 'feed_slot_coordinator.dart';
import 'feed_prefetch_orchestrator.dart';
import 'feed_recovery_engine.dart';
import 'feed_tracking_service.dart';
import 'playback_episode_metrics_tracker.dart';
import 'feed_playback_policy.dart';
import 'watch_history_reporter.dart';

export 'video_feed_state.dart'
    show FeedPlaybackStatus, FeedEpisodeState, ForegroundResumeStrategy;

part 'feed_activation_pipeline.dart';
part 'feed_recovery.dart';
part 'feed_native_preload_orchestrator.dart';
part 'feed_episode_data_resolver.dart';
part 'feed_engagement_manager.dart';
part 'feed_playback_lifecycle.dart';

/// TikTok 风格视频信息流控制器
///
/// 保留 feed 专属 UX：generation token、防滑动竞态、预取下一集、自动进集、后台前台。
/// 通用播放生命周期由 [PlaybackEngine] 负责。
/// 剧集激活策略见 [FeedActivationPipeline]（`feed_activation_pipeline.dart`）。
class VideoFeedController extends Notifier<VideoFeedState>
    implements PlaybackEngineListener {
  VideoFeedController(this._args);

  final VideoFeedArgs _args;

  late final FeedPrefetchOrchestrator _prefetch;
  late final FeedTrackingService _tracking;
  final List<PlaybackEngine?> _engines = List.filled(3, null);
  bool _servicesReady = false;

  /// Triple-slot bookkeeping (episode↔slot map + selection heuristics).
  late final FeedSlotCoordinator _slot = FeedSlotCoordinator(
    _engineForSlotOrNull,
  );

  int get _activeEngineIndex => _slot.activeEngineIndex;
  set _activeEngineIndex(int v) => _slot.activeEngineIndex = v;
  List<FeedSlot> get _slots => _slot.slots;

  Set<int> get preloadedEpisodeNos => _slot.preloadedEpisodeNos;

  /// Episodes whose engines have painted a first frame (early-activate gate).
  Set<int> get frameReadyEpisodeNos =>
      _cachedFrameReadyEpisodeNos ?? const {};

  /// Episodes with a settled preload (load finished, play identity holds) —
  /// semi-open early-activate may start before the first painted frame.
  Set<int> get settledPreloadEpisodeNos {
    final out = <int>{};
    for (final entry in _slot.episodeToSlot.entries) {
      final ep = entry.key;
      final engine = _engineForSlotOrNull(entry.value);
      if (engine == null) continue;
      if (engine.currentEpisodeNo != ep) continue;
      if (engine.currentPlay == null) continue;
      if (engine.hasPendingLoad) continue;
      out.add(ep);
    }
    return out;
  }

  Set<int> get _nativePreloadInFlightEpisodeNos =>
      _slot.nativePreloadInFlightEpisodeNos;

  /// Shared work identity. Standalone short videos are keyed by episode id.
  String get _dramaId => _args.workId;
  int get initialEpisodeNo => _args.episodeNo;
  int get totalEpisodes => _args.totalEpisodes;

  Future<Result<DramaPlayResponse>> _loadEpisodePlay(int episodeNo) {
    if (_args.isShortVideo) {
      return _dramaRepo.getEpisodeDetailByEpisodeId(_args.episodeId!);
    }
    return _dramaRepo.getEpisodeDetail(_args.dramaId, episodeNo);
  }

  /// Returns the currently active engine (the one visible to the user).
  PlaybackEngine get _engine {
    if (!_alive) _throwDisposed();
    _ensureServices();
    return _engineForSlot(_activeEngineIndex);
  }

  PlaybackEngine? _engineForSlotOrNull(int slot) {
    if (_disposed || !_servicesReady || slot < 0 || slot >= 3) return null;
    return _engines[slot];
  }

  PlaybackEngine _engineForSlot(int slot) {
    final existing = _engineForSlotOrNull(slot);
    if (existing != null) return existing;
    if (!_alive) _throwDisposed();
    _ensureServices();
    final created = _engineForSlotOrNull(slot);
    if (created == null) {
      throw StateError('VideoFeedController engine slot $slot unavailable');
    }
    return created;
  }

  Iterable<int> get _inactiveSlots => _slot.inactiveSlots;

  Never _throwDisposed() {
    throw StateError('VideoFeedController is disposed');
  }

  // ─── Repository accessors (for same-library extensions) ──────────
  DramaRepository get _dramaRepo => ref.read(dramaRepositoryProvider);
  StoryLocalRepository get _localRepo => ref.read(localRepositoryProvider);

  // ─── Engagement accessors (for same-library extensions) ──────────
  EpisodeEngagementController _episodeEngagementNotifier(
    EpisodeEngagementKey key,
  ) => ref.read(episodeEngagementProvider(key).notifier);

  EpisodeEngagementState _episodeEngagement(EpisodeEngagementKey key) =>
      ref.read(episodeEngagementProvider(key));

  /// Stale-while-revalidate detail fetch: render the cached detail
  /// immediately, then replace it with a force-refreshed server copy so
  /// counters (favoriteCount, avgRating) are current when entering the
  /// player straight from a list.
  Future<void> fetchDramaDetail() async {
    if (!_canContinue()) return;
    if (_args.isShortVideo) return;
    final repo = _dramaRepo;

    final cached = await repo.peekDetail(dramaId);
    if (cached != null && _alive) {
      _dramaDetail = cached;
      _notify();
    }
    if (!_canContinue()) return;

    // Cache miss → plain fetch (network anyway); hit → force refresh.
    final result = await repo.getDetail(dramaId, forceRefresh: cached != null);
    if (result.isSuccess && _alive) {
      _dramaDetail = result.dataOrNull;
      StoryLogger.d(
        'dramaDetail loaded: title=${_dramaDetail?.title} '
        'rolesCount=${_dramaDetail?.roles?.length} '
        'descLen=${_dramaDetail?.description?.length ?? -1}',
        tag: 'Feed',
      );
      final detail = _dramaDetail;
      if (detail != null) {
        // Push fresh counters into the shared store — a retained store from
        // a previous detail-page visit may still hold stale seeded values.
        ref
            .read(dramaEngagementProvider(dramaId).notifier)
            .applyServer(
              favoritedByMe: detail.favoritedByMe,
              favoriteCount: detail.favoriteCount,
              avgRating: detail.avgRating,
            );
      }
      _notify();
    } else if (result.isFailure) {
      StoryLogger.w(
        'dramaDetail fetch failed: ${result.errorOrNull}',
        tag: 'Feed',
      );
    }
  }

  void _ensureServices() {
    if (!_canContinue()) return;
    if (_servicesReady) return;
    _servicesReady = true;
    final dramaRepo = ref.read(dramaRepositoryProvider);
    final localRepo = ref.read(localRepositoryProvider);
    final cloudfront = ref.read(cloudfrontCookieServiceProvider);
    final episodeLoader = _args.isShortVideo ? _loadEpisodePlay : null;
    _tracking = FeedTrackingService(ref);
    _prefetch = FeedPrefetchOrchestrator(
      ref: ref,
      dramaId: _dramaId,
      totalEpisodes: totalEpisodes,
      onPrefetchStarted: (epNo) {
        if (!_canContinue()) return;
        _episodeStates[epNo] = const FeedEpisodeState(isPrefetching: true);
        _episodeStatesDirty = true;
        _episodeErrorsDirty = true;
      },
      onPrefetchSuccess: (epNo, play) {
        if (!_canContinue()) return;
        _episodeStates[epNo] = FeedEpisodeState(play: play);
        _ingestEpisodeCover(
          epNo,
          play.posterUrl,
          coverOnlyUrl: play.coverUrl,
        );
        _prefetchedEpisodeNos.add(epNo);
        _episodeStatesDirty = true;
        _setsDirty = true;
        _episodeErrorsDirty = true;
        _notify();
      },
      onPrefetchError: (epNo, error) {
        if (!_canContinue()) return;
        final errorString = error is String ? error : error.toString();
        _episodeStates[epNo] = FeedEpisodeState(error: errorString);
        _episodeStatesDirty = true;
        _episodeErrorsDirty = true;
        _notify();
      },
    );
    _engines[0] = PlaybackEngine(
      dramaRepo: dramaRepo,
      localRepo: localRepo,
      cloudfront: cloudfront,
      dramaId: _dramaId,
      tag: 'Feed.A',
      restoreWatchProgress: false,
      episodeLoader: episodeLoader,
      isCellular: () => ref.read(connectivityProvider).isCellular,
    );
    _engines[1] = PlaybackEngine(
      dramaRepo: dramaRepo,
      localRepo: localRepo,
      cloudfront: cloudfront,
      dramaId: _dramaId,
      tag: 'Feed.B',
      restoreWatchProgress: false,
      coordinator: NativeVideoPlayerCoordinator.feedPreloadInstance,
      episodeLoader: episodeLoader,
      isCellular: () => ref.read(connectivityProvider).isCellular,
    );
    _engines[2] = PlaybackEngine(
      dramaRepo: dramaRepo,
      localRepo: localRepo,
      cloudfront: cloudfront,
      dramaId: _dramaId,
      tag: 'Feed.C',
      restoreWatchProgress: false,
      coordinator: NativeVideoPlayerCoordinator.feedNextPreloadInstance,
      episodeLoader: episodeLoader,
      isCellular: () => ref.read(connectivityProvider).isCellular,
    );
    _wireEngineCallbacks();
    for (var i = 0; i < 3; i++) {
      final ctrl = _controllers[i];
      if (ctrl != null) _engines[i]!.initialize(ctrl);
    }
    _syncLooping();
  }

  @override
  VideoFeedState build() {
    final watchHistory = ref.read(watchHistoryBatchReporterProvider.notifier);
    ref.onDispose(() {
      unawaited(watchHistory.flush());
      dispose();
    });
    // Seed on provider creation so the first overlay frame already has title /
    // synopsis (avoids "BottomInfo: drama is null" before attach/initialize).
    _currentEpisodeNo = initialEpisodeNo;
    _seedDramaDetailFromArgs();
    _seedEpisodeCoversFromArgs();
    seedRouteEngagement(initialEpisodeNo);
    return _pb.materialize(
      playedEpisodeNos: const {},
      prefetchedEpisodeNos: const {},
      episodePlays: const {},
      episodeCoverUrls: Map<int, String>.unmodifiable(_episodeCoverUrls),
      episodeErrors: const {},
      preloadedEpisodeNos: const {},
      frameReadyEpisodeNos: const {},
    );
  }

  /// Attach current, previous and next native controllers from the page.
  ///
  /// Call once in initState after creating the three [NativeVideoPlayerController]s.
  /// Does **not** start native bootstrap — platform views must be mounted first
  /// (see [startEagerInitialization]). Starting three concurrent
  /// `controller.initialize()` waits before the surfaces exist was hanging
  /// entry and freezing the UI when banner teardown overlapped.
  void attachTripleControllers(
    NativeVideoPlayerController primary,
    NativeVideoPlayerController previous,
    NativeVideoPlayerController next,
  ) {
    _controllers[0] = primary;
    _controllers[1] = previous;
    _controllers[2] = next;
    _ensureServices();
    _engines[0]!.initialize(primary);
    _engines[1]!.initialize(previous);
    _engines[2]!.initialize(next);
    // Overlay metadata is seeded in [build]; play payloads refresh in
    // [initialize] / [_markEpisodeReady].
    _notify();
  }

  /// Fill [dramaDetail] from route args / in-memory detail provider ASAP.
  void _seedDramaDetailFromArgs() {
    // Route args first — always available on the first frame.
    if (_dramaDetail == null) {
      final seedTitle = _args.title.trim();
      final seedDesc = _args.description?.trim();
      final seedCover = _args.coverUrl?.trim();
      final seedCreatorName = _args.creatorName?.trim();
      final seedCreatorUserId = _args.creatorUserId?.trim();
      final seedCreatorAvatar = _args.creatorAvatarUrl?.trim();
      final seedRoles = _args.roles;
      if (seedTitle.isNotEmpty ||
          (seedDesc != null && seedDesc.isNotEmpty) ||
          (seedCover != null && seedCover.isNotEmpty) ||
          (seedCreatorName != null && seedCreatorName.isNotEmpty) ||
          (seedCreatorUserId != null && seedCreatorUserId.isNotEmpty) ||
          (seedCreatorAvatar != null && seedCreatorAvatar.isNotEmpty) ||
          (seedRoles != null && seedRoles.isNotEmpty)) {
        _dramaDetail = DramaDetail(
          // Carry the work identity so `dramaDetail.id == dramaId` holds even
          // for the first-frame seed (short video: the episode/work id).
          id: _args.workId,
          title: seedTitle.isNotEmpty ? seedTitle : null,
          description: (seedDesc != null && seedDesc.isNotEmpty)
              ? seedDesc
              : null,
          coverUrl: (seedCover != null && seedCover.isNotEmpty)
              ? seedCover
              : null,
          creatorName: (seedCreatorName != null && seedCreatorName.isNotEmpty)
              ? seedCreatorName
              : null,
          userId: (seedCreatorUserId != null && seedCreatorUserId.isNotEmpty)
              ? seedCreatorUserId
              : null,
          creatorAvatarUrl:
              (seedCreatorAvatar != null && seedCreatorAvatar.isNotEmpty)
              ? seedCreatorAvatar
              : null,
          roles: seedRoles,
        );
      }
    }

    // Upgrade to the full detail-page cache when still alive underneath.
    if (_args.isShortVideo) return;
    try {
      final cached = ref.read(dramaDetailProvider(_dramaId)).asData?.value;
      final fromProvider = cached?.dataOrNull;
      if (fromProvider != null) {
        _dramaDetail = fromProvider;
        StoryLogger.d(
          'dramaDetail seeded from provider: title=${fromProvider.title}',
          tag: 'Feed',
        );
      }
    } catch (_) {
      // Provider may be disposed or unavailable.
    }
  }

  /// Seed follow chrome from route args for the initial episode only.
  void _seedRouteFollowStatus() {
    final creatorId = _args.creatorUserId?.trim();
    final followed = _args.followedByMe;
    if (creatorId == null ||
        creatorId.isEmpty ||
        followed == null ||
        !ref.read(authControllerProvider).isLoggedIn) {
      return;
    }
    ref
        .read(followStatusStoreProvider.notifier)
        .seedIfUnknown(creatorId, followed);
  }

  void _syncVisibleEpisodeEngagement(
    EpisodeEngagementKey key,
    VisibleEpisodeEngagement engagement, {
    DramaPlayResponse? authoritativePlay,
  }) {
    syncVisibleEpisodeEngagement(
      ref,
      key: key,
      engagement: engagement,
      authoritativePlay: authoritativePlay,
    );
  }

  /// Bootstrap native controllers after their platform views are in the tree.
  ///
  /// Call once views are mounted (page owns controllers from the first frame).
  /// Default: only the active slot, overlapping episode fetch so
  /// [PlaybackEngine.applyPlayback] can skip bootstrap. With [neighbors]
  /// true, also warm inactive slots after the first episode is live.
  ///
  /// Do **not** call before [NativeVideoPlayer] is in the tree —
  /// `controller.initialize()` has no internal timeout and will hang.
  void startEagerInitialization({bool neighbors = false}) {
    _unawaitedLogged(_engine.eagerInitialize(), reason: 'eager-init-active');
    if (!neighbors) return;
    for (final slot in _inactiveSlots) {
      _unawaitedLogged(
        _engineForSlot(slot).eagerInitialize(),
        reason: 'eager-init-neighbor-$slot',
      );
    }
  }

  // ─── 原生播放器控制器 ────────────────────────────────────────
  final List<NativeVideoPlayerController?> _controllers = List.filled(3, null);

  /// The native controller of the currently active engine.
  NativeVideoPlayerController? get nativeController =>
      _controllers[_activeEngineIndex];

  NativeVideoPlayerController? _controllerForSlot(int slot) {
    if (slot < 0 || slot >= 3) return null;
    return _controllers[slot];
  }

  /// The native controller of the active engine (same as [nativeController]).
  NativeVideoPlayerController? get activeNativeController => nativeController;

  /// Controllers and episode identities currently mounted by the three slots.
  List<({NativeVideoPlayerController controller, int episodeNo})>
  get nativePlayerSurfaces {
    final surfaces =
        <({NativeVideoPlayerController controller, int episodeNo})>[];
    for (var slot = 0; slot < 3; slot++) {
      final controller = _controllerForSlot(slot);
      if (controller == null) continue;
      // O(1) slot→episode lookup (was O(n) entries.where().map().toList()).
      final mappedEpisode = _slot.episodeForSlot(slot);
      // Active slot: prefer the engine's decoded episode. During preload-swap
      // `_loadedEpisodeNo` lags until migrate finishes — using it alone parks
      // the playing surface off-screen (audio+progress, frozen frame).
      final episodeNo = slot == _activeEngineIndex
          ? (_engineForSlot(slot).currentEpisodeNo ??
                _loadedEpisodeNo ??
                (_currentEpisodeNo > 0 ? _currentEpisodeNo : initialEpisodeNo))
          : (mappedEpisode ??
                _engineForSlot(slot).currentEpisodeNo ??
                // Keep an unassigned platform view mounted far off-screen so
                // eager native initialization can still receive view-ready.
                -(slot + 1));
      surfaces.add((controller: controller, episodeNo: episodeNo));
    }
    return surfaces;
  }

  // ─── UI playback mirror（_notify 一次 materialize）──────────
  final FeedPlaybackMirror _pb = FeedPlaybackMirror();

  // Aliases keep call sites readable while `_notify` syncs via [_pb].
  int get _currentEpisodeNo => _pb.currentEpisodeNo;
  set _currentEpisodeNo(int v) => _pb.currentEpisodeNo = v;
  int? get _loadedEpisodeNo => _pb.loadedEpisodeNo;
  set _loadedEpisodeNo(int? v) => _pb.loadedEpisodeNo = v;
  FeedPlaybackStatus get _status => _pb.status;
  set _status(FeedPlaybackStatus v) => _pb.status = v;
  bool get _isPlaying => _pb.isPlaying;
  set _isPlaying(bool v) => _pb.isPlaying = v;
  bool get _isUserPaused => _pb.isUserPaused;
  set _isUserPaused(bool v) => _pb.isUserPaused = v;
  Duration get _position => _pb.position;
  set _position(Duration v) => _pb.position = v;
  Duration get _duration => _pb.duration;
  set _duration(Duration v) => _pb.duration = v;
  DramaPlayResponse? get _currentPlay => _pb.currentPlay;
  set _currentPlay(DramaPlayResponse? v) => _pb.currentPlay = v;
  DramaDetail? get _dramaDetail => _pb.dramaDetail;
  set _dramaDetail(DramaDetail? v) => _pb.dramaDetail = v;
  Object? get _error => _pb.error;
  set _error(Object? v) => _pb.error = v;
  int? get _autoAdvanceToEpisodeNo => _pb.autoAdvanceToEpisodeNo;
  set _autoAdvanceToEpisodeNo(int? v) => _pb.autoAdvanceToEpisodeNo = v;
  bool get _playerSurfaceVisible => _pb.playerSurfaceVisible;
  set _playerSurfaceVisible(bool v) => _pb.playerSurfaceVisible = v;

  /// Leaf chrome listenables — overlays rebuild on pause without PageView.
  final ValueNotifier<bool> playingListenable = ValueNotifier<bool>(false);
  final ValueNotifier<bool> userPausedListenable = ValueNotifier<bool>(false);

  /// Drama-scoped favorite. Episode payloads often omit / reset
  /// [DramaPlayResponse.favoritedByMe] on swipe.

  // ─── Generation token（防止过期异步操作） ──────────────────────
  int _switchGeneration = 0;

  // ─── Recovery and lifecycle state (used by FeedRecovery extension) ─
  AuthRecoveryPhase _authPhase = AuthRecoveryPhase.idle;
  Future<void>? _pendingAuthRecovery;
  DateTime? _lastFrameRenderedAt;
  int? _lastFrameEpisode;
  bool _wasPlayingBeforeBackground = false;

  /// Shared unexpected-pause / frame-stall recovery choreography. Attempt
  /// budgets and the decision flow live in [FeedRecoveryEngine]; this
  /// controller only supplies the state + actions via [_VideoFeedRecoveryHost].
  late final FeedRecoveryEngine _recovery = FeedRecoveryEngine(
    _VideoFeedRecoveryHost(this),
  );

  /// Soft-resume started at — frame-stall recovery is suppressed briefly so
  /// it does not race foreground play into a double force-reactivate.
  DateTime? _foregroundResumeAt;

  /// When the feed last entered a suspended state (app background or route
  /// cover). Used to pick brief / soft / force resume strategies.
  DateTime? _suspendedAt;

  /// In-flight suspend pause — foreground resume awaits this so a late
  /// native pause cannot stop a just-resumed player.
  Future<void>? _suspendInFlight;

  /// Bumped on every suspend so in-flight soft-resume work is abandoned.
  int _lifecycleGeneration = 0;

  /// Native emitted a fatal error while we were not visible (typical iOS
  /// "The network connection was lost" after backgrounding). Soft play cannot
  /// recover — force-reactivate on the next reveal.
  bool _needsForegroundReload = false;

  /// True while a push route covers the feed. Survives app background so
  /// [onAppForeground] does not resume audio under the covering page.
  bool _routeCovered = false;

  /// Feed visibility — set by lifecycle callbacks and activation pipeline.
  FeedVisibility _visibility = FeedVisibility.active;

  /// Episode already disk-warmed via mid-playback progress trigger.
  int? _progressWarmedNextEpisode;

  // ─── 预加载缓存 ──────────────────────────────────────────────
  final Map<int, FeedEpisodeState> _episodeStates = {};
  final Map<int, String> _episodeCoverUrls = {};
  final Set<int> _playedEpisodeNos = {};
  final Set<int> _prefetchedEpisodeNos = {};

  /// Episodes whose engagement counters were server-refreshed this session.
  /// The 24h episode-play cache serves stale like/comment counts; each
  /// episode is hydrated once when it first becomes live.
  final Set<int> _engagementHydratedEpisodeNos = {};

  // ─── 缓存的不可变集合（避免每次 _notify 重建） ──────────────
  Map<int, DramaPlayResponse>? _cachedEpisodePlays;
  Map<int, String>? _cachedEpisodeCoverUrls;
  Set<int>? _cachedPlayedEpisodeNos;
  Set<int>? _cachedPrefetchedEpisodeNos;
  Set<int>? _cachedFrameReadyEpisodeNos;
  Map<int, Object>? _cachedEpisodeErrors;
  bool _episodeStatesDirty = true;
  bool _setsDirty = true;
  bool _episodeErrorsDirty = true;

  // ─── 有效播放 / 完播 metrics（每集单次会话内去重） ─────────────
  final FeedEpisodeMetricsSession _episodeMetrics =
      FeedEpisodeMetricsSession();
  final FeedWatchHistoryGate _watchHistoryGate = FeedWatchHistoryGate();

  final FeedActivateTelemetrySession _activateTelemetry =
      FeedActivateTelemetrySession(feed: 'drama');

  void _beginFeedActivateTelemetry(int episodeNo, {String? episodeId}) {
    _activateTelemetry.begin(
      PlaybackFrameCacheService.frameCacheKey(
        dramaId: _dramaId,
        episodeId: episodeId,
        episodeNo: episodeNo,
      ),
    );
  }

  void _reportFeedActivateTelemetry({required bool fromNeighbor}) {
    _activateTelemetry.reportActivate(fromNeighbor: fromNeighbor);
  }

  void _reportFeedFirstFrameTelemetry(int episodeNo, {String? episodeId}) {
    _activateTelemetry.reportFirstFrame(
      fallbackPlaybackId: PlaybackFrameCacheService.frameCacheKey(
        dramaId: _dramaId,
        episodeId: episodeId,
        episodeNo: episodeNo,
      ),
    );
  }

  void _reportCurrentEpisodeWatchHistory(String episodeId) {
    reportWatchHistory(ref, episodeId, EpisodeTrackEvent.play);
  }

  /// Records [url] for [episodeNo] when non-empty. Returns true if the map changed.
  ///
  /// When [coverOnlyUrl] is set (play/list cover without a first frame), do not
  /// replace a different already-seeded poster — list entry firstFrameUrl is
  /// already in the image cache and must win over cover-only detail.
  bool _ingestEpisodeCover(
    int episodeNo,
    String? url, {
    String? coverOnlyUrl,
  }) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return false;
    final existing = _episodeCoverUrls[episodeNo];
    if (!VideoUrlHelpers.shouldReplaceEpisodePoster(
      existing: existing,
      candidate: trimmed,
      coverOnlyUrl: coverOnlyUrl,
    )) {
      return false;
    }
    _episodeCoverUrls[episodeNo] = trimmed;
    return true;
  }

  void _seedEpisodeCoversFromArgs() {
    final initialCover = _args.episodeCoverUrl?.trim();
    if (initialCover != null && initialCover.isNotEmpty) {
      _ingestEpisodeCover(_args.episodeNo, initialCover);
    }
  }

  /// Load public episode-list posters for swipe transitions (best-effort).
  void _prefetchEpisodeListCovers() {
    if (_args.isShortVideo) return;
    unawaited(() async {
      try {
        final result = await ref
            .read(dramaRepositoryProvider)
            .listEpisodes(_dramaId);
        if (!_alive) return;
        result.when(
          success: (page) {
            var changed = false;
            for (final item in page.list ?? const <DramaEpisodeListItem>[]) {
              final epNo = item.episodeNo;
              if (epNo == null || epNo < 1) continue;
              if (_ingestEpisodeCover(
                epNo,
                item.posterUrl,
                coverOnlyUrl: item.coverUrl,
              )) {
                changed = true;
              }
            }
            if (changed && _alive) _notify();
          },
          failure: (_) {},
        );
      } catch (e) {
        StoryLogger.d('Episode cover prefetch failed', error: e, tag: 'Feed');
      }
    }());
  }

  bool _disposed = false;
  bool get disposed => _disposed;

  /// True while this controller may still schedule work.
  bool get _alive => !_disposed;

  /// Unified dispose / generation / custom-predicate guard (mirrors
  /// [PlaybackEngine._canContinue]).
  bool _canContinue([bool Function()? shouldContinue]) {
    if (_disposed) return false;
    return shouldContinue == null || shouldContinue();
  }

  /// Fire-and-forget with a debug log so non-critical races stay visible.
  void _unawaitedLogged(Future<void> future, {required String reason}) {
    StoryLogger.d('unawaited: $reason', tag: 'Feed');
    unawaited(() async {
      try {
        await future;
      } catch (e) {
        if (!_alive) return;
        StoryLogger.w('unawaited failed ($reason)', error: e, tag: 'Feed');
      }
    }());
  }

  // ─── 位置通知器 ──────────────────────────────────────────────
  ValueNotifier<Duration> get positionNotifier => _engine.positionNotifier;

  /// 选集器跳转：与滑动切集共用 [_activateEpisode]。
  Future<void> selectEpisode(int episodeNo) =>
      _enqueueActivate(episodeNo, reason: 'picker');

  /// Latest-wins activate queue — coalesces rapid swipes / picker taps so
  /// only the newest target runs after the current switch settles.
  int? _queuedActivateEpisode;
  String? _queuedActivateReason;
  bool _activateRunning = false;

  /// Caps deferred adjacent retries so a wedged neighbor cannot loop forever.
  int _adjacentRetryCount = 0;
  int? _adjacentRetryEpisode;

  /// Settles the active decoder briefly before neighbor loadUrl — overlapping
  /// a second AVPlayer/ExoPlayer load right after migrateToActive play is a
  /// common frozen-video + continuing-audio failure mode.
  Timer? _adjacentPreloadSettleTimer;

  /// True after [onPagerTargetEpisode] ducked the playing engine so we only
  /// restore once on swipe-cancel (not on every scroll tick).
  bool _volumeDucked = false;

  // Activation queue / swap / cold: see FeedActivationPipeline extension
  // in feed_activation_pipeline.dart

  /// Mute + pause every engine that is not decoding [episodeNo].
  ///
  /// Mute runs before pause so audio stops even when pause is slow.
  Future<void> silenceExceptEpisode(int episodeNo) async {
    if (!_canContinue()) return;

    // Fast path: skip list allocation + Future.wait when all other engines
    // are already silent (currentEpisodeNo has already moved elsewhere).
    var needsWork = false;
    for (var slot = 0; slot < 3; slot++) {
      if (_engineForSlot(slot).currentEpisodeNo != episodeNo) {
        needsWork = true;
        break;
      }
    }
    if (!needsWork) return;

    final futures = <Future<void>>[];
    for (var slot = 0; slot < 3; slot++) {
      final engine = _engineForSlot(slot);
      if (engine.currentEpisodeNo == episodeNo) continue;
      futures.add(() async {
        await engine.setVolume(0.0);
        // Skip the native pause() call when the engine is already paused —
        // avoids an unnecessary MethodChannel round-trip on rapid swipes.
        if (engine.isPlaying) {
          await engine.pause();
        }
      }());
    }
    if (futures.isEmpty) return;
    await Future.wait(futures);
  }

  /// Mute + pause every slot except [keepSlot].
  ///
  /// Prefer this over [silenceExceptEpisode] on preload-swap: the target
  /// slot must never be paused even if episode bookkeeping briefly lags.
  Future<void> silenceExceptSlot(int keepSlot) async {
    if (!_canContinue()) return;
    final futures = <Future<void>>[];
    for (var slot = 0; slot < 3; slot++) {
      if (slot == keepSlot) continue;
      final engine = _engineForSlot(slot);
      futures.add(() async {
        await engine.setVolume(0.0);
        // Skip the native pause() call when the engine is already paused.
        if (engine.isPlaying) {
          await engine.pause();
        }
      }());
    }
    if (futures.isEmpty) return;
    await Future.wait(futures);
  }

  /// Mute outgoing audio as soon as the pager leaves the playing episode.
  ///
  /// Only [setVolume] — never pause here. pause-then-later-migrate seek/play
  /// is a frozen-video failure mode when the user swipes back to that slot.
  void onPagerTargetEpisode(int targetEpisode) {
    if (!_canContinue(() => targetEpisode >= 1)) return;
    final playing = _loadedEpisodeNo ?? _currentEpisodeNo;
    if (playing < 1) return;

    // Mid preload-swap: `_currentEpisodeNo` already rotated to the incoming
    // episode while `_loadedEpisodeNo` still points at the outgoing one.
    // Ducking `_engine` here would mute the *new* active slot (auto-advance
    // animateToPage races with migrateToActive) and leave playback silent.
    if (_loadedEpisodeNo != null && _currentEpisodeNo != _loadedEpisodeNo) {
      return;
    }

    // Incoming episode already owns the active identity — never duck it.
    if (targetEpisode == _currentEpisodeNo) {
      if (!_volumeDucked) return;
      if (_activateRunning || _isUserPaused) return;
      if (_status != FeedPlaybackStatus.ready || !_isPlaying) return;
      if (_loadedEpisodeNo != playing) return;
      _volumeDucked = false;
      _unawaitedLogged(() async {
        await _engine.setVolume(1.0);
        if (!_engine.isPlaying) {
          await _engine.resumeForFeed(FeedResumeStyle.waitForFrame);
        }
      }(), reason: 'pager-unduck-audio');
      return;
    }

    if (targetEpisode != playing) {
      if (_volumeDucked) return;
      _volumeDucked = true;
      // Mute the engine that still owns [playing], not whatever is currently
      // `_engine` (slot may have already rotated during auto-advance).
      final duckTarget = _engineForEpisode(playing) ?? _engine;
      _unawaitedLogged(duckTarget.setVolume(0.0), reason: 'pager-duck-audio');
      return;
    }
    // Swipe cancelled back onto the playing page before a new activate won.
    if (!_volumeDucked) return;
    if (_activateRunning || _isUserPaused) return;
    if (_status != FeedPlaybackStatus.ready || !_isPlaying) return;
    if (_loadedEpisodeNo != playing) return;
    _volumeDucked = false;
    _unawaitedLogged(() async {
      final unduckTarget = _engineForEpisode(playing) ?? _engine;
      await unduckTarget.setVolume(1.0);
      // Prefer volume restore only; resume if native actually paused.
      if (!unduckTarget.isPlaying) {
        await unduckTarget.resumeForFeed(FeedResumeStyle.waitForFrame);
      }
    }(), reason: 'pager-unduck-audio');
  }

  /// Engine currently bound to [episodeNo], if any.
  PlaybackEngine? _engineForEpisode(int episodeNo) {
    for (var slot = 0; slot < 3; slot++) {
      final engine = _engineForSlotOrNull(slot);
      if (engine?.currentEpisodeNo == episodeNo) return engine;
    }
    return null;
  }

  // ─── Getters ──────────────────────────────────────────────
  String get dramaId => _dramaId;
  WorkContentType get contentType => _args.contentType;
  bool get isShortVideo => _args.isShortVideo;
  int get currentEpisodeNo => _currentEpisodeNo;
  int? get loadedEpisodeNo => _loadedEpisodeNo;
  FeedPlaybackStatus get status => _status;
  bool get isPlaying => _isPlaying;
  bool get isUserPaused => _isUserPaused;

  /// When false, the current episode loops instead of auto-advancing.
  bool _autoPlayEnabled = true;
  bool get autoPlayEnabled => _autoPlayEnabled;
  set autoPlayEnabled(bool value) {
    if (_autoPlayEnabled == value) return;
    _autoPlayEnabled = value;
    _syncLooping();
    // Replay only when turning 连播 off at EOS. Enabling under an overlay
    // must not replay — that fights auto-advance after the sheet closes.
    if (!value &&
        !overlayHoldsAdvance &&
        _status == FeedPlaybackStatus.completed) {
      _unawaitedLogged(
        _replayFromStart(),
        reason: 'loop-after-disable-autoplay',
      );
    }
  }

  /// Comment / drama / character sheets: do not auto-advance underneath.
  final FeedOverlayHold _overlayHold = FeedOverlayHold();
  bool get overlayHoldsAdvance => _overlayHold.holdsAdvance;

  void beginOverlayHold() {
    _overlayHold.begin(
      onBegan: () {
        if (_autoAdvanceToEpisodeNo != null) consumeAutoAdvance();
      },
    );
  }

  void endOverlayHold({bool advanceIfCompleted = true}) {
    _overlayHold.end(
      advanceIfCompleted: advanceIfCompleted,
      onEnded: ({required bool advanceIfCompleted}) {
        _syncLooping();
        if (advanceIfCompleted &&
            _autoPlayEnabled &&
            _status == FeedPlaybackStatus.completed) {
          _requestAutoAdvanceFromCompleted();
        }
      },
    );
  }

  Future<T> holdAutoAdvance<T>(
    Future<T> Function() action, {
    bool advanceIfCompletedOnEnd = true,
  }) {
    return _overlayHold.run(
      action,
      onBegan: () {
        if (_autoAdvanceToEpisodeNo != null) consumeAutoAdvance();
      },
      onEnded: ({required bool advanceIfCompleted}) {
        _syncLooping();
        if (advanceIfCompleted &&
            _autoPlayEnabled &&
            _status == FeedPlaybackStatus.completed) {
          _requestAutoAdvanceFromCompleted();
        }
      },
      advanceIfCompletedOnEnd: advanceIfCompletedOnEnd,
    );
  }

  void _syncLooping() {
    // Short / unknown duration keeps native loop off so first-pass completed
    // fires immediately; Dart replay handles 连播-off repeat UX.
    for (final engine in _engines) {
      if (engine == null) continue;
      final looping = FeedPlaybackPolicy.shouldUseNativeLoop(
        autoPlayEnabled: _autoPlayEnabled,
        duration: engine.duration,
      );
      _unawaitedLogged(engine.setLooping(looping), reason: 'set-looping');
    }
  }

  void _requestAutoAdvanceFromCompleted() {
    final next = _currentEpisodeNo + 1;
    final allowIntraDramaAdvance =
        _args.searchPlaylist.isEmpty || _args.searchDramaPlaylist;
    if (!allowIntraDramaAdvance || next > totalEpisodes) return;
    maintainAdjacentNativePreloads();
    _autoAdvanceToEpisodeNo = next;
    _notify();
  }

  Future<void> _replayFromStart() async {
    if (_disposed) return;
    _status = FeedPlaybackStatus.ready;
    _isUserPaused = false;
    _notify();
    // Soft-decode emulator: EOS → seek(0) can leave the SurfaceView without
    // a buffer; reconnect before play so Dart-side loop is not a black tile.
    await _engine.ensureSurfaceConnected();
    if (_disposed) return;
    await _engine.seekTo(Duration.zero);
    if (_disposed) return;
    final ok = await _engine.startPlayback();
    if (_disposed) return;
    _isPlaying = ok;
    if (ok) _episodeMetrics.onPlayStart();
    _status = FeedPlaybackStatus.ready;
    _notify();
  }

  Duration get position => _position;
  Duration get duration => _duration;
  DramaPlayResponse? get currentPlay => _currentPlay;

  /// Best-known play payload for [episodeNo] — memory cache first, then the
  /// active slot when it matches. Used by per-page chrome during fast swipes.
  DramaPlayResponse? playForEpisode(int episodeNo) {
    if (episodeNo < 1) return null;
    final cached = _episodeStates[episodeNo]?.play;
    if (cached != null) return cached;
    if (episodeNo == _currentEpisodeNo) return _currentPlay;
    return null;
  }

  DramaDetail? get dramaDetail => _dramaDetail;
  Object? get error => _error;
  int? get autoAdvanceToEpisodeNo => _autoAdvanceToEpisodeNo;
  int get episodeCount => totalEpisodes;
  bool get isLoading => _status == FeedPlaybackStatus.loading;

  /// True when the pager shows the same episode that is loaded and playback
  /// is ready — used as a gate by audio-duck, lifecycle resume, and preload
  /// scheduling to avoid acting on a stale or mid-transition surface.
  bool get _isActiveEpisodeReady =>
      _loadedEpisodeNo == _currentEpisodeNo &&
      _status == FeedPlaybackStatus.ready;

  /// Called before [initialize] when [EpisodePlayHandoff] already has play data
  /// (Theater banner → feed), so the UI can skip the cover-wait frame.
  void primeWarmStart(int episodeNo) {
    _playedEpisodeNos.add(episodeNo);
    _setsDirty = true;
    _currentEpisodeNo = episodeNo;
    _status = FeedPlaybackStatus.loading;
    _hidePlayerSurface();
    _notify();
  }

  void _hidePlayerSurface() {
    _playerSurfaceVisible = false;
  }

  /// Reset playback state fields shared by cold-path and preload-swap activate.
  void _resetPlaybackForEpisode(int episodeNo, {required bool playing}) {
    _position = Duration.zero;
    _duration = Duration.zero;
    _currentEpisodeNo = episodeNo;
    _lastFrameRenderedAt = null;
    _lastFrameEpisode = null;
    _recovery.resetBudgets();
    _progressWarmedNextEpisode = null;
    _resetEpisodeMetrics();
    _isPlaying = playing;
    _error = null;
    _autoAdvanceToEpisodeNo = null;
    _authPhase = AuthRecoveryPhase.idle;
  }

  void _revealPlayerSurface() {
    if (_playerSurfaceVisible) return;
    if (_loadedEpisodeNo != _currentEpisodeNo) return;
    _playerSurfaceVisible = true;
    if (_status == FeedPlaybackStatus.loading ||
        _status == FeedPlaybackStatus.buffering) {
      _status = FeedPlaybackStatus.ready;
    }
    _notify();
  }

  /// 安全通知 — UI 字段经 [FeedPlaybackMirror.materialize] 同步。
  void _notify() {
    if (!_canContinue()) return;

    // Only rebuild episodePlays when _episodeStates actually changes.
    if (_episodeStatesDirty) {
      final playsMap = <int, DramaPlayResponse>{};
      _episodeStates.forEach((epNo, epState) {
        if (epState.play != null) {
          playsMap[epNo] = epState.play!;
        }
      });
      _cachedEpisodePlays = Map<int, DramaPlayResponse>.unmodifiable(playsMap);
      _episodeStatesDirty = false;
    }

    _cachedEpisodeCoverUrls = Map<int, String>.unmodifiable(_episodeCoverUrls);

    if (_setsDirty) {
      _cachedPlayedEpisodeNos = Set<int>.unmodifiable(_playedEpisodeNos);
      _cachedPrefetchedEpisodeNos = Set<int>.unmodifiable(
        _prefetchedEpisodeNos,
      );
      _setsDirty = false;
    }

    _syncFrameReadyEpisodeNos();

    if (_episodeErrorsDirty) {
      _cachedEpisodeErrors = Map<int, Object>.unmodifiable(
        _episodeStates.entries
            .where((e) => e.value.error != null)
            .fold<Map<int, Object>>(
              <int, Object>{},
              (acc, e) => acc..[e.key] = e.value.error!,
            ),
      );
      _episodeErrorsDirty = false;
    }

    state = _pb.materialize(
      playedEpisodeNos: _cachedPlayedEpisodeNos ?? const {},
      prefetchedEpisodeNos: _cachedPrefetchedEpisodeNos ?? const {},
      episodePlays: _cachedEpisodePlays ?? const {},
      episodeCoverUrls:
          _cachedEpisodeCoverUrls ??
          Map<int, String>.unmodifiable(_episodeCoverUrls),
      episodeErrors: _cachedEpisodeErrors ?? const {},
      preloadedEpisodeNos: preloadedEpisodeNos,
      frameReadyEpisodeNos: _cachedFrameReadyEpisodeNos ?? const {},
    );
    if (playingListenable.value != _isPlaying) {
      playingListenable.value = _isPlaying;
    }
    if (userPausedListenable.value != _isUserPaused) {
      userPausedListenable.value = _isUserPaused;
    }
  }

  /// Rebuild the frame-ready set from live engines so neighbor covers only
  /// unmount after a real painted frame (not merely after loadUrl).
  void _syncFrameReadyEpisodeNos() {
    if (!_servicesReady) {
      _cachedFrameReadyEpisodeNos = const {};
      return;
    }
    final next = <int>{};
    for (var slot = 0; slot < 3; slot++) {
      final engine = _engineForSlot(slot);
      final ep = engine.currentEpisodeNo;
      if (ep != null && engine.hasPresentedFirstFrame) {
        next.add(ep);
      }
    }
    final cached = _cachedFrameReadyEpisodeNos;
    if (cached != null &&
        cached.length == next.length &&
        cached.containsAll(next)) {
      return;
    }
    _cachedFrameReadyEpisodeNos = Set<int>.unmodifiable(next);
  }

  /// Returns `true` when this controller is still alive and [engine] is still
  /// the active engine — used as the first-line guard in every engine callback.
  bool _isActiveEngine(PlaybackEngine engine) =>
      _canContinue(() => identical(engine, _engine));

  void _wireEngineCallbacks() {
    for (final engine in _engines) {
      if (engine != null) _wireOne(engine);
    }
  }

  void _wireOne(PlaybackEngine engine) {
    engine.listener = this;
  }

  @override
  void onEpisodeResult(
    PlaybackEngine engine,
    Result<DramaPlayResponse> result,
  ) {
    // VideoFeedController does not handle episode results directly.
  }

  @override
  void onActivityEvent(PlaybackEngine engine, PlayerActivityEvent event) {
    if (!_isActiveEngine(engine)) return;
    _handlePlayerActivity(event);
  }

  @override
  void onDurationChanged(PlaybackEngine engine, Duration duration) {
    _onEngineDurationChanged(engine, duration);
  }

  @override
  void onPlayingChanged(PlaybackEngine engine, bool isPlaying) {
    _onEnginePlayingChanged(engine, isPlaying);
  }

  @override
  void onBufferingChanged(PlaybackEngine engine, bool isBuffering) {
    _onEngineBufferingChanged(engine, isBuffering);
  }

  @override
  void onPositionUpdate(PlaybackEngine engine, int positionMs, int durationMs) {
    _onEnginePositionUpdate(engine, positionMs, durationMs);
  }

  @override
  void onFrameRendered(
    PlaybackEngine engine, {
    required bool isFirstFrame,
    required DateTime renderedAt,
  }) {
    if (!_canContinue()) return;
    _onEngineFrameRendered(
      engine,
      isFirstFrame: isFirstFrame,
      renderedAt: renderedAt,
    );
  }

  @override
  void onCompleted(PlaybackEngine engine) {
    if (!_isActiveEngine(engine)) return;
    handleCompletion();
  }

  @override
  void onPlaybackFailure(
    PlaybackEngine engine,
    Object error, {
    required bool isSwitch,
  }) {
    _onEnginePlaybackFailure(engine, error, isSwitch: isSwitch);
  }

  @override
  void onError(PlaybackEngine engine, Object error) {
    _onEngineError(engine, error);
  }

  void _onEngineDurationChanged(PlaybackEngine engine, Duration nextDuration) {
    if (!_isActiveEngine(engine)) return;
    _duration = nextDuration;
    _syncLooping();
    _notify();
  }

  void _onEnginePlayingChanged(PlaybackEngine engine, bool playing) {
    if (!_isActiveEngine(engine)) return;
    _isPlaying = playing;
    if (playing) {
      _episodeMetrics.onPlayStart();
      if (_status == FeedPlaybackStatus.buffering ||
          _status == FeedPlaybackStatus.loading) {
        _status = FeedPlaybackStatus.ready;
      }
    } else if (!engine.hasCompleted) {
      _episodeMetrics.onPause();
      _maybeRecoverUnexpectedPause();
    }
    _notify();
  }

  void _onEngineBufferingChanged(PlaybackEngine engine, bool isBuffering) {
    if (!_isActiveEngine(engine)) return;
    if (isBuffering) {
      // Native EOS seeks to 0 which briefly buffers. Do not clobber
      // [completed] or the center play affordance disappears on the
      // last episode.
      if (_status == FeedPlaybackStatus.error ||
          _status == FeedPlaybackStatus.buffering ||
          _status == FeedPlaybackStatus.completed) {
        return;
      }
      _status = FeedPlaybackStatus.buffering;
      _notify();
    } else if (_status == FeedPlaybackStatus.buffering) {
      // Keep paused for !isPlaying so mid-swipe activate gaps do not
      // flash the center play button (overlay ignores paused).
      _status = _isPlaying
          ? FeedPlaybackStatus.ready
          : FeedPlaybackStatus.paused;
      _notify();
    }
  }

  void _onEnginePositionUpdate(
    PlaybackEngine engine,
    int positionMs,
    int durationMs,
  ) {
    if (!_isActiveEngine(engine)) return;
    _position = Duration(milliseconds: positionMs);
    _maybeRecoverFrameStall(engine);
    // Soft resume may play without a fresh `playing` event after suspend.
    if (engine.isPlaying || _isPlaying) {
      _episodeMetrics.onPlayStart();
    }
    final metricsDurMs =
        durationMs > 0 ? durationMs : _duration.inMilliseconds;
    _onEpisodeMetricsTimeUpdate(positionMs, metricsDurMs);
    _maybeWatchTrack(positionMs);
    if (durationMs > 0) {
      final nextDuration = Duration(milliseconds: durationMs);
      if (_duration != nextDuration) {
        _duration = nextDuration;
        _notify();
      }
      maybeWarmNextFromProgress(positionMs, durationMs);
    }
  }

  void _onEngineFrameRendered(
    PlaybackEngine engine, {
    required bool isFirstFrame,
    required DateTime renderedAt,
  }) {
    if (!_canContinue()) return;
    final ep = engine.currentEpisodeNo;
    final isActiveEngine = identical(engine, _engine);
    if (isActiveEngine) {
      _lastFrameRenderedAt = renderedAt;
      _lastFrameEpisode = ep;
      _recovery.notifyFrameRendered();
      if (isFirstFrame && ep != null) {
        _reportFeedFirstFrameTelemetry(
          ep,
          episodeId: engine.currentPlay?.episodeId,
        );
      }
      if (_loadedEpisodeNo == _currentEpisodeNo || ep == _currentEpisodeNo) {
        _revealPlayerSurface();
        // Arm N±1 native preload off the first painted frame instead
        // of polling playhead — earlier warm window on slow starts.
        if (isFirstFrame && ep == _currentEpisodeNo) {
          _scheduleAdjacentNativePreloads();
        }
      }
      if (ep != null && engine.hasPresentedFirstFrame) {
        _captureEpisodeFrame(engine, ep);
      }
      return;
    }
    // Preload slot painted a frame — rebuild so neighbor covers
    // can unmount. Skip if this episode is already in the set.
    if (ep != null &&
        engine.hasPresentedFirstFrame &&
        !(_cachedFrameReadyEpisodeNos?.contains(ep) ?? false)) {
      _notify();
    }
    if (ep != null && engine.hasPresentedFirstFrame) {
      _captureEpisodeFrame(engine, ep);
    }
  }

  void _onEnginePlaybackFailure(
    PlaybackEngine engine,
    Object error, {
    required bool isSwitch,
  }) {
    if (!_isActiveEngine(engine)) return;
    StoryLogger.e(
      '播放失败 (重试耗尽) switch=$isSwitch '
      'url=${engine.playbackUrl ?? ''} '
      'drama=$dramaId ep=$_currentEpisodeNo '
      'reason=$error',
      error: error,
      tag: 'Feed',
    );
    // Wedged load / missing platform view are not cookie-auth failures —
    // refetching play metadata cannot unstick a hung native Completer.
    if (!_shouldAttemptStaleAuthRecovery(error)) {
      _status = FeedPlaybackStatus.error;
      _error = error;
      _notify();
      return;
    }
    _pendingAuthRecovery ??= _recoverFromStaleAuthOnce(isSwitch: isSwitch);
    _unawaitedLogged(_pendingAuthRecovery!, reason: 'stale-auth-recovery');
  }

  void _onEngineError(PlaybackEngine engine, Object error) {
    if (!_isActiveEngine(engine)) return;
    // Background / route-cover: iOS often reports "network connection
    // was lost" on every slot. Do not flip the UI to error — flag a
    // force-reload for the next reveal instead.
    if (_visibility != FeedVisibility.active) {
      _needsForegroundReload = true;
      StoryLogger.d(
        'suppressed player error while ${_visibility.name}: $error',
        tag: 'Feed',
      );
      return;
    }
    _status = FeedPlaybackStatus.error;
    _error = error;
    _notify();
  }

  void _handlePlayerActivity(PlayerActivityEvent event) {
    if (_loadedEpisodeNo != _currentEpisodeNo) return;
    switch (event.state) {
      case PlayerActivityState.playing:
      case PlayerActivityState.loaded:
        // A playing/loaded event does not prove the video surface painted a
        // frame. Visibility is committed by onFrameRendered.
        break;
      default:
        break;
    }
  }

  // ─── 初始化 ──────────────────────────────────────────────────

  /// 初始化控制器并加载首个剧集。
  /// VideoFeedPage 预创建 NativeVideoPlayerController，保持第一帧挂载模式。
  /// [warmStart] 为 true 时优先消费 [EpisodePlayHandoff] 缓存，跳过封面等待。
  Future<void> initialize({bool warmStart = false}) async {
    // Seed before any await — otherwise BottomInfo stays null while episode
    // metadata is still resolving and entry looks frozen.
    _seedDramaDetailFromArgs();
    _seedEpisodeCoversFromArgs();
    fetchDramaDetail();
    _prefetchEpisodeListCovers();
    _notify();

    final handoff = warmStart
        ? EpisodePlayHandoff.take(
            dramaId: _dramaId,
            episodeNo: initialEpisodeNo,
          )
        : null;
    final handoffPlay = handoff?.play;
    final startAt = handoff?.startAt ?? Duration.zero;
    final diskWarmed = handoff?.diskWarmed ?? false;

    if (handoffPlay != null) {
      _playedEpisodeNos.add(initialEpisodeNo);
      _setsDirty = true;
      _ingestEpisodeCover(
        initialEpisodeNo,
        handoffPlay.posterUrl,
        coverOnlyUrl: handoffPlay.coverUrl,
      );
      _episodeStates[initialEpisodeNo] = FeedEpisodeState(play: handoffPlay);
      _episodeStatesDirty = true;
      _currentEpisodeNo = initialEpisodeNo;
      setCurrentPlay(handoffPlay);
      _status = FeedPlaybackStatus.loading;
      _notify();
    }

    seedRouteEngagement(initialEpisodeNo);

    final fetched = handoffPlay != null
        ? _engine.episodeDataFromPlay(handoffPlay)
        : await resolveEpisodeDataCommon(initialEpisodeNo, forPreload: false);
    if (fetched == null) return;

    // Detect cache hit to use shorter view ready delay. When data is
    // already in Hive, the NativeVideoPlayer widget was rendered before
    // the async fetch, so the full 500ms waitForViewReady is unnecessary.
    bool dataCached = handoffPlay != null || diskWarmed;
    if (!dataCached && !_args.isShortVideo) {
      try {
        dataCached =
            await ref
                .read(dramaRepositoryProvider)
                .peekPrefetchedEpisode(_dramaId, initialEpisodeNo) !=
            null;
      } catch (e) {
        StoryLogger.d('Peek prefetched episode failed', error: e, tag: 'Feed');
      }
    }

    // The page pre-creates all three NativeVideoPlayerControllers and calls
    // attachTripleControllers before initialize(), so this should never be
    // null. Creating a detached controller here would hang initialize()
    // (its platform view never enters the tree), so bail instead.
    if (_controllers.any((c) => c == null)) {
      StoryLogger.e(
        'initialize aborted: native controller not attached',
        tag: 'Feed',
      );
      _status = FeedPlaybackStatus.error;
      _error = StateError('Native controller not attached');
      _notify();
      return;
    }

    _currentEpisodeNo = initialEpisodeNo;
    _status = FeedPlaybackStatus.loading;
    _hidePlayerSurface();
    _notify();

    _beginFeedActivateTelemetry(
      initialEpisodeNo,
      episodeId: handoffPlay?.episodeId ?? fetched.play.episodeId,
    );

    // Don't await detailFuture — drama detail loads in the background.
    // If it fails, _markEpisodeReady below retries, and subsequent
    // _activateEpisode calls also retry. Non-blocking ensures playback
    // starts even if the detail API is slow.
    //
    // No separate waitForViewReady needed — NativePlayerBootstrap.initialize
    // inside applyPlayback already waits for the view to be ready.

    // Prime adjacent metadata while the active player bootstraps. This gives
    // the inactive slot a warm metadata/cache hit as soon as the first episode
    // starts, instead of beginning all prefetch work after playback is ready.
    prefetchAdjacent(initialEpisodeNo);

    // Start cookie application early, overlapping with the frame settle +
    // bootstrap work in applyPlayback.
    final cookieFut = _engine.preApplyCookies(fetched.play, fetched.url);

    try {
      final ok = await _engine.applyPlayback(
        fetched.play,
        fetched.url,
        fetched.headers,
        isSwitch: false,
        episodeNo: initialEpisodeNo,
        startAt: warmStart ? startAt : null,
        viewReadyDelay: dataCached || warmStart || diskWarmed
            ? StoryDurations.playerViewReadyDelaySwitch
            : StoryDurations.playerViewReadyDelay,
        cookiePreApplied: cookieFut,
      );
      if (ok) {
        _markEpisodeReady(initialEpisodeNo, fetched.play);
        _reportFeedActivateTelemetry(fromNeighbor: warmStart || diskWarmed);
      } else {
        await _failActivationIfStillLoading(
          initialEpisodeNo,
          fallbackError: StateError('Playback failed to start'),
        );
      }
    } catch (e, st) {
      StoryLogger.e('播放器初始化失败', error: e, stackTrace: st, tag: 'Feed');
      _status = FeedPlaybackStatus.error;
      _error = e;
      _notify();
    }
  }

  // ─── 剧集切换 ──────────────────────────────────────────────

  Future<void> onSwipeToIndex(int index) async {
    await _enqueueActivate(index + 1, reason: 'swipe');
  }

  /// Drop a coalesced activate (e.g. fling past the current episode).
  void dropQueuedActivate() {
    _queuedActivateEpisode = null;
    _queuedActivateReason = null;
  }

  // _activateEpisode and related paths live in FeedActivationPipeline.

  void _captureEpisodeFrame(PlaybackEngine engine, int episodeNo) {
    // 捕获时 engine.currentPlay 已加载（onFrameRendered），优先用 episodeId
    // 生成与推荐流一致的 `dramaId:episodeId` key，跨入口共享首帧缓存。
    final episodeId = engine.currentPlay?.episodeId;
    unawaited(
      PlaybackFrameCacheService.instance.captureAndStore(
        engine: engine,
        playbackId: PlaybackFrameCacheService.frameCacheKey(
          dramaId: _dramaId,
          episodeId: episodeId,
          episodeNo: episodeNo,
        ),
      ),
    );
  }

  void _scheduleAdjacentNativePreloads() {
    _adjacentPreloadSettleTimer?.cancel();
    final episode = _currentEpisodeNo;
    void kick() {
      _adjacentPreloadSettleTimer = null;
      if (!_canContinue()) return;
      if (_currentEpisodeNo != episode) return;
      // Wait until the active episode has painted a frame. Overlapping
      // neighbor loadUrl right after migrateToActive freezes the visible
      // texture while audio continues — first-frame is a stronger gate than
      // playhead>=80ms and arms sooner when buffering delays position ticks.
      final hasFrameForCurrent = _lastFrameEpisode == episode;
      if (!_isPlaying ||
          _status != FeedPlaybackStatus.ready ||
          !hasFrameForCurrent ||
          _engine.isBuffering ||
          _engine.hasPendingLoad) {
        _adjacentPreloadSettleTimer = Timer(
          StoryDurations.adjacentPreloadFramePoll,
          kick,
        );
        return;
      }
      _adjacentPreloadSettleTimer = Timer(
        StoryDurations.adjacentPreloadAfterPlaying,
        () {
          _adjacentPreloadSettleTimer = null;
          if (!_canContinue() || _currentEpisodeNo != episode) return;
          maintainAdjacentNativePreloads();
        },
      );
    }

    kick();
  }

  /// Called while dragging. With three slots both directions normally remain
  /// ready; this only repairs a missing side after a fast picker jump.
  void ensurePreloadForScrollDirection({required bool preferForward}) {
    if (!_canContinue(() => _status != FeedPlaybackStatus.idle)) return;
    final current = _currentEpisodeNo;
    if (current < 1) return;
    final target = preferForward ? current + 1 : current - 1;
    if (target < 1 || target > totalEpisodes) return;
    startNativePreload(target);
  }

  // Moved to FeedNativePreloadOrchestrator extension

  void _removeStalePreloadEntries() => _slot.removeStalePreloadEntries();

  void _invalidateInactivePreloads({
    int? exceptEpisode,
    Set<int> exceptEpisodes = const {},
  }) {
    _slot.invalidateInactivePreloads(
      exceptEpisode: exceptEpisode,
      exceptEpisodes: exceptEpisodes,
    );
  }

  int? _choosePreloadSlot(int episodeNo, {bool force = false}) {
    return _slot.choosePreloadSlot(
      episodeNo,
      currentEpisodeNo: _currentEpisodeNo,
      force: force,
    );
  }

  // Moved to FeedNativePreloadOrchestrator extension

  // Moved to FeedEpisodeDataResolver extension

  void _markEpisodeReady(int episodeNo, DramaPlayResponse play) {
    // Session-played set drives UI cover-skip on cold revisit.
    _playedEpisodeNos.add(episodeNo);
    _prefetchedEpisodeNos.remove(episodeNo);
    _setsDirty = true;
    _ingestEpisodeCover(
      episodeNo,
      play.posterUrl,
      coverOnlyUrl: play.coverUrl,
    );
    _loadedEpisodeNo = episodeNo;
    setCurrentPlay(play);
    _authPhase = AuthRecoveryPhase.idle;
    // applyPlayback already issued play() — promote to ready immediately so
    // we don't flash a loading overlay over an already-live surface.
    // Keep cover until a painted frame (same gate as recommend).
    if (_status != FeedPlaybackStatus.error) {
      _status = FeedPlaybackStatus.ready;
      _isPlaying = true;
      if (_engine.hasPresentedFirstFrame) {
        _playerSurfaceVisible = true;
      }
    }
    _isUserPaused = false;
    _notify();
    // Prefetch already started in _activateEpisode; evict distant caches.
    evictDistantStates(episodeNo);
    // Neighbor loadUrl initializes inactive slots — do NOT also fire
    // eagerInitialize(neighbors) or both contend on the same coordinator
    // (acquire timeout → preload fail → swipe null-engine crash).
    _scheduleAdjacentNativePreloads();
    seedRouteEngagement(episodeNo);
    _hydrateEpisodeEngagement(episodeNo, play);
    StoryLogger.d('✅ 剧集 $episodeNo 加载完成', tag: 'Feed');
  }

  /// Server-refresh like/comment/favorite counters for [episodeNo] once per
  /// session. The 24h episode-play cache renders instantly (stale numbers);
  /// [EngagementHydrator] then overwrites the shared stores with fresh data,
  /// which the feed rail watches directly.
  void _hydrateEpisodeEngagement(int episodeNo, DramaPlayResponse play) {
    if (_args.isShortVideo) {
      final episodeId = play.episodeId?.trim() ?? '';
      if (episodeId.isEmpty) return;
      // The short-video detail endpoint is not backed by the episode-play
      // cache, so this payload is already authoritative. Push it into the
      // shared store; otherwise a retained value from another entry point can
      // win over this fresh response in the player rail.
      ref
          .read(
            episodeEngagementProvider(
              EpisodeEngagementKey.forEpisode(
                dramaId: dramaId,
                episodeId: episodeId,
                episodeNo: play.episodeNo,
              ),
            ).notifier,
          )
          .applyServer(
            likedByMe: play.likedByMe ?? false,
            likeCount: play.likeCount ?? 0,
            commentCount: play.commentCount ?? 0,
            favoritedByMe: play.favoritedByMe ?? false,
            favoriteCount: play.favoriteCount ?? 0,
          );
      return;
    }
    if (!_engagementHydratedEpisodeNos.add(episodeNo)) return;
    _unawaitedLogged(
      ref
          .read(engagementHydratorProvider)
          .hydrateEpisode(dramaId: dramaId, episodeNo: episodeNo),
      reason: 'hydrate-engagement-$episodeNo',
    );
  }

  // ─── 播放控制 ──────────────────────────────────────────────

  Future<void> togglePlayPause() async {
    // Suspend / route cover mutes to 0 and skips unmute while user-paused.
    // Force volume back before/after play so resume is never silent.
    if (!_engine.isPlaying) {
      await _engine.setVolume(1.0, force: true);
      final playing = await _engine.togglePlayPause();
      if (playing == null) return;
      _isPlaying = playing;
      _isUserPaused = !playing;
      if (playing) {
        await _engine.setVolume(1.0, force: true);
      }
      _notify();
      return;
    }

    // Pause: leave the native surface visible. Decoder / player layer already
    // holds the last frame — no JPEG freeze cover.
    _isPlaying = false;
    _isUserPaused = true;
    _notify();
    try {
      await _engine.pause();
    } catch (_) {}
    unawaited(persistWatchProgress());
  }

  Future<void> retry() async {
    _error = null;
    _status = FeedPlaybackStatus.idle;
    _loadedEpisodeNo = null;
    _authPhase = AuthRecoveryPhase.idle;
    _pendingAuthRecovery = null;
    // Force re-bootstrap after NO_VIEW / failed init — the platform view may
    // have been remounted while the engine still thinks it is initialized.
    for (final e in _engines) {
      e?.invalidateNativeInitialization();
    }
    _notify();
    // Route through the latest-wins queue so rapid retry + swipe cannot race.
    await _enqueueActivate(_currentEpisodeNo, reason: 'retry');
  }

  Future<void> seekTo(Duration position) async {
    await _engine.seekTo(position);
    _position = position;
    _notify();
  }

  // ─── 点赞/收藏 ──────────────────────────────────────────────
  //
  // Mutations go through the shared engagement store (single write path for
  // every page); the feed then mirrors the settled store state into its own
  // play payloads for playback bookkeeping.

  // Moved to FeedEngagementManager extension

  bool _isCurrentGeneration(int generation) {
    return _canContinue(() => generation == _switchGeneration);
  }
}

/// Session counters for activate-path mix (tune early-activate vs cold).
class FeedActivateMetrics {
  FeedActivateMetrics._();

  static int neighborSwap = 0;
  static int jump = 0;
  static int adjacentCold = 0;
  static int cold = 0;

  static void record(String path) {
    switch (path) {
      case 'preload-swap':
      case 'neighbor-swap':
        neighborSwap++;
      case 'jump-ready':
      case 'jump-preload':
        jump++;
      case 'adjacent-controlled-cold':
        adjacentCold++;
      case 'cold':
        cold++;
    }
    StoryLogger.i(
      'activate path=$path totals swap=$neighborSwap jump=$jump '
      'adjCold=$adjacentCold cold=$cold',
      tag: 'Feed',
    );
  }
}

/// Recovery host adapter for [VideoFeedController] — exposes the controller's
/// private playback state to the shared [FeedRecoveryEngine] without
/// polluting the controller's public API.
///
/// Pure-forward state getters ([FeedRecoveryHost.isPlaying] / [volumeDucked] /
/// [lastFrameRenderedAt]) are inherited from [FeedRecoveryHostForwarder];
/// everything below is video-feed-specific.
class _VideoFeedRecoveryHost
    with FeedRecoveryHostForwarder
    implements FeedRecoveryHostView {
  _VideoFeedRecoveryHost(this._c);

  final VideoFeedController _c;

  @override
  bool get hostIsPlaying => _c._isPlaying;

  @override
  bool get hostVolumeDucked => _c._volumeDucked;

  @override
  DateTime? get hostLastFrameRenderedAt => _c._lastFrameRenderedAt;

  @override
  bool aliveForGeneration(int generation) => _c._alive;

  @override
  bool get userPaused => _c._isUserPaused;

  @override
  bool get visible => _c._visibility == FeedVisibility.active;

  @override
  bool get activationRunning =>
      _c._activateRunning || _c._queuedActivateEpisode != null;

  @override
  bool get neighborLoadInFlight => _c._neighborNativeLoadInFlight;

  @override
  bool get promoteInFlight => false;

  @override
  bool get ended => false;

  @override
  bool get buffering => _c._engine.isBuffering;

  @override
  bool get playbackFailed => _c._status == FeedPlaybackStatus.error;

  @override
  String get boundIdentity {
    final ep = _c._loadedEpisodeNo;
    return ep == null ? '' : '$ep';
  }

  @override
  PlaybackEngine? get engine => _c._engine;

  @override
  bool isPlaybackArmActive() => false;

  @override
  bool get couldBeRecoverable {
    final ep = _c._loadedEpisodeNo;
    return _c._isActiveEpisodeReady &&
        ep != null &&
        _c._engine.currentEpisodeNo == ep;
  }

  @override
  bool get readyForResume {
    final ep = _c._loadedEpisodeNo;
    return ep != null &&
        _c._currentEpisodeNo == ep &&
        _c._engine.currentEpisodeNo == ep &&
        _c._status == FeedPlaybackStatus.ready &&
        !_c._engine.hasCompleted;
  }

  @override
  bool get readyForStallCheck {
    final ep = _c._loadedEpisodeNo;
    return ep != null &&
        ep == _c._currentEpisodeNo &&
        _c._engine.currentEpisodeNo == ep &&
        _c._lastFrameEpisode == ep &&
        _c._status == FeedPlaybackStatus.ready;
  }

  @override
  bool isWithinForegroundGrace() {
    final resumeAt = _c._foregroundResumeAt;
    return resumeAt != null &&
        DateTime.now().difference(resumeAt) < const Duration(seconds: 3);
  }

  @override
  void onGuardSkip() {}

  @override
  Future<bool> resumeActivePlayback() async {
    await _c._engine.setVolume(1.0, force: true);
    return _c._engine.resumeForFeed(FeedResumeStyle.waitForFrame);
  }

  @override
  Future<void> onResumeSucceeded() async {
    await _c._engine.setVolume(1.0, force: true);
    _c._isPlaying = true;
    _c._revealPlayerSurface();
    _c._notify();
  }

  @override
  Future<void> onFrameStallEscalate({required int attempt}) async {
    if (attempt == 1) {
      await _c._forceReactivateCurrent(reason: 'frame-stall');
      return;
    }
    _c._isPlaying = false;
    _c._status = FeedPlaybackStatus.error;
    _c._error = StateError('Video frames stopped rendering');
    _c._hidePlayerSurface();
    _c._notify();
  }

  @override
  void logWarning(String message) => StoryLogger.w(message, tag: 'Feed');

  @override
  void logDebug(String message) => StoryLogger.d(message, tag: 'Feed');
}
