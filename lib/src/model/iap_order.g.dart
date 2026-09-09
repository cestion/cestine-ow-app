// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iap_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IapOrder _$IapOrderFromJson(Map<String, dynamic> json) => IapOrder(
  orderId: json['orderId'] as String,
  paymentChannel: json['paymentChannel'] as String?,
  productId: json['productId'] as String?,
  purchaseAmount: json['purchaseAmount'] as String?,
  currency: json['currency'] as String?,
  tokenAmount: json['tokenAmount'] as String?,
  providerAccountId: json['providerAccountId'] as String?,
  status: (json['status'] as num?)?.toInt(),
  statusName: json['statusName'] as String?,
  providerTransactionId: json['providerTransactionId'] as String?,
  operatorOrderId: json['operatorOrderId'] as String?,
  operatorStatus: json['operatorStatus'] as String?,
  createdAt: (json['createdAt'] as num?)?.toInt(),
);

Map<String, dynamic> _$IapOrderToJson(IapOrder instance) => <String, dynamic>{
  'orderId': instance.orderId,
  'paymentChannel': instance.paymentChannel,
  'productId': instance.productId,
  'purchaseAmount': instance.purchaseAmount,
  'currency': instance.currency,
  'tokenAmount': instance.tokenAmount,
  'providerAccountId': instance.providerAccountId,
  'status': instance.status,
  'statusName': instance.statusName,
  'providerTransactionId': instance.providerTransactionId,
  'operatorOrderId': instance.operatorOrderId,
  'operatorStatus': instance.operatorStatus,
  'createdAt': instance.createdAt,
};
