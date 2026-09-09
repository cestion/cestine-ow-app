import 'dart:async';

import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../data/repository/draft_repository.dart';
import '../l10n/app_localizations.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/actor_repository.dart';
import '../repositories/drama_repository.dart';
import '../repositories/file_upload_repository.dart';
import '../repositories/tag_repository.dart';
import '../repositories/user_repository.dart';
import '../services/image_picker_service.dart';
import 'create_drama_state.dart';
import 'draft_autosave_coordinator.dart';
import 'draft_save_status.dart';
import 'story_controller_mixin.dart';
import 'user_profile_dramas_state.dart';
import 'video_upload_state.dart';

class CreateDramaController extends Notifier<CreateDramaState>
    with StoryControllerMixin<CreateDramaState> {
  late final FileUploadRepository _uploader;
  late final TagRepository _tagRepo;
  late final DramaRepository _dramaRepo;
  late final ActorRepository _actorRepo;
  late final DraftRepository _draftRepo;
  late DraftAutosaveCoordinator<CreateDramaDraft> _draftAutosave;
  late String _draftOwnerId;
  bool _draftStarted = false;
  bool _restoringDraft = false;

  @override
  CreateDramaState build() {
    _uploader = ref.read(fileUploadRepositoryProvider);
    _tagRepo = ref.read(tagRepositoryProvider);
    _dramaRepo = ref.read(dramaRepositoryProvider);
    _actorRepo = ref.read(actorRepositoryProvider);
    _draftRepo = ref.read(draftRepositoryProvider);
    final authUserId = ref.read(authControllerProvider).userId?.trim();
    final storedUserId = ref.read(localRepositoryProvider).getUser()?.userId;
    _draftOwnerId = authUserId?.isNotEmpty == true
        ? authUserId!
        : (storedUserId?.trim() ?? '');
    _draftAutosave = _createDraftAutosave(_draftOwnerId);
    ref.onDispose(() => _draftAutosave.dispose());
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;
      _draftAutosave.dispose();
      _draftOwnerId = next?.trim() ?? '';
      _draftAutosave = _createDraftAutosave(_draftOwnerId);
      _draftStarted = false;
      _restoringDraft = false;
      state = const CreateDramaState(isTagsLoading: true);
      Future.microtask(loadTags);
    });
    ref.listen<VideoUploadState>(videoUploadControllerProvider, (
      previous,
      next,
    ) {
      if (_restoringDraft || state.isEditMode) return;
      if (_videoDraftSignature(previous) == _videoDraftSignature(next)) return;
      final uploadedNow = next.videos.any(
        (video) =>
            _isPersistableVideo(video) &&
            !(previous?.videos.any(
                  (old) =>
                      old.id == video.id &&
                      _isPersistableVideo(old) &&
                      old.videoObjectKey == video.videoObjectKey,
                ) ??
                false),
      );
      _markDraftDirty(immediate: uploadedNow);
    });
    // 退出页面后 controller autoDispose，重新进入会重新拉取标签。
    // 必须延迟到 build() 返回之后执行，否则在 build 期间读写 state 会触发
    // "uninitialized provider"（Riverpod Notifier 在 build 返回前 state 不可用）。
    Future.microtask(loadTags);
    return const CreateDramaState(isTagsLoading: true);
  }

  /// 当前新建内容是否值得保存为草稿。
  bool get hasDraftableContent =>
      !state.isEditMode && _hasDraftableContent(state);

  bool get hasDraftOrContent =>
      !state.isEditMode && (_draftStarted || _hasDraftableContent(state));

  /// 保存当前新建内容为草稿。空白新建页不会创建无意义草稿。
  Future<bool> saveDraftForExit() async {
    if (!ref.mounted || state.isEditMode || _draftOwnerId.isEmpty) return true;
    if (!_draftStarted && !_hasDraftableContent(state)) return true;
    _markDraftDirty();
    return _draftAutosave.flush();
  }

  /// 放弃当前新建内容，并清除此前可能已恢复的草稿。
  Future<bool> discardDraftForExit() async {
    if (!ref.mounted || state.isEditMode || _draftOwnerId.isEmpty) return true;
    final deleted = await _draftAutosave.discard(
      () => _draftRepo.deleteCreateDramaDraft(_draftOwnerId),
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
      ref.read(videoUploadControllerProvider.notifier).reset();
    } else {
      _draftAutosave.resumeAfterDiscardFailure();
    }
    return deleted;
  }

  Future<bool> flushDraftForLifecycle() => _draftAutosave.flush();

  Future<void> loadTags() async {
    state = state.copyWith(isTagsLoading: true, clearTagsError: true);
    final result = await _tagRepo.listTags();
    if (!ref.mounted) return;
    result.when(
      success: (tags) {
        state = state.copyWith(
          availableTags: tags,
          isTagsLoading: false,
          clearTagsError: true,
        );
      },
      failure: (error) {
        state = state.copyWith(isTagsLoading: false, tagsError: error);
      },
    );
  }

  /// 尝试从本地草稿恢复新建短剧的内容（仅新建模式调用）。
  ///
  /// 若当前已处于编辑模式、或 state 已被修改（如已恢复过），则跳过。
  /// 标签需先加载完成以便按 id 匹配 `selectedTags`；若标签尚未就绪则等待。
  Future<void> tryRestoreDraft() async {
    if (state.isEditMode) return;
    if (state.draftRestored) return;
    if (_draftOwnerId.isEmpty) return;
    final draft = await _draftRepo.getCreateDramaDraft(_draftOwnerId);
    if (draft == null || (!draft.hasContent && draft.savedAt <= 0)) return;
    if (state.availableTags.isEmpty) {
      await loadTags();
      if (!ref.mounted) return;
      if (state.isEditMode) return;
    }
    if (!ref.mounted) return;
    if (_hasDraftableContent(state)) return;
    _draftStarted = true;
    final selectedTags = _matchTagsByIds(
      state.availableTags,
      draft.selectedTagIds,
    );
    final roles = <DramaRoleDraft>[
      for (final r in draft.roles)
        if ((r.boundActorCollectionId ?? '').trim().isNotEmpty)
          DramaRoleDraft(
            id: _newRoleId(),
            name: r.name,
            bio: r.bio,
            avatarUrl: r.avatarUrl,
            sortNo: r.sortNo,
            boundActorCollectionId: r.boundActorCollectionId,
            boundActorName: r.boundActorName,
            boundActorAvatarUrl: r.boundActorAvatarUrl,
          ),
    ];
    _restoringDraft = true;
    state = state.copyWith(
      // 始终从第一步（基本信息）开始展示，不恢复到草稿保存时的步骤。
      currentStep: 0,
      title: draft.title,
      synopsis: draft.synopsis,
      coverUrl: draft.coverUrl,
      coverObjectKey: draft.coverObjectKey,
      selectedTags: selectedTags,
      roles: roles,
      draftRestored: true,
      draftSaveStatus: DraftSaveStatus.saved,
    );
    ref
        .read(videoUploadControllerProvider.notifier)
        .restoreDraftVideos(
          sessionId: draft.uploadSessionId,
          sessionExpiresAt: draft.uploadSessionExpiresAt,
          hasExternalResources:
              draft.coverObjectKey?.trim().isNotEmpty == true ||
              draft.roles.any(
                (role) => role.avatarObjectKey?.trim().isNotEmpty == true,
              ),
          videos: draft.videos,
        );
    _restoringDraft = false;
  }

  void toggleTag(DramaTag tag) {
    final selected = state.selectedTags;
    final next = state.tagIsSelected(tag)
        ? selected.where((t) => t != tag).toList(growable: false)
        : [...selected, tag];
    state = state.copyWith(selectedTags: next);
    _markDraftDirty();
  }

  @override
  CreateDramaState copyWithLoadingState({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return state.copyWith(
      isLoading: isLoading,
      lastError: lastError,
      clearLastError: clearLastError,
    );
  }

  int get currentStep => state.currentStep;
  int get totalSteps => CreateDramaState.totalSteps;
  bool get isLastStep => currentStep == totalSteps - 1;

  void nextStep() {
    if (currentStep < totalSteps - 1) {
      state = state.copyWith(currentStep: currentStep + 1);
    }
  }

  void prevStep() {
    if (currentStep > 0) {
      state = state.copyWith(currentStep: currentStep - 1);
    }
  }

  Future<void> pickAndUploadCover({
    required String toolbarTitle,
    required AppLocalizations l10n,
    required BuildContext context,
  }) async {
    if (state.isUploadingCover) return;
    final picked = await ImagePickerService.pickAndCropImage(
      context: context,
      toolbarTitle: toolbarTitle,
      preserveOriginalQuality: true,
    );
    if (picked == null || !ref.mounted) return;
    state = state.copyWith(
      isUploadingCover: true,
      coverUploadProgress: 0,
      localCoverPath: picked.path,
      clearLastError: true,
    );
    // 封面必须与视频/角色头像共用同一上传会话，否则提交时后端会校验
    // 「对象键不属于当前上传会话」。会话由 VideoUploadController 统一持有。
    final sessionId = await ref
        .read(videoUploadControllerProvider.notifier)
        .ensureUploadSession();
    if (sessionId == null) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isUploadingCover: false,
        lastError: ApiError.unknown(l10n.createDramaUploadSessionFailed),
      );
      return;
    }
    final result = await _uploader.uploadFileWithObjectKey(
      filePath: picked.path,
      fileCategory: FileCategory.cover,
      uploadSessionId: sessionId,
      onProgress: (progress) {
        if (ref.mounted) {
          state = state.copyWith(coverUploadProgress: progress);
        }
      },
    );
    if (!ref.mounted) return;
    result.when(
      success: (file) {
        ref
            .read(videoUploadControllerProvider.notifier)
            .markSessionResourceUploaded(sessionId);
        state = state.copyWith(
          isUploadingCover: false,
          coverUrl: file.publicUrl,
          coverObjectKey: file.objectKey,
        );
        _markDraftDirty(immediate: true);
      },
      failure: (error) {
        state = state.copyWith(isUploadingCover: false, lastError: error);
      },
    );
  }

  void setTitle(String value) {
    if (value == state.title) return;
    state = state.copyWith(title: value);
    _markDraftDirty();
  }

  void setSynopsis(String value) {
    if (value == state.synopsis) return;
    state = state.copyWith(synopsis: value);
    _markDraftDirty();
  }

  /// 进入编辑模式：先确保标签列表已加载，再拉取 edit-session 并回显到 state。
  ///
  /// edit-session 接口返回 `uploadSessionId`、`episodes`（含 videoUrl/hlsOutputKey）、
  /// `actorCollections` 等，用于全量回显。视频列表通过 [VideoUploadController]
  /// 的 `initWithEditSession` 以 success 状态回显，后续新上传复用同一会话。
  Future<void> loadForEdit(String dramaId) async {
    state = state.copyWith(
      editingDramaId: dramaId,
      isEditMode: true,
      isEditLoading: true,
      clearLastError: true,
      clearEditLoadError: true,
    );
    // 标签可能还在加载中（build 里 microtask 触发），这里再 await 一次，
    // 复用同一请求结果，确保后续匹配 selectedTags 时 availableTags 已就绪。
    if (state.availableTags.isEmpty) {
      await loadTags();
      if (!ref.mounted) return;
    }
    final result = await _dramaRepo.getEditSession(dramaId);
    if (!ref.mounted) return;
    result.when(
      success: (session) {
        // 同步视频上传 controller：回显已有剧集 + 复用 uploadSessionId。
        ref
            .read(videoUploadControllerProvider.notifier)
            .initWithEditSession(session);

        final selectedTags = _matchTagsByIds(
          state.availableTags,
          session.tagIds,
        );
        final roles = <DramaRoleDraft>[
          for (var i = 0; i < (session.actorCollections?.length ?? 0); i++)
            if ((session.actorCollections![i].actorCollectionId ?? '')
                .trim()
                .isNotEmpty)
              DramaRoleDraft(
                id: _newRoleId(),
                name:
                    session.actorCollections![i].name ??
                    session.actorCollections![i].actorCollectionId ??
                    '',
                avatarUrl: session.actorCollections![i].avatarUrl,
                sortNo: i,
                boundActorCollectionId:
                    session.actorCollections![i].actorCollectionId,
                boundActorName: session.actorCollections![i].name,
                boundActorAvatarUrl: session.actorCollections![i].avatarUrl,
                // edit-session 已回显的绑定不可解除或更换。
                actorBindingPersisted: true,
              ),
        ];
        state = state.copyWith(
          originalSession: session,
          title: session.title ?? '',
          synopsis: session.description ?? '',
          coverUrl: session.coverUrl,
          clearCoverObjectKey: true,
          clearLocalCoverPath: true,
          selectedTags: selectedTags,
          roles: roles,
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

  /// 重试编辑模式详情加载（页面错误态「重试」按钮调用）。
  Future<void> retryEditLoad() async {
    final id = state.editingDramaId;
    if (id == null || id.isEmpty) return;
    await loadForEdit(id);
  }

  /// 把后端返回的 tagIds 列表匹配到本地 [DramaTag]。
  List<DramaTag> _matchTagsByIds(List<DramaTag> available, List<String>? ids) {
    if (ids == null || ids.isEmpty) return const [];
    final idSet = ids.toSet();
    return available
        .where((t) => t.id != null && idSet.contains(t.id))
        .toList(growable: false);
  }

  /// 当前 state 是否有值得保存为草稿的实质内容。
  bool _hasDraftableContent(CreateDramaState s) {
    if (s.title.trim().isNotEmpty || s.synopsis.trim().isNotEmpty) return true;
    if (s.selectedTags.isNotEmpty) return true;
    if (s.coverUrl != null || s.coverObjectKey != null) return true;
    if (s.roles.isNotEmpty) return true;
    final vState = ref.read(videoUploadControllerProvider);
    if (vState.videos.any(_isPersistableVideo)) return true;
    return false;
  }

  /// 把当前 state + 视频上传 state 序列化为草稿（仅 success 视频纳入）。
  CreateDramaDraft _toDraft(CreateDramaState s) {
    final vState = ref.read(videoUploadControllerProvider);
    final videos = <DraftVideoItem>[
      for (final v in vState.videos.where(_isPersistableVideo))
        DraftVideoItem(
          taskId: v.id,
          localFilePath: v.path.isEmpty ? null : v.path,
          uploadStatus: v.status.name,
          name: v.name,
          description: v.description,
          durationMs: v.durationMs,
          sizeBytes: v.sizeBytes,
          width: v.width,
          height: v.height,
          url: v.url,
          videoObjectKey: v.videoObjectKey,
          thumbnailPath: v.thumbnailPath,
          isReplacement: v.isReplacement,
        ),
    ];
    final roles = <DraftRoleItem>[
      for (final r in s.roles)
        if (r.isActorBound)
          DraftRoleItem(
            name: r.name,
            bio: r.bio,
            avatarUrl: r.avatarUrl,
            sortNo: r.sortNo,
            boundActorCollectionId: r.boundActorCollectionId,
            boundActorName: r.boundActorName,
            boundActorAvatarUrl: r.boundActorAvatarUrl,
          ),
    ];
    return CreateDramaDraft(
      currentStep: s.currentStep,
      title: s.title,
      synopsis: s.synopsis,
      selectedTagIds: s.selectedTags
          .map((t) => t.id)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList(growable: false),
      coverUrl: s.coverUrl,
      coverObjectKey: s.coverObjectKey,
      uploadSessionId: vState.uploadSessionId,
      uploadSessionExpiresAt: vState.uploadSessionExpiresAt,
      videos: videos,
      roles: roles,
      savedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _markDraftDirty({bool immediate = false}) {
    if (!ref.mounted ||
        state.isEditMode ||
        _restoringDraft ||
        _draftOwnerId.isEmpty) {
      return;
    }
    if (!_draftStarted && !_hasDraftableContent(state)) return;
    _draftStarted = true;
    state = state.copyWith(draftSaveStatus: DraftSaveStatus.dirty);
    _draftAutosave.markDirty(_toDraft(state), immediate: immediate);
  }

  DraftAutosaveCoordinator<CreateDramaDraft> _createDraftAutosave(
    String ownerId,
  ) {
    return DraftAutosaveCoordinator<CreateDramaDraft>(
      save: (draft) => _writeDraft(ownerId, draft),
      onError: (error, stackTrace) {
        _handleDraftSaveError(ownerId, error, stackTrace);
      },
    );
  }

  Future<void> _writeDraft(String ownerId, CreateDramaDraft draft) async {
    if (ref.mounted && _draftOwnerId == ownerId) {
      state = state.copyWith(draftSaveStatus: DraftSaveStatus.saving);
    }
    if (ownerId.isNotEmpty) {
      await _draftRepo.saveCreateDramaDraft(ownerId, draft);
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
      'Failed to save create-drama draft',
      error: error,
      stackTrace: stackTrace,
      tag: 'CreateDramaDraft',
    );
    if (ref.mounted && _draftOwnerId == ownerId) {
      state = state.copyWith(draftSaveStatus: DraftSaveStatus.failed);
    }
  }

  static int _videoDraftSignature(VideoUploadState? uploadState) => Object.hash(
    uploadState?.uploadSessionId,
    uploadState?.uploadSessionExpiresAt,
    Object.hashAll([
      for (final video in uploadState?.videos ?? const <VideoUploadItem>[])
        if (_isPersistableVideo(video))
          Object.hashAll([
            video.id,
            video.path,
            video.status,
            video.name,
            video.description,
            video.durationMs,
            video.sizeBytes,
            video.width,
            video.height,
            video.url,
            video.videoObjectKey,
            video.thumbnailPath,
          ]),
    ]),
  );

  static bool _isPersistableVideo(VideoUploadItem video) =>
      (video.isSuccess && video.videoObjectKey?.trim().isNotEmpty == true) ||
      (!video.preexisting && video.path.trim().isNotEmpty);

  /// 上传角色头像，返回包含 `objectKey` 的 [UploadedFile]。
  ///
  /// 调用方（角色表单）自行管理选图、进度与本地预览态；上传成功后再通过
  /// [addRole] / [updateRole] 将 `avatarObjectKey` 与 `localAvatarPath` 持久化到 state。
  ///
  /// 头像必须与封面/视频共用同一上传会话，否则提交时后端会校验
  /// 「对象键不属于当前上传会话」。
  Future<Result<UploadedFile>> uploadRoleAvatar({
    required String filePath,
    required AppLocalizations l10n,
    void Function(double progress)? onProgress,
  }) async {
    final sessionId = await ref
        .read(videoUploadControllerProvider.notifier)
        .ensureUploadSession();
    if (sessionId == null) {
      return Result.failure(
        ApiError.unknown(l10n.createDramaUploadSessionFailed),
      );
    }
    final result = await _uploader.uploadFileWithObjectKey(
      filePath: filePath,
      fileCategory: FileCategory.avatar,
      uploadSessionId: sessionId,
      onProgress: onProgress,
    );
    if (result.isSuccess && ref.mounted) {
      ref
          .read(videoUploadControllerProvider.notifier)
          .markSessionResourceUploaded(sessionId);
    }
    return result;
  }

  /// 生成一个新的本地角色 id。
  String _newRoleId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(this)}';

  /// 新增角色。`sortNo` 自动取当前列表长度，`id` 由 controller 分配。
  void addRole(DramaRoleDraft role) {
    final next = DramaRoleDraft(
      id: _newRoleId(),
      name: role.name,
      bio: role.bio,
      avatarObjectKey: role.avatarObjectKey,
      localAvatarPath: role.localAvatarPath,
      avatarUrl: role.avatarUrl,
      sortNo: state.roles.length,
    );
    state = state.copyWith(roles: [...state.roles, next]);
    _markDraftDirty();
  }

  /// 更新已存在的角色（按 `id` 替换），保留原 `sortNo`。
  void updateRole(DramaRoleDraft role) {
    final roles = state.roles;
    final idx = roles.indexWhere((r) => r.id == role.id);
    if (idx < 0) return;
    final next = List<DramaRoleDraft>.from(roles);
    next[idx] = role.copyWith(sortNo: roles[idx].sortNo);
    state = state.copyWith(roles: next);
    _markDraftDirty();
  }

  /// 删除角色并重排剩余 `sortNo`。
  void deleteRole(String id) {
    final targetIndex = state.roles.indexWhere((role) => role.id == id);
    final target = targetIndex < 0 ? null : state.roles[targetIndex];
    // 与 Web v0828 一致：edit-session 已存在的绑定不可解除或更换。
    if (target?.actorBindingPersisted == true) return;
    final kept = state.roles.where((r) => r.id != id).toList(growable: false);
    final reindexed = [
      for (var i = 0; i < kept.length; i++) kept[i].copyWith(sortNo: i),
    ];
    state = state.copyWith(roles: reindexed);
    _markDraftDirty();
  }

  /// 拉取当前用户持有的演员 IP（ActorCollection）列表，供绑定选择器使用。
  Future<Result<List<ActorCollection>>> loadOwnedActorCollections() =>
      _actorRepo.listOwnedActorCollections();

  /// 将选择器返回的演员 IP 批量添加为短剧角色绑定。
  ///
  /// 同一 IP 不会重复添加，且绑定总数最多 5 个。这里同时完成
  /// [ActorCollection] → [DramaRoleDraft] 的转换，让弹窗保持纯选择职责，
  /// 其它入口复用弹窗时无需了解创建短剧的本地状态结构。
  void addBoundActorCollections(Iterable<ActorCollection> collections) {
    const maxBindings = 5;
    final existingIds = state.roles
        .map((role) => role.boundActorCollectionId?.trim())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    var remaining = maxBindings - existingIds.length;
    if (remaining <= 0) return;

    // 兼容旧草稿：第三步只保留真正绑定了 IP 的项目。
    final next = state.roles
        .where((role) => role.isActorBound)
        .toList(growable: true);
    for (final actor in collections) {
      if (remaining <= 0) break;
      final actorId = actor.id?.trim();
      if (actorId == null || actorId.isEmpty || !existingIds.add(actorId)) {
        continue;
      }
      final actorName = actor.name?.trim();
      next.add(
        DramaRoleDraft(
          id: _newRoleId(),
          name: actorName == null || actorName.isEmpty ? actorId : actorName,
          bio: actor.bio?.trim() ?? '',
          avatarUrl: actor.avatarUrl,
          sortNo: next.length,
          boundActorCollectionId: actorId,
          boundActorName: actorName,
          boundActorAvatarUrl: actor.avatarUrl,
        ),
      );
      remaining--;
    }
    if (next.length != state.roles.length) {
      state = state.copyWith(roles: next);
      _markDraftDirty();
    }
  }

  /// 提交创建短剧。调用方（页面）应先完成本地校验。
  ///
  /// 成功后重置自身与视频上传 controller 到初始态，返回成功的 [Result]；
  /// 失败时 `lastError` 已由 [withLoadingResult] 写入 state，返回失败 [Result]。
  Future<Result<CreatorDrama>> submit() async {
    final isEdit = state.isEditMode && state.editingDramaId != null;

    final Result<CreatorDrama> result;
    if (isEdit) {
      result = await _submitEdit();
    } else {
      result = await _submitCreate();
    }

    if (result.isFailure) return result;
    final created = result.dataOrNull!;

    if (!state.isEditMode && _draftOwnerId.isNotEmpty) {
      final deleted = await _draftAutosave.discard(
        () => _draftRepo.deleteCreateDramaDraft(_draftOwnerId),
      );
      if (!deleted) {
        StoryLogger.w(
          'Published create-drama draft could not be deleted',
          tag: 'CreateDramaDraft',
        );
      }
      _draftStarted = false;
    }
    _revalidateLoadedPublishedDramas();
    reset();
    ref.read(videoUploadControllerProvider.notifier).reset();
    return Result.success(created);
  }

  void _revalidateLoadedPublishedDramas() {
    final provider = userProfileDramasProvider(
      const UserProfileDramaParam(type: ProfileDramaType.published),
    );
    if (!ref.exists(provider)) return;
    unawaited(ref.read(provider.notifier).silentRevalidateAfterMutation());
  }

  // ─── Create flow (full payload) ──────────────────────────────────────

  Future<Result<CreatorDrama>> _submitCreate() async {
    final vState = ref.read(videoUploadControllerProvider);
    final successVideos = vState.videos
        .where((v) => v.isSuccess)
        .toList(growable: false);

    final episodes = <CreateEpisodeRequest>[
      for (var i = 0; i < successVideos.length; i++)
        CreateEpisodeRequest(
          durationSec: (successVideos[i].durationMs / 1000).round(),
          description: successVideos[i].description.trim(),
          episodeNo: i + 1,
          title: _stripExtension(successVideos[i].name),
          videoObjectKey: successVideos[i].videoObjectKey ?? '',
          width: successVideos[i].width,
          height: successVideos[i].height,
        ),
    ];
    for (final ep in episodes) {
      StoryLogger.i(
        '发布短剧剧集: episodeNo=${ep.episodeNo} title=${ep.title} '
        'width=${ep.width} height=${ep.height} durationSec=${ep.durationSec}',
        tag: 'CreateDrama',
      );
    }
    final actorCollectionIds = _uniqueBoundActorCollectionIds(state.roles);
    final tagIds = state.selectedTags
        .map((t) => t.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final request = CreateDramaRequest(
      coverObjectKey: state.coverObjectKey ?? '',
      description: state.synopsis,
      episodes: episodes,
      actorCollectionIds: actorCollectionIds.isEmpty
          ? null
          : actorCollectionIds,
      tagIds: tagIds,
      title: state.title.trim(),
      uploadSessionId: vState.uploadSessionId ?? '',
    );

    final created = await withLoadingResult(
      () => _dramaRepo.createDrama(request),
      operation: 'CreateDrama.submit',
    );
    if (created == null) {
      return Result.failure(
        state.lastError ?? ApiError.unknown('submit failed'),
      );
    }
    return Result.success(created);
  }

  // ─── Edit flow (delta payload — only changed fields) ─────────────────

  Future<Result<CreatorDrama>> _submitEdit() async {
    final original = state.originalSession;
    final dramaId = state.editingDramaId!;
    final vState = ref.read(videoUploadControllerProvider);

    // ── Title ──────────────────────────────────────────────────────────
    final trimmedTitle = state.title.trim();
    final originalTitle = original?.title?.trim() ?? '';
    final hasTitleChanged = trimmedTitle != originalTitle;

    // ── Description ────────────────────────────────────────────────────
    final trimmedDesc = state.synopsis.trim();
    final originalDesc = original?.description?.trim() ?? '';
    final hasDescChanged = trimmedDesc != originalDesc;

    // ── Cover ──────────────────────────────────────────────────────────
    // coverObjectKey != null means user uploaded a new cover.
    final hasCoverChanged = state.coverObjectKey != null;

    // ── Tags ───────────────────────────────────────────────────────────
    final currentTagIds = state.selectedTags
        .map((t) => t.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    final originalTagIds = original?.tagIds ?? const <String>[];
    final hasTagsChanged = !_listEq(currentTagIds, originalTagIds);
    // ── Episodes ──────────────────────────────────────────────────────
    // 已有剧集的描述发生变化时，只提交 id + description；
    // 新上传视频的提交逻辑保持不变。
    final allSuccessVideos = vState.videos
        .where((v) => v.isSuccess)
        .toList(growable: false);
    final originalDescriptions = <String, String>{
      for (final episode in original?.episodes ?? const <EditSessionEpisode>[])
        if (episode.id != null) episode.id!: episode.description?.trim() ?? '',
    };

    final List<DramaEditEpisodeItem> episodesPayload = [];
    for (int i = 0; i < allSuccessVideos.length; i++) {
      final video = allSuccessVideos[i];
      if (video.preexisting) {
        final currentDescription = video.description.trim();
        if (currentDescription == (originalDescriptions[video.id] ?? '')) {
          continue;
        }
        episodesPayload.add(
          DramaEditEpisodeItem(id: video.id, description: currentDescription),
        );
        continue;
      }

      if (video.videoObjectKey == null) continue;
      final width = video.width > 0 ? video.width : null;
      final height = video.height > 0 ? video.height : null;
      final item = video.isHistoricalUpload
          ? DramaEditEpisodeItem(
              id: video.id,
              title: _stripExtension(video.name),
              description: video.description.trim(),
              videoObjectKey: video.videoObjectKey,
              durationSec: (video.durationMs / 1000).round(),
              width: width,
              height: height,
            )
          : DramaEditEpisodeItem(
              episodeNo: i + 1,
              title: _stripExtension(video.name),
              description: video.description.trim(),
              videoObjectKey: video.videoObjectKey,
              durationSec: (video.durationMs / 1000).round(),
              width: width,
              height: height,
            );
      episodesPayload.add(item);
      StoryLogger.i(
        '编辑短剧剧集: id=${item.id} episodeNo=${item.episodeNo} '
        'title=${item.title} width=${item.width} height=${item.height} '
        'durationSec=${item.durationSec}',
        tag: 'CreateDrama',
      );
    }
    final bool hasEpisodesChanged = episodesPayload.isNotEmpty;

    // ── Actor collection bindings (add / delete) ────────────────────────
    final currentActorIds = _uniqueBoundActorCollectionIds(state.roles);
    final originalActorIds = _uniqueEditSessionActorCollectionIds(
      original?.actorCollections,
    );
    final currentActorIdSet = currentActorIds.toSet();
    final originalActorIdSet = originalActorIds.toSet();
    final addedActorIds = currentActorIds
        .where((id) => !originalActorIdSet.contains(id))
        .toList(growable: false);
    final deletedActorIds = originalActorIds
        .where((id) => !currentActorIdSet.contains(id))
        .toList(growable: false);
    final hasActorCollectionChanges =
        addedActorIds.isNotEmpty || deletedActorIds.isNotEmpty;
    final actorCollectionChanges = hasActorCollectionChanges
        ? ActorCollectionChanges(
            add: addedActorIds.isEmpty ? null : addedActorIds,
            delete: deletedActorIds.isEmpty ? null : deletedActorIds,
          )
        : null;

    // ── uploadSessionId ────────────────────────────────────────────────
    // 只有媒体资源变化才需要上传会话；IP 绑定不再上传角色头像。
    final hasResourceChanged =
        hasCoverChanged ||
        allSuccessVideos.any(
          (video) => !video.preexisting && video.videoObjectKey != null,
        );
    final uploadSessionId = hasResourceChanged ? vState.uploadSessionId : null;

    // ── Build request ──────────────────────────────────────────────────
    final editRequest = DramaEditRequest(
      uploadSessionId: uploadSessionId,
      title: hasTitleChanged ? trimmedTitle : null,
      description: hasDescChanged ? trimmedDesc : null,
      coverObjectKey: hasCoverChanged ? state.coverObjectKey : null,
      episodes: hasEpisodesChanged ? episodesPayload : null,
      actorCollectionChanges: actorCollectionChanges,
      tagIds: hasTagsChanged ? currentTagIds : null,
    );

    final created = await withLoadingResult(
      () => _dramaRepo.updateDramaEditRevision(dramaId, editRequest),
      operation: 'CreateDrama.submitEdit',
    );
    if (created == null) {
      return Result.failure(
        state.lastError ?? ApiError.unknown('edit submit failed'),
      );
    }

    // 提交成功后拉取最新详情，确保返回的 CreatorDrama 包含更新后的字段。
    final detail = await _dramaRepo.getCreatorDrama(dramaId);
    if (!ref.mounted) return Result.success(created);
    return Result.success(detail.isSuccess ? detail.dataOrNull! : created);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  /// Reset to initial create state.
  void reset() {
    state = const CreateDramaState(isTagsLoading: true);
    Future.microtask(loadTags);
  }

  static String _stripExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  static List<String> _uniqueBoundActorCollectionIds(
    Iterable<DramaRoleDraft> roles,
  ) {
    final ids = <String>[];
    final seen = <String>{};
    for (final role in roles) {
      final id = role.boundActorCollectionId?.trim();
      if (id == null || id.isEmpty || !seen.add(id)) continue;
      ids.add(id);
      if (ids.length == 5) break;
    }
    return ids;
  }

  static List<String> _uniqueEditSessionActorCollectionIds(
    Iterable<EditSessionActorCollection>? collections,
  ) {
    final ids = <String>[];
    final seen = <String>{};
    for (final collection
        in collections ?? const <EditSessionActorCollection>[]) {
      final id = collection.actorCollectionId?.trim();
      if (id == null || id.isEmpty || !seen.add(id)) continue;
      ids.add(id);
    }
    return ids;
  }

  static bool _listEq<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    final aset = a.toSet();
    return b.every(aset.contains);
  }
}
