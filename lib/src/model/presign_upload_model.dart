import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'presign_upload_model.g.dart';

/// 后端「创建上传会话」接口返回的会话信息。一个会话可复用于同一批次
/// 的多个文件（如批量剧集）。
@JsonSerializable()
class UploadSession extends Equatable {
  /// 后端生成的上传会话 ID，以字符串保存以避免大整数精度丢失。
  final String? uploadSessionId;

  /// 会话有效期（秒），后端可能以字符串返回，统一转 int。
  @JsonKey(fromJson: asInt)
  final int? expireSeconds;

  const UploadSession({this.uploadSessionId, this.expireSeconds});

  factory UploadSession.fromJson(Map<String, dynamic> json) =>
      _$UploadSessionFromJson(json);

  Map<String, dynamic> toJson() => _$UploadSessionToJson(this);

  bool get isValid => uploadSessionId != null && uploadSessionId!.isNotEmpty;

  @override
  List<Object?> get props => [uploadSessionId, expireSeconds];
}

/// 后端预签名上传接口返回的凭证。
///
/// 字段为后端返回的 camelCase 键，故不启用 [FieldRename]。
@JsonSerializable()
class PresignUploadResult extends Equatable {
  /// 预签名的绝对上传地址（PUT 目标）。
  final String? uploadUrl;

  /// 对象存储中的最终 key，用于后续拼接访问地址或回传后端。
  final String? objectKey;

  /// 直传时必须原样携带的请求头（如 `x-amz-acl`、`Content-Type`）。
  final Map<String, String>? requiredHeaders;

  /// 预签名有效期（秒），后端可能以字符串返回，统一转 int。
  @JsonKey(fromJson: asInt)
  final int? expireSeconds;

  const PresignUploadResult({
    this.uploadUrl,
    this.objectKey,
    this.requiredHeaders,
    this.expireSeconds,
  });

  factory PresignUploadResult.fromJson(Map<String, dynamic> json) =>
      _$PresignUploadResultFromJson(json);

  Map<String, dynamic> toJson() => _$PresignUploadResultToJson(this);

  /// 是否具备发起直传所需的最小信息。
  bool get isValid =>
      uploadUrl != null &&
      uploadUrl!.isNotEmpty &&
      objectKey != null &&
      objectKey!.isNotEmpty;

  @override
  List<Object?> get props => [
    uploadUrl,
    objectKey,
    requiredHeaders,
    expireSeconds,
  ];
}

/// 上传完成后的文件信息：包含对象存储 key 与可公开访问的 URL。
///
/// 供需要回传 objectKey 给后端（如角色头像 `avatarObjectKey`）的场景使用。
class UploadedFile extends Equatable {
  final String objectKey;
  final String publicUrl;

  const UploadedFile({required this.objectKey, required this.publicUrl});

  @override
  List<Object?> get props => [objectKey, publicUrl];
}
