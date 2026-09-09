import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'actor_upgrade_material_model.g.dart';

/// 升级需求，与 web `UpgradeRequirement` 对齐。
@JsonSerializable()
class UpgradeRequirement extends Equatable {
  /// 升级目标等级
  @JsonKey(fromJson: asInt)
  final int? toLevel;

  /// 所需材料数量
  @JsonKey(fromJson: asInt)
  final int? requiredMaterialCount;

  /// 升级费用 (USDC)
  @JsonKey(fromJson: asDouble)
  final double? fee;

  const UpgradeRequirement({
    this.toLevel,
    this.requiredMaterialCount,
    this.fee,
  });

  factory UpgradeRequirement.fromJson(Map<String, dynamic> json) =>
      _$UpgradeRequirementFromJson(json);

  Map<String, dynamic> toJson() => _$UpgradeRequirementToJson(this);

  @override
  List<Object?> get props => [toLevel, requiredMaterialCount, fee];
}

/// 演员 NFT 咖位升级可用耗材，与 web `ActorLevelUpgradeMaterialResponse` 对齐。
@JsonSerializable()
class ActorUpgradeMaterial extends Equatable {
  /// 演员NFT tokenId
  @JsonKey(fromJson: asString)
  final String? actorId;

  /// 演员合集ID
  @JsonKey(fromJson: asString)
  final String? actorCollectionId;

  /// 演员名称
  final String? actorName;

  /// 头像URL
  final String? avatarUrl;

  /// 等级 (1-5)
  @JsonKey(fromJson: asInt)
  final int? level;

  /// 咖位名称
  final String? levelName;

  /// 当前体力 (0-168)
  @JsonKey(fromJson: asInt)
  final int? stamina;

  /// 体力上限
  @JsonKey(fromJson: asInt)
  final int? staminaLimit;

  /// 派遣状态
  final String? deploymentStatus;

  /// 升级需求
  final UpgradeRequirement? upgradeRequirement;

  const ActorUpgradeMaterial({
    this.actorId,
    this.actorCollectionId,
    this.actorName,
    this.avatarUrl,
    this.level,
    this.levelName,
    this.stamina,
    this.staminaLimit,
    this.deploymentStatus,
    this.upgradeRequirement,
  });

  factory ActorUpgradeMaterial.fromJson(Map<String, dynamic> json) =>
      _$ActorUpgradeMaterialFromJson(json);

  Map<String, dynamic> toJson() => _$ActorUpgradeMaterialToJson(this);

  /// 解析 actorId 为 tokenId (int)
  int? get tokenId {
    final raw = actorId?.trim();
    if (raw == null || raw.isEmpty) return null;
    final id = raw.startsWith('#') ? raw.substring(1) : raw;
    return int.tryParse(id);
  }

  @override
  List<Object?> get props => [
    actorId,
    actorCollectionId,
    actorName,
    avatarUrl,
    level,
    levelName,
    stamina,
    staminaLimit,
    deploymentStatus,
    upgradeRequirement,
  ];
}
