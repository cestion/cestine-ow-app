import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'iap_google_verify_request_model.g.dart';

/// Body for `POST /api/userWallet/iap/google/verify` (IAP v2.0.0 契约 §7)。
@JsonSerializable()
class IapGoogleVerifyRequest extends Equatable {
  final String orderId;

  /// Google Play Billing 返回的购买 Token。
  final String purchaseToken;

  const IapGoogleVerifyRequest({
    required this.orderId,
    required this.purchaseToken,
  });

  factory IapGoogleVerifyRequest.fromJson(Map<String, dynamic> json) =>
      _$IapGoogleVerifyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$IapGoogleVerifyRequestToJson(this);

  @override
  List<Object?> get props => [orderId, purchaseToken];
}
