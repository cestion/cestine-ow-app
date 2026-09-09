import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usdc_income_model.g.dart';

/// 与 web `UsdcIncomeItemResponse` 对齐：单条 USDC 收益（演员铸造分成）。
@JsonSerializable(explicitToJson: true)
class UsdcIncomeItem extends Equatable {
  final String? id;
  final String? createdAt;
  final String? type;
  final String? actorCollectionId;
  final String? actorName;
  final String? tokenId;
  final String? amount;
  final String? status;

  const UsdcIncomeItem({
    this.id,
    this.createdAt,
    this.type,
    this.actorCollectionId,
    this.actorName,
    this.tokenId,
    this.amount,
    this.status,
  });

  factory UsdcIncomeItem.fromJson(Map<String, dynamic> json) =>
      _$UsdcIncomeItemFromJson(json);

  Map<String, dynamic> toJson() => _$UsdcIncomeItemToJson(this);

  @override
  List<Object?> get props => [
    id,
    createdAt,
    type,
    actorCollectionId,
    actorName,
    tokenId,
    amount,
    status,
  ];
}

/// 与 web `UsdcIncomePageResponse` 对齐：USDC 收益分页响应，首页含累计 total。
@JsonSerializable(explicitToJson: true)
class UsdcIncomePage extends Equatable {
  final String? total;
  final String? mark;
  final String? pageSize;
  final bool? hasMore;
  final List<UsdcIncomeItem>? list;

  const UsdcIncomePage({
    this.total,
    this.mark,
    this.pageSize,
    this.hasMore,
    this.list,
  });

  factory UsdcIncomePage.fromJson(Map<String, dynamic> json) =>
      _$UsdcIncomePageFromJson(json);

  Map<String, dynamic> toJson() => _$UsdcIncomePageToJson(this);

  @override
  List<Object?> get props => [total, mark, pageSize, hasMore, list];
}
