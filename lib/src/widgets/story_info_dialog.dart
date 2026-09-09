import 'package:flutter/material.dart';

import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';

/// Info / help dialog with a title, optional subtitle, scrollable body, and a
/// single dismiss action. Used for metric explanations and similar read-only
/// content.
class StoryInfoDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final String actionLabel;
  final VoidCallback? onClose;
  final double maxContentHeightFraction;
  final EdgeInsets insetPadding;

  const StoryInfoDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actionLabel,
    this.subtitle,
    this.onClose,
    this.maxContentHeightFraction = 0.55,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: StorySpacing.xxxl,
    ),
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required Widget content,
    required String actionLabel,
    String? subtitle,
    double maxContentHeightFraction = 0.55,
    EdgeInsets insetPadding = const EdgeInsets.symmetric(
      horizontal: StorySpacing.xxxl,
    ),
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => StoryInfoDialog(
        title: title,
        subtitle: subtitle,
        content: content,
        actionLabel: actionLabel,
        maxContentHeightFraction: maxContentHeightFraction,
        insetPadding: insetPadding,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _close(BuildContext context) {
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Dialog(
      backgroundColor: StoryColors.cardOf(brightness),
      elevation: 0,
      insetPadding: insetPadding,
      shape: const RoundedRectangleBorder(borderRadius: StoryRadius.brXl),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: StoryTextStyles.titleMedium(
                color: StoryColors.foregroundOf(brightness),
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: StorySpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: StoryTextStyles.caption(
                  color: StoryColors.mutedForegroundOf(brightness),
                ),
              ),
            ],
            const SizedBox(height: StorySpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.sizeOf(context).height *
                    maxContentHeightFraction,
              ),
              child: SingleChildScrollView(child: content),
            ),
            const SizedBox(height: StorySpacing.md),
            OutlinedButton(
              onPressed: () => _close(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: BorderSide(color: StoryColors.borderOf(brightness)),
                shape: const RoundedRectangleBorder(
                  borderRadius: StoryRadius.brXl,
                ),
              ),
              child: Text(
                actionLabel,
                style: StoryTextStyles.bodyMedium(
                  color: StoryColors.foregroundOf(brightness),
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Teal-tinted panel for info dialog body sections.
class StoryInfoPanel extends StatelessWidget {
  final Widget child;

  const StoryInfoPanel({super.key, required this.child});

  static Color highlightSurface(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0x1401BAB2)
        : StoryColors.actorSignPriceBannerBg;
  }

  static Color highlightBorder(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0x3D01BAB2)
        : StoryColors.actorSignPriceBannerBorder;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlightSurface(brightness),
        borderRadius: StoryRadius.brXl,
        border: Border.all(color: highlightBorder(brightness)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.base,
          vertical: StorySpacing.md,
        ),
        child: child,
      ),
    );
  }
}

/// Label / value row inside [StoryInfoPanel].
class StoryInfoDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const StoryInfoDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderColor = StoryInfoPanel.highlightBorder(brightness);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: StorySpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: StoryTextStyles.bodySmall(
                    color: StoryColors.mutedForegroundOf(brightness),
                  ),
                ),
              ),
              const SizedBox(width: StorySpacing.base),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: StoryTextStyles.bodySmall(
                    color: StoryColors.brandTeal,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 1, color: borderColor),
      ],
    );
  }
}
