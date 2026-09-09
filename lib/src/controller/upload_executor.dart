import '../api/upload_cancel_token.dart';
import '../core/result.dart';
import '../model/models.dart';

/// Multipart checkpoint write-back while a task runs.
///
/// The executor calls this with a fresh [UploadTask.copyWith] snapshot after
/// durable state changes (initiate, reconciled parts, each completed part,
/// finalize submission) so the coordinator can persist resume state.
typedef MultipartCheckpointSink = void Function(UploadTask task);

/// Pluggable execution boundary for one upload attempt.
///
/// Today this is a foreground single-PUT implementation plus a multipart
/// resumable implementation. A native background implementation can replace
/// either without changing queue/UI code.
abstract interface class UploadExecutor {
  bool get supportsBackground;
  bool get supportsResume;

  Future<Result<UploadAttemptOutcome>> upload(
    UploadTask task, {
    required UploadCancelToken cancelToken,
    required void Function(double progress) onProgress,
    MultipartCheckpointSink? onCheckpoint,
  });
}

/// Result payload of one executor attempt.
sealed class UploadAttemptOutcome {
  const UploadAttemptOutcome();
}

/// The object is fully uploaded and ready to use (single-PUT path, or a
/// multipart merge that was already finished when complete was submitted).
class UploadReady extends UploadAttemptOutcome {
  final UploadedFile file;

  const UploadReady(this.file);
}

/// All parts are on object storage and the (asynchronous) merge request was
/// accepted by the backend. The caller must poll the finalize status until
/// READY before treating the object as uploaded.
class UploadFinalizePending extends UploadAttemptOutcome {
  final String uploadSessionId;
  final String uploadId;
  final String objectKey;

  /// Best-effort public URL derived from a presigned part URL (query string
  /// stripped). Null when every part was already complete at resume time and
  /// no presign happened; video flows consume [objectKey] only.
  final String? publicUrl;

  const UploadFinalizePending({
    required this.uploadSessionId,
    required this.uploadId,
    required this.objectKey,
    this.publicUrl,
  });
}
