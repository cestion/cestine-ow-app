import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/styles/story_colors.dart';
import 'package:story_app/src/view/widgets/agent_v3/agent_v3_perform_all_confirm_dialog.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('matches the perform-all confirmation screenshot', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        AgentV3PerformAllConfirmCard(
          deployCount: 2,
          onCancel: () {},
          onConfirm: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dialog = find.byKey(
      const ValueKey('agent-v3-perform-all-confirm-dialog'),
    );
    expect(tester.getSize(dialog), const Size(343, 220));
    expect(find.text('一键演出'), findsNWidgets(2));
    expect(find.text('将按片酬从高到低安排到空在演位'), findsOneWidget);
    expect(find.text('2个角色'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);

    final count = tester.widget<Container>(
      find.byKey(const ValueKey('agent-v3-perform-all-count')),
    );
    final countDecoration = count.decoration! as BoxDecoration;
    expect(count.constraints?.maxHeight, 50);
    expect(countDecoration.color, StoryColors.lightMuted);
    expect((countDecoration.borderRadius! as BorderRadius).topLeft.x, 12);

    final cancel = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('agent-v3-perform-all-cancel-button')),
    );
    final cancelSide = cancel.style!.side!.resolve({})!;
    expect(cancelSide.width, 1.5);
    expect(cancelSide.color, StoryColors.lightDivider);

    final confirm = tester.widget<FilledButton>(
      find.byKey(const ValueKey('agent-v3-perform-all-confirm-button')),
    );
    expect(
      confirm.style!.backgroundColor!.resolve({}),
      StoryColors.darkButtonBg,
    );
  });

  testWidgets('returns true only after the confirm button is tapped', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showAgentV3PerformAllConfirmDialog(
                context,
                deployCount: 2,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(result, isNull);

    await tester.tap(
      find.byKey(const ValueKey('agent-v3-perform-all-confirm-button')),
    );
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
