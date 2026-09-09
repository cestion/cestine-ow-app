// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drama_play_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DramaPlayResponse _$DramaPlayResponseFromJson(Map<String, dynamic> json) =>
    DramaPlayResponse(
      dramaId: asString(json['dramaId']),
      episodeId: asString(json['episodeId']),
      episodeNo: asInt(json['episodeNo']),
      title: json['title'] as String?,
      description: json['description'] as String?,
      mediaAccessUrl: asPreferredPlayUrl(json['mediaAccessUrl']),
      playbackType: json['playbackType'] as String?,
      videoUrl: asPreferredPlayUrl(json['videoUrl']),
      hlsUrl: asPreferredPlayUrl(json['hlsUrl']),
      signedCookies: DramaPlayResponse._signedCookiesFromJson(
        json['signedCookies'],
      ),
      likeCount: asInt(json['likeCount']),
      commentCount: asInt(json['commentCount']),
      favoriteCount: asInt(json['favoriteCount']),
      favoritedByMe: asBool(json['favoritedByMe']),
      likedByMe: asBool(json['likedByMe']),
      userId: asString(json['userId']),
      creatorId: asString(json['creatorId']),
      creatorName: json['creatorName'] as String?,
      creatorAvatarUrl: json['creatorAvatarUrl'] as String?,
      coverUrl: asString(json['coverUrl']),
      firstFrameUrl: asString(json['firstFrameUrl']),
    );

Map<String, dynamic> _$DramaPlayResponseToJson(DramaPlayResponse instance) =>
    <String, dynamic>{
      'dramaId': instance.dramaId,
      'episodeId': instance.episodeId,
      'episodeNo': instance.episodeNo,
      'title': instance.title,
      'description': instance.description,
      'mediaAccessUrl': instance.mediaAccessUrl,
      'playbackType': instance.playbackType,
      'videoUrl': instance.videoUrl,
      'hlsUrl': instance.hlsUrl,
      'signedCookies': instance.signedCookies?.toJson(),
      'likeCount': instance.likeCount,
      'commentCount': instance.commentCount,
      'favoriteCount': instance.favoriteCount,
      'favoritedByMe': instance.favoritedByMe,
      'likedByMe': instance.likedByMe,
      'userId': instance.userId,
      'creatorId': instance.creatorId,
      'creatorName': instance.creatorName,
      'creatorAvatarUrl': instance.creatorAvatarUrl,
      'coverUrl': instance.coverUrl,
      'firstFrameUrl': instance.firstFrameUrl,
    };
