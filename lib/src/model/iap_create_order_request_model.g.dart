// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iap_create_order_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IapCreateOrderRequest _$IapCreateOrderRequestFromJson(
  Map<String, dynamic> json,
) => IapCreateOrderRequest(
  paymentChannel: json['paymentChannel'] as String,
  productId: json['productId'] as String,
);

Map<String, dynamic> _$IapCreateOrderRequestToJson(
  IapCreateOrderRequest instance,
) => <String, dynamic>{
  'paymentChannel': instance.paymentChannel,
  'productId': instance.productId,
};
