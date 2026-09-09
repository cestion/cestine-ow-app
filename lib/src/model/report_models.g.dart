// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportTypeItem _$ReportTypeItemFromJson(Map<String, dynamic> json) =>
    ReportTypeItem(
      id: asString(json['id']),
      code: json['code'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$ReportTypeItemToJson(ReportTypeItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

SubmitReportRequest _$SubmitReportRequestFromJson(Map<String, dynamic> json) =>
    SubmitReportRequest(
      reportType: json['reportType'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$SubmitReportRequestToJson(
  SubmitReportRequest instance,
) => <String, dynamic>{
  'reportType': instance.reportType,
  'description': instance.description,
};
