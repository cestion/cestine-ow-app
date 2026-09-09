import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'iap_apple_verify_request_model.g.dart';

/// Body for `POST /api/userWallet/iap/apple/verify` (IAP v2.0.0 契约 §6)。
@JsonSerializable()
class IapAppleVerifyRequest extends Equatable {
  final String orderId;

  /// StoreKit 2 交易原始 JWS，不可传解码后的 JSON。
  final String signedTransactionInfo;

  const IapAppleVerifyRequest({
    required this.orderId,
    required this.signedTransactionInfo,
  });

  factory IapAppleVerifyRequest.fromJson(Map<String, dynamic> json) =>
      _$IapAppleVerifyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$IapAppleVerifyRequestToJson(this);

  @override
  List<Object?> get props => [orderId, signedTransactionInfo];
}
