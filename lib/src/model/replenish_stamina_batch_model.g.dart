// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replenish_stamina_batch_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplenishStaminaBatchRequest _$ReplenishStaminaBatchRequestFromJson(
  Map<String, dynamic> json,
) => ReplenishStaminaBatchRequest(
  items: (json['items'] as List<dynamic>?)
      ?.map(
        (e) => ReplenishStaminaBatchItem.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  walletAddress: json['walletAddress'] as String?,
);

Map<String, dynamic> _$ReplenishStaminaBatchRequestToJson(
  ReplenishStaminaBatchRequest instance,
) => <String, dynamic>{
  'items': ?instance.items?.map((e) => e.toJson()).toList(),
  'walletAddress': ?instance.walletAddress,
};

ReplenishStaminaBatchItem _$ReplenishStaminaBatchItemFromJson(
  Map<String, dynamic> json,
) => ReplenishStaminaBatchItem(
  actorNftId: json['actorNftId'] as String,
  payAmount: (json['payAmount'] as num).toDouble(),
);

Map<String, dynamic> _$ReplenishStaminaBatchItemToJson(
  ReplenishStaminaBatchItem instance,
) => <String, dynamic>{
  'actorNftId': instance.actorNftId,
  'payAmount': instance.payAmount,
};

ActorNeedingStaminaRefill _$ActorNeedingStaminaRefillFromJson(
  Map<String, dynamic> json,
) => ActorNeedingStaminaRefill(
  actorNftId: json['actorNftId'] as String,
  supplyFee: _asRequiredDouble(json['supplyFee']),
);

Map<String, dynamic> _$ActorNeedingStaminaRefillToJson(
  ActorNeedingStaminaRefill instance,
) => <String, dynamic>{
  'actorNftId': instance.actorNftId,
  'supplyFee': instance.supplyFee,
};

ReplenishBatchResult _$ReplenishBatchResultFromJson(
  Map<String, dynamic> json,
) => ReplenishBatchResult(
  canonicalPayload: json['canonicalPayload'] as String?,
  expiresAt: asInt(json['expiresAt']),
  issuedAt: asInt(json['issuedAt']),
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => ReplenishResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  orderNo: json['orderNo'] as String?,
  payAmountMinor: json['payAmountMinor'] as String?,
  payToken: json['payToken'] as String?,
  sig: json['sig'] as String?,
  totalCost: asDouble(json['totalCost']),
);

Map<String, dynamic> _$ReplenishBatchResultToJson(
  ReplenishBatchResult instance,
) => <String, dynamic>{
  'canonicalPayload': ?instance.canonicalPayload,
  'expiresAt': ?instance.expiresAt,
  'issuedAt': ?instance.issuedAt,
  'items': ?instance.items,
  'orderNo': ?instance.orderNo,
  'payAmountMinor': ?instance.payAmountMinor,
  'payToken': ?instance.payToken,
  'sig': ?instance.sig,
  'totalCost': ?instance.totalCost,
};
