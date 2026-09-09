import '../repositories/drama_repository.dart';
import 'playback_episode_metrics_tracker.dart';

/// Per-episode play / complete metrics session shared by drama and recommend.
class FeedEpisodeMetricsSession {
  final PlaybackEpisodeMetricsTracker tracker = PlaybackEpisodeMetricsTracker();
  bool _sessionPlayReported = false;
  bool _sessionCompleteReported = false;

  void reset() {
    tracker.reset();
    _sessionPlayReported = false;
    _sessionCompleteReported = false;
  }

  void onPlayStart() => tracker.onPlayStart();

  void onPause() => tracker.onPause();

  PlaybackEpisodeMetricsSignals onTimeUpdate(
    int positionMs,
    int durationMs,
  ) {
    final durationSec = durationMs > 0 ? durationMs / 1000.0 : null;
    return tracker.onTimeUpdate(positionMs / 1000.0, durationSec);
  }

  void applySignals(
    PlaybackEpisodeMetricsSignals signals, {
    required void Function(EpisodeTrackEvent event) fireTrack,
  }) {
    if (signals.reportPlay && !_sessionPlayReported) {
      _sessionPlayReported = true;
      fireTrack(EpisodeTrackEvent.play);
    }
    if (signals.reportComplete && !_sessionCompleteReported) {
      _sessionCompleteReported = true;
      fireTrack(EpisodeTrackEvent.complete);
    }
  }
}

/// Dedupes watch-history play events within a single card session.
class FeedWatchHistoryGate {
  String? _reportedEpisodeId;
  int _reportedEpisodeNo = 0;

  bool shouldReportPlay({
    required int positionMs,
    String? episodeId,
    int? episodeNo,
  }) {
    if (positionMs < 1000) return false;
    if (episodeId != null && episodeId.isNotEmpty) {
      return _reportedEpisodeId != episodeId;
    }
    if (episodeNo != null && episodeNo > 0) {
      return _reportedEpisodeNo != episodeNo;
    }
    return false;
  }

  void markReported({String? episodeId, int? episodeNo}) {
    if (episodeId != null && episodeId.isNotEmpty) {
      _reportedEpisodeId = episodeId;
    }
    if (episodeNo != null && episodeNo > 0) {
      _reportedEpisodeNo = episodeNo;
    }
  }

  void reset() {
    _reportedEpisodeId = null;
    _reportedEpisodeNo = 0;
  }
}
