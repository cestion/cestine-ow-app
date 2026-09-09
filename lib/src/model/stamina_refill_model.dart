import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'stamina_refill_model.g.dart';

int _asRequiredInt(Object? value) => asInt(value)!;

/// A centralized stamina refill paid with the user's `STAMINA_PACK` balance.
@JsonSerializable()
class StaminaRefillResult extends Equatable {
  /// Actor NFT asset id in `{actorCollectionId}_{tokenId}` format.
  final String actorNftId;

  @JsonKey(fromJson: _asRequiredInt)
  final int beforeStamina;

  @JsonKey(fromJson: _asRequiredInt)
  final int afterStamina;

  const StaminaRefillResult({
    required this.actorNftId,
    required this.beforeStamina,
    required this.afterStamina,
  });

  factory StaminaRefillResult.fromJson(Map<String, dynamic> json) =>
      _$StaminaRefillResultFromJson(json);

  Map<String, dynamic> toJson() => _$StaminaRefillResultToJson(this);

  @override
  List<Object?> get props => [actorNftId, beforeStamina, afterStamina];
}

/// One actor requested by the centralized batch-refill endpoint.
@JsonSerializable()
class StaminaRefillBatchItem extends Equatable {
  final String actorNftId;

  const StaminaRefillBatchItem({required this.actorNftId});

  factory StaminaRefillBatchItem.fromJson(Map<String, dynamic> json) =>
      _$StaminaRefillBatchItemFromJson(json);

  Map<String, dynamic> toJson() => _$StaminaRefillBatchItemToJson(this);

  @override
  List<Object?> get props => [actorNftId];
}

/// Batch refill request. Omitting [items], or passing an empty list, asks the
/// backend to refill every eligible actor owned by the current user.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class StaminaRefillBatchRequest extends Equatable {
  final List<StaminaRefillBatchItem>? items;

  const StaminaRefillBatchRequest({this.items});

  factory StaminaRefillBatchRequest.fromJson(Map<String, dynamic> json) =>
      _$StaminaRefillBatchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StaminaRefillBatchRequestToJson(this);

  @override
  List<Object?> get props => [items];
}

/// Result returned by the centralized batch-refill endpoint.
@JsonSerializable(explicitToJson: true)
class StaminaRefillBatchResult extends Equatable {
  final List<StaminaRefillResult>? items;

  const StaminaRefillBatchResult({this.items});

  factory StaminaRefillBatchResult.fromJson(Map<String, dynamic> json) =>
      _$StaminaRefillBatchResultFromJson(json);

  Map<String, dynamic> toJson() => _$StaminaRefillBatchResultToJson(this);

  @override
  List<Object?> get props => [items];
}
