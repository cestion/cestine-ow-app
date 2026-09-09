import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/services/iap_store_service.dart';

class MockInAppPurchase extends Mock implements InAppPurchase {}

void main() {
  late MockInAppPurchase mock;
  late IapStoreService service;

  final product = ProductDetails(
    id: 'stamina_100',
    title: '100 Stamina',
    description: 'Consumable stamina pack',
    price: r'$0.99',
    rawPrice: 0.99,
    currencyCode: 'USD',
  );

  setUpAll(() {
    registerFallbackValue(
      PurchaseParam(
        productDetails: ProductDetails(
          id: '',
          title: '',
          description: '',
          price: '',
          rawPrice: 0,
          currencyCode: '',
        ),
      ),
    );
  });

  setUp(() {
    mock = MockInAppPurchase();
    service = IapStoreService(inAppPurchase: mock);
  });

  test('buyConsumable uses autoConsume:true on non-Android and carries providerAccountId',
      () async {
    when(
      () => mock.buyConsumable(
        purchaseParam: any(named: 'purchaseParam'),
        autoConsume: any(named: 'autoConsume'),
      ),
    ).thenAnswer((_) async => true);

    await service.buyConsumable(
      product,
      providerAccountId: '754ce1d4-6d77-46cd-b121-48bbf8494218',
    );

    final captured = verify(
      () => mock.buyConsumable(
        purchaseParam: captureAny(named: 'purchaseParam'),
        // 测试宿主为 macOS（非 Android）→ iOS 语义为 true。
        autoConsume: !Platform.isAndroid,
      ),
    ).captured.single as PurchaseParam;
    expect(captured.productDetails.id, 'stamina_100');
    // 插件：iOS 映射 appAccountToken / Android 映射 obfuscatedAccountId。
    expect(
      captured.applicationUserName,
      '754ce1d4-6d77-46cd-b121-48bbf8494218',
    );
  });

  test('googlePurchaseToken falls back to serverVerificationData', () {
    final purchase = PurchaseDetails(
      productID: 'com.story.usdc.10',
      purchaseID: 'purchase-id',
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: 'google-play-purchase-token',
        source: 'Google Play',
      ),
      transactionDate: '2026-08-15',
      status: PurchaseStatus.purchased,
    );

    expect(service.googlePurchaseToken(purchase), 'google-play-purchase-token');
  });

  test('queryPastPurchases is a no-op on non-Android platforms', () async {
    final result = await service.queryPastPurchases();
    expect(result, isEmpty);
  });
}
