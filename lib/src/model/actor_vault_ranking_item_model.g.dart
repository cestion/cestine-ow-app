// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor_vault_ranking_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActorVaultRankingItem _$ActorVaultRankingItemFromJson(
  Map<String, dynamic> json,
) => ActorVaultRankingItem(
  rank: asInt(json['rank']),
  actorName: json['actorName'] as String?,
  number: json['number'] as String?,
  actorId: json['actorId'] as String?,
  vault: asDouble(json['vault']),
);

Map<String, dynamic> _$ActorVaultRankingItemToJson(
  ActorVaultRankingItem instance,
) => <String, dynamic>{
  'rank': instance.rank,
  'actorName': instance.actorName,
  'number': instance.number,
  'actorId': instance.actorId,
  'vault': instance.vault,
};
