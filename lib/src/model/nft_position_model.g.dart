// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nft_position_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NftPosition _$NftPositionFromJson(Map<String, dynamic> json) => NftPosition(
  id: NftPosition._readId(json, 'id') as String?,
  dramaId: json['dramaId'] as String?,
  nftContractAddress: json['nftContractAddress'] as String?,
  dramaName: json['dramaName'] as String?,
  coverUrl: json['coverUrl'] as String?,
  episodeCount: asInt(json['episodeCount']),
  description: json['description'] as String?,
  status: asString(json['status']),
  createdAt: asInt(json['createdAt']),
);

Map<String, dynamic> _$NftPositionToJson(NftPosition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dramaId': instance.dramaId,
      'nftContractAddress': instance.nftContractAddress,
      'dramaName': instance.dramaName,
      'coverUrl': instance.coverUrl,
      'episodeCount': instance.episodeCount,
      'description': instance.description,
      'status': instance.status,
      'createdAt': instance.createdAt,
    };
