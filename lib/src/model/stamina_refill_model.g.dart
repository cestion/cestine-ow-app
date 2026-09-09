// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stamina_refill_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaminaRefillResult _$StaminaRefillResultFromJson(Map<String, dynamic> json) =>
    StaminaRefillResult(
      actorNftId: json['actorNftId'] as String,
      beforeStamina: _asRequiredInt(json['beforeStamina']),
      afterStamina: _asRequiredInt(json['afterStamina']),
    );

Map<String, dynamic> _$StaminaRefillResultToJson(
  StaminaRefillResult instance,
) => <String, dynamic>{
  'actorNftId': instance.actorNftId,
  'beforeStamina': instance.beforeStamina,
  'afterStamina': instance.afterStamina,
};

StaminaRefillBatchItem _$StaminaRefillBatchItemFromJson(
  Map<String, dynamic> json,
) => StaminaRefillBatchItem(actorNftId: json['actorNftId'] as String);

Map<String, dynamic> _$StaminaRefillBatchItemToJson(
  StaminaRefillBatchItem instance,
) => <String, dynamic>{'actorNftId': instance.actorNftId};

StaminaRefillBatchRequest _$StaminaRefillBatchRequestFromJson(
  Map<String, dynamic> json,
) => StaminaRefillBatchRequest(
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => StaminaRefillBatchItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StaminaRefillBatchRequestToJson(
  StaminaRefillBatchRequest instance,
) => <String, dynamic>{
  'items': ?instance.items?.map((e) => e.toJson()).toList(),
};

StaminaRefillBatchResult _$StaminaRefillBatchResultFromJson(
  Map<String, dynamic> json,
) => StaminaRefillBatchResult(
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => StaminaRefillResult.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StaminaRefillBatchResultToJson(
  StaminaRefillBatchResult instance,
) => <String, dynamic>{
  'items': instance.items?.map((e) => e.toJson()).toList(),
};
