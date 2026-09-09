// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Actor _$ActorFromJson(Map<String, dynamic> json) => Actor(
  id: asString(json['id']),
  userId: asString(json['userId']),
  name: json['name'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  bio: json['bio'] as String?,
  gender: json['gender'] as String?,
  status: json['status'] as String?,
  auditReason: json['auditReason'] as String?,
  nftMintAddress: json['nftMintAddress'] as String?,
  nftMaxSupply: asInt(json['nftMaxSupply']),
  creatorReservedQuantity: asInt(json['creatorReservedQuantity']),
  mintQuantity: asInt(json['mintQuantity']),
  nftUnitPrice: asDouble(json['nftUnitPrice']),
  nftMinHoldThreshold: asInt(json['nftMinHoldThreshold']),
  nftChain: json['nftChain'] as String?,
  nftTokenStandard: json['nftTokenStandard'] as String?,
  nftTxHash: json['nftTxHash'] as String?,
  createdAt: asInt(json['createdAt']),
  updatedAt: asInt(json['updatedAt']),
  version: asInt(json['version']),
);

Map<String, dynamic> _$ActorToJson(Actor instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'name': instance.name,
  'avatarUrl': instance.avatarUrl,
  'bio': instance.bio,
  'gender': instance.gender,
  'status': instance.status,
  'auditReason': instance.auditReason,
  'nftMintAddress': instance.nftMintAddress,
  'nftMaxSupply': instance.nftMaxSupply,
  'creatorReservedQuantity': instance.creatorReservedQuantity,
  'mintQuantity': instance.mintQuantity,
  'nftUnitPrice': instance.nftUnitPrice,
  'nftMinHoldThreshold': instance.nftMinHoldThreshold,
  'nftChain': instance.nftChain,
  'nftTokenStandard': instance.nftTokenStandard,
  'nftTxHash': instance.nftTxHash,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'version': instance.version,
};
