import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_scroll_activate_snapshot.dart';
import 'package:story_app/src/view/widgets/video_feed/player_sheet_layout.dart';

void main() {
  group('FeedScrollActivateSnapshot', () {
    test('analyze aggregates duck and direction without neighbor', () {
      final centered = FeedScrollActivateSnapshot.analyze(
        page: 1.02,
        activeIndex: 1,
        inSkipDuckWindow: false,
      );
      expect(centered.shouldDuckOutgoing, isFalse);
      expect(centered.preferForward, isNull);
      expect(centered.earlyActivateIndex, isNull);

      final drifting = FeedScrollActivateSnapshot.analyze(
        page: 1.15,
        activeIndex: 1,
        inSkipDuckWindow: false,
      );
      // Direction bias still trips at the tiny drift threshold.
      expect(drifting.shouldDuckOutgoing, isFalse);
      expect(drifting.preferForward, isTrue);

      final committed = FeedScrollActivateSnapshot.analyze(
        page: 1.6,
        activeIndex: 1,
        inSkipDuckWindow: false,
      );
      expect(committed.shouldDuckOutgoing, isTrue);
      expect(committed.preferForward, isTrue);
    });

    test('early activate honors explicit goingForward for prev neighbor', () {
      final forward = FeedScrollActivateSnapshot.analyze(
        page: 0.7,
        activeIndex: 0,
        inSkipDuckWindow: false,
        neighborIndex: 1,
        neighborReady: true,
        goingForward: true,
      );
      expect(forward.earlyActivateIndex, 1);

      final backwardBlocked = FeedScrollActivateSnapshot.analyze(
        page: 0.7,
        activeIndex: 0,
        inSkipDuckWindow: false,
        neighborIndex: 1,
        neighborReady: true,
        goingForward: false,
      );
      expect(backwardBlocked.earlyActivateIndex, isNull);
    });
  });

  group('PlayerSheetLayoutCoordinator.slotTopOffset', () {
    test('follows fractional page within park threshold', () {
      expect(
        PlayerSheetLayoutCoordinator.slotTopOffset(
          page: 1.2,
          slotIndex: 2,
          pageHeight: 800,
        ),
        closeTo(640, 0.001),
      );
    });

    test('parks slots beyond threshold', () {
      expect(
        PlayerSheetLayoutCoordinator.slotTopOffset(
          page: 0,
          slotIndex: 3,
          pageHeight: 800,
        ),
        1600,
      );
      expect(
        PlayerSheetLayoutCoordinator.slotTopOffset(
          page: 5,
          slotIndex: 2,
          pageHeight: 800,
        ),
        -1600,
      );
    });
  });
}
