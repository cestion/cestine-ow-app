import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';

/// Reusable empty-state card for lists with no data.
class StoryEmptyCard extends StatelessWidget {
  final String label;
  final double iconSize;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? backgroundColor;

  const StoryEmptyCard({
    super.key,
    required this.label,
    this.iconSize = 88.0,
    this.actionLabel,
    this.onAction,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final listBg =
        backgroundColor ?? StoryColors.actorPlazaListBgOf(brightness);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.xl,
        vertical: StorySpacing.xxl,
      ),
      decoration: BoxDecoration(color: listBg, borderRadius: StoryRadius.brLg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              isDark ? 'assets/common/empty_d.svg' : 'assets/common/empty.svg',
              width: iconSize,
              height: iconSize,
            ),
            const SizedBox(height: StorySpacing.md),
            Text(
              label,
              style: StoryTextStyles.bodyMedium(
                color: StoryColors.mutedForegroundOf(brightness),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: StorySpacing.xl),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(color: theme.colorScheme.outline),
                  shape: const RoundedRectangleBorder(
                    borderRadius: StoryRadius.brSm,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: StorySpacing.base,
                    vertical: StorySpacing.sm,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
