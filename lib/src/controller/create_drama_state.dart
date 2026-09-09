import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';
import 'draft_save_status.dart';

class CreateDramaState extends Equatable {
  static const int totalSteps = 3;

  final int currentStep;
  final String title;
  final String synopsis;
  final List<DramaTag> availableTags;
  final List<DramaTag> selectedTags;
  final bool isTagsLoading;
  final ApiError? tagsError;
  final String? coverUrl;
  final String? coverObjectKey;
  final String? localCoverPath;
  final bool isUploadingCover;
  final double coverUploadProgress;
  final List<DramaRoleDraft> roles;
  final bool isLoading;
  final ApiError? lastError;

  /// 编辑模式：详情加载失败时的错误（独立于 [lastError]，用于页面区分
  /// 「编辑初始化失败」与「后续操作失败」两种态）。仅 [isEditMode] 下有意义。
  final ApiError? editLoadError;

  /// 编辑模式：当前编辑的短剧 id；新建模式为 null。
  final String? editingDramaId;

  /// 是否处于编辑模式。
  final bool isEditMode;

  /// 编辑模式详情加载中。
  final bool isEditLoading;

  /// 草稿恢复标记：从本地草稿回填后置为 true，供页面展示提示后复位。
  final bool draftRestored;

  final DraftSaveStatus draftSaveStatus;

  /// 编辑模式：原始 edit-session 数据，用于提交时增量对比。
  /// 新建模式为 null。
  final DramaEditSession? originalSession;

  const CreateDramaState({
    this.currentStep = 0,
    this.title = '',
    this.synopsis = '',
    this.availableTags = const [],
    this.selectedTags = const [],
    this.isTagsLoading = false,
    this.tagsError,
    this.coverUrl,
    this.coverObjectKey,
    this.localCoverPath,
    this.isUploadingCover = false,
    this.coverUploadProgress = 0,
    this.roles = const [],
    this.isLoading = false,
    this.lastError,
    this.editingDramaId,
    this.isEditMode = false,
    this.isEditLoading = false,
    this.draftRestored = false,
    this.draftSaveStatus = DraftSaveStatus.idle,
    this.originalSession,
    this.editLoadError,
  });

  String get errorMessage => lastError?.userMessage ?? '';

  CreateDramaState copyWith({
    int? currentStep,
    String? title,
    String? synopsis,
    List<DramaTag>? availableTags,
    List<DramaTag>? selectedTags,
    bool? isTagsLoading,
    ApiError? tagsError,
    bool clearTagsError = false,
    String? coverUrl,
    String? coverObjectKey,
    String? localCoverPath,
    bool? isUploadingCover,
    double? coverUploadProgress,
    bool clearCoverUrl = false,
    bool clearCoverObjectKey = false,
    bool clearLocalCoverPath = false,
    List<DramaRoleDraft>? roles,
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    String? editingDramaId,
    bool? isEditMode,
    bool? isEditLoading,
    bool? draftRestored,
    bool clearDraftRestored = false,
    DraftSaveStatus? draftSaveStatus,
    DramaEditSession? originalSession,
    bool clearOriginalSession = false,
    ApiError? editLoadError,
    bool clearEditLoadError = false,
  }) {
    return CreateDramaState(
      currentStep: currentStep ?? this.currentStep,
      title: title ?? this.title,
      synopsis: synopsis ?? this.synopsis,
      availableTags: availableTags ?? this.availableTags,
      selectedTags: selectedTags ?? this.selectedTags,
      isTagsLoading: isTagsLoading ?? this.isTagsLoading,
      tagsError: clearTagsError ? null : (tagsError ?? this.tagsError),
      coverUrl: clearCoverUrl ? null : (coverUrl ?? this.coverUrl),
      coverObjectKey: clearCoverObjectKey
          ? null
          : (coverObjectKey ?? this.coverObjectKey),
      localCoverPath: clearLocalCoverPath
          ? null
          : (localCoverPath ?? this.localCoverPath),
      isUploadingCover: isUploadingCover ?? this.isUploadingCover,
      coverUploadProgress: coverUploadProgress ?? this.coverUploadProgress,
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      editingDramaId: editingDramaId ?? this.editingDramaId,
      isEditMode: isEditMode ?? this.isEditMode,
      isEditLoading: isEditLoading ?? this.isEditLoading,
      draftRestored: clearDraftRestored
          ? false
          : (draftRestored ?? this.draftRestored),
      draftSaveStatus: draftSaveStatus ?? this.draftSaveStatus,
      originalSession: clearOriginalSession
          ? null
          : (originalSession ?? this.originalSession),
      editLoadError: clearEditLoadError
          ? null
          : (editLoadError ?? this.editLoadError),
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    title,
    synopsis,
    availableTags,
    selectedTags,
    isTagsLoading,
    tagsError,
    coverUrl,
    coverObjectKey,
    localCoverPath,
    isUploadingCover,
    coverUploadProgress,
    roles,
    isLoading,
    lastError,
    editingDramaId,
    isEditMode,
    isEditLoading,
    editLoadError,
    draftRestored,
    draftSaveStatus,
    originalSession,
  ];
}

extension CreateDramaStateX on CreateDramaState {
  bool tagIsSelected(DramaTag tag) {
    final key = tag.id ?? tag.code ?? tag.name ?? '';
    return selectedTags.any((t) => (t.id ?? t.code ?? t.name ?? '') == key);
  }

  bool get isStep1Complete =>
      title.trim().isNotEmpty &&
      synopsis.trim().isNotEmpty &&
      (coverObjectKey != null || coverUrl != null) &&
      selectedTags.isNotEmpty;
}
