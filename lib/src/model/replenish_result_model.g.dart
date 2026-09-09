// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replenish_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplenishResult _$ReplenishResultFromJson(Map<String, dynamic> json) =>
    ReplenishResult(
      actorNftId: json['actorNftId'] as String?,
      beforeStamina: asInt(json['beforeStamina']),
      afterStamina: asInt(json['afterStamina']),
      cost: asDouble(json['cost']),
      orderNo: json['orderNo'] as String?,
      status: json['status'] as String?,
      walletAddress: json['walletAddress'] as String?,
      payToken: json['payToken'] as String?,
      payAmountMinor: json['payAmountMinor'] as String?,
      issuedAt: asInt(json['issuedAt']),
      expiresAt: asInt(json['expiresAt']),
      canonicalPayload: json['canonicalPayload'] as String?,
      sig: json['sig'] as String?,
    );

Map<String, dynamic> _$ReplenishResultToJson(ReplenishResult instance) =>
    <String, dynamic>{
      'actorNftId': instance.actorNftId,
      'beforeStamina': instance.beforeStamina,
      'afterStamina': instance.afterStamina,
      'cost': instance.cost,
      'orderNo': instance.orderNo,
      'status': instance.status,
      'walletAddress': instance.walletAddress,
      'payToken': instance.payToken,
      'payAmountMinor': instance.payAmountMinor,
      'issuedAt': instance.issuedAt,
      'expiresAt': instance.expiresAt,
      'canonicalPayload': instance.canonicalPayload,
      'sig': instance.sig,
    };
