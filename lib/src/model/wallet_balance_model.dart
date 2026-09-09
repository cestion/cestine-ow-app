import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'wallet_balance_model.g.dart';

@JsonSerializable()
class WalletBalance extends Equatable {
  final String? assetCode;
  @JsonKey(fromJson: asDouble)
  final double? availableBalance;
  @JsonKey(fromJson: asDouble)
  final double? frozenBalance;
  @JsonKey(fromJson: asInt)
  final int? decimals;

  const WalletBalance({
    this.assetCode,
    this.availableBalance,
    this.frozenBalance,
    this.decimals,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) =>
      _$WalletBalanceFromJson(json);

  Map<String, dynamic> toJson() => _$WalletBalanceToJson(this);

  @override
  List<Object?> get props => [
    assetCode,
    availableBalance,
    frozenBalance,
    decimals,
  ];
}
