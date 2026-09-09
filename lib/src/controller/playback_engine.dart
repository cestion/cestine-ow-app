// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/result.dart';
import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../core/json_helpers.dart';
import '../core/story_dns_preheater.dart';
import '../data/repository/story_local_repository.dart';
import '../model/models.dart';
import '../repositories/drama_repository.dart';
import '../services/cloudfront_cookie_service.dart';
import '../services/native_player_bootstrap.dart';
import '../services/native_video_player_coordinator.dart';
import '../services/ios_video_cache_service.dart';
import '../services/video_precache_service.dart';
import '../services/playback_cookie_service.dart';
import '../services/playback_frame_tracker.dart';
import 'feed_playback_policy.dart';
import 'playback_engine_listener.dart';
import 'playback_quality_policy.dart';

class PlaybackEpisodeData {
  final DramaPlayResponse play;
  final String url;
  final Map<String, String> headers;

  const PlaybackEpisodeData({
    required this.play,
    required this.url,
    required this.headers,
  });
}

/// Active slots may `play()`. Preload slots may only `loadUrl` + pause.
enum PlaybackEngineRole { active, preload }

/// How a feed resumes after pause / cover / unexpected-pause recovery.
///
/// Recommend deliberately avoids [waitForFrame] after neighbor `loadUrl` —
/// waiting for a frame there froze the visible texture. Short-drama feed
/// waits so soft resume does not reveal a black SurfaceView.
enum FeedResumeStyle {
  /// `play()` then wait for a painted frame (video / short-drama feed).
  waitForFrame,

  /// `play()` command only (recommend feed).
  playCommandOnly,
}

/// Shared native playback lifecycle for episode player and vertical feed.
///
/// This folds the responsibilities previously duplicated in both controllers
/// (and partially covered by PlaybackMixin) into one owner: fetch episode data,
/// apply CloudFront cookies, load URLs, restore/persist resume, start playback,
/// translate native activity/control events, and dispose the native controller.
class PlaybackEngine {
  PlaybackEngine({
    required DramaRepository dramaRepo,
    required StoryLocalRepository localRepo,
    required CloudFrontCookieService cloudfront,
    required this.dramaId,
    required this.tag,
    this.restoreWatchProgress = true,
    this.coordinator,
    Future<Result<DramaPlayResponse>> Function(int episodeNo)? episodeLoader,
    CloudFrontCookieFamily cookieFamily = CloudFrontCookieFamily.feed,
    bool Function()? isCellular,
  }) : _dramaRepo = dramaRepo,
       _localRepo = localRepo,
       _episodeLoader = episodeLoader,
       _cookieFamily = cookieFamily,
       _isCellular = isCellular,
       _cookieSvc = PlaybackCookieService(
         cloudfront: cloudfront,
         dramaRepo: dramaRepo,
         dramaId: dramaId,
         episodeLoader: episodeLoader,
         family: cookieFamily,
       );

  final DramaRepository _dramaRepo;
  final StoryLocalRepository _localRepo;
  final Future<Result<DramaPlayResponse>> Function(int episodeNo)?
  _episodeLoader;
  final PlaybackCookieService _cookieSvc;
  final CloudFrontCookieFamily _cookieFamily;
  final bool Function()? _isCellular;
  String dramaId;
  String tag;
  final bool restoreWatchProgress;
  PlaybackEngineRole _role = PlaybackEngineRole.active;
  PlaybackEngineRole get role => _role;

  /// Neighbor / recycled slots must not `play()` (fights the visible decoder).
  void retargetSlot({required String tag, required PlaybackEngineRole role}) {
    this.tag = tag;
    _role = role;
  }

  final Object _playerOwner = Object();
  Object get playerOwner => _playerOwner;

  /// Optional dedicated coordinator for the second (preload) player.
  /// When null, the default [NativeVideoPlayerCoordinator.instance] is used.
  final NativeVideoPlayerCoordinator? coordinator;

  bool get _isRecommendFamily =>
      _cookieFamily == CloudFrontCookieFamily.recommend;

  Duration get _loadTimeout => _isRecommendFamily
      ? StoryConstants.recommendLoadTimeout
      : StoryConstants.playerOperationTimeout;

  int get _maxLoadRetries => _isRecommendFamily
      ? StoryConstants.recommendMaxRetries
      : StoryConstants.playerMaxRetries;

  final PlaybackFrameTracker _frameTracker = PlaybackFrameTracker();

  NativeVideoPlayerController? _nativeController;
  NativeVideoPlayerController? get nativeController => _nativeController;

  final ValueNotifier<Duration> positionNotifier = ValueNotifier<Duration>(
    Duration.zero,
  );

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _completed = false;

  /// The CDN refused the currently loaded URL. Reset on every load so it only
  /// ever describes the resource in flight.
  bool _mediaUnauthorized = false;
  bool _looping = false;
  // Invalidates late completions from older play/pause method-channel calls.
  // Native commands are ordered, but their Futures may resolve after a newer
  // command and must not overwrite the newer Dart-side transport state.
  int _transportCommandGeneration = 0;
  DramaPlayResponse? _currentPlay;
  int? _currentEpisodeNo;
  int _lastNotifiedSecond = -1;
  bool _disposed = false;
  Future<void>? _disposeFuture;
  int? _lastSavedProgressMs;

  /// Throttle [refreshCookiesIfNearExpiry] to avoid a `unawaited(Future)`
  /// allocation on every 1-second position tick. 30-second cooldown is
  /// well below the 2-minute cooldown inside the cookie service, so no
  /// refresh opportunity is missed.
  int _lastCookieRefreshCheckMs = 0;

  /// Cache: last applied max-height quality key (`$url@$maxHeight`).
  ///
  /// Prevents redundant `setQuality` calls when the same URL+cap is reused
  /// across apply/preload or fast episode switches.
  final Set<String> _appliedPeakCapKeys = <String>{};

  /// Cellular soft peak was applied and should release to Auto after first frame.
  bool _cellularSoftPeakPendingRelease = false;

  /// URL last used for a peak-cap apply (needed when releasing before
  /// [_currentPlay] is assigned on the cold path).
  String? _lastPeakCapUrl;

  String _peakCapKey(String loadUrl, int maxHeight) => '$loadUrl@$maxHeight';

  /// Hard 1080p ceiling only — used on preload slots so neighbor decode does
  /// not pay an extra cellular soft-peak setQuality before the user swipes.
  Future<void> _applyHardPlaybackPeak({required String loadUrl}) async {
    await _applyMaxPlaybackVideoHeight(
      maxHeight: StoryConstants.maxPlaybackVideoHeight,
      loadUrl: loadUrl,
    );
    _lastPeakCapUrl = loadUrl;
  }

  /// Applies the connection-aware startup peak (cellular soft / Wi‑Fi hard).
  Future<void> _applyStartupPlaybackPeak({required String loadUrl}) async {
    final cellular = _isCellular?.call() ?? false;
    final maxHeight = PlaybackQualityPolicy.startupMaxHeight(
      isCellular: cellular,
    );
    // Re-evaluate on every load — a prior soft-peak→release cycle must not
    // skip the next cellular startup cap via the apply cache.
    _appliedPeakCapKeys.removeWhere((k) => k.startsWith('$loadUrl@'));
    final applied = await _applyMaxPlaybackVideoHeight(
      maxHeight: maxHeight,
      loadUrl: loadUrl,
    );
    _lastPeakCapUrl = loadUrl;
    _cellularSoftPeakPendingRelease =
        applied &&
        PlaybackQualityPolicy.shouldReleaseSoftPeak(
          isCellular: cellular,
          appliedMaxHeight: maxHeight,
        );
  }

  /// After first frame: drop the temporary cellular soft peak so ABR can climb
  /// again, then re-assert the hard 1080p ceiling when the ladder needs it.
  Future<void> _releaseCellularSoftPeakIfNeeded() async {
    if (!_cellularSoftPeakPendingRelease || _disposed) return;
    _cellularSoftPeakPendingRelease = false;
    final controller = _nativeController;
    if (controller == null) return;

    try {
      await _nativeCall(
        controller.setQuality(NativeVideoPlayerQuality.auto()),
        label: 'setQuality(auto soft-peak release)',
      );
    } catch (_) {
      // Best-effort — keep playing under the soft peak if release fails.
    }
    if (_disposed) return;

    final url = _lastPeakCapUrl ?? _currentPlay?.effectivePlayUrl;
    if (url == null || url.isEmpty) return;
    await _applyMaxPlaybackVideoHeight(
      maxHeight: StoryConstants.maxPlaybackVideoHeight,
      loadUrl: url,
    );
  }

  /// Caps HLS ABR via native track selector (`preferredMaximumResolution` /
  /// peak bitrate). Returns true when `setQuality` was issued.
  Future<bool> _applyMaxPlaybackVideoHeight({
    required int maxHeight,
    required String loadUrl,
  }) async {
    final controller = _nativeController;
    if (_disposed || controller == null) return false;

    final cacheKey = _peakCapKey(loadUrl, maxHeight);
    if (_appliedPeakCapKeys.contains(cacheKey)) return false;

    final chosen = PlaybackQualityPolicy.chooseUnderMaxHeight(
      qualities: controller.qualities,
      maxHeight: maxHeight,
    );
    if (chosen == null) return false;

    try {
      await _nativeCall(
        controller.setQuality(chosen),
        label: 'setQuality(max ${maxHeight}p)',
      );
      _appliedPeakCapKeys.add(cacheKey);
      return true;
    } catch (_) {
      // Best-effort: if the native quality change fails, never stall
      // playback.
      return false;
    }
  }

  /// Whether [NativePlayerBootstrap.initialize] has completed successfully.
  /// Used by callers to decide if the controller needs initialization.
  bool _nativeInitialized = false;
  bool get isNativeInitialized => _nativeInitialized;

  /// Force the next [applyPlayback] to re-run native bootstrap.
  ///
  /// Call after the platform view was torn down (NO_VIEW) or a failed entry
  /// so retry does not skip initialize and hang on a dead surface.
  ///
  /// Does **not** clear [_eagerInitPending] — that future must still be
  /// drained by [_awaitEagerInit] to avoid overlapping plugin initialize().
  void invalidateNativeInitialization() {
    _nativeInitialized = false;
  }

  /// Tracks an in-flight [eagerInitialize] so [applyPlayback] and
  /// [preloadEpisode] can await it instead of racing with a second
  /// [NativePlayerBootstrap.initialize] on the same controller.
  Future<void>? _eagerInitPending;

  /// Eagerly bootstrap the native controller so [controller.initialize()]
  /// is already waiting when the platform view dispatches its ready signal.
  ///
  /// Call fire-and-forget right after attaching the native controller,
  /// before episode data is fetched. If this completes before
  /// [applyPlayback] runs, the bootstrap step is skipped there.
  Future<void> eagerInitialize() async {
    if (_disposed || _nativeController == null || _nativeInitialized) return;
    final pending = _doEagerInit();
    _eagerInitPending = pending;
    await pending;
  }

  Future<void> _doEagerInit() async {
    try {
      if (!await _waitIfNativeTeardown()) return;
      await NativePlayerBootstrap.initialize(
        _nativeController!,
        owner: _playerOwner,
        coordinator: coordinator,
      );
      _nativeInitialized = true;
      StoryLogger.d('eagerInitialize completed for $tag', tag: tag);
    } catch (e) {
      _nativeInitialized = false;
      StoryLogger.d(
        'eagerInitialize failed (will retry in applyPlayback): $e',
        tag: tag,
      );
    } finally {
      _eagerInitPending = null;
    }
  }

  /// Shared bootstrap block used by both [applyPlayback] and [preloadEpisode].

  /// Ensures [_nativeInitialized] is true by either awaiting any in-flight
  /// [eagerInitialize] or running [NativePlayerBootstrap.initialize] itself.
  ///
  /// No-op when [_nativeInitialized] is already true. Eager-timeout failure
  /// is swallowed by [_awaitEagerInit] (best-effort), so this method always
  /// falls through to [NativePlayerBootstrap.initialize] when eager did not
  /// set the flag — matching the pre-refactor behaviour where both
  /// [applyPlayback] and [preloadEpisode] re-ran bootstrap eagerly if the
  /// eager future had not completed in time.
  Future<void> _ensureNativeInitialized({
    Duration viewReadyDelay = StoryDurations.playerViewReadyDelay,
    bool Function()? isCurrent,
  }) async {
    if (_nativeInitialized) return;
    await _awaitEagerInit();
    if (_nativeInitialized) return;
    try {
      await NativePlayerBootstrap.initialize(
        _nativeController!,
        owner: _playerOwner,
        coordinator: coordinator,
        isCurrent: isCurrent,
        viewReadyDelay: viewReadyDelay,
      );
      _nativeInitialized = true;
    } on TimeoutException {
      _nativeController?.abortPendingInitialize();
      _nativeInitialized = false;
      rethrow;
    } on NativePlayerInitCancelled {
      _nativeInitialized = false;
      rethrow;
    } catch (_) {
      _nativeInitialized = false;
      rethrow;
    }
  }

  /// If [eagerInitialize] is still in-flight, await it (with a timeout)
  /// instead of racing with a second [NativePlayerBootstrap.initialize].
  ///
  /// Never drain the pending future without a timeout — the plugin Completer
  /// has no internal deadline; an unbounded await freezes feed entry.
  Future<void> _awaitEagerInit() async {
    final pending = _eagerInitPending;
    if (pending == null) return;
    try {
      await pending.timeout(StoryConstants.playerOperationTimeout);
    } catch (e) {
      StoryLogger.d(
        'eagerInit timed out or failed, bounded drain before retry: $e',
        tag: tag,
      );
      final stillPending = _eagerInitPending;
      if (stillPending != null) {
        try {
          await stillPending.timeout(const Duration(seconds: 2));
        } catch (_) {
          StoryLogger.w(
            'eagerInit drain abandoned; applyPlayback will retry bootstrap',
            tag: tag,
          );
        }
      }
    }
  }

  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;

  bool get isBuffering {
    if (_isBuffering) return true;
    return _nativeController?.activityState == PlayerActivityState.buffering;
  }

  bool get isLoadingMedia {
    final state = _nativeController?.activityState;
    return state == PlayerActivityState.loading ||
        state == PlayerActivityState.initializing;
  }

  /// Native reported [PlayerActivityState.completed] since the last play/seek.
  /// Callers must not treat a follow-up `paused` as an unexpected stall.
  bool get hasCompleted => _completed;
  bool get looping => _looping;
  DramaPlayResponse? get currentPlay => _currentPlay;
  int? get currentEpisodeNo => _currentEpisodeNo;

  /// CDN origin last passed to native `loadUrl` (not the iOS proxy URL).
  String? get playbackUrl =>
      _lastLoadOriginUrl ?? _currentPlay?.effectivePlayUrl;
  int get frameSequence => _frameTracker.frameSequence;
  bool get hasPresentedFirstFrame => _frameTracker.hasPresentedFirstFrame;
  DateTime? get lastFrameRenderedAt => _frameTracker.lastFrameRenderedAt;

  /// Unified listener for engine lifecycle events.
  ///
  /// Replaces the 10 individual callback fields that were previously set
  /// ad-hoc by consumers. The engine passes itself as the first parameter
  /// to every callback, allowing listeners to identify which engine
  /// triggered the event.
  PlaybackEngineListener? listener;

  Future<void> initialize(NativeVideoPlayerController? existing) async {
    final isSame = identical(_nativeController, existing);
    // Always detach then re-attach so teardown → resume still gets events.
    _detachListeners();
    if (!isSame) {
      // New native controller must go through NativePlayerBootstrap again.
      _nativeInitialized = false;
    }
    _nativeController = existing;
    // Slots swap native controllers constantly; the incoming one carries the
    // volume the previous owner left it at. Never trust the cached value
    // across an attach or the dedupe below can skip a mute that must land.
    _currentVolume = -1.0;
    _nativeController?.addActivityListener(_handleActivityEvent);
    _nativeController?.addControlListener(_handleControlEvent);
  }

  void reset() {
    _lastNotifiedSecond = -1;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isPlaying = false;
    _isBuffering = false;
    _lastSavedProgressMs = null;
    // Keep peak-cap / soft-peak state: reset() only clears UI scrubber fields
    // before preload→active swap. Native media + setQuality caps survive.
    positionNotifier.value = Duration.zero;
  }

  /// Reuse this engine for another drama without disposing the native view.
  ///
  /// Recommend For You swaps titles every page; recreating
  /// [NativeVideoPlayerController] + [initialize] is the jank source.
  /// Keep the platform view, retarget [dramaId] / cookies, then
  /// [applyPlayback] / [preloadEpisode].
  void rebindDrama(String nextDramaId) {
    if (_disposed) return;
    dramaId = nextDramaId;
    _cookieSvc.rebindDrama(nextDramaId);
    _currentPlay = null;
    _currentEpisodeNo = null;
    _frameTracker.resetFrameEvidence();
    _appliedPeakCapKeys.clear();
    _cellularSoftPeakPendingRelease = false;
    _lastPeakCapUrl = null;
    reset();
  }

  /// Drop CloudFront jar ownership when this player leaves the screen.
  void releaseCookieFamily() {
    if (_disposed) return;
    _cookieSvc.releaseActiveFamily();
  }

  /// Waits for a native frame event newer than [afterSequence].
  Future<FrameWaitResult> waitForFrameResult(
    int afterSequence, {
    Duration timeout = StoryConstants.playerFirstFrameTimeout,
    bool Function()? shouldContinue,
  }) {
    return _frameTracker.waitForFrameAfter(
      afterSequence,
      timeout: timeout,
      shouldContinue: shouldContinue,
    );
  }

  /// Convenience for callers that only need painted-vs-not.
  Future<bool> waitForFrameAfter(
    int afterSequence, {
    Duration timeout = StoryConstants.playerFirstFrameTimeout,
    bool Function()? shouldContinue,
  }) async {
    final result = await waitForFrameResult(
      afterSequence,
      timeout: timeout,
      shouldContinue: shouldContinue,
    );
    return result == FrameWaitResult.presented;
  }

  /// Called from [_handleControlEvent] when a native frame event arrives.
  /// Forwards frame tracking and notifies the engine-level callback.
  void _recordFrame({
    required bool isFirstFrame,
    required DateTime renderedAt,
  }) {
    _frameTracker.recordFrame(
      isFirstFrame: isFirstFrame,
      renderedAt: renderedAt,
    );
    // Forward to the engine-level callback (set externally by video_feed_controller etc.)
    listener?.onFrameRendered(
      this,
      isFirstFrame: isFirstFrame,
      renderedAt: renderedAt,
    );
  }

  Future<PlaybackEpisodeData?> fetchEpisodeData(int episodeNo) async {
    _currentEpisodeNo = episodeNo;
    final loader = _episodeLoader;
    final result = loader != null
        ? await loader(episodeNo)
        : await _dramaRepo.getEpisodeDetail(dramaId, episodeNo);
    listener?.onEpisodeResult(this, result);

    if (result.isFailure) {
      final error = result.errorOrNull!;
      StoryLogger.e('获取剧集详情失败: ${error.userMessage}', tag: tag);
      listener?.onError(this, error);
      return null;
    }

    final play = result.dataOrNull!;
    final url = play.effectivePlayUrl;
    if (url == null || url.isEmpty) {
      final error = Exception('视频地址为空');
      StoryLogger.e('视频地址为空', tag: tag);
      listener?.onError(this, error);
      return null;
    }

    _currentPlay = play;
    _cookieSvc.urlToClear = play.signedCookies != null ? url : null;
    StoryLogger.d(
      '✅ 获取剧集详情成功 hls=${play.isHls} type=${play.playbackType}',
      tag: tag,
    );

    return _episodeDataFromResponse(play, url);
  }

  PlaybackEpisodeData? episodeDataFromPlay(DramaPlayResponse play) {
    final url = play.effectivePlayUrl;
    if (url == null || url.isEmpty) return null;
    // If the cached play has expired CloudFront cookies, the resulting
    // loadUrl headers would be empty and CloudFront would return 403.
    // Treat as a miss so the caller falls through to a fresh API fetch.
    if (play.signedCookies != null && !play.signedCookies!.isValid) {
      StoryLogger.d('Skipping cached episode: cookies expired', tag: tag);
      return null;
    }
    return _episodeDataFromResponse(play, url);
  }

  /// Shared construction of [PlaybackEpisodeData] from a resolved play.
  PlaybackEpisodeData _episodeDataFromResponse(
    DramaPlayResponse play,
    String url,
  ) {
    _currentPlay = play;
    _cookieSvc.urlToClear = play.signedCookies != null ? url : null;
    unawaited(StoryDnsPreheater.preheat(url));
    return PlaybackEpisodeData(
      play: play,
      url: url,
      headers: CloudFrontCookieService.buildHeaders(play),
    );
  }

  /// Tracks the most recent [loadUrl] operation so that [dispose] and
  /// subsequent loads can serialise against it, preventing races on the
  /// underlying AVPlayer observer (which crashes when
  /// `removeTimeObserver:` is called on an already-invalidated observer).
  Future<void>? _lastLoadOperation;

  /// Raw native loads that must settle before their controller is disposed.
  ///
  /// [_lastLoadOperation] is a logical serialization lock and may be cleared
  /// by [forceAbandonPendingLoad] after a soft hide. The native AVPlayer work
  /// is not actually cancelled, so route teardown keeps these raw Futures
  /// separately to avoid disposing a controller mid-load.
  final Set<Future<void>> _nativeLoadDrainOperations = <Future<void>>{};

  /// Origin CDN URL from the last [_executeTrackedLoad] (before iOS proxy).
  String? _lastLoadOriginUrl;

  int _staleLoadCancelCount = 0;

  Future<void>? _cancelStaleLoadInFlight;

  /// True while a native [loadUrl] is still unresolved.
  ///
  /// Callers must not start another load on this engine until this is false —
  /// overlapping AVPlayer item replacements can SIGABRT on iOS.
  bool get hasPendingLoad => _lastLoadOperation != null;

  /// How many times a stale in-flight load was cancelled via [cancelStaleLoad].
  int get staleLoadCancelCount => _staleLoadCancelCount;

  /// Wait out an in-flight [loadUrl] before starting another.
  ///
  /// Previously this forced `about:blank` after a short budget. On iOS that
  /// overlaps a second `handleLoad` with the still-running first one; both call
  /// `setupPeriodicTimeObserver` → `AVPlayer.removeTimeObserver:` with a stale
  /// token → SIGABRT (seen repeatedly on feed switches). Prefer waiting.
  ///
  /// Concurrent callers share one wait so abandoned preloads + a follow-up
  /// [preloadEpisode] do not each burn the full extended budget.
  ///
  /// If the load is still pending after [extendedWait], [_lastLoadOperation]
  /// stays set until the native future settles — callers must check
  /// [hasPendingLoad] and avoid starting another [loadUrl].
  Future<void> cancelStaleLoad({
    Duration waitBudget = const Duration(milliseconds: 100),
    Duration extendedWait = const Duration(seconds: 3),
  }) async {
    final pending = _lastLoadOperation;
    if (pending == null) return;

    final inFlight = _cancelStaleLoadInFlight;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final wait = _waitForStaleLoad(
      pending,
      waitBudget: waitBudget,
      extendedWait: extendedWait,
    );
    _cancelStaleLoadInFlight = wait;
    try {
      await wait;
    } finally {
      if (identical(_cancelStaleLoadInFlight, wait)) {
        _cancelStaleLoadInFlight = null;
      }
    }
  }

  /// Extra drain for wedged slots: wait longer, nudge pause, wait again.
  ///
  /// Returns true when it is safe to start another [loadUrl] on this engine.
  /// When the native future never settles (missing surface / hung ExoPlayer),
  /// [forceAbandonPendingLoad] clears the Dart-side lock so another engine
  /// path can proceed — overlapping loadUrl on the same AVPlayer is still
  /// avoided by resetting [_nativeInitialized] when the view never came up.
  Future<bool> tryRecoverWedgedLoad({
    Duration wait = const Duration(seconds: 8),
  }) async {
    if (!hasPendingLoad) return true;
    await cancelStaleLoad(extendedWait: wait);
    if (!hasPendingLoad) return true;

    StoryLogger.w(
      'slot still pending after ${wait.inSeconds}s; '
      'rebind surface + pause to encourage settle',
      tag: tag,
    );
    try {
      await ensureSurfaceConnected();
      await _nativeCall(_nativeController?.pause(), label: 'wedged-pause');
    } catch (e) {
      StoryLogger.d('wedged-slot recover failed', error: e, tag: tag);
    }
    await cancelStaleLoad(
      waitBudget: Duration.zero,
      extendedWait: const Duration(seconds: 2),
    );
    if (!hasPendingLoad) return true;

    StoryLogger.w('slot remain wedged; force-abandon pending load', tag: tag);
    forceAbandonPendingLoad();
    return !hasPendingLoad;
  }

  /// Drop the Dart-side pending-load lock when native work will never settle.
  ///
  /// Does not cancel the native op (iOS has no safe mid-load cancel). Clears
  /// tracking so callers can recycle this engine after a failed bootstrap or
  /// timed-out loadUrl that left [_lastLoadOperation] stuck forever.
  void forceAbandonPendingLoad() {
    final pending = _lastLoadOperation;
    if (pending == null) return;
    StoryLogger.w('forceAbandonPendingLoad', tag: tag);
    _lastLoadOperation = null;
    pending.catchError((Object _) {});
    final controller = _nativeController;
    if (controller != null && !controller.isInitialized) {
      controller.abortPendingInitialize();
      _nativeInitialized = false;
    }
  }

  Future<void> _waitForStaleLoad(
    Future<void> pending, {
    required Duration waitBudget,
    required Duration extendedWait,
  }) async {
    void clearIfCurrent() {
      if (identical(_lastLoadOperation, pending)) {
        _lastLoadOperation = null;
      }
    }

    try {
      await pending.timeout(waitBudget);
      clearIfCurrent();
      return;
    } on TimeoutException {
      // Still in flight — fall through to extended wait.
    } catch (e) {
      StoryLogger.d(
        'cancelStaleLoad: load failed during initial wait: $e',
        tag: tag,
      );
      clearIfCurrent();
      return;
    }

    _staleLoadCancelCount++;
    StoryLogger.d(
      'cancelStaleLoad #$staleLoadCancelCount (await in-flight load)',
      tag: tag,
    );
    try {
      await pending.timeout(extendedWait);
      clearIfCurrent();
    } on TimeoutException catch (e, st) {
      StoryLogger.w(
        'cancelStaleLoad: previous load still pending after extended wait',
        error: e,
        stackTrace: st,
        tag: tag,
      );
      // Keep [_lastLoadOperation] until the native op settles so a follow-up
      // loadUrl cannot overlap it. Clear when it finally completes.
      pending.whenComplete(clearIfCurrent).catchError((Object err) {
        StoryLogger.d('Suppressed stale load error: $err', tag: tag);
      });
    } catch (e) {
      StoryLogger.d(
        'cancelStaleLoad: load failed during extended wait: $e',
        tag: tag,
      );
      clearIfCurrent();
    }
  }

  Future<bool> applyPlayback(
    DramaPlayResponse play,
    String url,
    Map<String, String> headers, {
    required bool isSwitch,
    required int episodeNo,
    bool retry = true,
    bool Function()? shouldContinue,
    Duration? startAt,
    Duration viewReadyDelay = StoryDurations.playerViewReadyDelay,

    /// If provided, the caller started cookies earlier and this future
    /// resolves when they are ready — overlays cookie application with
    /// prefetch / UI work so it doesn't block the hot path.
    Future<bool>? cookiePreApplied,

    /// Fires after the new URL is on the native item and before play().
    /// Callers that need a poster until the first painted frame must not
    /// drop the cover here — wait for [onFrameRendered] / frame wait instead.
    void Function()? onSourceLoaded,
  }) async {
    _role = PlaybackEngineRole.active;
    final action = isSwitch ? '切换视频源' : '初始化播放器';
    final attempts = retry ? _maxLoadRetries : 1;
    final loadStopwatch = Stopwatch()..start();

    final previousCookieUrl = _cookieSvc.urlToClear;
    if (previousCookieUrl != null && previousCookieUrl != url) {
      // Skip the native clear when the new playback has valid signed cookies:
      // applyCookiesIfNeeded will overwrite the jar, so the explicit clear
      // is redundant. Only unsigned / stale-URL transitions need the clear
      // to avoid leftover Policy/Signature cookies 403-ing the new request.
      if (play.signedCookies == null || !play.signedCookies!.isValid) {
        await _cookieSvc.clearCookies(previousCookieUrl);
      }
    }

    for (var attempt = 1; attempt <= attempts; attempt++) {
      if (_nativeController == null) {
        _logPlaybackFailure('native controller is null', url: url, play: play);
        listener?.onError(this, StateError('Native controller is null'));
        return false;
      }
      // Wait for previous load to finish. Cached episodes complete in
      // ~50-100 ms; if this takes longer the load is stale (uncached or
      // timed out) and we cancel it to prevent concurrent AVPlayerItem
      // replacements from crashing the native player.
      await cancelStaleLoad();
      if (!_canContinue(shouldContinue)) return false;
      // Active load must not overlap a still-draining native loadUrl.
      if (hasPendingLoad) {
        await cancelStaleLoad(
          waitBudget: Duration.zero,
          extendedWait: const Duration(seconds: 12),
        );
        if (!_canContinue(shouldContinue)) return false;
        if (hasPendingLoad) {
          StoryLogger.w(
            '$action: force-abandon wedged load before retry $attempt',
            tag: tag,
          );
          forceAbandonPendingLoad();
        }
      }

      try {
        final cookiesOk = cookiePreApplied != null
            ? await cookiePreApplied
            : await applyCookiesIfNeeded(play, url);
        if (!cookiesOk) {
          // Cookie layer already did a timeout retry. Do not loop applyPlayback
          // attempts — each would wait another MethodChannel budget and feel
          // like a frozen start on weak net.
          StoryLogger.w(
            '$action: cookies failed — abort without loadUrl retry budget',
            tag: tag,
          );
          final err = StateError('CloudFront cookies application failed');
          _logPlaybackFailure(err, url: url, play: play);
          if (listener != null) {
            listener!.onPlaybackFailure(this, err, isSwitch: isSwitch);
          } else {
            listener?.onError(this, err);
          }
          return false;
        }
        if (!_canContinue(shouldContinue)) return false;

        StoryLogger.d('--- $action (尝试 $attempt) ---', tag: tag);
        // Ensure the native controller is bootstrapped whenever the flag is
        // unset — a prior NO_VIEW teardown invalidates initialization even
        // though the controller object is still referenced. Re-initializing
        // here prevents loadUrl from hanging on a dead surface.
        if (_nativeInitialized &&
            _nativeController?.hasPlatformView != true) {
          invalidateNativeInitialization();
        }
        if (!_nativeInitialized) {
          StoryLogger.d('awaiting native bootstrap…', tag: tag);
          await _ensureNativeInitialized(
            viewReadyDelay: viewReadyDelay,
            isCurrent: shouldContinue == null
                ? null
                : () => _canContinue(shouldContinue),
          );
          if (!_canContinue(shouldContinue)) return false;
          if (_nativeInitialized) {
            StoryLogger.d('✅ 播放器初始化完成', tag: tag);
          } else {
            StoryLogger.d(
              '⚠️ native bootstrap did not mark initialized; not stopping (stale eager drain)',
              tag: tag,
            );
          }
        }

        // SurfaceView / Texture may have been torn down while backgrounded or
        // mid-swap; rebind before loadUrl so Media3 does not hang forever.
        await ensureSurfaceConnected();
        if (!_canContinue(shouldContinue)) return false;
        if (!await _waitIfNativeTeardown()) return false;

        // Suppress errors from the previous load — it was abandoned when
        // [applyPlayback] was re-entered via a fast episode switch.
        final loadedOk = await _executeTrackedLoad(
          url: url,
          headers: headers,
          startAt: startAt,
          shouldAbort: () => !_canContinue(shouldContinue),
        );
        if (!loadedOk) return false;
        // Check generation before logging success — a stale loadUrl may have
        // completed after the user swiped; logging "success" here is misleading.
        if (!_canContinue(shouldContinue)) return false;
        StoryLogger.d(isSwitch ? '✅ 视频源已切换' : '✅ 视频加载请求已发送', tag: tag);
        onSourceLoaded?.call();
        if (!_canContinue(shouldContinue)) return false;

        // Snapshot before setQuality: quality changes re-init the decoder
        // and often emit firstFrame before play(). Waiting only for a
        // post-play event then times out with a painted surface.
        final frameBeforePlay = _frameTracker.frameSequence;

        // Cap HLS ABR for this connection: Wi‑Fi → 1080 hard ceiling;
        // cellular → temporary soft peak (released after first frame).
        await _applyStartupPlaybackPeak(loadUrl: url);
        if (!_canContinue(shouldContinue)) return false;

        // Quality: API preferPlaySource + NativeVideoPlayerConfig
        // qualityForViewportSize (ABR). Do not setQuality(lowest) — that
        // bypasses the viewport cap and fights adaptive bitrate.

        // Only issue seekTo when there is a non-zero target. The native
        // player already starts from zero by default, so explicitly seeking
        // to Duration.zero wastes a platform-channel roundtrip and can
        // trigger a seek storm when precache has already preloaded the head.
        if (restoreWatchProgress) {
          await restoreResumeIfNeeded(episodeNo);
        } else if (startAt != null && startAt > Duration.zero) {
          // [startAt] was already applied in [_executeTrackedLoad] / loadUrl
          // (native seek-before-first-frame). A second seekTo here races the
          // decoder on remount and can leave the player paused through play().
          _position = startAt;
          positionNotifier.value = startAt;
        } else {
          _position = Duration.zero;
          _lastSavedProgressMs = null;
          positionNotifier.value = Duration.zero;
        }
        if (!_canContinue(shouldContinue)) return false;

        // Cold path may follow silenceExcept* which left this slot at 0.
        // Recommend feed keeps a poster until the first frame is presented,
        // so delay unmuting until a frame is actually ready.
        await setVolume(_isRecommendFamily ? 0.0 : 1.0);
        if (!_canContinue(shouldContinue)) return false;

        final playbackStarted = await startPlayback();
        if (!playbackStarted) {
          throw StateError('Native play command did not complete');
        }
        await _kickPlayIfStillPaused(shouldContinue: shouldContinue);
        if (!_canContinue(shouldContinue)) return false;
        if (_mediaUnauthorized && !hasPresentedFirstFrame) {
          // The CDN already refused this URL; no frame is coming. Fail now
          // instead of burning the full first-frame timeout. Keep both
          // "unauthorized" and the no-frame phrase so classifyFailure →
          // unauthorized and auth recovery can refetch credentials.
          throw StateError(
            'Native playback produced no video frame (unauthorized)',
          );
        }
        final frameWait = await waitForFrameResult(
          frameBeforePlay,
          shouldContinue: () => _canContinue(shouldContinue),
        );
        switch (frameWait) {
          case FrameWaitResult.presented:
            break;
          case FrameWaitResult.aborted:
            return false;
          case FrameWaitResult.timedOut:
            if (!hasPresentedFirstFrame) {
              throw StateError('Native playback produced no video frame');
            }
            StoryLogger.d(
              'play() emitted no new frame event; keeping load-time frame',
              tag: tag,
            );
        }
        if (!_canContinue(shouldContinue)) return false;
        await _releaseCellularSoftPeakIfNeeded();
        if (!_canContinue(shouldContinue)) return false;

        _currentEpisodeNo = episodeNo;
        _currentPlay = play;
        _isPlaying = true;
        listener?.onPlayingChanged(this, true);
        loadStopwatch.stop();
        StoryLogger.d(
          'time_to_playback_ms=${loadStopwatch.elapsedMilliseconds} '
          'episode=$episodeNo switch=$isSwitch',
          tag: tag,
        );
        StoryLogger.d('=== ${isSwitch ? "剧集切换" : "剧集加载"}完成 ===', tag: tag);
        return true;
      } catch (e, stackTrace) {
        StoryLogger.e(
          '$action失败 (尝试 $attempt/$attempts)',
          error: e,
          stackTrace: stackTrace,
          tag: tag,
        );
        if (_isUnsupportedUrlError(e)) {
          final origin = _lastLoadOriginUrl ?? url;
          IosVideoCacheService.instance.invalidateProxy(origin);
        }
        if (attempt < attempts) {
          if (FeedPlaybackPolicy.isNoVideoFrameError(e) &&
              !FeedPlaybackPolicy.shouldRetryLoadAfterNoFrame(
                // Native may have entered playing before Dart latched
                // `_isPlaying` (set only on the success path after the frame
                // wait). Count that as "did enter playing" so a missed frame
                // event can still reload once. Sustained buffering/loading
                // without `playing` is also retryable (surface race).
                didEnterPlaying:
                    _isPlaying ||
                    _nativeController?.activityState ==
                        PlayerActivityState.playing,
                didBufferOrLoad:
                    _isBuffering ||
                    _nativeController?.activityState ==
                        PlayerActivityState.buffering ||
                    _nativeController?.activityState ==
                        PlayerActivityState.loading,
                mediaUnauthorized: _mediaUnauthorized,
                hasPresentedFirstFrame: hasPresentedFirstFrame,
              )) {
            StoryLogger.w(
              '$action: no frame and no startup progress; skip further loadUrl',
              tag: tag,
            );
            _logPlaybackFailure(e, url: url, play: play);
            if (listener != null) {
              listener!.onPlaybackFailure(this, e, isSwitch: isSwitch);
            } else {
              listener?.onError(this, e);
            }
            return false;
          }
          // loadUrl timeout leaves [_lastLoadOperation] set until native
          // settles — without clearing the lock the next attempt never
          // issues a new load. Skip the multi-second drain: we already
          // waited playerOperationTimeout.
          if (e is TimeoutException || hasPendingLoad) {
            StoryLogger.w(
              '$action: force-abandon wedged load before retry $attempt→${attempt + 1}',
              tag: tag,
            );
            forceAbandonPendingLoad();
            await ensureSurfaceConnected();
          }
          if (!_canContinue(shouldContinue)) return false;
          await Future<void>.delayed(
            StoryDurations.playerRetryBaseDelay * attempt,
          );
          continue;
        }
        // Prefer [onPlaybackFailure] when wired (Feed auth recovery). Calling
        // both would flash an error toast before recovery can succeed.
        _logPlaybackFailure(e, url: url, play: play);
        if (listener != null) {
          listener!.onPlaybackFailure(this, e, isSwitch: isSwitch);
        } else {
          listener?.onError(this, e);
        }
      }
    }
    return false;
  }

  /// Shared loadUrl tracking + timeout-cleanup.

  /// Runs the native [loadUrl] with the standard stale-load suppression,
  /// iOS playback-URL resolution, frame-tracker reset, and timeout handling.
  ///
  /// Returns `true` on success, `false` when [shouldAbort] reports the
  /// operation was cancelled (disposed / superseded / pending load) after
  /// the iOS URL resolve.
  ///
  /// Both [applyPlayback] and [preloadEpisode] call this to share one copy
  /// of the loadUrl-tracking + TimeoutException cleanup. The caller keeps
  /// its own `_canContinue(shouldContinue)` / `_disposed` guards around
  /// the await — passing them in via [shouldAbort] preserves the in-flight
  /// abort cadence each path requires.
  Future<bool> _executeTrackedLoad({
    required String url,
    required Map<String, String> headers,
    Duration? startAt,
    bool Function()? shouldAbort,
  }) async {
    // Suppress errors from the previous load — it was abandoned when
    // this method was re-entered via a fast episode switch.
    _lastLoadOperation?.catchError((Object _) {});
    _lastLoadOriginUrl = url;
    _mediaUnauthorized = false;
    final playbackUrl = await IosVideoCacheService.instance.resolvePlaybackUrl(
      url,
    );
    if (shouldAbort != null && shouldAbort()) return false;
    if (playbackUrl != url) {
      StoryLogger.d(
        'loadUrl via iOS proxy originHost=${Uri.tryParse(url)?.host} '
        'proxyHost=${Uri.tryParse(playbackUrl)?.host}',
        tag: tag,
      );
    }
    _frameTracker.resetFrameEvidence();
    // Track the raw loadUrl future (not the .timeout wrapper) so a
    // TimeoutException does not clear our handle while native work continues.
    final loadFuture = _nativeController!.loadUrl(
      url: playbackUrl,
      headers: headers,
      startAt: startAt,
    );
    // Capture the Set, not this engine, so a permanently wedged native Future
    // cannot retain the entire playback/UI callback graph through cleanup.
    final nativeLoadDrains = _nativeLoadDrainOperations;
    nativeLoadDrains.add(loadFuture);
    unawaited(
      loadFuture
          .whenComplete(() {
            nativeLoadDrains.remove(loadFuture);
          })
          .catchError((Object _) {}),
    );
    _lastLoadOperation = loadFuture;
    try {
      await loadFuture.timeout(_loadTimeout);
      if (identical(_lastLoadOperation, loadFuture)) {
        _lastLoadOperation = null;
      }
    } on TimeoutException {
      // Keep [_lastLoadOperation] until native settles.
      loadFuture
          .whenComplete(() {
            if (identical(_lastLoadOperation, loadFuture)) {
              _lastLoadOperation = null;
            }
          })
          .catchError((Object _) {});
      rethrow;
    } catch (_) {
      if (identical(_lastLoadOperation, loadFuture)) {
        _lastLoadOperation = null;
      }
      rethrow;
    }
    return true;
  }

  Future<void> waitForViewReady({
    Duration extraDelay = StoryDurations.playerViewReadyDelay,
  }) async {
    return NativePlayerBootstrap.waitForViewReady(extraDelay: extraDelay);
  }

  Future<bool> _waitForPlatformView({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final controller = _nativeController;
    if (controller == null) return false;
    if (controller.hasPlatformView) return true;

    final mounted = Completer<void>();
    void onActivity(PlayerActivityEvent event) {
      if (controller.hasPlatformView && !mounted.isCompleted) {
        mounted.complete();
      }
    }

    controller.addActivityListener(onActivity);
    try {
      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        if (controller.hasPlatformView) return true;
        if (mounted.isCompleted) return controller.hasPlatformView;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return controller.hasPlatformView;
    } finally {
      controller.removeActivityListener(onActivity);
    }
  }

  /// Public wait used by recommend remount / soft-resume after occlusion.
  Future<bool> waitForPlatformView({
    Duration timeout = const Duration(seconds: 2),
  }) => _waitForPlatformView(timeout: timeout);

  Future<bool?> togglePlayPause() async {
    if (_disposed) return null;
    final controller = _nativeController;
    if (controller == null) return null;
    try {
      if (_isPlaying) {
        final command = ++_transportCommandGeneration;
        final ok = await _nativeCall(controller.pause(), label: 'pause');
        if (!ok || command != _transportCommandGeneration) return null;
        _isPlaying = false;
      } else {
        // Surface may have been torn down while route-covered; reconnect
        // before play() so a tap right after pop is not a silent NO_VIEW.
        await ensureSurfaceConnected();
        final command = ++_transportCommandGeneration;
        final frameBeforePlay = _frameTracker.frameSequence;
        final ok = await _nativeCall(controller.play(), label: 'play');
        if (!ok || command != _transportCommandGeneration) return null;

        // Resuming from user pause / post-remount often reuses the last
        // decoded frame — native may not emit a new frame event. Same rule
        // as [migrateToActive]: accept timeout when we already painted once.
        final frameWait = await waitForFrameResult(frameBeforePlay);
        final frameOk =
            frameWait == FrameWaitResult.presented ||
            (frameWait == FrameWaitResult.timedOut && hasPresentedFirstFrame);
        if (!frameOk || command != _transportCommandGeneration) return null;
        _isPlaying = true;
      }
      listener?.onPlayingChanged(this, _isPlaying);
      return _isPlaying;
    } catch (e) {
      StoryLogger.d('Player control skipped: $e', tag: tag);
      return null;
    }
  }

  Future<bool> resumePlayback({
    Duration frameTimeout = StoryConstants.playerFirstFrameTimeout,
  }) async {
    if (_disposed) return false;
    try {
      await ensureSurfaceConnected();
      final command = ++_transportCommandGeneration;
      final frameBeforePlay = _frameTracker.frameSequence;
      final ok = await _nativeCall(_nativeController?.play(), label: 'play');
      if (!ok) return false;
      final frameWait = await waitForFrameResult(
        frameBeforePlay,
        timeout: frameTimeout,
      );
      final frameOk =
          frameWait == FrameWaitResult.presented ||
          (frameWait == FrameWaitResult.timedOut && hasPresentedFirstFrame);
      if (!frameOk) return false;
      if (command != _transportCommandGeneration) return false;
      _isPlaying = true;
      listener?.onPlayingChanged(this, true);
      return true;
    } catch (e) {
      StoryLogger.d('Resume playback skipped: $e', tag: tag);
      return false;
    }
  }

  /// Single resume entry for both feeds — pick [FeedResumeStyle] instead of
  /// calling [resumePlayback] / [startPlayback] ad hoc.
  Future<bool> resumeForFeed(
    FeedResumeStyle style, {
    Duration frameTimeout = StoryConstants.playerFirstFrameTimeout,
  }) {
    switch (style) {
      case FeedResumeStyle.waitForFrame:
        return resumePlayback(frameTimeout: frameTimeout);
      case FeedResumeStyle.playCommandOnly:
        return startPlayback();
    }
  }

  /// Rebind the native surface after backgrounding (Android SurfaceView /
  /// TextureView may have been destroyed while the Flutter view stayed mounted).
  Future<void> ensureSurfaceConnected() async {
    if (_disposed || _nativeController == null) return;
    await _nativeCall(
      _nativeController?.ensureSurfaceConnected(),
      label: 'ensureSurfaceConnected',
    );
  }

  /// Snapshots the current decoded frame from the native player surface.
  Future<Uint8List?> captureCurrentFrame({
    int maxWidth = 480,
    Duration timeout = StoryConstants.playerControlTimeout,
  }) async {
    if (_disposed || _nativeController == null || !hasPresentedFirstFrame) {
      return null;
    }
    try {
      return await _nativeController!
          .captureCurrentFrame(maxWidth: maxWidth)
          .timeout(timeout);
    } on TimeoutException {
      StoryLogger.w('captureCurrentFrame timed out', tag: tag);
      return null;
    } catch (e) {
      StoryLogger.d('captureCurrentFrame failed', error: e, tag: tag);
      return null;
    }
  }

  /// Prepare cookies for a soft foreground resume.
  ///
  /// Returns `false` when signed cookies are present but already expired —
  /// soft play would 403; the caller should force-reactivate instead.
  Future<bool> prepareCookiesForForegroundResume() async {
    if (_disposed) return false;
    await refreshCookiesIfNearExpiry();
    if (_disposed) return false;
    final play = _currentPlay;
    final cookies = play?.signedCookies;
    if (cookies != null && !cookies.isValid) {
      StoryLogger.w(
        'Foreground resume blocked: CloudFront cookies expired',
        tag: tag,
      );
      return false;
    }
    final url = play?.effectivePlayUrl;
    if (play != null && url != null && url.isNotEmpty) {
      // OS / WebView may have cleared the jar while we were backgrounded.
      return _cookieSvc.applyCookiesIfNeeded(play, url);
    }
    return true;
  }

  Future<void> pause() async {
    if (_disposed) return;
    final command = ++_transportCommandGeneration;
    final controller = _nativeController;
    if (controller == null) {
      if (command == _transportCommandGeneration) {
        _isPlaying = false;
      }
      return;
    }
    try {
      await _nativeCall(controller.pause(), label: 'pause');
      if (command != _transportCommandGeneration) return;
      _isPlaying = false;
      listener?.onPlayingChanged(this, false);
    } catch (e) {
      if (command != _transportCommandGeneration) return;
      _isPlaying = false;
      // NO_VIEW is expected when the platform view was already torn down
      // (e.g. navigating under another route). Avoid noisy error spam.
      if (_isNoViewError(e)) {
        StoryLogger.d('pause skipped: native view already gone', tag: tag);
        return;
      }
      StoryLogger.d('原生播放器暂停失败: $e', tag: tag);
    }
  }

  /// Await a native method-channel future with a hard budget.
  ///
  /// A disposed / remounting platform view can leave [invokeMethod] pending
  /// forever; without a timeout the feed activate queue (and UI) wedges.
  /// Returns `false` on timeout so callers can fall back.
  Future<bool> _nativeCall(
    Future<void>? future, {
    required String label,
    Duration timeout = StoryConstants.playerControlTimeout,
  }) async {
    if (future == null || _disposed) return false;
    try {
      await future.timeout(timeout);
      return true;
    } on TimeoutException {
      StoryLogger.w(
        '$label timed out after ${timeout.inMilliseconds}ms',
        tag: tag,
      );
      return false;
    }
  }

  /// Drop the native controller reference without disposing the engine.
  ///
  /// Used when the platform view is destroyed (fullscreen cover) so the next
  /// attach must re-run [NativePlayerBootstrap.initialize]. Caller is
  /// responsible for disposing [previous] if non-null.
  NativeVideoPlayerController? detachNativeController() {
    _detachListeners();
    final previous = _nativeController;
    _nativeController = null;
    _nativeInitialized = false;
    _isPlaying = false;
    return previous;
  }

  static bool _isNoViewError(Object e) {
    if (e is PlatformException && e.code == 'NO_VIEW') return true;
    final msg = e.toString();
    return msg.contains('NO_VIEW') || msg.contains('No view found');
  }

  /// Loop the current item instead of emitting [onCompleted].
  ///
  /// Native iOS/Android already restart without a `completed` event when
  /// looping is on; this flag is the Dart-side fallback if one still arrives.
  Future<void> setLooping(bool looping) async {
    if (_disposed) return;
    _looping = looping;
    await _applyLooping();
  }

  Future<void> _applyLooping() async {
    if (_disposed || _nativeController == null) return;
    await _nativeCall(
      _nativeController?.setLooping(_looping),
      label: 'setLooping',
    );
  }

  Future<void> seekTo(Duration position) async {
    if (_disposed) return;
    _completed = false;
    await _nativeCall(_nativeController?.seekTo(position), label: 'seekTo');
    _position = position;
    positionNotifier.value = position;
  }

  /// Start applying CloudFront cookies for [play] early.
  /// Returns a future that resolves with whether cookies were applied.
  /// Callers can pass this future to [applyPlayback] via [cookiePreApplied]
  /// so cookie application overlaps with prefetch / UI work.
  ///
  /// Pass [background] `true` for inactive-slot / preload paths so the shared
  /// CloudFront cookie jar is not re-marked as the foreground resource.
  Future<bool> preApplyCookies(
    DramaPlayResponse play,
    String url, {
    bool background = false,
  }) {
    return _cookieSvc.applyCookiesIfNeeded(play, url, background: background);
  }

  Future<bool> applyCookiesIfNeeded(
    DramaPlayResponse play,
    String url, {
    bool background = false,
  }) {
    return _cookieSvc.applyCookiesIfNeeded(play, url, background: background);
  }

  Future<void> restoreResumeIfNeeded(int episodeNo) async {
    final resumeMs = _localRepo.getWatchProgress(dramaId, episodeNo);
    if (resumeMs <= 0) return;
    StoryLogger.d('--- Restoring progress: ${resumeMs}ms ---', tag: tag);
    try {
      await _nativeController
          ?.seekTo(Duration(milliseconds: resumeMs))
          .timeout(StoryConstants.playerOperationTimeout);
    } catch (e, st) {
      StoryLogger.w(
        'restoreResumeIfNeeded seekTo failed',
        error: e,
        stackTrace: st,
        tag: tag,
      );
    }
  }

  /// Starts native playback and reports whether the command completed.
  ///
  /// A platform-channel timeout is not playback success. Callers must not
  /// commit `ready` / `isPlaying` when this returns false.
  Future<bool> startPlayback() async {
    if (_role != PlaybackEngineRole.active) {
      StoryLogger.d('skip play() on preload slot', tag: tag);
      return false;
    }
    if (!await _waitIfNativeTeardown()) return false;
    StoryLogger.d('--- Starting playback ---', tag: tag);
    _completed = false;
    await _applyLooping();
    final command = ++_transportCommandGeneration;
    try {
      final ok = await _nativeCall(_nativeController?.play(), label: 'play');
      if (!ok) {
        StoryLogger.w('Playback start command did not complete', tag: tag);
        return false;
      }
      if (command != _transportCommandGeneration) {
        StoryLogger.d('Playback start superseded by a newer command', tag: tag);
        return false;
      }
      StoryLogger.d('✅ Playback started', tag: tag);
      return true;
    } catch (e, st) {
      StoryLogger.w(
        'Playback start command failed',
        error: e,
        stackTrace: st,
        tag: tag,
      );
      return false;
    }
  }

  /// iOS often ACKs play() while the AVPlayerItem is still paused after
  /// loadUrl — or after a sibling AVPlayer is deallocated (drama-feed pop).
  /// Delayed kicks cover that; never re-play while buffering/loading, but
  /// keep polling those windows so a brief loading flash does not skip the
  /// pause-recovery path entirely.
  Future<void> _kickPlayIfStillPaused({bool Function()? shouldContinue}) async {
    if (_role != PlaybackEngineRole.active) return;
    if (_nativeController?.hasPlatformView != true) return;
    for (
      var attempt = 0;
      attempt < FeedPlaybackPolicy.playAckRetryAttempts;
      attempt++
    ) {
      if (!_canContinue(shouldContinue)) return;
      if (_kickLoopSatisfied()) return;
      await Future<void>.delayed(FeedPlaybackPolicy.playAckRetryGap);
      if (!_canContinue(shouldContinue)) return;
      if (_kickLoopSatisfied()) return;
      // Startup in flight — wait out this attempt without interrupting.
      if (_isStartupBusy()) continue;
      StoryLogger.d(
        'play() ACK without playing/frame; retry play() #${attempt + 1}',
        tag: tag,
      );
      await ensureSurfaceConnected();
      if (!_canContinue(shouldContinue)) return;
      if (_kickLoopSatisfied()) return;
      if (_isStartupBusy()) continue;
      await startPlayback();
    }
  }

  bool _kickLoopSatisfied() {
    final nativeState = _nativeController?.activityState;
    return FeedPlaybackPolicy.kickLoopSatisfied(
      isPlaying: _isPlaying || nativeState == PlayerActivityState.playing,
      hasPresentedFirstFrame: hasPresentedFirstFrame,
      completed: _completed,
      unauthorized: _mediaUnauthorized,
    );
  }

  bool _isStartupBusy() {
    final nativeState = _nativeController?.activityState;
    return FeedPlaybackPolicy.isStartupBusy(
      isBuffering:
          _isBuffering || nativeState == PlayerActivityState.buffering,
      isLoading: nativeState == PlayerActivityState.loading,
    );
  }

  /// Silently load the given episode on this engine without playing.
  ///
  /// - Initializes the native controller if this is the first load (uses
  ///   [coordinator] if set, otherwise the default instance).
  /// - Mutes the player before loading to prevent an audio blip.
  /// - Pauses after load so the first frame is decoded and ready.
  ///
  /// Returns `true` if the load completed successfully.
  Future<bool> preloadEpisode({
    required DramaPlayResponse play,
    required String url,
    required Map<String, String> headers,
    required int episodeNo,
    Duration viewReadyDelay = StoryDurations.playerViewReadyDelay,
  }) async {
    if (_nativeController == null || _disposed) return false;
    _role = PlaybackEngineRole.preload;
    StoryLogger.d('--- 预加载第 $episodeNo 集 (静音) ---', tag: tag);

    try {
      if (!await _waitIfNativeTeardown()) return false;
      if (_nativeController == null || _disposed) return false;
      await cancelStaleLoad();
      if (_nativeController == null || _disposed) return false;
      // Never overlap loadUrl on the same AVPlayer — the abandoned op may
      // still be running after cancelStaleLoad's short wait.
      if (hasPendingLoad) {
        StoryLogger.d(
          'preload skipped ep=$episodeNo: previous load still pending',
          tag: tag,
        );
        return false;
      }

      // Neighbor slots mount after first ready. Always require a live view —
      // [isInitialized]/[_nativeInitialized] can outlive dispose (NO_VIEW).
      final controller = _nativeController;
      if (controller == null) return false;
      if (!controller.hasPlatformView) {
        if (_nativeInitialized) invalidateNativeInitialization();
        // Short wait: neighbors attach ~50ms after first frame. A long hang
        // here just delays the orchestrator's next kick.
        final mounted = await _waitForPlatformView(
          timeout: const Duration(milliseconds: 300),
        );
        if (!mounted || !controller.hasPlatformView) {
          StoryLogger.d(
            'preload skipped ep=$episodeNo: platform view not mounted',
            tag: tag,
          );
          return false;
        }
      }
      if (!_nativeInitialized) {
        await _ensureNativeInitialized(viewReadyDelay: viewReadyDelay);
      }

      // Preload must not touch the shared native cookie jar — that races the
      // foreground stream. Auth for loadUrl uses Cookie headers; activate
      // calls [promotePreloadedResource] to install the jar before play.
      final headerOnly = headers.containsKey('Cookie') ||
          (play.signedCookies != null && play.signedCookies!.isValid);
      if (headerOnly) {
        StoryLogger.d(
          'preload ep=$episodeNo: cookie jar skipped (header-only)',
          tag: tag,
        );
      } else {
        final cookiesOk =
            await applyCookiesIfNeeded(play, url, background: true);
        if (!cookiesOk) {
          StoryLogger.w('预加载 cookies 失败 episode=$episodeNo', tag: tag);
          return false;
        }
      }
      if (_disposed || hasPendingLoad) return false;

      // Mute before loading so no audio blip escapes. Must go through
      // setVolume so the dedupe cache tracks it; a raw native call here would
      // let a later unmute be skipped as redundant and strand the slot silent.
      await setVolume(0.0);

      // Suppress stale-load errors
      final loadHeaders = headers.isNotEmpty
          ? headers
          : CloudFrontCookieService.buildHeaders(play);
      final loadedOk = await _executeTrackedLoad(
        url: url,
        headers: loadHeaders,
        shouldAbort: () => _disposed || hasPendingLoad,
      );
      if (!loadedOk) return false;

      // Preload: hard 1080 cap only. Cellular soft peak runs when the slot
      // becomes active (migrateToActive / applyPlayback cold path).
      await _applyHardPlaybackPeak(loadUrl: url);
      if (_disposed || hasPendingLoad) return false;

      // loadUrl() does not auto-play, so a post-load pause is redundant here.
      // On Android/ExoPlayer this extra pause can flush the codec, which shows
      // up as stale/unknown buffer churn and adds avoidable rebuffer work
      // right before the slot is promoted to active.

      _currentEpisodeNo = episodeNo;
      _currentPlay = play;
      _position = Duration.zero;
      positionNotifier.value = Duration.zero;
      _isPlaying = false;

      StoryLogger.d('✅ 预加载完成: 第 $episodeNo 集', tag: tag);
      return true;
    } on TimeoutException catch (e, st) {
      // Same as applyPlayback: abandon the wedged native load so the 15s
      // plugin watchdog does not surface a stale error on a neighbor slot.
      forceAbandonPendingLoad();
      try {
        await _nativeCall(_nativeController?.pause(), label: 'preload-timeout-pause');
      } catch (_) {}
      StoryLogger.d(
        '预加载超时 episode=$episodeNo',
        error: e,
        stackTrace: st,
        tag: tag,
      );
      return false;
    } catch (e, st) {
      if (_isNoViewError(e)) {
        invalidateNativeInitialization();
        StoryLogger.d(
          '预加载跳过 episode=$episodeNo (NO_VIEW — surface not mounted)',
          tag: tag,
        );
        return false;
      }
      StoryLogger.e(
        '预加载失败 episode=$episodeNo',
        error: e,
        stackTrace: st,
        tag: tag,
      );
      return false;
    }
  }

  /// Quietly decode one frame on a preload slot so neighbor covers can unmount.
  ///
  /// [preloadEpisode] only `loadUrl`s — many platforms never paint until
  /// `play()`. A brief muted play→pause primes [hasPresentedFirstFrame]
  /// without promoting the slot to active. Skips if a frame already exists.
  Future<bool> primePreloadFirstFrame({
    Duration timeout = const Duration(milliseconds: 1200),
    bool Function()? shouldContinue,
  }) async {
    if (_disposed || _nativeController == null) return false;
    if (_role != PlaybackEngineRole.preload) return hasPresentedFirstFrame;
    if (hasPresentedFirstFrame) return true;
    if (_currentPlay == null) return false;
    bool stillWanted() =>
        !_disposed &&
        _role == PlaybackEngineRole.preload &&
        (shouldContinue == null || shouldContinue());

    await setVolume(0.0);
    if (!stillWanted()) return false;

    final frameBefore = _frameTracker.frameSequence;
    final command = ++_transportCommandGeneration;
    try {
      final ok = await _nativeCall(
        _nativeController?.play(),
        label: 'prime-play',
      );
      if (!ok || !stillWanted() || command != _transportCommandGeneration) {
        await _nativeCall(_nativeController?.pause(), label: 'prime-pause');
        return hasPresentedFirstFrame;
      }
      await waitForFrameResult(
        frameBefore,
        timeout: timeout,
        shouldContinue: stillWanted,
      );
    } finally {
      if (!_disposed) {
        await _nativeCall(_nativeController?.pause(), label: 'prime-pause');
        await setVolume(0.0);
        _isPlaying = false;
      }
    }
    return hasPresentedFirstFrame;
  }

  /// Promotes the preloaded media's CloudFront cookies to foreground.
  ///
  /// Preload is **header-only** (does not write the shared native jar).
  /// Before swapping this engine into the active slot, the caller must
  /// promote so subsequent HLS segment requests use the new signature.
  ///
  /// Fast path: if the native jar already holds this URL+signature, only
  /// [CloudFrontCookieService.markActiveResource] runs (no MethodChannel).
  Future<bool> promotePreloadedResource() {
    return _cookieSvc.promotePreloadedResource(_currentPlay);
  }

  /// Transition this engine from preload → active: unmute, play, notify.
  ///
  /// [shouldContinue] is checked between async steps so a superseded swipe can
  /// abort before/after play and avoid "audio plays, video frozen" from a
  /// stale migrate racing the next activate.
  Future<bool> migrateToActive({bool Function()? shouldContinue}) async {
    if (_disposed || _nativeController == null) return false;
    bool stillWanted() =>
        !_disposed && (shouldContinue == null || shouldContinue());

    _role = PlaybackEngineRole.active;
    StoryLogger.d('--- 预加载播放器切为活跃 (episode $_currentEpisodeNo) ---', tag: tag);

    // Capture playhead before clearing UI progress. Preload usually sits at 0;
    // a redundant seekTo(0) right before play() commonly freezes the video
    // track while audio still starts. Only seek when the playhead moved
    // (e.g. reverse-swipe reuse mid-episode).
    final playhead = _nativeController!.currentPosition > _position
        ? _nativeController!.currentPosition
        : _position;
    _position = Duration.zero;
    positionNotifier.value = Duration.zero;

    if (playhead >
        const Duration(milliseconds: StoryConstants.migrateSeekThresholdMs)) {
      try {
        await _nativeCall(
          _nativeController?.seekTo(Duration.zero),
          label: 'migrate-seekTo(0)',
        );
      } catch (e) {
        StoryLogger.d('seekTo(0) during migrate failed', error: e, tag: tag);
      }
    }
    if (!stillWanted()) return false;

    // Cellular soft peak before play (preload only applied the hard cap).
    final peakUrl = _currentPlay?.effectivePlayUrl;
    if (peakUrl != null && peakUrl.isNotEmpty) {
      await _applyStartupPlaybackPeak(loadUrl: peakUrl);
    }
    if (!stillWanted()) return false;

    // Promote can race layout: play() ACK on a missing platform view leaves
    // the item paused through the whole first-frame window. Match recommend's
    // flush budget before issuing play.
    await ensureSurfaceConnected();
    if (!stillWanted()) return false;
    if (_nativeController?.hasPlatformView != true) {
      final deadline = DateTime.now().add(const Duration(milliseconds: 800));
      while (_nativeController?.hasPlatformView != true &&
          DateTime.now().isBefore(deadline)) {
        if (!stillWanted()) return false;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (_nativeController?.hasPlatformView != true) {
        StoryLogger.w(
          'migrateToActive: no platform view after wait',
          tag: tag,
        );
        return false;
      }
      await ensureSurfaceConnected();
      if (!stillWanted()) return false;
    }

    // Recommend feed keeps a poster until first frame is presented, so
    // delay unmuting until then to avoid "audio starts before video".
    await setVolume(_isRecommendFamily ? 0.0 : 1.0);
    if (!stillWanted()) {
      await setVolume(0.0);
      return false;
    }

    final frameBeforePlay = _frameTracker.frameSequence;
    final playbackStarted = await startPlayback();
    if (!playbackStarted) {
      _isPlaying = false;
      listener?.onPlayingChanged(this, false);
      await setVolume(0.0);
      return false;
    }
    await _kickPlayIfStillPaused(shouldContinue: shouldContinue);
    if (!stillWanted()) {
      await setVolume(0.0);
      return false;
    }
    if (_mediaUnauthorized && !hasPresentedFirstFrame) {
      // CDN refused this URL — skip the first-frame timeout, no frame is
      // coming. Same outcome as the frame wait timing out below.
      _isPlaying = false;
      listener?.onPlayingChanged(this, false);
      await setVolume(0.0);
      return false;
    }
    final frameWait = await waitForFrameResult(
      frameBeforePlay,
      shouldContinue: stillWanted,
    );
    final framePresented =
        frameWait == FrameWaitResult.presented ||
        (frameWait == FrameWaitResult.timedOut && hasPresentedFirstFrame);
    if (!framePresented) {
      _isPlaying = false;
      listener?.onPlayingChanged(this, false);
      await setVolume(0.0);
      return false;
    }
    if (!stillWanted()) {
      // Mute only — do not pause. pause()-immediately-after-play before the
      // first frame paints freezes video on the next migrateToActive, while
      // the winning activate will silenceExceptSlot this engine anyway.
      await setVolume(0.0);
      return false;
    }
    await _releaseCellularSoftPeakIfNeeded();
    if (!stillWanted()) {
      await setVolume(0.0);
      return false;
    }
    _isPlaying = true;
    listener?.onPlayingChanged(this, true);

    // We already waited for a fresh frame after play(). Avoid issuing an
    // immediate follow-up seek here: on HLS streams that seek commonly forces
    // an unnecessary rebuffer right after activation, which shows up as
    // play -> buffering -> play oscillation in the feed logs.
    return stillWanted();
  }

  /// Force the texture / surface to present a fresh sample after play.
  Future<void> nudgeTextureFrame() async {
    if (_disposed || _nativeController == null) return;
    final pos = _nativeController!.currentPosition;
    final target = pos < const Duration(milliseconds: 16)
        ? const Duration(milliseconds: 33)
        : pos;
    await _nativeCall(
      _nativeController?.seekTo(target),
      label: 'texture-nudge',
    );
  }

  /// Mute/unmute the native player.
  ///
  /// Pass [force] after OS lifecycle (background → foreground) so we re-hit
  /// the platform channel even when Dart still thinks volume is already the
  /// target — iOS may have ducked/muted AVPlayer without our cache noticing.
  double _currentVolume = -1.0; // sentinel: first call always applies

  Future<void> setVolume(double volume, {bool force = false}) async {
    if (_disposed || _nativeController == null) {
      // The request never reached native, so the cache no longer describes it.
      _currentVolume = -1.0;
      return;
    }
    if (!force && volume == _currentVolume) {
      return; // skip redundant MethodChannel call
    }
    try {
      await _nativeCall(
        _nativeController?.setVolume(volume),
        label: 'setVolume',
      );
      _currentVolume = volume;
    } catch (e) {
      // NO_VIEW / teardown races are common here. Committing the cache before
      // the call would make every later identical request a silent no-op and
      // strand the engine audible.
      _currentVolume = -1.0;
      StoryLogger.d('setVolume failed: $e', tag: tag);
    }
  }

  /// Persist the current position for [episodeNo] (e.g. on pause / leave).
  ///
  /// Unlike the periodic save in [_handleControlEvent], this always writes
  /// when position > 0 even if [restoreWatchProgress] is false — feed /
  /// recommend flows disable auto-restore but still need resume points on exit.
  Future<void> persistResume(int episodeNo) async {
    if (_position.inMilliseconds <= 0) return;
    await _localRepo.saveWatchProgress(
      dramaId,
      episodeNo,
      _position.inMilliseconds,
    );
  }

  void clearWatchProgress(int episodeNo) {
    _localRepo.clearWatchProgress(dramaId, episodeNo);
  }

  /// Build CloudFront cookie headers for [play].
  Map<String, String> buildHeaders(DramaPlayResponse play) =>
      CloudFrontCookieService.buildHeaders(play);

  /// Pre-caches the video media segments and warms DNS resolution for the given episode.
  Future<void> preheatEpisode(int episodeNo, {double budgetRatio = 1.0}) async {
    try {
      final play = await _dramaRepo.prefetchEpisode(dramaId, episodeNo);
      if (play != null) {
        await VideoPrecacheService.instance.precachePlay(
          play,
          budgetRatio: budgetRatio,
          priority: PrecachePriority.active,
        );
        StoryLogger.d(
          '✅ PlaybackEngine: 预热缓存成功: 第 $episodeNo 集 '
          'budgetRatio=$budgetRatio',
          tag: tag,
        );
      }
    } catch (e) {
      StoryLogger.w(
        'Preheat failed in PlaybackEngine: $episodeNo',
        error: e,
        tag: tag,
      );
    }
  }

  /// Clear stale play cache, refetch episode metadata, and retry load once.
  ///
  /// Used after loadUrl retries are exhausted (often expired CloudFront
  /// cookies served from Hive). Does not re-run the 3-attempt loop.
  Future<bool> recoverFromStaleAuth({
    required int episodeNo,
    required bool isSwitch,
    bool Function()? shouldContinue,
    Duration? startAt,
  }) async {
    if (_disposed) return false;
    StoryLogger.w(
      'recoverFromStaleAuth episode=$episodeNo switch=$isSwitch',
      tag: tag,
    );
    _dramaRepo.clearPrefetchCache(dramaId, episodeNo);
    final data = await fetchEpisodeData(episodeNo);
    if (data == null || !_canContinue(shouldContinue)) return false;
    return applyPlayback(
      data.play,
      data.url,
      data.headers,
      isSwitch: isSwitch,
      episodeNo: episodeNo,
      retry: false,
      shouldContinue: shouldContinue,
      startAt: startAt,
    );
  }

  /// If current cookies are near expiry, silently refetch play metadata and
  /// re-apply cookies without interrupting the active AVPlayer item.
  Completer<DramaPlayResponse?>? _cookieRefreshInflight;

  Future<void> refreshCookiesIfNearExpiry() async {
    // Dedup: if a refresh is already in-flight, wait for it instead of starting
    // another one. Multiple engines calling this concurrently only hit the
    // network once.
    final existing = _cookieRefreshInflight;
    if (existing != null && !existing.isCompleted) {
      await existing.future;
      return;
    }
    final completer = Completer<DramaPlayResponse?>();
    _cookieRefreshInflight = completer;
    try {
      final fresh = await _cookieSvc.refreshCookiesIfNearExpiry(
        episodeNo: _currentEpisodeNo,
        play: _currentPlay,
        isDisposed: _disposed,
      );
      if (fresh != null) {
        _currentPlay = fresh;
      }
      if (!completer.isCompleted) completer.complete(fresh);
    } catch (e) {
      if (!completer.isCompleted) completer.complete(null);
    } finally {
      _cookieRefreshInflight = null;
    }
  }

  /// Detach and dispose the native view without tearing down the engine.
  Future<void> releaseNativePlayer() async {
    if (_disposed) return;
    // Wait for every raw in-flight load, including one whose logical lock was
    // abandoned while this feed was hidden, before tearing down native state.
    final pendingLoads = List<Future<void>>.of(_nativeLoadDrainOperations);
    try {
      await Future.wait<void>(
        pendingLoads.map((load) => load.catchError((Object _) {})),
      ).timeout(StoryConstants.playerOperationTimeout);
    } catch (e) {
      StoryLogger.d(
        'Wait for native loads before release failed',
        error: e,
        tag: tag,
      );
    }
    await pause();
    _detachListeners();
    try {
      await _nativeController?.dispose().catchError((Object e) {
        StoryLogger.d(
          'nativeController dispose catchError (non-fatal)',
          error: e,
          tag: tag,
        );
      });
    } catch (e, st) {
      StoryLogger.w(
        'releaseNativePlayer dispose failed',
        error: e,
        stackTrace: st,
        tag: tag,
      );
    }
    _nativeController = null;
    _currentPlay = null;
    _currentEpisodeNo = null;
    final c = coordinator ?? NativeVideoPlayerCoordinator.instance;
    await c.release(_playerOwner);
  }

  /// Release coordinator ownership without disposing the native controller.
  ///
  /// Used when the page owns controller lifetime (VideoFeed dual players) so
  /// [dispose] / page teardown never double-dispose the same platform view.
  void relinquishControllerOwnership() {
    _detachListeners();
    // Abandon in-flight bootstrap waits — the page-owned controller is gone
    // and joining a hung plugin initialize Completer would freeze the next
    // feed entry on this process.
    _eagerInitPending = null;
    _nativeController = null;
    _nativeInitialized = false;
    _isPlaying = false;
    if (_disposed) return;
    final c = coordinator ?? NativeVideoPlayerCoordinator.instance;
    // Synchronous owner clear so the next acquire (banner / feed) sees idle
    // in the same turn — unawaited async release can race the next waiter.
    c.releaseNow(_playerOwner);
  }

  /// Disposes this engine and completes only after native/player-cookie
  /// resources have been handed off. Route transitions use this awaited form
  /// so the next feed cannot start while an old AVPlayer or cookie clear is
  /// still in flight.
  /// 页面切换必须等待该 Future，不能在原生 loadUrl 未结束时销毁播放器。
  Future<void> disposeAndWait({bool disposeNativeController = true}) {
    final pendingDispose = _disposeFuture;
    if (pendingDispose != null) return pendingDispose;
    if (_disposed) return Future<void>.value();
    _disposed = true;
    _frameTracker.markDisposed();
    if (_role == PlaybackEngineRole.active) {
      _cookieSvc.releaseActiveFamily();
    }
    _cookieSvc.disposed = true;
    _detachListeners();
    // Capture local refs before nulling — the async continuation must not
    // read the cleared fields (otherwise pause/dispose never run).
    final controller = _nativeController;
    final owner = _playerOwner;
    final pendingLoads = List<Future<void>>.of(_nativeLoadDrainOperations);
    final logicalPendingLoad = _lastLoadOperation;
    if (logicalPendingLoad != null &&
        !pendingLoads.contains(logicalPendingLoad)) {
      pendingLoads.add(logicalPendingLoad);
    }
    final c = coordinator ?? NativeVideoPlayerCoordinator.instance;
    _nativeController = null;
    _currentPlay = null;
    _currentEpisodeNo = null;
    final url = _cookieSvc.urlToClear;
    final cookieClear = url == null
        ? Future<void>.value()
        : _cookieSvc.clearCookies(url);
    positionNotifier.dispose();

    if (!disposeNativeController) {
      // Page (or caller) owns the NativeVideoPlayerController lifetime.
      // Still drain raw loads before returning: the caller disposes its native
      // controller as soon as this Future completes.
      final future = () async {
        try {
          await Future.wait<void>(
            pendingLoads.map((load) => load.catchError((Object _) {})),
          ).timeout(StoryConstants.playerOperationTimeout);
        } on TimeoutException {
          StoryLogger.w(
            'pending load did not settle before detached dispose timeout',
            tag: tag,
          );
        } finally {
          await c.release(owner, settleDelay: Duration.zero);
          await cookieClear;
        }
      }();
      _disposeFuture = future;
      return future;
    }

    // Wait for any in-flight load, then pause + dispose so AVPlayer stops
    // before the platform view is torn down (prevents audio continuing).
    final future = () async {
      try {
        try {
          await Future.wait<void>(
            pendingLoads.map((load) => load.catchError((Object _) {})),
          ).timeout(StoryConstants.playerOperationTimeout);
        } on TimeoutException {
          StoryLogger.w(
            'pending load did not settle before dispose timeout',
            tag: tag,
          );
          controller?.abortPendingInitialize();
        }
        try {
          await controller?.pause().timeout(
            StoryConstants.playerControlTimeout,
          );
        } catch (e) {
          StoryLogger.d(
            'controller.pause during dispose failed',
            error: e,
            tag: tag,
          );
        }
        try {
          await controller
              ?.dispose()
              .catchError((Object e) {
                if (e is PlatformException && e.code == 'NO_VIEW') return null;
                return null;
              })
              .timeout(StoryConstants.playerControlTimeout);
        } catch (e) {
          StoryLogger.d('controller.dispose failed', error: e, tag: tag);
        }
      } finally {
        await c.release(owner);
        await cookieClear;
      }
    }();
    _disposeFuture = future;
    return future;
  }

  void dispose({bool disposeNativeController = true}) {
    unawaited(disposeAndWait(disposeNativeController: disposeNativeController));
  }

  bool _canContinue(bool Function()? shouldContinue) {
    return !_disposed &&
        _nativeController != null &&
        (shouldContinue == null || shouldContinue());
  }

  Future<bool> _waitIfNativeTeardown() async {
    if (!NativeVideoPlayerCoordinator.isTearingDown) {
      return !_disposed && _nativeController != null;
    }
    StoryLogger.d('defer until native teardown idle', tag: tag);
    await NativeVideoPlayerCoordinator.waitForTeardown(
      timeout: const Duration(seconds: 90),
    );
    return !NativeVideoPlayerCoordinator.isTearingDown &&
        !_disposed &&
        _nativeController != null;
  }

  static bool _isUnsupportedUrlMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('unsupported url') ||
        lower.contains('unsupportedurl');
  }

  static bool _isUnsupportedUrlError(Object error) {
    return _isUnsupportedUrlMessage(error.toString());
  }

  /// Always include the CDN URL so a failed item can be grepped from logcat.
  void _logPlaybackFailure(
    Object reason, {
    String? url,
    DramaPlayResponse? play,
  }) {
    final resolved = play ?? _currentPlay;
    final failedUrl =
        url ?? _lastLoadOriginUrl ?? resolved?.effectivePlayUrl ?? '';
    final cookies = resolved?.signedCookies;
    final hasCookies = cookies != null && cookies.isValid;
    final failure = FeedPlaybackPolicy.classifyFailure(reason);
    StoryLogger.e(
      'playback failed failure=${failure.name} url=$failedUrl '
      'drama=${resolved?.dramaId ?? dramaId} '
      'ep=${resolved?.episodeNo ?? _currentEpisodeNo} '
      'cookies=$hasCookies '
      'reason=$reason',
      error: reason,
      tag: tag,
    );
  }

  void _detachListeners() {
    _nativeController?.removeActivityListener(_handleActivityEvent);
    _nativeController?.removeControlListener(_handleControlEvent);
  }

  /// Public variant so callers (detail page) can detach without disposal.
  void detachListeners() => _detachListeners();

  void _handleActivityEvent(PlayerActivityEvent event) {
    StoryLogger.d('PlayerActivity: ${event.state}', tag: tag);
    listener?.onActivityEvent(this, event);

    // Track state transitions as implicit frame evidence.
    // The native player may not emit firstFrame/frameRendered control events
    // on all platforms (iOS AVPlayer, Android Media3), but entering playing
    // proves a frame was rendered; entering paused from playing also means
    // a frame was rendered (e.g. preload paused after first frame).
    final wasPlaying = _isPlaying;

    switch (event.state) {
      case PlayerActivityState.completed:
        _isPlaying = false;
        _isBuffering = false;
        _completed = true;
        final episodeNo = _currentEpisodeNo;
        if (episodeNo != null) clearWatchProgress(episodeNo);
        // onCompleted first so UI can latch ended/completed before the
        // follow-up paused event is treated as an unexpected stall.
        listener?.onCompleted(this);
        listener?.onPlayingChanged(this, false);
        return;
      case PlayerActivityState.loaded:
        final durationMs = asIntOrNull(event.data?['duration']);
        if (durationMs != null && durationMs > 0) {
          _duration = Duration(milliseconds: durationMs);
          listener?.onDurationChanged(this, _duration);
        }
        break;
      case PlayerActivityState.error:
        final message =
            asStringOrNull(event.data?['message']) ?? 'Unknown error';
        _logPlaybackFailure(message);
        if (FeedPlaybackPolicy.isUnauthorizedMediaError(message)) {
          // Stops _kickPlayIfStillPaused from replaying a URL the CDN just
          // rejected; only a credential refresh can fix this.
          _mediaUnauthorized = true;
        }
        // Poisoned iOS proxy mappings cause AVPlayer "unsupported URL";
        // drop them so the next applyPlayback attempt uses the origin CDN.
        if (_isUnsupportedUrlMessage(message)) {
          final origin = _lastLoadOriginUrl;
          if (origin != null && origin.isNotEmpty) {
            IosVideoCacheService.instance.invalidateProxy(origin);
          }
        }
        _isBuffering = false;
        listener?.onError(this, message);
        return;
      case PlayerActivityState.playing:
        _isPlaying = true;
        _isBuffering = false;
        // Entering playing guarantees at least one frame was decoded and
        // rendered — including cache-hit fast paths where buffering was
        // never observed. Record unconditionally.
        if (!_frameTracker.hasPresentedFirstFrame) {
          _recordFrame(isFirstFrame: true, renderedAt: DateTime.now());
        }
        listener?.onPlayingChanged(this, true);
        listener?.onBufferingChanged(this, false);
        break;
      case PlayerActivityState.paused:
        _isPlaying = false;
        // Record a frame only when the engine was previously playing
        // (including buffering→playing→paused sequences). Skip preload/
        // loading→paused transitions where no frame was actually rendered.
        if (wasPlaying && !_frameTracker.hasPresentedFirstFrame) {
          _recordFrame(isFirstFrame: true, renderedAt: DateTime.now());
        }
        _isBuffering = false;
        listener?.onPlayingChanged(this, false);
        listener?.onBufferingChanged(this, false);
        break;
      case PlayerActivityState.buffering:
        _isBuffering = true;
        listener?.onBufferingChanged(this, true);
        break;
      default:
        break;
    }
  }

  void _handleControlEvent(PlayerControlEvent event) {
    if (event.state == PlayerControlState.firstFrameRendered ||
        event.state == PlayerControlState.frameRendered) {
      _recordFrame(
        isFirstFrame: event.state == PlayerControlState.firstFrameRendered,
        renderedAt: DateTime.now(),
      );
      return;
    }
    if (event.state != PlayerControlState.timeUpdated || event.data == null) {
      return;
    }

    final posMs = asIntOrNull(event.data!['position']);
    final durMs = asIntOrNull(event.data!['duration']);
    if (posMs != null) {
      _position = Duration(milliseconds: posMs);
      positionNotifier.value = _position;
    }
    if (durMs != null && durMs > 0) {
      final next = Duration(milliseconds: durMs);
      if (_duration != next) {
        _duration = next;
        listener?.onDurationChanged(this, _duration);
      }
    }

    final episodeNo = _currentEpisodeNo;
    if (restoreWatchProgress &&
        episodeNo != null &&
        posMs != null &&
        posMs > 0) {
      final lastSaved = _lastSavedProgressMs;
      if (lastSaved == null || (posMs - lastSaved).abs() >= 10000) {
        _lastSavedProgressMs = posMs;
        _localRepo.saveWatchProgress(dramaId, episodeNo, posMs);
      }
    }

    if (posMs != null) {
      final currentSecond = posMs ~/ 1000;
      if (currentSecond != _lastNotifiedSecond) {
        _lastNotifiedSecond = currentSecond;
        listener?.onPositionUpdate(this, posMs, _duration.inMilliseconds);
        // Near-expiry is checked by the service at most every 2 minutes;
        // skip the `unawaited(Future)` allocation on most ticks.
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        if (nowMs - _lastCookieRefreshCheckMs > 30000) {
          _lastCookieRefreshCheckMs = nowMs;
          unawaited(refreshCookiesIfNearExpiry());
        }
      }
    } else if (durMs != null && durMs > 0) {
      listener?.onPositionUpdate(this, _position.inMilliseconds, durMs);
    }
  }
}
