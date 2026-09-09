import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';

const _maxVideoNameLength = 15;

String _displayVideoName(String videoName) {
  final trimmedName = videoName.trim();
  if (trimmedName.isEmpty) return '-';

  final characters = trimmedName.characters;
  if (characters.length <= _maxVideoNameLength) return trimmedName;

  return '${characters.take(_maxVideoNameLength).join()}…';
}

/// Video deletion confirmation dialog matching Figma node `557:104031`.
class DeleteVideoConfirmDialog extends StatelessWidget {
  final String videoName;
  final bool isDeleting;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const DeleteVideoConfirmDialog({
    super.key,
    required this.videoName,
    required this.isDeleting,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final confirmBackground = StoryColors.actorSignSheetConfirmBgOf(brightness);
    final confirmForeground = StoryColors.actorSignSheetConfirmFgOf(brightness);
    final displayName = _displayVideoName(videoName);

    return PopScope(
      canPop: !isDeleting,
      child: Dialog(
        backgroundColor: StoryColors.cardOf(brightness),
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: ConstrainedBox(
          key: const ValueKey<String>('delete-video-confirm-dialog'),
          constraints: const BoxConstraints(maxWidth: 343),
          child: Padding(
            padding: const EdgeInsets.all(StorySpacing.base),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: StorySpacing.sm),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        "assets/drama/delete_c.svg",
                        key: const ValueKey<String>(
                          'delete-video-confirm-icon',
                        ),
                        width: 44,
                        height: 44,
                      ),
                      const SizedBox(height: StorySpacing.base),
                      Text(
                        l10n.creatorDeleteVideoConfirmTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: StorySpacing.xs),
                      Text(
                        l10n.creatorDeleteVideoConfirmMessage(displayName),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: StorySpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        key: const ValueKey<String>('delete-video-confirm-no'),
                        label: l10n.commonNo,
                        onPressed: isDeleting ? null : onCancel,
                        backgroundColor: Colors.transparent,
                        borderColor: StoryColors.dividerOf(brightness),
                        foregroundColor: foreground,
                        borderWidth: 1.5,
                      ),
                    ),
                    const SizedBox(width: StorySpacing.md),
                    Expanded(
                      child: _DialogButton(
                        key: const ValueKey<String>('delete-video-confirm-yes'),
                        label: l10n.commonYes,
                        onPressed: isDeleting ? null : onConfirm,
                        backgroundColor: confirmBackground,
                        borderColor: confirmBackground,
                        foregroundColor: confirmForeground,
                        isLoading: isDeleting,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final double borderWidth;
  final bool isLoading;

  const _DialogButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    this.borderWidth = 1,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox.square(
                      dimension: 20,
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
                        color: foregroundColor,
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
