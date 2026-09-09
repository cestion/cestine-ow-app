// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drama_edit_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DramaEditRequest _$DramaEditRequestFromJson(Map<String, dynamic> json) =>
    DramaEditRequest(
      uploadSessionId: json['uploadSessionId'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      coverObjectKey: json['coverObjectKey'] as String?,
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => DramaEditEpisodeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      actorCollectionChanges: json['actorCollectionChanges'] == null
          ? null
          : ActorCollectionChanges.fromJson(
              json['actorCollectionChanges'] as Map<String, dynamic>,
            ),
      tagIds: (json['tagIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$DramaEditRequestToJson(DramaEditRequest instance) =>
    <String, dynamic>{
      'uploadSessionId': ?instance.uploadSessionId,
      'title': ?instance.title,
      'description': ?instance.description,
      'coverObjectKey': ?instance.coverObjectKey,
      'episodes': ?instance.episodes?.map((e) => e.toJson()).toList(),
      'actorCollectionChanges': ?instance.actorCollectionChanges?.toJson(),
      'tagIds': ?instance.tagIds,
    };

DramaEditEpisodeItem _$DramaEditEpisodeItemFromJson(
  Map<String, dynamic> json,
) => DramaEditEpisodeItem(
  id: json['id'] as String?,
  episodeNo: (json['episodeNo'] as num?)?.toInt(),
  title: json['title'] as String?,
  description: json['description'] as String?,
  videoObjectKey: json['videoObjectKey'] as String?,
  durationSec: (json['durationSec'] as num?)?.toInt(),
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
);

Map<String, dynamic> _$DramaEditEpisodeItemToJson(
  DramaEditEpisodeItem instance,
) => <String, dynamic>{
  'id': ?instance.id,
  'episodeNo': ?instance.episodeNo,
  'title': ?instance.title,
  'description': ?instance.description,
  'videoObjectKey': ?instance.videoObjectKey,
  'durationSec': ?instance.durationSec,
  'width': ?instance.width,
  'height': ?instance.height,
};

ActorCollectionChanges _$ActorCollectionChangesFromJson(
  Map<String, dynamic> json,
) => ActorCollectionChanges(
  add: (json['add'] as List<dynamic>?)?.map((e) => e as String).toList(),
  delete: (json['delete'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$ActorCollectionChangesToJson(
  ActorCollectionChanges instance,
) => <String, dynamic>{'add': ?instance.add, 'delete': ?instance.delete};
