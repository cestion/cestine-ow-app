import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/profile/profile_colors.dart';
import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';

const _referralIcon = 'assets/drawer/referral.svg';

/// Figma 绑定邀请码弹窗 — 亮色 `1285:128292` / 暗色 `1285:128220`。
///
/// [prompt] 为 true 时展示「跳过后可在邀请页绑定」副标题（登录后引导场景）。
class InviteBindCodeDialog extends StatefulWidget {
  final Future<bool> Function(String code) onSubmit;
  final bool prompt;

  const InviteBindCodeDialog({
    super.key,
    required this.onSubmit,
    this.prompt = false,
  });

  /// 返回 `true` 表示绑定成功；`false` 表示取消；`null` 表示系统关闭。
  static Future<bool?> show(
    BuildContext context, {
    required Future<bool> Function(String code) onSubmit,
    bool prompt = false,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => InviteBindCodeDialog(onSubmit: onSubmit, prompt: prompt),
    );
  }

  @override
  State<InviteBindCodeDialog> createState() => _InviteBindCodeDialogState();
}

class _InviteBindCodeDialogState extends State<InviteBindCodeDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final ok = await widget.onSubmit(code);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final border = StoryColors.dividerOf(brightness);
    final confirmBg = ProfileColors.followPrimaryBg(brightness);
    final confirmFg = ProfileColors.followPrimaryFg(brightness);
    final inputBg = brightness == Brightness.dark
        ? ProfileColors.darkThirdlySurface
        : StoryColors.lightMuted;
    final placeholder = StoryColors.mutedForegroundOf(brightness);

    return Dialog(
      backgroundColor: StoryColors.backgroundOf(brightness),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: StorySpacing.sm),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0x17F4D900),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      _referralIcon,
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFF4D900),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: StorySpacing.base),
                  Text(
                    l10n.inviteBindCode,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  if (widget.prompt) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.inviteBindCodePromptHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        color: placeholder,
                      ),
                    ),
                  ],
                  const SizedBox(height: StorySpacing.base),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border, width: 0.5),
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      style: TextStyle(
                        fontSize: 15,
                        height: 22 / 15,
                        color: fg,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.inviteBindCodePlaceholder,
                        hintStyle: TextStyle(
                          fontSize: 15,
                          height: 22 / 15,
                          color: placeholder,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _InviteBindDialogButton(
                    label: l10n.commonCancel,
                    onTap: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    backgroundColor: Colors.transparent,
                    borderColor: border,
                    foregroundColor: fg,
                    borderWidth: 1.5,
                  ),
                ),
                const SizedBox(width: StorySpacing.md),
                Expanded(
                  child: _InviteBindDialogButton(
                    label: l10n.inviteBindConfirm,
                    onTap: _isSubmitting ? null : _submit,
                    backgroundColor: confirmBg,
                    borderColor: confirmBg,
                    foregroundColor: confirmFg,
                    loading: _isSubmitting,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteBindDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final double borderWidth;
  final bool loading;

  const _InviteBindDialogButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    this.borderWidth = 1,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foregroundColor,
                        ),
                      )
                    : Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w700,
                          color: foregroundColor,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
