import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/story_constants.dart';
import '../../../widgets/story_cached_image.dart';

import '../../../components/common/story_toast.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../services/image_picker_service.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../widgets/story_text_field.dart';

/// 角色新增/编辑表单（Modal BottomSheet）。
///
/// `initial` 为 null 表示新增；非 null 表示编辑已有角色。表单内部自管理
/// 头像选图与上传（含进度），提交时调用 [CreateDramaController.addRole]
/// 或 [updateRole] 写回 state。
class RoleFormSheet extends ConsumerStatefulWidget {
  final DramaRoleDraft? initial;

  const RoleFormSheet({super.key, this.initial});

  /// 弹出表单。[initial] 为 null 时为新增模式。
  static Future<void> show(BuildContext context, {DramaRoleDraft? initial}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: StoryColors.cardOf(Theme.of(context).brightness),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RoleFormSheet(initial: initial),
    );
  }

  @override
  ConsumerState<RoleFormSheet> createState() => _RoleFormSheetState();
}

class _RoleFormSheetState extends ConsumerState<RoleFormSheet>
    with WidgetsBindingObserver {
  static const _keyboardSettleDelay = Duration(milliseconds: 200);

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _bioFocusNode = FocusNode();
  final _nameFieldKey = GlobalKey();
  final _bioFieldKey = GlobalKey();
  Timer? _ensureVisibleTimer;
  bool _submitted = false;

  // 头像本地态：上传成功后持有 objectKey 与本地预览路径。
  String? _avatarObjectKey;
  String? _localAvatarPath;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  double _avatarProgress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final init = widget.initial;
    if (init != null) {
      _nameCtrl.text = init.name;
      _bioCtrl.text = init.bio;
      _avatarObjectKey = init.avatarObjectKey;
      _localAvatarPath = init.localAvatarPath;
      _avatarUrl = init.avatarUrl;
    }
    _nameCtrl.addListener(_onNameChanged);
    _nameFocusNode.addListener(_ensureFocusedFieldVisible);
    _bioFocusNode.addListener(_ensureFocusedFieldVisible);
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
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
    if (!_nameFocusNode.hasFocus && !_bioFocusNode.hasFocus) return;
    _ensureVisibleTimer = Timer(
      _keyboardSettleDelay,
      _scrollFocusedFieldIntoView,
    );
  }

  void _scrollFocusedFieldIntoView() {
    final FocusNode focusedNode;
    final GlobalKey fieldKey;
    if (_nameFocusNode.hasFocus) {
      focusedNode = _nameFocusNode;
      fieldKey = _nameFieldKey;
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
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _nameFocusNode.dispose();
    _bioFocusNode.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.initial != null;
  bool get _nameValid => _nameCtrl.text.trim().isNotEmpty;
  bool get _bioValid => _bioCtrl.text.trim().isNotEmpty;
  bool get _avatarValid =>
      _avatarObjectKey != null || (_avatarUrl != null && _isEdit);
  bool get _canSave => _nameValid && _bioValid && _avatarValid;

  Future<void> _pickAndUploadAvatar() async {
    final l10n = context.l10n;
    final picked = await ImagePickerService.pickAndCropImage(
      context: context,
      toolbarTitle: l10n.createDramaRoleAvatarCropTitle,
      ratioX: 1,
      ratioY: 1,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _isUploadingAvatar = true;
      _avatarProgress = 0;
      _localAvatarPath = picked.path;
      _avatarUrl = null;
    });
    final result = await ref
        .read(createDramaControllerProvider.notifier)
        .uploadRoleAvatar(
          filePath: picked.path,
          l10n: l10n,
          onProgress: (p) {
            if (mounted) setState(() => _avatarProgress = p);
          },
        );
    if (!mounted) return;
    result.when(
      success: (file) {
        setState(() {
          _isUploadingAvatar = false;
          _avatarObjectKey = file.objectKey;
          _avatarUrl = file.publicUrl;
        });
      },
      failure: (error) {
        setState(() {
          _isUploadingAvatar = false;
          _avatarObjectKey = null;
        });
        StoryToast.error(context, context.l10nError(error));
      },
    );
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!_nameValid || !_bioValid || _isUploadingAvatar) return;
    final draft = DramaRoleDraft(
      id: widget.initial?.id ?? '',
      name: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      avatarObjectKey: _avatarObjectKey,
      localAvatarPath: _localAvatarPath,
      avatarUrl: _avatarUrl,
      sortNo: widget.initial?.sortNo ?? 0,
    );
    final notifier = ref.read(createDramaControllerProvider.notifier);
    if (_isEdit) {
      notifier.updateRole(draft);
    } else {
      notifier.addRole(draft);
    }
    Navigator.of(context).pop();
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
                StorySpacing.base,
                StorySpacing.screenHorizontal,
                StorySpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAvatarPicker(theme),
                  const SizedBox(height: StorySpacing.base),
                  StoryTextField(
                    key: _nameFieldKey,
                    label: l10n.createDramaRoleNameLabel,
                    controller: _nameCtrl,
                    focusNode: _nameFocusNode,
                    hint: l10n.createDramaRoleNameHint,
                    labelStyle: StoryTextStyles.labelLarge(
                      color: StoryColors.foregroundOf(brightness),
                    ),
                  ),
                  if (_submitted && !_nameValid)
                    Padding(
                      padding: const EdgeInsets.only(top: StorySpacing.xs),
                      child: Text(
                        l10n.createDramaRoleNameRequired,
                        style: StoryTextStyles.caption(
                          color: StoryColors.destructive,
                        ),
                      ),
                    ),
                  const SizedBox(height: StorySpacing.base),
                  _BioField(
                    key: _bioFieldKey,
                    controller: _bioCtrl,
                    focusNode: _bioFocusNode,
                    label: l10n.createDramaRoleBioLabel,
                    hint: l10n.createDramaRoleBioHint,
                  ),
                  if (_submitted && !_bioValid)
                    Padding(
                      padding: const EdgeInsets.only(top: StorySpacing.xs),
                      child: Text(
                        l10n.createDramaRoleBioRequired,
                        style: StoryTextStyles.caption(
                          color: StoryColors.destructive,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 操作按钮固定在底部，键盘弹出时仍始终可见。
          _buildFooter(theme),
          SizedBox(
            height: StorySpacing.md + MediaQuery.paddingOf(context).bottom,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Brightness brightness) {
    final l10n = context.l10n;
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
            _isEdit
                ? l10n.createDramaRoleEditTitle
                : l10n.createDramaRoleAddTitle,
            style: StoryTextStyles.headingMedium(
              color: StoryColors.foregroundOf(brightness),
            ),
          ),
        ),
      ],
    );
  }

  /// 头像选择区：192×160 圆角方框 + 「上传头像」胶囊按钮，整体居中。
  Widget _buildAvatarPicker(ThemeData theme) {
    final brightness = theme.brightness;
    final l10n = context.l10n;
    return Column(
      children: [
        GestureDetector(
          onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
          child: Container(
            width: 192,
            height: 160,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StoryColors.mutedOf(brightness),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: StoryColors.borderOf(brightness)),
            ),
            child: _buildAvatarContent(brightness),
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
    if (_avatarUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: _avatarUrl!,
            fit: BoxFit.cover,
            memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
              context,
              StoryImageCache.avatarEdit,
            ),
            placeholder: (_, _) => Center(child: _buildAvatarProgress()),
            errorWidget: (_, _, _) => Icon(
              Icons.person,
              size: 80,
              color: StoryColors.mutedForegroundOf(brightness),
            ),
          ),
        ],
      );
    }
    if (_isUploadingAvatar) {
      return Center(child: _buildAvatarProgress());
    }
    return Icon(
      Icons.person,
      size: 80,
      color: StoryColors.mutedForegroundOf(brightness),
    );
  }

  Widget _buildAvatarProgress() {
    return SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(
        value: _avatarProgress > 0 ? _avatarProgress : null,
        strokeWidth: 2.5,
        color: StoryColors.brandTeal,
      ),
    );
  }

  /// 底部操作栏：取消（描边）+ 保存（深色主按钮），左右等分。
  Widget _buildFooter(ThemeData theme) {
    final brightness = theme.brightness;
    final l10n = context.l10n;
    final isLight = brightness == Brightness.light;
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
              onTap: () => Navigator.of(context).pop(),
              background: Colors.transparent,
              foreground: StoryColors.foregroundOf(brightness),
              borderColor: StoryColors.dividerOf(brightness),
            ),
          ),
          const SizedBox(width: StorySpacing.md),
          Expanded(
            child: _FooterButton(
              label: l10n.createDramaRoleSave,
              onTap: (_isUploadingAvatar || !_canSave) ? null : _submit,
              loading: _isUploadingAvatar,
              background: _canSave
                  ? (isLight
                        ? StoryColors.privyLightNormal
                        : StoryColors.privyDarkNormal)
                  : StoryColors.mutedOf(brightness),
              foreground: _canSave
                  ? (isLight
                        ? StoryColors.privyLightForeground
                        : StoryColors.privyDarkForeground)
                  : StoryColors.buttonDisabledForeground,
            ),
          ),
        ],
      ),
    );
  }
}

/// 底部操作栏按钮：12px 圆角，可选 1.5px 描边，与设计稿一致。
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

class _BioField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;

  const _BioField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: StoryTextStyles.labelLarge(
            color: StoryColors.foregroundOf(theme.brightness),
          ),
        ),
        const SizedBox(height: StorySpacing.xs),
        Stack(
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 4,
              maxLength: 500,
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
              bottom: 10,
              right: StorySpacing.md,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, _) {
                  return Text(
                    '${value.text.length}/500',
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
