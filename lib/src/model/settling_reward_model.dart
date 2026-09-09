import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'settling_reward_model.g.dart';

/// 结算中奖励（`GET /api/mining/settlingReward`）。
@JsonSerializable(explicitToJson: true)
class SettlingReward extends Equatable {
  @JsonKey(fromJson: asDouble)
  final double? miningReward;
  @JsonKey(fromJson: asDouble)
  final double? inviteReward;

  const SettlingReward({this.miningReward, this.inviteReward});

  /// 结算中 STORY 合计。
  double get totalStory => (miningReward ?? 0) + (inviteReward ?? 0);

  factory SettlingReward.fromJson(Map<String, dynamic> json) =>
      _$SettlingRewardFromJson(json);

  Map<String, dynamic> toJson() => _$SettlingRewardToJson(this);

  @override
  List<Object?> get props => [miningReward, inviteReward];
}
