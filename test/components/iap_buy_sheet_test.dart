import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/components/iap/iap_buy_sheet.dart';
import 'package:story_app/src/controller/iap_controller.dart';
import 'package:story_app/src/controller/iap_state.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/services/iap_store_service.dart';

class _MockInAppPurchase extends Mock implements InAppPurchase {}

class _FakeIapStore extends IapStoreService {
  _FakeIapStore(this.response)
    : super(inAppPurchase: _MockInAppPurchase());

  final ProductDetailsResponse response;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => response;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();
}

class _FakeIapController extends IapController {
  @override
  IapState build() => const IapState(
    products: [
      IapProduct(productId: 'points_100', grantedAmount: 100, priceUsd: 0.99),
      IapProduct(productId: 'points_500', grantedAmount: 500, priceUsd: 3.99),
    ],
  );

  /// 模拟终态失败信号，供 view 接线测试。
  void emitFailure(String reason) =>
      state = state.copyWith(lastFailedReason: reason);
}

class _FakeWalletBalance extends WalletBalanceNotifier {
  @override
  WalletBalanceState build() => const WalletBalanceState(usdcBalance: 123.45);
}

void main() {
  final response = ProductDetailsResponse(
    productDetails: [
      ProductDetails(
        id: 'points_100',
        title: '100 Points',
        description: '',
        price: r'$1.99',
        rawPrice: 1.99,
        currencyCode: 'USD',
      ),
      ProductDetails(
        id: 'points_500',
        title: '500 Points',
        description: '',
        price: r'$7.99',
        rawPrice: 7.99,
        currencyCode: 'USD',
      ),
    ],
    notFoundIDs: const [],
  );

  Widget buildSheet({ProductDetailsResponse? storeResponse, bool dark = false}) {
    return ProviderScope(
      overrides: [
        iapControllerProvider.overrideWith(_FakeIapController.new),
        onChainWalletBalanceProvider.overrideWith(_FakeWalletBalance.new),
        iapStoreServiceProvider.overrideWith(
          (ref) => _FakeIapStore(storeResponse ?? response),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(brightness: Brightness.light),
        darkTheme: ThemeData(brightness: Brightness.dark),
        home: const Scaffold(body: IapBuySheet()),
      ),
    );
  }

  testWidgets('renders title, product rows with store prices and buttons', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet());
    await tester.pumpAndSettle();

    expect(find.text('购买点数'), findsOneWidget);
    expect(find.text('点数用于签约角色等 APP 内服务'), findsOneWidget);

    // 余额行：取 onChainWalletBalanceProvider.usdcBalance（123.45，double 展示）
    expect(find.text('余额'), findsOneWidget);
    expect(find.text('123.45'), findsOneWidget);

    // 商品行：发放点数（服务端）+ 商店价格
    expect(find.text('100 点数'), findsOneWidget);
    expect(find.text('500 点数'), findsOneWidget);
    expect(find.text(r'$1.99'), findsOneWidget);
    expect(find.text(r'$7.99'), findsOneWidget);

    expect(find.text('确认购买'), findsOneWidget);
  });

  testWidgets('selected product defaults to the first available one', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet());
    await tester.pumpAndSettle();

    // 默认选中第一项：选中行是品牌红 5% 背景 + 1px 品牌红描边
    final selectedMaterial = find.byWidgetPredicate(
      (w) =>
          w is Material &&
          w.type == MaterialType.canvas &&
          w.color == const Color(0xFFE50815).withValues(alpha: 0.05) &&
          (w.shape is RoundedRectangleBorder &&
              (w.shape as RoundedRectangleBorder).side.color ==
                  const Color(0xFFE50815)),
    );
    expect(selectedMaterial, findsOneWidget);
    expect(
      find.ancestor(of: find.text('100 点数'), matching: selectedMaterial),
      findsOneWidget,
    );
  });

  testWidgets('terminal failure opens the failure result dialog', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet());
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(IapBuySheet)),
    );
    (container.read(iapControllerProvider.notifier) as _FakeIapController)
        .emitFailure('验单失败');
    await tester.pumpAndSettle();

    expect(find.text('购买失败'), findsOneWidget);
    expect(find.text('验单失败'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
  });

  testWidgets('confirm button is disabled with gray style when nothing selected',
      (tester) async {
    // 商店返回空详情 → 无选中项
    await tester.pumpWidget(
      buildSheet(
        storeResponse: ProductDetailsResponse(
          productDetails: const [],
          notFoundIDs: const ['points_100', 'points_500'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final confirm = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '确认购买'),
    );
    expect(confirm.onPressed, isNull);
    expect(
      confirm.style?.backgroundColor?.resolve(const {}),
      const Color(0xFFC3C5CE),
    );
    expect(
      tester.widget<Text>(find.text('确认购买')).style?.color,
      const Color(0xFFFFFFFF),
    );
  });

  testWidgets('confirm button disabled color differs in dark mode',
      (tester) async {
    await tester.pumpWidget(
      buildSheet(
        dark: true,
        storeResponse: ProductDetailsResponse(
          productDetails: const [],
          notFoundIDs: const ['points_100', 'points_500'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Dark 模式色值（Figma 822-152104）
    final sheet = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).color == const Color(0xFF111113),
    );
    expect(sheet, findsOneWidget);
    expect(
      tester.widget<Text>(find.text('购买点数')).style?.color,
      const Color(0xFFEDEDF0), // darkContentText，与 Figma #EDEEF0 相差 1 单位
    );

    final confirm = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '确认购买'),
    );
    expect(confirm.onPressed, isNull);
    expect(
      confirm.style?.backgroundColor?.resolve(const {}),
      const Color(0xFF4F5359),
    );
    expect(
      tester.widget<Text>(find.text('确认购买')).style?.color,
      const Color(0xFF111113),
    );
  });
}
