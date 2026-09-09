import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../core/story_logger.dart';

/// Thin wrapper over the `in_app_purchase` plugin for consumable IAP.
///
/// Encapsulates the plugin so repository/controller layers never import it
/// directly. Key production rules (IAP v2.0.0 契约):
/// - `buyConsumable`：Android `autoConsume: false`（服务端 consume），
///   iOS 上该参数被忽略（StoreKit 2 按 `true` 处理）；
/// - Apple 验单 `code==100000` 后才 `completePurchase`（finish）；
/// - Google **客户端不 consume/acknowledge**，由后端 consume。
class IapStoreService {
  IapStoreService({InAppPurchase? inAppPurchase})
    : _iap = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  static const _tag = 'IapStore';

  /// Whether the store is available (Google Play / App Store ready).
  Future<bool> isAvailable() => _iap.isAvailable();

  /// Query store product details. [identifiers] MUST come from the
  /// server-provided catalog, never hardcoded.
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) => _iap.queryProductDetails(identifiers);

  /// Real-time purchase updates (incl. app-start replay of unfinished
  /// transactions). Subscribe globally once at app start.
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  /// 发起消耗型购买。`autoConsume` 仅对 Android 生效（iOS StoreKit 2 忽略，
  /// 固定按 `true` 语义处理）；Android 上置 `false`，由服务端验单后 consume。
  /// [providerAccountId] 为后端 `providerAccountId`（== orderId），经
  /// [PurchaseParam.applicationUserName] 传递，插件在 iOS 上映射为 StoreKit 2
  /// `appAccountToken`、在 Android 上映射为 Billing `obfuscatedAccountId`。
  Future<bool> buyConsumable(
    ProductDetails productDetails, {
    required String providerAccountId,
  }) {
    return _iap.buyConsumable(
      purchaseParam: PurchaseParam(
        productDetails: productDetails,
        applicationUserName: providerAccountId,
      ),
      autoConsume: !Platform.isAndroid,
    );
  }

  /// Google 验单用购买 Token。插件在 Android 上将
  /// `verificationData.serverVerificationData` 设为 `purchaseToken`
  /// （== `billingClientPurchase.purchaseToken`），故直接取它即可。
  String? googlePurchaseToken(PurchaseDetails purchase) {
    final data = purchase.verificationData.serverVerificationData;
    return data.isEmpty ? null : data;
  }

  /// 是否为 Google Play 购买（用于决定是否可调用 consume/finish）。
  bool isGooglePurchase(PurchaseDetails purchase) =>
      purchase is GooglePlayPurchaseDetails;

  /// Settle the store transaction (iOS finish / Android consume). 仅 Apple
  /// 在服务端 `code==100000` 后调用；Google 不要调用（后端 consume）。
  ///
  /// 防护：Android 上非 [GooglePlayPurchaseDetails] 的对象（如
  /// ITEM_ALREADY_OWNED 等错误构造的空壳 PurchaseDetails）直接跳过，
  /// 插件内部强转会抛错。
  Future<void> completePurchase(PurchaseDetails purchase) {
    if (Platform.isAndroid && purchase is! GooglePlayPurchaseDetails) {
      return Future.value();
    }
    return _iap.completePurchase(purchase);
  }

  /// Android-only fallback: query unconsumed past purchases to reconcile
  /// missed `purchaseStream` events (design §10.1 #7). No-op elsewhere.
  Future<List<PurchaseDetails>> queryPastPurchases() async {
    if (!Platform.isAndroid) return const [];
    try {
      final addition = _iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (response.error != null) {
        StoryLogger.w(
          'queryPastPurchases error: ${response.error}',
          tag: _tag,
        );
      }
      return response.pastPurchases;
    } catch (e, st) {
      StoryLogger.w(
        'queryPastPurchases failed',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
      return const [];
    }
  }

  /// iOS-only: retry loading purchase verification data after an initial
  /// failure. No-op elsewhere.
  Future<void> refreshPurchaseVerificationData() async {
    if (!Platform.isIOS) return;
    try {
      final addition = _iap
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await addition.refreshPurchaseVerificationData();
    } catch (e, st) {
      StoryLogger.w(
        'refreshPurchaseVerificationData failed',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
    }
  }
}
