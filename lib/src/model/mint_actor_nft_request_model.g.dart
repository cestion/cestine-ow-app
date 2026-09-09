// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mint_actor_nft_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MintActorNftRequest _$MintActorNftRequestFromJson(Map<String, dynamic> json) =>
    MintActorNftRequest(
      nftChain: json['nftChain'] as String,
      nftTokenStandard: json['nftTokenStandard'] as String,
      nftContractAddress: json['nftContractAddress'] as String,
      walletAddress: json['walletAddress'] as String,
      payMethod: json['payMethod'] as String? ?? 'usdc',
    );

Map<String, dynamic> _$MintActorNftRequestToJson(
  MintActorNftRequest instance,
) => <String, dynamic>{
  'nftChain': instance.nftChain,
  'nftTokenStandard': instance.nftTokenStandard,
  'nftContractAddress': instance.nftContractAddress,
  'walletAddress': instance.walletAddress,
  'payMethod': instance.payMethod,
};
