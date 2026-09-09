import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_drama_request_model.g.dart';

/// 创建短剧请求中的单集信息。
@JsonSerializable()
class CreateEpisodeRequest extends Equatable {
  final int durationSec;
  final String description;
  final int episodeNo;
  final String title;
  final String videoObjectKey;
  final int width;
  final int height;

  const CreateEpisodeRequest({
    required this.durationSec,
    required this.description,
    required this.episodeNo,
    required this.title,
    required this.videoObjectKey,
    required this.width,
    required this.height,
  });

  factory CreateEpisodeRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateEpisodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateEpisodeRequestToJson(this);

  @override
  List<Object?> get props => [
    durationSec,
    description,
    episodeNo,
    title,
    videoObjectKey,
    width,
    height,
  ];
}

/// 创建短剧请求体。对应 `POST /api/mini-drama/creator/dramas`。
@JsonSerializable(includeIfNull: false)
class CreateDramaRequest extends Equatable {
  final String coverObjectKey;
  final String description;
  final List<CreateEpisodeRequest> episodes;

  /// 可选的角色 IP 绑定，最多 5 个。
  ///
  /// 后端 Long / Snowflake ID 必须保持字符串，避免精度丢失。为空时不序列化，
  /// 对应「不绑定 IP 也可直接发布」。
  final List<String>? actorCollectionIds;

  final List<String> tagIds;
  final String title;
  final String uploadSessionId;

  const CreateDramaRequest({
    required this.coverObjectKey,
    required this.description,
    required this.episodes,
    this.actorCollectionIds,
    required this.tagIds,
    required this.title,
    required this.uploadSessionId,
  });

  factory CreateDramaRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDramaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateDramaRequestToJson(this);

  @override
  List<Object?> get props => [
    coverObjectKey,
    description,
    episodes,
    actorCollectionIds,
    tagIds,
    title,
    uploadSessionId,
  ];
}
