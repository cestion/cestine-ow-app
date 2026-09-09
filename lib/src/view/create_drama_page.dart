import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/common/story_toast.dart';
import '../components/creator/drama_video_upload_item.dart';
import '../components/common/primary_action_button.dart';
import '../controller/create_drama_state.dart';
import '../controller/video_upload_controller.dart';
import '../controller/video_upload_state.dart';
import '../core/result.dart';
import '../core/video_url_helpers.dart';
import '../l10n/story_l10n.dart';
import '../l10n/upload_failure_l10n.dart';
import '../provider/app_providers.dart';
import '../routes/actor_detail_navigation.dart';
import '../styles/story_colors.dart';
import '../styles/story_format.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../widgets/widgets.dart';
import 'widgets/create_drama/bind_ip_step.dart';
import 'widgets/create_drama/bind_ip_selection_sheet.dart';
import 'widgets/create_drama/draft_exit_menu.dart';
import 'widgets/create_drama/secondary_action_button.dart';
import 'widgets/create_drama/video_preview_page.dart';

const _kSectionLabel = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  height: 1.5,
  letterSpacing: 0,
);

/// 标签最多可选数量。
const int _kMaxTags = 5;

/// 已上传视频数达到上限后，按钮 disabled；本文件常量仅用于步骤 2 按钮状态，
/// 实际拦截 / 截断逻辑见 [VideoUploadController.pickVideos]。
const int _kMaxEpisodes = kMaxEpisodesPerDrama;

/// Create Drama wizard page.
///
/// [dramaId] 非空时进入编辑模式，自动加载并回显该短剧的数据。
class CreateDramaPage extends ConsumerStatefulWidget {
  final String? dramaId;

  const CreateDramaPage({super.key, this.dramaId});

  @override
  ConsumerState<CreateDramaPage> createState() => _CreateDramaPageState();
}

class _CreateDramaPageState extends ConsumerState<CreateDramaPage>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final _titleCtrl = TextEditingController();
  final _synopsisCtrl = TextEditingController();
  bool _step1Submitted = false;
  bool _step2Submitted = false;
  bool _editPrefilled = false;
  bool _draftPrefilled = false;
  bool _draftToastShown = false;
  final LayerLink _backMenuLink = LayerLink();
  OverlayEntry? _exitMenuEntry;
  bool _isExitActionPending = false;
  bool _canPop = false;
  bool _cellularDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleCtrl.addListener(_syncTitle);
    _synopsisCtrl.addListener(_syncSynopsis);
    final dramaId = widget.dramaId;
    if (dramaId != null && dramaId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(createDramaControllerProvider.notifier).loadForEdit(dramaId);
      });
    } else {
      // 新建模式：尝试从本地草稿恢复（标签加载完成后回填）。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(createDramaControllerProvider.notifier).tryRestoreDraft();
      });
    }
  }

  void _syncTitle() {
    ref.read(createDramaControllerProvider.notifier).setTitle(_titleCtrl.text);
    if (_step1Submitted) setState(() {});
  }

  void _syncSynopsis() {
    ref
        .read(createDramaControllerProvider.notifier)
        .setSynopsis(_synopsisCtrl.text);
    if (_step1Submitted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _exitMenuEntry?.remove();
    _exitMenuEntry = null;
    _titleCtrl.dispose();
    _synopsisCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(
        ref
            .read(createDramaControllerProvider.notifier)
            .flushDraftForLifecycle(),
      );
    }
  }

  Future<void> _requestExit() async {
    if (_isExitActionPending) return;
    if (_exitMenuEntry != null) {
      _hideExitMenu();
      return;
    }

    final controller = ref.read(createDramaControllerProvider.notifier);
    if (ref.read(createDramaControllerProvider).isEditMode) {
      ref.read(videoUploadControllerProvider.notifier).reset();
      _completePop();
      return;
    }
    if (!controller.hasDraftOrContent) {
      _completePop();
      return;
    }
    _showExitMenu();
  }

  void _showExitMenu() {
    if (_exitMenuEntry != null || !mounted) return;
    final l10n = context.l10n;
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideExitMenu,
            ),
          ),
          CompositedTransformFollower(
            link: _backMenuLink,
            targetAnchor: Alignment.bottomCenter,
            offset: const Offset(-21.5, -4),
            child: DraftExitMenu(
              discardLabel: l10n.createDramaDraftDiscard,
              saveLabel: l10n.createDramaDraftSave,
              onDiscard: _discardDraftAndExit,
              onSave: _saveDraftAndExit,
            ),
          ),
        ],
      ),
    );
    _exitMenuEntry = entry;
    overlay.insert(entry);
  }

  void _hideExitMenu() {
    _exitMenuEntry?.remove();
    _exitMenuEntry = null;
  }

  Future<void> _saveDraftAndExit() async {
    if (_isExitActionPending) return;
    _isExitActionPending = true;
    _hideExitMenu();
    final saved = await ref
        .read(createDramaControllerProvider.notifier)
        .saveDraftForExit();
    if (!mounted) return;
    if (!saved) {
      _isExitActionPending = false;
      StoryToast.error(context, context.l10n.errorOperationFailed);
      return;
    }
    _completePop();
  }

  Future<void> _discardDraftAndExit() async {
    if (_isExitActionPending) return;
    _isExitActionPending = true;
    _hideExitMenu();
    final deleted = await ref
        .read(createDramaControllerProvider.notifier)
        .discardDraftForExit();
    if (!mounted) return;
    if (!deleted) {
      _isExitActionPending = false;
      StoryToast.error(context, context.l10n.errorOperationFailed);
      return;
    }
    _completePop();
  }

  void _completePop([Object? result]) {
    _hideExitMenu();
    if (!mounted) return;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  Widget _buildBackButton() {
    return CompositedTransformTarget(
      link: _backMenuLink,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: _requestExit,
      ),
    );
  }

  void _nextStep() {
    final controller = ref.read(createDramaControllerProvider.notifier);
    if (controller.isLastStep) {
      _submit();
      return;
    }
    if (controller.currentStep == 0) {
      final state = ref.read(createDramaControllerProvider);
      if (!state.isStep1Complete) {
        setState(() => _step1Submitted = true);
        return;
      }
      setState(() => _step1Submitted = false);
    }
    if (controller.currentStep == 1) {
      final vState = ref.read(videoUploadControllerProvider);
      final missingDesc = vState.videos.any(
        (v) => v.description.trim().isEmpty,
      );
      if (missingDesc) {
        setState(() => _step2Submitted = true);
        return;
      }
      setState(() => _step2Submitted = false);
    }
    controller.nextStep();
    _pageController.animateToPage(
      controller.currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    final controller = ref.read(createDramaControllerProvider.notifier);
    controller.prevStep();
    _pageController.animateToPage(
      controller.currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final dramaState = ref.read(createDramaControllerProvider);
    final vState = ref.read(videoUploadControllerProvider);
    final hasSuccessVideo = vState.videos.any((v) => v.isSuccess);

    if (dramaState.title.trim().isEmpty) {
      StoryToast.error(context, l10n.createDramaSubmitValidationTitle);
      return;
    }
    if (dramaState.coverObjectKey == null && dramaState.coverUrl == null) {
      StoryToast.error(context, l10n.createDramaSubmitValidationCover);
      return;
    }
    if (!hasSuccessVideo) {
      StoryToast.error(context, l10n.createDramaSubmitValidationVideos);
      return;
    }
    if (vState.uploadSessionId == null) {
      StoryToast.error(context, l10n.createDramaSubmitValidationSession);
      return;
    }
    final result = await ref
        .read(createDramaControllerProvider.notifier)
        .submit();
    if (!mounted) return;
    result.when(
      success: (created) {
        StoryToast.success(context, context.l10n.createDramaPublishedSuccess);
        _completePop(created);
      },
      failure: (error) => StoryToast.error(context, context.l10nError(error)),
    );
  }

  Future<void> _pickAndUploadCover() async {
    final l10n = context.l10n;
    final notifier = ref.read(createDramaControllerProvider.notifier);
    await notifier.pickAndUploadCover(
      context: context,
      toolbarTitle: l10n.createDramaCoverCropTitle,
      l10n: l10n,
    );
    final error = ref.read(createDramaControllerProvider).lastError;
    if (error != null && mounted) {
      StoryToast.error(context, context.l10nError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final state = ref.watch(createDramaControllerProvider);
    final steps = [
      l10n.createDramaBasicInfo,
      l10n.createDramaEpisodes,
      l10n.createDramaRoles,
    ];

    ref.listen<VideoUploadState>(videoUploadControllerProvider, (prev, next) {
      if (prev == null) return;
      _maybeShowCellularDialog(next.cellularConfirmationPending);
      for (final item in next.videos) {
        final old = prev.videos.firstWhere(
          (v) => v.id == item.id,
          orElse: () => item,
        );
        if (old.status != VideoUploadStatus.failed &&
            item.status == VideoUploadStatus.failed) {
          final reason = _videoErrorMessage(item);
          StoryToast.error(
            context,
            reason == null
                ? l10n.createDramaVideoUploadFailed(item.name)
                : '${l10n.createDramaVideoUploadFailed(item.name)}：$reason',
          );
        }
      }
      final wasActive = prev.videos.any(
        (v) =>
            v.isIncomplete,
      );
      final isActive = next.videos.any(
        (v) =>
            v.isIncomplete,
      );
      if (wasActive && !isActive && next.videos.isNotEmpty) {
        final anyFailed = next.videos.any(
          (v) => v.status == VideoUploadStatus.failed,
        );
        if (!anyFailed) {
          StoryToast.success(context, l10n.createDramaVideoUploadComplete);
        }
      }
      // 选择视频超过剩余可加数量时被截断，提示用户。
      final prevOverflow = prev.pickOverflow;
      if (next.pickOverflow > 0 && next.pickOverflow != prevOverflow) {
        final allowedNow = _kMaxEpisodes - prev.videos.length;
        StoryToast.error(
          context,
          l10n.createDramaVideoPickOverflow(allowedNow, next.pickOverflow),
        );
        ref.read(videoUploadControllerProvider.notifier).clearPickOverflow();
      }
    });

    // 编辑模式：详情首次回填后同步到本地 TextEditingController（只做一次）。
    if (!_editPrefilled && state.isEditMode && !state.isEditLoading) {
      _editPrefilled = true;
      if (_titleCtrl.text != state.title) {
        _titleCtrl
          ..removeListener(_syncTitle)
          ..text = state.title
          ..addListener(_syncTitle);
      }
      if (_synopsisCtrl.text != state.synopsis) {
        _synopsisCtrl
          ..removeListener(_syncSynopsis)
          ..text = state.synopsis
          ..addListener(_syncSynopsis);
      }
    }

    // 新建模式：草稿首次回填后同步到本地 TextEditingController 与 PageController，
    // 并展示一次提示 Toast（只做一次）。
    if (!_draftPrefilled && state.draftRestored && !state.isEditMode) {
      _draftPrefilled = true;
      if (_titleCtrl.text != state.title) {
        _titleCtrl
          ..removeListener(_syncTitle)
          ..text = state.title
          ..addListener(_syncTitle);
      }
      if (_synopsisCtrl.text != state.synopsis) {
        _synopsisCtrl
          ..removeListener(_syncSynopsis)
          ..text = state.synopsis
          ..addListener(_syncSynopsis);
      }
      // 草稿恢复后始终从第一步开始，无需跳页（PageView 默认在第 0 页）。
      if (!_draftToastShown) {
        _draftToastShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            StoryToast.success(context, l10n.createDramaDraftRestored);
          }
        });
      }
    }

    return PopScope<Object?>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: AppScaffold(
        backgroundColor: StoryColors.createDramaPageSurfaceOf(theme.brightness),
        title: state.isEditMode
            ? l10n.editDramaTitle
            : l10n.creatorPublishNewDrama,
        leading: _buildBackButton(),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: StorySpacing.screenHorizontal,
                vertical: StorySpacing.md,
              ),
              color: StoryColors.createDramaPageSurfaceOf(theme.brightness),
              child: StoryStepIndicator(
                currentStep: state.currentStep + 1,
                steps: steps,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.isEditLoading
                  ? _buildEditSkeleton(theme)
                  : (state.isEditMode && state.editLoadError != null)
                  ? _buildEditLoadError(theme, state.editLoadError!)
                  : PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1BasicInfo(theme, state),
                        _buildStep2Episodes(theme),
                        _buildStep3BindIp(),
                      ],
                    ),
            ),
            _buildBottomActions(theme, state.currentStep),
          ],
        ),
      ),
    );
  }

  Widget _buildEditLoadError(ThemeData theme, ApiError error) {
    final l10n = context.l10n;
    return StoryStateWidget.error(
      message: l10n.createDramaEditLoadError,
      actionLabel: l10n.createDramaTagsRetry,
      onAction: () =>
          ref.read(createDramaControllerProvider.notifier).retryEditLoad(),
    );
  }

  /// 编辑模式首屏骨架：与 [_buildStep1BasicInfo] 的基本信息表单布局对齐，
  /// 加载完成切换到真实表单时无布局跳动。
  Widget _buildEditSkeleton(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.screenHorizontal,
        vertical: StorySpacing.xs,
      ),
      children: [
        const SizedBox(height: StorySpacing.md),
        // 标题输入框
        const StorySkeletonBox(width: 80, height: 16),
        const SizedBox(height: 10),
        const StorySkeletonBox(
          width: double.infinity,
          height: 48,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        const SizedBox(height: StorySpacing.base),
        // 简介输入框
        const StorySkeletonBox(width: 80, height: 16),
        const SizedBox(height: 10),
        const StorySkeletonBox(
          width: double.infinity,
          height: 120,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        const SizedBox(height: StorySpacing.base),
        // 封面区
        const StorySkeletonBox(width: 80, height: 16),
        const SizedBox(height: 10),
        const Row(
          children: [
            StorySkeletonBox(
              width: 130,
              height: 108,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            SizedBox(width: StorySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StorySkeletonBox(
                    width: 120,
                    height: 36,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  SizedBox(height: StorySpacing.md),
                  StorySkeletonBox(width: 160, height: 12),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: StorySpacing.base),
        // 标签区
        const StorySkeletonBox(width: 80, height: 16),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(
            6,
            (_) => const StorySkeletonBox(
              width: 56,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1BasicInfo(ThemeData theme, CreateDramaState state) {
    final l10n = context.l10n;
    final showErrors = _step1Submitted;
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.screenHorizontal,
        vertical: StorySpacing.xs,
      ),
      children: [
        const SizedBox(height: StorySpacing.md),
        StoryTextField(
          label: l10n.createDramaName,
          controller: _titleCtrl,
          hint: l10n.createDramaNameHint,
          enabled: !state.isEditMode,
          style: state.isEditMode
              ? theme.textTheme.bodyLarge?.copyWith(
                  color: StoryColors.mutedForegroundOf(theme.brightness),
                )
              : null,
          labelGap: 10,
          labelStyle: _kSectionLabel,
        ),
        if (showErrors && state.title.trim().isEmpty)
          _buildFieldError(l10n.createDramaStep1TitleRequired),
        const SizedBox(height: StorySpacing.base),
        _SynopsisField(
          label: l10n.createDramaSynopsis,
          controller: _synopsisCtrl,
          hint: l10n.createDramaSynopsisHint,
        ),
        if (showErrors && state.synopsis.trim().isEmpty)
          _buildFieldError(l10n.createDramaStep1SynopsisRequired),
        const SizedBox(height: StorySpacing.base),
        Text(l10n.createDramaCover, style: _kSectionLabel),
        const SizedBox(height: 10),
        _buildCoverPicker(theme, state),
        if (showErrors && state.coverObjectKey == null)
          _buildFieldError(l10n.createDramaStep1CoverRequired),
        const SizedBox(height: StorySpacing.base),
        Text(l10n.createDramaTags, style: _kSectionLabel),
        const SizedBox(height: 10),
        _buildTagsPicker(theme, state),
        if (showErrors && state.selectedTags.isEmpty)
          _buildFieldError(l10n.createDramaStep1TagsRequired),
        const SizedBox(height: StorySpacing.base),
      ],
    );
  }

  Widget _buildFieldError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: StorySpacing.xs),
      child: Text(
        message,
        style: StoryTextStyles.bodySmall(color: StoryColors.destructive),
      ),
    );
  }

  Widget _buildTagsPicker(ThemeData theme, CreateDramaState state) {
    final l10n = context.l10n;
    if (state.isTagsLoading && state.availableTags.isEmpty) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(6, (_) {
          return const StorySkeletonBox(
            width: 56,
            height: 36,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          );
        }),
      );
    }
    final error = state.tagsError;
    if (error != null && state.availableTags.isEmpty) {
      return StoryStateWidget.error(
        message: context.l10nError(error),
        actionLabel: l10n.createDramaTagsRetry,
        onAction: () =>
            ref.read(createDramaControllerProvider.notifier).loadTags(),
      );
    }
    final tags = state.availableTags;
    if (tags.isEmpty) {
      return StoryStateWidget.empty(
        message: l10n.createDramaTagsEmpty,
        actionLabel: l10n.createDramaTagsRetry,
        onAction: () =>
            ref.read(createDramaControllerProvider.notifier).loadTags(),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          _TagChip(
            label: tag.name ?? tag.code ?? '',
            selected: state.tagIsSelected(tag),
            disabled:
                !state.tagIsSelected(tag) &&
                state.selectedTags.length >= _kMaxTags,
            onTap: () =>
                ref.read(createDramaControllerProvider.notifier).toggleTag(tag),
          ),
      ],
    );
  }

  Widget _buildCoverPicker(ThemeData theme, CreateDramaState state) {
    final l10n = context.l10n;
    return Row(
      children: [
        GestureDetector(
          onTap: _pickAndUploadCover,
          child: Container(
            width: 130,
            height: 108,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: StoryColors.mutedOf(theme.brightness),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: StoryColors.borderOf(theme.brightness)),
            ),
            child: _buildCoverContent(theme, state),
          ),
        ),
        const SizedBox(width: StorySpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UploadCoverButton(
                label: l10n.createDramaCoverUpload,
                loading: state.isUploadingCover,
                onPressed: state.isUploadingCover ? null : _pickAndUploadCover,
              ),
              const SizedBox(height: StorySpacing.md),
              Text(
                l10n.createDramaCoverPlaceholder,
                style: StoryTextStyles.caption(
                  color: StoryColors.mutedForegroundOf(theme.brightness),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverContent(ThemeData theme, CreateDramaState state) {
    final localPath = state.localCoverPath;
    final localImage = localPath != null
        ? Image.file(File(localPath), fit: BoxFit.cover)
        : null;

    if (state.isUploadingCover) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (localImage != null)
            Positioned.fill(child: localImage)
          else
            ColoredBox(color: StoryColors.mutedOf(theme.brightness)),
          const ColoredBox(color: StoryColors.overlayMedium),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: state.coverUploadProgress > 0
                        ? state.coverUploadProgress
                        : null,
                    strokeWidth: 2,
                    color: StoryColors.brandTeal,
                  ),
                ),
                const SizedBox(height: StorySpacing.xs),
                Text(
                  '${(state.coverUploadProgress * 100).toStringAsFixed(0)}%',
                  style: StoryTextStyles.bodySmall(
                    color: StoryColors.foregroundOf(Brightness.dark),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final coverUrl = state.coverUrl;
    if (coverUrl != null) {
      return SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: coverUrl,
          fit: BoxFit.cover,
          memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
            context,
            MediaQuery.sizeOf(context).width,
          ),
          placeholder: localImage != null
              ? (context, url) => localImage
              : (context, url) => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: StoryColors.brandTeal,
                    ),
                  ),
                ),
          errorWidget: (context, url, error) {
            if (localImage != null) return localImage;
            return Icon(
              Icons.broken_image_outlined,
              size: 32,
              color: StoryColors.mutedForegroundOf(theme.brightness),
            );
          },
        ),
      );
    }

    return Center(
      child: Icon(
        Icons.add_photo_alternate_outlined,
        size: 32,
        color: StoryColors.mutedForegroundOf(theme.brightness),
      ),
    );
  }

  Widget _buildStep2Episodes(ThemeData theme) {
    final l10n = context.l10n;
    final isEditMode = ref.watch(
      createDramaControllerProvider.select((s) => s.isEditMode),
    );
    final vState = ref.watch(videoUploadControllerProvider);
    final videos = vState.videos;
    final hasActiveUpload = videos.any(
      (v) =>
          v.isIncomplete,
    );
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: StorySpacing.screenHorizontal,
            vertical: StorySpacing.xs,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: StorySpacing.md),
              Text(
                l10n.createDramaEpisodesDesc,
                style:
                    StoryTextStyles.bodySmall(
                      color: StoryColors.mutedForegroundOf(theme.brightness),
                    ).copyWith(
                      height: 16 / 12,
                      letterSpacing: 0.04,
                      fontWeight: FontWeight.w400,
                    ),
              ),
              const SizedBox(height: StorySpacing.xl),
              _buildVideoUploadModule(theme, vState),
              const SizedBox(height: StorySpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.createDramaAddedVideosLabel,
                        style: _kSectionLabel.copyWith(
                          color: StoryColors.foregroundOf(theme.brightness),
                        ),
                      ),
                      const SizedBox(width: StorySpacing.xs),
                      Text(
                        l10n.createDramaAddedVideosCount('${videos.length}'),
                        style: _kSectionLabel.copyWith(
                          fontWeight: FontWeight.w400,
                          color: StoryColors.mutedForegroundOf(
                            theme.brightness,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: StorySpacing.md),
              if (videos.isEmpty)
                StoryStateWidget.empty(message: l10n.createDramaVideoEmpty),
            ]),
          ),
        ),
        if (videos.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.screenHorizontal,
            ),
            sliver: SliverReorderableList(
              itemCount: videos.length,
              onReorderItem: (oldIndex, newIndex) {
                ref
                    .read(videoUploadControllerProvider.notifier)
                    .move(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final video = videos[index];
                return DramaVideoUploadItem(
                  key: ValueKey<String>(video.id),
                  dragEnabled: !hasActiveUpload &&
                      (!isEditMode ||
                          (!video.preexisting && !video.isReplacement)),
                  index: index + 1,
                  title: video.name,
                  fileExtension: VideoUrlHelpers.pathExtensionOf(
                    video.url ?? video.path,
                  ),
                  details: _videoDetails(video),
                  progress: video.progress,
                  status: video.status,
                  networkWait: video.networkWait,
                  speedBps: video.speedBps,
                  statusLabel: _videoStatusLabel(video),
                  description: video.description,
                  descriptionHint: l10n.createDramaEpisodeDescriptionHint,
                  descriptionError:
                      _step2Submitted && video.description.trim().isEmpty
                      ? l10n.createDramaEpisodeDescriptionRequired
                      : null,
                  onDescriptionChanged: (description) => ref
                      .read(videoUploadControllerProvider.notifier)
                      .updateDescription(video.id, description),
                  thumbnailPath: video.thumbnailPath,
                  onPlay:
                      (video.path.isNotEmpty ||
                          (video.url?.isNotEmpty ?? false))
                      ? () => _playVideo(video)
                      : null,
                  onPause: () => ref
                      .read(videoUploadControllerProvider.notifier)
                      .pauseVideo(video.id),
                  onResume: () => ref
                      .read(videoUploadControllerProvider.notifier)
                      .resumeVideo(video.id),
                  onRetry:
                      video.isFailed ? () => _retryVideo(video.id) : null,
                  onReupload: () => _replaceVideo(video.id),
                  onDelete: () => _confirmDeleteVideo(video),
                  deleteEnabled: !video.preexisting && !video.isReplacement,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVideoUploadModule(ThemeData theme, VideoUploadState vState) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.cardPadding,
        vertical: StorySpacing.xl,
      ),
      decoration: BoxDecoration(
        color: StoryColors.createDramaPanelSurfaceOf(theme.brightness),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: StoryColors.dividerOf(theme.brightness)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 44,
            color: StoryColors.tertiaryTextOf(theme.brightness),
          ),
          const SizedBox(height: StorySpacing.md),
          Text(
            l10n.createDramaUploadDesc,
            textAlign: TextAlign.center,
            style: StoryTextStyles.labelLarge(
              color: StoryColors.foregroundOf(theme.brightness),
            ),
          ),
          const SizedBox(height: StorySpacing.sm),
          Text(
            l10n.createDramaVideoFileTypeHint,
            textAlign: TextAlign.center,
            style: StoryTextStyles.caption(
              color: StoryColors.mutedForegroundOf(theme.brightness),
            ),
          ),
          const SizedBox(height: StorySpacing.lg),
          Center(
            child: _UploadVideoButton(
              label: l10n.createDramaUploadVideo,
              loading: vState.isPicking,
              onPressed:
                  (vState.isPicking || vState.videos.length >= _kMaxEpisodes)
                  ? null
                  : _pickVideos,
            ),
          ),
        ],
      ),
    );
  }

  String _videoDetails(VideoUploadItem item) {
    return '${StoryFormat.formatFileSize(item.sizeBytes)}'
        ' · ${StoryFormat.formatDuration(item.durationMs)}';
  }

  String _videoStatusLabel(VideoUploadItem item) {
    final l10n = context.l10n;
    if (item.isWaitingNetwork) return l10n.uploadStatusWaitingNetwork;
    if (item.isSuccess) return l10n.createDramaVideoStatusDone;
    if (item.isFailed) return l10n.createDramaVideoStatusFailed;
    if (item.isPaused) return l10n.createDramaVideoStatusPaused;
    return l10n.createDramaVideoStatusUploading;
  }

  /// 蜂窝网络确认弹窗（PRD：队列把未确认 session 停在 paused 时触发）。
  void _maybeShowCellularDialog(bool pending) {
    if (pending == _cellularDialogShowing) return;
    if (!pending) {
      if (_cellularDialogShowing && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _cellularDialogShowing = false;
      return;
    }
    _cellularDialogShowing = true;
    final l10n = context.l10n;
    StoryDialog.confirm(
      context: context,
      title: l10n.uploadCellularDialogMessage,
      confirmLabel: l10n.commonConfirm,
      cancelLabel: l10n.commonCancel,
    ).then((accepted) {
      if (!mounted) return;
      _cellularDialogShowing = false;
      ref
          .read(videoUploadControllerProvider.notifier)
          .confirmCellularUpload(accepted == true);
    });
  }

  /// 视频项错误详情文案。Controller 无 BuildContext，故将 l10n key 写入
  /// [VideoUploadItem.error]；这里翻译为本地化文案。对于上传失败等由
  /// ApiError 产生的英文兜底文案不在此展示（保留原有状态徽标即可）。
  String? _videoErrorMessage(VideoUploadItem item) {
    if (item.error == null) return null;
    if (item.error == kVideoTooLargeErrorKey) {
      return context.l10n.createDramaVideoTooLarge;
    }
    return localizeUploadFailure(context.l10n, item.error);
  }

  Future<void> _pickVideos() async {
    final notifier = ref.read(videoUploadControllerProvider.notifier);
    final synopsis = ref.read(createDramaControllerProvider).synopsis;
    try {
      await notifier.pickVideos(initialDescription: synopsis);
    } catch (e) {
      if (mounted) {
        final msg = e is StateError ? e.message : '';
        if (msg == kVideoAnyTooLargeErrorKey) {
          StoryToast.error(context, context.l10n.createDramaVideoAnyTooLarge);
        } else {
          StoryToast.error(context, context.l10n.createDramaVideoPickFailed);
        }
      }
    }
  }

  Future<void> _retryVideo(String id) async {
    try {
      await ref.read(videoUploadControllerProvider.notifier).retry(id);
    } catch (e) {
      if (mounted) {
        final msg = e is StateError ? e.message : '';
        if (msg == kVideoAnyTooLargeErrorKey) {
          StoryToast.error(context, context.l10n.createDramaVideoAnyTooLarge);
        }
      }
    }
  }

  Future<void> _replaceVideo(String id) async {
    try {
      await ref.read(videoUploadControllerProvider.notifier).replaceVideo(id);
    } catch (e) {
      if (mounted) {
        final msg = e is StateError ? e.message : '';
        if (msg == kVideoAnyTooLargeErrorKey) {
          StoryToast.error(context, context.l10n.createDramaVideoAnyTooLarge);
        } else {
          StoryToast.error(context, context.l10n.createDramaVideoPickFailed);
        }
      }
    }
  }

  void _playVideo(VideoUploadItem video) {
    if (video.isHistoricalUpload) {
      StoryToast.error(
        context,
        context.l10n.createDramaVideoPreviewUnavailable,
      );
      return;
    }

    final source = video.path.isNotEmpty ? video.path : video.url;
    if (source == null || source.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPreviewPage(videoPath: source, title: video.name),
      ),
    );
  }

  Widget _buildStep3BindIp() {
    final roles = ref.watch(
      createDramaControllerProvider.select((s) => s.roles),
    );
    final isEditMode = ref.watch(
      createDramaControllerProvider.select((s) => s.isEditMode),
    );
    final onlineAt = ref.watch(
      createDramaControllerProvider.select((s) => s.originalSession?.onlineAt),
    );
    return BindIpStep(
      roles: roles,
      onlineAt: onlineAt,
      onAdd: _onAddIp,
      onAddExpired: () {
        StoryToast.warning(context, context.l10n.createDramaBindActorExpired);
      },
      onActorTap: isEditMode
          ? (role) {
              final actorId = role.boundActorCollectionId?.trim();
              if (actorId == null || actorId.isEmpty) return;
              openActorDetail(context, actorId: actorId);
            }
          : null,
      onRemove: (role) {
        ref.read(createDramaControllerProvider.notifier).deleteRole(role.id);
      },
    );
  }

  /// 打开多选角色 IP 弹窗，并把确认结果写回创建短剧状态。
  Future<void> _onAddIp() async {
    final state = ref.read(createDramaControllerProvider);
    final boundIds = state.roles
        .map((role) => role.boundActorCollectionId?.trim())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    final remaining = BindIpStep.maxItems - boundIds.length;
    if (remaining <= 0) return;

    final selected = await BindIpSelectionSheet.show(
      context,
      boundActorIds: boundIds,
      maxSelections: remaining,
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    ref
        .read(createDramaControllerProvider.notifier)
        .addBoundActorCollections(selected);
  }

  void _confirmDeleteVideo(VideoUploadItem video) {
    final l10n = context.l10n;
    StoryDialog.confirm(
      context: context,
      title: l10n.createDramaVideoDeleteTitle,
      message: l10n.createDramaVideoDeleteConfirm(video.name),
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
      confirmLabel: MaterialLocalizations.of(context).okButtonLabel,
      onConfirm: () {
        ref.read(videoUploadControllerProvider.notifier).remove(video.id);
      },
    );
  }

  Widget _buildBottomActions(ThemeData theme, int currentStep) {
    final l10n = context.l10n;
    final state = ref.watch(createDramaControllerProvider);
    final vState = ref.watch(videoUploadControllerProvider);
    final isSubmitting = state.isLoading;
    final isLastStep = currentStep == 2;
    final videos = vState.videos;
    final hasVideos = videos.isNotEmpty;
    final allUploaded = !videos.any(
      (v) =>
          v.isIncomplete,
    );
    final allSuccess = hasVideos && videos.every((v) => v.isSuccess);
    final canProceed = switch (currentStep) {
      0 => !state.isUploadingCover,
      1 => allUploaded && allSuccess,
      // Figma：绑定 IP 为选填，可以不绑定直接发布。
      2 => true,
      _ => true,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.screenHorizontal,
        vertical: StorySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: StoryColors.createDramaPageSurfaceOf(theme.brightness),
        border: Border(
          top: BorderSide(color: StoryColors.borderOf(theme.brightness)),
        ),
      ),
      child: Row(
        children: [
          if (currentStep > 0) ...[
            Expanded(
              child: SecondaryActionButton(
                label: l10n.createDramaPrevStep,
                onPressed: isSubmitting ? null : _prevStep,
              ),
            ),
            const SizedBox(width: StorySpacing.md),
          ],
          Expanded(
            child: PrimaryActionButton(
              label: isLastStep
                  ? l10n.createDramaSubmit
                  : l10n.createDramaNextStep,
              onPressed: (isSubmitting || !canProceed) ? null : _nextStep,
              loading: isLastStep && isSubmitting,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _TagChip({
    required this.label,
    required this.selected,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInteractive = !disabled || selected;
    final isDark = theme.brightness == Brightness.dark;
    final selectedBg = isDark ? Colors.white : StoryColors.darkButtonBg;
    final selectedText = isDark
        ? const Color(0xFF1C2024)
        : StoryColors.onOverlay;
    final unselectedBorder = StoryColors.dividerOf(theme.brightness);
    final unselectedText = StoryColors.foregroundOf(theme.brightness);
    final disabledBg = StoryColors.mutedOf(theme.brightness);
    const disabledText = StoryColors.buttonDisabledForeground;
    final bg = disabled
        ? disabledBg
        : (selected ? selectedBg : const Color(0x00000000));
    final border = selected
        ? null
        : (disabled ? null : Border.all(color: unselectedBorder));
    final fg = selected
        ? selectedText
        : (disabled ? disabledText : unselectedText);
    return GestureDetector(
      onTap: isInteractive ? onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 56, minHeight: 36),
        child: IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: StorySpacing.sm),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              border: border,
            ),
            child: Text(
              label,
              style: StoryTextStyles.bodyMedium(
                color: fg,
              ).copyWith(fontWeight: FontWeight.w500, height: 20 / 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _SynopsisField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _SynopsisField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _kSectionLabel),
        const SizedBox(height: 10),
        Stack(
          children: [
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 1000,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: StoryTextStyles.bodyMedium(
                  color: StoryColors.mutedForegroundOf(theme.brightness),
                ),
                filled: true,
                fillColor: StoryColors.mutedOf(theme.brightness),
                border: const OutlineInputBorder(
                  borderRadius: StoryRadius.brMd,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: StoryRadius.brMd,
                  borderSide: BorderSide(
                    color: StoryColors.brandTeal,
                    width: 1.5,
                  ),
                ),
                counterText: '',
                contentPadding: const EdgeInsets.fromLTRB(
                  StorySpacing.md,
                  StorySpacing.md,
                  StorySpacing.md,
                  28,
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 16,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, _) {
                  return Text(
                    '${value.text.length}/1000',
                    style: StoryTextStyles.caption(
                      color: StoryColors.mutedForegroundOf(theme.brightness),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UploadVideoButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _UploadVideoButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final bg = disabled
        ? StoryColors.mutedOf(Theme.of(context).brightness)
        : StoryColors.brandTealRed;
    final fg = disabled
        ? StoryColors.buttonDisabledForeground
        : StoryColors.brandTealForeground;
    final content = IntrinsicWidth(
      child: Container(
        height: 44,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(color: bg, borderRadius: StoryRadius.brLg),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Text(label, style: StoryTextStyles.labelLarge(color: fg)),
      ),
    );
    if (disabled) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: StoryRadius.brPill,
        child: content,
      ),
    );
  }
}

class _UploadCoverButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _UploadCoverButton({
    required this.label,
    required this.loading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onPressed == null;
    final bg = StoryColors.mutedOf(theme.brightness);
    final border = StoryColors.dividerOf(theme.brightness);
    final fg = disabled
        ? StoryColors.buttonDisabledForeground
        : StoryColors.foregroundOf(theme.brightness);
    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              ),
            if (loading) const SizedBox(width: 10),
            Text(
              label,
              style: StoryTextStyles.labelLarge(
                color: fg,
              ).copyWith(fontWeight: FontWeight.w700, height: 20 / 14),
            ),
          ],
        ),
      ),
    );
  }
}
