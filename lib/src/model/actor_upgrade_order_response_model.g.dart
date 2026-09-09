// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor_upgrade_order_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActorUpgradeOrderResponse _$ActorUpgradeOrderResponseFromJson(
  Map<String, dynamic> json,
) => ActorUpgradeOrderResponse(
  sig: json['sig'] as String?,
  expiresAt: json['expiresAt'] as String?,
  payload: json['payload'] as String?,
  payToken: json['payToken'] as String?,
);

Map<String, dynamic> _$ActorUpgradeOrderResponseToJson(
  ActorUpgradeOrderResponse instance,
) => <String, dynamic>{
  'sig': instance.sig,
  'expiresAt': instance.expiresAt,
  'payload': instance.payload,
  'payToken': instance.payToken,
};
