import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'creator_drama_model.g.dart';

/// Sentinel 用于 [CreatorDrama.copyWith] 的「显式赋 null」语义。
const Object _sentinel = Object();

/// A bound actor collection associated with a drama (from creator API).
@JsonSerializable()
class BoundActor extends Equatable {
  @JsonKey(fromJson: asInt)
  final int? actorCollectionId;
  final String? assetId;
  final String? name;
  @JsonKey(readValue: _readAvatarUrl)
  final String? avatarUrl;
  @JsonKey(fromJson: asDouble)
  final double? trust;

  /// 创作管理接口以 computingPower 表示该角色 IP 的 STORY/h 片酬。
  @JsonKey(fromJson: asDouble)
  final double? computingPower;

  const BoundActor({
    this.actorCollectionId,
    this.assetId,
    this.name,
    this.avatarUrl,
    this.trust,
    this.computingPower,
  });

  static Object? _readAvatarUrl(Map<dynamic, dynamic> json, String key) {
    final avatar = json['avatar'];
    if (avatar is String && avatar.isNotEmpty) return avatar;
    final avatarUrl = json['avatarUrl'];
    if (avatarUrl is String && avatarUrl.isNotEmpty) return avatarUrl;
    final legacy = json['actorCollectionAvatar'];
    if (legacy is String && legacy.isNotEmpty) return legacy;
    return null;
  }

  factory BoundActor.fromJson(Map<String, dynamic> json) =>
      _$BoundActorFromJson(json);

  Map<String, dynamic> toJson() => _$BoundActorToJson(this);

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

/// Drama data returned by the creator management API.
/// Mirrors [DramaDetailResponse] from the web OpenAPI spec.
@JsonSerializable(explicitToJson: true)
class CreatorDrama extends Equatable {
  @JsonKey(fromJson: asString)
  final String? id;
  final String? title;
  final String? description;
  final String? coverUrl;
  @JsonKey(fromJson: asInt)
  final int? totalEpisodes;
  final List<String>? tags;
  final List<BoundActor>? boundActorCollections;
  final String? status;
  final String? auditReason;
  @JsonKey(fromJson: asInt)
  final int? onlineAt;
  @JsonKey(fromJson: asInt)
  final int? offlineAt;
  final String? nftChain;
  final String? nftContractAddress;
  final String? nftTxHash;
  @JsonKey(fromJson: asBool)
  final bool? nftMinted;
  @JsonKey(fromJson: asInt)
  final int? createdAt;
  @JsonKey(fromJson: asInt)
  final int? version;

  const CreatorDrama({
    this.id,
    this.title,
    this.description,
    this.coverUrl,
    this.totalEpisodes,
    this.tags,
    this.boundActorCollections,
    this.status,
    this.auditReason,
    this.onlineAt,
    this.offlineAt,
    this.nftChain,
    this.nftContractAddress,
    this.nftTxHash,
    this.nftMinted,
    this.createdAt,
    this.version,
  });

  factory CreatorDrama.fromJson(Map<String, dynamic> json) =>
      _$CreatorDramaFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorDramaToJson(this);

  /// 原地更新副本构造器，便于在控制器侧按 id 替换列表项时复用。
  CreatorDrama copyWith({
    String? title,
    String? description,
    String? coverUrl,
    int? totalEpisodes,
    List<String>? tags,
    List<BoundActor>? boundActorCollections,
    String? status,
    String? auditReason,
    int? onlineAt,
    int? offlineAt,
    String? nftChain,
    String? nftContractAddress,
    String? nftTxHash,
    bool? nftMinted,
    int? createdAt,
    int? version,
    // 清空标志（仿 video_upload_state 的 sentinel 模式）
    Object? clearAuditReason = _sentinel,
    Object? clearNftTxHash = _sentinel,
  }) {
    return CreatorDrama(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      tags: tags ?? this.tags,
      boundActorCollections:
          boundActorCollections ?? this.boundActorCollections,
      status: status ?? this.status,
      auditReason: identical(clearAuditReason, _sentinel)
          ? (auditReason ?? this.auditReason)
          : null,
      onlineAt: onlineAt ?? this.onlineAt,
      offlineAt: offlineAt ?? this.offlineAt,
      nftChain: nftChain ?? this.nftChain,
      nftContractAddress: nftContractAddress ?? this.nftContractAddress,
      nftTxHash: identical(clearNftTxHash, _sentinel)
          ? (nftTxHash ?? this.nftTxHash)
          : null,
      nftMinted: nftMinted ?? this.nftMinted,
      createdAt: createdAt ?? this.createdAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    coverUrl,
    totalEpisodes,
    tags,
    boundActorCollections,
    status,
    auditReason,
    onlineAt,
    offlineAt,
    nftMinted,
    createdAt,
    version,
  ];
}
