import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/view/widgets/video_feed/player_pinch_clear_screen.dart';

void main() {
  testWidgets('pinch out enters clear-screen', (tester) async {
    var hidden = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PlayerPinchClearScreen(
                chromeHidden: hidden,
                onEnter: () => setState(() => hidden = true),
                onExit: () => setState(() => hidden = false),
                child: const SizedBox.expand(
                  child: ColoredBox(color: Colors.black),
                ),
              );
            },
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(PlayerPinchClearScreen));
    final g1 = await tester.startGesture(center + const Offset(-40, 0));
    final g2 = await tester.startGesture(center + const Offset(40, 0));
    await g1.moveBy(const Offset(-30, 0));
    await g2.moveBy(const Offset(30, 0));
    await tester.pump();

    expect(hidden, isTrue);

    await g1.up();
    await g2.up();
  });

  testWidgets('pinch in exits clear-screen', (tester) async {
    var hidden = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PlayerPinchClearScreen(
                chromeHidden: hidden,
                onEnter: () => setState(() => hidden = true),
                onExit: () => setState(() => hidden = false),
                child: const SizedBox.expand(
                  child: ColoredBox(color: Colors.black),
                ),
              );
            },
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(PlayerPinchClearScreen));
    final g1 = await tester.startGesture(center + const Offset(-80, 0));
    final g2 = await tester.startGesture(center + const Offset(80, 0));
    await g1.moveBy(const Offset(40, 0));
    await g2.moveBy(const Offset(-40, 0));
    await tester.pump();

    expect(hidden, isFalse);

    await g1.up();
    await g2.up();
  });

  testWidgets('one-finger drag does not toggle chrome', (tester) async {
    var hidden = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerPinchClearScreen(
            chromeHidden: hidden,
            onEnter: () => hidden = true,
            onExit: () => hidden = false,
            child: const SizedBox.expand(
              child: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byType(PlayerPinchClearScreen),
      const Offset(0, -120),
    );
    await tester.pump();
    expect(hidden, isFalse);
  });
}
