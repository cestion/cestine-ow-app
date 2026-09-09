import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'total_reward_model.g.dart';

/// 与 web `TotalRewardDTO` 对齐：累计派遣挖矿奖励 + 累计邀请奖励。
@JsonSerializable(explicitToJson: true)
class TotalReward extends Equatable {
  @JsonKey(fromJson: asDouble)
  final double? totalMiningReward;
  @JsonKey(fromJson: asDouble)
  final double? totalInviteReward;

  const TotalReward({this.totalMiningReward, this.totalInviteReward});

  factory TotalReward.fromJson(Map<String, dynamic> json) =>
      _$TotalRewardFromJson(json);

  Map<String, dynamic> toJson() => _$TotalRewardToJson(this);

  @override
  List<Object?> get props => [totalMiningReward, totalInviteReward];
}
