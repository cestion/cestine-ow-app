import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_neighbor_mount_policy.dart';
import 'package:story_app/src/controller/playback_engine.dart';

void main() {
  group('FeedResumeStyle', () {
    test('has distinct styles for video vs recommend', () {
      expect(FeedResumeStyle.values, contains(FeedResumeStyle.waitForFrame));
      expect(FeedResumeStyle.values, contains(FeedResumeStyle.playCommandOnly));
    });
  });

  group('FeedNeighborMountPolicy', () {
    test('default delays neighbors until first frame', () {
      expect(FeedNeighborMountPolicy.eagerNeighborMount, isFalse);
      expect(
        FeedNeighborMountPolicy.mayMountNeighbors(activeHasFirstFrame: false),
        isFalse,
      );
      expect(
        FeedNeighborMountPolicy.mayMountNeighbors(activeHasFirstFrame: true),
        isTrue,
      );
      expect(
        FeedNeighborMountPolicy.mayMountNeighbors(
          activeHasFirstFrame: false,
          warmEntry: true,
        ),
        isTrue,
      );
    });

    test('scheduleNeighborMount invokes onMount after delay', () async {
      var mounted = false;
      FeedNeighborMountPolicy.scheduleNeighborMount(
        activeHasFirstFrame: true,
        stillNeeded: () => true,
        onMount: () => mounted = true,
      );
      expect(mounted, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(mounted, isTrue);
    });

    test('scheduleNeighborMount calls onAborted when stillNeeded fails', () async {
      var aborted = false;
      FeedNeighborMountPolicy.scheduleNeighborMount(
        activeHasFirstFrame: true,
        stillNeeded: () => false,
        onMount: () => fail('should not mount'),
        onAborted: () => aborted = true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(aborted, isTrue);
    });
  });
}
