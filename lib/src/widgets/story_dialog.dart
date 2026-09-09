import 'package:flutter/material.dart';

import '../l10n/story_l10n.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';

/// Centered confirmation dialog with an outlined cancel button and a filled
/// confirm button.
///
/// The confirm button is filled with [confirmColor] (falling back to the
/// theme foreground). While [isLoading] is true both buttons are disabled and
/// the confirm button shows a spinner.
class StoryDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  final String? message;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool isLoading;
  final Color? confirmColor;

  const StoryDialog({
    super.key,
    required this.title,
    this.content,
    this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    this.onCancel,
    this.onConfirm,
    this.isLoading = false,
    this.confirmColor,
  });

  /// Show a single-button acknowledgement dialog (no cancel).
  ///
  /// Matches Figma login consent prompt: title + body + one full-width confirm.
  static Future<bool?> acknowledge({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    String? confirmLabel,
  }) {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final brightness = Theme.of(ctx).brightness;
        return Dialog(
          backgroundColor: StoryColors.backgroundOf(brightness),
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: StorySpacing.base,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(StorySpacing.base),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style:
                      StoryTextStyles.titleMedium(
                        color: StoryColors.foregroundOf(brightness),
                      ).copyWith(
                        fontSize: 18,
                        height: 26 / 18,
                        letterSpacing: -0.04,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (content != null || message != null) ...[
                  const SizedBox(height: StorySpacing.xl),
                  content ??
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: StoryTextStyles.bodyMedium(
                          color: StoryColors.mutedForegroundOf(brightness),
                        ),
                      ),
                ],
                const SizedBox(height: StorySpacing.xl),
                _DialogButton(
                  label: confirmLabel ?? l10n.commonConfirm,
                  onTap: () => Navigator.of(ctx).pop(true),
                  // Figma: both themes use dark fill (#212225) + white label.
                  backgroundColor: StoryColors.darkButtonBg,
                  borderColor: StoryColors.darkButtonBg,
                  foregroundColor: StoryColors.onOverlay,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show a styled centered confirmation dialog.
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Color? confirmColor,
    bool isLoading = false,
  }) {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => StoryDialog(
        title: title,
        content: content,
        message: message,
        cancelLabel: cancelLabel ?? l10n.commonCancel,
        confirmLabel: confirmLabel ?? l10n.commonConfirm,
        onCancel: () {
          Navigator.of(ctx).pop(false);
          onCancel?.call();
        },
        onConfirm: () {
          Navigator.of(ctx).pop(true);
          onConfirm?.call();
        },
        isLoading: isLoading,
        confirmColor: confirmColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Dialog(
      backgroundColor: StoryColors.backgroundOf(brightness),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: StorySpacing.xxxl),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          StorySpacing.base,
          StorySpacing.xl,
          StorySpacing.base,
          StorySpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: StoryTextStyles.titleMedium(
                color: StoryColors.foregroundOf(brightness),
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            if (content != null || message != null) ...[
              const SizedBox(height: StorySpacing.md),
              content ??
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: StoryTextStyles.bodyMedium(
                      color: StoryColors.mutedForegroundOf(brightness),
                    ),
                  ),
            ],
            const SizedBox(height: StorySpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: cancelLabel,
                    onTap: isLoading ? null : onCancel,
                    backgroundColor: StoryColors.backgroundOf(brightness),
                    borderColor: StoryColors.dividerOf(brightness),
                    foregroundColor: StoryColors.foregroundOf(brightness),
                  ),
                ),
                const SizedBox(width: StorySpacing.md),
                Expanded(
                  child: _DialogButton(
                    label: confirmLabel,
                    onTap: isLoading ? null : onConfirm,
                    backgroundColor:
                        confirmColor ?? StoryColors.foregroundOf(brightness),
                    borderColor:
                        confirmColor ?? StoryColors.foregroundOf(brightness),
                    foregroundColor: confirmColor != null
                        ? StoryColors.onOverlay
                        : StoryColors.backgroundOf(brightness),
                    loading: isLoading,
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

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final bool loading;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.xxl,
          vertical: StorySpacing.md,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: borderColor),
        ),
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
                style: StoryTextStyles.labelLarge(
                  color: foregroundColor,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
