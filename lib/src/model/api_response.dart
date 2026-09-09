import 'package:json_annotation/json_annotation.dart';

import '../core/story_constants.dart';

part 'api_response.g.dart';

@JsonSerializable(
  genericArgumentFactories: true,
  fieldRename: FieldRename.snake,
)
class ApiResponse<T> {
  final int code;
  final String? msg;
  final String? message;

  /// Raw backend payload. Kept generic/dynamic at the API-client boundary so
  /// callers can decode domain models with their own converters.
  final T? data;

  const ApiResponse({required this.code, this.msg, this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? fromJson) fromJsonT,
  ) => _$ApiResponseFromJson<T>(json, fromJsonT);

  String get effectiveMessage => msg ?? message ?? '';
  bool get isSuccess =>
      code == ApiResponseCode.success || code == ApiResponseCode.successAlt;
  bool get isUnauthorized =>
      code == ApiResponseCode.unauthorized ||
      code == ApiResponseCode.unauthorizedAlt;
}
