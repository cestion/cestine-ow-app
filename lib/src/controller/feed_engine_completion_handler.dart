import 'playback_engine.dart';
import 'feed_playback_policy.dart';

/// Result of analyzing a native player completion callback.
enum FeedCompletionAction {
  /// Ignore — spurious complete before first frame / at t=0.
  ignore,

  /// Loop in place (auto-play off or overlay holds advance).
  loopInPlace,

  /// Advance to the next feed item / episode.
  advance,
}

/// Shared completion decision logic for triple-slot feeds.
class FeedEngineCompletionHandler {
  FeedEngineCompletionHandler._();

  static FeedCompletionAction decide({
    required PlaybackEngine engine,
    required DateTime? playbackArmedAt,
    required bool autoPlayEnabled,
    required bool overlayHoldsAdvance,
  }) {
    if (FeedPlaybackPolicy.shouldIgnoreSpuriousComplete(
      hasPresentedFirstFrame: engine.hasPresentedFirstFrame,
      position: engine.position,
      duration: engine.duration,
      playbackArmedAt: playbackArmedAt,
    )) {
      return FeedCompletionAction.ignore;
    }
    if (FeedPlaybackPolicy.shouldLoopCurrentItem(
      autoPlayEnabled: autoPlayEnabled,
      overlayHoldsAdvance: overlayHoldsAdvance,
    )) {
      return FeedCompletionAction.loopInPlace;
    }
    return FeedCompletionAction.advance;
  }

  static bool isBufferingTimeout(Object error) =>
      FeedPlaybackPolicy.isBufferingTimeoutError(error);
}
