// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'short_video_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublishShortVideoRequest _$PublishShortVideoRequestFromJson(
  Map<String, dynamic> json,
) => PublishShortVideoRequest(
  uploadSessionId: _shortVideoInt(json['uploadSessionId']),
  videoObjectKey: _shortVideoString(json['videoObjectKey']),
  coverObjectKey: _shortVideoString(json['coverObjectKey']),
  title: _shortVideoString(json['title']),
  description: _shortVideoString(json['description']),
  durationSec: _shortVideoInt(json['durationSec']),
  width: _shortVideoInt(json['width']),
  height: _shortVideoInt(json['height']),
);

Map<String, dynamic> _$PublishShortVideoRequestToJson(
  PublishShortVideoRequest instance,
) => <String, dynamic>{
  'uploadSessionId': instance.uploadSessionId,
  'videoObjectKey': instance.videoObjectKey,
  'coverObjectKey': instance.coverObjectKey,
  'title': instance.title,
  'description': instance.description,
  'durationSec': instance.durationSec,
  'width': instance.width,
  'height': instance.height,
};

EditShortVideoRequest _$EditShortVideoRequestFromJson(
  Map<String, dynamic> json,
) => EditShortVideoRequest(
  uploadSessionId: _shortVideoInt(json['uploadSessionId']),
  title: _shortVideoString(json['title']),
  description: _shortVideoString(json['description']),
  coverObjectKey: _shortVideoString(json['coverObjectKey']),
);

Map<String, dynamic> _$EditShortVideoRequestToJson(
  EditShortVideoRequest instance,
) => <String, dynamic>{
  'uploadSessionId': instance.uploadSessionId,
  'title': instance.title,
  'description': instance.description,
  'coverObjectKey': instance.coverObjectKey,
};

ShortVideoEditSession _$ShortVideoEditSessionFromJson(
  Map<String, dynamic> json,
) => ShortVideoEditSession(
  uploadSessionId: _shortVideoInt(json['uploadSessionId']),
  uploadExpireSeconds: _shortVideoInt(json['uploadExpireSeconds']),
  episodeId: _shortVideoInt(json['episodeId']),
  userId: _shortVideoInt(json['userId']),
  title: _shortVideoString(json['title']),
  description: _shortVideoString(json['description']),
  coverUrl: _shortVideoString(json['coverUrl']),
  firstFrameUrl: asString(json['firstFrameUrl']),
  videoUrl: _shortVideoString(json['videoUrl']),
  videoSizeBytes: _shortVideoInt(json['videoSizeBytes']),
  transcodeStatus: _shortVideoString(json['transcodeStatus']),
  durationSec: _shortVideoInt(json['durationSec']),
  width: _shortVideoInt(json['width']),
  height: _shortVideoInt(json['height']),
  status: _shortVideoString(json['status']),
);

Map<String, dynamic> _$ShortVideoEditSessionToJson(
  ShortVideoEditSession instance,
) => <String, dynamic>{
  'uploadSessionId': instance.uploadSessionId,
  'uploadExpireSeconds': instance.uploadExpireSeconds,
  'episodeId': instance.episodeId,
  'userId': instance.userId,
  'title': instance.title,
  'description': instance.description,
  'coverUrl': instance.coverUrl,
  'firstFrameUrl': instance.firstFrameUrl,
  'videoUrl': instance.videoUrl,
  'videoSizeBytes': instance.videoSizeBytes,
  'transcodeStatus': instance.transcodeStatus,
  'durationSec': instance.durationSec,
  'width': instance.width,
  'height': instance.height,
  'status': instance.status,
};

CreatorShortVideo _$CreatorShortVideoFromJson(Map<String, dynamic> json) =>
    CreatorShortVideo(
      episodeId: _shortVideoInt(json['episodeId']),
      userId: _shortVideoInt(json['userId']),
      collectionId: _shortVideoInt(json['collectionId']),
      title: _shortVideoString(json['title']),
      description: _shortVideoString(json['description']),
      coverUrl: _shortVideoString(json['coverUrl']),
      firstFrameUrl: asString(json['firstFrameUrl']),
      videoUrl: _shortVideoString(json['videoUrl']),
      status: _shortVideoString(json['status']),
      auditReason: json['auditReason'] as String?,
      durationSec: _shortVideoInt(json['durationSec']),
      playCount: _shortVideoInt(json['playCount']),
      likeCount: _shortVideoInt(json['likeCount']),
      commentCount: _shortVideoInt(json['commentCount']),
      favoriteCount: asInt(json['favoriteCount']),
      createdAt: _shortVideoInt(json['createdAt']),
    );

Map<String, dynamic> _$CreatorShortVideoToJson(CreatorShortVideo instance) =>
    <String, dynamic>{
      'episodeId': instance.episodeId,
      'userId': instance.userId,
      'collectionId': instance.collectionId,
      'title': instance.title,
      'description': instance.description,
      'coverUrl': instance.coverUrl,
      'firstFrameUrl': instance.firstFrameUrl,
      'videoUrl': instance.videoUrl,
      'status': instance.status,
      'auditReason': instance.auditReason,
      'durationSec': instance.durationSec,
      'playCount': instance.playCount,
      'likeCount': instance.likeCount,
      'commentCount': instance.commentCount,
      'favoriteCount': instance.favoriteCount,
      'createdAt': instance.createdAt,
    };

ShortVideo _$ShortVideoFromJson(Map<String, dynamic> json) => ShortVideo(
  id: _shortVideoInt(json['id']),
  dramaId: _shortVideoInt(json['dramaId']),
  type: _shortVideoString(json['type']),
  episodeNo: _shortVideoInt(json['episodeNo']),
  title: _shortVideoString(json['title']),
  description: _shortVideoString(json['description']),
  coverUrl: _shortVideoString(json['coverUrl']),
  firstFrameUrl: asString(json['firstFrameUrl']),
  videoUrl: _shortVideoString(json['videoUrl']),
  videoMimeType: _shortVideoString(json['videoMimeType']),
  videoSizeBytes: _shortVideoInt(json['videoSizeBytes']),
  transcodeStatus: _shortVideoString(json['transcodeStatus']),
  transcodeJobId: _shortVideoString(json['transcodeJobId']),
  hlsOutputKey: _shortVideoString(json['hlsOutputKey']),
  hlsUrl: _shortVideoString(json['hlsUrl']),
  durationSec: _shortVideoInt(json['durationSec']),
  width: _shortVideoInt(json['width']),
  height: _shortVideoInt(json['height']),
  status: _shortVideoString(json['status']),
  createdAt: _shortVideoInt(json['createdAt']),
  updatedAt: _shortVideoInt(json['updatedAt']),
  version: _shortVideoInt(json['version']),
);

Map<String, dynamic> _$ShortVideoToJson(ShortVideo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dramaId': instance.dramaId,
      'type': instance.type,
      'episodeNo': instance.episodeNo,
      'title': instance.title,
      'description': instance.description,
      'coverUrl': instance.coverUrl,
      'firstFrameUrl': instance.firstFrameUrl,
      'videoUrl': instance.videoUrl,
      'videoMimeType': instance.videoMimeType,
      'videoSizeBytes': instance.videoSizeBytes,
      'transcodeStatus': instance.transcodeStatus,
      'transcodeJobId': instance.transcodeJobId,
      'hlsOutputKey': instance.hlsOutputKey,
      'hlsUrl': instance.hlsUrl,
      'durationSec': instance.durationSec,
      'width': instance.width,
      'height': instance.height,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'version': instance.version,
    };
