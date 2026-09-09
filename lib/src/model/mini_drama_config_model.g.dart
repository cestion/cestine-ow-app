// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mini_drama_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MiniDramaConfig _$MiniDramaConfigFromJson(Map<String, dynamic> json) =>
    MiniDramaConfig(
      rebateTiers: (json['rebate_tiers'] as List<dynamic>?)
          ?.map((e) => RebateTier.fromJson(e as Map<String, dynamic>))
          .toList(),
      creatorRateMax: asDouble(json['creator_rate_max']),
      defaultCreatorRate: asDouble(json['default_creator_rate']),
      selfRewardUsdtRate: asDouble(json['self_reward_usdt_rate']),
      usdtToPointsRate: asInt(json['usdt_to_points_rate']),
      pointCostPerEpisode: asInt(json['point_cost_per_episode']),
      bulkUnlockDiscountRate: asDouble(json['bulk_unlock_discount_rate']),
    );

Map<String, dynamic> _$MiniDramaConfigToJson(MiniDramaConfig instance) =>
    <String, dynamic>{
      'rebate_tiers': instance.rebateTiers,
      'creator_rate_max': instance.creatorRateMax,
      'default_creator_rate': instance.defaultCreatorRate,
      'self_reward_usdt_rate': instance.selfRewardUsdtRate,
      'usdt_to_points_rate': instance.usdtToPointsRate,
      'point_cost_per_episode': instance.pointCostPerEpisode,
      'bulk_unlock_discount_rate': instance.bulkUnlockDiscountRate,
    };

RebateTier _$RebateTierFromJson(Map<String, dynamic> json) => RebateTier(
  startEpisode: asInt(json['start_episode']),
  endEpisode: (json['end_episode'] as num?)?.toInt(),
  directInviterRate: asDouble(json['direct_inviter_rate']),
  indirectInviterRate: asDouble(json['indirect_inviter_rate']),
);

Map<String, dynamic> _$RebateTierToJson(RebateTier instance) =>
    <String, dynamic>{
      'start_episode': instance.startEpisode,
      'end_episode': instance.endEpisode,
      'direct_inviter_rate': instance.directInviterRate,
      'indirect_inviter_rate': instance.indirectInviterRate,
    };
