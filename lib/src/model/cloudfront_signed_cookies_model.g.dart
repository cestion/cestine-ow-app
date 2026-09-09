// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloudfront_signed_cookies_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CloudFrontSignedCookies _$CloudFrontSignedCookiesFromJson(
  Map<String, dynamic> json,
) => CloudFrontSignedCookies(
  policy: json['policy'] as String?,
  signature: json['signature'] as String?,
  keyPairId: json['keyPairId'] as String?,
  expires: asInt(json['expires']),
);

Map<String, dynamic> _$CloudFrontSignedCookiesToJson(
  CloudFrontSignedCookies instance,
) => <String, dynamic>{
  'policy': instance.policy,
  'signature': instance.signature,
  'keyPairId': instance.keyPairId,
  'expires': instance.expires,
};
