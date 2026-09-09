// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IncomeStats _$IncomeStatsFromJson(Map<String, dynamic> json) => IncomeStats(
  totalAmount: asDouble(json['totalAmount']),
  mintFee: asDouble(json['mintFee']),
  staminaFee: asDouble(json['staminaFee']),
  upgradeFee: asDouble(json['upgradeFee']),
  txFee: asDouble(json['txFee']),
  royalty: asDouble(json['royalty']),
);

Map<String, dynamic> _$IncomeStatsToJson(IncomeStats instance) =>
    <String, dynamic>{
      'totalAmount': instance.totalAmount,
      'mintFee': instance.mintFee,
      'staminaFee': instance.staminaFee,
      'upgradeFee': instance.upgradeFee,
      'txFee': instance.txFee,
      'royalty': instance.royalty,
    };
