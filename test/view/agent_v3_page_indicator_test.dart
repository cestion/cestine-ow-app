import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/styles/story_colors.dart';
import 'package:story_app/src/view/widgets/agent_v3/agent_v3_page_indicator.dart';

void main() {
  testWidgets('distinguishes selected, occupied, and empty slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AgentV3PageIndicator(
            occupiedItemCount: 2,
          ),
        ),
      ),
    );

    BoxDecoration decorationAt(int index) {
      final container = tester.widget<Container>(
        find.byKey(ValueKey('agent-v3-page-indicator-$index')),
      );
      return container.decoration! as BoxDecoration;
    }

    final primary = StoryColors.foregroundOf(Brightness.light);
    final occupied = decorationAt(0);
    final selected = decorationAt(1);
    final empty = decorationAt(2);

    expect(selected.color, primary);
    expect(selected.border, isNull);
    expect(occupied.color, primary.withValues(alpha: 0.3));
    expect(occupied.border, isNull);
    expect(empty.color, Colors.transparent);
    expect((empty.border! as Border).top.color, primary.withValues(alpha: 0.3));
  });

  testWidgets('selected state takes precedence for an empty slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AgentV3PageIndicator(
            occupiedItemCount: 1,
            selectedIndex: 3,
          ),
        ),
      ),
    );

    final selected = tester.widget<Container>(
      find.byKey(const ValueKey('agent-v3-page-indicator-3')),
    );
    final decoration = selected.decoration! as BoxDecoration;

    expect(decoration.color, StoryColors.foregroundOf(Brightness.light));
    expect(decoration.border, isNull);
  });
}
