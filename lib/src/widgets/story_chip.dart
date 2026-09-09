import 'package:flutter/material.dart';

import '../foundation/story_theme.dart';
import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';

enum StoryChipStyle { brand, info, success, warning, destructive, neutral }

class StoryChip extends StatelessWidget {
  final String label;
  final StoryChipStyle style;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;

  const StoryChip({
    super.key,
    required this.label,
    this.style = StoryChipStyle.neutral,
    this.icon,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.sm,
          vertical: StorySpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? StoryColors.brandTeal.withValues(alpha: 0.12)
              : colors.background,
          borderRadius: StoryRadius.brPill,
          border: selected
              ? Border.all(color: StoryColors.brandTeal.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: colors.foreground),
              const SizedBox(width: StorySpacing.xxs),
            ],
            Text(
              label,
              style: StoryTextStyles.labelSmall(color: colors.foreground),
            ),
          ],
        ),
      ),
    );
  }

  _ChipColors _resolveColors(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<StoryCustomColors>();
    final surfaceMuted = customColors?.surfaceMuted ?? StoryColors.lightMuted;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return switch (style) {
      StoryChipStyle.brand => _ChipColors(
        background: StoryColors.brandTeal.withValues(alpha: 0.12),
        foreground: StoryColors.brandTeal,
      ),
      StoryChipStyle.info => _ChipColors(
        background: StoryColors.info.withValues(alpha: 0.12),
        foreground: StoryColors.info,
      ),
      StoryChipStyle.success => _ChipColors(
        background: StoryColors.success.withValues(alpha: 0.12),
        foreground: StoryColors.success,
      ),
      StoryChipStyle.warning => _ChipColors(
        background: StoryColors.warning.withValues(alpha: 0.12),
        foreground: StoryColors.warning,
      ),
      StoryChipStyle.destructive => _ChipColors(
        background: StoryColors.destructive.withValues(alpha: 0.12),
        foreground: StoryColors.destructive,
      ),
      StoryChipStyle.neutral => _ChipColors(
        background: surfaceMuted,
        foreground: onSurfaceVariant,
      ),
    };
  }
}

class _ChipColors {
  final Color background;
  final Color foreground;

  const _ChipColors({required this.background, required this.foreground});
}
