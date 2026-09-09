import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_playback_policy.dart';
import 'package:story_app/src/controller/feed_role_ring.dart';

void main() {
  group('FeedRoleRing', () {
    test('rotateForward cycles active←next←prev', () {
      final ring = FeedRoleRing();
      expect((ring.active, ring.next, ring.prev), (0, 1, 2));
      ring.rotateForward();
      expect((ring.active, ring.next, ring.prev), (1, 2, 0));
      ring.rotateForward();
      expect((ring.active, ring.next, ring.prev), (2, 0, 1));
    });

    test('rotateBackward cycles active←prev←next', () {
      final ring = FeedRoleRing();
      ring.rotateBackward();
      expect((ring.active, ring.next, ring.prev), (2, 0, 1));
    });

    test('reset restores default roles', () {
      final ring = FeedRoleRing();
      ring.rotateForward();
      ring.rotateForward();
      ring.reset();
      expect((ring.active, ring.next, ring.prev), (0, 1, 2));
    });
  });

  group('FeedPlaybackPolicy.chooseRecommendActivate', () {
    test('prefers resume when active already holds the item', () {
      final decision = FeedPlaybackPolicy.chooseRecommendActivate(
        canResumeActive: true,
        nextMatchesTarget: true,
        nextDecodedReady: true,
        nextLoadInFlight: false,
        prevMatchesTarget: false,
        prevDecodedReady: false,
        prevLoadInFlight: false,
      );
      expect(decision.isResume, isTrue);
    });

    test('promotes next via shared AdjacentActivateChoice', () {
      final swap = FeedPlaybackPolicy.chooseRecommendActivate(
        canResumeActive: false,
        nextMatchesTarget: true,
        nextDecodedReady: true,
        nextLoadInFlight: false,
        prevMatchesTarget: false,
        prevDecodedReady: false,
        prevLoadInFlight: false,
      );
      expect(swap.isPromote, isTrue);
      expect(swap.forward, isTrue);
      expect(swap.adjacent, AdjacentActivateChoice.swap);

      final wait = FeedPlaybackPolicy.chooseRecommendActivate(
        canResumeActive: false,
        nextMatchesTarget: true,
        nextDecodedReady: false,
        nextLoadInFlight: true,
        prevMatchesTarget: false,
        prevDecodedReady: false,
        prevLoadInFlight: false,
      );
      expect(wait.adjacent, AdjacentActivateChoice.waitInFlight);
    });

    test('falls back to cold when no neighbor matches', () {
      final decision = FeedPlaybackPolicy.chooseRecommendActivate(
        canResumeActive: false,
        nextMatchesTarget: false,
        nextDecodedReady: false,
        nextLoadInFlight: false,
        prevMatchesTarget: false,
        prevDecodedReady: false,
        prevLoadInFlight: false,
      );
      expect(decision.isCold, isTrue);
    });
  });
}
