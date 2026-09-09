// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iap_apple_verify_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IapAppleVerifyRequest _$IapAppleVerifyRequestFromJson(
  Map<String, dynamic> json,
) => IapAppleVerifyRequest(
  orderId: json['orderId'] as String,
  signedTransactionInfo: json['signedTransactionInfo'] as String,
);

Map<String, dynamic> _$IapAppleVerifyRequestToJson(
  IapAppleVerifyRequest instance,
) => <String, dynamic>{
  'orderId': instance.orderId,
  'signedTransactionInfo': instance.signedTransactionInfo,
};
