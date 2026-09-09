// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settling_reward_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlingReward _$SettlingRewardFromJson(Map<String, dynamic> json) =>
    SettlingReward(
      miningReward: asDouble(json['miningReward']),
      inviteReward: asDouble(json['inviteReward']),
    );

Map<String, dynamic> _$SettlingRewardToJson(SettlingReward instance) =>
    <String, dynamic>{
      'miningReward': instance.miningReward,
      'inviteReward': instance.inviteReward,
    };
