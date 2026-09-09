// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor_collection_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActorCollection _$ActorCollectionFromJson(Map<String, dynamic> json) =>
    ActorCollection(
      id: asString(json['id']),
      userId: asString(json['userId']),
      creatorName: json['creatorName'] as String?,
      assetId: json['assetId'] as String?,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      status: json['status'] as String?,
      auditReason: json['auditReason'] as String?,
      nftMintAddress: json['nftMintAddress'] as String?,
      pricingMode: json['pricingMode'] as String?,
      badge: json['badge'] as String?,
      totalSupply: asString(json['totalSupply']),
      mintedSupply: asString(json['mintedSupply']),
      availableSupply: asString(json['availableSupply']),
      initialPriceUsdc: asDouble(json['initialPriceUsdc']),
      currentPriceUsdc: asDouble(json['currentPriceUsdc']),
      floorPriceUsdc: asDouble(json['floorPriceUsdc']),
      nftChain: json['nftChain'] as String?,
      nftTokenStandard: json['nftTokenStandard'] as String?,
      nftTxHash: json['nftTxHash'] as String?,
      completedViewCount: asString(json['completedViewCount']),
      heatValue: asDouble(json['heatValue']),
      trust: asDouble(json['trust']),
      initialPriceMultiplier: asDouble(json['initialPriceMultiplier']),
      computingPower: asDouble(json['computingPower']),
      createdAt: asString(json['createdAt']),
      updatedAt: asString(json['updatedAt']),
      version: asString(json['version']),
    );

Map<String, dynamic> _$ActorCollectionToJson(ActorCollection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'creatorName': instance.creatorName,
      'assetId': instance.assetId,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'bio': instance.bio,
      'status': instance.status,
      'auditReason': instance.auditReason,
      'nftMintAddress': instance.nftMintAddress,
      'pricingMode': instance.pricingMode,
      'badge': instance.badge,
      'totalSupply': instance.totalSupply,
      'mintedSupply': instance.mintedSupply,
      'availableSupply': instance.availableSupply,
      'initialPriceUsdc': instance.initialPriceUsdc,
      'currentPriceUsdc': instance.currentPriceUsdc,
      'floorPriceUsdc': instance.floorPriceUsdc,
      'nftChain': instance.nftChain,
      'nftTokenStandard': instance.nftTokenStandard,
      'nftTxHash': instance.nftTxHash,
      'completedViewCount': instance.completedViewCount,
      'heatValue': instance.heatValue,
      'trust': instance.trust,
      'initialPriceMultiplier': instance.initialPriceMultiplier,
      'computingPower': instance.computingPower,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'version': instance.version,
    };
