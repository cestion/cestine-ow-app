import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'iap_create_order_request_model.g.dart';

/// Body for `POST /api/userWallet/iap/orders` (IAP v2.0.0 契约 §4)。
///
/// 商品金额与发放数量由后端决定，客户端只能传渠道与商品 ID。
@JsonSerializable()
class IapCreateOrderRequest extends Equatable {
  /// `APPLE` / `GOOGLE`（[IapPaymentChannel.apiValue]）。
  final String paymentChannel;
  final String productId;

  const IapCreateOrderRequest({
    required this.paymentChannel,
    required this.productId,
  });

  factory IapCreateOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$IapCreateOrderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$IapCreateOrderRequestToJson(this);

  @override
  List<Object?> get props => [paymentChannel, productId];
}
