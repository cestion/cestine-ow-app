import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'weekly_reward_item_model.g.dart';

/// 与 web `WeeklyRewardItemDTO` 对齐：单日挖矿/邀请奖励统计。
@JsonSerializable(explicitToJson: true)
class WeeklyRewardItem extends Equatable {
  final String? rewardPeriodStart;
  final String? rewardPeriodEnd;
  @JsonKey(fromJson: asInt)
  final int? hardLimit;
  @JsonKey(fromJson: asDouble)
  final double? miningRewards;
  @JsonKey(fromJson: asDouble)
  final double? inviteRewards;

  const WeeklyRewardItem({
    this.rewardPeriodStart,
    this.rewardPeriodEnd,
    this.hardLimit,
    this.miningRewards,
    this.inviteRewards,
  });

  factory WeeklyRewardItem.fromJson(Map<String, dynamic> json) =>
      _$WeeklyRewardItemFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyRewardItemToJson(this);

  @override
  List<Object?> get props => [
    rewardPeriodStart,
    rewardPeriodEnd,
    hardLimit,
    miningRewards,
    inviteRewards,
  ];
}
