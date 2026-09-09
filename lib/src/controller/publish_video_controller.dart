import 'dart:async';
import 'dart:io';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:path_provider/path_provider.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../core/upload_failure.dart';
import '../data/repository/draft_repository.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/file_upload_repository.dart';
import '../repositories/short_video_repository.dart';
import '../services/image_picker_service.dart';
import '../services/video_file_picker_service.dart';
import 'draft_autosave_coordinator.dart';
import 'draft_save_status.dart';
import 'publish_video_state.dart';
import 'upload_coordinator.dart';
import 'upload_session_manager.dart';

const int kPublishVideoMaxBytes = 2 * 1024 * 1024 * 1024;
const int kPublishVideoCoverMaxBytes = 5 * 1024 * 1024;
const int kPublishVideoThumbnailMaxEdge = 3840;

/// 管理独立短视频的文件选择、上传和发布。
///
/// 视频与封面必须共用同一个上传会话，后端才会接受最终发布请求。
class PublishVideoController extends Notifier<PublishVideoState> {
  late final FileUploadRepository _uploader;
  late final UploadCoordinator _coordinator;
  late final UploadSessionManager _sessionManager;
  late final ShortVideoRepository _shortVideoRepository;
  late final DraftRepository _draftRepo;
  late DraftAutosaveCoordinator<PublishVideoDraft> _draftAutosave;
  late String _draftOwnerId;
  final FlutterVideoInfo _videoInfo = FlutterVideoInfo();
  int _operationGeneration = 0;
  bool _draftStarted = false;
  bool _restoringDraft = false;

  @override
  PublishVideoState build() {
    _uploader = ref.read(fileUploadRepositoryProvider);
    _coordinator = ref.read(uploadCoordinatorProvider.notifier);
    _sessionManager = UploadSessionManager(
      uploader: _uploader,
      coordinator: _coordinator,
      readOwnerUserId: () => ref.read(currentUserIdProvider),
      onSessionChanged: (sessionId, expiresAt) {
        if (!ref.mounted) return;
        state = state.copyWith(
          uploadSessionId: sessionId,
          uploadSessionExpiresAt: expiresAt,
          clearUploadSessionExpiresAt: expiresAt == null,
        );
        _markDraftDirty();
      },
    )..reset();
    _shortVideoRepository = ref.read(shortVideoRepositoryProvider);
    _draftRepo = ref.read(draftRepositoryProvider);
    final authUserId = ref.read(authControllerProvider).userId?.trim();
    final storedUserId = ref.read(localRepositoryProvider).getUser()?.userId;
    _draftOwnerId = authUserId?.isNotEmpty == true
        ? authUserId!
        : (storedUserId?.trim() ?? '');
    _draftAutosave = _createDraftAutosave(_draftOwnerId);
    ref.listen<Map<String, UploadTask>>(uploadCoordinatorProvider, (_, next) {
      _syncVideoUploadTask(next);
    });
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;
      _operationGeneration++;
      _sessionManager.handleOwnerChanged();
      _draftAutosave.dispose();
      _draftOwnerId = next?.trim() ?? '';
      _draftAutosave = _createDraftAutosave(_draftOwnerId);
      _draftStarted = false;
      _restoringDraft = false;
      // Old tasks stay owner-scoped in the global queue for draft recovery.
      state = const PublishVideoState();
    });
    ref.onDispose(_sessionManager.dispose);
    ref.onDispose(() => _draftAutosave.dispose());
    return const PublishVideoState();
  }

  void setDescription(String value) {
    if (value == state.description) return;
    state = state.copyWith(description: value);
    _markDraftDirty();
  }

  void clearFeedback() {
    state = state.copyWith(clearIssue: true, clearLastError: true);
  }

  bool get hasDraftableContent => state.hasDraftableContent;
  bool get hasDraftOrContent =>
      !state.isEditMode && (_draftStarted || state.hasDraftableContent);

  /// 新建模式进入页面时恢复上一次保存的草稿。
  Future<void> tryRestoreDraft() async {
    if (state.isEditMode || state.draftRestored || state.hasDraftableContent) {
      return;
    }
    if (_draftOwnerId.isEmpty) return;
    final draft = await _draftRepo.getPublishVideoDraft(_draftOwnerId);
    if (draft == null || (!draft.hasContent && draft.savedAt <= 0)) return;
    if (!ref.mounted) return;
    if (state.isEditMode || state.hasDraftableContent) return;

    PublishVideoFile? video;
    if (draft.videoObjectKey != null && draft.videoName.isNotEmpty) {
      video = PublishVideoFile(
        path: '',
        name: draft.videoName,
        sizeBytes: draft.videoSizeBytes,
        durationMs: draft.videoDurationMs,
        width: draft.videoWidth,
        height: draft.videoHeight,
        uploadProgress: 1,
        uploadStatus: PublishVideoUploadStatus.success,
        objectKey: draft.videoObjectKey,
      );
    } else if (draft.videoTaskId != null &&
        draft.videoLocalFilePath != null &&
        draft.videoName.isNotEmpty) {
      video = PublishVideoFile(
        uploadTaskId: draft.videoTaskId,
        path: draft.videoLocalFilePath!,
        name: draft.videoName,
        sizeBytes: draft.videoSizeBytes,
        durationMs: draft.videoDurationMs,
        width: draft.videoWidth,
        height: draft.videoHeight,
        uploadStatus: PublishVideoUploadStatus.uploading,
      );
    }

    _draftStarted = true;
    _restoringDraft = true;
    state = state.copyWith(
      video: video,
      coverObjectKey: draft.coverObjectKey,
      coverSource: _resolveDraftCoverSource(draft),
      description: draft.description,
      uploadSessionId: draft.uploadSessionId,
      uploadSessionExpiresAt: draft.uploadSessionExpiresAt,
      draftRestored: true,
      draftSaveStatus: DraftSaveStatus.saved,
      clearIssue: true,
      clearLastError: true,
    );
    _sessionManager.restore(
      sessionId: draft.uploadSessionId,
      expiresAt: draft.uploadSessionExpiresAt,
      hasExternalResources:
          draft.videoObjectKey != null || draft.coverObjectKey != null,
    );
    _restoringDraft = false;
    if (video?.uploadTaskId != null) {
      unawaited(_restoreVideoUploadTask(video!));
      if (draft.coverObjectKey == null) {
        unawaited(_generateVideoThumbnail(video));
      }
    }
  }

  /// 保存当前页面内容；上传中或失败的视频不会写入草稿。
  Future<bool> saveDraft() async {
    if (!ref.mounted || state.isEditMode || _draftOwnerId.isEmpty) return true;
    if (!_draftStarted && !state.hasDraftableContent) return true;
    _markDraftDirty();
    return _draftAutosave.flush();
  }

  Future<bool> saveDraftForExit() => saveDraft();

  /// 放弃页面内容并删除此前保存的发布视频草稿。
  Future<bool> discardDraftForExit() async {
    if (!ref.mounted || state.isEditMode || _draftOwnerId.isEmpty) return true;
    final deleted = await _draftAutosave.discard(
      () => _draftRepo.deletePublishVideoDraft(_draftOwnerId),
    );
    if (ref.mounted) {
      state = state.copyWith(
        draftSaveStatus: deleted
            ? DraftSaveStatus.discarded
            : DraftSaveStatus.failed,
      );
    }
    if (deleted) {
      _draftStarted = false;
      await _deleteCurrentLocalAssets();
    } else {
      _draftAutosave.resumeAfterDiscardFailure();
    }
    return deleted;
  }

  Future<bool> flushDraftForLifecycle() => _draftAutosave.flush();

  /// Retries the managed local video without reopening the picker.
  Future<void> retryVideo() async {
    final video = state.video;
    if (video == null ||
        video.uploadTaskId == null ||
        video.path.isEmpty ||
        video.isUploaded ||
        video.isUploading ||
        video.isMerging) {
      return;
    }
    state = state.copyWith(
      video: video.copyWith(
        // 断点续传：进度由队列同步从 checkpoint 恢复，不做乐观归零。
        uploadStatus: PublishVideoUploadStatus.uploading,
        clearObjectKey: true,
      ),
      clearIssue: true,
      clearLastError: true,
    );
    await _restoreVideoUploadTask(state.video!);
  }

  /// 移除当前已选择的视频；在途上传的回调会因 path 不再匹配而被忽略。
  ///
  /// 若当前封面来自视频缩略图（auto），则一并清除；用户手动上传的封面（manual）保留。
  void removeVideo() {
    final video = state.video;
    _operationGeneration++;
    final wasAutoCover = state.coverSource == PublishVideoCoverSource.auto;
    state = state.copyWith(
      clearVideo: true,
      clearIssue: true,
      clearLastError: true,
      clearLocalCoverPath: wasAutoCover,
      clearCoverObjectKey: wasAutoCover,
      coverSource: wasAutoCover ? PublishVideoCoverSource.none : null,
      // 自动封面与视频绑定，移除视频后其上传回调会被路径守卫忽略，
      // 因此这里同步复位上传态，避免 isUploadingCover 卡在 true。
      isUploadingCover: wasAutoCover ? false : null,
      coverUploadProgress: wasAutoCover ? 0 : null,
    );
    _markDraftDirty();
    // 上传中的文件仍可能被 HTTP 客户端读取，待请求结束后由上传流程清理。
    if (video?.uploadTaskId case final taskId?) {
      unawaited(_coordinator.remove(taskId));
    } else if (video != null && !video.isUploading) {
      unawaited(VideoFilePickerService.deleteTemporaryFile(video.path));
    }
  }

  Future<void> loadForEdit(int episodeId) async {
    if (episodeId <= 0) return;
    state = state.copyWith(
      editingEpisodeId: episodeId,
      isEditLoading: true,
      clearLastError: true,
      clearEditLoadError: true,
    );
    final result = await _shortVideoRepository.getEditSession(episodeId);
    if (!ref.mounted) return;
    result.when(
      success: (session) {
        _sessionManager.restore(
          sessionId: session.uploadSessionId.toString(),
          expiresAt: null,
          hasExternalResources: true,
        );
        state = state.copyWith(
          editingEpisodeId: session.episodeId,
          editSession: session,
          description: session.description,
          uploadSessionId: session.uploadSessionId.toString(),
          isEditLoading: false,
          clearLastError: true,
          clearEditLoadError: true,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isEditLoading: false,
          lastError: error,
          editLoadError: error,
        );
      },
    );
  }

  /// 选择一个视频并立即上传；重新选择会替换当前视频。
  Future<void> pickAndUploadVideo({
    VideoPickSource source = VideoPickSource.gallery,
  }) async {
    if (state.isPickingVideo || state.video?.isMerging == true) {
      return;
    }
    final ownerUserId = ref.read(currentUserIdProvider);
    if (ownerUserId == null) return;
    final generation = ++_operationGeneration;
    String? pickedTemporaryPath;
    String? managedVideoPath;
    var acceptedAsCurrentVideo = false;
    final pickStopwatch = Stopwatch()..start();
    state = state.copyWith(
      isPickingVideo: true,
      clearIssue: true,
      clearLastError: true,
    );
    StoryLogger.i('开始选择发布视频: source=${source.name}', tag: 'PublishVideo');

    try {
      final pickResult = await VideoFilePickerService.pick(
        maxBytes: kPublishVideoMaxBytes,
        source: source,
      );
      StoryLogger.i(
        '视频选择准备完成: source=${source.name} '
        'result=${pickResult.runtimeType} elapsedMs=${pickStopwatch.elapsedMilliseconds}',
        tag: 'PublishVideo',
      );
      if (pickResult is PickVideoCanceled) {
        if (_isCurrentOperation(generation, ownerUserId)) {
          state = state.copyWith(isPickingVideo: false);
        }
        return;
      }
      if (pickResult is PickVideoTooLarge) {
        if (_isCurrentOperation(generation, ownerUserId)) {
          state = state.copyWith(
            isPickingVideo: false,
            issue: PublishVideoIssue.videoTooLarge,
          );
        }
        return;
      }
      if (pickResult is PickVideoFailed) {
        StoryLogger.w(
          '视频选择准备失败: source=${source.name} '
          'reason=${pickResult.reason.name} '
          'detail=${pickResult.technicalMessage ?? ""}',
          tag: 'PublishVideo',
        );
        if (_isCurrentOperation(generation, ownerUserId)) {
          state = state.copyWith(
            isPickingVideo: false,
            issue: switch (pickResult.reason) {
              PickVideoFailureReason.insufficientStorage =>
                PublishVideoIssue.videoInsufficientStorage,
              PickVideoFailureReason.permissionDenied =>
                PublishVideoIssue.videoPermissionDenied,
              PickVideoFailureReason.sourceUnavailable =>
                PublishVideoIssue.videoSourceUnavailable,
              PickVideoFailureReason.prepareFailed =>
                PublishVideoIssue.videoPrepareFailed,
            },
          );
        }
        return;
      }
      final picked = (pickResult as PickVideoSelected).file;
      final path = picked.path;
      pickedTemporaryPath = path;
      if (!_isCurrentOperation(generation, ownerUserId)) {
        await VideoFilePickerService.deleteTemporaryFile(path);
        return;
      }
      final previousVideo = state.video;

      final metadata = await _readVideoDisplaySize(path);
      if (!_isCurrentOperation(generation, ownerUserId)) {
        await VideoFilePickerService.deleteTemporaryFile(path);
        return;
      }
      if (metadata.width <= 0 ||
          metadata.height <= 0 ||
          metadata.durationMs <= 0) {
        if (ref.mounted) {
          state = state.copyWith(
            isPickingVideo: false,
            issue: PublishVideoIssue.videoMetadataUnavailable,
          );
        }
        await VideoFilePickerService.deleteTemporaryFile(path);
        return;
      }

      final taskId =
          'short_video_${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(this)}';
      final managedPath = await _coordinator.adoptFile(taskId, path);
      managedVideoPath = managedPath;
      if (managedPath != path) {
        await VideoFilePickerService.deleteTemporaryFile(path);
      }
      if (!_isCurrentOperation(generation, ownerUserId)) {
        await _coordinator.discardManagedFile(managedPath);
        return;
      }

      final video = PublishVideoFile(
        uploadTaskId: taskId,
        path: managedPath,
        name: picked.name,
        sizeBytes: picked.sizeBytes,
        durationMs: metadata.durationMs,
        width: metadata.width,
        height: metadata.height,
        uploadStatus: PublishVideoUploadStatus.uploading,
      );
      if (!_isCurrentOperation(generation, ownerUserId)) {
        await _coordinator.discardManagedFile(managedPath);
        return;
      }
      state = state.copyWith(video: video, isPickingVideo: false);
      // 新视频尚未成功，不会进入草稿；先保存当前表单快照，使旧的成功视频
      // 不会在上传中断后被误恢复。
      _markDraftDirty();
      acceptedAsCurrentVideo = true;
      if (previousVideo?.uploadTaskId case final previousTaskId?) {
        unawaited(_coordinator.remove(previousTaskId));
      } else if (previousVideo != null && previousVideo.path != managedPath) {
        unawaited(
          VideoFilePickerService.deleteTemporaryFile(previousVideo.path),
        );
      }
      unawaited(_generateVideoThumbnail(video));

      final sessionId = await _ensureUploadSession();
      if (sessionId == null ||
          !_isCurrentOperation(generation, ownerUserId) ||
          state.video?.uploadTaskId != taskId) {
        if (state.video?.uploadTaskId == taskId) {
          state = state.copyWith(
            video: state.video!.copyWith(
              uploadStatus: PublishVideoUploadStatus.failed,
            ),
          );
        }
        return;
      }
      try {
        await _coordinator.enqueue(
          UploadTask(
            id: taskId,
            localFilePath: managedPath,
            fileName: picked.name,
            fileSize: picked.sizeBytes,
            contentType: _videoContentType(picked.name),
            category: FileCategory.video,
            ownerUserId: ownerUserId,
            uploadSessionId: sessionId,
            uploadSessionExpiresAt: state.uploadSessionExpiresAt,
          ),
        );
      } on StateError {
        if (_isCurrentOperation(generation, ownerUserId) &&
            state.video?.uploadTaskId == taskId) {
          state = state.copyWith(
            video: state.video!.copyWith(
              uploadStatus: PublishVideoUploadStatus.failed,
            ),
            lastError: ApiError.unknown(
              const UploadFailure(UploadFailureKind.accountChanged).encoded,
            ),
          );
        }
      }
    } catch (error, stackTrace) {
      StoryLogger.e(
        '发布视频选择流程异常: source=${source.name} '
        'elapsedMs=${pickStopwatch.elapsedMilliseconds}',
        tag: 'PublishVideo',
        error: error,
        stackTrace: stackTrace,
      );
      final pathToCleanup = pickedTemporaryPath;
      if (pathToCleanup != null &&
          (!acceptedAsCurrentVideo ||
              (ref.mounted && state.video?.path != pathToCleanup))) {
        await VideoFilePickerService.deleteTemporaryFile(pathToCleanup);
      }
      final managedPathToCleanup = managedVideoPath;
      if (!acceptedAsCurrentVideo && managedPathToCleanup != null) {
        await _coordinator.discardManagedFile(managedPathToCleanup);
      }
      if (!ref.mounted) return;
      state = state.copyWith(
        isPickingVideo: false,
        issue: PublishVideoIssue.videoPickFailed,
      );
    }
  }

  /// 生成用于本地预览和自动封面上传的高清缩略图。
  ///
  /// 优先保留视频原始分辨率（最长边上限 4K）和最高 JPEG 质量；若生成文件
  /// 超过封面 5MB 上限，再逐级调整质量/尺寸，选择首个可上传的最清晰版本。
  Future<void> _generateVideoThumbnail(PublishVideoFile video) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final destination =
          '${directory.path}/publish_video_thumb_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final candidates = <({int maxEdge, int quality})>[
        (maxEdge: kPublishVideoThumbnailMaxEdge, quality: 100),
        (maxEdge: kPublishVideoThumbnailMaxEdge, quality: 95),
        (maxEdge: kPublishVideoThumbnailMaxEdge, quality: 90),
        (maxEdge: 2560, quality: 95),
        (maxEdge: 1920, quality: 95),
        (maxEdge: 1920, quality: 85),
        (maxEdge: 1280, quality: 85),
      ];
      var generatedWithinLimit = false;
      final thumbnail = File(destination);
      for (final candidate in candidates) {
        final size = _fitThumbnailSize(
          width: video.width,
          height: video.height,
          maxEdge: candidate.maxEdge,
        );
        final generated = await FcNativeVideoThumbnail().getVideoThumbnail(
          srcFile: video.path,
          destFile: destination,
          width: size.width,
          height: size.height,
          format: 'jpeg',
          quality: candidate.quality,
        );
        if (!generated) continue;
        if (await thumbnail.length() <= kPublishVideoCoverMaxBytes) {
          generatedWithinLimit = true;
          break;
        }
      }
      if (!generatedWithinLimit ||
          !ref.mounted ||
          state.video?.path != video.path) {
        if (await thumbnail.exists()) await thumbnail.delete();
        return;
      }
      state = state.copyWith(
        video: state.video!.copyWith(thumbnailPath: destination),
      );
      // 缩略图生成后，若用户尚未手动上传封面，则把它作为默认封面并上传，
      // 让用户无需手动选封面即可发布；手动封面不会被覆盖（见 [_applyAutoCoverFromThumbnail]）。
      unawaited(_applyAutoCoverFromThumbnail(destination));
    } catch (_) {
      // 缩略图仅用于预览；生成失败不应阻断视频上传。
    }
  }

  static ({int width, int height}) _fitThumbnailSize({
    required int width,
    required int height,
    required int maxEdge,
  }) {
    final sourceMaxEdge = width > height ? width : height;
    if (sourceMaxEdge <= maxEdge) return (width: width, height: height);
    final scale = maxEdge / sourceMaxEdge;
    return (
      width: (width * scale).round().clamp(1, maxEdge),
      height: (height * scale).round().clamp(1, maxEdge),
    );
  }

  /// 用视频缩略图作为默认封面并上传。仅在当前封面不是用户手动上传时执行，
  /// 以满足“新视频不覆盖用户手动上传的封面”的约束。
  Future<void> _applyAutoCoverFromThumbnail(String thumbnailPath) async {
    if (state.coverSource == PublishVideoCoverSource.manual) return;
    if (!ref.mounted || state.video?.thumbnailPath != thumbnailPath) return;

    state = state.copyWith(
      localCoverPath: thumbnailPath,
      coverSource: PublishVideoCoverSource.auto,
      clearCoverObjectKey: true,
      isUploadingCover: true,
      coverUploadProgress: 0,
      clearIssue: true,
      clearLastError: true,
    );

    final sessionId = await _ensureUploadSession();
    if (sessionId == null || !ref.mounted) return;
    if (state.localCoverPath != thumbnailPath) return;

    final uploadResult = await _uploader.uploadFileWithObjectKey(
      filePath: thumbnailPath,
      fileCategory: FileCategory.cover,
      uploadSessionId: sessionId,
      onProgress: (progress) {
        if (ref.mounted && state.localCoverPath == thumbnailPath) {
          state = state.copyWith(coverUploadProgress: progress);
        }
      },
    );
    if (!ref.mounted || state.localCoverPath != thumbnailPath) return;
    uploadResult.when(
      success: (uploaded) {
        _sessionManager.markResourceUploaded(sessionId);
        state = state.copyWith(
          isUploadingCover: false,
          coverUploadProgress: 1,
          coverObjectKey: uploaded.objectKey,
        );
        _markDraftDirty(immediate: true);
      },
      failure: (error) {
        state = state.copyWith(
          isUploadingCover: false,
          clearCoverObjectKey: true,
          lastError: error,
        );
      },
    );
  }

  /// 选择 3:4 封面、裁剪后校验 5MB，并立即上传。
  Future<void> pickAndUploadCover({
    required BuildContext context,
    required String toolbarTitle,
  }) async {
    if (state.isPickingCover || state.isUploadingCover) return;
    state = state.copyWith(
      isPickingCover: true,
      clearIssue: true,
      clearLastError: true,
    );

    try {
      final picked = await ImagePickerService.pickAndCropImage(
        context: context,
        ratioX: 3,
        ratioY: 4,
        toolbarTitle: toolbarTitle,
        allowedExtensions: const {'jpg', 'jpeg', 'png'},
        maxSourceBytes: kPublishVideoCoverMaxBytes,
      );
      if (picked == null) {
        if (ref.mounted) state = state.copyWith(isPickingCover: false);
        return;
      }

      final sizeBytes = await picked.length();
      if (sizeBytes > kPublishVideoCoverMaxBytes) {
        if (ref.mounted) {
          state = state.copyWith(
            isPickingCover: false,
            issue: PublishVideoIssue.coverTooLarge,
          );
        }
        return;
      }
      if (!ref.mounted) return;
      state = state.copyWith(
        localCoverPath: picked.path,
        coverSource: PublishVideoCoverSource.manual,
        clearCoverObjectKey: true,
        isPickingCover: false,
        isUploadingCover: true,
        coverUploadProgress: 0,
      );
      _markDraftDirty();

      final sessionId = await _ensureUploadSession();
      if (sessionId == null || !ref.mounted) return;
      final uploadResult = await _uploader.uploadFileWithObjectKey(
        filePath: picked.path,
        fileCategory: FileCategory.cover,
        uploadSessionId: sessionId,
        onProgress: (progress) {
          if (ref.mounted && state.localCoverPath == picked.path) {
            state = state.copyWith(coverUploadProgress: progress);
          }
        },
      );
      if (!ref.mounted || state.localCoverPath != picked.path) return;
      uploadResult.when(
        success: (uploaded) {
          _sessionManager.markResourceUploaded(sessionId);
          state = state.copyWith(
            isUploadingCover: false,
            coverUploadProgress: 1,
            coverObjectKey: uploaded.objectKey,
          );
          _markDraftDirty(immediate: true);
        },
        failure: (error) {
          state = state.copyWith(
            isUploadingCover: false,
            clearCoverObjectKey: true,
            lastError: error,
          );
        },
      );
    } on UnsupportedImageFormatException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isPickingCover: false,
        isUploadingCover: false,
        issue: PublishVideoIssue.coverUnsupportedFormat,
      );
    } on ImageTooLargeException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isPickingCover: false,
        isUploadingCover: false,
        issue: PublishVideoIssue.coverTooLarge,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isPickingCover: false,
        isUploadingCover: false,
        issue: PublishVideoIssue.coverPickFailed,
      );
    }
  }

  void _markDraftDirty({bool immediate = false}) {
    if (!ref.mounted ||
        state.isEditMode ||
        _restoringDraft ||
        _draftOwnerId.isEmpty) {
      return;
    }
    final snapshot = _toDraft(state);
    if (!_draftStarted && !snapshot.hasContent) return;
    _draftStarted = true;
    state = state.copyWith(draftSaveStatus: DraftSaveStatus.dirty);
    _draftAutosave.markDirty(snapshot, immediate: immediate);
  }

  PublishVideoDraft _toDraft(PublishVideoState current) {
    final currentVideo = current.video;
    final persistedVideo =
        currentVideo?.isUploaded == true ||
            (currentVideo?.uploadTaskId != null &&
                currentVideo?.path.isNotEmpty == true)
        ? currentVideo
        : null;
    final hasUploadedResource =
        persistedVideo != null || current.coverObjectKey != null;
    return PublishVideoDraft(
      videoTaskId: persistedVideo?.isUploaded == true
          ? null
          : persistedVideo?.uploadTaskId,
      videoLocalFilePath: persistedVideo?.isUploaded == true
          ? null
          : persistedVideo?.path,
      videoName: persistedVideo?.name ?? '',
      videoSizeBytes: persistedVideo?.sizeBytes ?? 0,
      videoDurationMs: persistedVideo?.durationMs ?? 0,
      videoWidth: persistedVideo?.width ?? 0,
      videoHeight: persistedVideo?.height ?? 0,
      videoObjectKey: persistedVideo?.objectKey,
      coverObjectKey: current.coverObjectKey,
      coverSource: current.coverSource.name,
      description: current.description,
      uploadSessionId: hasUploadedResource ? current.uploadSessionId : null,
      uploadSessionExpiresAt: hasUploadedResource
          ? current.uploadSessionExpiresAt
          : null,
      savedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  DraftAutosaveCoordinator<PublishVideoDraft> _createDraftAutosave(
    String ownerId,
  ) {
    return DraftAutosaveCoordinator<PublishVideoDraft>(
      save: (draft) => _writeDraft(ownerId, draft),
      onError: (error, stackTrace) {
        _handleDraftSaveError(ownerId, error, stackTrace);
      },
    );
  }

  Future<void> _writeDraft(String ownerId, PublishVideoDraft draft) async {
    if (ref.mounted && _draftOwnerId == ownerId) {
      state = state.copyWith(draftSaveStatus: DraftSaveStatus.saving);
    }
    if (ownerId.isNotEmpty) {
      await _draftRepo.savePublishVideoDraft(ownerId, draft);
    }
    if (ref.mounted && _draftOwnerId == ownerId) {
      state = state.copyWith(draftSaveStatus: DraftSaveStatus.saved);
    }
  }

  void _handleDraftSaveError(
    String ownerId,
    Object error,
    StackTrace stackTrace,
  ) {
    StoryLogger.w(
      'Failed to save publish-video draft',
      error: error,
      stackTrace: stackTrace,
      tag: 'PublishVideoDraft',
    );
    if (ref.mounted && _draftOwnerId == ownerId) {
      state = state.copyWith(draftSaveStatus: DraftSaveStatus.failed);
    }
  }

  Future<Result<ShortVideo>> publish() async {
    final video = state.video;
    final sessionId = int.tryParse(state.uploadSessionId ?? '');
    if (!state.canContinue ||
        video == null ||
        video.objectKey == null ||
        state.coverObjectKey == null ||
        sessionId == null) {
      return Result.failure(
        ApiError.unknown('Publish video form is incomplete'),
      );
    }

    state = state.copyWith(
      isPublishing: true,
      clearIssue: true,
      clearLastError: true,
    );
    final result = await _shortVideoRepository.publish(
      PublishShortVideoRequest(
        uploadSessionId: sessionId,
        videoObjectKey: video.objectKey!,
        coverObjectKey: state.coverObjectKey!,
        title: _stripExtension(video.name),
        description: state.description.trim(),
        durationSec: (video.durationMs / 1000).round(),
        width: video.width,
        height: video.height,
      ),
    );
    if (result.isSuccess) {
      if (_draftOwnerId.isNotEmpty) {
        final deleted = await _draftAutosave.discard(
          () => _draftRepo.deletePublishVideoDraft(_draftOwnerId),
        );
        if (!deleted) {
          StoryLogger.w(
            'Published short-video draft could not be deleted',
            tag: 'PublishVideoDraft',
          );
        }
      }
      _draftStarted = false;
      await _deleteCurrentLocalAssets();
    }
    if (!ref.mounted) {
      return result;
    }
    result.when(
      success: (_) => state = state.copyWith(isPublishing: false),
      failure: (error) =>
          state = state.copyWith(isPublishing: false, lastError: error),
    );
    return result;
  }

  Future<Result<ShortVideo>> submit() {
    return state.isEditMode ? _edit() : publish();
  }

  Future<Result<ShortVideo>> _edit() async {
    final session = state.editSession;
    final episodeId = state.editingEpisodeId;
    final sessionId = int.tryParse(state.uploadSessionId ?? '');
    if (!state.canContinue ||
        session == null ||
        episodeId == null ||
        sessionId == null) {
      return Result.failure(ApiError.unknown('Edit video form is incomplete'));
    }

    state = state.copyWith(
      isPublishing: true,
      clearIssue: true,
      clearLastError: true,
    );
    final result = await _shortVideoRepository.edit(
      episodeId,
      EditShortVideoRequest(
        uploadSessionId: sessionId,
        title: session.title,
        description: state.description.trim(),
        coverObjectKey: state.coverObjectKey ?? '',
      ),
    );
    if (!ref.mounted) return result;
    result.when(
      success: (_) => state = state.copyWith(isPublishing: false),
      failure: (error) =>
          state = state.copyWith(isPublishing: false, lastError: error),
    );
    return result;
  }

  Future<String?> _ensureUploadSession() async {
    final sessionId = await _sessionManager.ensure();
    if (sessionId != null || !ref.mounted) return sessionId;
    _applyUploadSessionFailure();
    return null;
  }

  void _applyUploadSessionFailure() {
    if (!ref.mounted) return;
    final currentVideo = state.video;
    final failure = _sessionFailure();
    state = state.copyWith(
      isUploadingCover: false,
      video: currentVideo?.isUploaded == true
          ? currentVideo
          : currentVideo?.copyWith(
              uploadStatus: PublishVideoUploadStatus.failed,
            ),
      lastError: ApiError.unknown(failure.encoded),
      clearIssue: true,
    );
  }

  UploadFailure _sessionFailure() {
    final apiError = _sessionManager.lastError;
    if (apiError != null) return UploadFailure.fromApiError(apiError);
    return switch (_sessionManager.lastFailure) {
      UploadSessionFailureReason.ownerChanged => const UploadFailure(
        UploadFailureKind.accountChanged,
      ),
      UploadSessionFailureReason.expiredWithResources => const UploadFailure(
        UploadFailureKind.sessionExpired,
      ),
      UploadSessionFailureReason.requestFailed ||
      UploadSessionFailureReason.unavailable ||
      UploadSessionFailureReason.none => const UploadFailure(
        UploadFailureKind.sessionUnavailable,
      ),
    };
  }

  Future<({int durationMs, int width, int height})> _readVideoDisplaySize(
    String path,
  ) async {
    final info = await _videoInfo.getVideoInfo(path);
    var width = info?.width ?? 0;
    var height = info?.height ?? 0;
    final orientation = info?.orientation ?? 0;
    if ((orientation == 90 || orientation == 270) && width > 0 && height > 0) {
      final originalWidth = width;
      width = height;
      height = originalWidth;
    }
    return (
      durationMs: info?.duration?.round() ?? 0,
      width: width,
      height: height,
    );
  }

  static String _stripExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  /// 解析草稿中的封面来源。旧草稿缺少 coverSource 字段时，若存在已上传
  /// 封面则按手动上传处理，避免新视频缩略图覆盖它。
  static PublishVideoCoverSource _resolveDraftCoverSource(
    PublishVideoDraft draft,
  ) {
    switch (draft.coverSource) {
      case 'auto':
        return PublishVideoCoverSource.auto;
      case 'manual':
        return PublishVideoCoverSource.manual;
      default:
        return draft.coverObjectKey != null
            ? PublishVideoCoverSource.manual
            : PublishVideoCoverSource.none;
    }
  }

  Future<void> _deleteCurrentLocalAssets() async {
    final video = state.video;
    final currentCoverPath = state.localCoverPath;
    final currentThumbnailPath = video?.thumbnailPath;
    if (video?.uploadTaskId case final taskId?) {
      await _coordinator.remove(taskId);
    } else if (video != null && !video.isUploading && video.path.isNotEmpty) {
      await VideoFilePickerService.deleteTemporaryFile(video.path);
    }
    final directory = await getApplicationDocumentsDirectory();
    final paths = <String?>{currentCoverPath, currentThumbnailPath};
    for (final path in paths) {
      await _deleteOwnedDraftFile(path, directory.path);
    }
  }

  void _syncVideoUploadTask(Map<String, UploadTask> tasks) {
    if (!ref.mounted) return;
    _syncCellularConfirmation();
    final video = state.video;
    final taskId = video?.uploadTaskId;
    if (video == null || taskId == null) return;
    final task = tasks[taskId];
    if (task == null || task.ownerUserId != ref.read(currentUserIdProvider)) {
      return;
    }
    final status = switch (task.status) {
      UploadTaskStatus.success => PublishVideoUploadStatus.success,
      UploadTaskStatus.failed ||
      UploadTaskStatus.canceled => PublishVideoUploadStatus.failed,
      UploadTaskStatus.merging => PublishVideoUploadStatus.merging,
      UploadTaskStatus.paused => PublishVideoUploadStatus.paused,
      UploadTaskStatus.queued ||
      UploadTaskStatus.uploading ||
      UploadTaskStatus.retryWaiting => PublishVideoUploadStatus.uploading,
    };
    final wasUploaded = video.isUploaded;
    final next = video.copyWith(
      uploadProgress: task.progress,
      uploadStatus: status,
      objectKey: task.objectKey,
      clearObjectKey: status != PublishVideoUploadStatus.success,
      speedBps: task.speedBps,
      networkWait: task.networkWait,
    );
    if (next == video) return;
    state = state.copyWith(
      video: next,
      lastError: status == PublishVideoUploadStatus.failed
          ? ApiError.unknown(task.lastError ?? 'Video upload failed')
          : null,
      clearLastError: status != PublishVideoUploadStatus.failed,
    );
    if (!wasUploaded && next.isUploaded) {
      _sessionManager.markResourceUploaded(task.uploadSessionId);
      _markDraftDirty(immediate: true);
    }
  }

  /// 把队列的蜂窝确认状态镜像进 state，驱动 UI 弹窗。
  void _syncCellularConfirmation({bool force = false}) {
    if (!ref.mounted) return;
    final pending = state.uploadSessionId != null &&
        _coordinator.pendingCellularConfirmations.contains(
          state.uploadSessionId,
        );
    if (pending == state.cellularConfirmationPending && !force) return;
    state = state.copyWith(cellularConfirmationPending: pending);
  }

  /// 手动暂停当前视频（分片任务保留断点，PRD「上传暂停」）。
  Future<void> pauseVideo() async {
    final taskId = state.video?.uploadTaskId;
    if (taskId == null) return;
    await _coordinator.pauseTask(taskId);
  }

  /// 手动继续当前视频：从断点续传；蜂窝下按 PRD 直接上传不再询问。
  Future<void> resumeVideo() async {
    final taskId = state.video?.uploadTaskId;
    if (taskId == null) return;
    await _coordinator.resumeTask(taskId);
  }

  /// 处理当前草稿 session 的蜂窝确认结果（UI 弹窗回调）。
  Future<void> confirmCellularUpload(bool accepted) async {
    final sessionId = state.uploadSessionId;
    if (sessionId == null) return;
    await _coordinator.confirmCellularUpload(
      sessionId,
      accepted: accepted,
    );
    _syncCellularConfirmation(force: true);
  }

  Future<void> _restoreVideoUploadTask(PublishVideoFile video) async {
    final taskId = video.uploadTaskId;
    if (taskId == null || video.path.isEmpty) return;
    final ownerUserId = ref.read(currentUserIdProvider);
    if (ownerUserId == null) return;
    await _coordinator.ready;
    if (!ref.mounted || state.video?.uploadTaskId != taskId) return;

    final existing = _coordinator.task(taskId);
    if (state.uploadSessionId == null && existing != null) {
      _sessionManager.restore(
        sessionId: existing.uploadSessionId,
        expiresAt: existing.uploadSessionExpiresAt,
        hasExternalResources: existing.status == UploadTaskStatus.success,
      );
      state = state.copyWith(
        uploadSessionId: existing.uploadSessionId,
        uploadSessionExpiresAt: existing.uploadSessionExpiresAt,
        clearUploadSessionExpiresAt: existing.uploadSessionExpiresAt == null,
      );
    }

    final restored = await _sessionManager.restoreTasks((sessionId, expiresAt) {
      if (state.video?.uploadTaskId != taskId ||
          state.video?.path != video.path) {
        return const <UploadTask>[];
      }
      return [
        UploadTask(
          id: taskId,
          localFilePath: video.path,
          fileName: video.name,
          fileSize: video.sizeBytes,
          contentType: _videoContentType(video.name),
          category: FileCategory.video,
          ownerUserId: ownerUserId,
          uploadSessionId: sessionId,
          uploadSessionExpiresAt: expiresAt,
          status: UploadTaskStatus.paused,
        ),
      ];
    });
    if (!ref.mounted || state.video?.uploadTaskId != taskId) return;
    if (!restored) {
      _applyUploadSessionFailure();
      return;
    }
    _syncVideoUploadTask(ref.read(uploadCoordinatorProvider));
  }

  bool _isCurrentOperation(int generation, String ownerUserId) =>
      ref.mounted &&
      generation == _operationGeneration &&
      ref.read(currentUserIdProvider) == ownerUserId;

  static String _videoContentType(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final extension = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
    return switch (extension) {
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'm4v' => 'video/x-m4v',
      'webm' => 'video/webm',
      _ => 'application/octet-stream',
    };
  }

  static Future<void> _deleteOwnedDraftFile(
    String? path,
    String documentsPath,
  ) async {
    if (path == null ||
        (!path.startsWith('$documentsPath/publish_video_draft_') &&
            !path.startsWith('$documentsPath/publish_video_thumb_'))) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // 清理预览文件失败不应阻断清除草稿或退出页面。
    }
  }
}
