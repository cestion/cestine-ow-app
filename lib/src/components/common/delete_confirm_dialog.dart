import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';

const _trashAsset = 'assets/watch_history/trash.svg';
const _iconColor = Color(0xFFE50815);
const _iconBackground = Color(0x1AFE0A3B);

/// Generic delete confirmation dialog with cancel/confirm actions.
///
/// Reusable across features — keeps the original required API while allowing
/// callers to add the optional supporting [message] and [confirmLabel].
class DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String? confirmLabel;
  final bool isDeleting;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const DeleteConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel,
    required this.isDeleting,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final surface = StoryColors.createDramaPageSurfaceOf(brightness);
    final confirmBackground = brightness == Brightness.dark
        ? StoryColors.darkForeground
        : StoryColors.darkButtonBg;
    final confirmForeground = StoryColors.whiteToDarkOf(brightness);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        key: const ValueKey<String>('deleteConfirmDialog.surface'),
        width: 343,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          color: _iconBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SvgPicture.asset(
                            _trashAsset,
                            key: const ValueKey<String>(
                              'deleteConfirmDialog.icon',
                            ),
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              _iconColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (message != null && message!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        key: const ValueKey<String>(
                          'deleteConfirmDialog.cancel',
                        ),
                        label: l10n.commonCancel,
                        onTap: isDeleting ? null : onCancel,
                        backgroundColor: surface,
                        borderColor: StoryColors.dividerOf(brightness),
                        foregroundColor: foreground,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogButton(
                        key: const ValueKey<String>(
                          'deleteConfirmDialog.confirm',
                        ),
                        label: confirmLabel ?? l10n.commonConfirm,
                        onTap: isDeleting ? null : onConfirm,
                        backgroundColor: confirmBackground,
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
  const _DialogButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: isLoading
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
                      color: foregroundColor,
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
