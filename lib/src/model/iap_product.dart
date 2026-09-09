import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'iap_product.g.dart';

/// A purchasable iOS product served by
/// `GET /api/admin/v1/configs/keys/ios_products` (server-driven catalog).
@JsonSerializable()
class IapProduct extends Equatable {
  @JsonKey(name: 'id')
  final String productId;

  /// 发放数量（后端 amount 为字符串，如 "1"）。
  @JsonKey(name: 'amount', fromJson: _amountFromJson)
  final int grantedAmount;

  /// Apple 侧价格（字符串 "1.99"）。
  @JsonKey(name: 'price', fromJson: _priceFromJson)
  final double? priceUsd;

  final String? currency;

  final bool active;
  final int? sortOrder;

  const IapProduct({
    required this.productId,
    required this.grantedAmount,
    this.priceUsd,
    this.currency,
    this.active = true,
    this.sortOrder,
  });

  static int _amountFromJson(Object? v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  static double? _priceFromJson(Object? v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');

  factory IapProduct.fromJson(Map<String, dynamic> json) =>
      _$IapProductFromJson(json);

  Map<String, dynamic> toJson() => _$IapProductToJson(this);

  @override
  List<Object?> get props => [
    productId,
    grantedAmount,
    priceUsd,
    currency,
    active,
    sortOrder,
  ];
}
