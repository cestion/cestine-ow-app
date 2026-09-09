import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_overlay_hold.dart';

void main() {
  group('FeedOverlayHold', () {
    test('nested holds keep advance blocked until outermost ends', () {
      final hold = FeedOverlayHold();
      var ended = 0;

      hold.begin();
      hold.begin();
      expect(hold.holdsAdvance, isTrue);

      hold.end(
        onEnded: ({required bool advanceIfCompleted}) => ended++,
      );
      expect(hold.holdsAdvance, isTrue);
      expect(ended, 0);

      hold.end(
        onEnded: ({required bool advanceIfCompleted}) => ended++,
      );
      expect(hold.holdsAdvance, isFalse);
      expect(ended, 1);
    });

    test('run invokes onBegan once and onEnded after action completes', () async {
      final hold = FeedOverlayHold();
      var began = 0;
      var ended = 0;

      final result = await hold.run(
        () async => 42,
        onBegan: () => began++,
        onEnded: ({required bool advanceIfCompleted}) => ended++,
      );

      expect(result, 42);
      expect(began, 1);
      expect(ended, 1);
      expect(hold.holdsAdvance, isFalse);
    });

    test('run still ends hold when action throws', () async {
      final hold = FeedOverlayHold();
      var ended = 0;

      await expectLater(
        hold.run(() async {
          throw StateError('sheet dismissed');
        }, onEnded: ({required bool advanceIfCompleted}) => ended++),
        throwsStateError,
      );

      expect(ended, 1);
      expect(hold.holdsAdvance, isFalse);
    });

    test('end is no-op when count is already zero', () {
      final hold = FeedOverlayHold();
      var ended = 0;

      hold.end(
        onEnded: ({required bool advanceIfCompleted}) => ended++,
      );

      expect(ended, 0);
      expect(hold.holdsAdvance, isFalse);
    });
  });
}
