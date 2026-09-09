import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/video_url_helpers.dart';
import 'drama_model.dart';
import 'json_converters.dart';
import 'work_content_type.dart';

part 'watch_history_model.g.dart';

/// Batch request used to report the user's latest episode watch timestamps.
@JsonSerializable(explicitToJson: true)
class WatchHistoryReportRequest extends Equatable {
  final List<WatchHistoryReportItem> items;

  const WatchHistoryReportRequest({required this.items});

  factory WatchHistoryReportRequest.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryReportRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WatchHistoryReportRequestToJson(this);

  @override
  List<Object?> get props => [items];
}

/// One episode watch timestamp in a [WatchHistoryReportRequest].
@JsonSerializable()
class WatchHistoryReportItem extends Equatable {
  final int episodeId;
  final int watchedAt;

  const WatchHistoryReportItem({
    required this.episodeId,
    required this.watchedAt,
  });

  factory WatchHistoryReportItem.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryReportItemFromJson(json);

  Map<String, dynamic> toJson() => _$WatchHistoryReportItemToJson(this);

  @override
  List<Object?> get props => [episodeId, watchedAt];
}

/// A recent watch-history record for the current user.
@JsonSerializable(explicitToJson: true)
class WatchHistoryItem extends Equatable {
  final String? kind;
  @JsonKey(fromJson: asInt)
  final int? watchedAt;
  final WatchHistoryDrama? drama;
  final WatchHistoryVideo? video;

  const WatchHistoryItem({this.kind, this.watchedAt, this.drama, this.video});

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$WatchHistoryItemToJson(this);

  @override
  List<Object?> get props => [kind, watchedAt, drama, video];
}

/// Drama summary embedded in a watch-history record.
@JsonSerializable(explicitToJson: true)
class WatchHistoryDrama extends Equatable {
  @JsonKey(fromJson: asString)
  final String? dramaId;
  final String? dramaTitle;
  final String? dramaCoverUrl;
  @JsonKey(fromJson: asInt)
  final int? totalEpisodes;
  final String? badge;
  final List<DramaActorCollection> actorCollections;
  @JsonKey(fromJson: asString)
  final String? lastEpisodeId;
  @JsonKey(fromJson: asInt)
  final int? lastEpisodeNo;
  final String? watchProgressText;

  const WatchHistoryDrama({
    this.dramaId,
    this.dramaTitle,
    this.dramaCoverUrl,
    this.totalEpisodes,
    this.badge,
    this.actorCollections = const [],
    this.lastEpisodeId,
    this.lastEpisodeNo,
    this.watchProgressText,
  });

  factory WatchHistoryDrama.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryDramaFromJson(json);

  Map<String, dynamic> toJson() => _$WatchHistoryDramaToJson(this);

  @override
  List<Object?> get props => [
    dramaId,
    dramaTitle,
    dramaCoverUrl,
    totalEpisodes,
    badge,
    actorCollections,
    lastEpisodeId,
    lastEpisodeNo,
    watchProgressText,
  ];
}

/// Last-watched work embedded in a watch-history record.
@JsonSerializable()
class WatchHistoryVideo extends Equatable {
  @JsonKey(fromJson: asString)
  final String? episodeId;
  @JsonKey(fromJson: asString)
  final String? dramaId;
  @JsonKey(fromJson: asInt)
  final int? episodeNo;
  @JsonKey(fromJson: _contentTypeFromJson, toJson: _contentTypeToJson)
  final WorkContentType contentType;
  final String? title;
  final String? coverUrl;

  /// Transcoded t=0 still — independent from [coverUrl].
  final String? firstFrameUrl;
  final String? description;
  @JsonKey(fromJson: asInt)
  final int? likeCount;

  const WatchHistoryVideo({
    this.episodeId,
    this.dramaId,
    this.episodeNo,
    this.contentType = WorkContentType.shortDrama,
    this.title,
    this.coverUrl,
    this.firstFrameUrl,
    this.description,
    this.likeCount,
  });

  factory WatchHistoryVideo.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryVideoFromJson(json);

  Map<String, dynamic> toJson() => _$WatchHistoryVideoToJson(this);

  /// Poster for list chrome: [firstFrameUrl] then [coverUrl].
  String? get posterUrl => VideoUrlHelpers.preferPosterUrl(
    firstFrameUrl: firstFrameUrl,
    coverUrl: coverUrl,
  );

  @override
  List<Object?> get props => [
    episodeId,
    dramaId,
    episodeNo,
    contentType,
    title,
    coverUrl,
    firstFrameUrl,
    description,
    likeCount,
  ];
}

WorkContentType _contentTypeFromJson(dynamic value) =>
    WorkContentType.fromApi(asString(value));

String _contentTypeToJson(WorkContentType value) => value.apiValue;
