// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_drama_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateEpisodeRequest _$CreateEpisodeRequestFromJson(
  Map<String, dynamic> json,
) => CreateEpisodeRequest(
  durationSec: (json['durationSec'] as num).toInt(),
  description: json['description'] as String,
  episodeNo: (json['episodeNo'] as num).toInt(),
  title: json['title'] as String,
  videoObjectKey: json['videoObjectKey'] as String,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
);

Map<String, dynamic> _$CreateEpisodeRequestToJson(
  CreateEpisodeRequest instance,
) => <String, dynamic>{
  'durationSec': instance.durationSec,
  'description': instance.description,
  'episodeNo': instance.episodeNo,
  'title': instance.title,
  'videoObjectKey': instance.videoObjectKey,
  'width': instance.width,
  'height': instance.height,
};

CreateDramaRequest _$CreateDramaRequestFromJson(Map<String, dynamic> json) =>
    CreateDramaRequest(
      coverObjectKey: json['coverObjectKey'] as String,
      description: json['description'] as String,
      episodes: (json['episodes'] as List<dynamic>)
          .map((e) => CreateEpisodeRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      actorCollectionIds: (json['actorCollectionIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tagIds: (json['tagIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      title: json['title'] as String,
      uploadSessionId: json['uploadSessionId'] as String,
    );

Map<String, dynamic> _$CreateDramaRequestToJson(CreateDramaRequest instance) =>
    <String, dynamic>{
      'coverObjectKey': instance.coverObjectKey,
      'description': instance.description,
      'episodes': instance.episodes,
      'actorCollectionIds': ?instance.actorCollectionIds,
      'tagIds': instance.tagIds,
      'title': instance.title,
      'uploadSessionId': instance.uploadSessionId,
    };
