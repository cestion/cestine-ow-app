import 'feed_scroll_activate_policy.dart';

/// Immutable scroll-tick analysis for triple-slot feeds.
///
/// Call [FeedScrollActivateSnapshot.analyze] from PageView scroll listeners
/// so recommend and short-drama feeds share duck / preload / early-activate
/// decisions without duplicating threshold math.
class FeedScrollActivateSnapshot {
  const FeedScrollActivateSnapshot({
    required this.page,
    required this.activeIndex,
    required this.shouldDuckOutgoing,
    required this.preferForward,
    required this.earlyActivateIndex,
  });

  final double page;
  final int activeIndex;
  final bool shouldDuckOutgoing;
  final bool? preferForward;
  final int? earlyActivateIndex;

  static FeedScrollActivateSnapshot analyze({
    required double page,
    required int activeIndex,
    required bool inSkipDuckWindow,
    int? neighborIndex,
    bool neighborReady = false,
    int? alreadyEarlyActivated,
    bool? goingForward,
    double? driftThreshold,
    double? earlyThreshold,
  }) {
    final preferForward = FeedScrollActivatePolicy.preferForwardScroll(
      page: page,
      activeIndex: activeIndex,
      driftThreshold: driftThreshold,
    );
    final towardForward = goingForward ?? preferForward ?? true;

    return FeedScrollActivateSnapshot(
      page: page,
      activeIndex: activeIndex,
      shouldDuckOutgoing: FeedScrollActivatePolicy.shouldDuckOutgoingAudio(
        page: page,
        activeIndex: activeIndex,
        inSkipDuckWindow: inSkipDuckWindow,
        driftThreshold: driftThreshold,
      ),
      preferForward: preferForward,
      earlyActivateIndex: FeedScrollActivatePolicy.earlyActivateNeighborIndex(
        page: page,
        activeIndex: activeIndex,
        neighborIndex: neighborIndex,
        neighborReady: neighborReady,
        alreadyEarlyActivated: alreadyEarlyActivated,
        goingForward: towardForward,
        threshold: earlyThreshold,
      ),
    );
  }
}
