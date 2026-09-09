import 'package:flutter/material.dart';

import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../widgets/widgets.dart';

class CreatorActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const CreatorActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor = StoryColors.brandTeal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StoryCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: StoryRadius.brMd,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: StorySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: StoryTextStyles.headingMedium()),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: StoryTextStyles.bodySmall(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: StoryColors.lightMutedForeground,
            size: 20,
          ),
        ],
      ),
    );
  }
}
