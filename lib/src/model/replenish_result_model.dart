import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'replenish_result_model.g.dart';

/// 补充体力 API 响应，与 web `ReplenishResult` 对齐。
@JsonSerializable()
class ReplenishResult extends Equatable {
  final String? actorNftId;
  @JsonKey(fromJson: asInt)
  final int? beforeStamina;
  @JsonKey(fromJson: asInt)
  final int? afterStamina;
  @JsonKey(fromJson: asDouble)
  final double? cost;
  final String? orderNo;
  final String? status;
  final String? walletAddress;
  final String? payToken;
  final String? payAmountMinor;
  @JsonKey(fromJson: asInt)
  final int? issuedAt;
  @JsonKey(fromJson: asInt)
  final int? expiresAt;
  final String? canonicalPayload;
  final String? sig;

  const ReplenishResult({
    this.actorNftId,
    this.beforeStamina,
    this.afterStamina,
    this.cost,
    this.orderNo,
    this.status,
    this.walletAddress,
    this.payToken,
    this.payAmountMinor,
    this.issuedAt,
    this.expiresAt,
    this.canonicalPayload,
    this.sig,
  });

  factory ReplenishResult.fromJson(Map<String, dynamic> json) =>
      _$ReplenishResultFromJson(json);

  Map<String, dynamic> toJson() => _$ReplenishResultToJson(this);

  bool get hasChainPayload =>
      (sig?.trim().isNotEmpty ?? false) &&
      (canonicalPayload?.trim().isNotEmpty ?? false) &&
      (payToken?.trim().isNotEmpty ?? false) &&
      (orderNo?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [
    actorNftId,
    beforeStamina,
    afterStamina,
    cost,
    orderNo,
    status,
    walletAddress,
    payToken,
    payAmountMinor,
    issuedAt,
    expiresAt,
    canonicalPayload,
    sig,
  ];
}
