import '../model/models.dart';
import 'video_feed_state.dart';

/// Mutable working copy of UI-facing playback fields for [VideoFeedController].
///
/// Controller mutates this object in place, then calls [materialize] once from
/// `_notify()` instead of hand-listing every field into [VideoFeedState].
/// Bookkeeping that is not shown in Riverpod state (generation, auth recovery,
/// dispose, progress warm, tracking) stays on the controller.
class FeedPlaybackMirror {
  int currentEpisodeNo = 0;
  int? loadedEpisodeNo;
  FeedPlaybackStatus status = FeedPlaybackStatus.idle;
  bool isPlaying = false;
  bool isUserPaused = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  DramaPlayResponse? currentPlay;
  DramaDetail? dramaDetail;
  Object? error;
  int? autoAdvanceToEpisodeNo;
  bool playerSurfaceVisible = false;

  VideoFeedState materialize({
    required Set<int> playedEpisodeNos,
    required Set<int> prefetchedEpisodeNos,
    required Map<int, DramaPlayResponse> episodePlays,
    required Map<int, String> episodeCoverUrls,
    required Map<int, Object> episodeErrors,
    required Set<int> preloadedEpisodeNos,
    required Set<int> frameReadyEpisodeNos,
  }) {
    return VideoFeedState(
      currentEpisodeNo: currentEpisodeNo,
      loadedEpisodeNo: loadedEpisodeNo,
      status: status,
      isPlaying: isPlaying,
      isUserPaused: isUserPaused,
      duration: duration,
      currentPlay: currentPlay,
      dramaDetail: dramaDetail,
      error: error,
      autoAdvanceToEpisodeNo: autoAdvanceToEpisodeNo,
      playedEpisodeNos: playedEpisodeNos,
      prefetchedEpisodeNos: prefetchedEpisodeNos,
      episodePlays: episodePlays,
      episodeCoverUrls: episodeCoverUrls,
      episodeErrors: episodeErrors,
      playerSurfaceVisible: playerSurfaceVisible,
      preloadedEpisodeNos: preloadedEpisodeNos,
      frameReadyEpisodeNos: frameReadyEpisodeNos,
    );
  }
}
