// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_reward_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeeklyRewardItem _$WeeklyRewardItemFromJson(Map<String, dynamic> json) =>
    WeeklyRewardItem(
      rewardPeriodStart: json['rewardPeriodStart'] as String?,
      rewardPeriodEnd: json['rewardPeriodEnd'] as String?,
      hardLimit: asInt(json['hardLimit']),
      miningRewards: asDouble(json['miningRewards']),
      inviteRewards: asDouble(json['inviteRewards']),
    );

Map<String, dynamic> _$WeeklyRewardItemToJson(WeeklyRewardItem instance) =>
    <String, dynamic>{
      'rewardPeriodStart': instance.rewardPeriodStart,
      'rewardPeriodEnd': instance.rewardPeriodEnd,
      'hardLimit': instance.hardLimit,
      'miningRewards': instance.miningRewards,
      'inviteRewards': instance.inviteRewards,
    };
