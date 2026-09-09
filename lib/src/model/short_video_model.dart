import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/video_url_helpers.dart';
import 'json_converters.dart';

part 'short_video_model.g.dart';

int _shortVideoInt(dynamic value) => asInt(value) ?? 0;

String _shortVideoString(dynamic value) => asString(value) ?? '';

/// 发布短视频请求体。
///
/// 对应 `POST /api/mini-drama/creator/short-videos`。
@JsonSerializable()
class PublishShortVideoRequest extends Equatable {
  @JsonKey(fromJson: _shortVideoInt)
  final int uploadSessionId;
  @JsonKey(fromJson: _shortVideoString)
  final String videoObjectKey;
  @JsonKey(fromJson: _shortVideoString)
  final String coverObjectKey;
  @JsonKey(fromJson: _shortVideoString)
  final String title;
  @JsonKey(fromJson: _shortVideoString)
  final String description;
  @JsonKey(fromJson: _shortVideoInt)
  final int durationSec;
  @JsonKey(fromJson: _shortVideoInt)
  final int width;
  @JsonKey(fromJson: _shortVideoInt)
  final int height;

  const PublishShortVideoRequest({
    required this.uploadSessionId,
    required this.videoObjectKey,
    required this.coverObjectKey,
    required this.title,
    required this.description,
    required this.durationSec,
    required this.width,
    required this.height,
  });

  factory PublishShortVideoRequest.fromJson(Map<String, dynamic> json) =>
      _$PublishShortVideoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PublishShortVideoRequestToJson(this);

  @override
  List<Object?> get props => [
    uploadSessionId,
    videoObjectKey,
    coverObjectKey,
    title,
    description,
    durationSec,
    width,
    height,
  ];
}

/// 编辑短视频请求体。
///
/// 对应 `PUT /api/mini-drama/creator/short-videos/{episodeId}`。
@JsonSerializable()
class EditShortVideoRequest extends Equatable {
  @JsonKey(fromJson: _shortVideoInt)
  final int uploadSessionId;
  @JsonKey(fromJson: _shortVideoString)
  final String title;
  @JsonKey(fromJson: _shortVideoString)
  final String description;
  @JsonKey(fromJson: _shortVideoString)
  final String coverObjectKey;

  const EditShortVideoRequest({
    required this.uploadSessionId,
    required this.title,
    required this.description,
    required this.coverObjectKey,
  });

  factory EditShortVideoRequest.fromJson(Map<String, dynamic> json) =>
      _$EditShortVideoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EditShortVideoRequestToJson(this);

  @override
  List<Object?> get props => [
    uploadSessionId,
    title,
    description,
    coverObjectKey,
  ];
}

/// 短视频编辑会话，包含编辑页回显及上传会话信息。
///
/// 对应 `GET /api/mini-drama/creator/short-videos/{episodeId}/edit-sessions`。
@JsonSerializable()
class ShortVideoEditSession extends Equatable {
  @JsonKey(fromJson: _shortVideoInt)
  final int uploadSessionId;
  @JsonKey(fromJson: _shortVideoInt)
  final int uploadExpireSeconds;
  @JsonKey(fromJson: _shortVideoInt)
  final int episodeId;
  @JsonKey(fromJson: _shortVideoInt)
  final int userId;
  @JsonKey(fromJson: _shortVideoString)
  final String title;
  @JsonKey(fromJson: _shortVideoString)
  final String description;
  @JsonKey(fromJson: _shortVideoString)
  final String coverUrl;

  /// Transcoded t=0 still — independent from [coverUrl].
  @JsonKey(fromJson: asString)
  final String? firstFrameUrl;
  @JsonKey(fromJson: _shortVideoString)
  final String videoUrl;
  @JsonKey(fromJson: _shortVideoInt)
  final int videoSizeBytes;
  @JsonKey(fromJson: _shortVideoString)
  final String transcodeStatus;
  @JsonKey(fromJson: _shortVideoInt)
  final int durationSec;
  @JsonKey(fromJson: _shortVideoInt)
  final int width;
  @JsonKey(fromJson: _shortVideoInt)
  final int height;
  @JsonKey(fromJson: _shortVideoString)
  final String status;

  const ShortVideoEditSession({
    required this.uploadSessionId,
    required this.uploadExpireSeconds,
    required this.episodeId,
    required this.userId,
    required this.title,
    required this.description,
    required this.coverUrl,
    this.firstFrameUrl,
    required this.videoUrl,
    required this.videoSizeBytes,
    required this.transcodeStatus,
    required this.durationSec,
    required this.width,
    required this.height,
    required this.status,
  });

  factory ShortVideoEditSession.fromJson(Map<String, dynamic> json) =>
      _$ShortVideoEditSessionFromJson(json);

  Map<String, dynamic> toJson() => _$ShortVideoEditSessionToJson(this);

  String? get posterUrl => VideoUrlHelpers.preferPosterUrl(
    firstFrameUrl: firstFrameUrl,
    coverUrl: coverUrl,
  );

  @override
  List<Object?> get props => [
    uploadSessionId,
    uploadExpireSeconds,
    episodeId,
    userId,
    title,
    description,
    coverUrl,
    firstFrameUrl,
    videoUrl,
    videoSizeBytes,
    transcodeStatus,
    durationSec,
    width,
    height,
    status,
  ];
}

/// 创作者短视频列表项。
///
/// 对应 `GET /api/mini-drama/creator/short-videos` 响应中的 `list` 项。
@JsonSerializable()
class CreatorShortVideo extends Equatable {
  @JsonKey(fromJson: _shortVideoInt)
  final int episodeId;
  @JsonKey(fromJson: _shortVideoInt)
  final int userId;
  @JsonKey(fromJson: _shortVideoInt)
  final int collectionId;
  @JsonKey(fromJson: _shortVideoString)
  final String title;
  @JsonKey(fromJson: _shortVideoString)
  final String description;
  @JsonKey(fromJson: _shortVideoString)
  final String coverUrl;

  /// Transcoded t=0 still — independent from [coverUrl].
  @JsonKey(fromJson: asString)
  final String? firstFrameUrl;
  @JsonKey(fromJson: _shortVideoString)
  final String videoUrl;
  @JsonKey(fromJson: _shortVideoString)
  final String status;
  final String? auditReason;
  @JsonKey(fromJson: _shortVideoInt)
  final int durationSec;
  @JsonKey(fromJson: _shortVideoInt)
  final int playCount;
  @JsonKey(fromJson: _shortVideoInt)
  final int likeCount;
  @JsonKey(fromJson: _shortVideoInt)
  final int commentCount;
  @JsonKey(fromJson: asInt)
  final int? favoriteCount;
  @JsonKey(fromJson: _shortVideoInt)
  final int createdAt;

  const CreatorShortVideo({
    required this.episodeId,
    required this.userId,
    required this.collectionId,
    required this.title,
    required this.description,
    required this.coverUrl,
    this.firstFrameUrl,
    required this.videoUrl,
    required this.status,
    this.auditReason,
    required this.durationSec,
    required this.playCount,
    required this.likeCount,
    required this.commentCount,
    this.favoriteCount,
    required this.createdAt,
  });

  factory CreatorShortVideo.fromJson(Map<String, dynamic> json) =>
      _$CreatorShortVideoFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorShortVideoToJson(this);

  String? get posterUrl => VideoUrlHelpers.preferPosterUrl(
    firstFrameUrl: firstFrameUrl,
    coverUrl: coverUrl,
  );

  @override
  List<Object?> get props => [
    episodeId,
    userId,
    collectionId,
    title,
    description,
    coverUrl,
    firstFrameUrl,
    videoUrl,
    status,
    auditReason,
    durationSec,
    playCount,
    likeCount,
    commentCount,
    favoriteCount,
    createdAt,
  ];
}

/// 已发布的短视频信息。
@JsonSerializable()
class ShortVideo extends Equatable {
  @JsonKey(fromJson: _shortVideoInt)
  final int id;
  @JsonKey(fromJson: _shortVideoInt)
  final int dramaId;
  @JsonKey(fromJson: _shortVideoString)
  final String type;
  @JsonKey(fromJson: _shortVideoInt)
  final int episodeNo;
  @JsonKey(fromJson: _shortVideoString)
  final String title;
  @JsonKey(fromJson: _shortVideoString)
  final String description;
  @JsonKey(fromJson: _shortVideoString)
  final String coverUrl;

  /// Transcoded t=0 still — independent from [coverUrl].
  @JsonKey(fromJson: asString)
  final String? firstFrameUrl;
  @JsonKey(fromJson: _shortVideoString)
  final String videoUrl;
  @JsonKey(fromJson: _shortVideoString)
  final String videoMimeType;
  @JsonKey(fromJson: _shortVideoInt)
  final int videoSizeBytes;
  @JsonKey(fromJson: _shortVideoString)
  final String transcodeStatus;
  @JsonKey(fromJson: _shortVideoString)
  final String transcodeJobId;
  @JsonKey(fromJson: _shortVideoString)
  final String hlsOutputKey;
  @JsonKey(fromJson: _shortVideoString)
  final String hlsUrl;
  @JsonKey(fromJson: _shortVideoInt)
  final int durationSec;
  @JsonKey(fromJson: _shortVideoInt)
  final int width;
  @JsonKey(fromJson: _shortVideoInt)
  final int height;
  @JsonKey(fromJson: _shortVideoString)
  final String status;
  @JsonKey(fromJson: _shortVideoInt)
  final int createdAt;
  @JsonKey(fromJson: _shortVideoInt)
  final int updatedAt;
  @JsonKey(fromJson: _shortVideoInt)
  final int version;

  const ShortVideo({
    required this.id,
    required this.dramaId,
    required this.type,
    required this.episodeNo,
    required this.title,
    required this.description,
    required this.coverUrl,
    this.firstFrameUrl,
    required this.videoUrl,
    required this.videoMimeType,
    required this.videoSizeBytes,
    required this.transcodeStatus,
    required this.transcodeJobId,
    required this.hlsOutputKey,
    required this.hlsUrl,
    required this.durationSec,
    required this.width,
    required this.height,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory ShortVideo.fromJson(Map<String, dynamic> json) =>
      _$ShortVideoFromJson(json);

  Map<String, dynamic> toJson() => _$ShortVideoToJson(this);

  String? get posterUrl => VideoUrlHelpers.preferPosterUrl(
    firstFrameUrl: firstFrameUrl,
    coverUrl: coverUrl,
  );

  @override
  List<Object?> get props => [
    id,
    dramaId,
    type,
    episodeNo,
    title,
    description,
    coverUrl,
    firstFrameUrl,
    videoUrl,
    videoMimeType,
    videoSizeBytes,
    transcodeStatus,
    transcodeJobId,
    hlsOutputKey,
    hlsUrl,
    durationSec,
    width,
    height,
    status,
    createdAt,
    updatedAt,
    version,
  ];
}
