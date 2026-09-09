// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Episode _$EpisodeFromJson(Map<String, dynamic> json) => Episode(
  id: asString(json['id']),
  dramaId: asString(json['dramaId']),
  episodeNo: asInt(json['episodeNo']),
  title: json['title'] as String?,
  description: json['description'] as String?,
  videoUrl: json['videoUrl'] as String?,
  videoMimeType: json['videoMimeType'] as String?,
  videoSizeBytes: asInt(json['videoSizeBytes']),
  transcodeStatus: json['transcodeStatus'] as String?,
  transcodeJobId: json['transcodeJobId'] as String?,
  hlsOutputKey: json['hlsOutputKey'] as String?,
  hlsUrl: json['hlsUrl'] as String?,
  durationSec: asInt(json['durationSec']),
  status: json['status'] as String?,
  createdAt: asInt(json['createdAt']),
  updatedAt: asInt(json['updatedAt']),
  version: asInt(json['version']),
);

Map<String, dynamic> _$EpisodeToJson(Episode instance) => <String, dynamic>{
  'id': instance.id,
  'dramaId': instance.dramaId,
  'episodeNo': instance.episodeNo,
  'title': instance.title,
  'description': instance.description,
  'videoUrl': instance.videoUrl,
  'videoMimeType': instance.videoMimeType,
  'videoSizeBytes': instance.videoSizeBytes,
  'transcodeStatus': instance.transcodeStatus,
  'transcodeJobId': instance.transcodeJobId,
  'hlsOutputKey': instance.hlsOutputKey,
  'hlsUrl': instance.hlsUrl,
  'durationSec': instance.durationSec,
  'status': instance.status,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'version': instance.version,
};
