import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_page_scroll_handler.dart';

void main() {
  group('FeedPageScrollEarlyActivate', () {
    test('dramaCommittedToTarget requires painted preload', () {
      expect(
        FeedPageScrollEarlyActivate.dramaCommittedToTarget(
          page: 1.3,
          activeIndex: 0,
          targetIndex: 1,
          targetEpisode: 2,
          frameReadyEpisodeNos: const {2},
          settledEpisodeNos: const {2},
          alreadyActivatedIndex: null,
        ),
        isTrue,
      );
      expect(
        FeedPageScrollEarlyActivate.dramaCommittedToTarget(
          page: 1.3,
          activeIndex: 0,
          targetIndex: 1,
          targetEpisode: 2,
          frameReadyEpisodeNos: const {},
          settledEpisodeNos: const {},
          alreadyActivatedIndex: null,
        ),
        isFalse,
      );
    });

    test('recommendNeighborIndex honors goingForward', () {
      expect(
        FeedPageScrollEarlyActivate.recommendNeighborIndex(
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
        FeedPageScrollEarlyActivate.recommendNeighborIndex(
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

  group('FeedScrollSettleDebouncer', () {
    test('debounces fractional scroll then fires once', () async {
      final settled = <int>[];
      final debouncer = FeedScrollSettleDebouncer(
        debounce: const Duration(milliseconds: 20),
        isMounted: () => true,
        onSettle: settled.add,
      );
      debouncer.schedule(2, activatedIndex: 0);
      debouncer.schedule(2, activatedIndex: 0);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(settled, [2]);
      debouncer.dispose();
    });
  });
}
