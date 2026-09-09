// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdraw_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WithdrawCreateResponse _$WithdrawCreateResponseFromJson(
  Map<String, dynamic> json,
) => WithdrawCreateResponse(orderNo: json['orderNo'] as String?);

Map<String, dynamic> _$WithdrawCreateResponseToJson(
  WithdrawCreateResponse instance,
) => <String, dynamic>{'orderNo': instance.orderNo};

WithdrawDetailResponse _$WithdrawDetailResponseFromJson(
  Map<String, dynamic> json,
) => WithdrawDetailResponse(
  orderNo: json['orderNo'] as String?,
  status: json['status'] as String?,
  txHash: json['txHash'] as String?,
);

Map<String, dynamic> _$WithdrawDetailResponseToJson(
  WithdrawDetailResponse instance,
) => <String, dynamic>{
  'orderNo': instance.orderNo,
  'status': instance.status,
  'txHash': instance.txHash,
};
