// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor_upgrade_material_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpgradeRequirement _$UpgradeRequirementFromJson(Map<String, dynamic> json) =>
    UpgradeRequirement(
      toLevel: asInt(json['toLevel']),
      requiredMaterialCount: asInt(json['requiredMaterialCount']),
      fee: asDouble(json['fee']),
    );

Map<String, dynamic> _$UpgradeRequirementToJson(UpgradeRequirement instance) =>
    <String, dynamic>{
      'toLevel': instance.toLevel,
      'requiredMaterialCount': instance.requiredMaterialCount,
      'fee': instance.fee,
    };

ActorUpgradeMaterial _$ActorUpgradeMaterialFromJson(
  Map<String, dynamic> json,
) => ActorUpgradeMaterial(
  actorId: asString(json['actorId']),
  actorCollectionId: asString(json['actorCollectionId']),
  actorName: json['actorName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  level: asInt(json['level']),
  levelName: json['levelName'] as String?,
  stamina: asInt(json['stamina']),
  staminaLimit: asInt(json['staminaLimit']),
  deploymentStatus: json['deploymentStatus'] as String?,
  upgradeRequirement: json['upgradeRequirement'] == null
      ? null
      : UpgradeRequirement.fromJson(
          json['upgradeRequirement'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ActorUpgradeMaterialToJson(
  ActorUpgradeMaterial instance,
) => <String, dynamic>{
  'actorId': instance.actorId,
  'actorCollectionId': instance.actorCollectionId,
  'actorName': instance.actorName,
  'avatarUrl': instance.avatarUrl,
  'level': instance.level,
  'levelName': instance.levelName,
  'stamina': instance.stamina,
  'staminaLimit': instance.staminaLimit,
  'deploymentStatus': instance.deploymentStatus,
  'upgradeRequirement': instance.upgradeRequirement,
};
