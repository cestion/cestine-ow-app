import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/short_video_model.dart';
import 'draft_save_status.dart';

/// 发布视频过程中可由页面直接翻译的本地校验错误。
enum PublishVideoIssue {
  videoTooLarge,
  videoPickFailed,
  videoInsufficientStorage,
  videoPermissionDenied,
  videoSourceUnavailable,
  videoPrepareFailed,
  videoMetadataUnavailable,
  coverTooLarge,
  coverUnsupportedFormat,
  coverPickFailed,
  uploadSessionUnavailable,
}

enum PublishVideoUploadStatus {
  idle,

  /// 上传中（排队/传输/自动重试中）。
  uploading,

  /// 用户手动或蜂窝策略暂停（保断点），点「上传」从断点续传。
  paused,

  /// 全部分片已传完、后端异步合并中（进度恒 100%，不显示速度）。
  merging,
  success,
  failed,
}

/// 当前封面的来源，用于决定新视频缩略图是否可覆盖现有封面。
enum PublishVideoCoverSource { none, auto, manual }

/// 单个待发布视频的本地信息与上传状态。
class PublishVideoFile extends Equatable {
  final String? uploadTaskId;
  final String path;
  final String name;
  final int sizeBytes;
  final int durationMs;
  final int width;
  final int height;
  final String? thumbnailPath;
  final double uploadProgress;
  final PublishVideoUploadStatus uploadStatus;
  final String? objectKey;

  /// 实时上传速度（字节/秒），仅 `uploading` 状态下有意义。
  final int speedBps;

  /// 断网等待标志（transient）：uploading/merging + networkWait →
  /// "等待网络连接..."+暂停按钮；paused + networkWait → +上传按钮（PRD）。
  final bool networkWait;

  const PublishVideoFile({
    this.uploadTaskId,
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.durationMs,
    required this.width,
    required this.height,
    this.thumbnailPath,
    this.uploadProgress = 0,
    this.uploadStatus = PublishVideoUploadStatus.idle,
    this.objectKey,
    this.speedBps = 0,
    this.networkWait = false,
  });

  bool get isUploading => uploadStatus == PublishVideoUploadStatus.uploading;
  bool get isPaused => uploadStatus == PublishVideoUploadStatus.paused;
  bool get isMerging => uploadStatus == PublishVideoUploadStatus.merging;
  bool get isUploaded =>
      uploadStatus == PublishVideoUploadStatus.success && objectKey != null;

  /// "等待网络连接..." 展示态（PRD）：网络中断且任务尚未终态。
  bool get isWaitingNetwork =>
      networkWait &&
      (uploadStatus == PublishVideoUploadStatus.uploading ||
          uploadStatus == PublishVideoUploadStatus.paused ||
          uploadStatus == PublishVideoUploadStatus.merging);

  PublishVideoFile copyWith({
    String? uploadTaskId,
    String? thumbnailPath,
    double? uploadProgress,
    PublishVideoUploadStatus? uploadStatus,
    String? objectKey,
    bool clearObjectKey = false,
    int? speedBps,
    bool? networkWait,
  }) {
    return PublishVideoFile(
      uploadTaskId: uploadTaskId ?? this.uploadTaskId,
      path: path,
      name: name,
      sizeBytes: sizeBytes,
      durationMs: durationMs,
      width: width,
      height: height,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      objectKey: clearObjectKey ? null : (objectKey ?? this.objectKey),
      speedBps: speedBps ?? this.speedBps,
      networkWait: networkWait ?? this.networkWait,
    );
  }

  @override
  List<Object?> get props => [
    uploadTaskId,
    path,
    name,
    sizeBytes,
    durationMs,
    width,
    height,
    thumbnailPath,
    uploadProgress,
    uploadStatus,
    objectKey,
    speedBps,
    networkWait,
  ];
}

class PublishVideoState extends Equatable {
  final PublishVideoFile? video;
  final String? localCoverPath;
  final String? coverObjectKey;
  final PublishVideoCoverSource coverSource;
  final String description;
  final String? uploadSessionId;
  final int? uploadSessionExpiresAt;
  final int? editingEpisodeId;
  final ShortVideoEditSession? editSession;
  final double coverUploadProgress;
  final bool isPickingVideo;
  final bool isPickingCover;
  final bool isUploadingCover;
  final bool isPublishing;
  final bool isEditLoading;
  final bool draftRestored;
  final DraftSaveStatus draftSaveStatus;
  final PublishVideoIssue? issue;
  final ApiError? lastError;
  final ApiError? editLoadError;

  /// 蜂窝网络确认弹窗镜像（transient）：当前草稿 session 被队列挂起
  /// 等待"是否继续使用流量上传"确认。UI 监听到 true 后弹窗并调用
  /// `PublishVideoController.confirmCellularUpload(accepted)`。
  final bool cellularConfirmationPending;

  const PublishVideoState({
    this.video,
    this.localCoverPath,
    this.coverObjectKey,
    this.coverSource = PublishVideoCoverSource.none,
    this.description = '',
    this.uploadSessionId,
    this.uploadSessionExpiresAt,
    this.editingEpisodeId,
    this.editSession,
    this.coverUploadProgress = 0,
    this.isPickingVideo = false,
    this.isPickingCover = false,
    this.isUploadingCover = false,
    this.isPublishing = false,
    this.isEditLoading = false,
    this.draftRestored = false,
    this.draftSaveStatus = DraftSaveStatus.idle,
    this.issue,
    this.lastError,
    this.editLoadError,
    this.cellularConfirmationPending = false,
  });

  bool get isEditMode => editingEpisodeId != null;

  String? get remoteCoverUrl => editSession?.coverUrl;

  bool get hasDraftableContent =>
      !isEditMode &&
      (video != null ||
          localCoverPath != null ||
          coverObjectKey != null ||
          description.trim().isNotEmpty);

  bool get canSaveDraft =>
      hasDraftableContent &&
      !isPickingVideo &&
      video?.isUploading != true &&
      !isPickingCover &&
      !isUploadingCover &&
      !isPublishing;

  /// 编辑时视频不可替换，封面未变更则由后端保留原封面。
  bool get canContinue {
    if (isEditMode) {
      return editSession != null &&
          description.trim().isNotEmpty &&
          !isEditLoading &&
          !isUploadingCover &&
          (localCoverPath == null || coverObjectKey != null) &&
          !isPublishing;
    }
    return video?.isUploaded == true &&
        coverObjectKey != null &&
        description.trim().isNotEmpty &&
        !isPublishing;
  }

  PublishVideoState copyWith({
    PublishVideoFile? video,
    bool clearVideo = false,
    String? localCoverPath,
    bool clearLocalCoverPath = false,
    String? coverObjectKey,
    bool clearCoverObjectKey = false,
    PublishVideoCoverSource? coverSource,
    String? description,
    String? uploadSessionId,
    int? uploadSessionExpiresAt,
    bool clearUploadSessionId = false,
    bool clearUploadSessionExpiresAt = false,
    int? editingEpisodeId,
    ShortVideoEditSession? editSession,
    bool clearEditSession = false,
    double? coverUploadProgress,
    bool? isPickingVideo,
    bool? isPickingCover,
    bool? isUploadingCover,
    bool? isPublishing,
    bool? isEditLoading,
    bool? draftRestored,
    DraftSaveStatus? draftSaveStatus,
    PublishVideoIssue? issue,
    bool clearIssue = false,
    ApiError? lastError,
    bool clearLastError = false,
    ApiError? editLoadError,
    bool clearEditLoadError = false,
    bool? cellularConfirmationPending,
  }) {
    return PublishVideoState(
      video: clearVideo ? null : (video ?? this.video),
      localCoverPath: clearLocalCoverPath
          ? null
          : (localCoverPath ?? this.localCoverPath),
      coverObjectKey: clearCoverObjectKey
          ? null
          : (coverObjectKey ?? this.coverObjectKey),
      coverSource: coverSource ?? this.coverSource,
      description: description ?? this.description,
      uploadSessionId: clearUploadSessionId
          ? null
          : (uploadSessionId ?? this.uploadSessionId),
      uploadSessionExpiresAt:
          clearUploadSessionId || clearUploadSessionExpiresAt
          ? null
          : (uploadSessionExpiresAt ?? this.uploadSessionExpiresAt),
      editingEpisodeId: editingEpisodeId ?? this.editingEpisodeId,
      editSession: clearEditSession ? null : (editSession ?? this.editSession),
      coverUploadProgress: coverUploadProgress ?? this.coverUploadProgress,
      isPickingVideo: isPickingVideo ?? this.isPickingVideo,
      isPickingCover: isPickingCover ?? this.isPickingCover,
      isUploadingCover: isUploadingCover ?? this.isUploadingCover,
      isPublishing: isPublishing ?? this.isPublishing,
      isEditLoading: isEditLoading ?? this.isEditLoading,
      draftRestored: draftRestored ?? this.draftRestored,
      draftSaveStatus: draftSaveStatus ?? this.draftSaveStatus,
      issue: clearIssue ? null : (issue ?? this.issue),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      editLoadError: clearEditLoadError
          ? null
          : (editLoadError ?? this.editLoadError),
      cellularConfirmationPending:
          cellularConfirmationPending ?? this.cellularConfirmationPending,
    );
  }

  @override
  List<Object?> get props => [
    video,
    localCoverPath,
    coverObjectKey,
    coverSource,
    description,
    uploadSessionId,
    uploadSessionExpiresAt,
    editingEpisodeId,
    editSession,
    coverUploadProgress,
    isPickingVideo,
    isPickingCover,
    isUploadingCover,
    isPublishing,
    isEditLoading,
    draftRestored,
    draftSaveStatus,
    issue,
    lastError,
    editLoadError,
    cellularConfirmationPending,
  ];
}
