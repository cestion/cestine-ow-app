// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LedgerItem _$LedgerItemFromJson(Map<String, dynamic> json) => LedgerItem(
  time: asString(json['time']),
  bizType: asString(json['bizType']),
  amount: asString(json['amount']),
);

Map<String, dynamic> _$LedgerItemToJson(LedgerItem instance) =>
    <String, dynamic>{
      'time': instance.time,
      'bizType': instance.bizType,
      'amount': instance.amount,
    };
