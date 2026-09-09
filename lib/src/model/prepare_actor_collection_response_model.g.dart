// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepare_actor_collection_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrepareActorCollectionResponse _$PrepareActorCollectionResponseFromJson(
  Map<String, dynamic> json,
) => PrepareActorCollectionResponse(
  actorCollectionId: asInt(json['actorCollectionId']),
  assetId: json['assetId'] as String?,
  name: json['name'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  bio: json['bio'] as String?,
  totalSupply: asInt(json['totalSupply']),
  initialPriceUsdc: asDouble(json['initialPriceUsdc']),
  pricingMode: json['pricingMode'] as String?,
  status: json['status'] as String?,
  expiresAt: asInt(json['expiresAt']),
);

Map<String, dynamic> _$PrepareActorCollectionResponseToJson(
  PrepareActorCollectionResponse instance,
) => <String, dynamic>{
  'actorCollectionId': instance.actorCollectionId,
  'assetId': instance.assetId,
  'name': instance.name,
  'avatarUrl': instance.avatarUrl,
  'bio': instance.bio,
  'totalSupply': instance.totalSupply,
  'initialPriceUsdc': instance.initialPriceUsdc,
  'pricingMode': instance.pricingMode,
  'status': instance.status,
  'expiresAt': instance.expiresAt,
};
