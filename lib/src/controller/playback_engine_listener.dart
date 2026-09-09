import 'package:better_native_video_player/better_native_video_player.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import 'playback_engine.dart';

/// Unified listener interface for [PlaybackEngine] lifecycle events.
///
/// Replaces the 10 individual callback fields that were previously set
/// ad-hoc by consumers. Each method has a default no-op implementation
/// so consumers only override what they need.
///
/// The engine passes itself as the first parameter to every callback,
/// allowing listeners to identify which engine triggered the event
/// without capturing the engine reference in a closure.
abstract class PlaybackEngineListener {
  void onEpisodeResult(
    PlaybackEngine engine,
    Result<DramaPlayResponse> result,
  ) {}
  void onActivityEvent(PlaybackEngine engine, PlayerActivityEvent event) {}
  void onDurationChanged(PlaybackEngine engine, Duration duration) {}
  void onPlayingChanged(PlaybackEngine engine, bool isPlaying) {}
  void onBufferingChanged(PlaybackEngine engine, bool isBuffering) {}
  void onPositionUpdate(
    PlaybackEngine engine,
    int positionMs,
    int durationMs,
  ) {}
  void onCompleted(PlaybackEngine engine) {}
  void onError(PlaybackEngine engine, Object error) {}
  void onPlaybackFailure(
    PlaybackEngine engine,
    Object error, {
    required bool isSwitch,
  }) {}
  void onFrameRendered(
    PlaybackEngine engine, {
    required bool isFirstFrame,
    required DateTime renderedAt,
  }) {}
}

/// Listener for neighbor/preload engines that only needs logging and frame rendering.
///
/// Neighbor engines should not trigger state updates on the active playback.
/// This listener logs errors and handles frame rendering for first-frame capture.
class NeighborEngineListener extends PlaybackEngineListener {
  NeighborEngineListener({required this.tag, this.onFrameRenderedCallback});

  final String tag;
  final void Function(
    PlaybackEngine engine, {
    required bool isFirstFrame,
    required DateTime renderedAt,
  })?
  onFrameRenderedCallback;

  @override
  void onError(PlaybackEngine engine, Object error) {
    StoryLogger.w('$tag error', error: error, tag: 'Rec');
  }

  @override
  void onFrameRendered(
    PlaybackEngine engine, {
    required bool isFirstFrame,
    required DateTime renderedAt,
  }) {
    onFrameRenderedCallback?.call(
      engine,
      isFirstFrame: isFirstFrame,
      renderedAt: renderedAt,
    );
  }
}
