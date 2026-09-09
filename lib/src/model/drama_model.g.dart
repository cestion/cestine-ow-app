// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drama_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DramaActorCollection _$DramaActorCollectionFromJson(
  Map<String, dynamic> json,
) => DramaActorCollection(
  id: asString(json['actorCollectionId']),
  name: asString(json['actorCollectionName']),
  avatarUrl: asString(json['actorCollectionAvatar']),
  badge: asString(json['badge']),
  trust: asDouble(json['trust']),
  storyPerHour: asDouble(json['storyPerHour']),
  unitPrice: asDouble(json['unitPrice']),
  computingPower: asDouble(json['computingPower']),
);

Map<String, dynamic> _$DramaActorCollectionToJson(
  DramaActorCollection instance,
) => <String, dynamic>{
  'actorCollectionId': instance.id,
  'actorCollectionName': instance.name,
  'actorCollectionAvatar': instance.avatarUrl,
  'badge': instance.badge,
  'trust': instance.trust,
  'storyPerHour': instance.storyPerHour,
  'unitPrice': instance.unitPrice,
  'computingPower': instance.computingPower,
};

DramaListItem _$DramaListItemFromJson(Map<String, dynamic> json) =>
    DramaListItem(
      id: asStringRequired(json['dramaId']),
      episodeId: asString(json['episodeId']),
      episodeNo: asInt(json['episodeNo']),
      dramaTitle: json['dramaTitle'] as String?,
      dramaDescription: json['dramaDescription'] as String?,
      dramaCoverUrl: json['dramaCoverUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      creatorName: json['creatorName'] as String?,
      badge: json['badge'] as String?,
      type: json['type'] as String?,
      durationSec: asInt(json['durationSec']),
      avgRating: asDouble(json['avgRating']),
      totalEpisodes: asInt(json['totalEpisodes']),
      totalPlayCount: asInt(json['totalPlayCount']),
      totalCompletedViewCount: asInt(json['totalCompletedViewCount']),
      totalHeatValue: asDouble(json['totalHeatValue']),
      likeCount: asInt(json['likeCount']),
      favoriteCount: asInt(json['favoriteCount']),
      actorCollections: (json['actorCollections'] as List<dynamic>?)
          ?.map((e) => DramaActorCollection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DramaListItemToJson(DramaListItem instance) =>
    <String, dynamic>{
      'dramaId': instance.id,
      'episodeId': instance.episodeId,
      'episodeNo': instance.episodeNo,
      'dramaTitle': instance.dramaTitle,
      'dramaDescription': instance.dramaDescription,
      'dramaCoverUrl': instance.dramaCoverUrl,
      'tags': instance.tags,
      'creatorName': instance.creatorName,
      'badge': instance.badge,
      'type': instance.type,
      'durationSec': instance.durationSec,
      'avgRating': instance.avgRating,
      'totalEpisodes': instance.totalEpisodes,
      'totalPlayCount': instance.totalPlayCount,
      'totalCompletedViewCount': instance.totalCompletedViewCount,
      'totalHeatValue': instance.totalHeatValue,
      'likeCount': instance.likeCount,
      'favoriteCount': instance.favoriteCount,
      'actorCollections': instance.actorCollections
          ?.map((e) => e.toJson())
          .toList(),
    };

DramaDetail _$DramaDetailFromJson(Map<String, dynamic> json) => DramaDetail(
  id: asString(json['id']),
  userId: asString(json['userId']),
  title: json['title'] as String?,
  description: json['description'] as String?,
  coverUrl: json['coverUrl'] as String?,
  bannerUrl: json['bannerUrl'] as String?,
  freeEps: asInt(json['freeEps']),
  totalEpisodes: asInt(json['totalEpisodes']),
  totalRoles: asInt(json['totalRoles']),
  episodePrice: asDouble(json['episodePrice']),
  batchUnlockDiscountRate: asDouble(json['batchUnlockDiscountRate']),
  dramaCommissionRatio: asDouble(json['dramaCommissionRatio']),
  totalBoundActorNftCount: asInt(json['totalBoundActorNftCount']),
  totalBoundActorRevenueShareRatio: asDouble(
    json['totalBoundActorRevenueShareRatio'],
  ),
  status: json['status'] as String?,
  auditReason: json['auditReason'] as String?,
  onlineAt: asInt(json['onlineAt']),
  offlineAt: asInt(json['offlineAt']),
  nftMinted: asBool(json['nftMinted']),
  nftChain: json['nftChain'] as String?,
  nftTokenStandard: json['nftTokenStandard'] as String?,
  nftContractAddress: json['nftContractAddress'] as String?,
  nftTxHash: json['nftTxHash'] as String?,
  createdAt: asInt(json['createdAt']),
  updatedAt: asInt(json['updatedAt']),
  version: asInt(json['version']),
  unlockedEpsCount: asInt(json['unlockedEpsCount']),
  totalPlayCount: asInt(json['totalPlayCount']),
  totalCompletedViewCount: asInt(json['totalCompletedViewCount']),
  totalHeatValue: asDouble(json['totalHeatValue']),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  creatorName: json['creatorName'] as String?,
  creatorAvatarUrl: json['creatorAvatarUrl'] as String?,
  badge: json['badge'] as String?,
  avgRating: asDouble(json['avgRating']),
  favoriteCount: asInt(json['favoriteCount']),
  favoritedByMe: asBool(json['favoritedByMe']),
  roles: DramaDetail._parseRoles(json['roles'] as List?),
);

Map<String, dynamic> _$DramaDetailToJson(
  DramaDetail instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'title': instance.title,
  'description': instance.description,
  'coverUrl': instance.coverUrl,
  'bannerUrl': instance.bannerUrl,
  'freeEps': instance.freeEps,
  'totalEpisodes': instance.totalEpisodes,
  'totalRoles': instance.totalRoles,
  'episodePrice': instance.episodePrice,
  'batchUnlockDiscountRate': instance.batchUnlockDiscountRate,
  'dramaCommissionRatio': instance.dramaCommissionRatio,
  'totalBoundActorNftCount': instance.totalBoundActorNftCount,
  'totalBoundActorRevenueShareRatio': instance.totalBoundActorRevenueShareRatio,
  'status': instance.status,
  'auditReason': instance.auditReason,
  'onlineAt': instance.onlineAt,
  'offlineAt': instance.offlineAt,
  'nftMinted': instance.nftMinted,
  'nftChain': instance.nftChain,
  'nftTokenStandard': instance.nftTokenStandard,
  'nftContractAddress': instance.nftContractAddress,
  'nftTxHash': instance.nftTxHash,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'version': instance.version,
  'unlockedEpsCount': instance.unlockedEpsCount,
  'totalPlayCount': instance.totalPlayCount,
  'totalCompletedViewCount': instance.totalCompletedViewCount,
  'totalHeatValue': instance.totalHeatValue,
  'tags': instance.tags,
  'creatorName': instance.creatorName,
  'creatorAvatarUrl': instance.creatorAvatarUrl,
  'badge': instance.badge,
  'avgRating': instance.avgRating,
  'favoriteCount': instance.favoriteCount,
  'favoritedByMe': instance.favoritedByMe,
  'roles': DramaDetail._serializeRoles(instance.roles),
};
