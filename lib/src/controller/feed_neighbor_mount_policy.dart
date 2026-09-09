import 'dart:async';

import 'feed_scroll_activate_policy.dart';

/// Policy for when neighbor Platform Views may attach in a triple-slot feed.
///
/// Defaults keep the production-safe path (delay until first active frame).
/// Override with `--dart-define=FEED_EAGER_NEIGHBOR_MOUNT=true` on high-end
/// Wi‑Fi devices when measuring scroll jank trade-offs.
class FeedNeighborMountPolicy {
  FeedNeighborMountPolicy._();

  /// When true, mount B/C as soon as controllers exist (more memory / jank risk).
  static const bool eagerNeighborMount = bool.fromEnvironment(
    'FEED_EAGER_NEIGHBOR_MOUNT',
  );

  /// Early-activate progress threshold (shared with [FeedScrollActivatePolicy]).
  static double get earlyActivateProgress =>
      FeedScrollActivatePolicy.earlyActivateProgress;

  /// Whether the video-feed page may mount neighbor surfaces now.
  ///
  /// [warmEntry] is true when theater/detail already prefetched play metadata
  /// (handoff) — mount neighbors immediately to speed up the first swipe.
  static bool mayMountNeighbors({
    required bool activeHasFirstFrame,
    bool warmEntry = false,
  }) {
    if (eagerNeighborMount || warmEntry) return true;
    return activeHasFirstFrame;
  }

  /// Delay before mounting neighbor Platform Views after the active slot's
  /// first frame (shared by short-drama and recommend feeds).
  static Duration get neighborMountDelay => const Duration(
    milliseconds: eagerNeighborMount ? 0 : 50,
  );

  /// Schedules [onMount] once neighbors may attach. [stillNeeded] runs after
  /// the delay so callers can bail if the feed was torn down.
  static void scheduleNeighborMount({
    required bool activeHasFirstFrame,
    required bool Function() stillNeeded,
    required void Function() onMount,
    void Function()? onAborted,
    bool warmEntry = false,
  }) {
    if (!mayMountNeighbors(
      activeHasFirstFrame: activeHasFirstFrame,
      warmEntry: warmEntry,
    )) {
      onAborted?.call();
      return;
    }
    unawaited(() async {
      await Future<void>.delayed(neighborMountDelay);
      if (!stillNeeded()) {
        onAborted?.call();
        return;
      }
      onMount();
    }());
  }
}
