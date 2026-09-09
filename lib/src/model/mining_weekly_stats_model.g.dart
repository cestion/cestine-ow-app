// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mining_weekly_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MiningWeeklyStats _$MiningWeeklyStatsFromJson(Map<String, dynamic> json) =>
    MiningWeeklyStats(
      weekPool: (json['weekPool'] as num?)?.toDouble(),
      weekInvitePool: (json['weekInvitePool'] as num?)?.toDouble(),
      weeklyNominalOutput: (json['weeklyNominalOutput'] as num?)?.toDouble(),
      weeklyTotalOutput: (json['weeklyTotalOutput'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MiningWeeklyStatsToJson(MiningWeeklyStats instance) =>
    <String, dynamic>{
      'weekPool': instance.weekPool,
      'weekInvitePool': instance.weekInvitePool,
      'weeklyNominalOutput': instance.weeklyNominalOutput,
      'weeklyTotalOutput': instance.weeklyTotalOutput,
    };
