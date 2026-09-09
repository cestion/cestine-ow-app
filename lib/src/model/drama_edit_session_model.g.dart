// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drama_edit_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EditSessionEpisode _$EditSessionEpisodeFromJson(Map<String, dynamic> json) =>
    EditSessionEpisode(
      id: asString(json['id']),
      episodeNo: (json['episodeNo'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      videoUrl: json['videoUrl'] as String?,
      videoSizeBytes: asInt(json['videoSizeBytes']),
      durationSec: (json['durationSec'] as num).toInt(),
      hlsOutputKey: json['hlsOutputKey'] as String?,
      hlsUrl: json['hlsUrl'] as String?,
    );

Map<String, dynamic> _$EditSessionEpisodeToJson(EditSessionEpisode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'episodeNo': instance.episodeNo,
      'title': instance.title,
      'description': instance.description,
      'videoUrl': instance.videoUrl,
      'videoSizeBytes': instance.videoSizeBytes,
      'durationSec': instance.durationSec,
      'hlsOutputKey': instance.hlsOutputKey,
      'hlsUrl': instance.hlsUrl,
    };

EditSessionActorCollection _$EditSessionActorCollectionFromJson(
  Map<String, dynamic> json,
) => EditSessionActorCollection(
  actorCollectionId: asString(json['actorCollectionId']),
  assetId: asString(json['assetId']),
  name: json['name'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  trust: asDouble(json['trust']),
  computingPower: asDouble(json['computingPower']),
);

Map<String, dynamic> _$EditSessionActorCollectionToJson(
  EditSessionActorCollection instance,
) => <String, dynamic>{
  'actorCollectionId': instance.actorCollectionId,
  'assetId': instance.assetId,
  'name': instance.name,
  'avatarUrl': instance.avatarUrl,
  'trust': instance.trust,
  'computingPower': instance.computingPower,
};

DramaEditSession _$DramaEditSessionFromJson(Map<String, dynamic> json) =>
    DramaEditSession(
      uploadSessionId: asString(json['uploadSessionId']),
      uploadExpireSeconds: asInt(json['uploadExpireSeconds']),
      dramaId: asString(json['dramaId']),
      userId: asString(json['userId']),
      title: json['title'] as String?,
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      onlineAt: asInt(json['onlineAt']),
      tagIds: _asStringList(json['tagIds']),
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => EditSessionEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
      actorCollections: (json['actorCollections'] as List<dynamic>?)
          ?.map(
            (e) =>
                EditSessionActorCollection.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$DramaEditSessionToJson(DramaEditSession instance) =>
    <String, dynamic>{
      'uploadSessionId': instance.uploadSessionId,
      'uploadExpireSeconds': instance.uploadExpireSeconds,
      'dramaId': instance.dramaId,
      'userId': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'coverUrl': instance.coverUrl,
      'onlineAt': instance.onlineAt,
      'tagIds': instance.tagIds,
      'episodes': instance.episodes,
      'actorCollections': instance.actorCollections,
    };
