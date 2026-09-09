import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';

import '../api/story_api_client.dart';
import '../api/upload_cancel_token.dart';
import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import '../repositories/file_upload_repository.dart';
import '../services/connectivity_service.dart';
import 'upload_executor.dart';

/// Foreground multipart executor for episode videos with byte-level resume.
///
/// Owns Phase A only: reconcile the checkpoint against the backend, transfer
/// the missing parts with a small concurrency pool, and submit the
/// (asynchronous) merge request. Merge polling (Phase B) belongs to the
/// coordinator so a long poll never blocks the queue or trips the foreground
/// stall detector.
///
/// Resume contract (episode-multipart-upload-api.md):
/// - The persisted checkpoint never stores presigned URLs; every attempt
///   re-presigns the missing parts.
/// - Reconciliation trusts the server part list: a part that finished on the
///   wire but was not persisted is simply re-uploaded (idempotent by part).
/// - A partially-transferred part is discarded on failure: only fully
///   acknowledged parts (with ETag) enter the checkpoint.
/// - `MULTIPART_UPLOAD_INVALID` (121026) restarts the attempt once with a
///   fresh uploadId under the same session.
class MultipartResumableUploadExecutor implements UploadExecutor {
  MultipartResumableUploadExecutor(
    this._repository,
    this._api,
    this._connectivity,
  );

  final FileUploadRepository _repository;
  final StoryApiClient _api;
  final ConnectivityService _connectivity;

  /// Part PUT concurrency on Wi-Fi (PRD: 3~5; backend doc: 3~4).
  @visibleForTesting
  static const int wifiPartConcurrency = 4;

  /// Part PUT concurrency on cellular, protecting downstream bandwidth.
  @visibleForTesting
  static const int cellularPartConcurrency = 2;

  /// Quick in-place retries per part before failing the whole attempt.
  @visibleForTesting
  static const int maxPartRetries = 2;

  /// One 121026 restart with a fresh uploadId per attempt.
  @visibleForTesting
  static const int maxReinitiateRounds = 1;

  /// One idempotent complete resend when the merge task was lost (FAILED +
  /// 100500 or a transient envelope error).
  @visibleForTesting
  static const int maxCompleteResends = 1;

  /// Progress callbacks are throttled to this interval (part completions
  /// always report) to avoid callback storms across concurrent workers.
  static const _progressIntervalMs = 100;

  @override
  bool get supportsBackground => false;

  @override
  bool get supportsResume => true;

  @override
  Future<Result<UploadAttemptOutcome>> upload(
    UploadTask task, {
    required UploadCancelToken cancelToken,
    required void Function(double progress) onProgress,
    MultipartCheckpointSink? onCheckpoint,
  }) async {
    if (cancelToken.isCanceled) {
      return Result.failure(
        ApiError.unknown(
          'Upload canceled',
          exception: const UploadCanceledException(),
        ),
      );
    }
    final file = File(task.localFilePath);
    if (!await file.exists()) {
      return Result.failure(ApiError.parse('Local upload file is missing'));
    }
    final fileSize = await file.length();
    if (fileSize <= 0 || fileSize != task.fileSize) {
      return Result.failure(
        ApiError.parse('Local file size changed since enqueue'),
      );
    }

    final progressReporter = _ProgressThrottle(onProgress);
    var checkpoint = task;
    var reinitiated = false;

    while (true) {
      final resolved = await _resolveCheckpoint(checkpoint, onCheckpoint);
      if (resolved case Failure(:final error)) {
        if (!MultipartUploadErrorCodes.isMultipartUploadInvalid(error) ||
            reinitiated) {
          return Result.failure(error);
        }
        reinitiated = true;
        checkpoint = checkpoint.copyWith(resetMultipartState: true);
        onCheckpoint?.call(checkpoint);
        StoryLogger.w(
          'Multipart uploadId invalid; restarting with a fresh initiate',
          tag: 'MultipartUpload',
        );
        continue;
      }
      checkpoint = resolved.dataOrNull!;

      final transferred = await _transferMissingParts(
        checkpoint,
        file,
        fileSize,
        cancelToken,
        progressReporter,
        onCheckpoint,
      );
      if (transferred case Failure(:final error)) {
        if (!MultipartUploadErrorCodes.isMultipartUploadInvalid(error) ||
            reinitiated) {
          return Result.failure(error);
        }
        reinitiated = true;
        checkpoint = checkpoint.copyWith(resetMultipartState: true);
        onCheckpoint?.call(checkpoint);
        StoryLogger.w(
          'Multipart uploadId invalid during presign; restarting',
          tag: 'MultipartUpload',
        );
        continue;
      }
      final (nextCheckpoint, publicUrl) = transferred.dataOrNull!;
      checkpoint = nextCheckpoint;

      final merge = await _submitMerge(checkpoint, onCheckpoint);
      if (merge case Failure(:final error)) {
        if (!MultipartUploadErrorCodes.isMultipartUploadInvalid(error) ||
            reinitiated) {
          return Result.failure(error);
        }
        reinitiated = true;
        checkpoint = checkpoint.copyWith(resetMultipartState: true);
        onCheckpoint?.call(checkpoint);
        StoryLogger.w(
          'Multipart uploadId invalid at complete; restarting',
          tag: 'MultipartUpload',
        );
        continue;
      }
      return Result.success(
        switch (merge.dataOrNull!) {
          _MergeResult.ready => UploadReady(
              UploadedFile(
                objectKey: checkpoint.multipartObjectKey!,
                publicUrl: publicUrl ?? '',
              ),
            ),
          _MergeResult.pending => UploadFinalizePending(
              uploadSessionId: task.uploadSessionId,
              uploadId: checkpoint.multipartUploadId!,
              objectKey: checkpoint.multipartObjectKey!,
              publicUrl: publicUrl,
            ),
        },
      );
    }
  }

  /// Initiates a fresh multipart upload, or reconciles the persisted
  /// checkpoint against the server part list (server wins).
  Future<Result<UploadTask>> _resolveCheckpoint(
    UploadTask task,
    MultipartCheckpointSink? onCheckpoint,
  ) async {
    if (task.multipartUploadId == null) {
      final result = await _repository.initiateMultipart(
        uploadSessionId: task.uploadSessionId,
        fileName: task.fileName,
        contentType: task.contentType,
        fileSize: task.fileSize,
      );
      if (result case Failure(:final error)) return Result.failure(error);
      final initiated = result.dataOrNull!;
      if (!initiated.isValid) {
        StoryLogger.e(
          'initiateMultipart returned invalid data: '
          'uploadId=${initiated.uploadId} objectKey=${initiated.objectKey} '
          'partSize=${initiated.partSize} totalParts=${initiated.totalParts}',
          tag: 'MultipartUpload',
        );
        return Result.failure(
          ApiError.parse('Invalid multipart initiate response'),
        );
      }
      StoryLogger.i(
        'initiateMultipart 成功: uploadId=${initiated.uploadId} '
        'partSize=${initiated.partSize} totalParts=${initiated.totalParts}',
        tag: 'MultipartUpload',
      );
      final next = task.copyWith(
        multipartUploadId: initiated.uploadId,
        multipartObjectKey: initiated.objectKey,
        partSize: initiated.partSize,
        totalParts: initiated.totalParts,
        completedParts: const [],
        uploadedBytes: 0,
        multipartPhase: MultipartPhase.partsUploading,
      );
      onCheckpoint?.call(next);
      return Result.success(next);
    }

    final result = await _repository.listCompletedParts(
      uploadSessionId: task.uploadSessionId,
      objectKey: task.multipartObjectKey!,
      uploadId: task.multipartUploadId!,
    );
    if (result case Failure(:final error)) return Result.failure(error);
    final serverParts = result.dataOrNull!;
    final uploadedBytes = serverParts.fold<int>(
      0,
      (sum, part) => sum + part.size,
    );
    final changed = !_sameParts(serverParts, task.completedParts) ||
        task.uploadedBytes != uploadedBytes;
    final next = changed || task.multipartPhase != MultipartPhase.partsUploading
        ? task.copyWith(
            completedParts: serverParts,
            uploadedBytes: uploadedBytes,
            multipartPhase: MultipartPhase.partsUploading,
          )
        : task;
    if (!identical(next, task)) onCheckpoint?.call(next);
    StoryLogger.i(
      '断点对账: serverParts=${serverParts.length} '
      'localParts=${task.completedParts.length} uploadedBytes=$uploadedBytes',
      tag: 'MultipartUpload',
    );
    return Result.success(next);
  }

  /// Transfers every missing part through a bounded concurrency pool.
  ///
  /// Returns the checkpoint with all parts complete plus the best-effort
  /// public URL derived from a presigned part URL.
  Future<Result<(UploadTask, String?)>> _transferMissingParts(
    UploadTask task,
    File file,
    int fileSize,
    UploadCancelToken cancelToken,
    _ProgressThrottle progressReporter,
    MultipartCheckpointSink? onCheckpoint,
  ) async {
    final partSize = task.partSize!;
    final totalParts = task.totalParts!;
    final completed = {
      for (final part in task.completedParts) part.partNumber: part,
    };
    final missing = [
      for (var n = 1; n <= totalParts; n++)
        if (!completed.containsKey(n)) n,
    ];

    progressReporter.report(
      completed.values.fold<int>(0, (sum, part) => sum + part.size) / fileSize,
      force: true,
    );
    if (missing.isEmpty) return Result.success((task, null));

    final presignResult = await _repository.presignPartUrls(
      uploadSessionId: task.uploadSessionId,
      objectKey: task.multipartObjectKey!,
      uploadId: task.multipartUploadId!,
      partNumbers: missing,
    );
    if (presignResult case Failure(:final error)) return Result.failure(error);
    final presigned = presignResult.dataOrNull!;
    final urls = {
      for (final part in presigned) part.partNumber!: part.uploadUrl!,
    };
    if (urls.length != missing.length) {
      return Result.failure(
        ApiError.parse('Presign omitted some requested parts'),
      );
    }
    final publicUrl = _publicUrlOf(urls[missing.first]!);

    var current = task;
    var nextIndex = 0;
    ApiError? firstError;
    final inFlight = <int, int>{};

    Future<void> worker() async {
      while (firstError == null && !cancelToken.isCanceled) {
        final index = nextIndex++;
        if (index >= missing.length) return;
        final partNumber = missing[index];
        final start = (partNumber - 1) * partSize;
        var end = start + partSize;
        if (end > fileSize) end = fileSize;
        final length = end - start;
        var attempt = 0;
        while (true) {
          if (cancelToken.isCanceled || firstError != null) return;
          final result = await _api.uploadPart(
            url: urls[partNumber]!,
            byteStream: file.openRead(start, end),
            contentLength: length,
            onProgress: (sent, total) {
              inFlight[partNumber] = sent;
              progressReporter.report(
                (current.uploadedBytes +
                        inFlight.values.fold<int>(0, (sum, v) => sum + v)) /
                    fileSize,
              );
            },
            cancelToken: cancelToken,
          );
          if (result case Success(:final data)) {
            inFlight.remove(partNumber);
            completed[partNumber] = UploadedPart(
              partNumber: partNumber,
              eTag: data,
              size: length,
            );
            final parts = completed.values.toList()
              ..sort((a, b) => a.partNumber.compareTo(b.partNumber));
            current = current.copyWith(
              completedParts: parts,
              uploadedBytes: parts.fold<int>(0, (sum, part) => sum + part.size),
            );
            onCheckpoint?.call(current);
            // Same aggregation as the throttled in-flight reports: a part
            // acknowledgement moves its bytes from "in-flight" to "completed",
            // so the sum is conserved and concurrent parts mid-stream keep
            // the progress monotonic (reporting completed-only here made the
            // bar jump backwards when several parts finished out of order).
            progressReporter.report(
              (current.uploadedBytes +
                      inFlight.values.fold<int>(0, (sum, v) => sum + v)) /
                  fileSize,
              force: true,
            );
            break;
          }
          attempt++;
          inFlight.remove(partNumber);
          if (attempt > maxPartRetries) {
            firstError ??= result.errorOrNull!;
            StoryLogger.w(
              '分片上传失败: part=$partNumber attempts=$attempt '
              'error=${result.errorOrNull?.userMessage}',
              tag: 'MultipartUpload',
            );
            return;
          }
          await Future<void>.delayed(
            Duration(milliseconds: 200 * (1 << (attempt - 1))),
          );
        }
      }
    }

    final concurrency = _connectivity.isWifi
        ? wifiPartConcurrency
        : cellularPartConcurrency;
    final workers = List.generate(
      concurrency,
      (_) => worker(),
      growable: false,
    );
    await Future.wait(workers);

    if (cancelToken.isCanceled) {
      return Result.failure(
        ApiError.unknown(
          'Upload canceled',
          exception: const UploadCanceledException(),
        ),
      );
    }
    if (firstError != null) return Result.failure(firstError!);
    return Result.success((current, publicUrl));
  }

  /// Submits the merge request. A lost merge task (FAILED + 100500) or a
  /// transient envelope error triggers one idempotent resend; parts are on
  /// object storage either way, so no re-upload happens here.
  ///
  /// Returns [_MergeResult.pending] when the merge was accepted (the caller
  /// assembles the finalize-pending outcome) or [_MergeResult.ready] when a
  /// repeat submit found the merge already finished.
  Future<Result<_MergeResult>> _submitMerge(
    UploadTask task,
    MultipartCheckpointSink? onCheckpoint,
  ) async {
    var submits = 0;
    while (true) {
      final result = await _repository.submitComplete(
        uploadSessionId: task.uploadSessionId,
        objectKey: task.multipartObjectKey!,
        uploadId: task.multipartUploadId!,
        parts: task.completedParts,
      );
      if (result case Failure(:final error)) return Result.failure(error);
      final status = result.dataOrNull!;
      switch (status.outcome) {
        case MultipartFinalizeOutcome.ready:
          StoryLogger.i(
            'complete 返回 READY（幂等重放）: objectKey=${status.objectKey}',
            tag: 'MultipartUpload',
          );
          return Result.success(_MergeResult.ready);
        case MultipartFinalizeOutcome.processing:
          onCheckpoint?.call(
            task.copyWith(multipartPhase: MultipartPhase.finalizeRequested),
          );
          StoryLogger.i(
            'complete 受理: objectKey=${task.multipartObjectKey}',
            tag: 'MultipartUpload',
          );
          return Result.success(_MergeResult.pending);
        case MultipartFinalizeOutcome.failedSystem:
        case MultipartFinalizeOutcome.transientError:
          submits++;
          if (submits > maxCompleteResends) {
            StoryLogger.w(
              'complete 重发后仍失败: errorCode=${status.errorCode}',
              tag: 'MultipartUpload',
            );
            return Result.failure(
              ApiError.business(
                status.errorCode ?? MultipartUploadErrorCodes.systemError,
                'Multipart merge failed',
              ),
            );
          }
          StoryLogger.w(
            'complete 需重发（合并任务丢失/瞬时错误）: errorCode='
            '${status.errorCode}',
            tag: 'MultipartUpload',
          );
          continue;
        case MultipartFinalizeOutcome.uploadInvalid:
          return Result.failure(
            ApiError.business(
              MultipartUploadErrorCodes.multipartUploadInvalid,
              'MULTIPART_UPLOAD_INVALID',
            ),
          );
        case MultipartFinalizeOutcome.failed:
          return Result.failure(
            ApiError.business(
              status.errorCode ?? 0,
              'Multipart merge failed',
            ),
          );
      }
    }
  }

  bool _sameParts(List<UploadedPart> a, List<UploadedPart> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Derives the object's public URL from a presigned part URL by stripping
  /// the signature query string (same convention as the single-PUT flow).
  String _publicUrlOf(String partUrl) {
    final uri = Uri.parse(partUrl);
    return '${uri.origin}${uri.path}';
  }
}

/// Signal from [_submitMerge]: merge accepted (pending) vs already done.
enum _MergeResult { pending, ready }

/// Time-based progress throttle; forced reports (part completion, phase
/// changes) always pass through.
class _ProgressThrottle {  final void Function(double progress) _onProgress;
  int _lastReportAt = 0;

  _ProgressThrottle(this._onProgress);

  void report(double progress, {bool force = false}) {
    if (!force) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastReportAt <
          MultipartResumableUploadExecutor._progressIntervalMs) {
        return;
      }
      _lastReportAt = now;
    }
    _onProgress(progress.clamp(0.0, 1.0));
  }
}
