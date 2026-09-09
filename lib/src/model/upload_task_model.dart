import 'package:equatable/equatable.dart';

import '../core/json_helpers.dart';
import 'uploaded_part_model.dart';

/// Upload business category values expected by the backend.
enum FileCategory {
  cover('COVER'),
  video('episode'),
  avatar('AVATAR');

  const FileCategory(this.value);
  final String value;
}

enum UploadTaskStatus {
  queued,
  uploading,
  paused,
  retryWaiting,
  merging,
  success,
  failed,
  canceled,
}

/// Lifecycle of the multipart transfer protocol within a video task.
///
/// Persisted so a process killed while the backend merges uploaded parts can
/// resume by polling instead of re-uploading every part.
enum MultipartPhase {
  none,
  partsUploading,
  finalizeRequested,
}

/// Persisted unit owned by the global foreground upload queue.
///
/// Presigned URLs are intentionally excluded: they expire and contain
/// credentials. Every attempt requests a fresh URL through the repository.
///
/// Multipart checkpoint fields (`multipartUploadId`, `completedParts`, ...) are
/// persisted so interrupted video uploads resume from the last completed part.
/// `networkWait` and `speedBps` are transient runtime signals and are never
/// persisted.
class UploadTask extends Equatable {
  final String id;
  final String localFilePath;
  final String fileName;
  final int fileSize;
  final String contentType;
  final FileCategory category;
  final String ownerUserId;
  final String uploadSessionId;
  final int? uploadSessionExpiresAt;
  final String? multipartUploadId;
  final String? multipartObjectKey;
  final int? partSize;
  final int? totalParts;
  final List<UploadedPart> completedParts;
  final int uploadedBytes;
  final MultipartPhase multipartPhase;
  final UploadTaskStatus status;
  final double progress;
  final int retryCount;
  final String? objectKey;
  final String? publicUrl;
  final String? lastError;
  final bool networkWait;
  final int speedBps;
  final int updatedAt;

  /// true 表示本次 paused 状态来自用户手动点击暂停；系统暂停（后台、断网、
  /// 蜂窝）为 false。用于区分「自动恢复」与「保持暂停」。
  final bool userPaused;

  const UploadTask({
    required this.id,
    required this.localFilePath,
    required this.fileName,
    required this.fileSize,
    required this.contentType,
    required this.category,
    required this.ownerUserId,
    required this.uploadSessionId,
    this.uploadSessionExpiresAt,
    this.multipartUploadId,
    this.multipartObjectKey,
    this.partSize,
    this.totalParts,
    this.completedParts = const [],
    this.uploadedBytes = 0,
    this.multipartPhase = MultipartPhase.none,
    this.status = UploadTaskStatus.queued,
    this.progress = 0,
    this.retryCount = 0,
    this.objectKey,
    this.publicUrl,
    this.lastError,
    this.networkWait = false,
    this.speedBps = 0,
    this.updatedAt = 0,
    this.userPaused = false,
  });

  UploadTask copyWith({
    String? localFilePath,
    String? uploadSessionId,
    int? uploadSessionExpiresAt,
    bool clearUploadSessionExpiresAt = false,
    String? multipartUploadId,
    String? multipartObjectKey,
    int? partSize,
    int? totalParts,
    List<UploadedPart>? completedParts,
    int? uploadedBytes,
    MultipartPhase? multipartPhase,
    bool resetMultipartState = false,
    UploadTaskStatus? status,
    double? progress,
    int? retryCount,
    String? objectKey,
    String? publicUrl,
    String? lastError,
    bool clearError = false,
    bool? networkWait,
    int? speedBps,
    int? updatedAt,
    bool? userPaused,
    bool clearUserPaused = false,
  }) {
    return UploadTask(
      id: id,
      localFilePath: localFilePath ?? this.localFilePath,
      fileName: fileName,
      fileSize: fileSize,
      contentType: contentType,
      category: category,
      ownerUserId: ownerUserId,
      uploadSessionId: uploadSessionId ?? this.uploadSessionId,
      uploadSessionExpiresAt: clearUploadSessionExpiresAt
          ? null
          : (uploadSessionExpiresAt ?? this.uploadSessionExpiresAt),
      multipartUploadId: resetMultipartState
          ? null
          : (multipartUploadId ?? this.multipartUploadId),
      multipartObjectKey: resetMultipartState
          ? null
          : (multipartObjectKey ?? this.multipartObjectKey),
      partSize: resetMultipartState ? null : (partSize ?? this.partSize),
      totalParts: resetMultipartState ? null : (totalParts ?? this.totalParts),
      completedParts: resetMultipartState
          ? const []
          : (completedParts ?? this.completedParts),
      uploadedBytes: resetMultipartState
          ? 0
          : (uploadedBytes ?? this.uploadedBytes),
      multipartPhase: resetMultipartState
          ? MultipartPhase.none
          : (multipartPhase ?? this.multipartPhase),
      status: status ?? this.status,
      progress: progress ?? this.progress,
      retryCount: retryCount ?? this.retryCount,
      objectKey: objectKey ?? this.objectKey,
      publicUrl: publicUrl ?? this.publicUrl,
      lastError: clearError ? null : (lastError ?? this.lastError),
      networkWait: networkWait ?? this.networkWait,
      speedBps: speedBps ?? this.speedBps,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      userPaused: clearUserPaused
          ? false
          : (userPaused ?? this.userPaused),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'localFilePath': localFilePath,
        'fileName': fileName,
        'fileSize': fileSize,
        'contentType': contentType,
        'category': category.name,
        'ownerUserId': ownerUserId,
        'uploadSessionId': uploadSessionId,
        if (uploadSessionExpiresAt != null)
          'uploadSessionExpiresAt': uploadSessionExpiresAt,
        if (multipartUploadId != null) 'multipartUploadId': multipartUploadId,
        if (multipartObjectKey != null)
          'multipartObjectKey': multipartObjectKey,
        if (partSize != null) 'partSize': partSize,
        if (totalParts != null) 'totalParts': totalParts,
        if (completedParts.isNotEmpty)
          'completedParts': [for (final part in completedParts) part.toMap()],
        if (uploadedBytes > 0) 'uploadedBytes': uploadedBytes,
        if (multipartPhase != MultipartPhase.none)
          'multipartPhase': multipartPhase.name,
        'status': status.name,
        'progress': progress,
        'retryCount': retryCount,
        if (objectKey != null) 'objectKey': objectKey,
        if (publicUrl != null) 'publicUrl': publicUrl,
        if (lastError != null) 'lastError': lastError,
        'updatedAt': updatedAt,
        if (userPaused) 'userPaused': true,
      };

  static UploadTask? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final id = asStringOrNull(map['id']);
    final path = asStringOrNull(map['localFilePath']);
    final fileName = asStringOrNull(map['fileName']);
    final ownerUserId = asStringOrNull(map['ownerUserId']);
    final sessionId = asStringOrNull(map['uploadSessionId']);
    if (id == null ||
        path == null ||
        fileName == null ||
        ownerUserId == null ||
        sessionId == null) {
      return null;
    }
    final categoryName = asStringOrNull(map['category']);
    final statusName = asStringOrNull(map['status']);
    final category = FileCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () => FileCategory.video,
    );
    var status = UploadTaskStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => UploadTaskStatus.paused,
    );
    // A process cannot still own an in-flight Dart socket after restoration.
    // `merging` survives: the merge was already accepted by the backend, so
    // restoration only needs to poll the finalize status.
    if (status == UploadTaskStatus.uploading ||
        status == UploadTaskStatus.retryWaiting ||
        status == UploadTaskStatus.queued) {
      status = UploadTaskStatus.paused;
    }
    final completedParts = <UploadedPart>[];
    final rawParts = map['completedParts'];
    if (rawParts is List) {
      for (final value in rawParts) {
        final part = UploadedPart.fromMap(value);
        if (part != null) completedParts.add(part);
      }
      completedParts.sort((a, b) => a.partNumber.compareTo(b.partNumber));
    }
    final phaseName = asStringOrNull(map['multipartPhase']);
    final multipartPhase = MultipartPhase.values.firstWhere(
      (value) => value.name == phaseName,
      orElse: () => MultipartPhase.none,
    );
    return UploadTask(
      id: id,
      localFilePath: path,
      fileName: fileName,
      fileSize: asIntOrNull(map['fileSize']) ?? 0,
      contentType:
          asStringOrNull(map['contentType']) ?? 'application/octet-stream',
      category: category,
      ownerUserId: ownerUserId,
      uploadSessionId: sessionId,
      uploadSessionExpiresAt: asIntOrNull(map['uploadSessionExpiresAt']),
      multipartUploadId: asStringOrNull(map['multipartUploadId']),
      multipartObjectKey: asStringOrNull(map['multipartObjectKey']),
      partSize: asIntOrNull(map['partSize']),
      totalParts: asIntOrNull(map['totalParts']),
      completedParts: completedParts,
      uploadedBytes: asIntOrNull(map['uploadedBytes']) ??
          completedParts.fold<int>(0, (sum, part) => sum + part.size),
      multipartPhase: multipartPhase,
      status: status,
      progress: status == UploadTaskStatus.success ||
              status == UploadTaskStatus.merging
          ? 1
          : ((map['progress'] as num?)?.toDouble() ?? 0),
      retryCount: asIntOrNull(map['retryCount']) ?? 0,
      objectKey: asStringOrNull(map['objectKey']),
      publicUrl: asStringOrNull(map['publicUrl']),
      lastError: asStringOrNull(map['lastError']),
      updatedAt: asIntOrNull(map['updatedAt']) ?? 0,
      userPaused: (map['userPaused'] as bool?) == true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        localFilePath,
        fileName,
        fileSize,
        contentType,
        category,
        ownerUserId,
        uploadSessionId,
        uploadSessionExpiresAt,
        multipartUploadId,
        multipartObjectKey,
        partSize,
        totalParts,
        completedParts,
        uploadedBytes,
        multipartPhase,
        status,
        progress,
        retryCount,
        objectKey,
        publicUrl,
        lastError,
        networkWait,
        speedBps,
        updatedAt,
        userPaused,
      ];
}
