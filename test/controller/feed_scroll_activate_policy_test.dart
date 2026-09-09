import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_scroll_activate_policy.dart';
import 'package:story_app/src/core/story_constants.dart';

void main() {
  group('FeedScrollActivatePolicy', () {
    test('waitInFlightRaceBudget matches jump race (poster limbo cap)', () {
      expect(
        StoryDurations.waitInFlightRaceBudget,
        StoryDurations.jumpPreloadRaceBudget,
      );
    });

    test('shares thresholds with StoryConstants', () {
      expect(
        FeedScrollActivatePolicy.earlyActivateProgress,
        StoryConstants.feedEarlyActivateProgress,
      );
      expect(
        FeedScrollActivatePolicy.pagerDriftThreshold,
        StoryConstants.feedPagerDriftThreshold,
      );
    });

    test('ducks outgoing audio past early-activate commitment', () {
      expect(
        FeedScrollActivatePolicy.shouldDuckOutgoingAudio(
          page: 1.6,
          activeIndex: 1,
          inSkipDuckWindow: false,
        ),
        isTrue,
      );
      expect(
        FeedScrollActivatePolicy.shouldDuckOutgoingAudio(
          page: 1.6,
          activeIndex: 1,
          inSkipDuckWindow: true,
        ),
        isFalse,
      );
      // Mid-swipe past tiny drift but before commitment must stay audible.
      expect(
        FeedScrollActivatePolicy.shouldDuckOutgoingAudio(
          page: 1.1,
          activeIndex: 1,
          inSkipDuckWindow: false,
        ),
        isFalse,
      );
      expect(
        FeedScrollActivatePolicy.shouldDuckOutgoingAudio(
          page: 1.02,
          activeIndex: 1,
          inSkipDuckWindow: false,
        ),
        isFalse,
      );
    });

    test('preferForwardScroll reports direction intent', () {
      expect(
        FeedScrollActivatePolicy.preferForwardScroll(
          page: 2.2,
          activeIndex: 2,
        ),
        isTrue,
      );
      expect(
        FeedScrollActivatePolicy.preferForwardScroll(
          page: 1.8,
          activeIndex: 2,
        ),
        isFalse,
      );
      expect(
        FeedScrollActivatePolicy.preferForwardScroll(
          page: 2.01,
          activeIndex: 2,
        ),
        isNull,
      );
    });

    test('earlyActivateNeighborIndex requires ready + commitment', () {
      expect(
        FeedScrollActivatePolicy.earlyActivateNeighborIndex(
          page: 0.7,
          activeIndex: 0,
          neighborIndex: 1,
          neighborReady: true,
          alreadyEarlyActivated: null,
          goingForward: true,
        ),
        1,
      );
      expect(
        FeedScrollActivatePolicy.earlyActivateNeighborIndex(
          page: 0.7,
          activeIndex: 0,
          neighborIndex: 1,
          neighborReady: false,
          alreadyEarlyActivated: null,
          goingForward: true,
        ),
        isNull,
      );
      expect(
        FeedScrollActivatePolicy.earlyActivateNeighborIndex(
          page: 0.7,
          activeIndex: 0,
          neighborIndex: 1,
          neighborReady: true,
          alreadyEarlyActivated: 1,
          goingForward: true,
        ),
        isNull,
      );
      expect(
        FeedScrollActivatePolicy.earlyActivateNeighborIndex(
          page: 0.2,
          activeIndex: 0,
          neighborIndex: 1,
          neighborReady: true,
          alreadyEarlyActivated: null,
          goingForward: true,
        ),
        isNull,
      );
      expect(
        FeedScrollActivatePolicy.earlyActivateNeighborIndex(
          page: 0.7,
          activeIndex: 0,
          neighborIndex: 1,
          neighborReady: true,
          alreadyEarlyActivated: null,
          goingForward: false,
        ),
        isNull,
      );
    });
  });
}
