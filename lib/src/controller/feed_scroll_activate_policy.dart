import '../core/story_constants.dart';

/// Shared PageView scroll → activate / duck decisions for triple-slot feeds.
///
/// Used by recommend mid-swipe early-activate and the short-drama pager so the
/// commitment threshold and audio-duck drift stay one source of truth.
/// Keep this file free of Flutter so scroll-tick logic stays cheap to unit-test.
class FeedScrollActivatePolicy {
  FeedScrollActivatePolicy._();

  /// Progress into the next/prev page before early-activate fires.
  static double get earlyActivateProgress =>
      StoryConstants.feedEarlyActivateProgress;

  /// Pager offset from the playing card before outgoing audio is ducked /
  /// scroll-direction preload is biased.
  static double get pagerDriftThreshold =>
      StoryConstants.feedPagerDriftThreshold;

  /// Whether the pager has left the playing card enough to mute outgoing audio.
  ///
  /// Uses [earlyActivateProgress] (not [pagerDriftThreshold]): mid-swipe must
  /// keep the current video audible until the gesture is committed toward a
  /// neighbor. Ducking at the tiny drift threshold muted audio while the
  /// pager still showed the playing card.
  static bool shouldDuckOutgoingAudio({
    required double page,
    required int activeIndex,
    required bool inSkipDuckWindow,
    double? driftThreshold,
  }) {
    if (inSkipDuckWindow) return false;
    final drift = driftThreshold ?? earlyActivateProgress;
    return (page - activeIndex).abs() > drift;
  }

  /// Forward / backward intent from scroll offset; `null` when still centered.
  static bool? preferForwardScroll({
    required double page,
    required int activeIndex,
    double? driftThreshold,
  }) {
    final drift = driftThreshold ?? pagerDriftThreshold;
    if (page > activeIndex + drift) return true;
    if (page < activeIndex - drift) return false;
    return null;
  }

  /// True when [page] is committed toward [neighborIndex] past the threshold.
  static bool isCommittedTowardNeighbor({
    required double page,
    required int activeIndex,
    required int neighborIndex,
    double? threshold,
  }) {
    final t = threshold ?? earlyActivateProgress;
    if (neighborIndex > activeIndex) {
      return page >= activeIndex + t;
    }
    if (neighborIndex < activeIndex) {
      return page <= activeIndex - t;
    }
    return false;
  }

  /// Recommend early-activate: neighbor slot must already hold decoded media
  /// and the swipe must be on that neighbor's side of [activeIndex].
  static int? earlyActivateNeighborIndex({
    required double page,
    required int activeIndex,
    required int? neighborIndex,
    required bool neighborReady,
    required int? alreadyEarlyActivated,
    required bool goingForward,
    double? threshold,
  }) {
    if (!neighborReady || neighborIndex == null) return null;
    if (neighborIndex == alreadyEarlyActivated) return null;
    if (goingForward && neighborIndex <= activeIndex) return null;
    if (!goingForward && neighborIndex >= activeIndex) return null;
    if (!isCommittedTowardNeighbor(
      page: page,
      activeIndex: activeIndex,
      neighborIndex: neighborIndex,
      threshold: threshold,
    )) {
      return null;
    }
    return neighborIndex;
  }
}
