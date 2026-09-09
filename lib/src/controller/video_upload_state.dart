import 'package:equatable/equatable.dart';

enum VideoUploadStatus {
  pending,
  uploading,
  paused,

  /// 全部分片已传完、后端异步合并中（进度恒 100%，不显示速度）。
  merging,
  success,
  failed,
}

const Object _sentinel = Object();

class VideoUploadItem extends Equatable {
  final String id;
  final String path;
  final String name;
  final String description;
  final int durationMs;
  final int sizeBytes;
  final int width;
  final int height;
  final double progress;
  final VideoUploadStatus status;
  final String? error;
  final String? url;
  final String? videoObjectKey;
  final String? thumbnailPath;

  /// 实时上传速度（字节/秒），仅 `uploading` 状态下有意义。
  final int speedBps;

  /// 断网等待标志（transient）：与 [status] 组合表达
  /// "等待网络连接..."——uploading/merging + networkWait → 显示暂停按钮，
  /// paused + networkWait → 显示上传按钮（按钮跟随上次状态，PRD）。
  final bool networkWait;

  /// true 表示该项来自编辑会话回显的已有剧集，UI 上不可删除/拖动。
  final bool preexisting;

  /// true 表示该项替换了已有剧集的位置，UI 上不可删除/拖动。
  final bool isReplacement;

  /// true 表示该项来自本地草稿恢复，仅用于区分历史上传视频。
  final bool restoredFromDraft;

  const VideoUploadItem({
    required this.id,
    required this.path,
    required this.name,
    this.description = '',
    this.durationMs = 0,
    this.sizeBytes = 0,
    this.width = 0,
    this.height = 0,
    this.progress = 0,
    this.status = VideoUploadStatus.pending,
    this.error,
    this.url,
    this.videoObjectKey,
    this.thumbnailPath,
    this.speedBps = 0,
    this.networkWait = false,
    this.preexisting = false,
    this.isReplacement = false,
    this.restoredFromDraft = false,
  });

  bool get isUploading => status == VideoUploadStatus.uploading;
  bool get isPaused => status == VideoUploadStatus.paused;
  bool get isMerging => status == VideoUploadStatus.merging;
  bool get isSuccess => status == VideoUploadStatus.success;
  bool get isFailed => status == VideoUploadStatus.failed;
  bool get isHistoricalUpload => preexisting || restoredFromDraft;

  /// 未到终态：排队 / 传输 / 暂停 / 合并中。
  /// 提交放行与「全部上传完成」提示的门控依据（合并未 READY 前不可提交）。
  bool get isIncomplete =>
      status == VideoUploadStatus.pending ||
      status == VideoUploadStatus.uploading ||
      status == VideoUploadStatus.paused ||
      status == VideoUploadStatus.merging;

  /// "等待网络连接..." 展示态（PRD）：网络中断且任务尚未终态。
  bool get isWaitingNetwork =>
      networkWait &&
      (status == VideoUploadStatus.uploading ||
          status == VideoUploadStatus.paused ||
          status == VideoUploadStatus.merging);

  VideoUploadItem copyWith({
    String? path,
    String? name,
    String? description,
    int? durationMs,
    int? sizeBytes,
    int? width,
    int? height,
    double? progress,
    VideoUploadStatus? status,
    String? error,
    String? url,
    String? videoObjectKey,
    String? thumbnailPath,
    Object? clearUrl = _sentinel,
    Object? clearVideoObjectKey = _sentinel,
    Object? clearThumbnailPath = _sentinel,
    int? speedBps,
    bool? networkWait,
    bool? isReplacement,
    bool clearError = false,
  }) {
    return VideoUploadItem(
      id: id,
      path: path ?? this.path,
      name: name ?? this.name,
      description: description ?? this.description,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      url: identical(clearUrl, _sentinel) ? (url ?? this.url) : null,
      videoObjectKey: identical(clearVideoObjectKey, _sentinel)
          ? (videoObjectKey ?? this.videoObjectKey)
          : null,
      thumbnailPath: identical(clearThumbnailPath, _sentinel)
          ? (thumbnailPath ?? this.thumbnailPath)
          : null,
      speedBps: speedBps ?? this.speedBps,
      networkWait: networkWait ?? this.networkWait,
      preexisting: preexisting,
      isReplacement: isReplacement ?? this.isReplacement,
      restoredFromDraft: restoredFromDraft,
    );
  }

  @override
  List<Object?> get props => [
    id,
    path,
    name,
    description,
    durationMs,
    sizeBytes,
    width,
    height,
    progress,
    status,
    error,
    url,
    videoObjectKey,
    thumbnailPath,
    speedBps,
    networkWait,
    preexisting,
    isReplacement,
    restoredFromDraft,
  ];
}

class VideoUploadState extends Equatable {
  final List<VideoUploadItem> videos;
  final bool isPicking;
  final String? uploadSessionId;
  final int? uploadSessionExpiresAt;
  final bool isEditMode;

  /// 最近一次 pickVideos 因达到 [kMaxEpisodesPerDrama] 上限而被截断的文件数量。
  /// UI 侧监听到 `> 0` 后展示提示 Toast，并调用
  /// `VideoUploadController.clearPickOverflow()` 清零，避免重复提示。
  final int pickOverflow;

  /// 蜂窝网络确认弹窗镜像（transient）：当前草稿 session 被队列挂起
  /// 等待"是否继续使用流量上传"确认。UI 监听到 true 后弹窗并调用
  /// `VideoUploadController.confirmCellularUpload(accepted)`。
  final bool cellularConfirmationPending;

  const VideoUploadState({
    this.videos = const [],
    this.isPicking = false,
    this.uploadSessionId,
    this.uploadSessionExpiresAt,
    this.isEditMode = false,
    this.pickOverflow = 0,
    this.cellularConfirmationPending = false,
  });

  VideoUploadState copyWith({
    List<VideoUploadItem>? videos,
    bool? isPicking,
    String? uploadSessionId,
    int? uploadSessionExpiresAt,
    bool clearUploadSessionId = false,
    bool clearUploadSessionExpiresAt = false,
    bool? isEditMode,
    int? pickOverflow,
    bool clearPickOverflow = false,
    bool? cellularConfirmationPending,
  }) {
    return VideoUploadState(
      videos: videos ?? this.videos,
      isPicking: isPicking ?? this.isPicking,
      uploadSessionId: clearUploadSessionId
          ? null
          : (uploadSessionId ?? this.uploadSessionId),
      uploadSessionExpiresAt:
          clearUploadSessionId || clearUploadSessionExpiresAt
          ? null
          : (uploadSessionExpiresAt ?? this.uploadSessionExpiresAt),
      isEditMode: isEditMode ?? this.isEditMode,
      pickOverflow: clearPickOverflow ? 0 : (pickOverflow ?? this.pickOverflow),
      cellularConfirmationPending:
          cellularConfirmationPending ?? this.cellularConfirmationPending,
    );
  }

  @override
  List<Object?> get props => [
    videos,
    isPicking,
    uploadSessionId,
    uploadSessionExpiresAt,
    isEditMode,
    pickOverflow,
    cellularConfirmationPending,
  ];
}
