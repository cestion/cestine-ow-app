import 'dart:async';

import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/player_long_press_menu.dart';
import '../../../components/common/story_toast.dart';
import '../../../controller/feed_engine_completion_handler.dart';
import '../../../controller/feed_page_scroll_handler.dart';
import '../../../controller/feed_scroll_activate_policy.dart';
import '../../../controller/feed_scroll_activate_snapshot.dart';
import '../../../controller/feed_playback_policy.dart';
import '../../../controller/feed_recovery_engine.dart';
import '../../../controller/playback_engine.dart';
import '../../../controller/playback_engine_listener.dart';
import '../../../controller/recommend_feed_controller.dart';
import '../../../controller/recommend_feed_state.dart';
import '../../../core/story_constants.dart';
import '../../../core/story_logger.dart';
import '../../../foundation/playback_auth_route_observer.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../provider/tab_index_provider.dart';
import '../../../services/cloudfront_cookie_service.dart';
import '../../../services/native_video_player_coordinator.dart';
import '../../../services/playback_frame_cache_service.dart';
import '../../../services/playback_wake_lock.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/auth_navigation.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/widgets.dart';
import '../../report_page.dart';
import '../drama_detail/drama_detail_sheet.dart';
import '../video_feed/video_feed_widgets.dart';
import 'recommend_recovery_host.dart';

import 'recommend_feed_frame_manager.dart';
import 'recommend_feed_page_item_chrome.dart';
import 'recommend_feed_sheets.dart';
import 'recommend_surface_coordinator.dart';
import '../../../controller/feed_slot.dart';
import '../../../controller/recommend_playback_session.dart';
import '../../../controller/recommend_bind_queue.dart';
import '../../../controller/recommend_activate_pipeline.dart';
import '../../../controller/feed_slot_preparer.dart';
import '../../../controller/feed_media_load.dart';
import '../../../controller/feed_slot_session.dart';
import '../../../controller/recommend_engine_bridge.dart';
import '../../../controller/feed_playback_telemetry.dart';
import '../../../foundation/playback_visibility.dart';
import '../../../foundation/navigator.dart';

/// Immersive vertical recommend feed embedded in the theater home tab.
class RecommendFeedBody extends ConsumerStatefulWidget {
  final bool isActive;
  final bool standalone;

  /// 搜索短剧列表传 false，仍保存本集毫秒进度，但不覆盖剧场续播集数。
  final bool persistDramaCursor;

  const RecommendFeedBody({
    super.key,
    required this.isActive,
    this.standalone = false,
    this.persistDramaCursor = true,
  });

  @override
  ConsumerState<RecommendFeedBody> createState() => _RecommendFeedBodyState();
}

class _RecommendFeedBodyState extends ConsumerState<RecommendFeedBody>
    with WidgetsBindingObserver, RouteAware
    implements
        RecommendFeedBodyState,
        RecommendActivateHost,
        FeedSlotPrepareHost,
        RecommendEngineEventSink {
  static int _playerIdNext = 9000;
  static int _nextPlayerId() => ++_playerIdNext;

  late final PageController _pageController;
  // Three stable slot objects (never aliased). Roles rotate by index, and
  // the Stack always paints A→B→C so keys stay unique — `_active = incoming`
  // used to make two children share one NativeVideoPlayerController.
  final FeedSlot _slotA = FeedSlot();
  final FeedSlot _slotB = FeedSlot();
  final FeedSlot _slotC = FeedSlot();
  late final List<FeedSlot> _slots = [_slotA, _slotB, _slotC];
  late final RecommendPlaybackController _playback =
      RecommendPlaybackController(this);
  late final RecommendActivatePipeline _activate =
      RecommendActivatePipeline(this);
  late final FeedSlotPreparer _slotPreparer = FeedSlotPreparer(this);

  FeedSlot get _active => _slots[_playback.roles.active];
  FeedSlot get _next => _slots[_playback.roles.next];
  FeedSlot get _prev => _slots[_playback.roles.prev];

  late final FeedScrollVolumeDucker _scrollVolumeDucker = FeedScrollVolumeDucker(
    onDuckChanged: (duck) {
      _volumeDucked = duck;
      unawaited(_active.engine?.setVolume(duck ? 0 : 1));
    },
  );

  ProviderSubscription<(int, String?, String?, bool, bool)>? _feedSub;
  ProviderSubscription<int>? _itemsLenSub;
  ProviderSubscription<int>? _tabIndexSub;
  FeedShellOcclusionCoordinator? _shellOcclusion;
  bool _volumeDucked = false;
  DateTime? _skipDuckUntil;
  DateTime? _playbackArmedAt;
  DateTime? _noMoreToastAt;
  bool _endLoadQueued = false;
  int _unplayableSkipStreak = 0;
  String? _skippingUnplayableDramaId;
  bool _ended = false;

  /// Auth login / report cover while a sheet hold keeps surfaces mounted.
  bool _authOverlayCovering = false;
  bool _wasPlayingBeforeAuthOverlay = false;

  /// Covers the pre-[ensureLoaded] frame(s) before the controller flips
  /// [RecommendFeedState.isLoading], same idea as theater's short-drama gate.
  bool _awaitingFirstLoad = true;

  /// Cached [RecommendFeedState.items.length] for scroll-tick rounding —
  /// avoids a Riverpod read on every PageController notification.
  int _cachedItemCount = 0;

  /// Clear-screen mode without rebuilding the player layer.
  final ValueNotifier<bool> _chromeHidden = ValueNotifier<bool>(false);

  /// Cover reveal / frameReady — PageView only.
  final ValueNotifier<int> _coverRevision = ValueNotifier<int>(0);

  /// Slot surfaceReady / native attach — player layer only.
  final ValueNotifier<int> _slotRevision = ValueNotifier<int>(0);

  /// Set at the start of [dispose] so async teardown never notifies disposed
  /// notifiers (`mounted` stays true until [State.dispose] returns).
  bool _stateDisposed = false;

  late final RecommendEngineBridge _engineBridge = RecommendEngineBridge(this);

  /// Drama / comment sheet open — collapse native surfaces into the top band.
  final ValueNotifier<bool> _playerSheetOpen = ValueNotifier<bool>(false);

  /// Sheet body height for collapse math (defaults to design constant).
  final ValueNotifier<double> _playerSheetHeight =
      ValueNotifier<double>(StoryConstants.playerOverlaySheetHeight);

  late final RecommendPlaybackSession _playbackSession =
      RecommendPlaybackSession(
        controller: _ctrl,
        playerSheetOpen: _playerSheetOpen,
      );

  late final RecommendSurfaceCoordinator _surfaces =
      RecommendSurfaceCoordinator(
        overlayHoldsAdvance: () => _ctrl.overlayHoldsAdvance,
        onMountedChanged: () {
          if (mounted) setState(() {});
        },
      );

  /// Player surface height is snapped on sheet open/close (not animated) —
  /// continuous Platform View height changes jank the modal presentation.
  /// [FeedPlayerLayerHost] reads sheet state and computes height once.

  bool get _nativeSurfacesMounted => _surfaces.surfacesMounted;
  FeedPlayerSurfaceCache get _surfaceCache => _surfaces.surfaceCache;

  final ValueNotifier<bool> _playing = ValueNotifier(false);
  final ValueNotifier<bool> _userPaused = ValueNotifier(false);
  final ValueNotifier<Duration> _durationN = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _idlePosition = ValueNotifier(Duration.zero);

  /// Stable progress UI source — survives hard teardown so chrome never keeps
  /// listening to a disposed engine [positionNotifier] (which freezes the bar).
  final ValueNotifier<Duration> _progressPosition = ValueNotifier(Duration.zero);
  PlaybackEngine? _progressMirrorEngine;
  VoidCallback? _detachProgressMirror;

  bool get _isPlaying => _playing.value;
  set _isPlaying(bool value) => _playing.value = value;

  Duration get _duration => _durationN.value;
  set _duration(Duration value) => _durationN.value = value;

  /// Mirrors [PageController.page] so player surfaces rebuild on every scroll
  /// tick without waiting for Riverpod state.
  final ValueNotifier<double> _pageOffset = ValueNotifier<double>(0);

  /// Rounded pager index for chrome binding — updates only when
  /// [PageController.page].round() changes (not every scroll tick).
  final ValueNotifier<int> _visiblePageIndex = ValueNotifier<int>(0);

  /// Last index already early-activated mid-swipe (avoid re-promote).
  int? _earlyActivatedIndex;

  /// Session resume after hard teardown (route cover / shell uncover).
  ///
  /// Recommend keeps [restoreWatchProgress] off so swipe-back does not jump to
  /// theater history — but leaving the page disposes engines, so we latch the
  /// active playhead here and pass it as [startAt] on the next cold bind of
  /// the same [playbackId]. Also seeds [_progressPosition] so the bar holds.
  String? _occlusionResumePlaybackId;
  Duration? _occlusionResumeAt;
  Duration? _occlusionResumeDuration;

  /// While set, progress-mirror ignores native playheads below this floor so the
  /// bar never flashes 0 → resume during cold load / late timeUpdated(0).
  Duration? _progressFloor;

  /// After occlusion remount + startAt cold bind, defer neighbor loadUrl so it
  /// cannot pause/starve Active while mid-content resume is still settling.
  DateTime? _suppressNeighborWarmUntil;

  /// Retries [_maintainNeighbors] once when Active never went stable in time
  /// for the first warm attempt (avoids permanently empty neighbor slots).
  Timer? _deferredNeighborWarmTimer;
  int? _deferredNeighborWarmIndex;
  int _deferredNeighborWarmPlayGen = -1;

  /// Scroll intent for neighbor warm — bandwidth goes to the swipe direction
  /// first; the reverse side is deferred / WiFi-only.
  bool? _preferForwardNeighbor;

  /// Helper managing cached JPEG snapshots for [RecommendFeedItem.playbackId].
  late final RecommendFeedFrameManager _frameManager =
      RecommendFeedFrameManager(
        onStateChanged: () {
          if (!mounted) return;
          // Narrow rebuild: PageView covers listen to [_coverRevision], not
          // the whole RecommendFeedBody (avoids remounting player chrome).
          _coverRevision.value++;
        },
      );

  // ─── Lightweight recovery ──────────────────────────────────
  // Unexpected-pause / frame-stall decision flow lives in the shared
  // [FeedRecoveryEngine] (same choreography as the video feed); this widget
  // only tracks frame/arm state and supplies actions via the host adapter.
  DateTime? _lastFrameRenderedAt;
  String? _lastFrameDramaId;
  DateTime? _foregroundResumeAt;
  late final FeedRecoveryEngine _recovery = FeedRecoveryEngine(
    RecommendRecoveryHost(this),
  );

  /// Debounce playback-error toasts so mid-retry / weak-network swipes do not
  /// spam. Global gap limits cross-card bursts; per-drama gap covers multi-phase
  /// failures (load → auth → buffering) on one item.
  static const Duration _playbackErrorToastGlobalGap = Duration(seconds: 8);
  static const Duration _playbackErrorToastSameDramaGap = Duration(seconds: 20);

  String? _lastErrorToastDramaId;
  DateTime? _lastErrorToastAt;
  DateTime? _lastGlobalPlaybackErrorToastAt;
  bool _playbackFailed = false;
  int _bufferingTimeoutRecoveries = 0;
  String? _bufferingTimeoutDramaId;

  /// Auth/cookie recovery state — one attempt per drama binding.
  bool _authRecoveryInFlight = false;
  String? _authRecoveryDramaId;

  bool _appForeground = true;

  final _routeSubscription = FeedRouteAwareSubscription();
  bool _standaloneRouteCovered = false;
  bool _standaloneExitRunning = false;
  Future<void>? _teardownFuture;

  RecommendFeedController get _ctrl =>
      ref.read(recommendFeedControllerProvider.notifier);

  PlaybackVisibilityKind get _visibilityKind {
    return _surfaces.resolveVisibility(
      mounted: mounted,
      feedActive: widget.isActive,
      appForeground: _appForeground,
      authOverlayCovering: _authOverlayCovering,
      standaloneRouteCovered: _standaloneRouteCovered,
      isStandalone: widget.standalone,
      tabIndex: ref.read(tabIndexProvider),
      theaterTabIndex: StoryTab.theater.index,
      drawerOpen: ref.read(mainShellDrawerOpenProvider),
      shellRouteCovered: ref.read(mainShellRouteCoveredProvider),
    );
  }

  bool get _isPlaybackVisible => _surfaces.isPlaybackVisible(_visibilityKind);

  /// True when the active slot lost its engine (hard shell-route teardown) or
  /// no longer holds a decoded instance of the current card.
  bool _activeSlotNeedsRebind(RecommendFeedState feed) {
    final item = feed.currentItem;
    final play = feed.currentPlay;
    if (item == null || play == null) return false;
    return !FeedPlaybackPolicy.canResumeBoundSlot(
      slotPlaybackId: _active.playbackId,
      itemPlaybackId: item.playbackId,
      surfaceReady: _active.surfaceReady,
      hasEngine: _active.engine != null,
      hasLoadedPlay: _active.engine?.currentPlay != null,
      loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
        _active.engine?.currentPlay,
      ),
    );
  }

  // ─── RecommendFeedBodyState interface implementations ──────
  // These expose private state to [RecommendRecoveryHost] without
  // breaking encapsulation of the widget.

  @override
  bool get isPlaybackVisible => _isPlaybackVisible;

  @override
  bool get isPlaying => _isPlaying;

  @override
  set isPlaying(bool value) => _isPlaying = value;

  @override
  bool get volumeDucked => _volumeDucked;

  @override
  DateTime? get lastFrameRenderedAt => _lastFrameRenderedAt;

  @override
  int get playGeneration => _playback.playGeneration;

  @override
  bool get isUserPaused {
    final feed = ref.read(recommendFeedControllerProvider);
    return feed.isUserPaused;
  }

  @override
  bool get bindRunning => _playback.bindRunning;

  @override
  bool get neighborLoadGuarded => _playback.neighborLoadGuarded(
    next: _next.engine,
    prev: _prev.engine,
  );

  // ─── RecommendBindHost ─────────────────────────────────────

  @override
  bool get isMounted => mounted;

  @override
  RecommendFeedState readFeed() => ref.read(recommendFeedControllerProvider);

  @override
  FeedSlot get activeSlot => _active;

  @override
  FeedSlot get nextSlot => _next;

  @override
  FeedSlot get prevSlot => _prev;

  @override
  void clearCoverRevealLatch() => _surfaces.coverRevealLatchedPlaybackId = null;

  @override
  void setPlaying(bool value) => _isPlaying = value;

  @override
  RecommendPlaybackController get playback => _playback;

  @override
  FeedSlot get active => _active;

  @override
  FeedSlot get next => _next;

  @override
  FeedSlot get prev => _prev;

  @override
  Future<void> bindOrPromote(RecommendFeedState feed) =>
      _activate.bindOrPromote(feed);

  @override
  bool get promoteInFlight => _playback.promoteInFlight;

  @override
  bool get ended => _ended;

  @override
  bool get playbackFailed => _playbackFailed;

  @override
  String? get activePlaybackId => _active.playbackId;

  @override
  PlaybackEngine? get activeEngine => _active.engine;

  @override
  bool get activeSurfaceReady => _active.surfaceReady;

  @override
  String? get currentItemPlaybackId {
    final feed = ref.read(recommendFeedControllerProvider);
    return feed.currentItem?.playbackId;
  }

  @override
  String? get lastFrameDramaId => _lastFrameDramaId;

  @override
  DateTime? get playbackArmedAt => _playbackArmedAt;

  @override
  DateTime? get foregroundResumeAt => _foregroundResumeAt;

  @override
  Future<void> restoreActiveAfterNeighborLoad() =>
      _restoreActiveAfterNeighborLoad();

  @override
  void pauseBecauseHidden() => _pauseBecauseHidden();

  void _pauseBecauseHidden() {
    unawaited(_persistActiveWatchProgress());
    // Bump generation so any in-flight unmute from a flappy resume is abandoned.
    final audio = _playback.lifecycleAudio;
    final gen = audio.beginMute();
    // Best-effort mute: pause() may fail with NO_VIEW during fast
    // route/surface transitions, but volume=0 should silence audio anyway.
    // Track the Future so foreground can await it before unmute — otherwise
    // a late setVolume(0) after resumed leaves playback silent.
    final mute = Future.wait<void>([
      _active.engine?.setVolume(0.0) ?? Future<void>.value(),
      _next.engine?.setVolume(0.0) ?? Future<void>.value(),
      _prev.engine?.setVolume(0.0) ?? Future<void>.value(),
      _active.engine?.pause() ?? Future<void>.value(),
      _next.engine?.pause() ?? Future<void>.value(),
      _prev.engine?.pause() ?? Future<void>.value(),
    ]);
    audio.trackMute(mute, gen);
    _isPlaying = false;
  }

  /// Login / other tabs / the drawer sit above this feed. Pause is not
  /// enough on Android: a mounted SurfaceView still punches through later
  /// Flutter routes (same OEM compositor bug as the theater banner).
  /// Also bump bind generation and drop the queue so in-flight
  /// `loadUrl` / `applyPlayback` fail [shouldContinue] immediately.
  void _hideNativeSurfacesForOcclusion() {
    _playback.invalidateStaleBind();
    _playback.clearQueueMarkers();
    // Same as isActive=false: drop neighbor generations so in-flight
    // preload loadUrl fails stillThisNeighbor immediately.
    _relinquishNeighborSlots();
    _pauseBecauseHidden();
    _unmountNativeSurfaces();
  }

  /// Route transitions must retain the real pending load Future so awaited
  /// teardown cannot dispose an AVPlayer while its loadUrl is still running.
  /// Soft tab/drawer hiding may abandon preloads; full cross-page handoff may
  /// not.
  void _teardownNativeSurfacesForOcclusion() {
    _captureOcclusionResume();
    unawaited(_persistActiveWatchProgress());
    unawaited(_active.engine?.setVolume(0.0));
    unawaited(_next.engine?.setVolume(0.0));
    unawaited(_prev.engine?.setVolume(0.0));
    _isPlaying = false;
    _unmountNativeSurfaces();
    unawaited(_teardownAllPlayers());
  }

  /// Snapshot the active playhead before engines are disposed.
  void _captureOcclusionResume() {
    final playbackId = _active.playbackId;
    final position = _active.engine?.position;
    if (playbackId == null ||
        playbackId.isEmpty ||
        position == null ||
        position <= Duration.zero) {
      return;
    }
    _occlusionResumePlaybackId = playbackId;
    _occlusionResumeAt = position;
    if (_duration > Duration.zero) {
      _occlusionResumeDuration = _duration;
    } else {
      final engineDur = _active.engine?.duration;
      if (engineDur != null && engineDur > Duration.zero) {
        _occlusionResumeDuration = engineDur;
      }
    }
    // Hold the chrome bar on this value across remount / cold bind.
    _progressPosition.value = position;
    _progressFloor = position;
  }

  Duration? _peekOcclusionResumeStartAt(String playbackId) {
    if (_occlusionResumePlaybackId != playbackId) return null;
    final at = _occlusionResumeAt;
    if (at == null || at <= Duration.zero) return null;
    return at;
  }

  void _clearOcclusionResume({String? onlyIfPlaybackId}) {
    if (onlyIfPlaybackId != null &&
        _occlusionResumePlaybackId != onlyIfPlaybackId) {
      return;
    }
    _occlusionResumePlaybackId = null;
    _occlusionResumeAt = null;
    _occlusionResumeDuration = null;
  }

  void _clearProgressFloor() {
    _progressFloor = null;
  }

  void _detachProgressMirrorNow() {
    _detachProgressMirror?.call();
    _detachProgressMirror = null;
    _progressMirrorEngine = null;
  }

  void _detachProgressMirrorIfEngine(PlaybackEngine? engine) {
    if (engine == null || !identical(engine, _progressMirrorEngine)) return;
    _detachProgressMirrorNow();
  }

  void _attachProgressMirror(PlaybackEngine engine) {
    _detachProgressMirrorNow();
    void sync() {
      final next = engine.positionNotifier.value;
      final floor = _progressFloor;
      // Fresh engines report 0 (and may tick near the head) before startAt
      // seek lands. Keep the chrome bar pinned at the resume point so it
      // never flashes 0 → continue.
      if (floor != null &&
          floor > Duration.zero &&
          next + const Duration(milliseconds: 500) < floor) {
        return;
      }
      if (floor != null &&
          next + const Duration(milliseconds: 500) >= floor) {
        // Native caught up — release the floor so normal scrubbing works.
        _progressFloor = null;
      }
      if (_progressPosition.value != next) {
        _progressPosition.value = next;
      }
    }

    engine.positionNotifier.addListener(sync);
    _progressMirrorEngine = engine;
    sync();
    _detachProgressMirror = () {
      try {
        engine.positionNotifier.removeListener(sync);
      } catch (_) {}
    };
  }

  bool get _shouldMountNativeSurfaces =>
      _surfaces.shouldMount(_visibilityKind);

  void _unmountNativeSurfaces() {
    if (!_nativeSurfacesMounted || !mounted) return;
    // Cover latch lives on [_surfaces]; [unmount] clears it unless a sheet
    // hold is active (poster must not flash over video).
    _surfaces.unmount(reason: 'occlusion');
    // Platform Views are gone — soft-resume must not treat slots as ready
    // (that path only calls play() and stuck with NO_VIEW / black frame).
    for (final slot in [_active, _next, _prev]) {
      if (slot.native != null) {
        slot.surfaceReady = false;
        slot.frameReady = false;
      }
      slot.engine?.invalidateNativeInitialization();
    }
    _slotRevision.value++;
    _coverRevision.value++;
  }

  /// Hold auto-advance while system share is up (iOS presents share from an
  /// elevated UIWindow so PlatformViews stay mounted and playing).
  Future<void> _aroundShare(Future<void> Function() share) async {
    await _playbackSession.aroundShare(share);
  }

  Future<T> _holdWithCollapsedPlayer<T>(Future<T> Function() action) async {
    final band = PlayerSheetLayoutCoordinator.collapsedBandHeight(
      MediaQuery.sizeOf(context).height,
      sheetHeight: _playerSheetHeight.value,
    );
    _surfaces.onSheetOpenChanged(open: true, bandHeight: band);
    try {
      return await _playbackSession.holdWithCollapsedPlayer(action);
    } finally {
      _surfaces.onSheetOpenChanged(open: false, bandHeight: band);
    }
  }

  void _onNeighborSurfacesMounted() {
    if (!mounted) return;
    _slotRevision.value++;
    final feed = ref.read(recommendFeedControllerProvider);
    final activeId = _active.playbackId;
    if (activeId != null && feed.currentItem?.playbackId == activeId) {
      _maintainNeighbors(feed.currentIndex);
    }
  }

  void _restoreNeighborSurfacesIfNeeded() {
    _surfaces.restoreNeighborSurfacesAfterRemount(
      activeHasFirstFrame: _active.frameReady,
      stillNeeded: () => mounted && _nativeSurfacesMounted,
      onNeighborMounted: _onNeighborSurfacesMounted,
    );
  }

  void _remountNativeSurfacesThenResume() {
    unawaited(_remountNativeSurfacesThenResumeAsync());
  }

  Future<void> _remountNativeSurfacesThenResumeAsync() async {
    final localTeardown = _teardownFuture;
    if (localTeardown != null) {
      await localTeardown;
    }
    if (NativeVideoPlayerCoordinator.isTearingDown) {
      await NativeVideoPlayerCoordinator.waitForTeardown(
        timeout: const Duration(seconds: 90),
      );
    }
    if (NativeVideoPlayerCoordinator.isTearingDown ||
        !mounted ||
        !_shouldMountNativeSurfaces) {
      return;
    }
    if (!_nativeSurfacesMounted) {
      _surfaces.remount();
      // playerLayer only mounts NativeVideoPlayer when surfaceReady — arm
      // existing slots first or hasPlatformView never becomes true (tab /
      // drawer return stuck on cover with no resume).
      _armExistingSurfacesForRemount();
      await waitOneFeedPostFrame();
      if (!mounted || !_shouldMountNativeSurfaces) return;
      await waitOneFeedPostFrame();
      if (!mounted || !_shouldMountNativeSurfaces) return;
      await _markSurfacesReadyAfterRemount();
      _restoreNeighborSurfacesIfNeeded();
    } else {
      _restoreNeighborSurfacesIfNeeded();
    }
    if (!mounted || !_isPlaybackVisible) return;
    _resumeIfVisible();
  }

  Future<void> _waitOnePostFrame() => waitOneFeedPostFrame();

  /// Soft-occlusion remount: allow Platform Views into the tree before we
  /// wait for [hasPlatformView]. Mirrors [FeedSlotPreparer] reuse order.
  void _armExistingSurfacesForRemount() {
    var armed = false;
    for (final slot in [_active, _next, _prev]) {
      if (!RecommendSurfaceCoordinator.shouldArmSurfaceReady(
        hasNative: slot.native != null,
        surfaceReady: slot.surfaceReady,
      )) {
        continue;
      }
      slot.surfaceReady = true;
      armed = true;
    }
    if (armed) {
      _slotRevision.value++;
    }
  }

  /// After occlusion remount, wait until at least the active native view
  /// registers (or slots are empty and cold-bind will create them).
  Future<void> _markSurfacesReadyAfterRemount() async {
    final deadline = DateTime.now().add(const Duration(milliseconds: 800));
    while (mounted && DateTime.now().isBefore(deadline)) {
      var anyPending = false;
      for (final slot in [_active, _next, _prev]) {
        final native = slot.native;
        if (native == null) continue;
        // Keep surfaceReady armed so the view can attach; only track
        // whether registration finished.
        if (!slot.surfaceReady) {
          slot.surfaceReady = true;
          anyPending = true;
        }
        if (!native.hasPlatformView) {
          anyPending = true;
        }
      }
      if (!anyPending) return;
      // Active empty (full teardown) — cold bind creates controllers later.
      if (_active.native == null &&
          _next.native == null &&
          _prev.native == null) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Best-effort resume point + last-watched episode for short dramas.
  Future<void> _persistActiveWatchProgress() async {
    final engine = _active.engine;
    if (engine == null) return;

    final feed = ref.read(recommendFeedControllerProvider);
    final item = feed.currentItem;
    if (item == null) return;

    // Engine / local progress keys use the API work id, not playbackId.
    final dramaId = item.dramaId.trim().isNotEmpty
        ? item.dramaId.trim()
        : engine.dramaId;
    if (dramaId.isEmpty) return;

    final episodeNo =
        feed.currentPlay?.episodeNo ??
        RecommendFeedController.episodeNoOf(item);
    if (episodeNo < 1) return;

    // Read Riverpod and persist the episode cursor before the first await.
    // Standalone exit pops immediately, so using ref after persistResume could
    // otherwise race State disposal and lose the last-watched episode.
    if (widget.persistDramaCursor && !item.workType.isShortVideo) {
      ref
          .read(currentDramaEpisodeProvider(dramaId).notifier)
          .setEpisode(episodeNo);
    }

    try {
      await engine.persistResume(episodeNo);
    } catch (_) {
      // Engine may be mid-teardown.
    }
  }

  void _resumeIfVisible() {
    unawaited(_resumeIfVisibleAsync());
  }

  Future<void> _resumeIfVisibleAsync() async {
    if (!_isPlaybackVisible) return;

    final audio = _playback.lifecycleAudio;
    final gen = audio.beginResume();
    await audio.awaitPendingMute();
    if (!mounted || !audio.isCurrent(gen) || !_isPlaybackVisible) {
      return;
    }

    // Background / occlusion always mutes every slot. Restore volume whenever
    // we become visible again — including user-paused — so tap-to-play is not
    // silent. Soft resume then force-unmutes again after play so a late
    // MethodChannel setVolume(0) cannot win the race.
    _volumeDucked = false;
    await _active.engine?.setVolume(1.0, force: true);
    if (!mounted || !audio.isCurrent(gen) || !_isPlaybackVisible) {
      return;
    }

    final latest = ref.read(recommendFeedControllerProvider);
    if (latest.isUserPaused) {
      // Hard teardown (e.g. public profile over main shell) disposes engines.
      // Re-bind paused so tap-to-play has a live AVPlayer, not a null engine.
      if (_activeSlotNeedsRebind(latest)) {
        await bindPlayback(latest);
      } else {
        try {
          await _active.engine?.ensureSurfaceConnected();
          await _active.engine?.nudgeTextureFrame();
        } catch (_) {}
      }
      return;
    }
    if (_ended) {
      try {
        await _active.engine?.ensureSurfaceConnected();
        await _active.engine?.nudgeTextureFrame();
      } catch (_) {}
      return;
    }

    final item = latest.currentItem;
    final play = latest.currentPlay;
    // Soft-occlusion kept the engine: force-unmute soft resume before the
    // bind queue (which uses forceUnmute:false) so tab/drawer return plays.
    if (item != null &&
        play != null &&
        _active.engine != null &&
        _active.native != null &&
        FeedPlaybackPolicy.canResumeBoundSlot(
          slotPlaybackId: _active.playbackId,
          itemPlaybackId: item.playbackId,
          surfaceReady: true,
          hasEngine: true,
          hasLoadedPlay: _active.engine?.currentPlay != null,
          loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
            _active.engine?.currentPlay,
          ),
        )) {
      if (!_active.surfaceReady) {
        _active.surfaceReady = true;
        _slotRevision.value++;
      }
      await resumeBoundActive(
        feed: latest,
        playbackId: item.playbackId,
        refreshCookies: true,
        forceUnmute: true,
      );
      return;
    }

    if (play != null) {
      _playback.enqueueBind(latest);
    } else {
      await _active.engine?.startPlayback();
    }
    if (!mounted || !audio.isCurrent(gen)) return;
    await _active.engine?.setVolume(1.0, force: true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initialFeed = ref.read(recommendFeedControllerProvider);
    final initialPage = initialFeed.currentIndex;
    _cachedItemCount = initialFeed.items.length;
    // External / already-warm feeds should not hold the bootstrap spinner.
    if (_ctrl.isExternalFeed || initialFeed.items.isNotEmpty) {
      _awaitingFirstLoad = false;
    }
    if (initialFeed.items.isNotEmpty) {
      _primeInitialFrameCaches(initialFeed);
    }
    _pageController = PageController(initialPage: initialPage);
    _visiblePageIndex.value = initialPage;
    _pageController.addListener(_onPageScroll);
    PlaybackFrameCacheService.instance.revisions.addListener(
      _onFrameCacheRevision,
    );
    _playing.addListener(_syncWakeLock);
    _userPaused.addListener(_syncWakeLock);
    PlaybackAuthRouteObserver.instance.addListener(_onAuthRouteCover);
    _itemsLenSub = ref.listenManual<int>(
      recommendFeedControllerProvider.select((s) => s.items.length),
      (prev, count) {
        if (count <= 0) return;
        _clearAwaitingFirstLoad();
        if ((prev ?? 0) > 0) return;
        _primeInitialFrameCaches(ref.read(recommendFeedControllerProvider));
      },
      fireImmediately: true,
    );
    _scheduleWhenActive();
    _feedSub = ref.listenManual<(int, String?, String?, bool, bool)>(
      recommendFeedControllerProvider.select(
        (s) => (
          s.currentIndex,
          s.currentItem?.id,
          s.currentPlay?.episodeId,
          s.isPlayLoading,
          FeedPlaybackPolicy.isUnplayableTranscodeError(s.lastError),
        ),
      ),
      (prev, next) {
        if (!mounted || !_isPlaybackVisible) return;
        final feed = ref.read(recommendFeedControllerProvider);
        _onFeedIdentity(prev?.$1, feed);
      },
    );
    if (!widget.standalone) {
      _shellOcclusion = FeedShellOcclusionCoordinator(
        theaterTabIndex: StoryTab.theater.index,
        overlayHoldsAdvance: () => _ctrl.overlayHoldsAdvance,
        onSoftHide: _hideNativeSurfacesForOcclusion,
        onHardTeardown: _teardownNativeSurfacesForOcclusion,
        onRemount: _remountNativeSurfacesThenResume,
      );
      _shellOcclusion!.attach(ref);
      _tabIndexSub = ref.listenManual<int>(tabIndexProvider, (prev, tabIndex) {
        if (prev == StoryTab.theater.index &&
            tabIndex != StoryTab.theater.index) {
          _ctrl.flushPendingWatchHistory();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeSubscription.update(
      context,
      this,
      enabled: widget.standalone,
    );
  }

  @override
  void didPushNext() {
    if (!widget.standalone || _ctrl.overlayHoldsAdvance) return;
    _standaloneRouteCovered = true;
    _teardownNativeSurfacesForOcclusion();
  }

  @override
  void didPopNext() {
    if (!widget.standalone || !_standaloneRouteCovered) return;
    _standaloneRouteCovered = false;
    _remountNativeSurfacesThenResume();
  }

  void _clearAwaitingFirstLoad() {
    if (!_awaitingFirstLoad || !mounted) return;
    setState(() => _awaitingFirstLoad = false);
  }

  void _primeInitialFrameCaches(RecommendFeedState feed) {
    final ids = feed.items.map(_frameCacheKeyFor).toList(growable: false);
    unawaited(
      _frameManager.primeAround(
        ids,
        centerIndex: feed.currentIndex.clamp(0, ids.isEmpty ? 0 : ids.length - 1),
      ),
    );
  }

  void _scheduleWhenActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isPlaybackVisible) return;
      final state = ref.read(recommendFeedControllerProvider);
      if (state.currentPlay != null) {
        _clearAwaitingFirstLoad();
        _enqueueBind(state);
      } else if (state.items.isNotEmpty) {
        _clearAwaitingFirstLoad();
        // SWR / sign-in-flight: wait for ensureLoaded → activateIndex.
        // Opportunistic activate here races the first-page revalidate.
        if (state.isPlayLoading || state.isLoading) return;
        unawaited(_ctrl.activateIndex(state.currentIndex));
      } else {
        unawaited(() async {
          try {
            await _ctrl.ensureLoaded();
          } finally {
            _clearAwaitingFirstLoad();
          }
        }());
      }
    });
  }

  @override
  void didUpdateWidget(covariant RecommendFeedBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _ctrl.flushPendingWatchHistory();
      _hideNativeSurfacesForOcclusion();
      _active.engine?.releaseCookieFamily();
      _earlyActivatedIndex = null;
      _syncWakeLock();
    } else if (!oldWidget.isActive && widget.isActive) {
      _scheduleWhenActive();
      _remountNativeSurfacesThenResume();
      _syncWakeLock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (FeedAppLifecyclePolicy.shouldMarkBackground(state)) {
      _appForeground = false;
      _pauseBecauseHidden();
      _syncWakeLock();
      return;
    }
    if (FeedAppLifecyclePolicy.shouldMarkForeground(state)) {
      _appForeground = true;
      _foregroundResumeAt = DateTime.now();
      _remountNativeSurfacesThenResume();
      _syncWakeLock();
    }
  }

  /// Hold the device awake while this feed is visibly playing.
  void _syncWakeLock() {
    if (!mounted) {
      unawaited(PlaybackWakeLock.current.release());
      return;
    }
    final feed = ref.read(recommendFeedControllerProvider);
    final keepOn = PlaybackWakeLockPolicy.shouldKeepScreenOn(
      isPlaying: _isPlaying,
      isPlaybackVisible:
          _isPlaybackVisible && widget.isActive && _appForeground,
      userPaused: feed.isUserPaused || _userPaused.value,
    );
    unawaited(PlaybackWakeLock.current.apply(keepOn: keepOn));
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == null) return;
    if (_pageOffset.value != page) {
      _pageOffset.value = page;
    }

    final itemCount = _cachedItemCount;
    if (itemCount > 0) {
      final targetIndex = page.round().clamp(0, itemCount - 1);
      if (targetIndex != _visiblePageIndex.value) {
        _visiblePageIndex.value = targetIndex;
      }
    }

    final activeIndex = _active.index;
    if (activeIndex == null) return;

    final skipDuck =
        _skipDuckUntil != null && DateTime.now().isBefore(_skipDuckUntil!);
    final threshold = FeedScrollActivatePolicy.earlyActivateProgress;
    final scrollTick = FeedScrollActivateSnapshot.analyze(
      page: page,
      activeIndex: activeIndex,
      inSkipDuckWindow: skipDuck,
    );

    if (scrollTick.preferForward != null) {
      _preferForwardNeighbor = scrollTick.preferForward!;
    }

    if (scrollTick.shouldDuckOutgoing) {
      _scrollVolumeDucker.apply(shouldDuck: true);
    } else {
      _scrollVolumeDucker.apply(shouldDuck: false);
    }

    _tryEarlyActivate(
      page: page,
      activeIndex: activeIndex,
      neighbor: _next,
      forward: true,
      threshold: threshold,
    );
    _tryEarlyActivate(
      page: page,
      activeIndex: activeIndex,
      neighbor: _prev,
      forward: false,
      threshold: threshold,
    );
  }

  void _tryEarlyActivate({
    required double page,
    required int activeIndex,
    required FeedSlot neighbor,
    required bool forward,
    required double threshold,
  }) {
    final neighborIndex = FeedPageScrollEarlyActivate.recommendNeighborIndex(
      page: page,
      activeIndex: activeIndex,
      neighborIndex: neighbor.index,
      neighborReady: FeedPlaybackPolicy.isNeighborReadyForEarlyActivate(
        slotPlaybackId: neighbor.playbackId,
        loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
          neighbor.engine?.currentPlay,
        ),
        hasPendingLoad: neighbor.engine?.hasPendingLoad ?? true,
        surfaceReady: neighbor.surfaceReady,
        frameReady: neighbor.frameReady,
      ),
      alreadyEarlyActivated: _earlyActivatedIndex,
      goingForward: forward,
      threshold: threshold,
    );
    if (neighborIndex == null) return;
    _earlyActivatedIndex = neighborIndex;
    unawaited(_ctrl.onPageChanged(neighborIndex));
  }

  void _onFeedIdentity(int? prevIndex, RecommendFeedState next) {
    _cachedItemCount = next.items.length;
    final indexChanged = prevIndex != next.currentIndex;
    if (indexChanged) {
      _earlyActivatedIndex = null;
      _playbackArmedAt = null;
      if (_surfaces.coverRevealLatchedPlaybackId != null &&
          _surfaces.coverRevealLatchedPlaybackId != next.currentItem?.playbackId) {
        _surfaces.coverRevealLatchedPlaybackId = null;
      }
    }
    // Only prime frame cache on index changes — identity recomposition
    // with the same index (e.g. play loading toggle) skips the
    // list-allocation + disk peek overhead.
    final currentItem = next.currentItem;
    if (indexChanged && (currentItem != null || next.items.isNotEmpty)) {
      final ids = next.items.map(_frameCacheKeyFor).toList(growable: false);
      unawaited(
        _frameManager.primeAround(
          ids,
          centerIndex: next.currentIndex.clamp(
            0,
            ids.isEmpty ? 0 : ids.length - 1,
          ),
        ),
      );
    }
    final manualRetryOwnsLoading = _playback.manualRetry.onFeedIdentity(
      currentIndex: next.currentIndex,
      bindWorkId: next.currentItem?.bindWorkId,
    );
    if (next.currentPlay != null) {
      _ended = false;
      _unplayableSkipStreak = 0;
      _skippingUnplayableDramaId = null;
      if (!FeedPlaybackPolicy.shouldEnqueueBindOnIdentity(
        hasCurrentPlay: true,
        isPlayLoading: next.isPlayLoading,
        authRecoveryInFlight: _authRecoveryInFlight,
        manualRetryOwnsLoading: manualRetryOwnsLoading,
      )) {
        return;
      }
      _playback.enqueueBind(next);
    } else if (!next.isPlayLoading) {
      unawaited(_handleUnplayableCurrent(next));
    }
  }

  void _enqueueBind(RecommendFeedState feed) => _playback.enqueueBind(feed);

  bool _bindTargetStillCurrent(RecommendFeedState snapshot) =>
      _playback.bindTargetStillCurrent(snapshot);

  /// 绑定管线的代数守卫：widget 已挂载、generation 未过期、绑定目标仍是
  /// 当前项。收敛 [bindPlayback] / [_promoteNeighborBody] 中重复的三重复合
  /// 守卫链（曾散落 9 处）。
  bool _bindStillCurrent(RecommendFeedState feed, int generation) =>
      _playback.bindStillCurrent(feed, generation);

  /// Slot 准备管线的代数守卫已迁入 [FeedSlotPreparer]（host.isMounted + gen）。

  /// `allowActive=false` 时禁止操作活跃槽 —— [_prepareSlot] 中重复的
  /// `if (!allowActive && identical(slot, _active)) return null;`。
  bool _slotAllowed(FeedSlot slot, bool allowActive) =>
      allowActive || !identical(slot, _active);

  /// 引擎回调的代数守卫：widget 已挂载且回调所属的 generation 仍是当前。
  /// [RecommendEngineBridge] 在派发前调用 [isGenerationCurrent]。
  bool _engineGenAlive(int generation) => _playback.engineGenAlive(generation);

  bool Function() _bindContinue(RecommendFeedState feed, int generation) =>
      () => FeedPlaybackPolicy.shouldContinueFeedBind(
        generation: generation,
        currentGeneration: _playback.playGeneration,
        mounted: mounted,
        snapshotStillCurrent: _bindTargetStillCurrent(feed),
      );

  /// Flush slot onto [index] and wait until layout applied; false if superseded.
  Future<bool> _flushSlotReadyForPlay(
    FeedSlot slot,
    int index,
    RecommendFeedState feed,
    int generation,
  ) async {
    await _flushSlotToPage(slot, index);
    if (!_bindStillCurrent(feed, generation)) return false;
    await _waitUntilSlotOnScreen(slot);
    if (!_bindStillCurrent(feed, generation)) return false;
    final engine = slot.engine;
    final native = engine?.nativeController ?? slot.native;
    if (engine != null &&
        native != null &&
        !native.hasPlatformView &&
        slot.surfaceReady) {
      final viewReady = await engine.waitForPlatformView(
        timeout: const Duration(milliseconds: 800),
      );
      if (!viewReady || !_bindStillCurrent(feed, generation)) {
        return false;
      }
    }
    return _bindStillCurrent(feed, generation);
  }

  @override
  Future<void> resumeBoundActive({
    required RecommendFeedState feed,
    required String playbackId,
    required bool refreshCookies,
    required bool forceUnmute,
    int? generation,
  }) async {
    await _flushSlotToPage(_active, feed.currentIndex);
    if (generation != null) {
      if (!_bindStillCurrent(feed, generation)) return;
    } else if (!_bindTargetStillCurrent(feed)) {
      return;
    }

    final engine = _active.engine;
    if (engine == null) return;

    final native = engine.nativeController ?? _active.native;
    if (native != null && !native.hasPlatformView) {
      final viewReady = await engine.waitForPlatformView(
        timeout: const Duration(milliseconds: 800),
      );
      if (!viewReady) {
        StoryLogger.d(
          'soft resume → cold rebind (no platform view)',
          tag: 'Rec',
        );
        await _coldRebindAfterFailedSoftResume(feed);
        return;
      }
    }
    if (native != null && !native.isInitialized) {
      engine.invalidateNativeInitialization();
    }
    if (_active.native != null) {
      _active.surfaceReady = true;
    }

    if (refreshCookies) {
      await engine.ensureSurfaceConnected();
      final cookiesReady = await engine.prepareCookiesForForegroundResume();
      if (!_bindTargetStillCurrent(feed)) return;
      if (!cookiesReady) {
        _active.playbackId = null;
        _active.frameReady = false;
        _surfaces.coverRevealLatchedPlaybackId = null;
        if (mounted) setState(() {});
        // The controller state transition queues the one replacement bind.
        // Returning here keeps this already-running drain from cold-binding
        // the same fresh payload a second time.
        await _ctrl.refreshCurrentPlay();
        return;
      }
    }

    _latchCoverRevealIfPainted(playbackId);
    if (!feed.isUserPaused && _isPlaybackVisible) {
      if (forceUnmute) await engine.setVolume(1.0, force: true);
      final started = await engine.startPlayback();
      if (!started && _bindTargetStillCurrent(feed) && _isPlaybackVisible) {
        StoryLogger.d(
          'soft resume play() failed → cold rebind',
          tag: 'Rec',
        );
        await _coldRebindAfterFailedSoftResume(feed);
        return;
      }
      if (started) {
        // play() ACK is not always followed by a `playing` activity event
        // after occlusion — arm metrics so 有效播放 keeps accumulating.
        _isPlaying = true;
        _ctrl.onEpisodeMetricsPlayStart();
      }
      if (forceUnmute) await engine.setVolume(1.0, force: true);
    }
    if (_bindTargetStillCurrent(feed)) {
      _maintainNeighbors(feed.currentIndex);
    }
  }

  /// Soft resume after occlusion can leave a dead surface; force the cold
  /// path by clearing slot identity so [canResumeBoundSlot] is false.
  Future<void> _coldRebindAfterFailedSoftResume(RecommendFeedState feed) async {
    // Keep playhead across the forced cold bind (engine may still hold it).
    _captureOcclusionResume();
    _active.playbackId = null;
    _active.frameReady = false;
    _active.surfaceReady = _active.native?.hasPlatformView == true;
    _surfaces.coverRevealLatchedPlaybackId = null;
    _active.engine?.invalidateNativeInitialization();
    if (mounted) setState(() {});
    await bindPlayback(feed);
  }

  /// After promote / cold bind: pause when occluded, else keep neighbors warm.
  Future<void> _finalizeActiveSession(RecommendFeedState feed) async {
    if (!_isPlaybackVisible || feed.isUserPaused) {
      await _active.engine?.pause();
      _isPlaying = false;
    } else if (!_ended) {
      // Remount / startAt resume can leave native paused after load races.
      // Kick play before neighbor warm so Active owns the decoder first.
      final engine = _active.engine;
      if (engine != null && !engine.isPlaying && !engine.hasCompleted) {
        final ok = await engine.startPlayback();
        if (ok) {
          _isPlaying = true;
          await engine.setVolume(1.0, force: true);
        }
      }
    }
    _maintainNeighbors(feed.currentIndex);
  }

  @override
  Future<bool> tryPromoteNeighbor(
    FeedSlot neighbor, {
    required RecommendFeedState feed,
    required Completer<bool>? ready,
    bool alreadyReady = false,
  }) async {
    final item = feed.currentItem;
    if (item == null ||
        identical(neighbor, _active) ||
        neighbor.playbackId != item.playbackId) {
      return false;
    }
    if (!_bindTargetStillCurrent(feed)) return false;

    if (alreadyReady ||
        FeedPlaybackPolicy.slotHoldsDecodedItem(
          slotPlaybackId: neighbor.playbackId,
          itemPlaybackId: item.playbackId,
          loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
            neighbor.engine?.currentPlay,
          ),
          hasPendingLoad: neighbor.engine?.hasPendingLoad ?? true,
          surfaceReady: neighbor.surfaceReady,
          frameReady: neighbor.frameReady,
        )) {
      return _promoteNeighbor(neighbor, feed);
    }

    if (ready == null) return false;
    // Wait under the current-page poster. Latching here uncovers the new
    // card over the previous active surface (wrong picture, then correct).
    final ok = await ready.future.timeout(
      StoryDurations.waitInFlightRaceBudget,
      onTimeout: () => false,
    );
    if (!ok ||
        !_bindTargetStillCurrent(feed) ||
        neighbor.playbackId != item.playbackId ||
        neighbor.engine?.currentPlay == null) {
      return false;
    }
    return _promoteNeighbor(neighbor, feed);
  }

  Future<bool> _promoteNeighbor(
    FeedSlot incoming,
    RecommendFeedState feed,
  ) async {
    final item = feed.currentItem;
    if (item == null ||
        incoming.engine == null ||
        incoming.playbackId != item.playbackId) {
      return false;
    }

    _playback.promoteInFlight = true;
    final generation = _playback.beginPromoteGeneration();
    try {
      return await _promoteNeighborBody(incoming, feed, generation);
    } finally {
      _playback.promoteInFlight = false;
    }
  }

  Future<bool> _promoteNeighborBody(
    FeedSlot incoming,
    RecommendFeedState feed,
    int generation,
  ) async {
    final item = feed.currentItem;
    if (item == null ||
        incoming.engine == null ||
        incoming.playbackId != item.playbackId) {
      return false;
    }
    if (!_bindTargetStillCurrent(feed)) return false;

    final previousIndex = incoming.index;
    void restoreIncomingIndex() {
      incoming.index = previousIndex;
      if (mounted) setState(() {});
    }

    var goingForward = identical(incoming, _next);

    final promoted = await FeedSlotSession.promoteNeighbor(
      silenceOutgoing: () => FeedMediaLoad.silenceBestEffort(_active.engine),
      prepareIncomingOnScreen: () async {
        // Promote may run before the post-first-frame neighbor mount delay
        // finishes; incoming must have a live Platform View for migrate.
        if (!_surfaces.mountNeighborSurfaces && _active.frameReady) {
          _surfaces.mountNeighborsImmediately(onMount: () {});
        }
        // Keep the poster up until migrate paints a frame — latching here
        // uncovers a black / stale surface mid-swap.
        if (!await _flushSlotReadyForPlay(
          incoming,
          feed.currentIndex,
          feed,
          generation,
        )) {
          restoreIncomingIndex();
          return false;
        }
        return true;
      },
      promoteCookies: () async {
        final cookiesOk = await incoming.engine!.promotePreloadedResource();
        if (!cookiesOk || !_bindStillCurrent(feed, generation)) {
          restoreIncomingIndex();
          return false;
        }
        _wireEngineCallbacks(incoming.engine!, generation);
        return true;
      },
      migrateToActive: () async {
        final ok = await incoming.engine!.migrateToActive(
          shouldContinue: _bindContinue(feed, generation),
        );
        if (!ok || !_bindStillCurrent(feed, generation)) {
          restoreIncomingIndex();
          return false;
        }
        return true;
      },
      rotateRoles: () async {
        goingForward = identical(incoming, _next);
        if (!goingForward && !identical(incoming, _prev)) {
          restoreIncomingIndex();
          return false;
        }
        _active.frameReady = false;
        _playback.rotateRoles(goingForward: goingForward);
        _active.frameReady = _active.engine?.hasPresentedFirstFrame ?? false;
        if (!_bindStillCurrent(feed, generation)) {
          unawaited(_active.engine?.pause());
          unawaited(_active.engine?.setVolume(0));
          _surfaces.coverRevealLatchedPlaybackId = null;
          _isPlaying = false;
          if (mounted) setState(() {});
          // Role rotation already committed — rebind to the live playhead.
          final live = ref.read(recommendFeedControllerProvider);
          if (mounted && live.currentPlay != null) {
            _enqueueBind(live);
          }
          return false;
        }
        return true;
      },
      finalizeActive: () async {
        _latchCoverRevealIfPainted(item.playbackId);
        _volumeDucked = false;
        _skipDuckUntil = DateTime.now().add(
          StoryDurations.adjacentPreloadAfterPlaying,
        );
        _playbackArmedAt = DateTime.now();
        // Neighbor prime may have already emitted playing under
        // NeighborEngineListener — metrics never saw onPlayStart.
        _ctrl.onEpisodeMetricsPlayStart();
        _active.engine?.retargetSlot(
          tag: 'Recommend',
          role: PlaybackEngineRole.active,
        );
        unawaited(_active.engine?.setVolume(1));
        _duration = _active.engine?.duration ?? _duration;
        _syncLooping();
        _isPlaying = true;
        _earlyActivatedIndex = null;
        if (mounted) setState(() {});
        _warmDiskSkippingNativeSlots();
        await _finalizeActiveSession(feed);
        StoryLogger.d(
          'Recommend promoted ${goingForward ? 'next' : 'prev'} '
          'drama=${item.dramaId}',
          tag: 'Rec',
        );
      },
    );
    return promoted;
  }

  @override
  Future<void> bindPlayback(RecommendFeedState feed) async {
    final item = feed.currentItem;
    final play = feed.currentPlay;
    if (item == null || play == null) return;
    if (!_bindTargetStillCurrent(feed)) return;

    final generation = _playback.beginColdBindGeneration();
    final dramaId = item.playbackId;
    final episodeNo = play.episodeNo ?? item.episodeNo ?? 1;

    // Same drama already bound — resume if needed.
    if (FeedPlaybackPolicy.canResumeBoundSlot(
      slotPlaybackId: _active.playbackId,
      itemPlaybackId: dramaId,
      surfaceReady: _active.surfaceReady,
      hasEngine: _active.engine != null,
      hasLoadedPlay: _active.engine?.currentPlay != null,
      loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
        _active.engine?.currentPlay,
      ),
    )) {
      await resumeBoundActive(
        feed: feed,
        playbackId: dramaId,
        refreshCookies: false,
        forceUnmute: true,
        generation: generation,
      );
      return;
    }

    _clearNeighborIdentityIfPlayback(dramaId);
    final startAt = _peekOcclusionResumeStartAt(dramaId);
    // Swiping to another card must not keep a teardown resume for the old one.
    if (_occlusionResumePlaybackId != null &&
        _occlusionResumePlaybackId != dramaId) {
      _clearOcclusionResume();
    }
    if (startAt == null) {
      _duration = Duration.zero;
      _progressPosition.value = Duration.zero;
      _clearProgressFloor();
    } else {
      // Keep duration + bar at the pre-nav position while cold-loading.
      // Without duration the slider pins to 0 even when position is held.
      final heldDur = _occlusionResumeDuration;
      if (_duration <= Duration.zero &&
          heldDur != null &&
          heldDur > Duration.zero) {
        _duration = heldDur;
      }
      _progressPosition.value = startAt;
      _progressFloor = startAt;
      // Neighbor loadUrl on iOS pauses Active — give remount resume time to
      // settle before warming Next/Prev (avoids 8s preload timeout + silence).
      _suppressNeighborWarmUntil = DateTime.now().add(
        const Duration(seconds: 3),
      );
    }
    _playbackFailed = false;
    _isPlaying = false;
    // Poster stays up for the whole cold load — clear any stale latch from a
    // previous paint of this drama (e.g. auth rebind).
    _surfaces.coverRevealLatchedPlaybackId = null;
    // Only reset auth-recovery state when binding a *different* drama.
    // Keeping the marker while rebinding the same drama after a recovery
    // prevents a second recovery attempt if the rebind also fails.
    if (_authRecoveryDramaId != dramaId) {
      _authRecoveryInFlight = false;
      _authRecoveryDramaId = null;
    }

    // Neighbor loadUrl pauses the active AVPlayer on iOS. Drop in-flight
    // silent loads before replacing the active item.
    _relinquishNeighborSlots();

    // Save the previous playbackId before _prepareSlot retargets it.
    // After teardown (e.g. notification route occlusion), _prepareSlot always
    // creates / re-initializes the engine so isNativeInitialized becomes true.
    // Comparing with the old playbackId lets us distinguish a genuine drama
    // switch from a same-drama restore.
    final previousPlaybackId = _active.playbackId;

    final engine = await _prepareSlot(
      slot: _active,
      playbackId: dramaId,
      bindWorkId: item.bindWorkId,
      index: feed.currentIndex,
      coordinator: NativeVideoPlayerCoordinator.recommendInstance,
      tag: 'Recommend',
      generation: generation,
      currentGeneration: () => _playback.playGeneration,
    );
    if (engine == null || !_bindStillCurrent(feed, generation)) {
      return;
    }
    // Keep the poster up while this slot still holds the previous item.
    // `_prepareSlot` retargets dramaId + surfaceReady immediately.
    if (!await _flushSlotReadyForPlay(
      _active,
      feed.currentIndex,
      feed,
      generation,
    )) {
      return;
    }
    _wireEngineCallbacks(engine, generation);

    final resolved = await FeedMediaLoad.resolveHttpEpisodeData(
      engine: engine,
      play: play,
      episodeNo: episodeNo,
      shouldContinue: _bindContinue(feed, generation),
      peekCachedPlay: (ep) async {
        final id = item.dramaId.trim();
        if (id.isEmpty) return null;
        return ref.read(dramaRepositoryProvider).peekPrefetchedEpisode(id, ep);
      },
      logTag: 'Rec',
      logRejectedUrl: true,
    );
    if (!resolved.hasData) {
      if (resolved.rejectedUrl &&
          _bindStillCurrent(feed, generation) &&
          !_shouldSuppressPlaybackErrorToast()) {
        _showPlaybackErrorToast();
      }
      return;
    }
    final data = resolved.data!;

    StoryLogger.d(
      'Recommend load drama=$dramaId ep=$episodeNo url=${data.url} '
      'cookies=${data.play.hasUsableSignedCookies}',
      tag: 'Rec',
    );

    final ok = await FeedMediaLoad.applyColdPlayback(
      engine: engine,
      data: data,
      episodeNo: episodeNo,
      isSwitch:
          engine.isNativeInitialized &&
          previousPlaybackId != null &&
          previousPlaybackId != dramaId,
      shouldContinue: _bindContinue(feed, generation),
      startAt: startAt,
    );
    if (!ok || !_bindStillCurrent(feed, generation)) {
      if (_bindStillCurrent(feed, generation) &&
          !ok &&
          !_shouldSuppressPlaybackErrorToast()) {
        _showPlaybackErrorToast();
      }
      return;
    }
    // Prefer the real playhead; if native still reports 0, keep startAt so the
    // bar does not snap to the head when we drop the occlusion latch.
    final playhead = engine.positionNotifier.value;
    if (playhead > Duration.zero) {
      _progressPosition.value = playhead;
    } else if (startAt != null && startAt > Duration.zero) {
      _progressPosition.value = startAt;
    }
    if (engine.duration > Duration.zero) {
      _duration = engine.duration;
    }
    if (startAt != null) {
      _clearOcclusionResume(onlyIfPlaybackId: dramaId);
    }

    // applyPlayback waits for a frame; only then drop the poster.
    _active.frameReady = engine.hasPresentedFirstFrame;
    _latchCoverRevealIfPainted(dramaId);
    if (mounted) setState(() {});
    _warmDiskSkippingNativeSlots();

    await _finalizeActiveSession(feed);
  }

  void _clearNeighborIdentityIfPlayback(String playbackId) {
    for (final slot in [_next, _prev]) {
      if (slot.playbackId != playbackId) continue;
      slot.playbackId = null;
      slot.index = null;
      slot.frameReady = false;
    }
    if (_next.playbackId == null) _playback.neighbors.nextReady = null;
    if (_prev.playbackId == null) _playback.neighbors.prevReady = null;
  }

  void _relinquishNeighborSlots() {
    _playback.relinquishNeighborMarkers();
    for (final slot in [_next, _prev]) {
      try {
        slot.engine?.forceAbandonPendingLoad();
      } catch (_) {}
      unawaited(FeedMediaLoad.silenceBestEffort(slot.engine));
      slot.engine?.relinquishControllerOwnership();
      slot
        ..playbackId = null
        ..index = null
        ..frameReady = false;
    }
    if (mounted) setState(() {});
  }

  Set<String> get _nativeSlotPlaybackIds => {
    if (_active.playbackId != null) _active.playbackId!,
    if (_next.playbackId != null) _next.playbackId!,
    if (_prev.playbackId != null) _prev.playbackId!,
  };

  void _warmDiskSkippingNativeSlots() {
    _ctrl.warmNeighborsAfterFirstFrame(skipDramaIds: _nativeSlotPlaybackIds);
  }

  void _maintainNeighbors(int currentIndex) {
    // A fresh maintain supersedes any deferred retry for this card.
    _cancelDeferredNeighborWarm();
    // Neighbor Platform Views attach only after the active slot's first frame
    // (same gate as [VideoFeedPage._mountNeighborSurfaces]).
    if (!_surfaces.mountNeighborSurfaces) {
      return;
    }
    final suppressUntil = _suppressNeighborWarmUntil;
    if (suppressUntil != null) {
      if (DateTime.now().isBefore(suppressUntil)) {
        final remaining = suppressUntil.difference(DateTime.now());
        unawaited(() async {
          await Future<void>.delayed(remaining);
          if (!mounted) return;
          final live = ref.read(recommendFeedControllerProvider);
          if (live.currentIndex != currentIndex) return;
          _maintainNeighbors(currentIndex);
        }());
        return;
      }
      _suppressNeighborWarmUntil = null;
    }
    // Do not overlap neighbor decode with an unsettled active load — shared
    // CloudFront / AVPlayer contention shows up as no-frame + 8s timeouts.
    final activeReady =
        _active.frameReady || (_active.engine?.hasPresentedFirstFrame ?? false);
    if (!activeReady || (_active.engine?.hasPendingLoad ?? false)) {
      return;
    }
    _playback.neighbors.bumpGeneration(isNext: true);
    _playback.neighbors.bumpGeneration(isNext: false);

    // Prefer the swipe direction so weak-net bandwidth feeds the slot the
    // user is actually approaching. Reverse side: WiFi only, and only after
    // the primary neighbor finishes (never parallel loadUrl — that pauses /
    // starves Active twice in a row).
    final preferForward = _preferForwardNeighbor ?? true;
    final isWifi = ref.read(connectivityProvider).isWifi;

    unawaited(() async {
      if (preferForward) {
        await _startNeighborPreload(
          index: currentIndex + 1,
          coordinator: NativeVideoPlayerCoordinator.recommendPreloadInstance,
          tag: 'Recommend.Next',
          isNext: true,
        );
        if (!isWifi || !mounted) return;
        await _startNeighborPreload(
          index: currentIndex - 1,
          coordinator: NativeVideoPlayerCoordinator.recommendPrevInstance,
          tag: 'Recommend.Prev',
          isNext: false,
          extraDelay: StoryDurations.adjacentPreloadReverseExtra,
        );
      } else {
        await _startNeighborPreload(
          index: currentIndex - 1,
          coordinator: NativeVideoPlayerCoordinator.recommendPrevInstance,
          tag: 'Recommend.Prev',
          isNext: false,
        );
        if (!isWifi || !mounted) return;
        await _startNeighborPreload(
          index: currentIndex + 1,
          coordinator: NativeVideoPlayerCoordinator.recommendPreloadInstance,
          tag: 'Recommend.Next',
          isNext: true,
          extraDelay: StoryDurations.adjacentPreloadReverseExtra,
        );
      }
    }());
  }

  Future<void> _startNeighborPreload({
    required int index,
    required NativeVideoPlayerCoordinator coordinator,
    required String tag,
    required bool isNext,
    Duration extraDelay = Duration.zero,
  }) async {
    if (!mounted || !_isPlaybackVisible || !_surfaces.mountNeighborSurfaces) {
      return;
    }
    final markers = _playback.neighbors;
    markers.setTargetIndex(index, isNext: isNext);
    final generation = markers.generation(isNext: isNext);
    await Future<void>.delayed(
      StoryDurations.adjacentPreloadAfterPlaying + extraDelay,
    );
    if (!_neighborPreloadStillValid(
      isNext: isNext,
      index: index,
      generation: generation,
    )) {
      return;
    }

    // Neighbor loadUrl can pause / starve Active. Wait until Active is
    // actually playing and not mid-buffer before touching the second player.
    // Abort (do not loadUrl) if the warm was superseded or Active never
    // settled — retry comes from the next [_maintainNeighbors].
    bool stillValid() => _neighborPreloadStillValid(
      isNext: isNext,
      index: index,
      generation: generation,
    );
    final activeStable = await _waitForActiveStableForNeighborLoad(
      stillValid: stillValid,
    );
    if (!activeStable || !stillValid()) {
      // Timed out waiting for Active — schedule one deferred maintain so the
      // neighbor slot is not left empty for the rest of this card. Superseded
      // warms (stillValid false) must not reschedule.
      if (stillValid()) {
        final feed = ref.read(recommendFeedControllerProvider);
        _scheduleDeferredNeighborWarm(feed.currentIndex);
      }
      return;
    }

    final slot = isNext ? _next : _prev;
    if (index < 0) {
      slot
        ..playbackId = null
        ..index = null
        ..frameReady = false;
      if (mounted) setState(() {});
      return;
    }

    final items = ref.read(recommendFeedControllerProvider).items;
    if (index >= items.length) return;
    var item = items[index];
    if (!item.hasPlayableIdentity) return;
    if (_ctrl.isUntranscoded(item)) return;
    final inflightReady = markers.ready(isNext: isNext);
    if (FeedPlaybackPolicy.shouldSkipNeighborPreload(
      slotPlaybackId: slot.playbackId,
      itemPlaybackId: item.playbackId,
      loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
        slot.engine?.currentPlay,
      ),
      frameReady: slot.frameReady,
      hasPendingLoad: slot.engine?.hasPendingLoad ?? true,
      hasInflightReady: inflightReady != null && !inflightReady.isCompleted,
    )) {
      return;
    }

    int currentGen() => markers.generation(isNext: isNext);
    bool stillThisNeighbor() => _neighborPreloadStillValid(
      isNext: isNext,
      index: index,
      generation: generation,
      slot: slot,
    );

    final play = await _ctrl.resolvePlayForIndex(index);
    if (play == null || !stillThisNeighbor()) return;
    final resolvedItems = ref.read(recommendFeedControllerProvider).items;
    if (index >= resolvedItems.length) return;
    item = resolvedItems[index];

    final ready = Completer<bool>();
    markers.setReady(ready, isNext: isNext);

    var success = false;
    try {
      final engine = await _prepareSlot(
        slot: slot,
        playbackId: item.playbackId,
        bindWorkId: item.bindWorkId,
        index: index,
        coordinator: coordinator,
        tag: tag,
        generation: generation,
        currentGeneration: currentGen,
        allowActive: false,
      );
      if (engine == null || !stillThisNeighbor()) {
        return;
      }
      // Neighbor engines use a minimal listener that only logs errors
      // and handles frame rendering. State updates are suppressed.
      engine.listener = NeighborEngineListener(
        tag: tag,
        onFrameRenderedCallback:
            (engine, {required isFirstFrame, required renderedAt}) {
              if (!stillThisNeighbor()) return;
              if (!identical(engine, slot.engine)) return;
              if (!mounted) return;
              if (RecommendFeedItem.playbackIdOfPlay(engine.currentPlay) !=
                  item.playbackId) {
                return;
              }
              if (!slot.frameReady) {
                slot.frameReady = true;
                _notifyCoverReveal();
              }
              unawaited(_captureFirstFrame(slot, _frameCacheKeyFor(item)));
            },
      );

      final episodeNo = RecommendFeedController.episodeNoOf(item);
      final resolved = await FeedMediaLoad.resolveHttpEpisodeData(
        engine: engine,
        play: play,
        episodeNo: episodeNo,
        shouldContinue: stillThisNeighbor,
        peekCachedPlay: (ep) async {
          final id = item.dramaId.trim();
          if (id.isEmpty) return null;
          return ref.read(dramaRepositoryProvider).peekPrefetchedEpisode(id, ep);
        },
        logTag: 'Rec',
      );
      final data = resolved.data;
      if (data == null || !stillThisNeighbor()) {
        return;
      }

      final outcome = await FeedMediaLoad.preloadNeighbor(
        engine: engine,
        data: data,
        episodeNo: data.play.episodeNo ?? episodeNo,
        shouldContinue: stillThisNeighbor,
        armLoadGuard: _armNeighborLoadGuard,
        // Always skip mute-play prime here: [_waitForActiveStableForNeighborLoad]
        // only proceeds while Active is playing (or user-paused), and priming
        // another decoder fights the shared AVPlayer/ExoPlayer path. Swipe
        // covers rely on JPEG / poster instead.
        shouldPrimeFrame: () => false,
      );
      success = outcome.loadOk;
      if (!stillThisNeighbor()) return;
      if (outcome.frameReady) {
        slot.frameReady = true;
        _notifyCoverReveal();
        unawaited(_captureFirstFrame(slot, _frameCacheKeyFor(item)));
      }
      StoryLogger.d(
        '$tag drama=${item.dramaId} ok=$success frame=${slot.frameReady}',
        tag: 'Rec',
      );
    } catch (e) {
      StoryLogger.d('$tag failed', error: e, tag: 'Rec');
    } finally {
      final shouldClearSlot = markers.finishReady(
        ready,
        isNext: isNext,
        success: success,
      );
      // Drop sticky failed identity so `_maintainNeighbors` can retry.
      if (shouldClearSlot && slot.playbackId == item.playbackId) {
        slot
          ..playbackId = null
          ..index = null
          ..frameReady = false;
        if (mounted) setState(() {});
      }
      _armNeighborLoadGuard();
      // First settle covers the common iOS pause-during-loadUrl. A short
      // follow-up catches late pauses that land after the first restore
      // early-out ("already playing").
      unawaited(() async {
        await _restoreActiveAfterNeighborLoad();
        if (!mounted) return;
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!mounted) return;
        await _restoreActiveAfterNeighborLoad();
      }());
    }
  }

  bool _neighborPreloadStillValid({
    required bool isNext,
    required int index,
    required int generation,
    FeedSlot? slot,
  }) {
    if (!mounted || !_isPlaybackVisible) return false;
    final markers = _playback.neighbors;
    if (generation != markers.generation(isNext: isNext)) {
      return false;
    }
    if (markers.targetIndex(isNext: isNext) != index) {
      return false;
    }
    final current = isNext ? _next : _prev;
    if (identical(current, _active)) return false;
    if (slot != null && !identical(slot, current)) return false;
    return true;
  }

  /// Blocks neighbor [loadUrl] until Active looks settled, so iOS pause /
  /// Android buffer-steal hits a quieter window.
  ///
  /// Returns `true` when it is safe to start neighbor loadUrl.
  /// Returns `false` on superseded warm ([stillValid]), hidden feed, or
  /// timeout — caller must **abort** (do not loadUrl on a busy Active).
  ///
  /// User pause / ended: Active is not decoding a live stream, so neighbor
  /// warm may proceed (still gated by [stillValid]).
  Future<bool> _waitForActiveStableForNeighborLoad({
    required bool Function() stillValid,
  }) async {
    const timeout = Duration(milliseconds: 2500);
    const poll = Duration(milliseconds: 100);
    const settle = Duration(milliseconds: 180);
    final deadline = DateTime.now().add(timeout);
    while (mounted && DateTime.now().isBefore(deadline)) {
      if (!stillValid()) return false;
      if (!_isPlaybackVisible) return false;
      final feed = ref.read(recommendFeedControllerProvider);
      if (feed.isUserPaused || _ended) {
        return stillValid();
      }
      final engine = _active.engine;
      final stable =
          _isPlaying &&
          engine != null &&
          engine.isPlaying &&
          !engine.isBuffering &&
          !engine.hasPendingLoad;
      if (stable) {
        await Future<void>.delayed(settle);
        if (!mounted || !stillValid()) return false;
        final again = _active.engine;
        if (_isPlaying &&
            again != null &&
            again.isPlaying &&
            !again.isBuffering &&
            !again.hasPendingLoad) {
          return true;
        }
      }
      await Future<void>.delayed(poll);
    }
    if (mounted && stillValid()) {
      StoryLogger.d(
        'neighbor warm aborted: active not stable within ${timeout.inMilliseconds}ms',
        tag: 'Rec',
      );
    }
    return false;
  }

  /// One-shot retry of [_maintainNeighbors] after Active failed to go stable
  /// in time. Generation + index guarded so a swipe cancels the retry.
  void _scheduleDeferredNeighborWarm(int currentIndex) {
    if (!mounted || !_isPlaybackVisible) return;
    if (_deferredNeighborWarmTimer != null &&
        _deferredNeighborWarmIndex == currentIndex &&
        _deferredNeighborWarmPlayGen == _playback.playGeneration) {
      return;
    }
    _deferredNeighborWarmTimer?.cancel();
    _deferredNeighborWarmIndex = currentIndex;
    _deferredNeighborWarmPlayGen = _playback.playGeneration;
    StoryLogger.d(
      'neighbor warm deferred: retry maintain at index=$currentIndex',
      tag: 'Rec',
    );
    _deferredNeighborWarmTimer = Timer(
      StoryDurations.adjacentPreloadAfterPlaying,
      () {
        _deferredNeighborWarmTimer = null;
        if (!mounted || !_isPlaybackVisible) return;
        if (_deferredNeighborWarmPlayGen != _playback.playGeneration) return;
        final feed = ref.read(recommendFeedControllerProvider);
        if (feed.currentIndex != currentIndex) return;
        if (feed.isUserPaused || _ended) return;
        _maintainNeighbors(currentIndex);
      },
    );
  }

  void _cancelDeferredNeighborWarm() {
    _deferredNeighborWarmTimer?.cancel();
    _deferredNeighborWarmTimer = null;
    _deferredNeighborWarmIndex = null;
    _deferredNeighborWarmPlayGen = -1;
  }

  /// Move [slot] onto [index] and wait two frames so Positioned layout
  /// (and the PageView cover hole) apply before play()/readyForDisplay.
  Future<void> _flushSlotToPage(FeedSlot slot, int index) async {
    if (!mounted) return;
    slot.index = index;
    setState(() {});
    Future<void> waitFrame() async {
      try {
        await WidgetsBinding.instance.endOfFrame.timeout(
          const Duration(milliseconds: 500),
        );
      } on TimeoutException {
        StoryLogger.d('endOfFrame timed out before recommend play', tag: 'Rec');
      }
    }

    await waitFrame();
    if (!mounted) return;
    await waitFrame();
  }

  /// play() on an off-screen AVPlayerLayer ACKs while staying paused — then
  /// `_kickPlayIfStillPaused` steals the decoder from the visible card.
  bool _slotNearOnScreen(FeedSlot slot) {
    final index = slot.index;
    if (index == null || !_pageController.hasClients) return true;
    final page = _pageController.page ?? index.toDouble();
    return (page - index).abs() <= 0.22;
  }

  Future<void> _waitUntilSlotOnScreen(FeedSlot slot) async {
    if (_slotNearOnScreen(slot)) return;
    final deadline = DateTime.now().add(const Duration(milliseconds: 450));
    while (mounted && DateTime.now().isBefore(deadline)) {
      if (_slotNearOnScreen(slot)) return;
      try {
        await WidgetsBinding.instance.endOfFrame.timeout(
          const Duration(milliseconds: 80),
        );
      } on TimeoutException {
        break;
      }
    }
  }

  // ─── FeedSlotPrepareHost ───────────────────────────────────

  @override
  NativeVideoPlayerController createNativeController() {
    return NativeVideoPlayerController(
      id: _nextPlayerId(),
      showNativeControls: false,
    );
  }

  @override
  PlaybackEngine createEngine({
    required String bindWorkId,
    required String tag,
    required NativeVideoPlayerCoordinator coordinator,
  }) {
    return PlaybackEngine(
      dramaRepo: ref.read(dramaRepositoryProvider),
      localRepo: ref.read(localRepositoryProvider),
      cloudfront: ref.read(cloudfrontCookieServiceProvider),
      dramaId: bindWorkId,
      tag: tag,
      restoreWatchProgress: false,
      coordinator: coordinator,
      cookieFamily: CloudFrontCookieFamily.recommend,
      isCellular: () => ref.read(connectivityProvider).isCellular,
    );
  }

  @override
  void notifySlotChanged() {
    _slotRevision.value++;
  }

  void _notifyCoverReveal() {
    _coverRevision.value++;
  }

  @override
  void invalidateSurfaceCache(NativeVideoPlayerController native) {
    _surfaceCache.remove(native);
  }

  /// Create the native slot once. [playbackId] keys slot identity
  /// (`dramaId:episodeId`); [bindWorkId] is the API / engine work id.
  Future<PlaybackEngine?> _prepareSlot({
    required FeedSlot slot,
    required String playbackId,
    required String bindWorkId,
    required int index,
    required NativeVideoPlayerCoordinator coordinator,
    required String tag,
    required int generation,
    required int Function() currentGeneration,
    bool allowActive = true,
  }) {
    return _slotPreparer.prepare(
      slot: slot,
      playbackId: playbackId,
      bindWorkId: bindWorkId,
      index: index,
      coordinator: coordinator,
      tag: tag,
      role: identical(slot, _active)
          ? PlaybackEngineRole.active
          : PlaybackEngineRole.preload,
      looping: FeedPlaybackPolicy.shouldUseNativeLoop(
        autoPlayEnabled: _ctrl.autoPlayEnabled,
        duration: slot.engine?.duration ?? _duration,
      ),
      generation: generation,
      currentGeneration: currentGeneration,
      allowSlot: (s) => _slotAllowed(s, allowActive),
      logTag: 'Rec',
    );
  }

  /// Latch cover reveal only after a painted frame for [playbackId] that
  /// native has actually loaded — `slot.playbackId` is retargeted before
  /// pixels catch up. Keep latching while user-paused so the native surface
  /// stays uncovered and holds the last decoded frame.
  void _latchCoverRevealIfPainted(String? playbackId) {
    if (playbackId == null) return;
    if (!_nativeSurfacesMounted) return;
    if (_active.playbackId != playbackId) return;
    if (RecommendFeedItem.playbackIdOfPlay(_active.engine?.currentPlay) !=
        playbackId) {
      return;
    }
    if (_active.engine?.hasPendingLoad ?? true) return;
    final painted =
        _active.frameReady || (_active.engine?.hasPresentedFirstFrame ?? false);
    if (!painted) return;
    if (!_active.frameReady) {
      _active.frameReady = true;
    }
    _surfaces.coverRevealLatchedPlaybackId = playbackId;
  }

  /// Always return the current feed item for sheet / header affordances.
  ///
  /// Previously this looked up the engine's [PlaybackEngine.currentPlay] to
  /// prefer the natively loaded card during early-activate. However, during
  /// rapid swipe → navigate-away → return → swipe, the engine may still hold
  /// a stale play while [RecommendFeedState.currentIndex] has advanced,
  /// causing chrome (title, cover, episode) to mismatch the displayed page.
  RecommendFeedItem? _chromeItemFor(RecommendFeedState feed) =>
      feed.currentItem;

  /// 首帧缓存统一 key —— 与短剧播放页使用同一 `frameCacheKey` 构造规则，
  /// 保证同一剧集 / 短视频跨入口共享首帧。不得改用 `item.playbackId`：
  /// 其短剧无 episodeId 分支为 `drama:episode:N`，与短剧页的
  /// `drama_ep$episodeNo` 不一致，会导致同一集缓存 miss。
  String _frameCacheKeyFor(RecommendFeedItem item) =>
      PlaybackFrameCacheService.frameCacheKey(
        dramaId: item.dramaId,
        episodeId: item.episodeId,
        episodeNo: item.resolvedEpisodeNo,
      );

  Future<void> _captureFirstFrame(FeedSlot slot, String playbackId) =>
      _frameManager.capture(slot, playbackId);

  void _onFrameCacheRevision() {
    if (!mounted) return;
    final feed = ref.read(recommendFeedControllerProvider);
    _frameManager.onRevision(feed.items.map(_frameCacheKeyFor));
  }

  void _wireEngineCallbacks(PlaybackEngine engine, int generation) {
    _engineBridge.attach(engine, generation);
    _attachProgressMirror(engine);
    if (engine.duration > Duration.zero) {
      _duration = engine.duration;
    }
  }

  @override
  bool isGenerationCurrent(int generation) => _engineGenAlive(generation);

  @override
  void onEngineDurationChanged(
    PlaybackEngine engine,
    int generation,
    Duration d,
  ) {
    _duration = d;
    _syncLooping();
  }

  @override
  void onEnginePlayingChanged(
    PlaybackEngine engine,
    int generation,
    bool playing,
  ) {
    // Update before unexpected-pause recovery so onGuardSkip sees the real
    // paused flag (neighbor loadUrl often pauses Active while the guard is armed).
    _isPlaying = playing;
    if (playing) {
      _ended = false;
      _recovery.notifyPlaybackStarted();
      _playbackFailed = false;
      _clearPlaybackErrorToastDebounce();
      // Only arm once per card — resetting on every playing=true makes a
      // real short-clip EOS look freshly armed and get dropped.
      _playbackArmedAt ??= DateTime.now();
      _ctrl.onEpisodeMetricsPlayStart();
    } else if (!_ended && !engine.hasCompleted) {
      _maybeRecoverUnexpectedPause(generation);
      _ctrl.onEpisodeMetricsPause();
    }
  }

  @override
  void onEnginePositionUpdate(
    PlaybackEngine engine,
    int generation,
    int positionMs,
    int durationMs,
  ) {
    if (!identical(engine, _active.engine)) return;
    if (durationMs > 0) {
      final next = Duration(milliseconds: durationMs);
      if (_duration != next) _duration = next;
    }
    _maybeRecoverFrameStall(engine, generation);
    // Soft resume / promote can play without a fresh `playing` activity
    // event — metrics stay paused after leave and never accumulate 有效播放.
    if (engine.isPlaying || _isPlaying) {
      _ctrl.onEpisodeMetricsPlayStart();
    }
    // Position ticks often arrive with duration=0 before metadata; fall back
    // to the UI duration so early watch seconds are not discarded.
    final metricsDurMs =
        durationMs > 0 ? durationMs : _duration.inMilliseconds;
    _ctrl.onEpisodeMetricsTimeUpdate(positionMs, metricsDurMs);
    _ctrl.maybeTrackWatchHistory(positionMs);
  }

  @override
  void onEngineCompleted(PlaybackEngine engine, int generation) {
    if (!identical(engine, _active.engine)) {
      StoryLogger.d(
        'drop completed reason=notActiveEngine tag=${engine.tag} '
        'activeTag=${_active.engine?.tag} '
        'pos=${engine.position.inMilliseconds} '
        'dur=${engine.duration.inMilliseconds}',
        tag: 'play-report-api',
      );
      return;
    }
    // Route / tab / teardown can emit completed while surfaces are gone.
    // Do not report complete or advance underneath an occluding page.
    if (!FeedPlaybackPolicy.shouldAcceptNaturalComplete(
      isPlaybackVisible: _isPlaybackVisible,
    )) {
      StoryLogger.d(
        'drop completed reason=notVisible '
        'drama=${_active.playbackId} '
        'kind=${_visibilityKind.name} '
        'pos=${engine.position.inMilliseconds} '
        'dur=${engine.duration.inMilliseconds}',
        tag: 'play-report-api',
      );
      return;
    }
    final action = FeedEngineCompletionHandler.decide(
      engine: engine,
      playbackArmedAt: _playbackArmedAt,
      autoPlayEnabled: _ctrl.autoPlayEnabled,
      overlayHoldsAdvance: _ctrl.overlayHoldsAdvance,
    );
    if (action == FeedCompletionAction.ignore) {
      StoryLogger.w(
        'drop completed reason=spurious '
        'drama=${_active.playbackId} '
        'pos=${engine.position.inMilliseconds} '
        'dur=${engine.duration.inMilliseconds} '
        'firstFrame=${engine.hasPresentedFirstFrame}',
        tag: 'play-report-api',
      );
      if (!engine.hasPresentedFirstFrame) {
        _showPlaybackErrorToast();
      }
      return;
    }
    // Ensure metrics session is armed even if playing event was missed.
    _ctrl.onEpisodeMetricsPlayStart();
    if (action == FeedCompletionAction.loopInPlace) {
      unawaited(_onPlaybackCompleted());
      return;
    }
    _ended = true;
    _isPlaying = false;
    unawaited(_onPlaybackCompleted());
  }

  @override
  void onEnginePlaybackFailure(
    PlaybackEngine engine,
    int generation,
    Object error, {
    required bool isSwitch,
  }) {
    if (!identical(engine, _active.engine)) return;
    _playbackFailed = true;
    final failure = FeedPlaybackPolicy.classifyFailure(error);
    StoryLogger.w(
      'Recommend playback failure failure=${failure.name} '
      'url=${engine.playbackUrl ?? ''} '
      'drama=${_active.playbackId} reason=$error',
      error: error,
      tag: 'Rec',
    );
    final dramaId = _active.playbackId;
    // Cookie refresh only helps CDN 403. Unsigned cookies=false noFrame is a
    // surface/startup race — auth recovery just rebinds the same URL after an
    // extra detail GET.
    if (FeedPlaybackPolicy.shouldAttemptAuthRecovery(failure) &&
        dramaId != null &&
        _authRecoveryDramaId != dramaId) {
      unawaited(_recoverFromAuthFailure(generation, dramaId));
      return;
    }
    // noFrame after loadUrl budget: same survival path as buffering timeout
    // (cold reload → seek-kick → toast).
    if (failure == PlaybackFailureReason.noFrame) {
      unawaited(_recoverFromBufferingTimeout(generation));
      return;
    }
    // When a recovery is already in-flight (or this failure happens during
    // a fast swipe transition), suppress immediate toast spam. The next
    // rebind/recovery attempt will either succeed or eventually hit the
    // non-recoverable path.
    if (_authRecoveryInFlight || isSwitch) return;
    if (_shouldSuppressPlaybackErrorToast()) return;
    _showPlaybackErrorToast();
  }

  @override
  void onEngineError(PlaybackEngine engine, int generation, Object error) {
    if (!identical(engine, _active.engine)) return;
    _playbackFailed = true;
    final failure = FeedPlaybackPolicy.classifyFailure(error);
    StoryLogger.w(
      'Recommend playback error failure=${failure.name} '
      'url=${engine.playbackUrl ?? ''} '
      'drama=${_active.playbackId} reason=$error',
      error: error,
      tag: 'Rec',
    );
    // Bump revision so the chrome rebuilds and the error overlay becomes
    // visible — without this the UI stays stuck on the black native surface.
    _slotRevision.value++;
    if (FeedEngineCompletionHandler.isBufferingTimeout(error)) {
      unawaited(_recoverFromBufferingTimeout(generation));
      return;
    }
    if (_shouldSuppressPlaybackErrorToast()) return;
    _showPlaybackErrorToast();
  }

  @override
  void onEngineFrameRendered(
    PlaybackEngine engine,
    int generation, {
    required bool isFirstFrame,
    required DateTime renderedAt,
  }) {
    if (!identical(engine, _active.engine)) return;
    final dramaId = _active.playbackId;
    final playId = RecommendFeedItem.playbackIdOfPlay(engine.currentPlay);
    // Stale frames from the previous card must not latch the new cover.
    if (dramaId == null ||
        playId == null ||
        playId != dramaId ||
        (engine.hasPendingLoad)) {
      return;
    }
    _lastFrameRenderedAt = renderedAt;
    _lastFrameDramaId = dramaId;
    _recovery.notifyFrameRendered();
    _clearPlaybackErrorToastDebounce();
    final feed = ref.read(recommendFeedControllerProvider);
    final frameKey = feed.currentItem == null
        ? null
        : _frameCacheKeyFor(feed.currentItem!);
    if (!_active.frameReady) {
      _active.frameReady = true;
      _ctrl.reportRecommendFirstFrameTelemetry();
      _latchCoverRevealIfPainted(dramaId);
      _notifyCoverReveal();
      if (frameKey != null) {
        unawaited(_captureFirstFrame(_active, frameKey));
      }
      _surfaces.scheduleNeighborMountAfterFirstFrame(
        warmEntry: _next.frameReady || _prev.frameReady,
        stillNeeded: () => mounted && _nativeSurfacesMounted,
        onMount: _onNeighborSurfacesMounted,
      );
      // Recommend UI keeps the poster until this callback. Post-frame
      // unmute so the UI has actually committed the cover removal before
      // audio starts.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (generation != _playback.playGeneration) return;
        if (!identical(engine, _active.engine)) return;
        if (RecommendFeedItem.playbackIdOfPlay(engine.currentPlay) !=
            _active.playbackId) {
          return;
        }
        unawaited(engine.setVolume(1.0));
      });
    }
  }

  void _armNeighborLoadGuard() => _playback.armNeighborLoadGuard();

  Future<void> _restoreActiveAfterNeighborLoad() async {
    final restoreGen = ++_playback.binds.neighborRestoreGeneration;
    final playGen = _playback.playGeneration;
    _armNeighborLoadGuard();
    await Future<void>.delayed(FeedPlaybackPolicy.neighborLoadGuard);
    if (restoreGen != _playback.binds.neighborRestoreGeneration) return;
    if (playGen != _playback.playGeneration) return;
    if (!mounted || !_isPlaybackVisible) return;
    if (_next.engine?.hasPendingLoad == true ||
        _prev.engine?.hasPendingLoad == true) {
      unawaited(_restoreActiveAfterNeighborLoad());
      return;
    }
    final feed = ref.read(recommendFeedControllerProvider);
    if (feed.isUserPaused ||
        _ended ||
        _volumeDucked ||
        _playback.bindRunning) {
      return;
    }
    if (_playbackFailed) return;
    final engine = _active.engine;
    if (engine == null || engine.hasCompleted) return;
    if (!FeedPlaybackPolicy.canResumeBoundSlot(
      slotPlaybackId: _active.playbackId,
      itemPlaybackId: feed.currentItem?.playbackId ?? '',
      surfaceReady: _active.surfaceReady,
      hasEngine: true,
      hasLoadedPlay: engine.currentPlay != null,
      loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
        engine.currentPlay,
      ),
    )) {
      return;
    }
    // Already playing — nothing to restore. Do not bail on a stale buffering
    // flag: neighbor loadUrl often leaves Active paused with buffering=true.
    if (_isPlaying && engine.isPlaying) return;
    final native = engine.nativeController ?? _active.native;
    if (native != null && !native.hasPlatformView) return;
    StoryLogger.d(
      'restore Active after neighbor load '
      '(flutterPlaying=$_isPlaying nativePlaying=${engine.isPlaying})',
      tag: 'Rec',
    );
    final ok = await engine.startPlayback();
    if (!_isPlaybackVisible) {
      _pauseBecauseHidden();
      return;
    }
    if (ok && mounted && !feed.isUserPaused && !_ended) {
      _isPlaying = true;
      StoryLogger.d('restore Active ok', tag: 'Rec');
    }
  }

  void _maybeRecoverUnexpectedPause(int generation) {
    _recovery.maybeRecoverUnexpectedPause(generation: generation);
  }

  void _maybeRecoverFrameStall(PlaybackEngine engine, int generation) {
    _recovery.maybeRecoverFrameStall(generation: generation, engine: engine);
  }

  ({PlaybackEngine? engine, NativeVideoPlayerController? native}) _takeSlot(
    FeedSlot slot,
  ) {
    final engine = slot.engine;
    final native = slot.native;
    if (engine != null) {
      _detachProgressMirrorIfEngine(engine);
      _engineBridge.detach(engine);
    }
    slot.engine = null;
    slot.native = null;
    slot.playbackId = null;
    slot.index = null;
    slot.surfaceReady = false;
    slot.frameReady = false;
    // Remove cached surface — controller is being torn down.
    if (native != null) {
      _surfaceCache.remove(native);
    }
    return (engine: engine, native: native);
  }

  Future<void> _disposeDetachedSlot(
    ({PlaybackEngine? engine, NativeVideoPlayerController? native}) slot,
  ) async {
    final engine = slot.engine;
    final native = slot.native;
    if (engine == null && native == null) return;
    final nativeOwnedByEngine =
        engine != null && identical(engine.nativeController, native);
    try {
      await engine?.disposeAndWait(
        disposeNativeController: nativeOwnedByEngine,
      );
    } catch (e) {
      StoryLogger.d('Recommend engine dispose failed', error: e, tag: 'Rec');
    }
    if (native != null && !nativeOwnedByEngine) {
      try {
        await native.dispose().timeout(StoryConstants.playerControlTimeout);
      } catch (_) {}
    }
  }

  Future<void> _teardownAllPlayers() {
    final pending = _teardownFuture;
    if (pending != null) return pending;
    final future = _runTeardownAllPlayers();
    _teardownFuture = future;
    future.whenComplete(() {
      if (identical(_teardownFuture, future)) {
        _teardownFuture = null;
      }
    });
    return future;
  }

  Future<void> _runTeardownAllPlayers() async {
    _playback.binds.playGeneration++;
    _playback.relinquishNeighborMarkers();
    _playback.binds.queuedBindIndex = null;
    _isPlaying = false;
    _surfaces.coverRevealLatchedPlaybackId = null;
    // Detach all slot references synchronously before the first await so a
    // route-resume callback cannot reuse a half-torn-down neighbor.
    final detachedNext = _takeSlot(_next);
    final detachedPrev = _takeSlot(_prev);
    final detachedActive = _takeSlot(_active);
    _engineBridge.clear();
    _playback.resetRoles();
    // Drop disposed engine notifiers from chrome; keep [_progressPosition] /
    // [_duration] so the bar holds the pre-nav resume point.
    // Skip when [dispose] already ran — notifiers may already be disposed and
    // `mounted` is still true until [State.dispose] finishes.
    if (mounted && !_stateDisposed) {
      _coverRevision.value++;
      _slotRevision.value++;
    }
    NativeVideoPlayerCoordinator.beginTeardown();
    try {
      await _disposeDetachedSlot(detachedActive);
      await _disposeDetachedSlot(detachedNext);
      await _disposeDetachedSlot(detachedPrev);
    } finally {
      NativeVideoPlayerCoordinator.endTeardown();
    }
  }

  /// Playlist / standalone: jump inside the flat PageView when the episode is
  /// already expanded; otherwise fall back to opening [VideoFeedPage].
  Future<void> _jumpToDramaEpisode({
    required RecommendFeedItem item,
    required int episodeNo,
    DramaDetail? detail,
  }) async {
    final dramaId = item.dramaId.trim();
    if (dramaId.isEmpty || episodeNo < 1) return;
    final feed = ref.read(recommendFeedControllerProvider);
    final target = feed.items.indexWhere(
      (it) =>
          !it.workType.isShortVideo &&
          it.dramaId.trim() == dramaId &&
          it.resolvedEpisodeNo == episodeNo,
    );
    if (target >= 0) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(target);
      }
      return;
    }
    await _openFullDrama(item, detail, episodeNo: episodeNo);
  }

  Future<void> _showStandaloneEpisodePicker(
    RecommendFeedItem item,
    DramaDetail? detail,
  ) async {
    final selected = await RecommendFeedSheets.showStandaloneEpisodePicker(
      context: context,
      ref: ref,
      item: item,
      detail: detail,
      onSyncLooping: _syncLooping,
    );
    if (!mounted || selected == null) return;
    await _jumpToDramaEpisode(item: item, episodeNo: selected, detail: detail);
  }

  Future<void> _openFullDrama(
    RecommendFeedItem item,
    DramaDetail? detail, {
    int? episodeNo,
  }) async {
    await _persistActiveWatchProgress();
    await _active.engine?.pause();
    if (!mounted) return;
    await RecommendFeedSheets.openFullDrama(
      context: context,
      ref: ref,
      item: item,
      detail: detail,
      episodeNo: episodeNo,
    );
  }

  Future<void> _showDramaDetailSheet({
    required RecommendFeedItem item,
    DramaDetail? detail,
    required DramaDetailSheetTab tab,
  }) async {
    final selected = await RecommendFeedSheets.showDramaDetailSheet(
      context: context,
      ref: ref,
      item: item,
      detail: detail,
      tab: tab,
      onSyncLooping: _syncLooping,
      playerSheetOpen: _playerSheetOpen,
      playerSheetHeight: _playerSheetHeight,
    );
    if (!mounted) return;
    if (selected != null) {
      if (widget.standalone) {
        await _jumpToDramaEpisode(
          item: item,
          episodeNo: selected,
          detail: detail,
        );
      } else {
        await _openFullDrama(item, detail, episodeNo: selected);
      }
      return;
    }
    if (_ended && _isPlaybackVisible) {
      unawaited(_replayCurrent());
    }
  }

  /// Cookie/auth recovery for recommend: refresh signed play from network and
  /// rebind. Mirrors [FeedRecovery._recoverFromStaleAuthOnce] for short-drama.
  Future<void> _recoverFromAuthFailure(int generation, String dramaId) async {
    if (!_engineGenAlive(generation)) return;
    if (_authRecoveryInFlight) return;
    _authRecoveryInFlight = true;
    _authRecoveryDramaId = dramaId;
    StoryLogger.w(
      'Recommend auth recovery: refresh play drama=$dramaId',
      tag: 'Rec',
    );
    // Cancel neighbor preloads before refresh — otherwise unsigned neighbor
    // loadUrl races the active rebind and both time out with no frame.
    _relinquishNeighborSlots();
    try {
      final play = await _ctrl.refreshCurrentPlay();
      if (!_engineGenAlive(generation)) return;
      if (play == null) {
        _showPlaybackErrorToast();
        return;
      }
      // Clear identity so bindPlayback performs a full reload.
      _active.playbackId = null;
      _active.frameReady = false;
      _surfaces.coverRevealLatchedPlaybackId = null;
      _clearPlaybackErrorToastDebounce();
      _playbackFailed = false;
      if (mounted) setState(() {});
      await bindPlayback(ref.read(recommendFeedControllerProvider));
    } finally {
      _authRecoveryInFlight = false;
    }
  }

  Future<void> _recoverFromBufferingTimeout(int generation) async {
    if (!_engineGenAlive(generation)) return;
    final dramaId = _active.playbackId;
    if (dramaId == null) return;
    if (_bufferingTimeoutDramaId != dramaId) {
      _bufferingTimeoutDramaId = dramaId;
      _bufferingTimeoutRecoveries = 0;
    }
    FeedPlaybackTelemetry.bufferingTimeout(
      feed: 'recommend',
      playbackId: _active.playbackId ?? dramaId,
    );
    // 0 → full reload; 1 → seek-kick; 2+ → toast (weak-net single-card survival).
    if (_bufferingTimeoutRecoveries >= 2) {
      if (_shouldSuppressPlaybackErrorToast()) return;
      _showPlaybackErrorToast();
      return;
    }
    final attempt = _bufferingTimeoutRecoveries;
    _bufferingTimeoutRecoveries++;
    if (attempt == 0) {
      StoryLogger.w(
        'Recommend buffering timeout, reload drama=$dramaId',
        tag: 'Rec',
      );
      try {
        await _next.engine?.pause();
      } catch (_) {}
      try {
        await _prev.engine?.pause();
      } catch (_) {}
      if (!_engineGenAlive(generation)) return;
      await _retryCurrentPlayback();
      return;
    }
    StoryLogger.w(
      'Recommend buffering timeout, seek-kick drama=$dramaId',
      tag: 'Rec',
    );
    final engine = _active.engine;
    if (engine == null || !_engineGenAlive(generation)) return;
    try {
      await engine.nudgeTextureFrame();
      if (!_engineGenAlive(generation)) return;
      await engine.startPlayback();
    } catch (e) {
      StoryLogger.w(
        'Recommend buffering seek-kick failed: $e',
        tag: 'Rec',
      );
    }
  }

  void _clearPlaybackErrorToastDebounce() {
    _lastErrorToastDramaId = null;
    _lastErrorToastAt = null;
    _lastGlobalPlaybackErrorToastAt = null;
  }

  void _showPlaybackErrorToast({bool allowAfterManualRetry = false}) {
    if (!mounted || !_isPlaybackVisible) return;
    final dramaId = _active.playbackId;
    final now = DateTime.now();
    if (!allowAfterManualRetry) {
      if (_lastGlobalPlaybackErrorToastAt != null &&
          now.difference(_lastGlobalPlaybackErrorToastAt!) <
              _playbackErrorToastGlobalGap) {
        return;
      }
      if (dramaId != null &&
          dramaId == _lastErrorToastDramaId &&
          _lastErrorToastAt != null &&
          now.difference(_lastErrorToastAt!) <
              _playbackErrorToastSameDramaGap) {
        return;
      }
    }
    _lastErrorToastDramaId = dramaId;
    _lastErrorToastAt = now;
    _lastGlobalPlaybackErrorToastAt = now;
    final l10n = context.l10n;
    StoryToast.error(
      context,
      l10n.playerPlayFailed,
      actionLabel: l10n.dramaDetailRetry,
      onAction: () => unawaited(_retryCurrentPlayback()),
      rootOverlay: true,
    );
  }

  bool _shouldSuppressPlaybackErrorToast() {
    if (!_isPlaybackVisible) return true;
    if (_authRecoveryInFlight ||
        _playback.manualRetry.inFlight ||
        _playback.bindRunning ||
        _playback.promoteInFlight) {
      return true;
    }
    if (_playback.binds.queuedBindIndex != null ||
        _playback.binds.bindingIndex != null) {
      return true;
    }
    if (neighborLoadGuarded) return true;
    return false;
  }

  Future<void> _retryCurrentPlayback() async {
    if (!mounted || _playback.manualRetry.inFlight) return;
    final expectedFeed = ref.read(recommendFeedControllerProvider);
    final expectedIndex = expectedFeed.currentIndex;
    final expectedWorkId = expectedFeed.currentItem?.bindWorkId;
    final retryGeneration = _playback.manualRetry.begin(
      index: expectedIndex,
      workId: expectedWorkId,
    );
    // User explicitly retried — allow a fresh failure toast if this attempt fails.
    _lastErrorToastAt = null;
    _lastGlobalPlaybackErrorToastAt = null;
    // Force the cold-bind path; resuming the existing native item would keep
    // the stale pipeline that timed out. Neighbors must drop first so their
    // loadUrl cannot race the reload (same as auth recovery).
    _relinquishNeighborSlots();
    _active.playbackId = null;
    _active.frameReady = false;
    _surfaces.coverRevealLatchedPlaybackId = null;
    _active.engine?.invalidateNativeInitialization();
    if (mounted) setState(() {});
    try {
      final play = await _ctrl.refreshCurrentPlay();
      if (!mounted || retryGeneration != _playback.manualRetry.generation) {
        return;
      }
      final liveFeed = ref.read(recommendFeedControllerProvider);
      if (expectedIndex != liveFeed.currentIndex ||
          expectedWorkId != liveFeed.currentItem?.bindWorkId) {
        return;
      }
      if (play == null) {
        // A newer activation may already have restored this same card after
        // an A→B→A swipe while the old retry was pending.
        if (liveFeed.currentPlay == null) {
          _showPlaybackErrorToast(allowAfterManualRetry: true);
        }
        return;
      }
      _clearPlaybackErrorToastDebounce();
      _playbackFailed = false;
      _authRecoveryInFlight = false;
      _authRecoveryDramaId = null;
      // Manual retry owns the cold bind (identity enqueue is suppressed while
      // isPlayLoading). Always bind here — do not rely on the feed listener.
      await bindPlayback(liveFeed);
    } finally {
      _playback.manualRetry.clearIfCurrent(retryGeneration);
    }
  }

  void _togglePlayPause() {
    final willPause = _isPlaying;
    if (willPause) {
      final engine = _active.engine;
      if (engine == null) return;
      // Native pause freezes on the last decoded frame — keep the surface
      // revealed (no JPEG cover / no parking).
      _isPlaying = false;
      _userPaused.value = true;
      _ctrl.setUserPaused(true);
      unawaited(() async {
        await engine.pause();
        await _persistActiveWatchProgress();
      }());
      return;
    }

    final engine = _active.engine;
    if (engine != null && (_ended || engine.hasCompleted)) {
      _ended = false;
      _userPaused.value = false;
      _ctrl.setUserPaused(false);
      unawaited(() async {
        // Lifecycle mute may have left volume at 0 while user-paused.
        await engine.setVolume(1.0, force: true);
        await engine.seekTo(Duration.zero);
        await engine.startPlayback();
        await engine.setVolume(1.0, force: true);
      }());
      return;
    }

    unawaited(() async {
      _volumeDucked = false;
      final feed = ref.read(recommendFeedControllerProvider);
      var activeEngine = _active.engine;
      // Bind while userPaused if the profile/login route tore players down.
      if (activeEngine == null || _activeSlotNeedsRebind(feed)) {
        await bindPlayback(feed);
        activeEngine = _active.engine;
      }
      if (activeEngine == null) return;
      _userPaused.value = false;
      _ctrl.setUserPaused(false);
      await activeEngine.setVolume(1.0, force: true);
      final playing = await activeEngine.togglePlayPause();
      if (playing == true && mounted) {
        _isPlaying = true;
      }
      await activeEngine.setVolume(1.0, force: true);
    }());
  }

  Future<void> _onPlaybackCompleted() async {
    final engine = _active.engine;
    if (engine != null) {
      // Engine duration can still be 0 at completed; fall back to UI duration.
      final engineDur = engine.duration.inMilliseconds;
      final durMs = engineDur > 0 ? engineDur : _duration.inMilliseconds;
      _ctrl.onEpisodeMetricsNaturalEnd(
        engine.position.inMilliseconds,
        durMs,
      );
    }
    if (!mounted) return;
    switch (FeedPlaybackPolicy.decideAdvance(
      autoPlayEnabled: _ctrl.autoPlayEnabled,
      overlayHoldsAdvance: _ctrl.overlayHoldsAdvance,
    )) {
      case FeedAdvanceDecision.advanceNext:
        _ended = true;
        await _advanceToNext();
      case FeedAdvanceDecision.loopCurrent:
        await _replayCurrent();
    }
  }

  Future<void> _replayCurrent() async {
    final engine = _active.engine;
    if (engine == null) return;
    _ended = false;
    _ctrl.setUserPaused(false);
    _volumeDucked = false;
    _clearOcclusionResume(onlyIfPlaybackId: _active.playbackId);
    _clearProgressFloor();
    _progressPosition.value = Duration.zero;
    await engine.setVolume(1.0, force: true);
    // Soft-decode emulator surfaces can drop the buffer queue across EOS
    // seek; rebind before seek+play so the loop is not a black tile.
    await engine.ensureSurfaceConnected();
    await engine.seekTo(Duration.zero);
    if (!mounted) return;
    await engine.startPlayback();
    await engine.setVolume(1.0, force: true);
  }

  void _syncLooping() {
    for (final slot in _slots) {
      final engine = slot.engine;
      if (engine == null) continue;
      final looping = FeedPlaybackPolicy.shouldUseNativeLoop(
        autoPlayEnabled: _ctrl.autoPlayEnabled,
        duration: engine.duration,
      );
      unawaited(engine.setLooping(looping));
    }
  }

  Future<void> _advanceToNext() async {
    if (_ctrl.overlayHoldsAdvance) return;
    var feed = ref.read(recommendFeedControllerProvider);
    var next = feed.currentIndex + 1;
    if (next >= feed.items.length) {
      await _ctrl.loadMoreIfAtEnd();
      if (!mounted) return;
      feed = ref.read(recommendFeedControllerProvider);
      next = feed.currentIndex + 1;
    }
    if (next < feed.items.length && _pageController.hasClients) {
      await _pageController.animateToPage(
        next,
        duration: StoryDurations.animationFast,
        curve: Curves.easeOut,
      );
      return;
    }
    // Parent still has pages — do not loop back to the first card.
    if (_ctrl.isExternalFeed && feed.hasMore) {
      return;
    }
    if (_ctrl.isExternalFeed && feed.items.isNotEmpty) {
      _ended = false;
      _pageController.jumpToPage(0);
      return;
    }
    _ctrl.setUserPaused(true);
    _isPlaying = false;
    _toastNoMoreIfNeeded(feed);
  }

  Future<void> _onFeedPageChanged(int index) async {
    unawaited(_ctrl.loadMoreIfAtEnd(index: index));
    await _ctrl.onPageChanged(index);
  }

  bool _onFeedScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollEndNotification) {
      _endLoadQueued = false;
      if (_pageController.hasClients) {
        final settled = _pageController.page?.round();
        final feed = ref.read(recommendFeedControllerProvider);
        if (settled != null &&
            settled >= 0 &&
            settled < feed.items.length &&
            settled != feed.currentIndex) {
          unawaited(_onFeedPageChanged(settled));
        }
      }
      return false;
    }
    final pastEnd = notification is OverscrollNotification
        ? notification.overscroll > 0
        : false;
    if (!pastEnd || _endLoadQueued) return false;
    final feed = ref.read(recommendFeedControllerProvider);
    final pageIndex = _pageController.hasClients
        ? (_pageController.page?.round() ?? feed.currentIndex)
        : feed.currentIndex;
    if (pageIndex < feed.items.length - 1) return false;
    _endLoadQueued = true;
    unawaited(_onLastPagePull(pageIndex));
    return false;
  }

  Future<void> _onLastPagePull(int pageIndex) async {
    final feed = ref.read(recommendFeedControllerProvider);
    if (feed.hasMore) {
      await _ctrl.loadMoreIfAtEnd(index: pageIndex);
      return;
    }
    _toastNoMoreIfNeeded(feed, index: pageIndex);
  }

  Future<void> _handleUnplayableCurrent(RecommendFeedState feed) async {
    if (!_isPlaybackVisible ||
        feed.isPlayLoading ||
        feed.currentPlay != null ||
        feed.currentItem == null) {
      return;
    }
    if (!FeedPlaybackPolicy.isUnplayableTranscodeError(feed.lastError)) {
      return;
    }
    final dramaId = feed.currentItem!.playbackId;
    if (dramaId.isEmpty || dramaId == _skippingUnplayableDramaId) return;
    if (_unplayableSkipStreak >= 8) {
      _showPlaybackErrorToast();
      return;
    }
    _skippingUnplayableDramaId = dramaId;
    _unplayableSkipStreak++;
    StoryLogger.w(
      'Recommend skip untranscoded drama=$dramaId streak=$_unplayableSkipStreak',
      tag: 'Rec',
    );
    // Auto-advance — no toast on first skip (next card may play). Toast only
    // when many consecutive skips suggest the feed is unusable.
    await _advanceToNext();
  }

  void _toastNoMoreIfNeeded(RecommendFeedState feed, {int? index}) {
    if (!FeedPlaybackPolicy.shouldToastNoMoreItems(
      currentIndex: index ?? feed.currentIndex,
      itemCount: feed.items.length,
      hasMore: feed.hasMore,
    )) {
      return;
    }
    final now = DateTime.now();
    if (_noMoreToastAt != null &&
        now.difference(_noMoreToastAt!) < const Duration(seconds: 2)) {
      return;
    }
    _noMoreToastAt = now;
    if (!mounted) return;
    StoryToast.info(context, context.l10n.listNoMoreData);
  }

  Future<void> _onNotInterested() async {
    final l10n = context.l10n;
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!mounted) return;

    final ok = await _ctrl.dislikeCurrent();
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(recommendFeedControllerProvider).lastError;
      StoryToast.error(context, err?.userMessage ?? l10n.playerPlayFailed);
      return;
    }

    // Jump pager to the new current index after the item was removed.
    _syncPagerToFeedCurrentIndex();
    StoryToast.success(context, l10n.playerNotInterestedDone);
  }

  /// Align [PageController] (and optionally rebind) after feed advanced without
  /// a user swipe — e.g. dislike / report "减少推荐".
  void _syncPagerToFeedCurrentIndex({bool forceRebind = false}) {
    final feed = ref.read(recommendFeedControllerProvider);
    if (_pageController.hasClients && feed.items.isNotEmpty) {
      final target = feed.currentIndex.clamp(0, feed.items.length - 1);
      if (_visiblePageIndex.value != target) {
        _visiblePageIndex.value = target;
      }
      if (_pageController.page?.round() != target) {
        _pageController.jumpToPage(target);
      }
    }
    if (!forceRebind) return;
    // Identity may have changed while /report covered the feed, so the
    // visibility-gated listenManual skipped [_onFeedIdentity].
    if (_isPlaybackVisible) {
      _onFeedIdentity(null, feed);
    }
  }

  void _showLongPressMenu() {
    final feed = ref.read(recommendFeedControllerProvider);
    final item = feed.currentItem;
    if (item == null) return;

    // 自己的作品不显示「不感兴趣」与「举报」。
    final creatorId =
        (item.creatorId ?? feed.currentDetail?.userId)?.trim() ?? '';
    final myId = ref.read(authControllerProvider).userId?.trim() ?? '';
    final isOwnWork = creatorId.isNotEmpty && creatorId == myId;

    // Hold before the modal route lands: otherwise shell-coverage tears down
    // the native surface and the feed falls back to a black ColoredBox.
    unawaited(() async {
      var reported = false;
      var reducedRecommend = false;
      await _ctrl.holdAutoAdvance(() async {
        // Overlay holds advance → loop while the menu / report UI is up.
        _syncLooping();
        final action = await PlayerLongPressMenu.show(
          context: context,
          dramaId: item.dramaId,
          episodeNo: item.episodeNo ?? 1,
          episodeId: item.episodeId ?? feed.currentPlay?.episodeId,
          contentType: item.workType,
          creatorId: item.creatorId ?? feed.currentDetail?.userId,
          creatorName: item.creatorName ?? feed.currentDetail?.creatorName,
          creatorAvatarUrl:
              item.creatorAvatar ?? feed.currentDetail?.creatorAvatarUrl,
          contentTitle: item.title ?? feed.currentDetail?.title,
          contentCoverUrl: item.posterUrl ?? feed.currentDetail?.coverUrl,
          autoPlayEnabled: _ctrl.autoPlayEnabled,
          onAutoPlayChanged: (next) {
            _ctrl.autoPlayEnabled = next;
            // Do not _syncLooping here: overlayHoldsAdvance is still true, so
            // enabling 连播 would keep native loop on and never fire completed.
            if (!next && _ended) {
              unawaited(_replayCurrent());
            }
          },
          onClearScreen: () {
            if (!mounted) return;
            _chromeHidden.value = true;
          },
          onNotInterested: () {
            unawaited(_onNotInterested());
          },
          isOwnWork: isOwnWork,
        );
        if (action != PlayerLongPressMenu.reportAction) return;
        if (!mounted) return;
        if (!await ensureLoggedInOrRedirect(context, ref)) return;
        if (!mounted) return;
        // Pause/resume via PlaybackAuthRouteObserver (/report); do not also
        // call _onAuthRouteCover here or cover/reveal runs twice.
        final result = await context.storyPushForResult<Object?>(RouteNames.report,
          arguments: <String, dynamic>{
            'dramaId': item.dramaId,
            'episodeNo': item.episodeNo ?? 1,
            'episodeId': item.episodeId ?? feed.currentPlay?.episodeId,
            'contentType': item.workType.apiValue,
            'userId': item.creatorId ?? feed.currentDetail?.userId,
            'targetDisplayName':
                item.creatorName ?? feed.currentDetail?.creatorName,
            'targetAvatarUrl':
                item.creatorAvatar ?? feed.currentDetail?.creatorAvatarUrl,
            'contentTitle': item.title ?? feed.currentDetail?.title,
            'contentCoverUrl': item.posterUrl ?? feed.currentDetail?.coverUrl,
          });
        reported = isReportPageSuccess(result);
        reducedRecommend =
            result is ReportPageResult && result.reducedRecommend;
      });
      if (!mounted) return;
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      final covered = widget.standalone
          ? ModalRoute.of(context)?.isCurrent != true
          : ref.read(mainShellRouteCoveredProvider);
      if (covered) {
        if (widget.standalone) _standaloneRouteCovered = true;
        _teardownNativeSurfacesForOcclusion();
        return;
      }
      // Hold released — apply the real 连播/loop preference.
      _syncLooping();
      if (reported) {
        // Feed dislikeCurrent already landed on the next item — sync pager.
        // Bare repository dislike still needs _advanceToNext().
        if (reducedRecommend) {
          _syncPagerToFeedCurrentIndex(forceRebind: true);
        } else {
          unawaited(_advanceToNext());
        }
        return;
      }
      if (_ctrl.autoPlayEnabled &&
          (_ended || (_active.engine?.hasCompleted ?? false))) {
        unawaited(_advanceToNext());
      }
    }());
  }

  void _onAuthRouteCover(bool covering) {
    if (!mounted) return;
    if (covering) {
      if (_authOverlayCovering) return;
      _authOverlayCovering = true;
      final feed = ref.read(recommendFeedControllerProvider);
      _wasPlayingBeforeAuthOverlay =
          _isPlaying && !feed.isUserPaused && widget.isActive && _appForeground;
      _pauseBecauseHidden();
      _syncWakeLock();
      scheduleFeedAuthCoverSurfaceTeardown(
        mounted: () => mounted,
        stillCovering: () => _authOverlayCovering,
        shouldUnmount: () => !_shouldMountNativeSurfaces,
        unmount: _unmountNativeSurfaces,
      );
      return;
    }
    if (!_authOverlayCovering) return;
    _authOverlayCovering = false;
    final shouldResume =
        _wasPlayingBeforeAuthOverlay &&
        !ref.read(recommendFeedControllerProvider).isUserPaused;
    _wasPlayingBeforeAuthOverlay = false;
    unawaited(_revealAfterAuthOverlay(shouldResume: shouldResume));
  }

  Future<void> _revealAfterAuthOverlay({required bool shouldResume}) async {
    if (!_nativeSurfacesMounted && _shouldMountNativeSurfaces) {
      _surfaces.remount();
      await _waitOnePostFrame();
      if (!mounted) return;
      await _markSurfacesReadyAfterRemount();
      _restoreNeighborSurfacesIfNeeded();
    } else {
      _restoreNeighborSurfacesIfNeeded();
    }
    if (!shouldResume || !mounted) return;
    _resumeIfVisible();
  }

  @override
  void dispose() {
    _stateDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    PlaybackAuthRouteObserver.instance.removeListener(_onAuthRouteCover);
    _playing.removeListener(_syncWakeLock);
    _userPaused.removeListener(_syncWakeLock);
    unawaited(PlaybackWakeLock.current.release());
    _routeSubscription.dispose(this);
    _pageController.removeListener(_onPageScroll);
    PlaybackFrameCacheService.instance.revisions.removeListener(
      _onFrameCacheRevision,
    );
    _feedSub?.close();
    _itemsLenSub?.close();
    _tabIndexSub?.close();
    _shellOcclusion?.dispose();
    unawaited(_persistActiveWatchProgress());
    _clearOcclusionResume();
    _clearProgressFloor();
    _suppressNeighborWarmUntil = null;
    _cancelDeferredNeighborWarm();
    _detachProgressMirrorNow();
    _active.engine?.releaseCookieFamily();
    // Sync detach before disposing chrome notifiers; bumps are skipped via
    // [_stateDisposed].
    unawaited(_teardownAllPlayers());
    _pageController.dispose();
    _pageOffset.dispose();
    _visiblePageIndex.dispose();
    _idlePosition.dispose();
    _progressPosition.dispose();
    _playing.dispose();
    _userPaused.dispose();
    _durationN.dispose();
    _playerSheetOpen.dispose();
    _playerSheetHeight.dispose();
    _chromeHidden.dispose();
    _coverRevision.dispose();
    _slotRevision.dispose();
    _surfaces.dispose();
    _frameManager.dispose();
    super.dispose();
  }

  Future<void> _exitStandalone() async {
    if (!widget.standalone || _standaloneExitRunning) return;
    _standaloneExitRunning = true;
    _standaloneRouteCovered = true;
    _teardownNativeSurfacesForOcclusion();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
      recommendFeedControllerProvider.select(
        (s) => (
          s.items.length,
          s.currentIndex,
          s.currentItem?.id,
        s.currentPlay?.episodeId,
        s.isLoading,
        s.isPlayLoading,
        s.hasMore,
        s.currentDetail?.totalEpisodes,
        s.lastError,
        ),
      ),
    );
    final feed = ref.read(recommendFeedControllerProvider);

    if ((feed.isLoading || _awaitingFirstLoad) && feed.items.isEmpty) {
      // Cache peek: keep a black frame (no spinner) so a hit can paint as
      // content. Network miss sets isLoading and shows the indicator.
      if (feed.isLoading) {
        return const ColoredBox(
          color: StoryColors.overlayHeavy,
          child: Center(
            child: SizedBox(
              width: StorySizes.loadingSmall,
              height: StorySizes.loadingSmall,
              child: CircularProgressIndicator(
                strokeWidth: StorySizes.loadingStroke,
                color: StoryColors.onOverlay,
              ),
            ),
          ),
        );
      }
      return const ColoredBox(color: StoryColors.overlayHeavy);
    }

    if (!feed.isLoading && !_awaitingFirstLoad && feed.items.isEmpty) {
      return ColoredBox(
        color: StoryColors.overlayHeavy,
        child: StoryStateWidget.empty(
          message: context.l10n.dramaEmpty,
          actionLabel: context.l10n.dramaRefresh,
          onAction: () => _ctrl.refresh(),
        ),
      );
    }

    final feedCurrent = feed.currentItem;
    final current = _chromeItemFor(feed) ?? feedCurrent;
    final showPersistentPlaybackError =
        widget.standalone &&
        feed.currentPlay == null &&
        !feed.isPlayLoading &&
        feed.lastError != null &&
        !FeedPlaybackPolicy.isUnplayableTranscodeError(feed.lastError);

    Widget playerLayer(
      FeedSlot slot,
      double Function(int) topFor,
      double pageHeight,
      double playerHeight,
    ) {
      final native = slot.native;
      final index = slot.index;
      final top = index == null ? pageHeight * 2.0 : topFor(index);
      // Always emit a keyed Positioned so Stack children stay 3 typed
      // slots. Mixing shrink/Positioned + Platform View trips semantics.
      Widget child = const SizedBox.expand();
      final isActiveSlot = identical(slot, _active);
      if (native != null &&
          slot.surfaceReady &&
          _surfaces.shouldMountSlotPlatformView(isActiveSlot: isActiveSlot)) {
        // fitCollapsedBand only adjusts Positioned geometry (no remount).
        child = _surfaceCache.surfaceFor(
          native,
          fitCollapsedBand: playerHeight < pageHeight - 1.0,
        );
      }
      return Positioned(
        key: ObjectKey(slot),
        top: top,
        left: 0,
        right: 0,
        height: playerHeight,
        child: ClipRect(child: child),
      );
    }

    bool neighborReady(RecommendFeedItem item) =>
        FeedPlaybackPolicy.slotHoldsDecodedItem(
          slotPlaybackId: _next.playbackId,
          itemPlaybackId: item.playbackId,
          loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
            _next.engine?.currentPlay,
          ),
          hasPendingLoad: _next.engine?.hasPendingLoad ?? true,
          surfaceReady: _next.surfaceReady,
          frameReady: _next.frameReady,
        ) ||
        FeedPlaybackPolicy.slotHoldsDecodedItem(
          slotPlaybackId: _prev.playbackId,
          itemPlaybackId: item.playbackId,
          loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
            _prev.engine?.currentPlay,
          ),
          hasPendingLoad: _prev.engine?.hasPendingLoad ?? true,
          surfaceReady: _prev.surfaceReady,
          frameReady: _prev.frameReady,
        );

    // Same as VideoFeedPage: wrap the whole feed. A partial wrap around
    // only the native layer is not enough — Material Slider keeps an
    // OverlayPortal value-indicator always shown, and grafting that overlay
    // child onto the portal (not the Overlay) trips
    // `identical(childRenderObject, parentRenderObject)` when a neighbor
    // UiKitView attaches and flushes semantics.
    final content = ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  ListenableBuilder(
                    listenable: _slotRevision,
                    builder: (context, _) {
                      return FeedPlayerLayerHost(
                        sheetOpenNotifier: _playerSheetOpen,
                        sheetHeightListenable: _playerSheetHeight,
                        pageController: _pageController,
                        pageOffset: _pageOffset,
                        feed: feed,
                        height: height,
                        slots: _slots,
                        // Collapse player into the top band for short drama and
                        // short video while a comment / detail sheet is open.
                        collapseForSheet: current != null,
                        playerLayer: playerLayer,
                      );
                    },
                  ),
                  NotificationListener<ScrollNotification>(
                    onNotification: _onFeedScrollNotification,
                    child: ListenableBuilder(
                      listenable: _coverRevision,
                      builder: (context, _) {
                        return ValueListenableBuilder<int>(
                          valueListenable: _visiblePageIndex,
                          builder: (context, visibleIndex, _) {
                            return PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          allowImplicitScrolling: true,
                          itemCount: feed.items.length,
                          onPageChanged: (index) {
                            unawaited(_onFeedPageChanged(index));
                          },
                          itemBuilder: (context, index) {
                            final item = feed.items[index];
                            final isCurrent = index == visibleIndex;
                            final episodeNo =
                                (item.episodeNo != null && item.episodeNo! >= 1)
                                ? item.episodeNo!
                                : 1;
                            final boundHere = _slots.any(
                              (slot) => FeedPlaybackPolicy.slotHoldsDecodedItem(
                                slotPlaybackId: slot.playbackId,
                                itemPlaybackId: item.playbackId,
                                loadedPlayPlaybackId:
                                    RecommendFeedItem.playbackIdOfPlay(
                                      slot.engine?.currentPlay,
                                    ),
                                hasPendingLoad:
                                    slot.engine?.hasPendingLoad ?? true,
                                surfaceReady:
                                    slot.surfaceReady &&
                                    slot.native != null &&
                                    slot.index == index,
                                frameReady: slot.frameReady,
                              ),
                            );
                            // Preload finished (loadUrl) but first frame may still
                            // be priming — treat as warm so we do not flash spinner.
                            final warmLoaded = _slots.any(
                              (slot) =>
                                  slot.playbackId == item.playbackId &&
                                  slot.surfaceReady &&
                                  slot.native != null &&
                                  RecommendFeedItem.playbackIdOfPlay(
                                        slot.engine?.currentPlay,
                                      ) ==
                                      item.playbackId &&
                                  !(slot.engine?.hasPendingLoad ?? true),
                            );
                            final surfaceReady =
                                isCurrent &&
                                _nativeSurfacesMounted &&
                                (FeedPlaybackPolicy.isCurrentPagePlayerReady(
                                      slotMatchesDrama:
                                          _active.playbackId == item.playbackId,
                                      loadedPlayMatches:
                                          RecommendFeedItem.playbackIdOfPlay(
                                            _active.engine?.currentPlay,
                                          ) ==
                                          item.playbackId,
                                      surfaceReady: _active.surfaceReady,
                                      frameReady: _active.frameReady,
                                    ) ||
                                    boundHere);
                            final reveal = shouldUnmountFeedCover(
                              isCurrentPage: isCurrent,
                              currentSurfaceReady: surfaceReady,
                              neighborHasDecodedFrame:
                                  !isCurrent &&
                                  (neighborReady(item) || boundHere),
                              currentRevealLatched:
                                  isCurrent &&
                                  _surfaces.coverRevealLatchedPlaybackId ==
                                      item.playbackId,
                              // Keep revealing while user-paused so the native
                              // surface holds the last frame (no JPEG cover).
                              allowLatchedReveal: _nativeSurfacesMounted,
                            );
                            final itemFrameKey = _frameCacheKeyFor(item);
                            final cachedFrame = _frameManager.getBytes(
                              itemFrameKey,
                            );
                            // Do not primeAround from itemBuilder — that races
                            // active playback with disk I/O + setState. Identity
                            // / initial load already warm current ± radius.
                            final itemTotalEps = item.totalEpisodes ?? 1;
                            // Chrome content is always this page's [item]. Match
                            // flags are per-page so early-activate cannot paste
                            // another card's rail / bottom info onto this page.
                            final itemMatchesActive =
                                _active.playbackId == item.playbackId &&
                                RecommendFeedItem.playbackIdOfPlay(
                                      _active.engine?.currentPlay,
                                    ) ==
                                    item.playbackId;
                            final itemSyncedWithFeed =
                                feedCurrent != null &&
                                item.playbackId == feedCurrent.playbackId;
                            // Only overlay roles when detail is for this drama —
                            // currentDetail can lag behind early-activate.
                            final rawDetail = itemSyncedWithFeed
                                ? feed.currentDetail
                                : null;
                            final itemDetail =
                                rawDetail != null &&
                                    rawDetail.id != null &&
                                    rawDetail.id == item.dramaId
                                ? rawDetail
                                : null;
                            // Hold bar on session resume while engines remount;
                            // otherwise live progress comes from the stable mirror.
                            final holdingOcclusionResume =
                                isCurrent &&
                                _occlusionResumePlaybackId == item.playbackId &&
                                _progressPosition.value > Duration.zero;
                            final itemPositionNotifier =
                                (itemMatchesActive || holdingOcclusionResume)
                                ? _progressPosition
                                : _idlePosition;
                            return FeedPageItem(
                              chrome: RecommendFeedPageItemChrome(
                                isCurrent: isCurrent,
                                item: item,
                                detail: itemDetail,
                                feed: feed,
                                chromeHidden: _chromeHidden,
                                ended: _ended,
                                playing: _playing,
                                userPaused: _userPaused,
                                duration: _durationN,
                                positionNotifier: itemPositionNotifier,
                                chromeMatchesActive:
                                    itemMatchesActive || holdingOcclusionResume,
                                chromeSyncedWithFeed: itemSyncedWithFeed,
                                standalone: widget.standalone,
                                playerSheetOpen: _playerSheetOpen,
                                sheetHeightNotifier: _playerSheetHeight,
                                onTogglePlayPause: _togglePlayPause,
                                onLongPress: _showLongPressMenu,
                                onClearScreen: () =>
                                    _chromeHidden.value = true,
                                onExitClearScreen: () =>
                                    _chromeHidden.value = false,
                                onSeekActive: (pos) {
                                  _progressPosition.value = pos;
                                  unawaited(_active.engine?.seekTo(pos));
                                },
                                onOpenFullDrama: () => unawaited(
                                  widget.standalone
                                      ? _showStandaloneEpisodePicker(
                                          item,
                                          itemDetail,
                                        )
                                      : _openFullDrama(item, itemDetail),
                                ),
                                onOpenDetailTab: (tab) => unawaited(
                                  _showDramaDetailSheet(
                                    item: item,
                                    detail: itemDetail,
                                    tab: tab,
                                  ),
                                ),
                                onLike: () => _ctrl.toggleLike(target: item),
                                onFavorite: () =>
                                    _ctrl.toggleFavorite(target: item),
                                onCommentPosted: _ctrl.onCommentPosted,
                                aroundShare: _aroundShare,
                                holdWithCollapsedPlayer:
                                    _holdWithCollapsedPlayer,
                              ),
                              child: VideoFeedPageItem(
                                episodeNo: episodeNo,
                                totalEpisodes: itemTotalEps,
                                coverUrl: item.posterUrl,
                                // Series poster only when detail is for this
                                // item (see itemDetail gate above). Never use
                                // feed.currentDetail for other pages — that
                                // bleeds the wrong drama cover across swipes.
                                dramaCoverUrl: itemDetail?.coverUrl,
                                firstFrameBytes: cachedFrame,
                                isCurrentPage: isCurrent,
                                revealPlayer: reveal,
                                pinProgressToBottom: true,
                                showLoading:
                                    isCurrent &&
                                    !reveal &&
                                    !warmLoaded &&
                                    cachedFrame == null &&
                                    feed.isPlayLoading,
                              ),
                            );
                          },
                        );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          if (showPersistentPlaybackError)
            ColoredBox(
              color: StoryColors.overlayHeavy,
              child: StoryStateWidget.error(
                message: context.l10nError(feed.lastError!),
                actionLabel: context.l10n.dramaDetailRetry,
                onAction: () => unawaited(_retryCurrentPlayback()),
              ),
            ),
          if (widget.standalone)
            ListenableBuilder(
              listenable: _chromeHidden,
              builder: (context, _) {
                if (_chromeHidden.value) {
                  return const SizedBox.shrink();
                }
                return VideoFeedHeaderOverlay(
                  episodeNo: current?.resolvedEpisodeNo ?? 1,
                  totalEpisodes: current?.totalEpisodes ?? 1,
                  title: current?.title ?? '',
                  showEpisodeLabel: false,
                  onBack: () => unawaited(_exitStandalone()),
                );
              },
            ),
        ],
      ),
    );
    if (!widget.standalone) return content;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_exitStandalone());
      },
      child: content,
    );
  }
}
