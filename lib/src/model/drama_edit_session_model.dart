import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'drama_edit_session_model.g.dart';

List<String>? _asStringList(dynamic value) {
  if (value is! List) return null;
  return value.map((item) => item.toString()).toList(growable: false);
}

/// 编辑会话中的单集信息。
@JsonSerializable()
class EditSessionEpisode extends Equatable {
  @JsonKey(fromJson: asString)
  final String? id;
  final int episodeNo;
  final String title;
  final String? description;
  final String? videoUrl;
  @JsonKey(fromJson: asInt)
  final int? videoSizeBytes;
  final int durationSec;
  final String? hlsOutputKey;
  final String? hlsUrl;

  const EditSessionEpisode({
    this.id,
    required this.episodeNo,
    required this.title,
    this.description,
    this.videoUrl,
    this.videoSizeBytes,
    required this.durationSec,
    this.hlsOutputKey,
    this.hlsUrl,
  });

  factory EditSessionEpisode.fromJson(Map<String, dynamic> json) =>
      _$EditSessionEpisodeFromJson(json);

  Map<String, dynamic> toJson() => _$EditSessionEpisodeToJson(this);

  @override
  List<Object?> get props => [
    id,
    episodeNo,
    title,
    description,
    videoUrl,
    videoSizeBytes,
    durationSec,
    hlsOutputKey,
    hlsUrl,
  ];
}

/// 编辑会话中已经绑定的角色 IP。
@JsonSerializable()
class EditSessionActorCollection extends Equatable {
  @JsonKey(fromJson: asString)
  final String? actorCollectionId;
  @JsonKey(fromJson: asString)
  final String? assetId;
  final String? name;
  final String? avatarUrl;
  @JsonKey(fromJson: asDouble)
  final double? trust;
  @JsonKey(fromJson: asDouble)
  final double? computingPower;

  const EditSessionActorCollection({
    this.actorCollectionId,
    this.assetId,
    this.name,
    this.avatarUrl,
    this.trust,
    this.computingPower,
  });

  factory EditSessionActorCollection.fromJson(Map<String, dynamic> json) =>
      _$EditSessionActorCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$EditSessionActorCollectionToJson(this);

  @override
  List<Object?> get props => [
    actorCollectionId,
    assetId,
    name,
    avatarUrl,
    trust,
    computingPower,
  ];
}

/// 编辑会话响应。
///
/// 对应 `GET /api/mini-drama/creator/dramas/{dramaId}/edit-sessions`，
/// 包含回显所需的全部数据（含 uploadSessionId、episodes、actorCollections）。
@JsonSerializable()
class DramaEditSession extends Equatable {
  @JsonKey(fromJson: asString)
  final String? uploadSessionId;
  @JsonKey(fromJson: asInt)
  final int? uploadExpireSeconds;
  @JsonKey(fromJson: asString)
  final String? dramaId;
  @JsonKey(fromJson: asString)
  final String? userId;
  final String? title;
  final String? description;
  final String? coverUrl;
  @JsonKey(fromJson: asInt)
  final int? onlineAt;
  @JsonKey(fromJson: _asStringList)
  final List<String>? tagIds;
  final List<EditSessionEpisode>? episodes;
  final List<EditSessionActorCollection>? actorCollections;

  const DramaEditSession({
    this.uploadSessionId,
    this.uploadExpireSeconds,
    this.dramaId,
    this.userId,
    this.title,
    this.description,
    this.coverUrl,
    this.onlineAt,
    this.tagIds,
    this.episodes,
    this.actorCollections,
  });

  factory DramaEditSession.fromJson(Map<String, dynamic> json) =>
      _$DramaEditSessionFromJson(json);

  Map<String, dynamic> toJson() => _$DramaEditSessionToJson(this);

  @override
  List<Object?> get props => [
    uploadSessionId,
    uploadExpireSeconds,
    dramaId,
    userId,
    title,
    description,
    coverUrl,
    onlineAt,
    tagIds,
    episodes,
    actorCollections,
  ];
}
