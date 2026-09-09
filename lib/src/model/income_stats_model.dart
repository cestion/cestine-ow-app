import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'income_stats_model.g.dart';

/// 与 web `IncomeStatsDTO` 对齐：资金看板累计收支统计。
@JsonSerializable(explicitToJson: true)
class IncomeStats extends Equatable {
  @JsonKey(fromJson: asDouble)
  final double? totalAmount;
  @JsonKey(fromJson: asDouble)
  final double? mintFee;
  @JsonKey(fromJson: asDouble)
  final double? staminaFee;
  @JsonKey(fromJson: asDouble)
  final double? upgradeFee;
  @JsonKey(fromJson: asDouble)
  final double? txFee;
  @JsonKey(fromJson: asDouble)
  final double? royalty;

  const IncomeStats({
    this.totalAmount,
    this.mintFee,
    this.staminaFee,
    this.upgradeFee,
    this.txFee,
    this.royalty,
  });

  factory IncomeStats.fromJson(Map<String, dynamic> json) =>
      _$IncomeStatsFromJson(json);

  Map<String, dynamic> toJson() => _$IncomeStatsToJson(this);

  @override
  List<Object?> get props => [
    totalAmount,
    mintFee,
    staminaFee,
    upgradeFee,
    txFee,
    royalty,
  ];
}
