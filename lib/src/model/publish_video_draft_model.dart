import 'package:equatable/equatable.dart';

import '../core/json_helpers.dart';

/// 发布独立短视频时保存在本地的草稿。
///
/// 成功资源记录 object key；上传中的视频记录全局任务 id 与 App 托管路径，
/// 以便进程重启后重新关联持久化队列。
class PublishVideoDraft with Equatable {
  final String? videoTaskId;
  final String? videoLocalFilePath;
  final String videoName;
  final int videoSizeBytes;
  final int videoDurationMs;
  final int videoWidth;
  final int videoHeight;
  final String? videoObjectKey;
  final String? coverObjectKey;

  /// 封面来源（none/auto/manual），用于恢复后判断新视频缩略图是否可覆盖。
  final String coverSource;
  final String description;
  final String? uploadSessionId;
  final int? uploadSessionExpiresAt;
  final int schemaVersion;
  final int savedAt;

  const PublishVideoDraft({
    this.videoTaskId,
    this.videoLocalFilePath,
    this.videoName = '',
    this.videoSizeBytes = 0,
    this.videoDurationMs = 0,
    this.videoWidth = 0,
    this.videoHeight = 0,
    this.videoObjectKey,
    this.coverObjectKey,
    this.coverSource = 'none',
    this.description = '',
    this.uploadSessionId,
    this.uploadSessionExpiresAt,
    this.schemaVersion = 1,
    this.savedAt = 0,
  });

  bool get hasContent =>
      videoTaskId != null ||
      videoObjectKey != null ||
      coverObjectKey != null ||
      description.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
    if (videoTaskId != null || videoObjectKey != null) ...{
      if (videoTaskId != null) 'videoTaskId': videoTaskId,
      if (videoLocalFilePath != null) 'videoLocalFilePath': videoLocalFilePath,
      'videoName': videoName,
      'videoSizeBytes': videoSizeBytes,
      'videoDurationMs': videoDurationMs,
      'videoWidth': videoWidth,
      'videoHeight': videoHeight,
      if (videoObjectKey != null) 'videoObjectKey': videoObjectKey,
    },
    if (coverObjectKey != null) 'coverObjectKey': coverObjectKey,
    'coverSource': coverSource,
    'description': description,
    if (uploadSessionId != null) 'uploadSessionId': uploadSessionId,
    if (uploadSessionExpiresAt != null)
      'uploadSessionExpiresAt': uploadSessionExpiresAt,
    'schemaVersion': schemaVersion,
    'savedAt': savedAt,
  };

  static PublishVideoDraft? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return PublishVideoDraft(
      videoTaskId: asStringOrNull(map['videoTaskId']),
      videoLocalFilePath: asStringOrNull(map['videoLocalFilePath']),
      videoName: asStringOrNull(map['videoName']) ?? '',
      videoSizeBytes: asIntOrNull(map['videoSizeBytes']) ?? 0,
      videoDurationMs: asIntOrNull(map['videoDurationMs']) ?? 0,
      videoWidth: asIntOrNull(map['videoWidth']) ?? 0,
      videoHeight: asIntOrNull(map['videoHeight']) ?? 0,
      videoObjectKey: asStringOrNull(map['videoObjectKey']),
      coverObjectKey: asStringOrNull(map['coverObjectKey']),
      coverSource: asStringOrNull(map['coverSource']) ?? 'none',
      description: asStringOrNull(map['description']) ?? '',
      uploadSessionId: asStringOrNull(map['uploadSessionId']),
      uploadSessionExpiresAt: asIntOrNull(map['uploadSessionExpiresAt']),
      schemaVersion: asIntOrNull(map['schemaVersion']) ?? 1,
      savedAt: asIntOrNull(map['savedAt']) ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    videoTaskId,
    videoLocalFilePath,
    videoName,
    videoSizeBytes,
    videoDurationMs,
    videoWidth,
    videoHeight,
    videoObjectKey,
    coverObjectKey,
    coverSource,
    description,
    uploadSessionId,
    uploadSessionExpiresAt,
    schemaVersion,
    savedAt,
  ];
}
