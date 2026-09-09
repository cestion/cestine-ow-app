import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'drama_edit_request_model.g.dart';

/// 编辑提交请求体。对应 `PUT /creator/dramas/{dramaId}`。
///
/// 所有字段均为可选 — 只有发生变化的字段才包含在请求中。
/// `includeIfNull: false` 确保 null 字段不序列化。
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class DramaEditRequest extends Equatable {
  /// 上传会话 Snowflake ID；仅媒体资源发生变化时提交。
  final String? uploadSessionId;
  final String? title;
  final String? description;
  final String? coverObjectKey;
  final List<DramaEditEpisodeItem>? episodes;
  final ActorCollectionChanges? actorCollectionChanges;
  final List<String>? tagIds;

  const DramaEditRequest({
    this.uploadSessionId,
    this.title,
    this.description,
    this.coverObjectKey,
    this.episodes,
    this.actorCollectionChanges,
    this.tagIds,
  });

  factory DramaEditRequest.fromJson(Map<String, dynamic> json) =>
      _$DramaEditRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DramaEditRequestToJson(this);

  @override
  List<Object?> get props => [
    uploadSessionId,
    title,
    description,
    coverObjectKey,
    episodes,
    actorCollectionChanges,
    tagIds,
  ];
}

/// 编辑提交中的单集信息。
@JsonSerializable(includeIfNull: false)
class DramaEditEpisodeItem extends Equatable {
  /// 已有剧集 Snowflake ID；新增剧集不传。
  final String? id;
  final int? episodeNo;
  final String? title;
  final String? description;
  final String? videoObjectKey;
  final int? durationSec;
  final int? width;
  final int? height;

  const DramaEditEpisodeItem({
    this.id,
    this.episodeNo,
    this.title,
    this.description,
    this.videoObjectKey,
    this.durationSec,
    this.width,
    this.height,
  });

  factory DramaEditEpisodeItem.fromJson(Map<String, dynamic> json) =>
      _$DramaEditEpisodeItemFromJson(json);

  Map<String, dynamic> toJson() => _$DramaEditEpisodeItemToJson(this);

  @override
  List<Object?> get props => [
    id,
    episodeNo,
    title,
    description,
    videoObjectKey,
    durationSec,
    width,
    height,
  ];
}

/// 角色 IP 绑定变更集合（增量）。
///
/// `add` 最多 5 个；ID 全链路保持字符串。当前 UI 不允许移除后端已经
/// 持久化的绑定，但保留 `delete` 字段以完整匹配接口契约。
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ActorCollectionChanges extends Equatable {
  final List<String>? add;
  final List<String>? delete;

  const ActorCollectionChanges({this.add, this.delete});

  factory ActorCollectionChanges.fromJson(Map<String, dynamic> json) =>
      _$ActorCollectionChangesFromJson(json);

  Map<String, dynamic> toJson() => _$ActorCollectionChangesToJson(this);

  @override
  List<Object?> get props => [add, delete];
}
