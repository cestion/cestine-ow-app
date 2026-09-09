// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepare_actor_collection_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrepareActorCollectionRequest _$PrepareActorCollectionRequestFromJson(
  Map<String, dynamic> json,
) => PrepareActorCollectionRequest(
  assetId: json['assetId'] as String,
  name: json['name'] as String,
  bio: json['bio'] as String,
  totalSupply: PrepareActorCollectionRequest._toInt(json['totalSupply']),
  pricingMode: json['pricingMode'] as String,
  initialPriceUsdc: PrepareActorCollectionRequest._toDouble(
    json['initialPriceUsdc'],
  ),
);

Map<String, dynamic> _$PrepareActorCollectionRequestToJson(
  PrepareActorCollectionRequest instance,
) => <String, dynamic>{
  'assetId': instance.assetId,
  'name': instance.name,
  'bio': instance.bio,
  'totalSupply': instance.totalSupply,
  'pricingMode': instance.pricingMode,
  'initialPriceUsdc': instance.initialPriceUsdc,
};
