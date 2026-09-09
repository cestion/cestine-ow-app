import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../profile/profile_colors.dart';

const _userMinusIcon = 'assets/follow/user_minus.svg';

/// Figma unfollow confirm dialog (`358:95327` / light counterpart).
class UnfollowConfirmDialog extends StatelessWidget {
  final String handle;

  const UnfollowConfirmDialog({super.key, required this.handle});

  static Future<bool?> show(
    BuildContext context, {
    required String? displayName,
  }) {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (_) => UnfollowConfirmDialog(
        handle: _formatHandle(
          displayName,
          fallback: l10n.followUserHandleFallback,
        ),
      ),
    );
  }

  static String _formatHandle(String? displayName, {required String fallback}) {
    final raw = displayName?.trim() ?? '';
    if (raw.isEmpty) return fallback;
    return raw.startsWith('@') ? raw : '@$raw';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final confirmBg = ProfileColors.followPrimaryBg(brightness);
    final confirmFg = ProfileColors.followPrimaryFg(brightness);
    final border = StoryColors.dividerOf(brightness);

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
                      color: Color(0x1AFE0A3B),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      _userMinusIcon,
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(height: StorySpacing.base),
                  Text(
                    l10n.followUnfollowTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.followUnfollowMessage(handle),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _UnfollowDialogButton(
                    label: l10n.followUnfollowNo,
                    onTap: () => Navigator.of(context).pop(false),
                    backgroundColor: Colors.transparent,
                    borderColor: border,
                    foregroundColor: fg,
                    borderWidth: 1.5,
                  ),
                ),
                const SizedBox(width: StorySpacing.md),
                Expanded(
                  child: _UnfollowDialogButton(
                    label: l10n.followUnfollowYes,
                    onTap: () => Navigator.of(context).pop(true),
                    backgroundColor: confirmBg,
                    borderColor: confirmBg,
                    foregroundColor: confirmFg,
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

class _UnfollowDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final double borderWidth;

  const _UnfollowDialogButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    this.borderWidth = 1,
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
                child: Text(
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
