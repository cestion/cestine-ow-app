part of 'video_feed_controller.dart';

/// Episode data resolution for [VideoFeedController].
///
/// Owns the logic for fetching episode data from multiple layers:
/// in-memory cache → Hive cache → API/Engine. Kept as a same-library
/// extension to access private controller fields while isolating data
/// resolution in one file.
extension FeedEpisodeDataResolver on VideoFeedController {
  /// Resolve episode data from multiple layers.
  ///
  /// Returns `null` when data cannot be resolved or the controller is disposed.
  Future<PlaybackEpisodeData?> resolveEpisodeDataCommon(
    int episodeNo, {
    required bool forPreload,
  }) async {
    if (!_canContinue()) return null;
    // 1. In-memory episode states (prefetched / previously played).
    final cached = _episodeStates[episodeNo]?.play;
    if (cached != null) {
      final data = playbackDataFromPlay(cached, forPreload: forPreload);
      if (data != null) return data;
      // Cookies expired / invalid URL — evict and try next layer.
      _episodeStates.remove(episodeNo);
      _episodeStatesDirty = true;
      _episodeErrorsDirty = true;
    }

    // 2. Hive cache via CacheChain.
    final prefetched = _args.isShortVideo
        ? null
        : await _dramaRepo.peekPrefetchedEpisode(_dramaId, episodeNo);
    if (prefetched != null) {
      final data = playbackDataFromPlay(prefetched, forPreload: forPreload);
      if (data != null) {
        _episodeStates[episodeNo] = FeedEpisodeState(play: prefetched);
        _episodeStatesDirty = true;
        return data;
      }
      if (_alive) {
        _dramaRepo.clearPrefetchCache(_dramaId, episodeNo);
      }
    }

    // 3. Fresh fetch from API or Engine.
    // DNS preheat: active path via episodeDataFromPlay / fetchEpisodeData;
    // preload path via playbackDataFromPlay below.
    if (!forPreload) {
      return _engine.fetchEpisodeData(episodeNo);
    }

    if (!_canContinue()) return null;
    final result = await _loadEpisodePlay(episodeNo);
    if (result.isFailure) {
      StoryLogger.w(
        '预加载数据解析失败 episode=$episodeNo: ${result.errorOrNull?.userMessage}',
        tag: 'Feed',
      );
      return null;
    }
    final play = result.dataOrNull;
    if (play == null) return null;
    return playbackDataFromPlay(play, forPreload: true);
  }

  /// Build [PlaybackEpisodeData] from a play payload.
  ///
  /// Returns `null` when URL is missing or signed cookies are expired.
  /// Active path primes the engine; preload path only DNS-preheats so we do
  /// not overwrite the active engine's current play.
  PlaybackEpisodeData? playbackDataFromPlay(
    DramaPlayResponse play, {
    required bool forPreload,
  }) {
    final cookies = play.signedCookies;
    if (cookies != null && !cookies.isValid) return null;
    final url = play.effectivePlayUrl;
    if (url == null || url.isEmpty) return null;
    if (!forPreload) {
      _engine.episodeDataFromPlay(play);
    } else {
      _unawaitedLogged(StoryDnsPreheater.preheat(url), reason: 'dns-preheat');
    }
    return PlaybackEpisodeData(
      play: play,
      url: url,
      headers: CloudFrontCookieService.buildHeaders(play),
    );
  }
}
