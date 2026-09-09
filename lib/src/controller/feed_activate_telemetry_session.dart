import 'feed_playback_telemetry.dart';

/// Per-activate stopwatch session for `feed_activate` / `feed_first_frame`.
///
/// Shared by short-drama and recommend controllers so timing wiring stays
/// one source of truth.
class FeedActivateTelemetrySession {
  FeedActivateTelemetrySession({required this.feed});

  final String feed;

  Stopwatch? _stopwatch;
  String? _playbackId;
  bool _activateReported = false;
  bool _firstFrameReported = false;

  void begin(String playbackId) {
    _stopwatch = Stopwatch()..start();
    _playbackId = playbackId;
    _activateReported = false;
    _firstFrameReported = false;
  }

  void reportActivate({required bool fromNeighbor}) {
    if (_activateReported) return;
    final sw = _stopwatch;
    final id = _playbackId;
    if (sw == null || id == null || id.isEmpty) return;
    _activateReported = true;
    FeedPlaybackTelemetry.activate(
      feed: feed,
      playbackId: id,
      elapsed: sw.elapsed,
      fromNeighbor: fromNeighbor,
    );
  }

  void reportFirstFrame({String? fallbackPlaybackId}) {
    if (_firstFrameReported) return;
    final sw = _stopwatch;
    final id = _playbackId ?? fallbackPlaybackId;
    if (sw == null || id == null || id.isEmpty) return;
    _firstFrameReported = true;
    FeedPlaybackTelemetry.firstFrame(
      feed: feed,
      playbackId: id,
      elapsed: sw.elapsed,
    );
  }
}
