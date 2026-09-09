import 'dart:async';
import 'dart:math' as math;

import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/core.dart';
import '../../core/json_helpers.dart';
import '../../core/story_constants.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../services/native_player_bootstrap.dart';
import '../../services/native_video_player_coordinator.dart';
import '../../services/video_precache_service.dart';
import '../../styles/story_format.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../utils/format_number.dart';
import '../../widgets/story_cached_image.dart';
import '../badge/content_badge.dart';
import 'theater_hero_actor_strip.dart';

/// Auto-rotating hero banner carousel from global config.
class TheaterHeroBanner extends StatefulWidget {
  /// Content height below the status bar. Total painted height is this plus
  /// the top safe inset so the cover fills under the status bar.
  static const double contentHeight = 380;

  /// Gap between the banner and the category tabs below it.
  static const double bottomGap = 12;

  final List<BannerItem> items;
  final List<DramaListItem> dramaItems;
  final void Function(BannerItem item, DramaDetail? detail)? onBannerTap;
  final bool isPageVisible;

  /// When false, hides the drama [ContentBadge] above the title.
  final bool showContentBadge;

  const TheaterHeroBanner({
    super.key,
    required this.items,
    this.dramaItems = const <DramaListItem>[],
    this.onBannerTap,
    this.isPageVisible = true,
    this.showContentBadge = false,
  });

  @override
  State<TheaterHeroBanner> createState() => _TheaterHeroBannerState();
}

class _TheaterHeroBannerState extends State<TheaterHeroBanner> {
  late PageController _pageController;
  Timer? _autoRotateTimer;

  /// Real (logical) page index — drives indicators and slide focus without
  /// rebuilding the entire [PageView] on every swipe.
  final ValueNotifier<int> _realPageNotifier = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, DramaDetail>> _detailsNotifier =
      ValueNotifier<Map<String, DramaDetail>>(const {});
  final Map<String, Future<void>> _detailLoads = {};
  int _virtualCurrentPage = 0;
  final ValueNotifier<bool> _isMutedNotifier = ValueNotifier<bool>(true);
  static const int _virtualMultiplier = 3;

  int get _realCurrentPage => _realPageNotifier.value;

  @override
  void initState() {
    super.initState();
    final itemsCount = _items.length;
    if (itemsCount > 1) {
      _realPageNotifier.value = 0;
      _virtualCurrentPage = itemsCount * (_virtualMultiplier ~/ 2);
      _pageController = PageController(initialPage: _virtualCurrentPage);
    } else {
      _pageController = PageController();
    }
    _setAutoRotate();
    _precacheBanners();
    // Defer video warm so it does not contend with first-slide init.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _armVideoAdvanceGuards();
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _precacheBannerVideos();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _items.isEmpty) return;
      _ensureBannerDetail(_items[_realCurrentPage]);
    });
  }

  @override
  void didUpdateWidget(covariant TheaterHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPageVisible != oldWidget.isPageVisible) {
      if (widget.isPageVisible) {
        _setAutoRotate();
        _armVideoAdvanceGuards();
      } else {
        _cancelVideoAdvanceGuards();
        _setAutoRotate(enabled: false);
        _isVideoPlaying = false;
      }
    }
    if (widget.items.length != oldWidget.items.length) {
      _setAutoRotate(enabled: false);
      _pageController.dispose();

      final itemsCount = _items.length;
      if (itemsCount > 1) {
        _realPageNotifier.value = 0;
        _virtualCurrentPage = itemsCount * (_virtualMultiplier ~/ 2);
        _pageController = PageController(initialPage: _virtualCurrentPage);
      } else {
        _pageController = PageController();
      }
      _setAutoRotate();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _items.isEmpty) return;
        _ensureBannerDetail(_items[_realCurrentPage]);
      });
    } else if (!identical(widget.items, oldWidget.items)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _items.isEmpty) return;
        _ensureBannerDetail(_items[_realCurrentPage]);
      });
    }
  }

  /// Resolve the focused banner from the cached drama-detail endpoint.
  ///
  /// [DramaRepository.getDetail] is a memory → Hive → network CacheChain and
  /// also coalesces concurrent requests by cache key. This local map avoids
  /// even repeating the repository lookup when the virtual carousel cycles
  /// back to another copy of the same banner.
  void _ensureBannerDetail(BannerItem item) {
    final dramaId = item.dramaId?.trim();
    if (dramaId == null || dramaId.isEmpty) return;
    if (_detailsNotifier.value.containsKey(dramaId)) return;
    if (_detailLoads.containsKey(dramaId)) return;

    final load = () async {
      try {
        final container = ProviderScope.containerOf(context);
        final result = await container
            .read(dramaRepositoryProvider)
            .getDetail(dramaId);
        final detail = result.dataOrNull;
        if (!mounted || detail == null) return;
        _detailsNotifier.value = {..._detailsNotifier.value, dramaId: detail};
      } catch (e, st) {
        StoryLogger.w(
          'Banner detail load failed: $dramaId',
          error: e,
          stackTrace: st,
          tag: 'TheaterHeroBanner',
        );
      } finally {
        _detailLoads.remove(dramaId);
      }
    }();
    _detailLoads[dramaId] = load;
    unawaited(load);
  }

  /// Precache the first 3 banner images to reduce perceived load time.
  void _precacheBanners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final items = _items;
      for (var i = 0; i < items.length && i < 3; i++) {
        final url = items[i].bannerUrl ?? items[i].thumbUrl;
        if (url != null && url.isNotEmpty) {
          // Match the on-screen decode size so precache doesn't hold full-res
          // bitmaps in memory (consistent with the banner CachedNetworkImage).
          precacheImage(
            ResizeImage(
              CachedNetworkImageProvider(url),
              width: StoryCachedImage.memCacheForLogicalWidth(
                context,
                StoryImageCache.cardCover,
              ),
            ),
            context,
          );
        }
      }
    });
  }

  /// Precache the upcoming slide only — never the focused URL (the active
  /// player already loads it). Warming current+neighbors on first paint
  /// starved decode and made the carousel feel stuck.
  void _precacheBannerVideos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final items = _items;
      if (items.length <= 1) return;
      final nextIndex = (_realCurrentPage + 1) % items.length;
      final videoUrl = resolvePreviewUrl(items[nextIndex]);
      if (videoUrl != null && _precachedBannerUrls.add(videoUrl)) {
        unawaited(
          VideoPrecacheService.instance.precacheUrl(
            videoUrl,
            context: VideoPrecacheContext.banner,
          ),
        );
      }
    });
  }

  bool _isVideoPlaying = false;
  Timer? _videoStallTimer;
  Timer? _videoMaxDwellTimer;

  bool _currentItemHasVideo() {
    final items = _items;
    if (items.isEmpty) return false;
    return _itemHasVideo(items[_realCurrentPage]);
  }

  void _cancelVideoAdvanceGuards() {
    _videoStallTimer?.cancel();
    _videoStallTimer = null;
    _videoMaxDwellTimer?.cancel();
    _videoMaxDwellTimer = null;
  }

  /// Video slides suppress the 5s image timer; without a stall / max-dwell
  /// guard a slow or hung preview leaves the carousel frozen on the cover.
  ///
  /// Stall must outlive [StoryConstants.bannerPlayerInitTimeout] so we do not
  /// advance while `loadUrl`/`play` is still within its legitimate window.
  void _armVideoAdvanceGuards() {
    _cancelVideoAdvanceGuards();
    if (!widget.isPageVisible) return;
    if (_items.length <= 1) return;
    if (!_currentItemHasVideo()) return;

    final stallAfter =
        StoryConstants.bannerPlayerInitTimeout + const Duration(seconds: 2);
    _videoStallTimer = Timer(stallAfter, () {
      if (!mounted || _isVideoPlaying) return;
      StoryLogger.w(
        'Banner preview stall — advancing carousel',
        tag: 'TheaterHeroBanner',
      );
      _onBannerVideoFailed(advanceImmediately: true);
    });
  }

  /// Image-only slides rotate on a periodic timer; video slides wait for
  /// playback end.  Call this to start/stop rotation based on current state.
  ///
  /// Always cancels the existing timer first.  When [enabled] is `true` a new
  /// periodic timer is started only if: the carousel is visible, there are at
  /// least 2 items, and no video is playing (or the current item is
  /// image-only).
  void _setAutoRotate({bool enabled = true}) {
    _autoRotateTimer?.cancel();
    _autoRotateTimer = null;
    if (!enabled) return;
    if (!widget.isPageVisible) return;
    if (_items.length <= 1) return;
    if (_isVideoPlaying || _currentItemHasVideo()) return;
    _autoRotateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _goToNextPage();
    });
  }

  void _goToNextPage() {
    if (!mounted || _isAdvancingPage) return;
    final items = _items;
    if (items.length <= 1) return;

    _isAdvancingPage = true;
    _virtualCurrentPage++;
    _pageController
        .animateToPage(
          _virtualCurrentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        )
        .whenComplete(() {
          if (mounted) _isAdvancingPage = false;
        });
  }

  void _onBannerVideoPlayingChanged(bool isPlaying) {
    if (!mounted) return;
    _isVideoPlaying = isPlaying;
    if (isPlaying) {
      _videoStallTimer?.cancel();
      _videoStallTimer = null;
      _videoMaxDwellTimer?.cancel();
      // Missed `completed` must not freeze rotation forever.
      _videoMaxDwellTimer = Timer(const Duration(seconds: 18), () {
        if (!mounted) return;
        _onBannerVideoCompleted();
      });
      _setAutoRotate(enabled: false);
      _precacheBannerVideos();
      return;
    }
    _videoMaxDwellTimer?.cancel();
    _videoMaxDwellTimer = null;
    if (!_currentItemHasVideo()) {
      _setAutoRotate();
    }
  }

  void _onBannerVideoCompleted() {
    if (!mounted) return;
    _cancelVideoAdvanceGuards();
    _isVideoPlaying = false;
    _setAutoRotate(enabled: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _goToNextPage();
    });
  }

  void _onBannerVideoFailed({bool advanceImmediately = false}) {
    if (!mounted) return;
    _cancelVideoAdvanceGuards();
    _isVideoPlaying = false;
    _setAutoRotate(enabled: false);
    if (advanceImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goToNextPage();
      });
      return;
    }
    _autoRotateTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _goToNextPage();
    });
  }

  @override
  void dispose() {
    _cancelVideoAdvanceGuards();
    _setAutoRotate(enabled: false);
    _pageController.dispose();
    _realPageNotifier.dispose();
    _detailsNotifier.dispose();
    _isMutedNotifier.dispose();
    super.dispose();
  }

  /// At most 10 banners — keeps carousel + preview-player cost bounded.
  static const int _maxBannerItems = 10;

  List<BannerItem> get _items {
    final items = widget.items;
    if (items.length > _maxBannerItems) {
      return items.sublist(0, _maxBannerItems);
    }
    return items;
  }

  /// Prefer non-empty HLS, then non-empty progressive MP4.
  static String? resolvePreviewUrl(BannerItem item) {
    final hls = item.previewHlsUrl?.trim();
    if (hls != null && hls.isNotEmpty) return hls;
    final mp4 = item.previewVideoUrl?.trim();
    if (mp4 != null && mp4.isNotEmpty) return mp4;
    return null;
  }

  bool _itemHasVideo(BannerItem item) => resolvePreviewUrl(item) != null;

  bool _isAdvancingPage = false;

  /// Tracks already-precached banner video URLs to avoid redundant native
  /// cache warming on rapid carousel rotations.
  final Set<String> _precachedBannerUrls = {};

  static const double contentHeight = TheaterHeroBanner.contentHeight;

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();

    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      margin: const EdgeInsets.only(bottom: TheaterHeroBanner.bottomGap),
      height: contentHeight + topInset,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (!mounted) return;
              // Update focus/indicators via ValueNotifier — avoid setState so
              // the PageView (and offscreen slides) are not rebuilt.
              _virtualCurrentPage = index;
              _realPageNotifier.value = index % items.length;
              _ensureBannerDetail(items[_realCurrentPage]);
              _isVideoPlaying = false;
              _setAutoRotate();
              _armVideoAdvanceGuards();
              _precacheBannerVideos();
            },
            itemCount: items.length > 1
                ? items.length * _virtualMultiplier
                : items.length,
            itemBuilder: (context, index) {
              final realIndex = index % items.length;
              return _BannerSlide(
                key: ValueKey('banner_${items[realIndex].dramaId}_$index'),
                item: items[realIndex],
                dramaItems: widget.dramaItems,
                detailsNotifier: _detailsNotifier,
                onTap: widget.onBannerTap,
                realIndex: realIndex,
                focusedPageNotifier: _realPageNotifier,
                isPageVisible: widget.isPageVisible,
                isMutedNotifier: _isMutedNotifier,
                showContentBadge: widget.showContentBadge,
                onVideoCompleted: _onBannerVideoCompleted,
                onVideoPlayingChanged: _onBannerVideoPlayingChanged,
                onVideoFailed: _onBannerVideoFailed,
              );
            },
          ),
          if (items.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: ValueListenableBuilder<int>(
                valueListenable: _realPageNotifier,
                builder: (context, realPage, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(items.length, (index) {
                      final isActive = realPage == index;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3.0),
                        width: isActive ? 8 : 6,
                        height: isActive ? 8 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Serializes banner native player teardown/init to avoid coordinator deadlocks.
class _BannerPlayerHandoff {
  _BannerPlayerHandoff._();

  static Future<void> _chain = Future<void>.value();

  static Future<T> run<T>(Future<T> Function() action) {
    final result = _chain.then((_) => action());
    _chain = result.then((_) {}, onError: (_) {});
    return result;
  }
}

class _BannerSlide extends StatefulWidget {
  final BannerItem item;
  final List<DramaListItem> dramaItems;
  final ValueListenable<Map<String, DramaDetail>> detailsNotifier;
  final void Function(BannerItem item, DramaDetail? detail)? onTap;
  final int realIndex;
  final ValueNotifier<int> focusedPageNotifier;
  final bool isPageVisible;
  final ValueNotifier<bool> isMutedNotifier;
  final bool showContentBadge;
  final VoidCallback? onVideoCompleted;
  final ValueChanged<bool>? onVideoPlayingChanged;
  final VoidCallback? onVideoFailed;

  const _BannerSlide({
    super.key,
    required this.item,
    required this.dramaItems,
    required this.detailsNotifier,
    this.onTap,
    required this.realIndex,
    required this.focusedPageNotifier,
    required this.isPageVisible,
    required this.isMutedNotifier,
    this.showContentBadge = false,
    this.onVideoCompleted,
    this.onVideoPlayingChanged,
    this.onVideoFailed,
  });

  @override
  State<_BannerSlide> createState() => _BannerSlideState();
}

class _BannerSlideState extends State<_BannerSlide>
    with WidgetsBindingObserver {
  NativeVideoPlayerController? _controller;
  bool _initialized = false;
  int? _currentPlayerId;
  int _initGeneration = 0;
  void Function(PlayerActivityEvent)? _activityListener;
  final Object _playerOwner = Object();
  Timer? _playbackWatchdog;
  bool _lastShouldPlay = false;
  DramaDetail? _detail;

  static int _playerIdCounter = 2000;
  static int _nextPlayerId() => _playerIdCounter++;

  bool get _isFocused => widget.focusedPageNotifier.value == widget.realIndex;

  bool get _shouldPlay => _isFocused && widget.isPageVisible;

  void _syncDetail({bool rebuild = true}) {
    final dramaId = widget.item.dramaId?.trim();
    final next = dramaId == null || dramaId.isEmpty
        ? null
        : widget.detailsNotifier.value[dramaId];
    if (identical(next, _detail)) return;
    _detail = next;
    if (rebuild && mounted) setState(() {});
  }

  void _onDetailsChanged() => _syncDetail();

  bool _isInitCurrent(int generation) {
    return mounted &&
        generation == _initGeneration &&
        _isFocused &&
        widget.isPageVisible &&
        _currentPlayerId != null;
  }

  void _markVideoSurfaceVisible() {
    if (_initialized || !mounted) return;
    setState(() => _initialized = true);
  }

  void _cancelPlaybackWatchdog() {
    _playbackWatchdog?.cancel();
    _playbackWatchdog = null;
  }

  void _startPlaybackWatchdog(int generation) {
    _cancelPlaybackWatchdog();
    // Align with bannerPlayerInitTimeout — 18s left the cover frozen too long.
    _playbackWatchdog = Timer(StoryConstants.bannerPlayerInitTimeout, () {
      if (!mounted || !_isInitCurrent(generation)) return;
      if (!_initialized) {
        StoryLogger.w(
          'Banner preview playback watchdog fired',
          tag: 'TheaterHeroBanner',
        );
        widget.onVideoFailed?.call();
      }
    });
  }

  void _onFocusedPageChanged() {
    _syncPlaybackForFocus();
  }

  void _syncPlaybackForFocus() {
    final shouldPlay = _shouldPlay;
    if (shouldPlay == _lastShouldPlay) return;
    _lastShouldPlay = shouldPlay;
    // Rebuild only this slide (Visibility / video surface), not the PageView.
    if (mounted) setState(() {});
    if (shouldPlay) {
      unawaited(_initPlayer());
    } else {
      // Invalidate in-flight initialize/load so the handoff queue is not
      // blocked by a 15s TimeoutException after the user already swiped away.
      _initGeneration++;
      unawaited(_pausePlayer(notifyPlayingChanged: true));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.isMutedNotifier.addListener(_handleMuteChanged);
    widget.focusedPageNotifier.addListener(_onFocusedPageChanged);
    widget.detailsNotifier.addListener(_onDetailsChanged);
    _syncDetail(rebuild: false);
    _lastShouldPlay = _shouldPlay;
    if (_lastShouldPlay) {
      unawaited(_initPlayer());
    }
  }

  @override
  void didUpdateWidget(covariant _BannerSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMutedNotifier != oldWidget.isMutedNotifier) {
      oldWidget.isMutedNotifier.removeListener(_handleMuteChanged);
      widget.isMutedNotifier.addListener(_handleMuteChanged);
    }
    if (widget.focusedPageNotifier != oldWidget.focusedPageNotifier) {
      oldWidget.focusedPageNotifier.removeListener(_onFocusedPageChanged);
      widget.focusedPageNotifier.addListener(_onFocusedPageChanged);
    }
    if (widget.detailsNotifier != oldWidget.detailsNotifier) {
      oldWidget.detailsNotifier.removeListener(_onDetailsChanged);
      widget.detailsNotifier.addListener(_onDetailsChanged);
    }
    if (widget.item.dramaId != oldWidget.item.dramaId ||
        widget.detailsNotifier != oldWidget.detailsNotifier) {
      _syncDetail(rebuild: false);
    }

    final urlChanged =
        _TheaterHeroBannerState.resolvePreviewUrl(oldWidget.item) !=
        _TheaterHeroBannerState.resolvePreviewUrl(widget.item);
    final visibilityChanged =
        widget.isPageVisible != oldWidget.isPageVisible ||
        widget.realIndex != oldWidget.realIndex;

    if (visibilityChanged) {
      if (!widget.isPageVisible) {
        // A paused SurfaceView still owns a native Android surface. Keeping
        // it mounted behind another route / IndexedStack tab can leak its
        // last frame above the covering page on some OEM compositors.
        // Detach the Flutter platform-view widget THIS frame — do not wait
        // for the handoff queue (init may still be awaiting loadUrl).
        _detachSurfaceForOcclusion();
      } else {
        _syncPlaybackForFocus();
      }
    } else if (_shouldPlay && urlChanged) {
      unawaited(_tearDownPlayer(notifyPlayingChanged: false));
      unawaited(_initPlayer());
    }
  }

  /// Synchronously remove the platform view from the tree, then dispose
  /// native resources on the handoff queue.
  void _detachSurfaceForOcclusion() {
    _lastShouldPlay = false;
    _initGeneration++;
    _cancelPlaybackWatchdog();
    if (_activityListener != null && _controller != null) {
      _controller!.removeActivityListener(_activityListener!);
    }
    _activityListener = null;

    final c = _controller;
    _controller = null;
    _currentPlayerId = null;
    _initialized = false;
    widget.onVideoPlayingChanged?.call(false);
    if (mounted) setState(() {});

    if (c == null) return;
    unawaited(
      _BannerPlayerHandoff.run(() async {
        try {
          await c.pause().timeout(const Duration(seconds: 2));
        } catch (e, st) {
          StoryLogger.w(
            'TheaterHeroBanner pause failed',
            error: e,
            stackTrace: st,
            tag: 'TheaterHeroBanner',
          );
        }
        await NativePlayerBootstrap.releaseOwner(
          _playerOwner,
          coordinator: NativeVideoPlayerCoordinator.bannerInstance,
        );
        try {
          await c.dispose().timeout(const Duration(seconds: 3));
        } catch (e, st) {
          StoryLogger.w(
            'TheaterHeroBanner dispose failed',
            error: e,
            stackTrace: st,
            tag: 'TheaterHeroBanner',
          );
        }
      }),
    );
  }

  void _handleMuteChanged() {
    _controller?.setVolume(widget.isMutedNotifier.value ? 0.0 : 1.0);
  }

  Future<void> _initPlayer({bool isRetry = false}) {
    if (isRetry) return _initPlayerBody(isRetry: true);
    return _BannerPlayerHandoff.run(() => _initPlayerBody());
  }

  Future<void> _initPlayerBody({bool isRetry = false}) async {
    final previewUrl = _TheaterHeroBannerState.resolvePreviewUrl(widget.item);
    if (previewUrl == null) return;
    if (!_isFocused || !widget.isPageVisible) return;

    // Always load the short banner preview URL. Substituting a cached episode
    // play URL (peekPrefetchedEpisode) used to pull the full ep1 stream and
    // regularly hit the 8s loadUrl timeout.
    final effectiveUrl = previewUrl;

    // If we have a paused controller (kept alive from previous visibility),
    // just re-acquire coordinator and resume playback.
    if (_controller != null && !isRetry) {
      final generation = ++_initGeneration;
      if (!mounted) return;
      _startPlaybackWatchdog(generation);
      try {
        await NativeVideoPlayerCoordinator.bannerInstance.acquire(_playerOwner);
        if (!_isInitCurrent(generation)) {
          // Bail-out must release the coordinator, otherwise the slot stays
          // held by an owner that no longer plays and every later acquire
          // deadlocks until the 5s timeout.
          await NativeVideoPlayerCoordinator.bannerInstance.release(
            _playerOwner,
          );
          return;
        }
        _activityListener = _buildActivityListener(generation);
        _controller!.addActivityListener(_activityListener!);
        await _controller!.play().timeout(
          StoryConstants.playerOperationTimeout,
        );
        if (!_isInitCurrent(generation)) return;
        _markVideoSurfaceVisible();
        _cancelPlaybackWatchdog();
        widget.onVideoPlayingChanged?.call(true);
        return;
      } catch (_) {
        _cancelPlaybackWatchdog();
        // Resume failed — fall through to full re-init.
      }
      if (mounted) {
        await _releasePlayer(notifyPlayingChanged: false);
      } else {
        return;
      }
    }

    unawaited(StoryDnsPreheater.preheat(effectiveUrl));

    await _releasePlayer(notifyPlayingChanged: false);

    final generation = ++_initGeneration;
    final pid = _nextPlayerId();
    _currentPlayerId = pid;

    final c = NativeVideoPlayerController(id: pid, showNativeControls: false);

    _controller = c;
    if (!mounted) return;
    setState(() {});

    await NativePlayerBootstrap.waitForViewReady(
      extraDelay: StoryDurations.playerViewReadyDelaySwitch,
    );
    if (!_isInitCurrent(generation)) return;

    _startPlaybackWatchdog(generation);

    try {
      await NativePlayerBootstrap.initialize(
        c,
        owner: _playerOwner,
        coordinator: NativeVideoPlayerCoordinator.bannerInstance,
        isCurrent: () => _isInitCurrent(generation),
        viewReadyDelay: StoryDurations.playerViewReadyDelaySwitch,
        timeout: StoryConstants.bannerPlayerInitTimeout,
      );
      if (!_isInitCurrent(generation)) return;

      await c.setVolume(widget.isMutedNotifier.value ? 0.0 : 1.0);
      if (!_isInitCurrent(generation)) return;

      _activityListener = _buildActivityListener(generation);
      c.addActivityListener(_activityListener!);

      await c
          .loadUrl(url: effectiveUrl)
          .timeout(StoryConstants.bannerPlayerInitTimeout);
      if (!_isInitCurrent(generation)) return;

      await c.play().timeout(StoryConstants.bannerPlayerInitTimeout);
      if (!_isInitCurrent(generation)) return;
      _markVideoSurfaceVisible();
      _cancelPlaybackWatchdog();
      widget.onVideoPlayingChanged?.call(true);
    } on NativePlayerInitCancelled {
      // Focus/visibility lost mid-init — drop the half-ready controller so the
      // next focus does a clean init instead of a failed resume.
      _cancelPlaybackWatchdog();
      await _releasePlayer(notifyPlayingChanged: false);
    } catch (e, stack) {
      if (!_isInitCurrent(generation)) {
        // Stale after swipe / stall advance — don't treat as a hard failure.
        _cancelPlaybackWatchdog();
        return;
      }
      _cancelPlaybackWatchdog();
      final isTimeout = e is TimeoutException;
      if (!isRetry && !isTimeout) {
        StoryLogger.w(
          'Banner preview init failed, retrying once',
          error: e,
          stackTrace: stack,
          tag: 'TheaterHeroBanner',
        );
        await _releasePlayer(notifyPlayingChanged: false);
        await _initPlayerBody(isRetry: true);
        return;
      }
      widget.onVideoPlayingChanged?.call(false);
      widget.onVideoFailed?.call();
      StoryLogger.w(
        'BannerSlide preview video initialize error: $e',
        error: e,
        stackTrace: stack,
        tag: 'TheaterHeroBanner',
      );
    }
  }

  /// Creates an activity listener bound to [generation] for stale-init
  /// protection. Shared by full init and resume paths.
  void Function(PlayerActivityEvent) _buildActivityListener(int generation) {
    return (event) {
      if (event.state == PlayerActivityState.completed) {
        _cancelPlaybackWatchdog();
        if (_isFocused && widget.isPageVisible && mounted) {
          widget.onVideoCompleted?.call();
        }
      } else if (event.state == PlayerActivityState.playing) {
        if (_isInitCurrent(generation)) {
          _markVideoSurfaceVisible();
          _cancelPlaybackWatchdog();
          widget.onVideoPlayingChanged?.call(true);
        }
      } else if (event.state == PlayerActivityState.loaded) {
        if (_isInitCurrent(generation)) {
          _markVideoSurfaceVisible();
        }
      } else if (event.state == PlayerActivityState.error) {
        if (_isInitCurrent(generation)) {
          _cancelPlaybackWatchdog();
          widget.onVideoPlayingChanged?.call(false);
          widget.onVideoFailed?.call();
          final message =
              asStringOrNull(event.data?['message']) ?? 'Unknown error';
          StoryLogger.e('BannerSlide preview video error: $message');
        }
      }
    };
  }

  Future<void> _tearDownPlayer({
    required bool notifyPlayingChanged,
    bool rebuild = true,
  }) {
    return _BannerPlayerHandoff.run(
      () => _releasePlayer(
        notifyPlayingChanged: notifyPlayingChanged,
        rebuild: rebuild,
      ),
    );
  }

  /// Lightweight pause: keeps controller alive for instant resume.
  /// Releases coordinator so other slides can initialize.
  Future<void> _pausePlayer({
    required bool notifyPlayingChanged,
    bool rebuild = true,
  }) {
    return _BannerPlayerHandoff.run(() async {
      _cancelPlaybackWatchdog();
      if (_activityListener != null && _controller != null) {
        _controller!.removeActivityListener(_activityListener!);
      }
      _activityListener = null;
      final c = _controller;
      if (c == null) return;
      if (notifyPlayingChanged) {
        widget.onVideoPlayingChanged?.call(false);
      }
      try {
        await c.pause().timeout(const Duration(seconds: 2));
      } catch (e) {
        StoryLogger.d('Banner player pause failed', error: e, tag: 'Banner');
      }
      await NativePlayerBootstrap.releaseOwner(
        _playerOwner,
        coordinator: NativeVideoPlayerCoordinator.bannerInstance,
      );
      if (mounted && rebuild) setState(() {});
    });
  }

  Future<void> _releasePlayer({
    required bool notifyPlayingChanged,
    bool rebuild = true,
  }) async {
    _cancelPlaybackWatchdog();

    if (_activityListener != null && _controller != null) {
      _controller!.removeActivityListener(_activityListener!);
    }
    _activityListener = null;

    final c = _controller;
    _controller = null;
    _currentPlayerId = null;
    _initialized = false;

    _initGeneration++;

    if (notifyPlayingChanged) {
      widget.onVideoPlayingChanged?.call(false);
    }

    // Drop the platform view from the tree before awaiting native pause /
    // dispose. Waiting left SurfaceView composited above other tabs/routes.
    if (mounted && rebuild) setState(() {});

    if (c == null) return;

    try {
      await c.pause().timeout(const Duration(seconds: 2));
    } catch (e, st) {
      StoryLogger.w(
        'TheaterHeroBanner pause failed',
        error: e,
        stackTrace: st,
        tag: 'TheaterHeroBanner',
      );
    }

    // Release the coordinator slot before native dispose so the next
    // banner slide can initialize without waiting on a slow teardown.
    await NativePlayerBootstrap.releaseOwner(
      _playerOwner,
      coordinator: NativeVideoPlayerCoordinator.bannerInstance,
    );

    try {
      await c.dispose().timeout(const Duration(seconds: 3));
    } catch (e, st) {
      StoryLogger.w(
        'TheaterHeroBanner dispose failed',
        error: e,
        stackTrace: st,
        tag: 'TheaterHeroBanner',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _controller == null) return;
    final isPlaying = _isFocused && widget.isPageVisible;
    if (!isPlaying) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _controller?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controller?.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.isMutedNotifier.removeListener(_handleMuteChanged);
    widget.focusedPageNotifier.removeListener(_onFocusedPageChanged);
    widget.detailsNotifier.removeListener(_onDetailsChanged);
    unawaited(_tearDownPlayer(notifyPlayingChanged: false, rebuild: false));
    super.dispose();
  }

  Widget _buildBannerCoverImage() {
    final url = widget.item.bannerUrl ?? widget.item.thumbUrl ?? '';
    if (url.isEmpty) {
      return Container(color: Colors.grey.shade900);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 180),
      memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
        context,
        StoryImageCache.cardCover,
      ),
      placeholder: (_, _) => Container(color: Colors.grey.shade900),
      errorWidget: (_, _, _) => Container(color: Colors.grey.shade900),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.dramaItems.indexWhere(
      (d) => d.id == widget.item.dramaId,
    );
    final matchingDrama = index >= 0
        ? widget.dramaItems[index]
        : const DramaListItem(id: '');
    final detail = _detail;

    // Only bound actor IPs show avatars. Unbound roles (role-only faces) and
    // banner `actorAvatarUrls` are omitted so unbound cast never appears here.
    final listActors =
        matchingDrama.actorCollections
            ?.where((a) => a.avatarUrl?.trim().isNotEmpty == true)
            .toList() ??
        const <DramaActorCollection>[];
    final listById = {
      for (final a in listActors)
        if (a.id != null && a.id!.isNotEmpty) a.id!: a,
    };
    final detailActors =
        detail?.roles
            ?.where((role) => role.isBound)
            .map(
              (role) => DramaActorCollection.fromBoundRole(
                role,
                fallback: listById[role.boundActorCollectionId],
              ),
            )
            .where((a) => a.avatarUrl?.trim().isNotEmpty == true)
            .toList() ??
        const <DramaActorCollection>[];
    // Once detail is loaded it is authoritative (may be empty if nothing bound).
    final displayActors = detail != null ? detailActors : listActors;

    final playCount =
        detail?.totalCompletedViewCount ??
        matchingDrama.totalCompletedViewCount ??
        widget.item.totalCompletedViewCount ??
        0;
    final heatLabel =
        formatHeatValue(detail?.totalHeatValue) ??
        formatHeatValue(matchingDrama.totalHeatValue) ??
        formatHeatValue((playCount * 1.5).round()) ??
        '0';
    final ratingLabel = (detail?.avgRating ?? matchingDrama.avgRating)
        ?.toStringAsFixed(1);
    final title = detail?.title?.trim().isNotEmpty == true
        ? detail!.title!
        : (widget.item.title ?? '');
    final badge = detail?.badge ?? matchingDrama.badge;
    final creator = (detail?.creatorName ?? matchingDrama.creatorName)?.trim();
    final creatorHandle = creator == null || creator.isEmpty
        ? null
        : (creator.startsWith('@') ? creator : '@$creator');

    return GestureDetector(
      onTap: widget.onTap != null
          ? () => widget.onTap!(widget.item, detail)
          : null,
      child: Stack(
        children: [
          // Only mount the platform view while this slide should actually
          // paint. Visibility(visible:false) alone still left a SurfaceView
          // in the Offstage IndexedStack tree long enough to leak above
          // other tabs on some Android OEMs.
          if (_controller != null && _isFocused && widget.isPageVisible)
            Positioned.fill(
              child: _BannerCoverPlayer(
                controller: _controller!,
                onSurfaceReady: _markVideoSurfaceVisible,
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _initialized,
              child: AnimatedOpacity(
                opacity: _initialized ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 250),
                child: _buildBannerCoverImage(),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: StorySpacing.lg,
            bottom: 36,
            right: StorySpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showContentBadge &&
                    ContentBadgeValue.fromApiValue(badge) != null) ...[
                  ContentBadge(
                    badge: badge,
                    variant: ContentBadgeVariant.drama,
                  ),
                  const SizedBox(height: StorySpacing.xs),
                ],
                Text(
                  title,
                  style: StoryTextStyles.displayMedium(
                    color: Colors.white,
                  ).copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: StorySpacing.xs),
                Row(
                  children: [
                    if (creatorHandle != null) ...[
                      SvgPicture.asset(
                        'assets/drama/card_user.svg',
                        width: 14,
                        height: 14,
                        colorFilter: ColorFilter.mode(
                          Colors.white.withValues(alpha: 0.9),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          creatorHandle,
                          style: StoryTextStyles.bodySmall(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: StorySpacing.md),
                    ],
                    SvgPicture.asset(
                      'assets/drama/brand_play.svg',
                      width: 14,
                      height: 14,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withValues(alpha: 0.9),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      StoryFormat.formatCount(playCount),
                      style: StoryTextStyles.bodySmall(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: StorySpacing.md),
                    SvgPicture.asset(
                      'assets/drama/brand_tinder.svg',
                      width: 14,
                      height: 14,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withValues(alpha: 0.9),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      heatLabel,
                      style: StoryTextStyles.bodySmall(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    if (ratingLabel != null) ...[
                      const SizedBox(width: StorySpacing.md),
                      SvgPicture.asset(
                        'assets/drama/brand_star.svg',
                        width: 14,
                        height: 14,
                        colorFilter: ColorFilter.mode(
                          Colors.white.withValues(alpha: 0.9),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ratingLabel,
                        style: StoryTextStyles.bodySmall(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                    const Spacer(),
                    ValueListenableBuilder<bool>(
                      valueListenable: widget.isMutedNotifier,
                      builder: (context, isMuted, _) {
                        return GestureDetector(
                          onTap: () {
                            widget.isMutedNotifier.value = !isMuted;
                          },
                          child: SvgPicture.asset(
                            isMuted
                                ? 'assets/drama/volume-unmute.svg'
                                : 'assets/drama/volume_mute.svg',
                            width: 18,
                            height: 18,
                            colorFilter: ColorFilter.mode(
                              Colors.white.withValues(alpha: 0.9),
                              BlendMode.srcIn,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (displayActors.isNotEmpty) ...[
                  const SizedBox(height: StorySpacing.sm),
                  TheaterHeroActorStrip(actors: displayActors),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scales the native preview to cover the banner without laying out the
/// platform view at source-pixel size (e.g. 1080×1920). That FittedBox
/// pattern previously froze the feed UI; size at *display* cover bounds.
class _BannerCoverPlayer extends StatefulWidget {
  final NativeVideoPlayerController controller;
  final VoidCallback? onSurfaceReady;

  const _BannerCoverPlayer({required this.controller, this.onSurfaceReady});

  @override
  State<_BannerCoverPlayer> createState() => _BannerCoverPlayerState();
}

class _BannerCoverPlayerState extends State<_BannerCoverPlayer> {
  StreamSubscription<NativeVideoPlayerVideoSize>? _sub;
  double _videoW = 0;
  double _videoH = 0;
  bool _notifiedReady = false;

  @override
  void initState() {
    super.initState();
    _applySize(widget.controller.videoSize);
    _sub = widget.controller.videoSizeStream.listen(_applySize);
  }

  @override
  void didUpdateWidget(covariant _BannerCoverPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    _sub?.cancel();
    _notifiedReady = false;
    _applySize(widget.controller.videoSize);
    _sub = widget.controller.videoSizeStream.listen(_applySize);
  }

  void _applySize(NativeVideoPlayerVideoSize? size) {
    if (size == null) return;
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    if (w == _videoW && h == _videoH) {
      _notifyReady();
      return;
    }
    if (!mounted) {
      _videoW = w;
      _videoH = h;
      return;
    }
    setState(() {
      _videoW = w;
      _videoH = h;
    });
    _notifyReady();
  }

  void _notifyReady() {
    if (_notifiedReady || _videoW <= 0 || _videoH <= 0) return;
    _notifiedReady = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSurfaceReady?.call();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewW = constraints.maxWidth;
        final viewH = constraints.maxHeight;
        if (viewW <= 0 || viewH <= 0) {
          return const SizedBox.shrink();
        }

        final hasVideoSize = _videoW > 0 && _videoH > 0;
        final scale = hasVideoSize
            ? math.max(viewW / _videoW, viewH / _videoH)
            : 1.0;
        final displayW = hasVideoSize ? _videoW * scale : viewW;
        final displayH = hasVideoSize ? _videoH * scale : viewH;

        // Keep a stable widget tree so NativeVideoPlayer is not remounted
        // when video dimensions arrive.
        return ClipRect(
          child: OverflowBox(
            minWidth: displayW,
            maxWidth: displayW,
            minHeight: displayH,
            maxHeight: displayH,
            child: SizedBox(
              width: displayW,
              height: displayH,
              // A SurfaceView punches through later routes (Login OTP over
              // theater). androidTextureViewSurface already keeps the
              // platform view on TLHC. The SurfaceView fallback only needs
              // the engine-texture escape hatch on real devices — on the
              // emulator that fallback pairs with soft-decode, and forcing
              // SurfaceProducer there paints the #159955 green strip.
              child: NativeVideoPlayer(
                controller: widget.controller,
                forceTextureMode:
                    !NativeVideoPlayerConfig.global.androidTextureViewSurface &&
                    !NativeVideoPlayerConfig.global
                        .androidForceSoftwareDecoders,
              ),
            ),
          ),
        );
      },
    );
  }
}
