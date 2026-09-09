import 'package:flutter/material.dart';
import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';

class StorySettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const StorySettingTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: StoryRadius.brMd,
      child: Container(
        padding: const EdgeInsets.all(StorySpacing.md),
        margin: const EdgeInsets.only(bottom: StorySpacing.sm),
        decoration: BoxDecoration(
          color: StoryColors.cardOf(theme.brightness),
          borderRadius: StoryRadius.brMd,
          border: Border.all(
            color: StoryColors.borderOf(theme.brightness),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: StoryColors.brandTeal, size: 20),
            const SizedBox(width: StorySpacing.md),
            Expanded(
              child: Text(
                label,
                style: StoryTextStyles.bodyMedium(
                  color: StoryColors.foregroundOf(theme.brightness),
                ),
              ),
            ),
            Text(
              value,
              style: StoryTextStyles.labelMedium(
                color: StoryColors.mutedForegroundOf(theme.brightness),
              ),
            ),
            const SizedBox(width: StorySpacing.sm),
            Icon(
              Icons.chevron_right,
              color: StoryColors.mutedForegroundOf(theme.brightness),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
