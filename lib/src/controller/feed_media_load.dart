import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../core/video_url_helpers.dart';
import '../model/models.dart';
import 'playback_engine.dart';

/// Shared media resolve / cold-apply / neighbor-preload steps.
///
/// Recommend cold bind and neighbor preload both did the same
/// `episodeDataFromPlay → fetchEpisodeData → isHttpUrl` dance; short-drama
/// uses a richer cache stack in [FeedEpisodeDataResolver]. This helper is the
/// Flutter-free common core both can call for "I already have a play payload".
class FeedMediaLoad {
  FeedMediaLoad._();

  /// Resolve playable HLS/HTTP data from [play], else fetch [episodeNo].
  ///
  /// Optional [peekCachedPlay] (Hive / CacheChain) runs before the network
  /// fetch when [play] cannot yield an HTTP URL — same layer order as
  /// [FeedEpisodeDataResolver].
  static Future<FeedMediaResolveResult> resolveHttpEpisodeData({
    required PlaybackEngine engine,
    required DramaPlayResponse? play,
    required int episodeNo,
    bool Function()? shouldContinue,
    Future<DramaPlayResponse?> Function(int episodeNo)? peekCachedPlay,
    String logTag = 'Feed',
    bool logRejectedUrl = false,
  }) async {
    PlaybackEpisodeData? data;
    if (play != null) {
      data = engine.episodeDataFromPlay(play);
      if (data != null && !VideoUrlHelpers.isHttpUrl(data.url)) {
        if (logRejectedUrl) {
          StoryLogger.e(
            'Rejected non-http play URL: ${data.url}',
            tag: logTag,
          );
        }
        return const FeedMediaResolveResult.rejectedUrl();
      }
    }
    if (data == null && peekCachedPlay != null) {
      if (shouldContinue != null && !shouldContinue()) {
        return const FeedMediaResolveResult.none();
      }
      final peeked = await peekCachedPlay(episodeNo);
      if (peeked != null) {
        data = engine.episodeDataFromPlay(peeked);
        if (data != null && !VideoUrlHelpers.isHttpUrl(data.url)) {
          data = null;
        }
      }
    }
    if (data == null) {
      if (shouldContinue != null && !shouldContinue()) {
        return const FeedMediaResolveResult.none();
      }
      data = await engine.fetchEpisodeData(episodeNo);
    }
    if (shouldContinue != null && !shouldContinue()) {
      return const FeedMediaResolveResult.none();
    }
    if (data == null) return const FeedMediaResolveResult.none();
    if (!VideoUrlHelpers.isHttpUrl(data.url)) {
      if (logRejectedUrl) {
        StoryLogger.e(
          'Rejected non-http play URL: ${data.url}',
          tag: logTag,
        );
      }
      return const FeedMediaResolveResult.rejectedUrl();
    }
    return FeedMediaResolveResult.ok(data);
  }

  /// Active-slot cold load with cookie pre-apply (recommend / any lazy feed).
  ///
  /// Optional [startAt] seeks before the first frame (e.g. session resume after
  /// hard teardown). Does not enable [PlaybackEngine.restoreWatchProgress].
  static Future<bool> applyColdPlayback({
    required PlaybackEngine engine,
    required PlaybackEpisodeData data,
    required int episodeNo,
    required bool isSwitch,
    required bool Function() shouldContinue,
    Duration? startAt,
    Duration viewReadyDelay = StoryDurations.playerViewReadyDelaySwitch,
  }) async {
    final cookieFut = engine.preApplyCookies(data.play, data.url);
    return engine.applyPlayback(
      data.play,
      data.url,
      data.headers,
      isSwitch: isSwitch,
      episodeNo: episodeNo,
      cookiePreApplied: cookieFut,
      shouldContinue: shouldContinue,
      viewReadyDelay: viewReadyDelay,
      startAt: startAt,
    );
  }

  /// Neighbor `preloadEpisode` + muted first-frame prime.
  ///
  /// [armLoadGuard] is invoked around native loadUrl / prime (iOS pauses the
  /// active AVPlayer during neighbor work).
  ///
  /// [shouldPrimeFrame] gates the muted play→pause decode. Skip while the
  /// active slot is playing — priming another decoder fights the foreground
  /// stream (visible hitch). Swipe covers then rely on JPEG / poster.
  static Future<NeighborPreloadOutcome> preloadNeighbor({
    required PlaybackEngine engine,
    required PlaybackEpisodeData data,
    required int episodeNo,
    required bool Function() shouldContinue,
    required void Function() armLoadGuard,
    bool Function()? shouldPrimeFrame,
  }) async {
    armLoadGuard();
    final ok = await engine.preloadEpisode(
      play: data.play,
      url: data.url,
      headers: data.headers,
      episodeNo: episodeNo,
    );
    if (!shouldContinue()) {
      return NeighborPreloadOutcome(loadOk: ok, frameReady: false);
    }
    if (!ok) {
      return const NeighborPreloadOutcome(loadOk: false, frameReady: false);
    }

    final allowPrime = shouldPrimeFrame?.call() ?? true;
    if (!allowPrime) {
      return NeighborPreloadOutcome(
        loadOk: true,
        frameReady: engine.hasPresentedFirstFrame,
      );
    }

    armLoadGuard();
    final primed = await engine.primePreloadFirstFrame(
      shouldContinue: shouldContinue,
    );
    if (!shouldContinue()) {
      return const NeighborPreloadOutcome(loadOk: true, frameReady: false);
    }
    final frameReady = primed || engine.hasPresentedFirstFrame;
    return NeighborPreloadOutcome(loadOk: true, frameReady: frameReady);
  }

  /// Best-effort mute + pause (platform view may already be gone).
  static Future<void> silenceBestEffort(PlaybackEngine? engine) async {
    if (engine == null) return;
    try {
      await engine.setVolume(0);
    } catch (e) {
      StoryLogger.d(
        'silenceBestEffort setVolume failed: $e',
        tag: 'Feed',
      );
    }
    try {
      await engine.pause();
    } catch (e) {
      StoryLogger.d(
        'silenceBestEffort pause failed: $e',
        tag: 'Feed',
      );
    }
  }
}

/// Result of [FeedMediaLoad.resolveHttpEpisodeData].
class FeedMediaResolveResult {
  const FeedMediaResolveResult._(this.data, {required this.rejectedUrl});

  const FeedMediaResolveResult.ok(PlaybackEpisodeData data)
    : this._(data, rejectedUrl: false);

  const FeedMediaResolveResult.rejectedUrl()
    : this._(null, rejectedUrl: true);

  const FeedMediaResolveResult.none() : this._(null, rejectedUrl: false);

  final PlaybackEpisodeData? data;
  final bool rejectedUrl;

  bool get hasData => data != null;
}

/// Outcome of [FeedMediaLoad.preloadNeighbor].
class NeighborPreloadOutcome {
  const NeighborPreloadOutcome({
    required this.loadOk,
    required this.frameReady,
  });

  final bool loadOk;
  final bool frameReady;
}
