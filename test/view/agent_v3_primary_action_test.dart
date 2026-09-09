import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/agent_v3_state.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/styles/story_colors.dart';
import 'package:story_app/src/view/widgets/agent_v3/agent_v3_primary_action.dart';

List<MiningActor> _actors(int count, {Set<int> depleted = const {}}) => [
  for (var index = 0; index < count; index++)
    MiningActor(
      actorNftId: 'actor-$index',
      stamina: depleted.contains(index) ? 0 : 1,
    ),
];

Widget _buildAction(
  AgentV3PrimaryActionKind action, {
  double claimableStory = 0,
  bool loading = false,
  VoidCallback? onPressed,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    home: Scaffold(
      body: Center(
        child: AgentV3PrimaryAction(
          action: action,
          claimableStory: claimableStory,
          loading: loading,
          onPressed: onPressed ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  group('AgentV3State primary action priority', () {
    test('claim overrides every other action', () {
      final state = AgentV3State(
        assets: UserAssets(const [
          WalletBalance(assetCode: 'STORY', availableBalance: 469),
        ]),
        deployedActors: _actors(5, depleted: const {0}),
      );

      expect(
        state.primaryActionKind(waitingActorCount: 3),
        AgentV3PrimaryActionKind.claim,
      );
    });

    test('vacancy performs when actors wait and signs when none wait', () {
      final state = AgentV3State(deployedActors: _actors(3));

      expect(
        state.primaryActionKind(waitingActorCount: 2),
        AgentV3PrimaryActionKind.performAll,
      );
      expect(
        state.primaryActionKind(waitingActorCount: 0),
        AgentV3PrimaryActionKind.signActor,
      );
    });

    test('full cast refills depleted actors, otherwise rests all', () {
      final depleted = AgentV3State(
        deployedActors: _actors(5, depleted: const {2}),
      );
      final healthy = AgentV3State(deployedActors: _actors(5));

      expect(
        depleted.primaryActionKind(waitingActorCount: 0),
        AgentV3PrimaryActionKind.refillAll,
      );
      expect(
        healthy.primaryActionKind(waitingActorCount: 0),
        AgentV3PrimaryActionKind.restAll,
      );
    });
  });

  testWidgets('renders all five localized labels', (tester) async {
    final cases = <AgentV3PrimaryActionKind, String>{
      AgentV3PrimaryActionKind.claim: '469 STORY · 领取',
      AgentV3PrimaryActionKind.performAll: '一键演出',
      AgentV3PrimaryActionKind.restAll: '一键休息',
      AgentV3PrimaryActionKind.refillAll: '一键补充',
      AgentV3PrimaryActionKind.signActor: '签约角色',
    };

    for (final entry in cases.entries) {
      await tester.pumpWidget(_buildAction(entry.key, claimableStory: 469));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('matches the Figma filled and outlined button geometry', (
    tester,
  ) async {
    await tester.pumpWidget(_buildAction(AgentV3PrimaryActionKind.performAll));
    await tester.pumpAndSettle();

    final filled = tester.widget<FilledButton>(find.byType(FilledButton));
    final filledSize = tester.getSize(find.byType(FilledButton));
    final filledStyle = filled.style!;
    expect(filledSize.height, 44);
    expect(filledStyle.backgroundColor!.resolve({}), StoryColors.darkButtonBg);
    expect(
      filledStyle.foregroundColor!.resolve({}),
      StoryColors.whiteToDarkOf(Brightness.light),
    );
    expect(filledStyle.textStyle!.resolve({})!.fontSize, 14);
    expect(filledStyle.textStyle!.resolve({})!.fontWeight, FontWeight.w700);

    await tester.pumpWidget(_buildAction(AgentV3PrimaryActionKind.restAll));
    await tester.pumpAndSettle();

    final outlined = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    final side = outlined.style!.side!.resolve({})!;
    expect(tester.getSize(find.byType(OutlinedButton)).height, 44);
    expect(side.width, 1.5);
    expect(side.color, StoryColors.dividerOf(Brightness.light));
  });

  testWidgets('claim loading state cannot be tapped again', (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      _buildAction(
        AgentV3PrimaryActionKind.claim,
        claimableStory: 469,
        loading: true,
        onPressed: () => tapCount++,
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('agent-v3-primary-loading')),
      findsOneWidget,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(tapCount, 0);
  });
}
