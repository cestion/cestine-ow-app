// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor_nft_recycle_estimate_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActorNftRecycleEstimateResponse _$ActorNftRecycleEstimateResponseFromJson(
  Map<String, dynamic> json,
) => ActorNftRecycleEstimateResponse(
  actorCollectionId: json['actorCollectionId'] as String,
  tokenId: json['tokenId'] as String,
  assetId: json['assetId'] as String,
  refundUsdcAmount: json['refundUsdcAmount'] as String,
  refundAmountMinor: json['refundAmountMinor'] as String,
  refundTrainingManual: json['refundTrainingManual'] as String,
);

Map<String, dynamic> _$ActorNftRecycleEstimateResponseToJson(
  ActorNftRecycleEstimateResponse instance,
) => <String, dynamic>{
  'actorCollectionId': instance.actorCollectionId,
  'tokenId': instance.tokenId,
  'assetId': instance.assetId,
  'refundUsdcAmount': instance.refundUsdcAmount,
  'refundAmountMinor': instance.refundAmountMinor,
  'refundTrainingManual': instance.refundTrainingManual,
};
