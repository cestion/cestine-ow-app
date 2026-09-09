// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multipart_upload_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitiateMultipartResult _$InitiateMultipartResultFromJson(
  Map<String, dynamic> json,
) => InitiateMultipartResult(
  uploadId: json['uploadId'] as String?,
  objectKey: json['objectKey'] as String?,
  partSize: asInt(json['partSize']),
  totalParts: asInt(json['totalParts']),
);

Map<String, dynamic> _$InitiateMultipartResultToJson(
  InitiateMultipartResult instance,
) => <String, dynamic>{
  'uploadId': instance.uploadId,
  'objectKey': instance.objectKey,
  'partSize': instance.partSize,
  'totalParts': instance.totalParts,
};

PresignedPartUrl _$PresignedPartUrlFromJson(Map<String, dynamic> json) =>
    PresignedPartUrl(
      partNumber: asInt(json['partNumber']),
      uploadUrl: json['uploadUrl'] as String?,
    );

Map<String, dynamic> _$PresignedPartUrlToJson(PresignedPartUrl instance) =>
    <String, dynamic>{
      'partNumber': instance.partNumber,
      'uploadUrl': instance.uploadUrl,
    };

PresignedPartUrls _$PresignedPartUrlsFromJson(Map<String, dynamic> json) =>
    PresignedPartUrls(
      parts: (json['parts'] as List<dynamic>?)
          ?.map((e) => PresignedPartUrl.fromJson(e as Map<String, dynamic>))
          .toList(),
      expireSeconds: asInt(json['expireSeconds']),
    );

Map<String, dynamic> _$PresignedPartUrlsToJson(PresignedPartUrls instance) =>
    <String, dynamic>{
      'parts': instance.parts,
      'expireSeconds': instance.expireSeconds,
    };

MultipartCompleteEnvelope _$MultipartCompleteEnvelopeFromJson(
  Map<String, dynamic> json,
) => MultipartCompleteEnvelope(
  status: json['status'] as String?,
  objectKey: json['objectKey'] as String?,
  errorCode: asInt(json['errorCode']),
);

Map<String, dynamic> _$MultipartCompleteEnvelopeToJson(
  MultipartCompleteEnvelope instance,
) => <String, dynamic>{
  'status': instance.status,
  'objectKey': instance.objectKey,
  'errorCode': instance.errorCode,
};
