import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/agent_v3_controller.dart';
import 'package:story_app/src/controller/agent_v3_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/view/widgets/agent_v3/agent_v3_refill_stamina_dialog.dart';

const _actor = MiningActor(
  actorNftId: '90001_10001',
  actorTokenId: 10001,
  level: 2,
  stamina: 120,
);

class _FakeAgentV3Controller extends AgentV3Controller {
  _FakeAgentV3Controller({required this.available, this.pendingResult});

  final double available;
  final Completer<Result<StaminaRefillResult>>? pendingResult;
  int refillCalls = 0;

  @override
  AgentV3State build() => AgentV3State(
    assets: UserAssets([
      WalletBalance(assetCode: 'STAMINA_PACK', availableBalance: available),
    ]),
    actorNftConfig: const InitActorNftConfig(
      staminaLimit: 168,
      levels: {'2': InitActorNftLevelConfig(staminaPackAmount: 2)},
    ),
  );

  @override
  Future<Result<StaminaRefillResult>> refillStaminaWithPack(MiningActor actor) {
    refillCalls++;
    return pendingResult?.future ??
        Future.value(
          Result.success(
            const StaminaRefillResult(
              actorNftId: '90001_10001',
              beforeStamina: 120,
              afterStamina: 168,
            ),
          ),
        );
  }
}

Widget _buildLauncher(_FakeAgentV3Controller controller) {
  return ProviderScope(
    overrides: [agentV3ControllerProvider.overrideWith(() => controller)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              // Keep the autoDispose controller alive between the launcher's
              // preflight read and the dialog route mounting.
              ref.watch(agentV3ControllerProvider);
              return Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showAgentV3RefillStaminaDialog(context, ref, _actor),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('matches the Figma single-actor refill dialog geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _FakeAgentV3Controller(available: 33);

    await tester.pumpWidget(_buildLauncher(controller));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('补满体力'), findsOneWidget);
    expect(find.text('Lv.2 消耗'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('可用 33'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('使用'), findsOneWidget);
    expect(
      tester.getSize(
        find.byKey(const ValueKey('agent-v3-refill-dialog-surface')),
      ),
      const Size(343, 255),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows loading and blocks repeated use while submitting', (
    tester,
  ) async {
    final pending = Completer<Result<StaminaRefillResult>>();
    final controller = _FakeAgentV3Controller(
      available: 33,
      pendingResult: pending,
    );

    await tester.pumpWidget(_buildLauncher(controller));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('agent-v3-refill-use')));
    await tester.pump();

    expect(controller.refillCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('agent-v3-refill-use')));
    await tester.pump();
    expect(controller.refillCalls, 1);

    pending.complete(
      Result.success(
        const StaminaRefillResult(
          actorNftId: '90001_10001',
          beforeStamina: 120,
          afterStamina: 168,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('agent-v3-refill-dialog')), findsNothing);
    expect(find.text('体力已补满'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('disables use when the stamina-pack balance is insufficient', (
    tester,
  ) async {
    final controller = _FakeAgentV3Controller(available: 1);

    await tester.pumpWidget(_buildLauncher(controller));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final availableTextFinder = find.byKey(
      const ValueKey('agent-v3-refill-available'),
    );
    final availableText = tester.widget<Text>(availableTextFinder);
    final availableTextSpan = availableText.textSpan! as TextSpan;
    final availableValueSpan = availableTextSpan.children!.last as TextSpan;
    final themeColor = Theme.of(
      tester.element(availableTextFinder),
    ).colorScheme.primary;

    expect(availableValueSpan.text, '1');
    expect(availableValueSpan.style?.color, themeColor);
    expect(availableValueSpan.style?.fontWeight, FontWeight.w700);

    await tester.tap(find.byKey(const ValueKey('agent-v3-refill-use')));
    await tester.pump();

    expect(controller.refillCalls, 0);
    expect(
      find.byKey(const ValueKey('agent-v3-refill-dialog')),
      findsOneWidget,
    );
  });
}
