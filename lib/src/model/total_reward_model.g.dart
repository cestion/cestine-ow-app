// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'total_reward_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotalReward _$TotalRewardFromJson(Map<String, dynamic> json) => TotalReward(
  totalMiningReward: asDouble(json['totalMiningReward']),
  totalInviteReward: asDouble(json['totalInviteReward']),
);

Map<String, dynamic> _$TotalRewardToJson(TotalReward instance) =>
    <String, dynamic>{
      'totalMiningReward': instance.totalMiningReward,
      'totalInviteReward': instance.totalInviteReward,
    };
