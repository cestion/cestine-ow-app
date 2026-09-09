// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presign_upload_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadSession _$UploadSessionFromJson(Map<String, dynamic> json) =>
    UploadSession(
      uploadSessionId: json['uploadSessionId'] as String?,
      expireSeconds: asInt(json['expireSeconds']),
    );

Map<String, dynamic> _$UploadSessionToJson(UploadSession instance) =>
    <String, dynamic>{
      'uploadSessionId': instance.uploadSessionId,
      'expireSeconds': instance.expireSeconds,
    };

PresignUploadResult _$PresignUploadResultFromJson(Map<String, dynamic> json) =>
    PresignUploadResult(
      uploadUrl: json['uploadUrl'] as String?,
      objectKey: json['objectKey'] as String?,
      requiredHeaders: (json['requiredHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      expireSeconds: asInt(json['expireSeconds']),
    );

Map<String, dynamic> _$PresignUploadResultToJson(
  PresignUploadResult instance,
) => <String, dynamic>{
  'uploadUrl': instance.uploadUrl,
  'objectKey': instance.objectKey,
  'requiredHeaders': instance.requiredHeaders,
  'expireSeconds': instance.expireSeconds,
};
