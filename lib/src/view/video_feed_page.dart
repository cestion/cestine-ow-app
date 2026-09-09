import 'dart:async';

import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/feed_neighbor_mount_policy.dart';
import '../controller/feed_page_scroll_handler.dart';
import '../controller/feed_persist_policy.dart';
import '../controller/feed_playback_policy.dart';
import '../controller/feed_scroll_activate_snapshot.dart';
import '../controller/video_feed_controller.dart';
import '../controller/video_feed_state.dart';
import '../components/common/story_bottom_sheet.dart';
import '../components/common/story_toast.dart';
import '../core/episode_play_handoff.dart';
import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../l10n/story_l10n.dart';
import '../routes/route_args.dart';
import '../routes/video_feed_navigation.dart';
import '../provider/app_providers.dart';
import '../foundation/playback_auth_route_observer.dart';
import '../foundation/playback_visibility.dart';
import '../services/native_video_player_coordinator.dart';
import '../services/playback_entry_warmup.dart';
import '../services/playback_frame_cache_service.dart';
import '../services/playback_wake_lock.dart';
import '../styles/story_colors.dart';
import '../widgets/widgets.dart';
import 'widgets/drama_detail/drama_detail_sheet.dart';

import 'widgets/video_comment/comment_bottom_sheet.dart';
import 'widgets/video_feed/video_feed_widgets.dart';

/// TikTok 风格垂直滑动视频信息流页面
///
/// 架构：
/// - 三个 NativeVideoPlayer 叠在 Stack 底层，分别承载上一集、当前集、下一集
/// - PageView.builder 垂直滚动，每页对应一集
/// - 当前页透明露出 active 播放器，非当前页显示封面占位
/// - 预加载引擎在用户滑动前已准备好下一集视频，滑动瞬间 swap 实现无缝过渡
class VideoFeedPage extends ConsumerStatefulWidget {
  final VideoFeedArgs feedArgs;

  const VideoFeedPage({super.key, required this.feedArgs});

  @override
  ConsumerState<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends ConsumerState<VideoFeedPage>
    with WidgetsBindingObserver, RouteAware {
  static int _playerIdNext = 1;
  static int _nextPlayerId() => _playerIdNext++;

  late final PageController _pageController;
  ProviderSubscription<VideoFeedState>? _controllerSubscription;
  bool _initialized = false;
  final _routeSubscription = FeedRouteAwareSubscription();

  final ValueNotifier<int> _pageIndex = ValueNotifier<int>(0);
  final ValueNotifier<int?> _activatedPageIndex = ValueNotifier<int?>(null);
  NativeVideoPlayerController? _nativePlayerA;
  NativeVideoPlayerController? _nativePlayerB;
  NativeVideoPlayerController? _nativePlayerC;

  /// Mount only the active slot on entry; add B/C after first ready so we
  /// do not create three Android TextureView+ExoPlayer sessions on the same
  /// frame (that is what drives `Skipped 1000+ frames` on feed re-entry).
  bool _mountNeighborSurfaces = false;
  bool _neighborMountScheduled = false;

  /// Keep TextureViews / SurfaceViews out of the tree once exit teardown
  /// starts, and while a covering Flutter route (Login, detail) is up —
  /// Android SurfaceView otherwise paints above the later route.
  bool _surfaceTreeEnabled = true;
  bool _exitTeardownRunning = false;
  late final FeedScrollSettleDebouncer _scrollSettleDebouncer =
      FeedScrollSettleDebouncer(
        isMounted: () => mounted,
        onSettle: (targetIndex) {
          if (targetIndex != _activatedPageIndex.value) {
            _activatedPageIndex.value = targetIndex;
            _feedController.onSwipeToIndex(targetIndex);
          }
        },
      );
  late final FeedScrollPrefetchDirector _prefetchDirector =
      FeedScrollPrefetchDirector(
        onDirectionChanged: (preferForward) {
          _feedController.ensurePreloadForScrollDirection(
            preferForward: preferForward,
          );
        },
      );
  // Fullscreen flag is a ValueNotifier so toggling only rebuilds the
  // overlays / player layout layers instead of the whole page (which hosts
  // three native player surfaces).
  final ValueNotifier<bool> _isFullscreen = ValueNotifier<bool>(false);

  /// Comment / drama-detail sheet is open — collapse the native surface into
  /// the band above the sheet.
  final ValueNotifier<bool> _playerSheetOpen = ValueNotifier<bool>(false);
  final ValueNotifier<double> _playerSheetHeight = ValueNotifier<double>(
    StoryConstants.playerOverlaySheetHeight,
  );
  bool _initialCommentsOpened = false;
  bool _initialCommentsWaitLogged = false;

  /// Last episode number written to Hive resume — avoid redundant writes
  /// on every state update (isPlaying, duration, like changes).
  int _lastPersistedEpisodeNo = 0;

  /// While the episode picker sheet is open, ignore [RouteAware] pause/resume.
  /// Modal sheets also push a route; pausing under the sheet then racing
  /// [selectEpisode] on dismiss freezes iOS platform-view video (audio+progress
  /// keep running).
  bool _ignoreRouteCover = false;

  bool _appForeground = true;
  bool _routeCovered = false;
  bool _authOverlayCovering = false;

  /// Debounce "no more episodes" toast on last-page overscroll.
  DateTime? _noMoreToastAt;
  bool _endToastQueued = false;

  /// [BouncingScrollPhysics] never emits [OverscrollNotification] (boundary
  /// delta is always 0). Detect past-end via pixels past [maxScrollExtent].
  static const double _pastEndToastPx = 12;

  VideoFeedArgs get _args => widget.feedArgs;

  VideoFeedController get _feedController =>
      ref.read(videoFeedControllerProvider(_args).notifier);

  /// Unified visibility — sheet hold keeps surfaces mounted (same as recommend).
  PlaybackVisibilityKind get _visibilityKind => PlaybackVisibility.resolve(
    mounted: mounted,
    feedActive: true,
    appForeground: _appForeground,
    authOverlayCovering: _authOverlayCovering,
    standaloneRouteCovered: _routeCovered,
    isStandalone: true,
    tabIndex: 0,
    theaterTabIndex: 0,
    drawerOpen: false,
    shellRouteCovered: false,
    overlayHoldsAdvance: _feedController.overlayHoldsAdvance,
  );

  String? _resolveCoverUrl(String? detailCoverUrl) {
    // Prefer the list→player poster seed (often firstFrameUrl) so the same
    // CachedNetworkImage URL paints instantly before play metadata arrives.
    final episodeCover = _args.episodeCoverUrl?.trim();
    if (episodeCover != null && episodeCover.isNotEmpty) return episodeCover;
    final fromRoute = _args.coverUrl?.trim();
    if (fromRoute != null && fromRoute.isNotEmpty) return fromRoute;
    if (detailCoverUrl != null && detailCoverUrl.isNotEmpty) {
      return detailCoverUrl;
    }
    return null;
  }

  /// Once an episode shows a cover URL, keep it across rebuilds.
  final Map<int, String> _stableCoverByEpisode = {};

  /// Once the native surface has been revealed for an episode, do not bring
  /// the poster back on brief `playerSurfaceVisible` / slot-map flickers.
  final Set<int> _coverRevealLatched = {};

  /// Lock per-episode poster when known. Series poster is passed separately
  /// as [VideoFeedPageItem.dramaCoverUrl] and is not locked into this map.
  String? _stableCoverForEpisode(int episodeNo, {String? episodeCover}) {
    final ep = episodeCover?.trim();
    if (ep != null && ep.isNotEmpty) {
      _stableCoverByEpisode[episodeNo] = ep;
      return ep;
    }

    final locked = _stableCoverByEpisode[episodeNo];
    if (locked != null && locked.isNotEmpty) return locked;
    return null;
  }

  /// 首帧缓存 key：优先 `dramaId:episodeId`（与推荐流一致，跨入口共享），
  /// episodeId 缺失时 fallback 到 `dramaId_ep$episodeNo`。
  String _frameCacheKey(int episodeNo) {
    final play = ref
        .read(videoFeedControllerProvider(_args))
        .episodePlays[episodeNo];
    return PlaybackFrameCacheService.frameCacheKey(
      dramaId: _args.dramaId,
      episodeId: play?.episodeId,
      episodeNo: episodeNo,
    );
  }

  /// Local copies of [PlaybackFrameCacheService] JPEGs for itemBuilder.
  final Map<int, Uint8List> _firstFrameBytes = {};

  /// Narrow rebuild for cover / first-frame JPEG updates (not full page).
  final ValueNotifier<int> _coverRevision = ValueNotifier<int>(0);

  /// Last episode for which frame cache was primed — avoid redundant async
  /// disk I/O on every revision during playback (~30 put/sec).
  int _lastPrimedEpisodeNo = 0;

  void _onFrameCacheRevision() {
    if (!mounted) return;
    final ep = _pageIndex.value + 1;
    // Only re-prime when the visible episode changed or this is the first
    // revision for a new episode. Revisions during steady-state playback
    // (same episode, same ±1 cached frames) are no-ops.
    if (ep == _lastPrimedEpisodeNo) return;
    _lastPrimedEpisodeNo = ep;
    unawaited(_primeFrameCacheAround(ep));
  }

  Future<void> _primeFrameCacheAround(int episodeNo) async {
    if (episodeNo < 1) return;
    const radius = StoryConstants.playbackFramePrimeRadius;
    final candidates = <int>{
      for (var ep = episodeNo - radius; ep <= episodeNo + radius; ep++)
        if (ep >= 1) ep,
    };
    // Also kick dual-key disk loads for the center episode (episodeId + legacy).
    final centerPlay = ref
        .read(videoFeedControllerProvider(_args))
        .episodePlays[episodeNo];
    PlaybackEntryWarmup.primeFrameCache(
      dramaId: _args.dramaId,
      episodeNo: episodeNo,
      episodeId: centerPlay?.episodeId,
    );
    var changed = false;
    for (final ep in candidates) {
      final key = _frameCacheKey(ep);
      final hot = PlaybackFrameCacheService.instance.peek(key);
      if (hot != null && hot.isNotEmpty) {
        if (!identical(_firstFrameBytes[ep], hot)) {
          _firstFrameBytes[ep] = hot;
          changed = true;
        }
        continue;
      }
      // Also try the legacy drama_epN key when episodeId key missed.
      final play = ref.read(videoFeedControllerProvider(_args)).episodePlays[ep];
      if (play?.episodeId != null && play!.episodeId!.trim().isNotEmpty) {
        final legacy = PlaybackFrameCacheService.frameCacheKey(
          dramaId: _args.dramaId,
          episodeNo: ep,
        );
        final legacyHot = PlaybackFrameCacheService.instance.peek(legacy);
        if (legacyHot != null && legacyHot.isNotEmpty) {
          if (!identical(_firstFrameBytes[ep], legacyHot)) {
            _firstFrameBytes[ep] = legacyHot;
            changed = true;
          }
          continue;
        }
      }
      if (_firstFrameBytes.containsKey(ep)) continue;
      var bytes = await PlaybackFrameCacheService.instance.get(key);
      if (!mounted) return;
      if ((bytes == null || bytes.isEmpty) &&
          play?.episodeId != null &&
          play!.episodeId!.trim().isNotEmpty) {
        bytes = await PlaybackFrameCacheService.instance.get(
          PlaybackFrameCacheService.frameCacheKey(
            dramaId: _args.dramaId,
            episodeNo: ep,
          ),
        );
        if (!mounted) return;
      }
      if (bytes != null && bytes.isNotEmpty) {
        _firstFrameBytes[ep] = bytes;
        changed = true;
      }
    }
    if (changed && mounted) {
      _coverRevision.value++;
    }
  }

  @override
  void initState() {
    super.initState();
    VideoFeedNavigation.register(_args);
    WidgetsBinding.instance.addObserver(this);
    final initialPage = _args.episodeNo < 1 ? 0 : _args.episodeNo - 1;
    _pageController = PageController(initialPage: initialPage);
    _pageIndex.value = initialPage;
    _activatedPageIndex.value = initialPage;
    _pageController.addListener(_onPageScroll);
    PlaybackFrameCacheService.instance.revisions.addListener(
      _onFrameCacheRevision,
    );
    PlaybackAuthRouteObserver.instance.addListener(_onAuthRouteCover);
    unawaited(
      _primeFrameCacheAround(_args.episodeNo < 1 ? 1 : _args.episodeNo),
    );

    // Mount current/previous/next platform views up front so both swipe
    // directions can activate a decoded player without another loadUrl.
    _nativePlayerA = NativeVideoPlayerController(
      id: _nextPlayerId(),
      showNativeControls: false,
    );
    _nativePlayerB = NativeVideoPlayerController(
      id: _nextPlayerId(),
      showNativeControls: false,
    );
    _nativePlayerC = NativeVideoPlayerController(
      id: _nextPlayerId(),
      showNativeControls: false,
    );

    _controllerSubscription = ref.listenManual<VideoFeedState>(
      videoFeedControllerProvider(_args),
      (_, next) => _onControllerUpdate(next),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      _initialized = true;
      _feedController.attachTripleControllers(
        _nativePlayerA!,
        _nativePlayerB!,
        _nativePlayerC!,
      );
      // Rebuild so NativeVideoPlayer surfaces bind to attached feed slots.
      if (mounted) setState(() {});
      if (_args.warmStart &&
          EpisodePlayHandoff.hasOffer(
            dramaId: _args.workId,
            episodeNo: _args.episodeNo,
          )) {
        _feedController.primeWarmStart(_args.episodeNo);
        PlaybackEntryWarmup.primeFrameCacheAround(
          dramaId: _args.dramaId,
          episodeNo: _args.episodeNo,
        );
        _mountNeighborSurfaces = true;
        _neighborMountScheduled = true;
      }
      // CRITICAL: do NOT call initialize()/applyPlayback on this frame.
      // Cached episode data returns instantly and would hit
      // controller.initialize() before setState mounts the three platform
      // views — the plugin Completer has no timeout and freezes feed entry
      // (stuck at "awaiting native bootstrap…").
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _feedController.startEagerInitialization();
        unawaited(_initController());
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeSubscription.update(context, this, enabled: true);
  }

  @override
  void didPushNext() {
    if (_ignoreRouteCover) return;
    _routeCovered = true;
    if (PlaybackVisibility.shouldMountSurfaces(_visibilityKind)) {
      // Sheet / auth overlay — keep Platform Views mounted.
      if (!PlaybackVisibility.isPlaybackVisible(_visibilityKind)) {
        unawaited(_feedController.onRouteCovered());
      }
      return;
    }
    // Unmount this frame before pause futures run. A paused SurfaceView
    // still composites above Login / detail on Android OEM compositors
    // (same bug as the theater banner).
    _unmountNativeSurfacesForCover();
    unawaited(_feedController.onRouteCovered());
  }

  @override
  void didPopNext() {
    if (_ignoreRouteCover) return;
    _routeCovered = false;
    if (!PlaybackVisibility.shouldMountSurfaces(_visibilityKind)) {
      return;
    }
    _remountNativeSurfacesAfterCover();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _ignoreRouteCover) return;
      if (!PlaybackVisibility.isPlaybackVisible(_visibilityKind)) return;
      _resumeAfterCoveringRoute();
    });
  }

  void _unmountNativeSurfacesForCover() {
    if (!mounted) return;
    _neighborMountScheduled = false;
    // Drop reveal latch so PageView remounts the poster/first-frame cover
    // instead of exposing a black hole while the platform views are gone.
    _coverRevealLatched.clear();
    if (!_surfaceTreeEnabled && !_mountNeighborSurfaces) return;
    setState(() {
      _surfaceTreeEnabled = false;
      _mountNeighborSurfaces = false;
    });
  }

  void _remountNativeSurfacesAfterCover() {
    if (!mounted || _surfaceTreeEnabled) return;
    setState(() => _surfaceTreeEnabled = true);
  }

  void _resumeAfterCoveringRoute() {
    final pending = VideoFeedNavigation.takePendingResume();
    if (pending != null && pending.playbackKey == _args.playbackKey) {
      if (pending.episodeNo != _feedController.currentEpisodeNo) {
        // Move the pager too — activating while the PageView still sits on
        // the old episode plays the new one off-screen (audio + progress
        // advance, picture frozen on the previous cover).
        unawaited(_jumpPagerAndActivate(pending.episodeNo));
        return;
      }
    }
    // Detail (or other route) paused us via [didPushNext] → onRouteCovered.
    _feedController.onPageRevealed();
  }

  /// Jump the pager onto [epNo]'s page, wait a frame so the destination
  /// surface is laid out on-screen, then activate. Shared by the in-player
  /// episode picker and detail-page episode taps (popUntil resume).
  Future<void> _jumpPagerAndActivate(int epNo) async {
    final index = epNo - 1;
    _scrollSettleDebouncer.cancel();
    _activatedPageIndex.value = index;
    _pageIndex.value = index;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
    // Two frames: one for the covering route (modal sheet / detail pop) to
    // finish tearing down, one for the pager jump to lay out the destination
    // surface. Timed so a wedged pipeline cannot hang activation.
    for (var i = 0; i < 2; i++) {
      try {
        await WidgetsBinding.instance.endOfFrame.timeout(
          const Duration(milliseconds: 500),
        );
      } on TimeoutException {
        break; // Ignore — activate anyway.
      }
      if (!mounted) return;
    }
    if (!mounted) return;
    try {
      await _feedController.selectEpisode(epNo);
    } on StateError catch (e) {
      if (_feedController.disposed) return;
      if (e.message.contains('disposed')) return;
      rethrow;
    }
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == null) return;

    final targetIndex = page.round().clamp(0, _args.totalEpisodes - 1);
    if (targetIndex != _pageIndex.value) {
      _pageIndex.value = targetIndex;
    }

    // Duck outgoing audio only once the swipe is committed toward another
    // episode (same threshold as early-activate). page.round() flips at 0.5
    // and used to mute while the playing card was still on screen.
    final playingIndex =
        (_feedController.loadedEpisodeNo ?? _feedController.currentEpisodeNo) -
        1;
    final scrollTick = FeedScrollActivateSnapshot.analyze(
      page: page,
      activeIndex: playingIndex.clamp(0, _args.totalEpisodes - 1),
      inSkipDuckWindow: false,
    );
    if (scrollTick.shouldDuckOutgoing) {
      _feedController.onPagerTargetEpisode(targetIndex + 1);
    } else if (playingIndex >= 0) {
      _feedController.onPagerTargetEpisode(playingIndex + 1);
    }

    // Bias native preload toward the drag direction before settle.
    // Skip when direction hasn't changed (scroll ticks keep firing with
    // the same intent — the controller's own guards are cheap but the
    // method dispatch still adds per-tick overhead).
    _prefetchDirector.apply(scrollTick);

    final activeIndex = _feedController.currentEpisodeNo - 1;
    final targetEpisode = targetIndex + 1;
    if (FeedPageScrollEarlyActivate.dramaCommittedToTarget(
      page: page,
      activeIndex: activeIndex,
      targetIndex: targetIndex,
      targetEpisode: targetEpisode,
      frameReadyEpisodeNos: _feedController.frameReadyEpisodeNos,
      settledEpisodeNos: _feedController.settledPreloadEpisodeNos,
      alreadyActivatedIndex: _activatedPageIndex.value,
    )) {
      _scrollSettleDebouncer.cancel();
      _activatedPageIndex.value = targetIndex;
      _feedController.onSwipeToIndex(targetIndex);
      return;
    }

    if (page == page.roundToDouble()) {
      _scrollSettleDebouncer.onSnapped();
      final settledEpisode = targetIndex + 1;
      if (settledEpisode != _feedController.currentEpisodeNo) {
        _activatedPageIndex.value = targetIndex;
        unawaited(_feedController.onSwipeToIndex(targetIndex));
      } else if (targetIndex != _activatedPageIndex.value) {
        _activatedPageIndex.value = targetIndex;
        unawaited(_feedController.onSwipeToIndex(targetIndex));
      }
    } else {
      _scrollSettleDebouncer.schedule(
        targetIndex,
        activatedIndex: _activatedPageIndex.value,
      );
    }

    // Snappy + Bouncing: no OverscrollNotification — toast from scroll metrics.
    _checkLastEpisodeOverscrollToast();
  }

  Future<void> _initController() async {
    // No waitUntilIdle needed — NativePlayerBootstrap.initialize inside
    // applyPlayback handles coordinator acquisition via acquire().
    if (!mounted) return;
    await _feedController.initialize(warmStart: _args.warmStart);
  }

  void _onControllerUpdate(VideoFeedState state) {
    if (!mounted) return;

    // Sync current episode to the shared provider for drama detail / theater
    // resume. Search「短剧」playlist starts at ep 1 by design and must not
    // clobber the Hive continue-watching cursor used by theater.
    // Only persist when the episode actually changes — the controller fires
    // _onControllerUpdate for every state update (isPlaying, duration, likes)
    // which would thrash Hive with ~30 writes/second during playback.
    if (_shouldPersistResumeEpisode &&
        state.currentEpisodeNo > 0 &&
        state.currentEpisodeNo != _lastPersistedEpisodeNo) {
      _lastPersistedEpisodeNo = state.currentEpisodeNo;
      ref
          .read(currentDramaEpisodeProvider(_args.dramaId).notifier)
          .setEpisode(state.currentEpisodeNo);
    }

    // Cover reveal latch lives outside itemBuilder — mutating Sets during
    // build is a Flutter anti-pattern and can desync the first paint.
    // Match recommend: latch only after a painted frame for the loaded ep.
    // Clear when the surface is hidden (login / detail route). Do not clear
    // on user pause — the native layer keeps the last decoded frame.
    _coverRevealLatched.removeWhere((ep) => ep != state.currentEpisodeNo);
    if (!state.playerSurfaceVisible) {
      _coverRevealLatched.remove(state.currentEpisodeNo);
    }
    final loaded = state.loadedEpisodeNo;
    if (state.playerSurfaceVisible &&
        loaded != null &&
        loaded == state.currentEpisodeNo &&
        state.frameReadyEpisodeNos.contains(loaded)) {
      _coverRevealLatched.add(loaded);
    }

    _syncWakeLock(state);

    // Warm first-frame JPEG cache for current ±1 so swipe keeps a poster.
    unawaited(_primeFrameCacheAround(state.currentEpisodeNo));

    if (state.status == FeedPlaybackStatus.ready &&
        state.loadedEpisodeNo != null) {
      _maybeOpenInitialComments(state);
      // Cover comes from the drama poster (CachedNetworkImage). Capturing
      // the live native surface with RepaintBoundary.toImage() freezes the
      // UI thread, so it is intentionally avoided.
      if (!_mountNeighborSurfaces &&
          !_neighborMountScheduled &&
          _surfaceTreeEnabled &&
          FeedNeighborMountPolicy.mayMountNeighbors(
            activeHasFirstFrame: true,
            warmEntry: _args.warmStart,
          )) {
        _neighborMountScheduled = true;
        FeedNeighborMountPolicy.scheduleNeighborMount(
          activeHasFirstFrame: true,
          warmEntry: _args.warmStart,
          stillNeeded: () =>
              mounted && !_mountNeighborSurfaces && _surfaceTreeEnabled,
          onMount: () {
            if (!mounted || _mountNeighborSurfaces || !_surfaceTreeEnabled) {
              return;
            }
            setState(() => _mountNeighborSurfaces = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !_mountNeighborSurfaces) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _feedController.maintainAdjacentNativePreloads();
              });
            });
          },
        );
      }
    }

    // Preload may finish *after* the user already dragged past the early
    // activate threshold — retry activate without waiting for the next
    // scroll tick.
    _tryEarlyActivateFromPreload(state);

    final target = state.autoAdvanceToEpisodeNo;
    if (target != null) {
      if (_feedController.overlayHoldsAdvance) {
        _feedController.consumeAutoAdvance();
        return;
      }
      // Same as picker / detail resume: jump the pager *before* activate.
      // activate+animateToPage left PageController.page on the old episode,
      // so migrateToActive played the next slot one screen off — lightweight
      // AVPlayerLayer never becomes readyForDisplay → "No native video frame
      // after 4000ms" on A/B/C as retries rotate.
      _feedController.consumeAutoAdvance();
      unawaited(_jumpPagerAndActivate(target));
      return;
    }
  }

  void _maybeOpenInitialComments(VideoFeedState state) {
    if (_initialCommentsOpened || !_args.openComments) return;
    final play = state.currentPlay;
    final episodeId = _args.commentEpisodeId ?? play?.episodeId;
    if (play == null || episodeId == null || episodeId.isEmpty) {
      if (!_initialCommentsWaitLogged) {
        _initialCommentsWaitLogged = true;
        StoryLogger.d(
          'Waiting to open notification comments workId=${_args.workId} '
          'routeEpisodeId=${_args.commentEpisodeId} '
          'stateEpisodeNo=${state.currentEpisodeNo} '
          'hasCurrentPlay=${play != null}',
          tag: 'NotificationNavigation',
        );
      }
      return;
    }

    _initialCommentsOpened = true;
    StoryLogger.i(
      'Opening notification comments workId=${_args.workId} '
      'episodeId=$episodeId episodeNo=${state.currentEpisodeNo} '
      'commentId=${_args.highlightedComment?.commentId}',
      tag: 'NotificationNavigation',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        StoryLogger.w(
          'Skip opening notification comments: player page unmounted',
          tag: 'NotificationNavigation',
        );
        return;
      }
      unawaited(
        _holdWithCollapsedPlayer(
          () => StoryBottomSheet.showCommentSheet<void>(
            context: context,
            builder: (_) => CommentBottomSheet(
              dramaId: _args.workId,
              episodeId: episodeId,
              episodeNo: _args.isShortVideo ? null : state.currentEpisodeNo,
              commentCount: play.commentCount ?? 0,
              highlightedComment: _args.highlightedComment,
              onCommentCountChanged: (_) => _feedController.onCommentPosted(),
              sheetHeightNotifier: _playerSheetHeight,
            ),
          ),
        ),
      );
    });
  }

  /// If the scroll offset is already committed toward a newly-ready preload
  /// slot, activate immediately (covers the race where preload completes
  /// mid-swipe after the early-activate check already ran).
  void _tryEarlyActivateFromPreload(VideoFeedState state) {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == null) return;

    final activeIndex = state.currentEpisodeNo - 1;
    final preloadIdx = page.round();
    final targetEpisode = preloadIdx + 1;
    if (!FeedPageScrollEarlyActivate.dramaCommittedToTarget(
      page: page,
      activeIndex: activeIndex,
      targetIndex: preloadIdx,
      targetEpisode: targetEpisode,
      frameReadyEpisodeNos: state.frameReadyEpisodeNos,
      settledEpisodeNos: _feedController.settledPreloadEpisodeNos,
      alreadyActivatedIndex: _activatedPageIndex.value,
    )) {
      return;
    }

    _scrollSettleDebouncer.cancel();
    _activatedPageIndex.value = preloadIdx;
    _feedController.onSwipeToIndex(preloadIdx);
  }

  void _toggleFullscreen() {
    _isFullscreen.value = !_isFullscreen.value;
  }

  /// Hold auto-advance and collapse the player into the top band while a
  /// fixed-height comment / drama sheet is presented.
  Future<T> _holdWithCollapsedPlayer<T>(Future<T> Function() action) async {
    _playerSheetHeight.value = StoryConstants.playerOverlaySheetHeight;
    _playerSheetOpen.value = true;
    try {
      return await _feedController.holdAutoAdvance(action);
    } finally {
      if (mounted) _playerSheetOpen.value = false;
    }
  }

  /// Hold auto-advance while system share is up (iOS presents share from an
  /// elevated UIWindow so PlatformViews stay mounted and playing).
  Future<void> _aroundShare(Future<void> Function() share) async {
    await _feedController.holdAutoAdvance(share);
  }

  bool get _shouldPersistResumeEpisode =>
      FeedPersistPolicy.shouldPersistDramaCursor(_args);

  int _syncCurrentEpisodeSelection() {
    final episodeNo = _feedController.currentEpisodeNo;
    if (!_shouldPersistResumeEpisode) return episodeNo;
    // Keep the detail page selection in sync even when its family provider
    // was recreated while covered, and also return the value to _openPlayer.
    ref
        .read(currentDramaEpisodeProvider(_args.dramaId).notifier)
        .setEpisode(episodeNo);
    return episodeNo;
  }

  void _popWithCurrentEpisode() {
    unawaited(_exitFeed());
  }

  /// Pause while surfaces still exist, then unmount TextureViews in stages
  /// before popping. Simultaneous dispose of three Android texture players
  /// blocks the UI thread for seconds (see `Skipped 1033 frames` logs).
  Future<void> _exitFeed([int? result]) async {
    if (_exitTeardownRunning) return;
    _exitTeardownRunning = true;
    final episodeNo = result ?? _syncCurrentEpisodeSelection();

    try {
      await _feedController.onAppBackground();
    } catch (_) {
      // Provider / NO_VIEW races during rapid re-entry.
    }

    if (mounted && _mountNeighborSurfaces) {
      setState(() => _mountNeighborSurfaces = false);
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    if (mounted && _surfaceTreeEnabled) {
      setState(() => _surfaceTreeEnabled = false);
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    if (!mounted) return;
    Navigator.of(context).pop(episodeNo);
  }

  void _showEpisodeSelector() {
    final feedState = ref.read(videoFeedControllerProvider(_args));
    final total = _feedController.episodeCount;
    if (total < 1) return;

    unawaited(() async {
      _ignoreRouteCover = true;
      final epNo = await EpisodePickerSheet.show(
        context: context,
        dramaId: _args.dramaId,
        totalEpisodes: total,
        currentEpisode: feedState.currentEpisodeNo,
        fallbackCoverUrl: _resolveCoverUrl(feedState.dramaDetail?.coverUrl),
      );
      if (!mounted) return;
      _ignoreRouteCover = false;

      if (epNo == null) return;
      if (!mounted) return;

      // Jump first so the destination surface is on-screen, then wait for the
      // modal route to finish disposing before play (iOS platform views).
      await _jumpPagerAndActivate(epNo);
    }());
  }

  /// Title / 短剧 Tab overlay. Keep native surfaces mounted (same as the
  /// episode picker) so Android does not composite a torn-down SurfaceView
  /// over the sheet.
  void _showDramaDetailSheet({
    DramaDetailSheetTab initialTab = DramaDetailSheetTab.drama,
  }) {
    if (_args.isShortVideo) return;

    unawaited(() async {
      _ignoreRouteCover = true;
      final play = _feedController.currentPlay;
      final selected = await _holdWithCollapsedPlayer(
        () => DramaDetailSheet.show(
          context: context,
          dramaId: _args.dramaId,
          coverUrl: _resolveCoverUrl(_feedController.dramaDetail?.coverUrl),
          initialTab: initialTab,
          episodeNo: play?.episodeNo ?? _feedController.currentEpisodeNo,
          episodeId: play?.episodeId,
          contentType: _feedController.contentType,
          sheetHeightNotifier: _playerSheetHeight,
        ),
      );
      if (!mounted) return;
      _ignoreRouteCover = false;

      if (selected == null) return;
      await _jumpPagerAndActivate(selected);
    }());
  }

  /// Build current/previous/next NativeVideoPlayer surfaces.
  ///
  /// Positions follow the continuous [PageController.page] so video surfaces
  /// track the finger during a swipe (TikTok-style video-to-video handoff).
  ///
  /// Controllers are **page-owned** and always mounted from the first frame so
  /// platform views exist before [NativeVideoPlayerController.initialize].
  ///
  /// Use local [ObjectKey]s on [Positioned] (not [GlobalKey] on the player).
  /// GlobalKey + Platform View + moving Positioned during preload swap trips
  /// semantics `identical(childRenderObject, parentRenderObject)`.
  List<Widget> _buildTriplePlayerWidgets() {
    if (!_surfaceTreeEnabled) return const <Widget>[];
    final a = _nativePlayerA;
    final b = _nativePlayerB;
    final c = _nativePlayerC;
    if (a == null) return const <Widget>[];

    final size = MediaQuery.sizeOf(context);
    final height = size.height;
    final screenWidth = size.width;
    final sheetOpen = _playerSheetOpen.value;
    final collapse = sheetOpen;
    final page = _pageController.hasClients
        ? (_pageController.page ?? _pageIndex.value.toDouble())
        : _pageIndex.value.toDouble();

    final episodeByController = <NativeVideoPlayerController, int>{
      for (final surface in _feedController.nativePlayerSurfaces)
        surface.controller: surface.episodeNo,
    };

    // Fixed A→B→C order so Stack children match by index; ObjectKey keeps
    // each Positioned/player Element tied to its controller across swaps.
    // Neighbor slots stay unmounted until the first episode is ready.
    final slots = <(NativeVideoPlayerController, int)>[
      (a, episodeByController[a] ?? -1),
      if (_mountNeighborSurfaces && b != null)
        (b, episodeByController[b] ?? -2),
      if (_mountNeighborSurfaces && c != null)
        (c, episodeByController[c] ?? -3),
    ];

    final currentEp = _feedController.currentEpisodeNo;
    final widgets = <Widget>[];
    for (final (controller, episodeNo) in slots) {
      // Layout follow is required for near-screen textures (Transform alone
      // has frozen painted frames while audio continues). Park slots farther
      // than ~1.25 pages so jump/stale mappings do not thrash Platform View
      // geometry every scroll tick.
      // Page stride stays full-screen height even while the visible surface
      // is collapsed above a sheet.
      final top = episodeNo > 0
          ? PlayerSheetLayoutCoordinator.slotTopOffset(
              page: page,
              slotIndex: episodeNo - 1,
              pageHeight: height,
            )
          : height * 2.0;
      // Shared active-slot matcher (index for short-drama; recommend uses
      // playbackId). Prefer identity when both sides have real ids.
      final isActive = PlayerSheetLayoutCoordinator.isActiveSlot(
        slotPlaybackId: null,
        slotIndex: episodeNo > 0 ? episodeNo - 1 : null,
        activePlaybackId: null,
        currentIndex: currentEp > 0 ? currentEp - 1 : -1,
      );
      final layout = PlayerSheetLayoutCoordinator.layoutForSlot(
        sheetOpen: collapse,
        collapseEnabled: true,
        isActiveSlot: isActive,
        windowHeight: height,
        bodyHeight: height,
        sheetHeight: _playerSheetHeight.value,
      );
      final playerHeight = layout.playerHeight;
      widgets.add(
        Positioned(
          key: ObjectKey(controller),
          top: top,
          left: 0,
          right: 0,
          height: playerHeight,
          child: SizedBox(
            width: screenWidth,
            height: playerHeight,
            child: ClipRect(
              child: VideoFeedPlayerSurface(
                key: ObjectKey(controller),
                controller: controller,
                fitCollapsedBand: layout.isCollapsed,
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (FeedAppLifecyclePolicy.shouldMarkBackground(state)) {
      _appForeground = false;
      _feedController.onAppBackground();
      _syncWakeLock();
      return;
    }
    if (FeedAppLifecyclePolicy.shouldMarkForeground(state)) {
      _appForeground = true;
      _feedController.onAppForeground();
      _syncWakeLock();
    }
  }

  void _syncWakeLock([VideoFeedState? state]) {
    if (!mounted) {
      unawaited(PlaybackWakeLock.current.release());
      return;
    }
    final playing = state?.isPlaying ?? _feedController.isPlaying;
    final userPaused = state?.isUserPaused ?? _feedController.isUserPaused;
    final keepOn = PlaybackWakeLockPolicy.shouldKeepScreenOn(
      isPlaying: playing,
      isPlaybackVisible: PlaybackVisibility.isPlaybackVisible(_visibilityKind),
      userPaused: userPaused,
    );
    unawaited(PlaybackWakeLock.current.apply(keepOn: keepOn));
  }

  /// Last episode overscroll → [listNoMoreData] (same copy as recommend).
  ///
  /// Prefer [_checkLastEpisodeOverscrollToast] (page listener): video feed uses
  /// [BouncingScrollPhysics], which does not dispatch [OverscrollNotification].
  /// Keep this for clamping / glow overscroll if physics change.
  bool _onEpisodeScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollEndNotification) {
      _endToastQueued = false;
      return false;
    }
    final metrics = notification.metrics;
    final pastEndByPixels =
        metrics.pixels > metrics.maxScrollExtent + _pastEndToastPx;
    final pastEndByOverscroll =
        notification is OverscrollNotification && notification.overscroll > 0;
    if (!pastEndByPixels && !pastEndByOverscroll) return false;
    _queueLastEpisodeNoMoreToast();
    return false;
  }

  /// Bouncing physics: past-end is visible as pixels beyond [maxScrollExtent].
  void _checkLastEpisodeOverscrollToast() {
    if (!_pageController.hasClients) return;
    final pos = _pageController.position;
    if (!pos.hasContentDimensions || !pos.hasPixels) return;

    if (pos.pixels <= pos.maxScrollExtent + _pastEndToastPx) {
      if (pos.pixels <= pos.maxScrollExtent) {
        _endToastQueued = false;
      }
      return;
    }
    _queueLastEpisodeNoMoreToast();
  }

  void _queueLastEpisodeNoMoreToast() {
    if (_endToastQueued) return;
    final total = _feedController.episodeCount;
    if (total <= 0) return;
    final pageIndex = (_pageController.hasClients
            ? (_pageController.page?.round() ?? _pageIndex.value)
            : _pageIndex.value)
        .clamp(0, total - 1);
    if (!FeedPlaybackPolicy.shouldToastNoMoreItems(
      currentIndex: pageIndex,
      itemCount: total,
      hasMore: false,
    )) {
      return;
    }
    _endToastQueued = true;
    _toastNoMoreEpisodesIfNeeded(pageIndex: pageIndex, itemCount: total);
  }

  void _toastNoMoreEpisodesIfNeeded({
    required int pageIndex,
    required int itemCount,
  }) {
    if (!FeedPlaybackPolicy.shouldToastNoMoreItems(
      currentIndex: pageIndex,
      itemCount: itemCount,
      hasMore: false,
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

  void _onAuthRouteCover(bool covering) {
    if (!mounted) return;
    _authOverlayCovering = covering;
    if (covering) {
      unawaited(_feedController.onRouteCovered());
      scheduleFeedAuthCoverSurfaceTeardown(
        mounted: () => mounted,
        stillCovering: () => _authOverlayCovering,
        shouldUnmount: () =>
            !PlaybackVisibility.shouldMountSurfaces(_visibilityKind),
        unmount: _unmountNativeSurfacesForCover,
      );
      _syncWakeLock();
      return;
    }
    if (PlaybackVisibility.shouldMountSurfaces(_visibilityKind)) {
      _remountNativeSurfacesAfterCover();
    }
    _feedController.onPageRevealed();
    _syncWakeLock();
  }

  @override
  void dispose() {
    VideoFeedNavigation.unregister(_args);
    WidgetsBinding.instance.removeObserver(this);
    PlaybackAuthRouteObserver.instance.removeListener(_onAuthRouteCover);
    unawaited(PlaybackWakeLock.current.release());
    _routeSubscription.dispose(this);
    _scrollSettleDebouncer.dispose();
    _pageController.removeListener(_onPageScroll);
    PlaybackFrameCacheService.instance.revisions.removeListener(
      _onFrameCacheRevision,
    );
    _controllerSubscription?.close();
    _controllerSubscription = null;
    _pageIndex.dispose();
    _activatedPageIndex.dispose();
    _isFullscreen.dispose();
    _playerSheetOpen.dispose();
    _playerSheetHeight.dispose();
    _coverRevision.dispose();
    _pageController.dispose();
    // Detach engines first so they cannot pause/dispose these controllers.
    try {
      _feedController.releasePlayersOwnedByPage();
    } catch (_) {
      // Provider may already be disposed.
    }
    // Platform views are already gone by widget unmount; dispose still runs
    // disposeController(id) for native cleanup. NO_VIEW on the view-routed
    // dispose call is expected and printed by the plugin — ignore here.
    final players = <NativeVideoPlayerController?>[
      _nativePlayerA,
      _nativePlayerB,
      _nativePlayerC,
    ];
    _nativePlayerA = null;
    _nativePlayerB = null;
    _nativePlayerC = null;
    unawaited(_disposePlayersStaggered(players));
    super.dispose();
  }

  /// Dispose native controllers sequentially after the route transition.
  ///
  /// Three concurrent AVPlayer disposes mid-pop wedge the iOS main thread
  /// and pause a successor Recommend player that already called play()
  /// (ACK without frames). Gate teardown so Recommend waits until idle.
  static Future<void> _disposePlayersStaggered(
    List<NativeVideoPlayerController?> players,
  ) async {
    NativeVideoPlayerCoordinator.beginTeardown();
    try {
      await Future<void>.delayed(StoryDurations.nativePlayerDisposeAfterPop);
      for (final player in players) {
        if (player == null) continue;
        try {
          await player.dispose().timeout(const Duration(seconds: 2));
        } catch (_) {
          // NO_VIEW / MissingPluginException / timeout after view teardown.
        }
        await Future<void>.delayed(StoryDurations.nativePlayerDisposeStagger);
      }
    } finally {
      NativeVideoPlayerCoordinator.endTeardown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = videoFeedControllerProvider(_args);
    final detailCoverUrl = ref.watch(
      feedProvider.select((s) => s.dramaDetail?.coverUrl),
    );
    final dramaCoverUrl = _resolveCoverUrl(detailCoverUrl);

    return PopScope<int>(
      // Intercept back so we can stagger TextureView teardown before the
      // route unmounts all three surfaces on one frame.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_exitFeed(result is int ? result : null));
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: StoryColors.footer,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          // Disable semantics for the whole feed: Platform Views + moving
          // Positioned players trip Flutter's semantics geometry assertion
          // (`identical(childRenderObject, parentRenderObject)`).
          body: ExcludeSemantics(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ─── Three-slot video layer ───────────────────────────
                // Track PageController continuously so surfaces move with the
                // finger; preload slot may be N+1 or N-1.
                if (_surfaceTreeEnabled && _nativePlayerA != null)
                  _PlayerLayerBuilder(
                    pageController: _pageController,
                    pageIndex: _pageIndex,
                    playerSheetOpen: _playerSheetOpen,
                    playerSheetHeight: _playerSheetHeight,
                    feedArgs: _args,
                    feedController: _feedController,
                    buildTriplePlayers: _buildTriplePlayerWidgets,
                  ),
                // PageView layer — rebuilds only on page/cover/status state,
                // decoupled from frequent overlay updates (isPlaying, duration,
                // like-count) so scrolling stays cheap.
                Positioned.fill(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _pageIndex,
                    builder: (context, visibleIndex, _) {
                      return ValueListenableBuilder<int>(
                        valueListenable: _coverRevision,
                        builder: (context, _, _) {
                          return Consumer(
                        builder: (context, ref, _) {
                          final total = _feedController.episodeCount;
                          final loadedEp = ref.watch(
                            feedProvider.select((s) => s.loadedEpisodeNo),
                          );
                          final status = ref.watch(
                            feedProvider.select((s) => s.status),
                          );
                          // episodePlays signature for current±1 is watched above.
                          final episodeErrors = ref.watch(
                            feedProvider.select((s) => s.episodeErrors),
                          );
                          final currentEp = ref.watch(
                            feedProvider.select((s) => s.currentEpisodeNo),
                          );
                          final playerSurfaceVisible = ref.watch(
                            feedProvider.select((s) => s.playerSurfaceVisible),
                          );
                          final preloadedEpisodes = ref.watch(
                            feedProvider.select((s) => s.preloadedEpisodeNos),
                          );
                          final playedEpisodes = ref.watch(
                            feedProvider.select((s) => s.playedEpisodeNos),
                          );
                          final frameReadyEpisodes = ref.watch(
                            feedProvider.select((s) => s.frameReadyEpisodeNos),
                          );
                          // Frame-cache keys need episodeId for current ±1 only —
                          // avoid watching the whole episodePlays map.
                          ref.watch(
                            feedProvider.select((s) {
                              String sig(int ep) {
                                final p = s.episodePlays[ep];
                                return p?.episodeId ?? '';
                              }

                              final cur = s.currentEpisodeNo;
                              return (sig(cur - 1), sig(cur), sig(cur + 1));
                            }),
                          );

                          final episodeCoverUrls = ref.watch(
                            feedProvider.select((s) => s.episodeCoverUrls),
                          );

                          return NotificationListener<ScrollNotification>(
                            onNotification: _onEpisodeScrollNotification,
                            child: PageView.builder(
                            controller: _pageController,
                            scrollDirection: Axis.vertical,
                            allowImplicitScrolling: true,
                            physics: const SnappyPageScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: total,
                            itemBuilder: (context, index) {
                              final epNo = index + 1;
                              final isCurrentPage = index == visibleIndex;
                              final isLiveChrome = epNo == currentEp;
                              final hasNativeSurface = preloadedEpisodes
                                  .contains(epNo);
                              final neighborHasDecodedFrame =
                                  hasNativeSurface &&
                                  frameReadyEpisodes.contains(epNo);
                              // Keep revealing while user-paused so the native
                              // surface holds the last decoded frame.
                              final surfaceReady =
                                  isCurrentPage &&
                                  _surfaceTreeEnabled &&
                                  epNo == loadedEp &&
                                  playerSurfaceVisible &&
                                  frameReadyEpisodes.contains(epNo);
                              final wasPlayed = playedEpisodes.contains(epNo);
                              final reveal = shouldUnmountFeedCover(
                                isCurrentPage: isCurrentPage,
                                currentSurfaceReady: surfaceReady,
                                neighborHasDecodedFrame:
                                    neighborHasDecodedFrame,
                                currentRevealLatched: _coverRevealLatched
                                    .contains(epNo),
                                allowLatchedReveal: _surfaceTreeEnabled,
                              );
                              final epCover = _stableCoverForEpisode(
                                epNo,
                                episodeCover: episodeCoverUrls[epNo],
                              );
                              final frameKey = _frameCacheKey(epNo);
                              final cachedFrame =
                                  PlaybackFrameCacheService.instance.peek(
                                    frameKey,
                                  ) ??
                                  _firstFrameBytes[epNo];
                              if (cachedFrame == null) {
                                unawaited(_primeFrameCacheAround(epNo));
                              }
                              final warmLoaded =
                                  hasNativeSurface ||
                                  cachedFrame != null ||
                                  wasPlayed;
                              final showLoading =
                                  isCurrentPage &&
                                  !reveal &&
                                  !warmLoaded &&
                                  (status == FeedPlaybackStatus.buffering ||
                                      status == FeedPlaybackStatus.idle ||
                                      status == FeedPlaybackStatus.loading);

                              return FeedPageItem(
                                chrome: isCurrentPage
                                    ? ListenableBuilder(
                                        listenable: _playerSheetOpen,
                                        builder: (context, _) {
                                          if (_playerSheetOpen.value) {
                                            return const SizedBox.shrink();
                                          }
                                          return ListenableBuilder(
                                            listenable: _isFullscreen,
                                            builder: (context, _) =>
                                                VideoFeedOverlays(
                                                  controller: _feedController,
                                                  episodeNo: epNo,
                                                  isLiveChrome: isLiveChrome,
                                                  title: _args.title,
                                                  isFullscreen:
                                                      _isFullscreen.value,
                                                  onEpisodeSelector:
                                                      _showEpisodeSelector,
                                                  onToggleFullscreen:
                                                      _toggleFullscreen,
                                                  onBack:
                                                      _popWithCurrentEpisode,
                                                  onSelectEpisode:
                                                      _jumpPagerAndActivate,
                                                  holdWithCollapsedPlayer:
                                                      _holdWithCollapsedPlayer,
                                                  sheetHeightNotifier:
                                                      _playerSheetHeight,
                                                  aroundShare: _aroundShare,
                                                  onOpenCharacters: () =>
                                                      _showDramaDetailSheet(
                                                        initialTab:
                                                            DramaDetailSheetTab
                                                                .characters,
                                                      ),
                                                  onTitleTap: _args.isShortVideo
                                                      ? null
                                                      : () =>
                                                            _showDramaDetailSheet(),
                                                ),
                                          );
                                        },
                                      )
                                    : null,
                                child: VideoFeedPageItem(
                                  episodeNo: epNo,
                                  totalEpisodes: total,
                                  coverUrl: epCover,
                                  dramaCoverUrl: dramaCoverUrl,
                                  firstFrameBytes: cachedFrame,
                                  isCurrentPage: isCurrentPage,
                                  revealPlayer: reveal,
                                  showLoading: showLoading,
                                  hasError: episodeErrors.containsKey(epNo),
                                  onRetry: episodeErrors.containsKey(epNo)
                                      ? () =>
                                            _feedController.selectEpisode(epNo)
                                      : null,
                                ),
                              );
                            },
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
            ),
          ),
        ),
      ),
    );
  }
}

/// Separates the per-frame player positioning from the infrequent feed-state
/// rebuilds. The original [ListenableBuilder] merged [_pageController] with
/// 5 [ref.watch] selectors — every scroll tick (~60fps) evaluated all
/// selectors even though their backing state rarely changes. This widget
/// listens to [_pageController] for continuous surface tracking while the
/// feed-state selectors only trigger rebuilds when their values actually
/// change (via a dedicated listener that calls setState).
class _PlayerLayerBuilder extends ConsumerStatefulWidget {
  const _PlayerLayerBuilder({
    required this.pageController,
    required this.pageIndex,
    required this.playerSheetOpen,
    required this.playerSheetHeight,
    required this.feedArgs,
    required this.feedController,
    required this.buildTriplePlayers,
  });

  final PageController pageController;
  final ValueNotifier<int> pageIndex;
  final ValueNotifier<bool> playerSheetOpen;
  final ValueNotifier<double> playerSheetHeight;
  final VideoFeedArgs feedArgs;
  final VideoFeedController feedController;
  final List<Widget> Function() buildTriplePlayers;

  @override
  ConsumerState<_PlayerLayerBuilder> createState() =>
      _PlayerLayerBuilderState();
}

class _PlayerLayerBuilderState extends ConsumerState<_PlayerLayerBuilder> {
  /// Snapshot of the feed state fields that affect player positioning.
  int _currentEpisodeNo = 0;
  int? _loadedEpisodeNo;
  Set<int> _preloadedEpisodeNos = const {};

  /// Monotonic revision counter — incremented when any feed selector changes.
  /// The [_pageController] listener uses this to decide whether a rebuild
  /// is needed (selectors changed since last frame) or can be skipped
  /// (only sub-pixel position changed).
  int _feedRevision = 0;
  int _lastBuiltRevision = -1;

  ProviderSubscription<VideoFeedState>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribe();
    widget.pageController.addListener(_onPageTick);
    widget.pageIndex.addListener(_onPageTick);
    // Sheet height is nested under sheet-open in [build] — do not rebuild
    // feed-revision tracking on every height notify while closed.
    widget.playerSheetOpen.addListener(_onPageTick);
  }

  @override
  void didUpdateWidget(covariant _PlayerLayerBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pageController, widget.pageController)) {
      oldWidget.pageController.removeListener(_onPageTick);
      widget.pageController.addListener(_onPageTick);
    }
    if (!identical(oldWidget.pageIndex, widget.pageIndex)) {
      oldWidget.pageIndex.removeListener(_onPageTick);
      widget.pageIndex.addListener(_onPageTick);
    }
    if (!identical(oldWidget.playerSheetOpen, widget.playerSheetOpen)) {
      oldWidget.playerSheetOpen.removeListener(_onPageTick);
      widget.playerSheetOpen.addListener(_onPageTick);
    }
    if (!identical(oldWidget.feedArgs, widget.feedArgs)) {
      _sub?.close();
      _subscribe();
    }
  }

  void _subscribe() {
    _sub = ref.listenManual<VideoFeedState>(
      videoFeedControllerProvider(widget.feedArgs),
      (_, next) {
        var changed = false;
        if (next.currentEpisodeNo != _currentEpisodeNo) {
          _currentEpisodeNo = next.currentEpisodeNo;
          changed = true;
        }
        if (next.loadedEpisodeNo != _loadedEpisodeNo) {
          _loadedEpisodeNo = next.loadedEpisodeNo;
          changed = true;
        }
        if (next.preloadedEpisodeNos != _preloadedEpisodeNos) {
          _preloadedEpisodeNos = next.preloadedEpisodeNos;
          changed = true;
        }
        if (changed) {
          _feedRevision++;
          // Trigger a rebuild on the next frame so the player positions
          // are recalculated with the new feed state.
          if (mounted) setState(() {});
        }
      },
      fireImmediately: true,
    );
  }

  void _onPageTick() {
    if (!mounted) return;
    // Only rebuild when feed selectors changed since last build.
    // Sub-pixel-only scrolls (same revision) skip the rebuild — the
    // ListenableBuilder already handles continuous surface tracking via
    // the pageController listener in the parent; here we only need to
    // rebuild the Stack when feed state changes or on the first frame.
    if (_feedRevision != _lastBuiltRevision) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _sub?.close();
    widget.pageController.removeListener(_onPageTick);
    widget.pageIndex.removeListener(_onPageTick);
    widget.playerSheetOpen.removeListener(_onPageTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _lastBuiltRevision = _feedRevision;
    // Keep one Stack under this builder. Nesting a height ListenableBuilder
    // only while the sheet is open swapped Stack ↔ ListenableBuilder and
    // remounted Platform Views (black band above the sheet).
    //
    // [playerSheetHeight] only notifies when a sheet reports — not on scroll.
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.pageController,
        widget.pageIndex,
        widget.playerSheetOpen,
        widget.playerSheetHeight,
      ]),
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: widget.buildTriplePlayers(),
        );
      },
    );
  }
}
