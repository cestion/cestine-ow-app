// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchHistoryReportRequest _$WatchHistoryReportRequestFromJson(
  Map<String, dynamic> json,
) => WatchHistoryReportRequest(
  items: (json['items'] as List<dynamic>)
      .map((e) => WatchHistoryReportItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WatchHistoryReportRequestToJson(
  WatchHistoryReportRequest instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

WatchHistoryReportItem _$WatchHistoryReportItemFromJson(
  Map<String, dynamic> json,
) => WatchHistoryReportItem(
  episodeId: (json['episodeId'] as num).toInt(),
  watchedAt: (json['watchedAt'] as num).toInt(),
);

Map<String, dynamic> _$WatchHistoryReportItemToJson(
  WatchHistoryReportItem instance,
) => <String, dynamic>{
  'episodeId': instance.episodeId,
  'watchedAt': instance.watchedAt,
};

WatchHistoryItem _$WatchHistoryItemFromJson(Map<String, dynamic> json) =>
    WatchHistoryItem(
      kind: json['kind'] as String?,
      watchedAt: asInt(json['watchedAt']),
      drama: json['drama'] == null
          ? null
          : WatchHistoryDrama.fromJson(json['drama'] as Map<String, dynamic>),
      video: json['video'] == null
          ? null
          : WatchHistoryVideo.fromJson(json['video'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WatchHistoryItemToJson(WatchHistoryItem instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'watchedAt': instance.watchedAt,
      'drama': instance.drama?.toJson(),
      'video': instance.video?.toJson(),
    };

WatchHistoryDrama _$WatchHistoryDramaFromJson(Map<String, dynamic> json) =>
    WatchHistoryDrama(
      dramaId: asString(json['dramaId']),
      dramaTitle: json['dramaTitle'] as String?,
      dramaCoverUrl: json['dramaCoverUrl'] as String?,
      totalEpisodes: asInt(json['totalEpisodes']),
      badge: json['badge'] as String?,
      actorCollections:
          (json['actorCollections'] as List<dynamic>?)
              ?.map(
                (e) => DramaActorCollection.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      lastEpisodeId: asString(json['lastEpisodeId']),
      lastEpisodeNo: asInt(json['lastEpisodeNo']),
      watchProgressText: json['watchProgressText'] as String?,
    );

Map<String, dynamic> _$WatchHistoryDramaToJson(
  WatchHistoryDrama instance,
) => <String, dynamic>{
  'dramaId': instance.dramaId,
  'dramaTitle': instance.dramaTitle,
  'dramaCoverUrl': instance.dramaCoverUrl,
  'totalEpisodes': instance.totalEpisodes,
  'badge': instance.badge,
  'actorCollections': instance.actorCollections.map((e) => e.toJson()).toList(),
  'lastEpisodeId': instance.lastEpisodeId,
  'lastEpisodeNo': instance.lastEpisodeNo,
  'watchProgressText': instance.watchProgressText,
};

WatchHistoryVideo _$WatchHistoryVideoFromJson(Map<String, dynamic> json) =>
    WatchHistoryVideo(
      episodeId: asString(json['episodeId']),
      dramaId: asString(json['dramaId']),
      episodeNo: asInt(json['episodeNo']),
      contentType: json['contentType'] == null
          ? WorkContentType.shortDrama
          : _contentTypeFromJson(json['contentType']),
      title: json['title'] as String?,
      coverUrl: json['coverUrl'] as String?,
      firstFrameUrl: json['firstFrameUrl'] as String?,
      description: json['description'] as String?,
      likeCount: asInt(json['likeCount']),
    );

Map<String, dynamic> _$WatchHistoryVideoToJson(WatchHistoryVideo instance) =>
    <String, dynamic>{
      'episodeId': instance.episodeId,
      'dramaId': instance.dramaId,
      'episodeNo': instance.episodeNo,
      'contentType': _contentTypeToJson(instance.contentType),
      'title': instance.title,
      'coverUrl': instance.coverUrl,
      'firstFrameUrl': instance.firstFrameUrl,
      'description': instance.description,
      'likeCount': instance.likeCount,
    };
