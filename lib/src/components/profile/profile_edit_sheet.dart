import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../l10n/story_l10n.dart';
import '../../provider/app_providers.dart';
import '../../repositories/file_upload_repository.dart';
import '../../services/image_picker_service.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_text_styles.dart';
import '../../styles/story_spacing.dart';
import '../../widgets/story_avatar.dart';
import '../../widgets/story_text_field.dart';
import '../common/story_toast.dart';

/// 「编辑资料」底部弹窗（仅本人可用）。
///
/// 支持修改头像与昵称。头像在弹窗内部自管理选图、裁剪与上传（含进度）；
/// 提交时调用 [ProfileController.saveProfile] 写回后端并刷新 profile。
class ProfileEditSheet extends ConsumerStatefulWidget {
  const ProfileEditSheet({super.key});

  /// 弹出编辑资料表单。
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: StoryColors.cardOf(Theme.of(context).brightness),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const ProfileEditSheet(),
    );
  }

  @override
  ConsumerState<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<ProfileEditSheet>
    with WidgetsBindingObserver {
  static const _keyboardSettleDelay = Duration(milliseconds: 350);
  static const _nicknameMaxLength = 64;

  final _nicknameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _nicknameFocusNode = FocusNode();
  final _bioFocusNode = FocusNode();
  final _nicknameFieldKey = GlobalKey();
  final _bioFieldKey = GlobalKey();
  Timer? _ensureVisibleTimer;

  String? _initialNickname;
  String? _initialAvatarUrl;
  String? _initialBio;
  String? _email;

  // 头像本地态：上传成功后持有远程 URL 与本地预览路径。
  String? _uploadedAvatarUrl;
  String? _localAvatarPath;
  bool _isUploadingAvatar = false;
  double _avatarProgress = 0;
  bool _isSaving = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final user = ref.read(profileControllerProvider).user;
    _initialNickname = user?.nickname;
    _initialAvatarUrl = user?.avatarUrl;
    _initialBio = user?.bio;
    _email = user?.email;
    _nicknameCtrl.text = user?.nickname ?? '';
    _bioCtrl.text = user?.bio ?? '';
    _nicknameFocusNode.addListener(_ensureFocusedFieldVisible);
    _bioFocusNode.addListener(_ensureFocusedFieldVisible);
  }

  void _ensureFocusedFieldVisible() {
    _scrollFocusedFieldIntoView();
    _scheduleEnsureFocusedFieldVisible();
  }

  @override
  void didChangeMetrics() {
    _scheduleEnsureFocusedFieldVisible();
  }

  void _scheduleEnsureFocusedFieldVisible() {
    _ensureVisibleTimer?.cancel();
    if (!_nicknameFocusNode.hasFocus && !_bioFocusNode.hasFocus) return;
    _ensureVisibleTimer = Timer(
      _keyboardSettleDelay,
      _scrollFocusedFieldIntoView,
    );
  }

  void _scrollFocusedFieldIntoView() {
    final FocusNode focusedNode;
    final GlobalKey fieldKey;
    if (_nicknameFocusNode.hasFocus) {
      focusedNode = _nicknameFocusNode;
      fieldKey = _nicknameFieldKey;
    } else if (_bioFocusNode.hasFocus) {
      focusedNode = _bioFocusNode;
      fieldKey = _bioFieldKey;
    } else {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !focusedNode.hasFocus) return;
      final fieldContext = fieldKey.currentContext;
      if (fieldContext == null) return;
      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ensureVisibleTimer?.cancel();
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    _nicknameFocusNode.dispose();
    _bioFocusNode.dispose();
    super.dispose();
  }

  bool get _nicknameValid => _nicknameCtrl.text.trim().isNotEmpty;

  Future<void> _pickAndUploadAvatar() async {
    final l10n = context.l10n;
    final picked = await ImagePickerService.pickAndCropImage(
      context: context,
      toolbarTitle: l10n.editAvatarCropTitle,
      ratioX: 1,
      ratioY: 1,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _isUploadingAvatar = true;
      _avatarProgress = 0;
      _localAvatarPath = picked.path;
    });
    final result = await ref
        .read(fileUploadRepositoryProvider)
        .uploadFile(
          filePath: picked.path,
          fileCategory: FileCategory.avatar,
          onProgress: (p) {
            if (mounted) setState(() => _avatarProgress = p);
          },
        );
    if (!mounted) return;
    result.when(
      success: (url) {
        setState(() {
          _isUploadingAvatar = false;
          _uploadedAvatarUrl = url;
        });
      },
      failure: (error) {
        setState(() {
          _isUploadingAvatar = false;
          _uploadedAvatarUrl = null;
          _localAvatarPath = null;
        });
        StoryToast.error(context, context.l10nError(error));
      },
    );
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_nicknameValid || _isUploadingAvatar || _isSaving) return;

    final nickname = _nicknameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();
    final nicknameChanged = nickname != (_initialNickname ?? '');
    final avatarChanged =
        _uploadedAvatarUrl != null && _uploadedAvatarUrl != _initialAvatarUrl;
    final bioChanged = bio != (_initialBio?.trim() ?? '');

    if (!nicknameChanged && !avatarChanged && !bioChanged) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);
    final result = await ref
        .read(profileControllerProvider.notifier)
        .saveProfile(
          nickname: nicknameChanged ? nickname : null,
          avatarUrl: avatarChanged ? _uploadedAvatarUrl : null,
          bio: bioChanged ? bio : null,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    result.when(
      success: (_) {
        StoryToast.success(context, context.l10n.profileUpdateSuccess);
        Navigator.of(context).pop();
      },
      failure: (error) => StoryToast.error(context, context.l10nError(error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final brightness = theme.brightness;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题区固定，不随表单内容滚动。
          _buildHeader(brightness),
          Flexible(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                StorySpacing.screenHorizontal,
                StorySpacing.lg,
                StorySpacing.screenHorizontal,
                StorySpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAvatarPicker(brightness),
                  const SizedBox(height: StorySpacing.lg),
                  StoryTextField(
                    key: _nicknameFieldKey,
                    label: l10n.editRoleNameLabel,
                    controller: _nicknameCtrl,
                    focusNode: _nicknameFocusNode,
                    hint: l10n.editNicknameHint,
                    maxLength: _nicknameMaxLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    labelStyle: StoryTextStyles.labelLarge(
                      color: StoryColors.foregroundOf(brightness),
                    ),
                  ),
                  if (_submitted && !_nicknameValid)
                    Padding(
                      padding: const EdgeInsets.only(top: StorySpacing.xs),
                      child: Text(
                        l10n.editNicknameRequired,
                        style: StoryTextStyles.caption(
                          color: StoryColors.destructive,
                        ),
                      ),
                    ),
                  const SizedBox(height: StorySpacing.base),
                  StoryTextField(
                    key: _bioFieldKey,
                    label: l10n.editProfileBioLabel,
                    controller: _bioCtrl,
                    focusNode: _bioFocusNode,
                    hint: l10n.editProfileBioHint,
                    maxLines: 2,
                    maxLength: 200,
                    labelStyle: StoryTextStyles.labelLarge(
                      color: StoryColors.foregroundOf(brightness),
                    ),
                  ),
                  const SizedBox(height: StorySpacing.base),
                  Text(
                    l10n.editProfileEmailLabel,
                    style: StoryTextStyles.labelLarge(
                      color: StoryColors.foregroundOf(brightness),
                    ),
                  ),
                  const SizedBox(height: StorySpacing.xs),
                  Text(
                    _email ?? '',
                    style: StoryTextStyles.bodyMedium(
                      color: StoryColors.foregroundOf(brightness),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 操作按钮固定在底部，键盘弹出时仍始终可见。
          _buildFooter(brightness),
          SizedBox(
            height: StorySpacing.md + MediaQuery.paddingOf(context).bottom,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Brightness brightness) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(StorySpacing.sm + 2),
          child: Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: StoryColors.dividerOf(brightness),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StorySpacing.screenHorizontal,
            StorySpacing.base,
            StorySpacing.screenHorizontal,
            0,
          ),
          child: Text(
            context.l10n.editProfileTitle,
            style: StoryTextStyles.headingMedium(
              color: StoryColors.foregroundOf(brightness),
            ),
          ),
        ),
      ],
    );
  }

  /// 头像选择区：圆形头像 + 「上传头像」胶囊按钮，整体居中，点击选图上传。
  Widget _buildAvatarPicker(Brightness brightness) {
    final l10n = context.l10n;
    return Column(
      children: [
        GestureDetector(
          onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
          child: ClipOval(
            child: SizedBox(
              width: 88,
              height: 88,
              child: _buildAvatarContent(brightness),
            ),
          ),
        ),
        const SizedBox(height: StorySpacing.md),
        Material(
          color: StoryColors.mutedOf(brightness),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(58),
            side: BorderSide(color: StoryColors.dividerOf(brightness)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(58),
            onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StorySpacing.xl,
                vertical: StorySpacing.sm,
              ),
              child: Text(
                l10n.createDramaRoleUploadAvatar,
                style: StoryTextStyles.labelLarge(
                  color: StoryColors.foregroundOf(brightness),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarContent(Brightness brightness) {
    if (_localAvatarPath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_localAvatarPath!), fit: BoxFit.cover),
          if (_isUploadingAvatar)
            ColoredBox(
              color: StoryColors.overlayMedium,
              child: Center(child: _buildAvatarProgress()),
            ),
        ],
      );
    }
    return StoryAvatar(
      imageUrl: _initialAvatarUrl,
      userId: ref.read(authControllerProvider).userId,
      fallbackText: _nicknameCtrl.text,
      size: 88,
    );
  }

  Widget _buildAvatarProgress() {
    return SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        value: _avatarProgress > 0 ? _avatarProgress : null,
        strokeWidth: 2.5,
        color: StoryColors.brandTeal,
      ),
    );
  }

  /// 底部操作栏：取消（描边）+ 保存（深色主按钮），左右等分。
  Widget _buildFooter(Brightness brightness) {
    final l10n = context.l10n;
    final isLight = brightness == Brightness.light;
    final busy = _isUploadingAvatar || _isSaving;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.screenHorizontal,
        vertical: StorySpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _FooterButton(
              label: l10n.commonCancel,
              onTap: _isSaving ? null : () => Navigator.of(context).pop(),
              background: Colors.transparent,
              foreground: StoryColors.foregroundOf(brightness),
              borderColor: StoryColors.dividerOf(brightness),
            ),
          ),
          const SizedBox(width: StorySpacing.md),
          Expanded(
            child: _FooterButton(
              label: l10n.editSaveChanges,
              onTap: busy ? null : _submit,
              loading: _isSaving,
              background: isLight
                  ? StoryColors.privyLightNormal
                  : StoryColors.privyDarkNormal,
              foreground: isLight
                  ? StoryColors.privyLightForeground
                  : StoryColors.privyDarkForeground,
            ),
          ),
        ],
      ),
    );
  }
}

/// 底部操作栏按钮：12px 圆角，可选 1.5px 描边。
class _FooterButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final bool loading;

  const _FooterButton({
    required this.label,
    required this.onTap,
    required this.background,
    required this.foreground,
    this.borderColor,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderColor != null
            ? BorderSide(color: borderColor!, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
          child: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              : Text(
                  label,
                  style: StoryTextStyles.labelLarge(color: foreground),
                ),
        ),
      ),
    );
  }
}
