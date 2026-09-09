import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'iap_order.g.dart';

/// 支付渠道（IAP v2.0.0 契约）。
enum IapPaymentChannel {
  apple('APPLE'),
  google('GOOGLE');

  const IapPaymentChannel(this.apiValue);
  final String apiValue;

  static IapPaymentChannel? fromApiValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final channel in IapPaymentChannel.values) {
      if (channel.apiValue == value) return channel;
    }
    return null;
  }
}

/// Server order states (IAP v2.0.0 契约 §8)。
enum IapOrderStatus {
  pendingPayment(0, 'PENDING_PAYMENT'),
  payProcessing(1, 'PAY_PROCESSING'),
  paid(2, 'PAID'),
  recharging(3, 'RECHARGING'),
  recharged(4, 'RECHARGED'),
  payFailed(5, 'PAY_FAILED'),
  rechargeFailed(6, 'RECHARGE_FAILED');

  const IapOrderStatus(this.code, this.apiValue);
  final int code;
  final String apiValue;

  static IapOrderStatus? fromCode(int? code) {
    if (code == null) return null;
    for (final status in IapOrderStatus.values) {
      if (status.code == code) return status;
    }
    return null;
  }

  static IapOrderStatus? fromApiValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final status in IapOrderStatus.values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}

/// An IAP order returned by the backend (IAP v2.0.0 契约 §4/§5/§6/§7)。
///
/// `status` 保留原始数值，经 [orderStatus] 解析，未知值不崩。
/// 金额字段（`purchaseAmount` / `tokenAmount`）为**字符串**，勿按浮点计算。
@JsonSerializable()
class IapOrder extends Equatable {
  /// 后端业务订单号（UUID）。
  final String orderId;

  /// `APPLE` / `GOOGLE`。
  final String? paymentChannel;

  final String? productId;

  /// 商品价格快照（字符串）。
  final String? purchaseAmount;
  final String? currency;

  /// 预计发放资产数量（字符串）。
  final String? tokenAmount;

  /// 商店订单与后端订单的绑定 ID（Apple `appAccountToken` / Google
  /// `obfuscatedExternalAccountId`），当前与 [orderId] 相同。
  final String? providerAccountId;

  /// 订单状态码（IAP v2.0.0 契约 §8）。
  final int? status;
  final String? statusName;

  /// Apple `transactionId` / Google Play `orderId`。
  final String? providerTransactionId;

  /// 资产发放系统订单号。
  final String? operatorOrderId;

  /// 资产发放系统返回的状态。
  final String? operatorStatus;

  /// 订单创建时间，Unix 毫秒。
  final int? createdAt;

  const IapOrder({
    required this.orderId,
    this.paymentChannel,
    this.productId,
    this.purchaseAmount,
    this.currency,
    this.tokenAmount,
    this.providerAccountId,
    required this.status,
    this.statusName,
    this.providerTransactionId,
    this.operatorOrderId,
    this.operatorStatus,
    this.createdAt,
  });

  factory IapOrder.fromJson(Map<String, dynamic> json) =>
      _$IapOrderFromJson(json);

  Map<String, dynamic> toJson() => _$IapOrderToJson(this);

  IapOrderStatus? get orderStatus => IapOrderStatus.fromCode(status);

  /// 支付已被服务端接受、等待发放完成（PAY_PROCESSING/PAID/RECHARGING/
  /// RECHARGED）——Apple 可在验单 `code==100000` 后 finish，随后轮询。
  bool get isAccepted =>
      orderStatus == IapOrderStatus.payProcessing ||
      orderStatus == IapOrderStatus.paid ||
      orderStatus == IapOrderStatus.recharging ||
      orderStatus == IapOrderStatus.recharged;

  /// 兼容旧命名：已受理即可 finish。
  bool get isFulfilled => isAccepted;

  /// 终态成功（RECHARGED）→ 展示到账成功。
  bool get isSettled => orderStatus == IapOrderStatus.recharged;

  /// 终态失败（PAY_FAILED / RECHARGE_FAILED）。
  bool get isFailed =>
      orderStatus == IapOrderStatus.payFailed ||
      orderStatus == IapOrderStatus.rechargeFailed;

  @override
  List<Object?> get props => [
    orderId,
    paymentChannel,
    productId,
    purchaseAmount,
    currency,
    tokenAmount,
    providerAccountId,
    status,
    statusName,
    providerTransactionId,
    operatorOrderId,
    operatorStatus,
    createdAt,
  ];
}
