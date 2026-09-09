import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'mining_weekly_stats_model.g.dart';

@JsonSerializable()
class MiningWeeklyStats extends Equatable {
  final double? weekPool;
  final double? weekInvitePool;
  final double? weeklyNominalOutput;
  final double? weeklyTotalOutput;

  const MiningWeeklyStats({
    this.weekPool,
    this.weekInvitePool,
    this.weeklyNominalOutput,
    this.weeklyTotalOutput,
  });

  factory MiningWeeklyStats.fromJson(Map<String, dynamic> json) =>
      _$MiningWeeklyStatsFromJson(json);

  Map<String, dynamic> toJson() => _$MiningWeeklyStatsToJson(this);

  @override
  List<Object?> get props => [
    weekPool,
    weekInvitePool,
    weeklyNominalOutput,
    weeklyTotalOutput,
  ];
}
