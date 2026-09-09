import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/result.dart';
import 'json_converters.dart';

part 'multipart_upload_models.g.dart';

/// 分片上传协议的业务错误码（后端契约 `episode-multipart-upload-api.md`）。
abstract final class MultipartUploadErrorCodes {
  /// 扩展名/MIME 不在视频白名单。
  static const fileTypeNotAllowed = 121012;

  /// complete 同步校验阶段核对总大小超限（后端已自动 abort）。
  static const fileSizeExceeded = 121013;

  /// `uploadSessionId` 不属于当前用户或已过期。
  static const sessionInvalid = 121014;

  /// `objectKey` 与 `uploadSessionId` 不匹配（本地记录已脏）。
  static const sessionObjectKeyMismatch = 121015;

  /// `uploadId` 在 S3 侧已彻底失效（过期/已 complete/已 abort），
  /// 需清本地记录重新 initiate。
  static const multipartUploadInvalid = 121026;

  /// 系统瞬时错误：作为轮询错误信封时继续轮询；作为 FAILED 态时
  /// 分片仍在 S3 上，幂等重发一次 complete 即可。
  static const systemError = 100500;

  static bool isMultipartUploadInvalid(ApiError error) =>
      error is BusinessError &&
      error.code == multipartUploadInvalid;

  static bool isSessionInvalid(ApiError error) =>
      error is BusinessError && error.code == sessionInvalid;
}

/// 「初始化分片上传」接口返回：`uploadId` 与最终 `objectKey` 在此即确定。
@JsonSerializable()
class InitiateMultipartResult extends Equatable {
  final String? uploadId;
  final String? objectKey;

  /// 服务端下发的分片大小（字节），客户端不自行计算。
  @JsonKey(fromJson: asInt)
  final int? partSize;

  /// 服务端计算的总分片数。
  @JsonKey(fromJson: asInt)
  final int? totalParts;

  const InitiateMultipartResult({
    this.uploadId,
    this.objectKey,
    this.partSize,
    this.totalParts,
  });

  factory InitiateMultipartResult.fromJson(Map<String, dynamic> json) =>
      _$InitiateMultipartResultFromJson(json);

  Map<String, dynamic> toJson() => _$InitiateMultipartResultToJson(this);

  /// 是否具备开始分片传输所需的最小信息。
  bool get isValid =>
      uploadId != null &&
      uploadId!.isNotEmpty &&
      objectKey != null &&
      objectKey!.isNotEmpty &&
      (partSize ?? 0) > 0 &&
      (totalParts ?? 0) > 0;

  @override
  List<Object?> get props => [uploadId, objectKey, partSize, totalParts];
}

/// 「分片预签名」接口返回的单个分片凭证。
@JsonSerializable()
class PresignedPartUrl extends Equatable {
  @JsonKey(fromJson: asInt)
  final int? partNumber;
  final String? uploadUrl;

  const PresignedPartUrl({this.partNumber, this.uploadUrl});

  factory PresignedPartUrl.fromJson(Map<String, dynamic> json) =>
      _$PresignedPartUrlFromJson(json);

  Map<String, dynamic> toJson() => _$PresignedPartUrlToJson(this);

  bool get isValid =>
      (partNumber ?? 0) >= 1 && uploadUrl != null && uploadUrl!.isNotEmpty;

  @override
  List<Object?> get props => [partNumber, uploadUrl];
}

/// 「分片预签名」接口返回的批量凭证集合。
@JsonSerializable()
class PresignedPartUrls extends Equatable {
  final List<PresignedPartUrl>? parts;

  /// 凭证有效期（秒）。
  @JsonKey(fromJson: asInt)
  final int? expireSeconds;

  const PresignedPartUrls({this.parts, this.expireSeconds});

  factory PresignedPartUrls.fromJson(Map<String, dynamic> json) =>
      _$PresignedPartUrlsFromJson(json);

  Map<String, dynamic> toJson() => _$PresignedPartUrlsToJson(this);

  /// 过滤非法条目并按 partNumber 升序排序。
  List<PresignedPartUrl> get validParts {
    final result =
        (parts ?? const []).where((part) => part.isValid).toList()
          ..sort((a, b) => a.partNumber!.compareTo(b.partNumber!));
    return result;
  }

  @override
  List<Object?> get props => [parts, expireSeconds];
}

/// complete（POST 受理 / GET 轮询）共用的响应信封。
///
/// POST 成功受理返回 `{objectKey, status: "PROCESSING"}`；GET 轮询返回
/// 三态 `{status, objectKey, errorCode}`，也可能直接返回错误信封
/// （由仓储层消解为 [MultipartFinalizeStatus]）。
@JsonSerializable()
class MultipartCompleteEnvelope extends Equatable {
  final String? status;
  final String? objectKey;

  @JsonKey(fromJson: asInt)
  final int? errorCode;

  const MultipartCompleteEnvelope({
    this.status,
    this.objectKey,
    this.errorCode,
  });

  factory MultipartCompleteEnvelope.fromJson(Map<String, dynamic> json) =>
      _$MultipartCompleteEnvelopeFromJson(json);

  Map<String, dynamic> toJson() => _$MultipartCompleteEnvelopeToJson(this);

  @override
  List<Object?> get props => [status, objectKey, errorCode];
}

/// complete 阶段的语义化结果：仓储层已消解「三态 data vs 错误信封」的
/// 二义性，执行器/轮询器不再触碰裸业务码。
enum MultipartFinalizeOutcome {
  /// 合并进行中，继续轮询。
  processing,

  /// 合并完成，objectKey 可用于后续创建/更新剧集。
  ready,

  /// FAILED + 100500：分片都还在 S3 上，只是合并任务没跑成，
  /// 幂等重发一次 complete 即可，不要重传文件。
  failedSystem,

  /// 121026（错误信封或 FAILED 态）：uploadId 已失效，
  /// 清本地记录后重新 initiate（全片重传）。
  uploadInvalid,

  /// 轮询撞上错误信封 100500：本次查询失败的瞬时错误，
  /// 不清记录、不重传，下一轮继续轮询。
  transientError,

  /// FAILED 且 errorCode 不在预期集合内：终态失败。
  failed,
}

/// [MultipartFinalizeOutcome] 的载体，`ready` 时携带最终 objectKey。
class MultipartFinalizeStatus extends Equatable {
  final MultipartFinalizeOutcome outcome;
  final String? objectKey;
  final int? errorCode;

  const MultipartFinalizeStatus(this.outcome, {this.objectKey, this.errorCode});

  @override
  List<Object?> get props => [outcome, objectKey, errorCode];
}
