// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RewardDetail _$RewardDetailFromJson(Map<String, dynamic> json) => RewardDetail(
  rewardTime: json['rewardTime'] as String?,
  type: $enumDecodeNullable(_$RewardDetailTypeEnumMap, json['type']),
  rewardPeriodStart: json['rewardPeriodStart'] as String?,
  rewardPeriodEnd: json['rewardPeriodEnd'] as String?,
  sourceUser: asString(json['sourceUser']),
  sourceUserName: json['sourceUserName'] as String?,
  storyAmount: asDouble(json['storyAmount']),
);

Map<String, dynamic> _$RewardDetailToJson(RewardDetail instance) =>
    <String, dynamic>{
      'rewardTime': instance.rewardTime,
      'type': _$RewardDetailTypeEnumMap[instance.type],
      'rewardPeriodStart': instance.rewardPeriodStart,
      'rewardPeriodEnd': instance.rewardPeriodEnd,
      'sourceUser': instance.sourceUser,
      'sourceUserName': instance.sourceUserName,
      'storyAmount': instance.storyAmount,
    };

const _$RewardDetailTypeEnumMap = {
  RewardDetailType.mining: 'MINING',
  RewardDetailType.invite: 'INVITE',
};

RewardDetailPage _$RewardDetailPageFromJson(Map<String, dynamic> json) =>
    RewardDetailPage(
      pageSize: json['pageSize'] as String?,
      mark: json['mark'] as String?,
      hasMore: json['hasMore'] as bool?,
      list: (json['list'] as List<dynamic>?)
          ?.map((e) => RewardDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RewardDetailPageToJson(RewardDetailPage instance) =>
    <String, dynamic>{
      'pageSize': instance.pageSize,
      'mark': instance.mark,
      'hasMore': instance.hasMore,
      'list': instance.list?.map((e) => e.toJson()).toList(),
    };
