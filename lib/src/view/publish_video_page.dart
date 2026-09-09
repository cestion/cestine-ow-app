import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/common/story_toast.dart';
import '../controller/publish_video_state.dart';
import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../routes/route_args.dart';
import '../foundation/navigator.dart';
import '../routes/route_names.dart';
import '../services/video_file_picker_service.dart';
import '../styles/story_colors.dart';
import '../widgets/story_dialog.dart';
import '../widgets/story_state_widget.dart';
import 'widgets/create_drama/draft_exit_menu.dart';
import 'widgets/create_drama/video_preview_page.dart';
import 'widgets/publish_video/publish_video_bottom_bar.dart';
import 'widgets/publish_video/publish_video_cover_section.dart';
import 'widgets/publish_video/publish_video_description_field.dart';
import 'widgets/publish_video/publish_video_upload_card.dart';

/// 发布独立短视频页面。
///
/// 视频、封面上传、草稿恢复和正式发布均接入现有仓储。
class PublishVideoPage extends ConsumerStatefulWidget {
  final int? episodeId;

  const PublishVideoPage({super.key, this.episodeId});

  @override
  ConsumerState<PublishVideoPage> createState() => _PublishVideoPageState();
}

class _PublishVideoPageState extends ConsumerState<PublishVideoPage>
    with WidgetsBindingObserver {
  final TextEditingController _descriptionController = TextEditingController();
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
    final episodeId = widget.episodeId;
    if (episodeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref
              .read(publishVideoControllerProvider.notifier)
              .loadForEdit(episodeId),
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref.read(publishVideoControllerProvider.notifier).tryRestoreDraft(),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _exitMenuEntry?.remove();
    _exitMenuEntry = null;
    _descriptionController.dispose();
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
            .read(publishVideoControllerProvider.notifier)
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
    final controller = ref.read(publishVideoControllerProvider.notifier);
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
    final state = ref.read(publishVideoControllerProvider);
    if (state.isEditMode) {
      StoryToast.warning(
        context,
        context.l10n.publishVideoDraftEditModeNotSupported,
      );
      return;
    }
    if (!state.hasDraftableContent) {
      StoryToast.warning(
        context,
        context.l10n.publishVideoDraftNothingToSave,
      );
      return;
    }
    _isExitActionPending = true;
    _hideExitMenu();
    final saved = await ref
        .read(publishVideoControllerProvider.notifier)
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
        .read(publishVideoControllerProvider.notifier)
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

  Future<void> _pickCover() async {
    await ref
        .read(publishVideoControllerProvider.notifier)
        .pickAndUploadCover(
          context: context,
          toolbarTitle: context.l10n.publishVideoCoverCropTitle,
        );
  }

  Future<void> _pickVideo() async {
    await ref
        .read(publishVideoControllerProvider.notifier)
        .pickAndUploadVideo(source: VideoPickSource.files);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final isEditMode = ref.read(publishVideoControllerProvider).isEditMode;
    final result = await ref
        .read(publishVideoControllerProvider.notifier)
        .submit();
    if (!mounted) return;
    result.when(
      success: (video) {
        StoryToast.success(
          context,
          isEditMode
              ? context.l10n.publishVideoUpdatedSuccess
              : context.l10n.publishVideoPublishedSuccess,
        );
        if (isEditMode) {
          _completePop(video);
          return;
        }
        ref.invalidate(creatorManagementOverviewControllerProvider);
        ref.invalidate(creatorVideoManagementControllerProvider);
        context.storyPushAndRemoveUntil(RouteNames.creatorManagement,
          ModalRoute.withName(RouteNames.main),
          arguments: const CreatorManagementArgs(initialTabIndex: 1).toMap());
      },
      // ApiError 由 ref.listen 统一展示，避免同一错误出现两个 Toast。
      failure: (_) {},
    );
  }

  void _playVideo(String videoPath, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPreviewPage(videoPath: videoPath, title: title),
      ),
    );
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
          .read(publishVideoControllerProvider.notifier)
          .confirmCellularUpload(accepted == true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(publishVideoControllerProvider);
    final editSession = state.editSession;
    final isEditMode = widget.episodeId != null;
    final brightness = Theme.of(context).brightness;
    final pageBackground = StoryColors.cardOf(brightness);

    if (!_editPrefilled && state.editSession != null && !state.isEditLoading) {
      _editPrefilled = true;
      _descriptionController.text = state.description;
    }

    if (!_draftPrefilled && state.draftRestored && !state.isEditMode) {
      _draftPrefilled = true;
      _descriptionController.text = state.description;
      if (!_draftToastShown) {
        _draftToastShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          StoryToast.success(context, l10n.createDramaDraftRestored);
        });
      }
    }

    ref.listen<PublishVideoState>(publishVideoControllerProvider, (prev, next) {
      _maybeShowCellularDialog(next.cellularConfirmationPending);
      if (next.issue != null && next.issue != prev?.issue) {
        StoryToast.error(context, _issueMessage(next.issue!));
      }
      if (next.lastError != null && next.lastError != prev?.lastError) {
        StoryToast.error(context, context.l10nError(next.lastError!));
      }
    });

    return PopScope<Object?>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        backgroundColor: pageBackground,
        appBar: AppBar(
          toolbarHeight: 44,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: pageBackground,
          foregroundColor: StoryColors.foregroundOf(brightness),
          leading: _buildBackButton(),
          title: Text(
            isEditMode ? l10n.editVideoTitle : l10n.publishVideo,
            style: TextStyle(
              color: StoryColors.foregroundOf(brightness),
              fontSize: 18,
              height: 26 / 18,
              letterSpacing: -0.04,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: state.isEditLoading
              ? const StoryStateWidget.loading()
              : state.editLoadError != null
              ? StoryStateWidget.error(
                  message: context.l10nError(state.editLoadError!),
                )
              : ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    PublishVideoUploadCard(
                      title: l10n.publishVideoUploadTitle,
                      hint: l10n.publishVideoFileHint,
                      buttonLabel:
                          state.video == null && !state.isEditMode
                          ? l10n.publishVideoChooseFile
                          : l10n.publishVideoChangeFile,
                      busyLabel: l10n.publishVideoPreparing,
                      selectedFileName: editSession?.title ?? state.video?.name,
                      thumbnailPath: state.video?.thumbnailPath,
                      thumbnailUrl: editSession?.coverUrl,
                      uploadStatus: editSession != null
                          ? PublishVideoUploadStatus.success
                          : state.video?.uploadStatus ??
                                PublishVideoUploadStatus.idle,
                      isBusy:
                          state.isPickingVideo ||
                          state.video?.isUploading == true,
                      isPicking: state.isPickingVideo,
                      enabled: !state.isEditMode,
                      showActions: !state.isEditMode,
                      uploadProgress: state.video?.uploadProgress ?? 0,
                      networkWait: state.video?.networkWait ?? false,
                      speedBps: state.video?.speedBps ?? 0,
                      fileSizeBytes:
                          editSession?.videoSizeBytes ??
                          state.video?.sizeBytes ??
                          0,
                      durationMs: editSession != null
                          ? editSession.durationSec * 1000
                          : state.video?.durationMs ?? 0,
                      onTap: state.isEditMode ? null : _pickVideo,
                      onPause:
                          state.video?.uploadStatus ==
                              PublishVideoUploadStatus.uploading
                          ? () => ref
                                .read(publishVideoControllerProvider.notifier)
                                .pauseVideo()
                          : null,
                      onResume:
                          state.video?.uploadStatus ==
                              PublishVideoUploadStatus.paused
                          ? () => ref
                                .read(publishVideoControllerProvider.notifier)
                                .resumeVideo()
                          : null,
                      onRetry:
                          state.video?.uploadStatus ==
                              PublishVideoUploadStatus.failed
                          ? () => ref
                                .read(publishVideoControllerProvider.notifier)
                                .retryVideo()
                          : null,
                      onDelete: state.isEditMode
                          ? null
                          : ref
                                .read(publishVideoControllerProvider.notifier)
                                .removeVideo,
                      onPlay:
                          !state.isEditMode &&
                              state.video != null &&
                              state.video!.path.isNotEmpty &&
                              File(state.video!.path).existsSync()
                          ? () =>
                                _playVideo(state.video!.path, state.video!.name)
                          : null,
                    ),
                    const SizedBox(height: 24),
                    PublishVideoCoverSection(
                      title: l10n.publishVideoCoverTitle,
                      buttonLabel: l10n.publishVideoChangeCover,
                      hint: l10n.publishVideoCoverHint,
                      localCoverPath: state.localCoverPath,
                      remoteCoverUrl: state.remoteCoverUrl,
                      isBusy: state.isPickingCover || state.isUploadingCover,
                      uploadProgress: state.coverUploadProgress,
                      onPressed: _pickCover,
                    ),
                    const SizedBox(height: 16),
                    PublishVideoDescriptionField(
                      label: l10n.publishVideoDescriptionLabel,
                      requiredLabel: l10n.publishVideoRequired,
                      hint: l10n.publishVideoDescriptionHint,
                      controller: _descriptionController,
                      onChanged: ref
                          .read(publishVideoControllerProvider.notifier)
                          .setDescription,
                    ),
                  ],
                ),
        ),
        bottomNavigationBar: PublishVideoBottomBar(
          showDraftButton: !isEditMode,
          draftLabel: l10n.publishVideoSaveDraft,
          nextLabel: l10n.createDramaSubmit,
          canContinue: state.canContinue,
          isPublishing: state.isPublishing,
          onSaveDraft: _saveDraftAndExit,
          onContinue: _submit,
        ),
      ),
    );
  }

  String _issueMessage(PublishVideoIssue issue) {
    final l10n = context.l10n;
    return switch (issue) {
      PublishVideoIssue.videoTooLarge => l10n.publishVideoVideoTooLarge,
      PublishVideoIssue.videoPickFailed => l10n.publishVideoVideoPickFailed,
      PublishVideoIssue.videoInsufficientStorage =>
        l10n.publishVideoInsufficientStorage,
      PublishVideoIssue.videoPermissionDenied =>
        l10n.publishVideoPermissionDenied,
      PublishVideoIssue.videoSourceUnavailable =>
        l10n.publishVideoSourceUnavailable,
      PublishVideoIssue.videoPrepareFailed => l10n.publishVideoPrepareFailed,
      PublishVideoIssue.videoMetadataUnavailable =>
        l10n.publishVideoMetadataUnavailable,
      PublishVideoIssue.coverTooLarge => l10n.publishVideoCoverTooLarge,
      PublishVideoIssue.coverUnsupportedFormat =>
        l10n.publishVideoCoverUnsupportedFormat,
      PublishVideoIssue.coverPickFailed => l10n.publishVideoCoverPickFailed,
      PublishVideoIssue.uploadSessionUnavailable =>
        l10n.publishVideoUploadSessionFailed,
    };
  }
}
