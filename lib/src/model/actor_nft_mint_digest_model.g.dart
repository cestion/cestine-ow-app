// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor_nft_mint_digest_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActorNftMintDigest _$ActorNftMintDigestFromJson(Map<String, dynamic> json) =>
    ActorNftMintDigest(
      actorCollectionId: asInt(json['actorCollectionId']),
      assetId: json['assetId'] as String?,
      walletAddress: json['walletAddress'] as String?,
      collectionMintAddress: json['collectionMintAddress'] as String?,
      name: json['name'] as String?,
      nftChain: json['nftChain'] as String?,
      nftTokenStandard: json['nftTokenStandard'] as String?,
      initialPriceUsdc: asDouble(json['initialPriceUsdc']),
      payToken: json['payToken'] as String?,
      currentSupply: asInt(json['currentSupply']),
      quantity: asInt(json['quantity']),
      basePrice: asDouble(json['basePrice']),
      totalPrice: asDouble(json['totalPrice']),
      totalPriceWithSlippage: asDouble(json['totalPriceWithSlippage']),
      nextPrice: asDouble(json['nextPrice']),
      issuedAt: asInt(json['issuedAt']),
      expiresAt: asInt(json['expiresAt']),
      canonicalPayload: json['canonicalPayload'] as String?,
      sig: json['sig'] as String?,
    );

Map<String, dynamic> _$ActorNftMintDigestToJson(ActorNftMintDigest instance) =>
    <String, dynamic>{
      'actorCollectionId': instance.actorCollectionId,
      'assetId': instance.assetId,
      'walletAddress': instance.walletAddress,
      'collectionMintAddress': instance.collectionMintAddress,
      'name': instance.name,
      'nftChain': instance.nftChain,
      'nftTokenStandard': instance.nftTokenStandard,
      'initialPriceUsdc': instance.initialPriceUsdc,
      'payToken': instance.payToken,
      'currentSupply': instance.currentSupply,
      'quantity': instance.quantity,
      'basePrice': instance.basePrice,
      'totalPrice': instance.totalPrice,
      'totalPriceWithSlippage': instance.totalPriceWithSlippage,
      'nextPrice': instance.nextPrice,
      'issuedAt': instance.issuedAt,
      'expiresAt': instance.expiresAt,
      'canonicalPayload': instance.canonicalPayload,
      'sig': instance.sig,
    };
