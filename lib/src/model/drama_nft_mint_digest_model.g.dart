// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drama_nft_mint_digest_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DramaNftMintDigest _$DramaNftMintDigestFromJson(Map<String, dynamic> json) =>
    DramaNftMintDigest(
      userId: json['userId'] as String?,
      dramaId: json['dramaId'] as String?,
      creatorAddress: json['creatorAddress'] as String?,
      mintWalletAddress: json['mintWalletAddress'] as String?,
      nftChain: json['nftChain'] as String?,
      nftTokenStandard: json['nftTokenStandard'] as String?,
      nftContractAddress: json['nftContractAddress'] as String?,
      metadataUrl: json['metadataUrl'] as String?,
      payToken: json['payToken'] as String?,
      feeAmount: json['feeAmount'] as String?,
      issuedAt: asInt(json['issuedAt']),
      expiresAt: asInt(json['expiresAt']),
      canonicalPayload: json['canonicalPayload'] as String?,
      sig: json['sig'] as String?,
    );

Map<String, dynamic> _$DramaNftMintDigestToJson(DramaNftMintDigest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'dramaId': instance.dramaId,
      'creatorAddress': instance.creatorAddress,
      'mintWalletAddress': instance.mintWalletAddress,
      'nftChain': instance.nftChain,
      'nftTokenStandard': instance.nftTokenStandard,
      'nftContractAddress': instance.nftContractAddress,
      'metadataUrl': instance.metadataUrl,
      'payToken': instance.payToken,
      'feeAmount': instance.feeAmount,
      'issuedAt': instance.issuedAt,
      'expiresAt': instance.expiresAt,
      'canonicalPayload': instance.canonicalPayload,
      'sig': instance.sig,
    };
