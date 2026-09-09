import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'actor_vault_stats_model.g.dart';

/// 与 web `ActorVaultStatsDTO` 对齐：演员金库累计统计。
@JsonSerializable(explicitToJson: true)
class ActorVaultStats extends Equatable {
  @JsonKey(fromJson: asDouble)
  final double? totalVault;
  @JsonKey(fromJson: asInt)
  final int? actorCount;

  const ActorVaultStats({this.totalVault, this.actorCount});

  factory ActorVaultStats.fromJson(Map<String, dynamic> json) =>
      _$ActorVaultStatsFromJson(json);

  Map<String, dynamic> toJson() => _$ActorVaultStatsToJson(this);

  @override
  List<Object?> get props => [totalVault, actorCount];
}
