import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'episode_model.g.dart';

@JsonSerializable()
class Episode extends Equatable {
  @JsonKey(fromJson: asString)
  final String? id;
  @JsonKey(fromJson: asString)
  final String? dramaId;
  @JsonKey(fromJson: asInt)
  final int? episodeNo;
  final String? title;
  final String? description;
  final String? videoUrl;
  final String? videoMimeType;
  @JsonKey(fromJson: asInt)
  final int? videoSizeBytes;
  final String? transcodeStatus;
  final String? transcodeJobId;
  final String? hlsOutputKey;
  final String? hlsUrl;
  @JsonKey(fromJson: asInt)
  final int? durationSec;
  final String? status;
  @JsonKey(fromJson: asInt)
  final int? createdAt;
  @JsonKey(fromJson: asInt)
  final int? updatedAt;
  @JsonKey(fromJson: asInt)
  final int? version;

  const Episode({
    this.id,
    this.dramaId,
    this.episodeNo,
    this.title,
    this.description,
    this.videoUrl,
    this.videoMimeType,
    this.videoSizeBytes,
    this.transcodeStatus,
    this.transcodeJobId,
    this.hlsOutputKey,
    this.hlsUrl,
    this.durationSec,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.version,
  });

  factory Episode.fromJson(Map<String, dynamic> json) =>
      _$EpisodeFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeToJson(this);

  @override
  List<Object?> get props => [
    id,
    dramaId,
    episodeNo,
    title,
    description,
    videoUrl,
    videoMimeType,
    videoSizeBytes,
    transcodeStatus,
    transcodeJobId,
    hlsOutputKey,
    hlsUrl,
    durationSec,
    status,
    createdAt,
    updatedAt,
    version,
  ];
}
