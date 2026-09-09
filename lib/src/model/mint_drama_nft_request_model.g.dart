// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mint_drama_nft_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MintDramaNftRequest _$MintDramaNftRequestFromJson(Map<String, dynamic> json) =>
    MintDramaNftRequest(
      nftChain: json['nftChain'] as String,
      nftContractAddress: json['nftContractAddress'] as String,
      nftTokenStandard: json['nftTokenStandard'] as String,
      walletAddress: json['walletAddress'] as String,
      payMethod: json['payMethod'] as String? ?? 'usdc',
    );

Map<String, dynamic> _$MintDramaNftRequestToJson(
  MintDramaNftRequest instance,
) => <String, dynamic>{
  'nftChain': instance.nftChain,
  'nftContractAddress': instance.nftContractAddress,
  'nftTokenStandard': instance.nftTokenStandard,
  'walletAddress': instance.walletAddress,
  'payMethod': instance.payMethod,
};
