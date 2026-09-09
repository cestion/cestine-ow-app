// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creator_drama_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BoundActor _$BoundActorFromJson(Map<String, dynamic> json) => BoundActor(
  actorCollectionId: asInt(json['actorCollectionId']),
  assetId: json['assetId'] as String?,
  name: json['name'] as String?,
  avatarUrl: BoundActor._readAvatarUrl(json, 'avatarUrl') as String?,
  trust: asDouble(json['trust']),
  computingPower: asDouble(json['computingPower']),
);

Map<String, dynamic> _$BoundActorToJson(BoundActor instance) =>
    <String, dynamic>{
      'actorCollectionId': instance.actorCollectionId,
      'assetId': instance.assetId,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'trust': instance.trust,
      'computingPower': instance.computingPower,
    };

CreatorDrama _$CreatorDramaFromJson(Map<String, dynamic> json) => CreatorDrama(
  id: asString(json['id']),
  title: json['title'] as String?,
  description: json['description'] as String?,
  coverUrl: json['coverUrl'] as String?,
  totalEpisodes: asInt(json['totalEpisodes']),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  boundActorCollections: (json['boundActorCollections'] as List<dynamic>?)
      ?.map((e) => BoundActor.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: json['status'] as String?,
  auditReason: json['auditReason'] as String?,
  onlineAt: asInt(json['onlineAt']),
  offlineAt: asInt(json['offlineAt']),
  nftChain: json['nftChain'] as String?,
  nftContractAddress: json['nftContractAddress'] as String?,
  nftTxHash: json['nftTxHash'] as String?,
  nftMinted: asBool(json['nftMinted']),
  createdAt: asInt(json['createdAt']),
  version: asInt(json['version']),
);

Map<String, dynamic> _$CreatorDramaToJson(CreatorDrama instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'coverUrl': instance.coverUrl,
      'totalEpisodes': instance.totalEpisodes,
      'tags': instance.tags,
      'boundActorCollections': instance.boundActorCollections
          ?.map((e) => e.toJson())
          .toList(),
      'status': instance.status,
      'auditReason': instance.auditReason,
      'onlineAt': instance.onlineAt,
      'offlineAt': instance.offlineAt,
      'nftChain': instance.nftChain,
      'nftContractAddress': instance.nftContractAddress,
      'nftTxHash': instance.nftTxHash,
      'nftMinted': instance.nftMinted,
      'createdAt': instance.createdAt,
      'version': instance.version,
    };
