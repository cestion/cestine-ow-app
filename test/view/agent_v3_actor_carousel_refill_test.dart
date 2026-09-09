import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/agent_v3_controller.dart';
import 'package:story_app/src/controller/agent_v3_state.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/profile_controller.dart';
import 'package:story_app/src/controller/profile_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/view/agent_v3_page.dart';

const _actorNftId = '90001_10001';

class _LoggedOutAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(ready: true);
}

class _EmptyProfileController extends ProfileController {
  @override
  ProfileState build() => const ProfileState();
}

class _CarouselAgentV3Controller extends AgentV3Controller {
  _CarouselAgentV3Controller({required this.stamina});

  final int stamina;
  int restActorCalls = 0;

  @override
  AgentV3State build() => AgentV3State(
    assets: UserAssets(const [
      WalletBalance(assetCode: 'STAMINA_PACK', availableBalance: 33),
    ]),
    actorNftConfig: const InitActorNftConfig(
      staminaLimit: 168,
      levels: {'2': InitActorNftLevelConfig(staminaPackAmount: 2)},
    ),
    staminaLimit: 168,
    deployedActors: [
      MiningActor(
        actorNftId: _actorNftId,
        actorName: 'Actor',
        actorTokenId: 10001,
        level: 2,
        stamina: stamina,
      ),
    ],
  );

  @override
  Future<Result<void>> restActor(MiningActor actor) async {
    restActorCalls++;
    state = state.copyWith(deployedActors: const []);
    return Result.success(null);
  }
}

Widget _buildPage(_CarouselAgentV3Controller controller) {
  return ProviderScope(
    overrides: [
      agentV3ControllerProvider.overrideWith(() => controller),
      authControllerProvider.overrideWith(_LoggedOutAuthController.new),
      profileControllerProvider.overrideWith(_EmptyProfileController.new),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('zh'),
      home: Scaffold(body: AgentV3Page(standalone: true)),
    ),
  );
}

void main() {
  testWidgets('opens the refill dialog from a carousel actor card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildPage(_CarouselAgentV3Controller(stamina: 120)),
    );
    await tester.pumpAndSettle();

    final refillButton = find.byKey(
      const ValueKey('agent-v3-card-refill-$_actorNftId'),
    );
    final buttonOpacity = tester.widget<Opacity>(
      find.descendant(of: refillButton, matching: find.byType(Opacity)),
    );
    expect(buttonOpacity.opacity, 1);

    await tester.tap(refillButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('agent-v3-refill-dialog')),
      findsOneWidget,
    );
    expect(find.text('Lv.2 消耗'), findsOneWidget);
    expect(find.text('可用 33'), findsOneWidget);
  });

  testWidgets('does not open refill dialog when actor stamina is full', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildPage(_CarouselAgentV3Controller(stamina: 168)),
    );
    await tester.pumpAndSettle();

    final refillButton = find.byKey(
      const ValueKey('agent-v3-card-refill-$_actorNftId'),
    );
    final buttonOpacity = tester.widget<Opacity>(
      find.descendant(of: refillButton, matching: find.byType(Opacity)),
    );
    expect(buttonOpacity.opacity, 0.4);

    await tester.tap(refillButton);
    await tester.pump();

    expect(find.byKey(const ValueKey('agent-v3-refill-dialog')), findsNothing);
  });

  testWidgets('opens the shared rest dialog and rests the selected actor', (
    tester,
  ) async {
    final controller = _CarouselAgentV3Controller(stamina: 120);
    await tester.pumpWidget(_buildPage(controller));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('agent-v3-card-rest-$_actorNftId')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('agent-v3-rest-confirm-dialog')),
      findsOneWidget,
    );
    expect(find.text('确认休息'), findsOneWidget);
    expect(find.text('Actor · Lv2 · 配角'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('休息'), findsOneWidget);
    expect(
      tester.getSize(
        find.byKey(const ValueKey('agent-v3-rest-confirm-dialog')),
      ),
      const Size(343, 200),
    );
    expect(
      find.byKey(const ValueKey('agent-v2-rest-all-button')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('agent-v3-rest-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(controller.restActorCalls, 1);
    expect(
      find.byKey(const ValueKey('agent-v3-rest-confirm-dialog')),
      findsNothing,
    );
    expect(find.text('休息成功'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
