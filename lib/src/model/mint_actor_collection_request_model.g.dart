// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mint_actor_collection_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MintActorCollectionRequest _$MintActorCollectionRequestFromJson(
  Map<String, dynamic> json,
) => MintActorCollectionRequest(
  actorCollectionId: asInt(json['actorCollectionId']),
  nftChain: json['nftChain'] as String,
  nftTokenStandard: json['nftTokenStandard'] as String,
  nftContractAddress: json['nftContractAddress'] as String,
  walletAddress: json['walletAddress'] as String,
  payMethod: json['payMethod'] as String? ?? 'usdc',
);

Map<String, dynamic> _$MintActorCollectionRequestToJson(
  MintActorCollectionRequest instance,
) => <String, dynamic>{
  'actorCollectionId': instance.actorCollectionId,
  'nftChain': instance.nftChain,
  'nftTokenStandard': instance.nftTokenStandard,
  'nftContractAddress': instance.nftContractAddress,
  'walletAddress': instance.walletAddress,
  'payMethod': instance.payMethod,
};
