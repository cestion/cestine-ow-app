// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  privyToken: json['privyToken'] as String,
  deviceType: json['deviceType'] as String,
  inviteCode: json['inviteCode'] as String?,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'privyToken': instance.privyToken,
      'inviteCode': instance.inviteCode,
      'deviceType': instance.deviceType,
    };
