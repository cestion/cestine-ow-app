// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iap_google_verify_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IapGoogleVerifyRequest _$IapGoogleVerifyRequestFromJson(
  Map<String, dynamic> json,
) => IapGoogleVerifyRequest(
  orderId: json['orderId'] as String,
  purchaseToken: json['purchaseToken'] as String,
);

Map<String, dynamic> _$IapGoogleVerifyRequestToJson(
  IapGoogleVerifyRequest instance,
) => <String, dynamic>{
  'orderId': instance.orderId,
  'purchaseToken': instance.purchaseToken,
};
