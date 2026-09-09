import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_playback_policy.dart';
import 'package:story_app/src/core/story_constants.dart';

/// Policy-level guards for the three-slot feed activate pipeline.
///
/// Full Widget/Notifier integration needs platform views; these tests lock the
/// invariants that prevent the worst regressions (adjacent cold wipe, jump
/// race budget, early-activate threshold).
void main() {
  group('feed activate policy', () {
    test('early activate threshold matches StoryConstants', () {
      expect(StoryConstants.feedEarlyActivateProgress, 0.58);
      expect(
        StoryConstants.feedEarlyActivateProgress,
        greaterThanOrEqualTo(0.5),
      );
    });

    test('jump preload race budget is short vs full player timeout', () {
      expect(
        StoryDurations.jumpPreloadRaceBudget,
        lessThan(StoryConstants.playerOperationTimeout),
      );
      expect(
        StoryDurations.jumpPreloadRaceBudget.inMilliseconds,
        inInclusiveRange(300, 2000),
      );
    });

    test('adjacent settle waits after first frame before neighbor loadUrl', () {
      expect(
        StoryDurations.adjacentPreloadAfterPlaying.inMilliseconds,
        inInclusiveRange(150, 400),
      );
      expect(
        StoryDurations.adjacentPreloadFramePoll.inMilliseconds,
        inInclusiveRange(100, 400),
      );
      expect(
        StoryDurations.adjacentPreloadAfterPlaying,
        lessThan(const Duration(seconds: 1)),
      );
    });

    test('adjacent episode distance helper', () {
      bool isAdjacent(int? loaded, int target) =>
          loaded != null && (target - loaded).abs() == 1;

      expect(isAdjacent(5, 6), isTrue);
      expect(isAdjacent(5, 4), isTrue);
      expect(isAdjacent(5, 7), isFalse);
      expect(isAdjacent(null, 1), isFalse);
    });

    test('migrate seek threshold skips near-zero playheads', () {
      expect(StoryConstants.migrateSeekThresholdMs, 2000);
    });

    test('playback height cap is 1080 so preload matches migrate', () {
      expect(StoryConstants.maxPlaybackVideoHeight, 1080);
      expect(StoryConstants.cellularSoftPeakVideoHeight, 480);
    });

    test('picker activate after dispose is superseded', () {
      expect(
        FeedPlaybackPolicy.isActivateSuperseded(
          disposed: true,
          episodeNo: 2,
          queuedEpisode: null,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isActivateSuperseded(
          disposed: false,
          episodeNo: 2,
          queuedEpisode: null,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.isActivateSuperseded(
          disposed: false,
          episodeNo: 2,
          queuedEpisode: 3,
        ),
        isTrue,
      );
    });
  });
}
