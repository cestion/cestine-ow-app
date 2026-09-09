// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mining_actor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MiningActorMemo _$MiningActorMemoFromJson(Map<String, dynamic> json) =>
    MiningActorMemo(
      p0: asDouble(json['p0']),
      heat: asDouble(json['heat']),
      trust1: asDouble(json['trust1']),
      trust2: asDouble(json['trust2']),
      cp: asDouble(json['CP']),
      mc: asDouble(json['MC']),
    );

Map<String, dynamic> _$MiningActorMemoToJson(MiningActorMemo instance) =>
    <String, dynamic>{
      'p0': instance.p0,
      'heat': instance.heat,
      'trust1': instance.trust1,
      'trust2': instance.trust2,
      'CP': instance.cp,
      'MC': instance.mc,
    };

MiningActor _$MiningActorFromJson(Map<String, dynamic> json) => MiningActor(
  actorName: json['actorName'] as String?,
  actorNftId: asString(json['actorNftId']),
  actorCollectionId: asInt(json['actorCollectionId']),
  level: asInt(json['level']),
  heat: asDouble(json['heat']),
  computingPower: asDouble(json['computingPower']),
  miningCoefficient: asDouble(json['miningCoefficient']),
  priceCoefficient: asDouble(json['priceCoefficient']),
  ipPower: asDouble(json['ipPower']),
  trust1: asDouble(json['trust1']),
  trust2: asDouble(json['trust2']),
  trust: asDouble(json['trust']),
  cpCoefficient: asDouble(json['cpCoefficient']),
  memo: _memoFromJson(json['memo']),
  status: json['status'] as String?,
  weeklyNominalOutput: asDouble(json['weeklyNominalOutput']),
  stamina: asInt(json['stamina']),
  avatarUrl: json['avatarUrl'] as String?,
  completedPlayCount: asInt(json['completedPlayCount']),
  materialCount: asInt(json['materialCount']),
  completePlayThresholdMet: asBool(json['completePlayThresholdMet']),
  actorTokenId: asInt(json['actorTokenId']),
);

Map<String, dynamic> _$MiningActorToJson(MiningActor instance) =>
    <String, dynamic>{
      'actorName': instance.actorName,
      'actorNftId': instance.actorNftId,
      'actorCollectionId': instance.actorCollectionId,
      'level': instance.level,
      'heat': instance.heat,
      'computingPower': instance.computingPower,
      'miningCoefficient': instance.miningCoefficient,
      'priceCoefficient': instance.priceCoefficient,
      'ipPower': instance.ipPower,
      'trust1': instance.trust1,
      'trust2': instance.trust2,
      'trust': instance.trust,
      'cpCoefficient': instance.cpCoefficient,
      'memo': _memoToJson(instance.memo),
      'status': instance.status,
      'weeklyNominalOutput': instance.weeklyNominalOutput,
      'stamina': instance.stamina,
      'avatarUrl': instance.avatarUrl,
      'completedPlayCount': instance.completedPlayCount,
      'materialCount': instance.materialCount,
      'completePlayThresholdMet': instance.completePlayThresholdMet,
      'actorTokenId': instance.actorTokenId,
    };
