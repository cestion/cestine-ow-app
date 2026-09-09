import 'dart:async';
import 'dart:io';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:path_provider/path_provider.dart';

import '../core/story_logger.dart';
import '../core/upload_failure.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../services/video_file_picker_service.dart';
import '../styles/story_format.dart';
import '../utils/natural_compare.dart';
import 'video_upload_state.dart';
import 'upload_coordinator.dart';
import 'upload_session_manager.dart';

/// 单个短剧最多可上传的视频（剧集）数量上限。
const int kMaxEpisodesPerDrama = 100;

/// 单个视频文件大小上限：2GB。超过此大小不允许上传，该项标记为失败并
/// 在视频卡片上展示错误文案。Controller 无 BuildContext 无法直接本地化，
/// 因此将 l10n key 写入 [VideoUploadItem.error]，由 UI 侧翻译展示。
const int kMaxVideoSizeBytes = 2 * 1024 * 1024 * 1024;

/// Controller 写入 [VideoUploadItem.error] 的「视频过大」错误标记（即 l10n
/// key），UI 侧（[create_drama_page] 的 `_videoErrorMessage`）据此展示本地化文案。
const String kVideoTooLargeErrorKey = 'createDramaVideoTooLarge';

/// 任一视频超过 2GB 时抛出的 StateError message，UI 层据此展示「所选视频中有文件超过2GB」Toast。
const String kVideoAnyTooLargeErrorKey = 'createDramaVideoAnyTooLarge';

/// 管理创建短剧流程中视频文件的选择与上传。
///
/// 页面退出后 UI 状态销毁，实际任务由全局上传队列继续管理。
class VideoUploadController extends Notifier<VideoUploadState> {
  late final UploadCoordinator _coordinator;
  late final UploadSessionManager _sessionManager;
  final FlutterVideoInfo _videoInfo = FlutterVideoInfo();
  int _idSeq = 0;
  int _operationGeneration = 0;

  @override
  VideoUploadState build() {
    _coordinator = ref.read(uploadCoordinatorProvider.notifier);
    _sessionManager = UploadSessionManager(
      uploader: ref.read(fileUploadRepositoryProvider),
      coordinator: _coordinator,
      readOwnerUserId: () => ref.read(currentUserIdProvider),
      onSessionChanged: (sessionId, expiresAt) {
        if (!ref.mounted) return;
        state = state.copyWith(
          uploadSessionId: sessionId,
          uploadSessionExpiresAt: expiresAt,
          clearUploadSessionExpiresAt: expiresAt == null,
        );
      },
    );
    ref.onDispose(_sessionManager.dispose);
    ref.listen<Map<String, UploadTask>>(uploadCoordinatorProvider, (_, next) {
      _syncUploadTasks(next);
    });
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;
      _operationGeneration++;
      _sessionManager.handleOwnerChanged();
      // Queue entries remain owner-scoped and paused for draft recovery.
      state = const VideoUploadState();
    });
    return const VideoUploadState();
  }

  /// 打开系统多选视频选择器；选择后追加到列表并自动开始上传。
  ///
  /// [initialDescription] 用于将第一步的短剧简介自动填入每个新分集的描述，
  /// 用户仍可在分集卡片中手动编辑。
  ///
  /// 抛出异常时由调用方（页面）捕获并以 toast 提示。
  Future<void> pickVideos({String initialDescription = ''}) async {
    if (state.isPicking) return;
    final generation = _operationGeneration;
    final ownerUserId = ref.read(currentUserIdProvider);
    if (ownerUserId == null) return;
    final remaining = kMaxEpisodesPerDrama - state.videos.length;
    if (remaining <= 0) {
      // 已达上限：忽略本次选择，UI 侧按钮已置灰；此处兜底保护。
      state = state.copyWith(isPicking: false, clearPickOverflow: true);
      return;
    }
    state = state.copyWith(isPicking: true);
    final adoptedItems = <VideoUploadItem>[];
    StoryLogger.i('打开视频选择器', tag: 'VideoUpload');
    try {
      final result = await FilePicker.pickFiles(type: FileType.video);
      if (!_isCurrentOperation(generation, ownerUserId)) return;
      if (result.isEmpty) {
        StoryLogger.i('用户取消选择视频', tag: 'VideoUpload');
        state = state.copyWith(isPicking: false, clearPickOverflow: true);
        return;
      }
      final allPaths = result
          .map((file) => file.path)
          .whereType<String>()
          .toList(growable: false);
      final paths = allPaths.length > remaining
          ? allPaths.sublist(0, remaining)
          : allPaths;
      final overflow = allPaths.length - paths.length;
      StoryLogger.i(
        '已选择 ${allPaths.length} 个视频'
        '${overflow > 0 ? "（超出上限 $remaining，截断 $overflow 个）" : ""}',
        tag: 'VideoUpload',
      );
      final fileInfos = <Map<String, dynamic>>[];
      for (final path in paths) {
        if (!_isCurrentOperation(generation, ownerUserId)) {
          await _discardAdoptedItems(adoptedItems);
          return;
        }
        final file = File(path);
        final name = path.split(Platform.pathSeparator).last;
        var durationMs = 0;
        var sizeBytes = 0;
        var width = 0;
        var height = 0;
        var orientation = 0;
        try {
          final meta = await _readVideoDisplaySize(path);
          durationMs = meta.durationMs;
          width = meta.width;
          height = meta.height;
          orientation = meta.orientation;
        } catch (e, st) {
          StoryLogger.w(
            'getVideoInfo 失败 $path: $e',
            tag: 'VideoUpload',
            error: e,
            stackTrace: st,
          );
        }
        try {
          sizeBytes = await file.length();
        } catch (e, st) {
          StoryLogger.w(
            '读取文件大小失败 $path: $e',
            tag: 'VideoUpload',
            error: e,
            stackTrace: st,
          );
        }
        fileInfos.add({
          'path': path,
          'name': name,
          'durationMs': durationMs,
          'sizeBytes': sizeBytes,
          'width': width,
          'height': height,
          'orientation': orientation,
        });
      }
      // 任一视频超过 2GB：全部拒绝，抛出异常交由 UI 层展示 Toast。
      for (final info in fileInfos) {
        final sizeBytes = info['sizeBytes'] as int;
        final name = info['name'] as String;
        if (sizeBytes > kMaxVideoSizeBytes) {
          StoryLogger.w(
            '所选视频中有文件超过 2GB，全部拒绝: name=$name '
            'size=${StoryFormat.formatFileSize(sizeBytes)} '
            'limit=${StoryFormat.formatFileSize(kMaxVideoSizeBytes)}',
            tag: 'VideoUpload',
          );
          throw StateError(kVideoAnyTooLargeErrorKey);
        }
      }
      if (!_isCurrentOperation(generation, ownerUserId)) {
        await _discardAdoptedItems(adoptedItems);
        return;
      }
      for (final info in fileInfos) {
        final width = info['width'] as int;
        final height = info['height'] as int;
        StoryLogger.i(
          '视频元数据: name=${info['name']} '
          'width=$width height=$height orientation=${info['orientation']} '
          'durationMs=${info['durationMs']} sizeBytes=${info['sizeBytes']}',
          tag: 'VideoUpload',
        );
        final id = '${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}';
        final managedPath = await _coordinator.adoptFile(
          id,
          info['path'] as String,
        );
        adoptedItems.add(
          VideoUploadItem(
            id: id,
            path: managedPath,
            name: info['name'] as String,
            durationMs: info['durationMs'] as int,
            sizeBytes: info['sizeBytes'] as int,
            width: width,
            height: height,
            description: initialDescription,
          ),
        );
        if (!_isCurrentOperation(generation, ownerUserId)) {
          await _discardAdoptedItems(adoptedItems);
          return;
        }
      }
      final processable = adoptedItems;
      final List<VideoUploadItem> toProcess;
      if (state.isEditMode) {
        // 编辑模式：已有剧集不可重排，新选视频直接追加到列表末尾，
        // 不按文件名排序、不合并到已有列表。
        state = state.copyWith(
          videos: [...state.videos, ...adoptedItems],
          isPicking: false,
          pickOverflow: overflow,
        );
        toProcess = processable;
      } else {
        // 新建模式：自动按文件名自然序插入到已有列表的「最合理位置」，
        // 保留已有项的相对顺序。新项自身先做一次自然序排序，再逐个按
        // 「找到第一个比它大的位置之前」插入。
        final sortedNew = naturalSortBy(
          adoptedItems,
          (VideoUploadItem v) => _stripExtension(v.name),
        );
        state = state.copyWith(
          videos: _mergeSorted(state.videos, sortedNew),
          isPicking: false,
          pickOverflow: overflow,
        );
        toProcess = processable;
      }
      unawaited(_generateThumbnails(toProcess));
      unawaited(_enqueueBatch(toProcess, generation));
    } catch (e, st) {
      await _discardAdoptedItems(adoptedItems);
      StoryLogger.e(
        'pickVideos 异常: $e',
        tag: 'VideoUpload',
        error: e,
        stackTrace: st,
      );
      if (_isCurrentOperation(generation, ownerUserId)) {
        state = state.copyWith(isPicking: false, clearPickOverflow: true);
      }
      if (!_isCurrentOperation(generation, ownerUserId)) return;
      rethrow;
    }
  }

  /// 对一批新加入的视频生成缩略图（取第 1 秒画面）。
  ///
  /// 缩略图与托管视频放在同一任务目录，便于统一回收。
  Future<void> _generateThumbnails(List<VideoUploadItem> items) async {
    for (final item in items) {
      if (!ref.mounted) return;
      try {
        final destPath = '${File(item.path).parent.path}/thumbnail.jpg';
        final ok = await FcNativeVideoThumbnail().getVideoThumbnail(
          srcFile: item.path,
          destFile: destPath,
          width: 120,
          height: 100,
          format: 'jpeg',
          quality: 75,
        );
        if (ok && ref.mounted) {
          final exists = state.videos.any((video) => video.id == item.id);
          if (exists) {
            _updateItem(item.id, (v) => v.copyWith(thumbnailPath: destPath));
          } else {
            await _deleteOwnedThumbnail(destPath);
          }
        }
      } catch (e, st) {
        StoryLogger.w(
          '生成缩略图失败 ${item.name}: $e',
          tag: 'VideoUpload',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// 重新选择单个视频文件替换 [videoId] 指定的分集。
  ///
  /// 新视频继承原分集的描述与列表位置，旧视频的上传任务及临时文件会被
  /// 清理。若所选文件超过 [kMaxVideoSizeBytes]，抛出 [StateError]（message
  /// 为 [kVideoAnyTooLargeErrorKey]），由调用方展示 Toast。
  Future<void> replaceVideo(String videoId) async {
    if (state.isPicking) return;
    final index = state.videos.indexWhere((v) => v.id == videoId);
    if (index < 0) return;
    final oldItem = state.videos[index];

    final generation = _operationGeneration;
    final ownerUserId = ref.read(currentUserIdProvider);
    if (ownerUserId == null) return;

    state = state.copyWith(isPicking: true);
    String? pickedTemporaryPath;
    String? managedVideoPath;
    VideoUploadItem? acceptedItem;
    try {
      final result = await FilePicker.pickFiles(type: FileType.video);
      if (!_isCurrentOperation(generation, ownerUserId)) {
        final path = result.firstOrNull?.path;
        if (path != null) {
          await VideoFilePickerService.deleteTemporaryFile(path);
        }
        return;
      }
      if (result.isEmpty) {
        state = state.copyWith(isPicking: false);
        return;
      }
      final file = result.first;
      final path = file.path;
      if (path == null || path.isEmpty) {
        state = state.copyWith(isPicking: false);
        return;
      }
      pickedTemporaryPath = path;
      final fileObj = File(path);
      final name = path.split(Platform.pathSeparator).last;
      var sizeBytes = 0;
      try {
        sizeBytes = await fileObj.length();
      } catch (e, st) {
        StoryLogger.w(
          '读取文件大小失败 $path: $e',
          tag: 'VideoUpload',
          error: e,
          stackTrace: st,
        );
      }
      if (sizeBytes > kMaxVideoSizeBytes) {
        state = state.copyWith(isPicking: false);
        throw StateError(kVideoAnyTooLargeErrorKey);
      }
      final meta = await _readVideoDisplaySize(path);
      if (!_isCurrentOperation(generation, ownerUserId)) {
        await VideoFilePickerService.deleteTemporaryFile(path);
        return;
      }
      if (meta.width <= 0 ||
          meta.height <= 0 ||
          meta.durationMs <= 0) {
        state = state.copyWith(isPicking: false);
        await VideoFilePickerService.deleteTemporaryFile(path);
        return;
      }
      final newId =
          '${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}';
      final managedPath = await _coordinator.adoptFile(newId, path);
      managedVideoPath = managedPath;
      if (managedPath != path) {
        await VideoFilePickerService.deleteTemporaryFile(path);
      }
      if (!_isCurrentOperation(generation, ownerUserId)) {
        await _coordinator.discardManagedFile(managedPath);
        return;
      }
      final newItem = VideoUploadItem(
        id: newId,
        path: managedPath,
        name: name,
        description: oldItem.description,
        durationMs: meta.durationMs,
        sizeBytes: sizeBytes,
        width: meta.width,
        height: meta.height,
        isReplacement: oldItem.preexisting || oldItem.isReplacement,
      );
      final newList = List<VideoUploadItem>.from(state.videos);
      newList[index] = newItem;
      state = state.copyWith(videos: newList, isPicking: false);
      acceptedItem = newItem;
      unawaited(_removeManagedItem(oldItem));
      unawaited(_generateThumbnails([newItem]));
      unawaited(_enqueueBatch([newItem], generation));
    } catch (e, st) {
      final pathToCleanup = pickedTemporaryPath;
      if (pathToCleanup != null &&
          (acceptedItem == null ||
              state.videos.every((v) => v.path != pathToCleanup))) {
        await VideoFilePickerService.deleteTemporaryFile(pathToCleanup);
      }
      final managedPathToCleanup = managedVideoPath;
      if (acceptedItem == null && managedPathToCleanup != null) {
        await _coordinator.discardManagedFile(managedPathToCleanup);
      }
      if (_isCurrentOperation(generation, ownerUserId)) {
        state = state.copyWith(isPicking: false);
      }
      if (e is StateError && e.message == kVideoAnyTooLargeErrorKey) rethrow;
      StoryLogger.e(
        '替换视频失败 videoId=$videoId: $e',
        tag: 'VideoUpload',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// 确保存在一个共享的上传会话：已存在则复用，否则创建并记入 state。
  ///
  /// 创建短剧流程中，封面、视频、角色头像必须共用同一个 `uploadSessionId`，
  /// 否则后端提交时会校验「对象键不属于当前上传会话」而失败。
  Future<String?> ensureUploadSession() async {
    final sessionId = await _sessionManager.ensure();
    if (sessionId != null) {
      StoryLogger.i('上传会话可用 uploadSessionId=$sessionId', tag: 'VideoUpload');
    }
    return sessionId;
  }

  /// Adds a batch to the global sequential queue with one shared session.
  ///
  /// Items are reordered to match their current display order in
  /// [state.videos] before being enqueued, so the upload start order aligns
  /// with the UI.
  Future<void> _enqueueBatch(
    List<VideoUploadItem> items,
    int generation,
  ) async {
    StoryLogger.i('上传批次开始，共 ${items.length} 个文件', tag: 'VideoUpload');
    final sessionId = await ensureUploadSession();
    if (!ref.mounted || generation != _operationGeneration) return;
    if (sessionId == null) {
      StoryLogger.e('无可用上传会话，批次上传终止', tag: 'VideoUpload');
      for (final item in items) {
        _updateItem(
          item.id,
          (video) => video.copyWith(
            status: VideoUploadStatus.failed,
            error: _sessionFailureError(),
          ),
        );
      }
      return;
    }
    final ownerUserId = ref.read(currentUserIdProvider);
    if (ownerUserId == null) {
      for (final item in items) {
        _updateItem(
          item.id,
          (video) => video.copyWith(
            status: VideoUploadStatus.failed,
            error: const UploadFailure(
              UploadFailureKind.accountChanged,
            ).encoded,
          ),
        );
      }
      return;
    }

    // 按当前 UI 列表中的实际顺序重排，使上传顺序与展示顺序一致。
    // 不在列表中的项保留在末尾，仍走 stillPresent 检查并被清理。
    final orderById = {
      for (var i = 0; i < state.videos.length; i++) state.videos[i].id: i,
    };
    final orderedItems = items.toList()
      ..sort((a, b) {
        final aIndex = orderById[a.id];
        final bIndex = orderById[b.id];
        if (aIndex != null && bIndex != null) {
          return aIndex.compareTo(bIndex);
        }
        if (aIndex != null) return -1;
        if (bIndex != null) return 1;
        return 0;
      });

    for (final item in orderedItems) {
      if (!ref.mounted || generation != _operationGeneration) return;
      final stillPresent = state.videos.any(
        (video) => video.id == item.id && video.path == item.path,
      );
      if (!stillPresent) {
        await _coordinator.discardManagedFile(item.path);
        continue;
      }
      try {
        await _coordinator.enqueue(
          UploadTask(
            id: item.id,
            localFilePath: item.path,
            fileName: item.name,
            fileSize: item.sizeBytes,
            contentType: _contentTypeFor(item.name),
            category: FileCategory.video,
            ownerUserId: ownerUserId,
            uploadSessionId: sessionId,
            uploadSessionExpiresAt: state.uploadSessionExpiresAt,
          ),
        );
      } catch (error, stackTrace) {
        StoryLogger.w(
          '视频加入上传队列失败',
          tag: 'VideoUpload',
          error: error,
          stackTrace: stackTrace,
        );
        _updateItem(
          item.id,
          (video) => video.copyWith(
            status: VideoUploadStatus.failed,
            error: const UploadFailure(
              UploadFailureKind.accountChanged,
            ).encoded,
          ),
        );
      }
    }
    StoryLogger.i('上传批次已加入队列', tag: 'VideoUpload');
  }

  /// Retries the original managed local file without reopening the picker.
  Future<void> retry(String id) async {
    final index = state.videos.indexWhere((video) => video.id == id);
    if (index < 0) return;
    final item = state.videos[index];
    if (item.path.isEmpty) return;
    final generation = _operationGeneration;
    final sessionId = await ensureUploadSession();
    if (!ref.mounted || generation != _operationGeneration) return;
    final stillPresent = state.videos.any(
      (video) => video.id == item.id && video.path == item.path,
    );
    if (!stillPresent) {
      await _coordinator.discardManagedFile(item.path);
      return;
    }
    if (sessionId == null) {
      _updateItem(
        id,
        (video) => video.copyWith(
          status: VideoUploadStatus.failed,
          error: _sessionFailureError(),
        ),
      );
      return;
    }
    if (_coordinator.task(id) == null) {
      final ownerUserId = ref.read(currentUserIdProvider);
      if (ownerUserId == null) return;
      try {
        await _coordinator.enqueue(
          UploadTask(
            id: item.id,
            localFilePath: item.path,
            fileName: item.name,
            fileSize: item.sizeBytes,
            contentType: _contentTypeFor(item.name),
            category: FileCategory.video,
            ownerUserId: ownerUserId,
            uploadSessionId: sessionId,
            uploadSessionExpiresAt: state.uploadSessionExpiresAt,
          ),
        );
      } on StateError {
        _updateItem(
          id,
          (video) => video.copyWith(
            status: VideoUploadStatus.failed,
            error: const UploadFailure(
              UploadFailureKind.accountChanged,
            ).encoded,
          ),
        );
      }
      return;
    }
    final task = _coordinator.task(id)!;
    if (task.status == UploadTaskStatus.queued ||
        task.status == UploadTaskStatus.uploading ||
        task.status == UploadTaskStatus.merging) {
      return;
    }
    await _coordinator.retry(id);
  }

  void markSessionResourceUploaded(String sessionId) {
    _sessionManager.markResourceUploaded(sessionId);
  }

  /// 清除上次 pickVideos 截断标记，UI 在展示 Toast 后调用以避免重复。
  void clearPickOverflow() {
    if (state.pickOverflow == 0) return;
    state = state.copyWith(clearPickOverflow: true);
  }

  /// 移除某个视频（未上传完成的也会中止状态展示）。
  void remove(String id) {
    final index = state.videos.indexWhere((video) => video.id == id);
    final item = index < 0 ? null : state.videos[index];
    state = state.copyWith(
      videos: state.videos.where((v) => v.id != id).toList(growable: false),
    );
    if (item != null) unawaited(_removeManagedItem(item));
  }

  /// 更新单集简介；上传、重试和重排均会保留该值。
  void updateDescription(String id, String description) {
    _updateItem(id, (video) => video.copyWith(description: description));
  }

  /// 拖动重排视频列表。
  ///
  /// `oldIndex`/`newIndex` 采用 Flutter `SliverReorderableList.onReorderItem`
  /// 的语义：`newIndex` 表示「移除 `oldIndex` 处元素后，再将其插入到 `newIndex`」，
  /// 因此**不需要**在 `oldIndex < newIndex` 时再做 −1 校正（这是与旧版
  /// `onReorder` 的关键差别，旧版的 `onReorder` 才需要 −1 校正）。
  ///
  /// 当 `oldIndex == newIndex` 时表示位置不变，直接返回。
  ///
  /// 编辑模式守卫：保持「已有剧集固定在前」不变量。已有剧集（`preexisting`
  /// 为 true）不允许被拖动（UI 已禁用，此处兜底）；新视频被拖入已有区间时
  /// 钳制到 `pCount`（紧贴已有区间末尾），避免提交时 `episodeNo = i+1`
  /// 与已有剧集服务端序号冲突。
  void move(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final list = List<VideoUploadItem>.from(state.videos);
    if (oldIndex < 0 || oldIndex >= list.length) return;
    var target = newIndex.clamp(0, list.length - 1);

    if (state.isEditMode) {
      final fixedCount =
          list.where((v) => v.preexisting || v.isReplacement).length;
      if (oldIndex < fixedCount) return;
      if (target < fixedCount) target = fixedCount;
    }

    final item = list.removeAt(oldIndex);
    list.insert(target, item);
    state = state.copyWith(videos: list);
  }

  /// 按文件名自然序把 [newItems]（调用方已对自身排序）逐个**插入**到
  /// [existing] 中「第一个比新项大的位置」之前；找不到则追加末尾。
  ///
  /// 关键性质：
  /// 1. [existing] 的相对顺序**完全保留**——用户手动拖动后的排序不受
  ///    添加新视频影响；只有「能放得更合理」的空缺处会被新项占用。
  /// 2. 名字重复的项自然走「找不到更大者」分支追加到末尾，行为可预期。
  /// 3. 若 [existing] 本身已序，结果即严格已序。
  ///
  /// 排序 key 取 `_stripExtension(name)`（去掉扩展名），与提交时
  /// `episode.title` 用的相同，避免 `第1集.mp4` 与 `第1集.mov` 因扩展名
  /// 字符差异被错排。
  List<VideoUploadItem> _mergeSorted(
    List<VideoUploadItem> existing,
    List<VideoUploadItem> newItems,
  ) {
    final result = List<VideoUploadItem>.of(existing);
    for (final newItem in newItems) {
      final key = _stripExtension(newItem.name);
      var inserted = false;
      for (var i = 0; i < result.length; i++) {
        if (naturalCompare(_stripExtension(result[i].name), key) > 0) {
          result.insert(i, newItem);
          inserted = true;
          break;
        }
      }
      if (!inserted) result.add(newItem);
    }
    return result;
  }

  /// 取排序 key：去掉文件扩展名后的文件名。与
  /// `CreateDramaController._stripExtension` 实现一致（重复 4 行可接受，
  /// 避免改动稳定的 `create_drama_controller.dart`）。
  static String _stripExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  /// 读取本地视频元数据；宽高按 [VideoData.orientation] 校正为**显示尺寸**。
  ///
  /// Android 竖拍常见 orientation=90/270：编码帧仍是横的（如 1920×1080），
  /// 但播放/封面按竖屏显示（1080×1920）。提交给后端的应是显示宽高。
  Future<({int durationMs, int width, int height, int orientation})>
  _readVideoDisplaySize(String path) async {
    final info = await _videoInfo.getVideoInfo(path);
    final durationMs = info?.duration?.round() ?? 0;
    var width = info?.width ?? 0;
    var height = info?.height ?? 0;
    final orientation = info?.orientation ?? 0;
    final rotated = orientation == 90 || orientation == 270;
    if (rotated && width > 0 && height > 0) {
      final tmp = width;
      width = height;
      height = tmp;
    }
    return (
      durationMs: durationMs,
      width: width,
      height: height,
      orientation: orientation,
    );
  }

  /// 重置到初始状态：清空视频列表与上传会话。
  void reset() {
    final items = state.videos
        .where((video) => !video.preexisting)
        .toList(growable: false);
    _operationGeneration++;
    _sessionManager.reset();
    state = const VideoUploadState();
    for (final item in items) {
      unawaited(_removeManagedItem(item));
    }
  }

  /// 编辑模式：用 edit-sessions 返回的数据初始化视频列表与上传会话。
  ///
  /// 已有剧集以 success 状态回显，`path` 使用 `videoUrl`（远程 MP4），
  /// `videoObjectKey` 使用 `hlsOutputKey`（提交时复用，无需重新上传）。
  /// 后续新选的视频会复用同一 `uploadSessionId` 继续上传。
  void initWithEditSession(DramaEditSession session) {
    _operationGeneration++;
    _sessionManager.restore(
      sessionId: session.uploadSessionId,
      expiresAt: null,
      hasExternalResources: true,
    );
    final episodes = session.episodes ?? const [];
    final videos = <VideoUploadItem>[
      for (final ep in episodes)
        VideoUploadItem(
          id: ep.id ?? '${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}',
          path: ep.videoUrl ?? '',
          name: ep.title,
          description: ep.description ?? '',
          durationMs: ep.durationSec * 1000,
          sizeBytes: ep.videoSizeBytes ?? 0,
          progress: 1.0,
          status: VideoUploadStatus.success,
          url: ep.videoUrl,
          preexisting: true,
        ),
    ];
    state = VideoUploadState(
      videos: videos,
      uploadSessionId: session.uploadSessionId,
      isEditMode: true,
    );
  }

  /// 草稿恢复：重建成功项与 App 托管目录中的待上传/暂停任务。
  ///
  /// 仅在当前视频列表为空时执行，避免覆盖正在进行的上传。
  void restoreDraftVideos({
    required String? sessionId,
    required int? sessionExpiresAt,
    required bool hasExternalResources,
    required List<DraftVideoItem> videos,
  }) {
    if (state.videos.isNotEmpty) return;
    if (videos.isEmpty && sessionId == null) return;
    _operationGeneration++;
    _sessionManager.restore(
      sessionId: sessionId,
      expiresAt: sessionExpiresAt,
      hasExternalResources:
          hasExternalResources ||
          videos.any(
            (video) => video.videoObjectKey?.trim().isNotEmpty == true,
          ),
    );
    final items = <VideoUploadItem>[
      for (final v in videos)
        VideoUploadItem(
          id:
              v.taskId ??
              '${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}',
          path: v.localFilePath ?? '',
          name: v.name,
          description: v.description,
          durationMs: v.durationMs,
          sizeBytes: v.sizeBytes,
          width: v.width,
          height: v.height,
          progress: v.videoObjectKey?.trim().isNotEmpty == true ? 1.0 : 0,
          status: v.videoObjectKey?.trim().isNotEmpty == true
              ? VideoUploadStatus.success
              : VideoUploadStatus.paused,
          url: v.url,
          videoObjectKey: v.videoObjectKey,
          thumbnailPath: v.thumbnailPath,
          isReplacement: v.isReplacement,
          restoredFromDraft: (v.localFilePath ?? '').isEmpty,
        ),
    ];
    state = VideoUploadState(
      videos: items,
      uploadSessionId: sessionId,
      uploadSessionExpiresAt: sessionExpiresAt,
    );
    final generation = _operationGeneration;
    unawaited(_restoreManagedTasks(items, generation));
  }

  Future<void> _restoreManagedTasks(
    List<VideoUploadItem> items,
    int generation,
  ) async {
    final ownerUserId = ref.read(currentUserIdProvider);
    if (ownerUserId == null) return;
    if (!ref.mounted ||
        generation != _operationGeneration ||
        ref.read(currentUserIdProvider) != ownerUserId) {
      return;
    }
    final restored = await _sessionManager.restoreTasks((
      activeSessionId,
      expiresAt,
    ) {
      return [
        for (final item in items)
          if (!item.isSuccess &&
              item.path.isNotEmpty &&
              state.videos.any(
                (video) => video.id == item.id && video.path == item.path,
              ))
            UploadTask(
              id: item.id,
              localFilePath: item.path,
              fileName: item.name,
              fileSize: item.sizeBytes,
              contentType: _contentTypeFor(item.name),
              category: FileCategory.video,
              ownerUserId: ownerUserId,
              uploadSessionId: activeSessionId,
              uploadSessionExpiresAt: expiresAt,
              status: UploadTaskStatus.paused,
            ),
      ];
    });
    if (!ref.mounted ||
        generation != _operationGeneration ||
        ref.read(currentUserIdProvider) != ownerUserId) {
      return;
    }
    if (!restored) {
      final error = _sessionFailureError();
      for (final item in items) {
        if (!item.isSuccess && item.path.isNotEmpty) {
          _updateItem(
            item.id,
            (video) =>
                video.copyWith(status: VideoUploadStatus.failed, error: error),
          );
        }
      }
      return;
    }
    _syncUploadTasks(ref.read(uploadCoordinatorProvider));
  }

  void _updateItem(
    String id,
    VideoUploadItem Function(VideoUploadItem) updater,
  ) {
    if (!ref.mounted) return;
    final list = state.videos;
    final i = list.indexWhere((v) => v.id == id);
    if (i < 0) return;
    final updated = updater(list[i]);
    if (updated == list[i]) return;
    final newList = List<VideoUploadItem>.from(list);
    newList[i] = updated;
    state = state.copyWith(videos: newList);
  }

  void _syncUploadTasks(Map<String, UploadTask> tasks) {
    if (!ref.mounted) return;
    _syncCellularConfirmation();
    if (state.videos.isEmpty) return;
    final ownerUserId = ref.read(currentUserIdProvider);
    var changed = false;
    final videos = <VideoUploadItem>[
      for (final video in state.videos)
        if (tasks[video.id] case final task?
            when task.ownerUserId == ownerUserId)
          _applyTask(video, task, () => changed = true)
        else
          video,
    ];
    if (changed) state = state.copyWith(videos: videos);
  }

  VideoUploadItem _applyTask(
    VideoUploadItem video,
    UploadTask task,
    void Function() markChanged,
  ) {
    final status = switch (task.status) {
      UploadTaskStatus.queued ||
      UploadTaskStatus.retryWaiting => VideoUploadStatus.pending,
      UploadTaskStatus.uploading => VideoUploadStatus.uploading,
      UploadTaskStatus.merging => VideoUploadStatus.merging,
      UploadTaskStatus.paused => VideoUploadStatus.paused,
      UploadTaskStatus.success => VideoUploadStatus.success,
      UploadTaskStatus.failed ||
      UploadTaskStatus.canceled => VideoUploadStatus.failed,
    };
    final next = video.copyWith(
      path: task.localFilePath,
      status: status,
      progress: task.progress,
      url: task.publicUrl,
      videoObjectKey: task.objectKey,
      speedBps: task.speedBps,
      networkWait: task.networkWait,
      error: status == VideoUploadStatus.failed ? task.lastError : null,
      clearError: status != VideoUploadStatus.failed,
    );
    if (next != video) markChanged();
    return next;
  }

  /// 手动暂停某个视频（分片任务保留断点，PRD「上传暂停」）。
  Future<void> pauseVideo(String id) => _coordinator.pauseTask(id);

  /// 手动继续某个视频：从断点续传；蜂窝下按 PRD 直接上传不再询问。
  Future<void> resumeVideo(String id) => _coordinator.resumeTask(id);

  /// 处理当前草稿 session 的蜂窝确认结果（UI 弹窗回调）。
  ///
  /// 确认 → 从断点继续上传并标记本 session 后续不再询问；
  /// 取消 → 维持暂停（保断点），用户之后手动点「上传」直接续传。
  Future<void> confirmCellularUpload(bool accepted) async {
    final sessionId = state.uploadSessionId;
    if (sessionId == null) return;
    await _coordinator.confirmCellularUpload(
      sessionId,
      accepted: accepted,
    );
    _syncCellularConfirmation(force: true);
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

  static String _contentTypeFor(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'm4v' => 'video/x-m4v',
      'webm' => 'video/webm',
      _ => 'application/octet-stream',
    };
  }

  String _sessionFailureError() {
    final apiError = _sessionManager.lastError;
    if (apiError != null) return UploadFailure.fromApiError(apiError).encoded;
    return switch (_sessionManager.lastFailure) {
      UploadSessionFailureReason.ownerChanged => const UploadFailure(
        UploadFailureKind.accountChanged,
      ).encoded,
      UploadSessionFailureReason.expiredWithResources =>
        UploadCoordinator.uploadSessionExpiredError,
      UploadSessionFailureReason.requestFailed ||
      UploadSessionFailureReason.unavailable ||
      UploadSessionFailureReason.none => const UploadFailure(
        UploadFailureKind.sessionUnavailable,
      ).encoded,
    };
  }

  bool _isCurrentOperation(int generation, String ownerUserId) =>
      ref.mounted &&
      generation == _operationGeneration &&
      ref.read(currentUserIdProvider) == ownerUserId;

  Future<void> _discardAdoptedItems(List<VideoUploadItem> items) async {
    for (final item in items) {
      await _coordinator.discardManagedFile(item.path);
    }
  }

  Future<void> _removeManagedItem(VideoUploadItem item) async {
    await _coordinator.remove(item.id);
    await _coordinator.discardManagedFile(item.path);
    if (item.thumbnailPath case final path?) {
      await _deleteOwnedThumbnail(path);
    }
  }

  Future<void> _deleteOwnedThumbnail(String path) async {
    final managedSegment =
        '${Platform.pathSeparator}managed_uploads${Platform.pathSeparator}';
    final documents = await getApplicationDocumentsDirectory();
    final legacyPrefix = '${documents.path}/video_thumb_';
    if (!path.contains(managedSegment) && !path.startsWith(legacyPrefix)) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (error, stackTrace) {
      StoryLogger.w(
        '清理视频缩略图失败',
        tag: 'VideoUpload',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
