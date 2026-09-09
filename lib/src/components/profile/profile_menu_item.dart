import 'package:flutter/material.dart';

import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color iconColor;
  final bool showChevron;
  final Widget? trailing;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.subtitle,
    this.onTap,
    this.iconColor = StoryColors.lightMutedForeground,
    this.showChevron = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.base,
          vertical: StorySpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: StorySpacing.md),
            Expanded(child: Text(label, style: StoryTextStyles.titleMedium())),
            if (value != null) ...[
              Text(
                value!,
                style: StoryTextStyles.bodyMedium(
                  color: StoryColors.mutedForegroundOf(theme.brightness),
                ),
              ),
              const SizedBox(width: StorySpacing.xs),
            ],
            if (subtitle != null)
              Text(
                subtitle!,
                style: StoryTextStyles.caption(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ?trailing,
            if (showChevron)
              const Icon(
                Icons.chevron_right,
                color: StoryColors.lightMutedForeground,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
