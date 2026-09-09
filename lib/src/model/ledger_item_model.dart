import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'ledger_item_model.g.dart';

/// 资金看板流水分页的单条记录，与 web `LedgerItemDTO` 对齐。
@JsonSerializable(explicitToJson: true)
class LedgerItem extends Equatable {
  /// 毫秒时间戳字符串，例如 "1784881165454"。
  @JsonKey(fromJson: asString)
  final String? time;

  /// 业务类型编号字符串，例如 "2108"。
  @JsonKey(fromJson: asString)
  final String? bizType;

  /// 金额字符串，例如 "1.000000"。
  @JsonKey(fromJson: asString)
  final String? amount;

  const LedgerItem({this.time, this.bizType, this.amount});

  factory LedgerItem.fromJson(Map<String, dynamic> json) =>
      _$LedgerItemFromJson(json);

  Map<String, dynamic> toJson() => _$LedgerItemToJson(this);

  @override
  List<Object?> get props => [time, bizType, amount];
}
