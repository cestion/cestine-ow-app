// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor_vault_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActorVaultStats _$ActorVaultStatsFromJson(Map<String, dynamic> json) =>
    ActorVaultStats(
      totalVault: asDouble(json['totalVault']),
      actorCount: asInt(json['actorCount']),
    );

Map<String, dynamic> _$ActorVaultStatsToJson(ActorVaultStats instance) =>
    <String, dynamic>{
      'totalVault': instance.totalVault,
      'actorCount': instance.actorCount,
    };
