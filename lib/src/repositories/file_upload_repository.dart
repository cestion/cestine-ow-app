import 'dart:io';

import '../core/result.dart';
import '../core/json_helpers.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import '../api/story_api_client.dart';
import '../api/upload_cancel_token.dart';

export '../model/upload_task_model.dart' show FileCategory;

abstract class FileUploadRepository {
  /// 向后端创建一次上传会话，返回后端生成的 uploadSessionId。
  /// 同一批次（如批量剧集）的多个文件应复用同一个会话。
  Future<Result<UploadSession>> createUploadSession();

  /// 向后端换取预签名上传凭证。[uploadSessionId] 由后端生成，必须传入。
  Future<Result<PresignUploadResult>> presign({
    required String contentType,
    required FileCategory fileCategory,
    required String fileName,
    required String uploadSessionId,
  });

  /// 上传本地文件：先换取预签名，再直传对象存储，成功后返回可公开访问的文件 URL。
  ///
  /// 返回的 URL 由预签名上传地址去掉签名查询串推导而来，因此始终指向正确的
  /// 对象存储域名（各环境自动适配）。[onProgress] 上报 0.0~1.0 的上传进度。
  /// [uploadSessionId] 用于关联同一批次（如批量剧集）；不传则自动向后端创建一个新会话。
  ///
  /// 实现通常委托给 [uploadFileWithObjectKey] 并取 `.publicUrl`。
  Future<Result<String>> uploadFile({
    required String filePath,
    required FileCategory fileCategory,
    String? contentType,
    String? uploadSessionId,
    void Function(double progress)? onProgress,
    UploadCancelToken? cancelToken,
  });

  /// 与 [uploadFile] 行为一致，但返回包含 `objectKey` 的 [UploadedFile]，
  /// 供需要回传 objectKey 给后端的场景（如角色头像 `avatarObjectKey`）使用。
  Future<Result<UploadedFile>> uploadFileWithObjectKey({
    required String filePath,
    required FileCategory fileCategory,
    String? contentType,
    String? uploadSessionId,
    void Function(double progress)? onProgress,
    UploadCancelToken? cancelToken,
  });

  /// 初始化分片上传（仅 `fileCategory=episode` 视频文件）。
  ///
  /// 返回 `uploadId`/`objectKey`/`partSize`/`totalParts`，其中
  /// `objectKey` 语义与单文件上传完全一致。
  Future<Result<InitiateMultipartResult>> initiateMultipart({
    required String uploadSessionId,
    required String fileName,
    required String contentType,
    required int fileSize,
  });

  /// 批量换取分片预签名 URL（支持全量或仅缺失分片，凭证可重复获取）。
  Future<Result<List<PresignedPartUrl>>> presignPartUrls({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
    required List<int> partNumbers,
  });

  /// 查询已完成分片（`{partNumber, eTag, size}`，按 partNumber 升序），
  /// 用于断点续传前的本地/服务端对账。
  Future<Result<List<UploadedPart>>> listCompletedParts({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  });

  /// 提交合并（complete）：异步受理，仅代表后端开始合并。
  ///
  /// 返回语义化的 [MultipartFinalizeStatus]；对同一 objectKey 重复调用
  /// 是幂等的。同步失败（如 121013 总大小超限，后端已自动 abort）以
  /// `Result.failure` 上抛。
  Future<Result<MultipartFinalizeStatus>> submitComplete({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
    required List<UploadedPart> parts,
  });

  /// 轮询合并状态（1~2s 间隔、由调用方控制总超时）。
  ///
  /// 契约规定该接口可能返回三态 data 或错误信封，二义性在此消解：
  /// 121026 → [MultipartFinalizeOutcome.uploadInvalid]，
  /// 错误信封 100500 → [MultipartFinalizeOutcome.transientError]。
  Future<Result<MultipartFinalizeStatus>> pollCompleteStatus({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  });

  /// 取消分片上传并清理对象存储残片。对已不存在的 `uploadId` 幂等成功。
  Future<Result<void>> abortMultipart({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  });

  Future<void> dispose();
}

class FileUploadRepositoryImpl implements FileUploadRepository {
  /// 创建上传会话接口路径（若后端不同请在此调整）。
  static const String _sessionPath = '/api/mini-drama/creator/uploads/sessions';

  /// 预签名接口路径（若后端不同请在此调整）。
  static const String _presignPath = '/api/mini-drama/creator/uploads/presign';

  /// 分片上传协议端点（episode-multipart-upload-api.md）。
  static const String _multipartInitiatePath =
      '/api/mini-drama/creator/uploads/multipart/initiate';
  static const String _multipartPartsPresignPath =
      '/api/mini-drama/creator/uploads/multipart/parts/presign';
  static const String _multipartPartsPath =
      '/api/mini-drama/creator/uploads/multipart/parts';
  static const String _multipartCompletePath =
      '/api/mini-drama/creator/uploads/multipart/complete';
  static const String _multipartAbortPath =
      '/api/mini-drama/creator/uploads/multipart/abort';

  final StoryApiClient _api;

  FileUploadRepositoryImpl(this._api);

  @override
  Future<Result<UploadSession>> createUploadSession() =>
      _api.safePost(_sessionPath, decoder: decodeWith(UploadSession.fromJson));

  @override
  Future<Result<String>> uploadFile({
    required String filePath,
    required FileCategory fileCategory,
    String? contentType,
    String? uploadSessionId,
    void Function(double progress)? onProgress,
    UploadCancelToken? cancelToken,
  }) async {
    final result = await uploadFileWithObjectKey(
      filePath: filePath,
      fileCategory: fileCategory,
      contentType: contentType,
      uploadSessionId: uploadSessionId,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
    return result.map((f) => f.publicUrl);
  }

  @override
  Future<Result<PresignUploadResult>> presign({
    required String contentType,
    required FileCategory fileCategory,
    required String fileName,
    required String uploadSessionId,
  }) {
    return _api.safePost(
      _presignPath,
      body: {
        'contentType': contentType,
        'fileCategory': fileCategory.value,
        'fileName': fileName,
        'uploadSessionId': uploadSessionId,
      },
      decoder: decodeWith(PresignUploadResult.fromJson),
    );
  }

  @override
  Future<Result<UploadedFile>> uploadFileWithObjectKey({
    required String filePath,
    required FileCategory fileCategory,
    String? contentType,
    String? uploadSessionId,
    void Function(double progress)? onProgress,
    UploadCancelToken? cancelToken,
  }) async {
    final file = File(filePath);
    final fileName = filePath.split(Platform.pathSeparator).last;
    final resolvedContentType = contentType ?? _inferContentType(fileName);
    StoryLogger.i(
      'uploadFile 开始: file=$fileName '
      'category=${fileCategory.value} contentType=$resolvedContentType '
      'sessionId=$uploadSessionId',
      tag: 'FileUpload',
    );

    var sessionId = uploadSessionId;
    if (sessionId == null) {
      final sessionResult = await createUploadSession();
      if (sessionResult case Failure(:final error)) {
        StoryLogger.e(
          'createUploadSession 失败: ${error.userMessage}',
          tag: 'FileUpload',
          error: error,
        );
        return Result.failure(error);
      }
      final session = sessionResult.dataOrNull!;
      if (!session.isValid) {
        StoryLogger.e(
          'createUploadSession 返回无效会话: $session',
          tag: 'FileUpload',
        );
        return Result.failure(
          ApiError.parse(
            'Failed to create upload session: missing uploadSessionId',
          ),
        );
      }
      sessionId = session.uploadSessionId!;
      StoryLogger.i(
        'createUploadSession 成功 sessionId=$sessionId',
        tag: 'FileUpload',
      );
    }

    final presignResult = await presign(
      contentType: resolvedContentType,
      fileCategory: fileCategory,
      fileName: fileName,
      uploadSessionId: sessionId,
    );
    if (presignResult case Failure(:final error)) {
      StoryLogger.e(
        'presign 失败: ${error.userMessage}',
        tag: 'FileUpload',
        error: error,
      );
      return Result.failure(error);
    }
    final presigned = presignResult.dataOrNull!;
    if (!presigned.isValid) {
      StoryLogger.e(
        'presign 返回无效结果: hasUrl=${presigned.uploadUrl?.isNotEmpty == true} '
        'hasObjectKey=${presigned.objectKey?.isNotEmpty == true}',
        tag: 'FileUpload',
      );
      return Result.failure(
        ApiError.parse('Presign response missing upload URL or objectKey'),
      );
    }
    StoryLogger.i(
      'presign 成功: objectKey=${presigned.objectKey} '
      'url=${_api.sanitizeUriForLog(Uri.parse(presigned.uploadUrl!))} '
      'headerNames=${presigned.requiredHeaders?.keys.toList()}',
      tag: 'FileUpload',
    );

    final length = await file.length();
    final headers = <String, String>{...?presigned.requiredHeaders};
    // 若签名头未提供有效 Content-Type，则补上推断值以匹配已签名的类型。
    final hasContentType = headers.entries.any(
      (e) => e.key.toLowerCase() == 'content-type' && e.value.isNotEmpty,
    );
    if (!hasContentType) {
      headers['Content-Type'] = resolvedContentType;
    }

    StoryLogger.i(
      'uploadBytes 开始: file=$fileName contentLength=$length',
      tag: 'FileUpload',
    );
    final uploadResult = await _api.uploadBytes(
      url: presigned.uploadUrl!,
      byteStream: file.openRead(),
      contentLength: length,
      headers: headers,
      onProgress: onProgress == null
          ? null
          : (sent, total) {
              if (total > 0) onProgress(sent / total);
            },
      cancelToken: cancelToken,
    );
    return uploadResult.map((_) {
      final publicUrl = _publicUrlOf(presigned.uploadUrl!);
      final objectKey = presigned.objectKey!;
      StoryLogger.i(
        'uploadBytes 成功: file=$fileName objectKey=$objectKey '
        'publicUrl=$publicUrl',
        tag: 'FileUpload',
      );
      return UploadedFile(objectKey: objectKey, publicUrl: publicUrl);
    });
  }

  @override
  Future<Result<InitiateMultipartResult>> initiateMultipart({
    required String uploadSessionId,
    required String fileName,
    required String contentType,
    required int fileSize,
  }) {
    return _api.safePost(
      _multipartInitiatePath,
      body: {
        'uploadSessionId': uploadSessionId,
        'fileName': fileName,
        'contentType': contentType,
        'fileSize': fileSize,
      },
      decoder: decodeWith(InitiateMultipartResult.fromJson),
    );
  }

  @override
  Future<Result<List<PresignedPartUrl>>> presignPartUrls({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
    required List<int> partNumbers,
  }) {
    return _api.safePost(
      _multipartPartsPresignPath,
      body: {
        'uploadSessionId': uploadSessionId,
        'objectKey': objectKey,
        'uploadId': uploadId,
        'partNumbers': partNumbers,
      },
      decoder: _decodePresignedPartUrls,
      // 换取凭证是无副作用的读操作，网络层异常可安全重试。
      retry: true,
    );
  }

  @override
  Future<Result<List<UploadedPart>>> listCompletedParts({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  }) {
    return _api.safeGet(
      _multipartPartsPath,
      query: _multipartQuery(
        uploadSessionId: uploadSessionId,
        objectKey: objectKey,
        uploadId: uploadId,
      ),
      decoder: _decodeCompletedParts,
    );
  }

  @override
  Future<Result<MultipartFinalizeStatus>> submitComplete({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
    required List<UploadedPart> parts,
  }) {
    return _api
        .safePost(
          _multipartCompletePath,
          body: {
            'uploadSessionId': uploadSessionId,
            'objectKey': objectKey,
            'uploadId': uploadId,
            'parts': [
              for (final part in parts)
                {'partNumber': part.partNumber, 'eTag': part.eTag},
            ],
          },
          decoder: decodeWith(MultipartCompleteEnvelope.fromJson),
          // 契约明确重复调用幂等（后端不会重复提交合并任务）。
          retry: true,
        )
        .then(_finalizeStatusFromSubmit);
  }

  @override
  Future<Result<MultipartFinalizeStatus>> pollCompleteStatus({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  }) {
    return _api
        .safeGet(
          _multipartCompletePath,
          query: _multipartQuery(
            uploadSessionId: uploadSessionId,
            objectKey: objectKey,
            uploadId: uploadId,
          ),
          decoder: decodeWith(MultipartCompleteEnvelope.fromJson),
        )
        .then(_finalizeStatusFromPoll);
  }

  @override
  Future<Result<void>> abortMultipart({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  }) {
    return _api.safePost<void>(
      _multipartAbortPath,
      body: {
        'uploadSessionId': uploadSessionId,
        'objectKey': objectKey,
        'uploadId': uploadId,
      },
      decoder: (dynamic data) {},
      // 契约明确对已不存在的 uploadId 幂等成功。
      retry: true,
    );
  }

  Map<String, dynamic> _multipartQuery({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  }) => {
        'uploadSessionId': uploadSessionId,
        'objectKey': objectKey,
        'uploadId': uploadId,
      };

  List<PresignedPartUrl> _decodePresignedPartUrls(dynamic data) {
    if (data is! Map) return const [];
    final rawParts = data['parts'];
    if (rawParts is! List) return const [];
    final parts = <PresignedPartUrl>[];
    for (final raw in rawParts) {
      if (raw is! Map) continue;
      try {
        parts.add(PresignedPartUrl.fromJson(Map<String, dynamic>.from(raw)));
      } catch (_) {
        // 单条凭证损坏不影响其余分片，缺失的由调用方补签。
      }
    }
    final valid = parts.where((part) => part.isValid).toList()
      ..sort((a, b) => a.partNumber!.compareTo(b.partNumber!));
    return valid;
  }

  List<UploadedPart> _decodeCompletedParts(dynamic data) {
    if (data is! Map) return const [];
    final rawParts = data['parts'];
    if (rawParts is! List) return const [];
    final parts = <UploadedPart>[];
    for (final raw in rawParts) {
      final part = UploadedPart.fromMap(raw);
      if (part != null) parts.add(part);
    }
    parts.sort((a, b) => a.partNumber.compareTo(b.partNumber));
    return parts;
  }

  /// POST complete 的语义映射：受理未知/缺失 status 时按 PROCESSING 处理
  /// （请求已成功，合并结果交给轮询确认）。
  Result<MultipartFinalizeStatus> _finalizeStatusFromSubmit(
    Result<MultipartCompleteEnvelope> result,
  ) {
    return _mapFinalizeEnvelope(result, defaultProcessing: true);
  }

  /// GET complete 的语义映射：意外 data 形状按瞬时错误处理，
  /// 交由轮询节奏与总超时兜底。
  Result<MultipartFinalizeStatus> _finalizeStatusFromPoll(
    Result<MultipartCompleteEnvelope> result,
  ) {
    return _mapFinalizeEnvelope(result, defaultProcessing: false);
  }

  Result<MultipartFinalizeStatus> _mapFinalizeEnvelope(
    Result<MultipartCompleteEnvelope> result, {
    required bool defaultProcessing,
  }) {
    if (result case Failure(:final error)) {
      final semantic = _semanticFromEnvelopeError(error);
      if (semantic != null) return Result.success(semantic);
      return Result.failure(error);
    }
    final envelope = result.dataOrNull!;
    return Result.success(
      _semanticFromEnvelope(envelope, defaultProcessing: defaultProcessing),
    );
  }

  MultipartFinalizeStatus? _semanticFromEnvelopeError(ApiError error) {
    if (error is! BusinessError) return null;
    if (error.code == MultipartUploadErrorCodes.multipartUploadInvalid) {
      return MultipartFinalizeStatus(
        MultipartFinalizeOutcome.uploadInvalid,
        errorCode: error.code,
      );
    }
    if (error.code == MultipartUploadErrorCodes.systemError) {
      return MultipartFinalizeStatus(
        MultipartFinalizeOutcome.transientError,
        errorCode: error.code,
      );
    }
    return null;
  }

  MultipartFinalizeStatus _semanticFromEnvelope(
    MultipartCompleteEnvelope envelope, {
    required bool defaultProcessing,
  }) {
    final status = envelope.status?.toUpperCase();
    final objectKey = envelope.objectKey;
    return switch (status) {
      'READY' => MultipartFinalizeStatus(
          MultipartFinalizeOutcome.ready,
          objectKey: objectKey,
        ),
      'FAILED' => switch (envelope.errorCode) {
          MultipartUploadErrorCodes.systemError => MultipartFinalizeStatus(
              MultipartFinalizeOutcome.failedSystem,
              objectKey: objectKey,
              errorCode: envelope.errorCode,
            ),
          MultipartUploadErrorCodes.multipartUploadInvalid =>
            MultipartFinalizeStatus(
              MultipartFinalizeOutcome.uploadInvalid,
              objectKey: objectKey,
              errorCode: envelope.errorCode,
            ),
          _ => MultipartFinalizeStatus(
              MultipartFinalizeOutcome.failed,
              objectKey: objectKey,
              errorCode: envelope.errorCode,
            ),
        },
      'PROCESSING' => MultipartFinalizeStatus(
          MultipartFinalizeOutcome.processing,
          objectKey: objectKey,
        ),
      _ => defaultProcessing
          ? MultipartFinalizeStatus(
              MultipartFinalizeOutcome.processing,
              objectKey: objectKey,
            )
          : const MultipartFinalizeStatus(MultipartFinalizeOutcome.transientError),
    };
  }

  /// 由预签名上传地址推导对象的公开访问地址（去掉签名查询串）。
  String _publicUrlOf(String uploadUrl) {
    final uri = Uri.parse(uploadUrl);
    return '${uri.origin}${uri.path}';
  }

  /// 依据文件扩展名推断 MIME 类型，未知时回退到二进制流。
  String _inferContentType(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot >= 0 ? fileName.substring(dot + 1).toLowerCase() : '';
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'm4v' => 'video/x-m4v',
      _ => 'application/octet-stream',
    };
  }

  @override
  Future<void> dispose() async {}
}
