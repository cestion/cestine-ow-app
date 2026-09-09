import 'dart:io';

import '../api/story_api_client.dart';
import '../core/cache_strategy.dart';
import '../core/iap_config.dart';
import '../core/json_helpers.dart';
import '../core/result.dart';
import '../data/repository/story_local_repository.dart';
import '../model/models.dart';

/// Remote IAP API repository (IAP v2.0.0 契约 §4–§7).
abstract class IapRepository {
  /// Server-provided product catalog
  /// (`/api/admin/v1/configs/keys/{ios|android}-products`，按平台区分),
  /// cached via [IapConfig.productsCacheTtl] (memory → Hive). On fetch failure
  /// the last cached list is returned as a fallback (no cache → the caller
  /// hides the purchase entry).
  Future<Result<List<IapProduct>>> getProducts();

  /// Create a pre-order before launching the store payment sheet
  /// (契约 §4). Sends `paymentChannel` + `productId`; price and granted
  /// amount are backend-configured.
  Future<Result<IapOrder>> createOrder(IapCreateOrderRequest request);

  /// Apple 验单 + 发放 USDC（契约 §6）。上传 StoreKit 2 原始 JWS。
  /// 幂等：重复提交返回当前订单结果。
  Future<Result<IapOrder>> verifyAppleOrder(IapAppleVerifyRequest request);

  /// Google 验单 + 发放 USDC（契约 §7）。上传购买 `purchaseToken`。
  /// 幂等：重复提交返回当前订单结果。
  Future<Result<IapOrder>> verifyGoogleOrder(IapGoogleVerifyRequest request);

  /// 查询订单状态（契约 §5）——只读本地订单，不触发发放重试。
  Future<Result<IapOrder>> getOrder(String orderId);

  Future<void> dispose();
}

class IapRepositoryImpl implements IapRepository {
  IapRepositoryImpl(this._api, [this._local]) {
    _productsMemory = MemoryCacheLayer<String, List<IapProduct>>(
      defaultTtl: IapConfig.productsCacheTtl,
    );
    final local = _local;
    final productsHive = local == null
        ? null
        : HiveCacheLayer<List<IapProduct>>(
            box: local.cacheBox,
            // HiveCacheLayer 默认 TTL 即 5min，与 IapConfig.productsCacheTtl 对齐。
            prefix: 'iap_products_',
            decoder: _decodeProducts,
            encoder: _encodeProducts,
          );
    _productsCache = CacheChain(
      fetcher: _fetchProducts,
      readLayers: [_productsMemory, ?productsHive],
      writeLayers: [_productsMemory, ?productsHive],
    );
  }

  final StoryApiClient _api;
  final StoryLocalRepository? _local;

  /// 商品清单路径按平台区分（config key：`ios-products` / `android-products`）。
  static String get _productsPath =>
      '/api/admin/v1/configs/keys/${Platform.isAndroid ? 'android' : 'ios'}-products';
  static const _ordersPath = '/api/userWallet/iap/orders';
  static const _appleVerifyPath = '/api/userWallet/iap/apple/verify';
  static const _googleVerifyPath = '/api/userWallet/iap/google/verify';

  late final MemoryCacheLayer<String, List<IapProduct>> _productsMemory;
  late final CacheChain<String, List<IapProduct>> _productsCache;

  static List<IapProduct> _decodeProducts(Object? data) {
    if (data is! List) return const [];
    return data
        .map((e) => IapProduct.fromJson(deepStringMap(e)))
        .toList(growable: false);
  }

  static Object _encodeProducts(List<IapProduct> value) =>
      value.map((e) => e.toJson()).toList();

  @override
  Future<Result<List<IapProduct>>> getProducts() async {
    final result = await _productsCache.get('products');
    if (result.isFailure) {
      // 拉取失败用上次缓存兜底。
      final cached = await _productsCache.getCachedOnly('products');
      if (cached != null) return Result.success(cached);
    }
    return result;
  }

  Future<Result<List<IapProduct>>> _fetchProducts(String key) {
    // 响应体键与路径同构：ios-products / android-products。
    final configKey = Platform.isAndroid ? 'android-products' : 'ios-products';
    return _api.safeGet(
      _productsPath,
      decoder: (d) {
        final map = normalizeJson(d);
        return parseList<IapProduct>(map[configKey], IapProduct.fromJson);
      },
    );
  }

  @override
  Future<Result<IapOrder>> createOrder(IapCreateOrderRequest request) {
    return _api.safePost(
      _ordersPath,
      body: request.toJson(),
      decoder: decodeWith(IapOrder.fromJson),
    );
  }

  @override
  Future<Result<IapOrder>> verifyAppleOrder(IapAppleVerifyRequest request) {
    return _api.safePost(
      _appleVerifyPath,
      body: request.toJson(),
      decoder: decodeWith(IapOrder.fromJson),
    );
  }

  @override
  Future<Result<IapOrder>> verifyGoogleOrder(IapGoogleVerifyRequest request) {
    return _api.safePost(
      _googleVerifyPath,
      body: request.toJson(),
      decoder: decodeWith(IapOrder.fromJson),
    );
  }

  @override
  Future<Result<IapOrder>> getOrder(String orderId) {
    return _api.safeGet(
      '$_ordersPath/$orderId',
      decoder: decodeWith(IapOrder.fromJson),
    );
  }

  @override
  Future<void> dispose() async {
    await _productsMemory.clear();
  }
}
