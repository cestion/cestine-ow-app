import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';
import 'replenish_result_model.dart';

part 'replenish_stamina_batch_model.g.dart';

// json_serializable requires a non-null converter for this required field.
double _asRequiredDouble(Object? value) => asDouble(value)!;

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ReplenishStaminaBatchRequest extends Equatable {
  final List<ReplenishStaminaBatchItem>? items;
  final String? walletAddress;

  const ReplenishStaminaBatchRequest({this.items, this.walletAddress});

  factory ReplenishStaminaBatchRequest.fromJson(Map<String, dynamic> json) =>
      _$ReplenishStaminaBatchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReplenishStaminaBatchRequestToJson(this);

  @override
  List<Object?> get props => [items, walletAddress];
}

@JsonSerializable()
class ReplenishStaminaBatchItem extends Equatable {
  final String actorNftId;
  final double payAmount;

  const ReplenishStaminaBatchItem({
    required this.actorNftId,
    required this.payAmount,
  });

  factory ReplenishStaminaBatchItem.fromJson(Map<String, dynamic> json) =>
      _$ReplenishStaminaBatchItemFromJson(json);

  Map<String, dynamic> toJson() => _$ReplenishStaminaBatchItemToJson(this);

  @override
  List<Object?> get props => [actorNftId, payAmount];
}

@JsonSerializable()
class ActorNeedingStaminaRefill extends Equatable {
  final String actorNftId;
  @JsonKey(fromJson: _asRequiredDouble)
  final double supplyFee;

  const ActorNeedingStaminaRefill({
    required this.actorNftId,
    required this.supplyFee,
  });

  factory ActorNeedingStaminaRefill.fromJson(Map<String, dynamic> json) =>
      _$ActorNeedingStaminaRefillFromJson(json);

  Map<String, dynamic> toJson() => _$ActorNeedingStaminaRefillToJson(this);

  @override
  List<Object?> get props => [actorNftId, supplyFee];
}

@JsonSerializable(includeIfNull: false)
class ReplenishBatchResult extends Equatable {
  final String? canonicalPayload;
  @JsonKey(fromJson: asInt)
  final int? expiresAt;
  @JsonKey(fromJson: asInt)
  final int? issuedAt;
  final List<ReplenishResult>? items;
  final String? orderNo;
  final String? payAmountMinor;
  final String? payToken;
  final String? sig;
  @JsonKey(fromJson: asDouble)
  final double? totalCost;

  const ReplenishBatchResult({
    this.canonicalPayload,
    this.expiresAt,
    this.issuedAt,
    this.items,
    this.orderNo,
    this.payAmountMinor,
    this.payToken,
    this.sig,
    this.totalCost,
  });

  factory ReplenishBatchResult.fromJson(Map<String, dynamic> json) =>
      _$ReplenishBatchResultFromJson(json);

  Map<String, dynamic> toJson() => _$ReplenishBatchResultToJson(this);

  bool get hasChainPayload =>
      (sig?.trim().isNotEmpty ?? false) &&
      (canonicalPayload?.trim().isNotEmpty ?? false) &&
      (payToken?.trim().isNotEmpty ?? false) &&
      (orderNo?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [
    canonicalPayload,
    expiresAt,
    issuedAt,
    items,
    orderNo,
    payAmountMinor,
    payToken,
    sig,
    totalCost,
  ];
}
