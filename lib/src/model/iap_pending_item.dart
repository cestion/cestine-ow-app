import 'package:equatable/equatable.dart';

import '../core/json_helpers.dart';

/// Client-side state of a pending IAP order (design §4.1).
enum IapPendingState {
  /// A [clientOrderId] has been created but the store payment has not been
  /// launched yet.
  pendingInit,

  /// The store payment sheet is open / in flight, awaiting a purchaseStream
  /// callback.
  pendingPurchase,

  /// Purchase confirmed by the store, waiting for server verify + delivery.
  waitingServer,

  /// Verify accepted, USDC issuance in progress (`RECHARGING`) — store
  /// transaction already finished, polling `getOrder` until terminal
  /// (`RECHARGED` / `PAY_FAILED` / `RECHARGE_FAILED`).
  recharging,

  /// Store transaction settled (consumed/finished) but NOT delivered yet —
  /// waiting for the original account to log back in (cross-account, §12.4).
  pendingDelivery,

  /// Delivered on the server AND settled on the store → removable.
  done,

  /// User cancelled or verification definitively rejected.
  cancelled,

  /// Automatic retries exhausted; kept for manual retry / diagnostics.
  failed,

  /// A leftover store transaction was found on this device with no local
  /// record; attribution to [IapPendingItem.userId] is best-effort.
  orphaned,
}

/// A persisted entry of the client pending-delivery queue.
///
/// Stored in the dedicated Hive box [IapConfig.queueBoxName], keyed by
/// [clientOrderId]. Deliberately bound to [userId] and **never cleared on
/// logout** so a purchase survives auth resets and cross-account switches.
class IapPendingItem with Equatable {
  final String clientOrderId;
  final String productId;

  /// The account that placed the order — delivery is only ever granted to
  /// this user (server-side ownership check is authoritative).
  final String userId;

  /// Server order id (UUID string) returned by `createOrder` — needed for
  /// getOrder/verifyOrder.
  final String? orderId;

  /// `APPLE` / `GOOGLE`（IAP 契约 §10.3 需持久化）。
  final String? paymentChannel;

  /// 商店订单与后端订单的绑定 ID（Apple `appAccountToken` / Google
  /// `obfuscatedExternalAccountId`），购买时传给商店 SDK。
  final String? providerAccountId;

  /// iOS `transactionId` (StoreKit), filled after the store confirms.
  final String? storeTransactionId;

  /// StoreKit 2 交易原始 JWS，用于后续补验单（Apple IAP 契约 §5.3）。
  final String? verificationData;

  final int retryCount;
  final IapPendingState state;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IapPendingItem({
    required this.clientOrderId,
    required this.productId,
    required this.userId,
    this.orderId,
    this.paymentChannel,
    this.providerAccountId,
    this.storeTransactionId,
    this.verificationData,
    this.retryCount = 0,
    this.state = IapPendingState.pendingInit,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a brand-new entry (initially `pendingInit`).
  factory IapPendingItem.create({
    required String clientOrderId,
    required String productId,
    required String userId,
    DateTime? now,
  }) {
    final ts = now ?? DateTime.now();
    return IapPendingItem(
      clientOrderId: clientOrderId,
      productId: productId,
      userId: userId,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  /// Store-side "in progress" states that must block a re-purchase of the
  /// same SKU for this account (design §6.2 / §12.1).
  ///
  /// [IapPendingState.pendingDelivery] is intentionally excluded: the store
  /// transaction is already consumed, so it never blocks other accounts.
  bool get isInFlight =>
      state == IapPendingState.pendingInit ||
      state == IapPendingState.pendingPurchase ||
      state == IapPendingState.waitingServer;

  /// Whether the store transaction has been settled for another account
  /// (cross-account settle, design §12.4) and awaits the owner's re-login.
  bool get awaitingOwnerDelivery =>
      state == IapPendingState.pendingDelivery;

  IapPendingItem copyWith({
    String? orderId,
    String? paymentChannel,
    String? providerAccountId,
    String? storeTransactionId,
    String? verificationData,
    int? retryCount,
    IapPendingState? state,
    DateTime? updatedAt,
  }) {
    return IapPendingItem(
      clientOrderId: clientOrderId,
      productId: productId,
      userId: userId,
      orderId: orderId ?? this.orderId,
      paymentChannel: paymentChannel ?? this.paymentChannel,
      providerAccountId: providerAccountId ?? this.providerAccountId,
      storeTransactionId: storeTransactionId ?? this.storeTransactionId,
      verificationData: verificationData ?? this.verificationData,
      retryCount: retryCount ?? this.retryCount,
      state: state ?? this.state,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'clientOrderId': clientOrderId,
    'productId': productId,
    'userId': userId,
    if (orderId != null) 'orderId': orderId,
    if (paymentChannel != null) 'paymentChannel': paymentChannel,
    if (providerAccountId != null) 'providerAccountId': providerAccountId,
    if (storeTransactionId != null) 'storeTransactionId': storeTransactionId,
    if (verificationData != null) 'verificationData': verificationData,
    'retryCount': retryCount,
    'state': state.name,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  static IapPendingItem? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final clientOrderId = asStringOrNull(map['clientOrderId']);
    final productId = asStringOrNull(map['productId']);
    final userId = asStringOrNull(map['userId']);
    if (clientOrderId == null ||
        clientOrderId.isEmpty ||
        productId == null ||
        userId == null) {
      return null;
    }
    return IapPendingItem(
      clientOrderId: clientOrderId,
      productId: productId,
      userId: userId,
      orderId: asStringOrNull(map['orderId']),
      paymentChannel: asStringOrNull(map['paymentChannel']),
      providerAccountId: asStringOrNull(map['providerAccountId']),
      storeTransactionId: asStringOrNull(map['storeTransactionId']),
      verificationData: asStringOrNull(map['verificationData']),
      retryCount: asIntOrNull(map['retryCount']) ?? 0,
      state: IapPendingState.values.asNameMap()[
              asStringOrNull(map['state'])] ??
          IapPendingState.pendingInit,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        asIntOrNull(map['createdAt']) ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        asIntOrNull(map['updatedAt']) ?? 0,
      ),
    );
  }

  @override
  List<Object?> get props => [
    clientOrderId,
    productId,
    userId,
    orderId,
    paymentChannel,
    providerAccountId,
    storeTransactionId,
    verificationData,
    retryCount,
    state,
    createdAt,
    updatedAt,
  ];
}
