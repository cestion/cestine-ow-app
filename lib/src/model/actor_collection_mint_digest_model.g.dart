// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor_collection_mint_digest_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActorCollectionMintDigest _$ActorCollectionMintDigestFromJson(
  Map<String, dynamic> json,
) => ActorCollectionMintDigest(
  actorCollectionId: asInt(json['actorCollectionId']),
  assetId: json['assetId'] as String?,
  creatorAddress: json['creatorAddress'] as String?,
  walletAddress: json['walletAddress'] as String?,
  collectionMintAddress: json['collectionMintAddress'] as String?,
  name: json['name'] as String?,
  nftChain: json['nftChain'] as String?,
  nftTokenStandard: json['nftTokenStandard'] as String?,
  baseUrl: json['baseUrl'] as String?,
  totalSupply: asInt(json['totalSupply']),
  initialPriceUsdc: asDouble(json['initialPriceUsdc']),
  initialPriceAmount: json['initialPriceAmount'] as String?,
  curveMultiplierAmount: json['curveMultiplierAmount'] as String?,
  payToken: json['payToken'] as String?,
  feeAmount: json['feeAmount'] as String?,
  issuedAt: asInt(json['issuedAt']),
  expiresAt: asInt(json['expiresAt']),
  canonicalPayload: json['canonicalPayload'] as String?,
  sig: json['sig'] as String?,
);

Map<String, dynamic> _$ActorCollectionMintDigestToJson(
  ActorCollectionMintDigest instance,
) => <String, dynamic>{
  'actorCollectionId': instance.actorCollectionId,
  'assetId': instance.assetId,
  'creatorAddress': instance.creatorAddress,
  'walletAddress': instance.walletAddress,
  'collectionMintAddress': instance.collectionMintAddress,
  'name': instance.name,
  'nftChain': instance.nftChain,
  'nftTokenStandard': instance.nftTokenStandard,
  'baseUrl': instance.baseUrl,
  'totalSupply': instance.totalSupply,
  'initialPriceUsdc': instance.initialPriceUsdc,
  'initialPriceAmount': instance.initialPriceAmount,
  'curveMultiplierAmount': instance.curveMultiplierAmount,
  'payToken': instance.payToken,
  'feeAmount': instance.feeAmount,
  'issuedAt': instance.issuedAt,
  'expiresAt': instance.expiresAt,
  'canonicalPayload': instance.canonicalPayload,
  'sig': instance.sig,
};
