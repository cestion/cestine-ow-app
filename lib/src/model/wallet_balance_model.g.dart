// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_balance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletBalance _$WalletBalanceFromJson(Map<String, dynamic> json) =>
    WalletBalance(
      assetCode: json['assetCode'] as String?,
      availableBalance: asDouble(json['availableBalance']),
      frozenBalance: asDouble(json['frozenBalance']),
      decimals: asInt(json['decimals']),
    );

Map<String, dynamic> _$WalletBalanceToJson(WalletBalance instance) =>
    <String, dynamic>{
      'assetCode': instance.assetCode,
      'availableBalance': instance.availableBalance,
      'frozenBalance': instance.frozenBalance,
      'decimals': instance.decimals,
    };
