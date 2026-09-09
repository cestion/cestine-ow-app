import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'report_models.g.dart';

/// Query `scope` for `GET /api/mini-drama/public/ugc/report-types`.
abstract final class UgcReportScope {
  static const work = 'WORK';
  static const drama = 'DRAMA';
  static const comment = 'COMMENT';
  static const user = 'USER';
}

@JsonSerializable()
class ReportTypeItem extends Equatable {
  @JsonKey(fromJson: asString)
  final String? id;
  final String? code;
  final String? name;

  const ReportTypeItem({this.id, this.code, this.name});

  factory ReportTypeItem.fromJson(Map<String, dynamic> json) =>
      _$ReportTypeItemFromJson(json);

  Map<String, dynamic> toJson() => _$ReportTypeItemToJson(this);

  @override
  List<Object?> get props => [id, code, name];
}

@JsonSerializable()
class SubmitReportRequest extends Equatable {
  final String reportType;
  final String? description;

  const SubmitReportRequest({required this.reportType, this.description});

  factory SubmitReportRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitReportRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SubmitReportRequestToJson(this);

  @override
  List<Object?> get props => [reportType, description];
}
