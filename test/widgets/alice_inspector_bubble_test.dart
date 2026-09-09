import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/core/story_env.dart';
import 'package:story_app/src/core/story_sdk_config.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/widgets/alice_inspector_bubble.dart';
import 'package:story_app/src/widgets/story_app_builder.dart';

class _LoggedOutAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(ready: true);
}

void main() {
  testWidgets('opens inspector when tapped', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [AliceInspectorBubble(onPressed: () => tapCount++)],
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.terminal_rounded));

    expect(tapCount, 1);
  });

  testWidgets('starts centered on the right edge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(children: [AliceInspectorBubble(onPressed: () {})]),
      ),
    );

    final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    final center = tester.getCenter(find.byIcon(Icons.terminal_rounded));

    expect(center.dx, closeTo(screenSize.width - 12 - 26, 0.01));
    expect(center.dy, closeTo(screenSize.height / 2, 0.01));
  });

  testWidgets('can be dragged without leaving screen bounds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(children: [AliceInspectorBubble(onPressed: () {})]),
      ),
    );

    final bubble = find.byIcon(Icons.terminal_rounded);
    final initialPosition = tester.getTopLeft(bubble);
    await tester.drag(bubble, const Offset(-10000, -10000));
    await tester.pump();
    final topLeftPosition = tester.getTopLeft(bubble);

    expect(topLeftPosition.dx, greaterThanOrEqualTo(12));
    expect(topLeftPosition.dy, greaterThanOrEqualTo(12));
    expect(topLeftPosition.dx, lessThan(initialPosition.dx));
    expect(topLeftPosition.dy, lessThan(initialPosition.dy));

    await tester.drag(bubble, const Offset(10000, 10000));
    await tester.pump();
    final bottomRightPosition = tester.getBottomRight(bubble);
    final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;

    expect(bottomRightPosition.dx, lessThanOrEqualTo(screenSize.width - 12));
    expect(bottomRightPosition.dy, lessThanOrEqualTo(screenSize.height - 12));
  });

  testWidgets('app builder shows inspector outside production', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storySdkConfigProvider.overrideWithValue(const StorySdkConfig()),
          authControllerProvider.overrideWith(_LoggedOutAuthController.new),
        ],
        child: MaterialApp(
          builder: (context, child) => StoryAppBuilder(child: child),
          home: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.byIcon(Icons.terminal_rounded), findsOneWidget);
  });

  testWidgets('app builder hides inspector in production', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storySdkConfigProvider.overrideWithValue(
            const StorySdkConfig(env: StoryEnv.production),
          ),
          authControllerProvider.overrideWith(_LoggedOutAuthController.new),
        ],
        child: MaterialApp(
          builder: (context, child) => StoryAppBuilder(child: child),
          home: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.byIcon(Icons.terminal_rounded), findsNothing);
  });
}
