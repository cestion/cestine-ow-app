import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_playback_policy.dart';
import 'package:story_app/src/controller/recommend_manual_retry_guard.dart';

void main() {
  group('RecommendManualRetryGuard', () {
    test('begin / clearIfCurrent tracks generation', () {
      final guard = RecommendManualRetryGuard();
      final gen = guard.begin(index: 2, workId: 'w');
      expect(guard.inFlight, isTrue);
      expect(guard.matches(currentIndex: 2, bindWorkId: 'w'), isTrue);

      guard.clearIfCurrent(gen - 1);
      expect(guard.inFlight, isTrue);

      guard.clearIfCurrent(gen);
      expect(guard.inFlight, isFalse);
    });

    test('onFeedIdentity invalidates after swipe away', () {
      final guard = RecommendManualRetryGuard();
      guard.begin(index: 1, workId: 'a');
      expect(
        guard.onFeedIdentity(currentIndex: 1, bindWorkId: 'a'),
        isTrue,
      );
      expect(
        guard.onFeedIdentity(currentIndex: 2, bindWorkId: 'b'),
        isFalse,
      );
      expect(guard.inFlight, isFalse);
    });
  });

  group('FeedPlaybackPolicy.shouldEnqueueBindOnIdentity', () {
    test('suppresses during auth recovery and manual-retry loading', () {
      expect(
        FeedPlaybackPolicy.shouldEnqueueBindOnIdentity(
          hasCurrentPlay: true,
          isPlayLoading: false,
          authRecoveryInFlight: true,
          manualRetryOwnsLoading: false,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldEnqueueBindOnIdentity(
          hasCurrentPlay: true,
          isPlayLoading: true,
          authRecoveryInFlight: false,
          manualRetryOwnsLoading: true,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldEnqueueBindOnIdentity(
          hasCurrentPlay: true,
          isPlayLoading: false,
          authRecoveryInFlight: false,
          manualRetryOwnsLoading: true,
        ),
        isTrue,
      );
    });
  });
}
