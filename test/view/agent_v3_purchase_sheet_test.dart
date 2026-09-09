import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/agent_v3_controller.dart';
import 'package:story_app/src/controller/agent_v3_state.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/core/card_purchase_currency.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/card_purchase_model.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/view/widgets/agent_v3/agent_v3_purchase_sheet.dart';
import 'package:story_app/src/widgets/story_button.dart';

class _LoggedInAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
    ready: true,
    isLoggedIn: true,
    token: 'test-token',
    solanaAddress: 'test-wallet',
  );

  @override
  Future<void> get ready async {}

  @override
  Future<PrivySessionGate> ensurePrivySessionReady() async =>
      PrivySessionGate.ready;
}

class _PurchaseController extends AgentV3Controller {
  @override
  AgentV3State build() => const AgentV3State(
    purchaseEnabled: true,
    energyPackUnitPrice: '10',
    trainingManualUnitPrice: '10',
  );
}

class _WalletBalanceController extends WalletBalanceNotifier {
  @override
  WalletBalanceState build() => const WalletBalanceState(usdcBalance: 10);

  @override
  Future<void> refreshSilently() async {}
}

class _PurchaseHarness extends ConsumerWidget {
  const _PurchaseHarness({required this.type});

  final CardPurchaseType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => showAgentV3PurchaseSheet(context, ref, type),
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  const currencyMode = CardPurchaseCurrencyDisplay.mode;
  final currencyLabel = currencyMode.label(pointsLabel: '点数');
  const currencyIconSuffix = currencyMode == CardPurchaseCurrencyMode.points
      ? 'points'
      : 'usdc';

  testWidgets('training manual sheet matches the design and edits quantity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_LoggedInAuthController.new),
          agentV3ControllerProvider.overrideWith(_PurchaseController.new),
          onChainWalletBalanceProvider.overrideWith(
            _WalletBalanceController.new,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _PurchaseHarness(type: CardPurchaseType.trainingManual),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('训练手册'), findsOneWidget);
    expect(find.text('角色升级材料，升级时按角色等级消耗。'), findsOneWidget);
    expect(find.text('合计 10 $currencyLabel'), findsOneWidget);
    expect(find.text('余额 10 $currencyLabel'), findsOneWidget);
    expect(find.text('购买'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('agent-v3-training-manual-$currencyIconSuffix-icon'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('agent-v3-training-manual-product')),
      ),
      const Size(88, 88),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('agent-v3-training-manual-stepper')),
      ),
      const Size(160, 44),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('agent-v3-training-manual-buy')),
      ),
      const Size(343, 44),
    );

    final quantity = find.byKey(
      const ValueKey('agent-v3-training-manual-quantity'),
    );
    await tester.enterText(quantity, '9');
    await tester.pump();
    expect(find.text('合计 90 $currencyLabel'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(tester.widget<TextField>(quantity).controller!.text, '10');
    expect(find.text('合计 100 $currencyLabel'), findsOneWidget);

    await tester.enterText(quantity, '');
    await tester.pump();
    final buyButton = tester.widget<StoryButton>(
      find.byKey(const ValueKey('agent-v3-training-manual-buy')),
    );
    expect(buyButton.onPressed, isNull);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(tester.widget<TextField>(quantity).controller!.text, '1');
    expect(find.text('合计 10 $currencyLabel'), findsOneWidget);

    final hold = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.add_rounded)),
    );
    await tester.pump(const Duration(milliseconds: 850));
    final repeatedQuantity = int.parse(
      tester.widget<TextField>(quantity).controller!.text,
    );
    expect(repeatedQuantity, greaterThan(1));

    await hold.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.widget<TextField>(quantity).controller!.text,
      '$repeatedQuantity',
    );
  });

  testWidgets('energy pack sheet matches the Figma design', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_LoggedInAuthController.new),
          agentV3ControllerProvider.overrideWith(_PurchaseController.new),
          onChainWalletBalanceProvider.overrideWith(
            _WalletBalanceController.new,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _PurchaseHarness(type: CardPurchaseType.energyPack),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('体力补给包'), findsOneWidget);
    expect(find.text('补满角色体力，按角色等级消耗。'), findsOneWidget);
    expect(find.text('合计 10 $currencyLabel'), findsOneWidget);
    expect(find.text('余额 10 $currencyLabel'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('agent-v3-energy-pack-$currencyIconSuffix-icon'),
      ),
      findsOneWidget,
    );

    final product = find.byKey(const ValueKey('agent-v3-energy-pack-product'));
    expect(tester.getSize(product), const Size(88, 88));
    final productImage = tester.widget<Image>(
      find.descendant(of: product, matching: find.byType(Image)),
    );
    expect(
      (productImage.image as AssetImage).assetName,
      'assets/game_v3/agent_token_story.png',
    );
    expect(productImage.width, 68);
    expect(productImage.height, 56);
    expect(
      tester.getSize(
        find.byKey(const ValueKey('agent-v3-energy-pack-stepper')),
      ),
      const Size(160, 44),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('agent-v3-energy-pack-buy'))),
      const Size(343, 44),
    );

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.text('合计 20 $currencyLabel'), findsOneWidget);
  });
}
