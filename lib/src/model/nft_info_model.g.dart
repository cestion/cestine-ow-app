// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nft_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NftInfo _$NftInfoFromJson(Map<String, dynamic> json) => NftInfo(
  mintAddress: json['mintAddress'] as String?,
  chain: json['chain'] as String?,
  tokenStandard: json['tokenStandard'] as String?,
  maxSupply: asInt(json['maxSupply']),
  unitPrice: asDouble(json['unitPrice']),
  minHoldThreshold: asInt(json['minHoldThreshold']),
  txHash: json['txHash'] as String?,
);

Map<String, dynamic> _$NftInfoToJson(NftInfo instance) => <String, dynamic>{
  'mintAddress': instance.mintAddress,
  'chain': instance.chain,
  'tokenStandard': instance.tokenStandard,
  'maxSupply': instance.maxSupply,
  'unitPrice': instance.unitPrice,
  'minHoldThreshold': instance.minHoldThreshold,
  'txHash': instance.txHash,
};
