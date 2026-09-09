import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'withdraw_order_model.g.dart';

@JsonSerializable()
class WithdrawCreateResponse extends Equatable {
  final String? orderNo;

  const WithdrawCreateResponse({this.orderNo});

  factory WithdrawCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$WithdrawCreateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WithdrawCreateResponseToJson(this);

  @override
  List<Object?> get props => [orderNo];
}

@JsonSerializable()
class WithdrawDetailResponse extends Equatable {
  final String? orderNo;
  final String? status;
  final String? txHash;

  const WithdrawDetailResponse({this.orderNo, this.status, this.txHash});

  factory WithdrawDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$WithdrawDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WithdrawDetailResponseToJson(this);

  static const String statusConfirmed = '2';
  static const String statusFailed = '3';

  @override
  List<Object?> get props => [orderNo, status, txHash];
}
