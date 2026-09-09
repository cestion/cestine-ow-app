/// IAP domain configuration, constants and pure types shared by all client
/// layers. Kept free of any `in_app_purchase` / view / repository imports so
/// the core layer stays dependency-free and testable.
library;

/// Static IAP configuration and retry policies.
///
/// All tunables live here so engineers adjust behavior without touching
/// repository / controller logic.
///
/// The product catalog is **server-driven** (Apple IAP: the client fetches
/// `GET /api/admin/v1/configs/keys/ios_products` and never hardcodes SKUs).
class IapConfig {
  IapConfig._();

  /// Hive box holding the client pending-delivery queue.
  ///
  /// Deliberately separate from `story_local_cache` so it survives logout
  /// (the queue is bound to `userId`, never cleared on auth reset).
  static const String queueBoxName = 'iap_pending_queue';

  /// Hive key storing the last logged-in `userId` on this device, used to
  /// best-effort attribute orphaned store transactions.
  static const String lastLoggedInUserIdKey = 'iap_last_user_id';

  /// TTL for the server-provided product catalog cache.
  /// On fetch failure the client falls back to the last cached list; with no
  /// cache the purchase entry is hidden.
  static const Duration productsCacheTtl = Duration(minutes: 5);

  /// Retention of cancelled entries (kept briefly for debugging).
  static const Duration cancelledRetention = Duration(days: 7);

  // ── Verify retry policy (Apple IAP §8: 110102/110013/110023) ─────────
  /// Maximum automatic retry attempts before leaving the entry in the queue
  /// for the next app-start reconcile.
  static const int verifyMaxAttempts = 5;

  /// failed 记录重放上限：冷启动/重登重放同一笔失败交易最多再验这么多次，
  /// 超过后跳过（防无限重验刷接口）。
  static const int failedReplayMaxAttempts = 3;

  /// pendingInit 中断记录的清理阈值：createOrder 未返回即中断（杀 App），
  /// 购买从未发起，超时即视为垃圾数据清理。
  static const Duration pendingInitStale = Duration(hours: 1);

  /// pendingPurchase 中断记录的清理阈值：订单已建但商店购买从未拉起
  /// （或事件丢失），超时即视为垃圾数据清理。支付页交互通常一两分钟，
  /// 5min 足够覆盖；若支付实际已成，交易重放/未完成交易重扫会重新入队。
  static const Duration pendingPurchaseStale = Duration(minutes: 5);

  /// Initial delay before the first retry.
  static const Duration verifyRetryInitialDelay = Duration(seconds: 30);

  /// Exponential multiplier per retry (30s → 60s → 120s → …).
  static const double verifyRetryBackoffFactor = 2.0;
}

/// Known Apple IAP business error codes returned by the backend
/// (Apple IAP contract §8).
///
/// Backend envelope uses integer codes ([ApiError.business]).
class IapErrorCode {
  IapErrorCode._();

  // ── 客户端本地错误码（非服务端返回） ─────────────────────────────
  /// 同 SKU 在途订单未完结（客户端在途拦截，非服务端业务码）。
  static const int orderInFlight = 70001;

  // ── 服务端业务码（Apple IAP 契约 §8） ───────────────────────────
  static const int success = 100000;
  static const int authInvalid = 100001;
  static const int parameterError = 100400;
  static const int unauthorized = 100401;
  static const int serverError = 100500;
  static const int systemConfigMissing = 100503;
  static const int assetNotSupported = 110003;
  static const int withdrawAddressInvalid = 110006;
  static const int idempotentDuplicate = 110007;

  /// 订单不存在或不属于当前用户（服务端不泄露归属）。
  static const int orderNotFound = 110011;

  /// 旧命名：跨账号结算判定码；契约对他人订单统一返回 [orderNotFound]。
  static const int ownerMismatch = orderNotFound;

  static const int orderStatusInvalid = 110012;
  static const int concurrentUpdateFailed = 110013;
  static const int operatorWithdrawFailed = 110023;
  static const int chainNotSupported = 110035;
  static const int appleVerifyFailed = 110101;

  /// Apple 验真服务临时不可用（HTTP 503），可退避重试。
  static const int appleServerUnavailable = 110102;

  /// Google 购买无效或不匹配（不重试）。
  static const int googleVerifyFailed = 110103;

  /// Google 服务临时不可用（HTTP 503），可退避重试。
  static const int googleServerUnavailable = 110104;

  static const List<int> _known = [
    orderInFlight,
    authInvalid,
    parameterError,
    unauthorized,
    serverError,
    systemConfigMissing,
    assetNotSupported,
    withdrawAddressInvalid,
    idempotentDuplicate,
    orderNotFound,
    orderStatusInvalid,
    concurrentUpdateFailed,
    operatorWithdrawFailed,
    chainNotSupported,
    appleVerifyFailed,
    appleServerUnavailable,
    googleVerifyFailed,
    googleServerUnavailable,
  ];

  static bool isKnown(int code) => _known.contains(code);

  /// Semantic name for logging / diagnostics, or `null` if unknown.
  static String? nameOf(int code) => switch (code) {
    orderInFlight => 'IAP_ORDER_IN_FLIGHT',
    authInvalid => 'AUTH_INVALID',
    parameterError => 'PARAMETER_ERROR',
    unauthorized => 'UNAUTHORIZED',
    serverError => 'SERVER_ERROR',
    systemConfigMissing => 'SYSTEM_CONFIG_MISSING',
    assetNotSupported => 'ASSET_NOT_SUPPORTED',
    withdrawAddressInvalid => 'WITHDRAW_ADDRESS_INVALID',
    idempotentDuplicate => 'IDEMPOTENT_DUPLICATE',
    orderNotFound => 'ORDER_NOT_FOUND',
    orderStatusInvalid => 'ORDER_STATUS_INVALID',
    concurrentUpdateFailed => 'CONCURRENT_UPDATE_FAILED',
    operatorWithdrawFailed => 'OPERATOR_WITHDRAW_FAILED',
    chainNotSupported => 'CHAIN_NOT_SUPPORTED',
    appleVerifyFailed => 'APPLE_VERIFY_FAILED',
    appleServerUnavailable => 'APPLE_SERVER_UNAVAILABLE',
    googleVerifyFailed => 'GOOGLE_VERIFY_FAILED',
    googleServerUnavailable => 'GOOGLE_SERVER_UNAVAILABLE',
    _ => null,
  };
}
