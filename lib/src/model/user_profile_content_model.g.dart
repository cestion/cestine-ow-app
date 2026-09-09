// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_content_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileContentDrama _$UserProfileContentDramaFromJson(
  Map<String, dynamic> json,
) => UserProfileContentDrama(
  id: asStringRequired(json['dramaId']),
  title: asString(json['title']),
  description: asString(json['description']),
  coverUrl: asString(json['coverUrl']),
  contentType: asString(json['contentType']),
  tags: _stringListFromJson(json['tags']),
  totalEpisodes: asInt(json['totalEpisodes']),
  badge: asString(json['badge']),
  actorCollections: (json['actorCollections'] as List<dynamic>?)
      ?.map((e) => DramaActorCollection.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalPlayCount: asInt(json['totalPlayCount']),
  totalCompletedViewCount: asInt(json['totalCompletedViewCount']),
  totalFavoriteCount: asInt(json['totalFavoriteCount']),
  totalHeatValue: asDouble(json['totalHeatValue']),
  avgRating: asDouble(json['avgRating']),
);

Map<String, dynamic> _$UserProfileContentDramaToJson(
  UserProfileContentDrama instance,
) => <String, dynamic>{
  'dramaId': instance.id,
  'title': instance.title,
  'description': instance.description,
  'coverUrl': instance.coverUrl,
  'contentType': instance.contentType,
  'tags': instance.tags,
  'totalEpisodes': instance.totalEpisodes,
  'badge': instance.badge,
  'actorCollections': instance.actorCollections
      ?.map((e) => e.toJson())
      .toList(),
  'totalPlayCount': instance.totalPlayCount,
  'totalCompletedViewCount': instance.totalCompletedViewCount,
  'totalFavoriteCount': instance.totalFavoriteCount,
  'totalHeatValue': instance.totalHeatValue,
  'avgRating': instance.avgRating,
};

UserProfileContentEpisode _$UserProfileContentEpisodeFromJson(
  Map<String, dynamic> json,
) => UserProfileContentEpisode(
  id: asStringRequired(json['episodeId']),
  episodeNo: asInt(json['episodeNo']),
  contentType: asString(json['contentType']),
  durationSec: asInt(json['durationSec']),
  title: asString(json['title']),
  description: asString(json['description']),
  coverUrl: asString(json['coverUrl']),
  firstFrameUrl: asString(json['firstFrameUrl']),
  playCount: asInt(json['playCount']),
  completeCount: asInt(json['completeCount']),
  likeCount: asInt(json['likeCount']),
  commentCount: asInt(json['commentCount']),
  favoriteCount: asInt(json['favoriteCount']),
);

Map<String, dynamic> _$UserProfileContentEpisodeToJson(
  UserProfileContentEpisode instance,
) => <String, dynamic>{
  'episodeId': instance.id,
  'episodeNo': instance.episodeNo,
  'contentType': instance.contentType,
  'durationSec': instance.durationSec,
  'title': instance.title,
  'description': instance.description,
  'coverUrl': instance.coverUrl,
  'firstFrameUrl': instance.firstFrameUrl,
  'playCount': instance.playCount,
  'completeCount': instance.completeCount,
  'likeCount': instance.likeCount,
  'commentCount': instance.commentCount,
  'favoriteCount': instance.favoriteCount,
};

UserProfileContentItem _$UserProfileContentItemFromJson(
  Map<String, dynamic> json,
) => UserProfileContentItem(
  userId: asString(json['userId']),
  creatorName: asString(json['creatorName']),
  creatorAvatarUrl: asString(json['creatorAvatarUrl']),
  likedByMe: asBool(json['likedByMe']),
  favoritedByMe: asBool(json['favoritedByMe']),
  followedByMe: asBool(json['followedByMe']),
  actionTime: asInt(json['actionTime']),
  type: asString(json['type']),
  drama: json['drama'] == null
      ? null
      : UserProfileContentDrama.fromJson(json['drama'] as Map<String, dynamic>),
  episode: json['episode'] == null
      ? null
      : UserProfileContentEpisode.fromJson(
          json['episode'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$UserProfileContentItemToJson(
  UserProfileContentItem instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'creatorName': instance.creatorName,
  'creatorAvatarUrl': instance.creatorAvatarUrl,
  'likedByMe': instance.likedByMe,
  'favoritedByMe': instance.favoritedByMe,
  'followedByMe': instance.followedByMe,
  'actionTime': instance.actionTime,
  'type': instance.type,
  'drama': instance.drama?.toJson(),
  'episode': instance.episode?.toJson(),
};
