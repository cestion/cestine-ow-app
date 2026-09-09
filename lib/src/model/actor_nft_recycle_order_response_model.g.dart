// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor_nft_recycle_order_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActorNftRecycleOrderResponse _$ActorNftRecycleOrderResponseFromJson(
  Map<String, dynamic> json,
) => ActorNftRecycleOrderResponse(
  sig: json['sig'] as String,
  expiresAt: json['expiresAt'] as String,
  orderNo: json['orderNo'] as String,
  assetId: json['assetId'] as String,
  refundAmountMinor: json['refundAmountMinor'] as String,
  refundUsdcAmount: json['refundUsdcAmount'] as String,
  refundTrainingManual: json['refundTrainingManual'] as String,
  payload: json['payload'] as String,
);

Map<String, dynamic> _$ActorNftRecycleOrderResponseToJson(
  ActorNftRecycleOrderResponse instance,
) => <String, dynamic>{
  'sig': instance.sig,
  'expiresAt': instance.expiresAt,
  'orderNo': instance.orderNo,
  'assetId': instance.assetId,
  'refundAmountMinor': instance.refundAmountMinor,
  'refundUsdcAmount': instance.refundUsdcAmount,
  'refundTrainingManual': instance.refundTrainingManual,
  'payload': instance.payload,
};
