import 'package:flutter/material.dart';

import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';

/// A branded gradient hero card with title and subtitle.
///
/// Wraps a [Container] with [StoryColors.brandGradient] background and
/// rounded corners, containing a [title] and [subtitle] in a vertical column.
///
/// Replaces the identical hero-banner pattern duplicated across
/// about, creators, and create-actor pages.
class StoryGradientHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double spacing;

  const StoryGradientHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.padding = const EdgeInsets.all(StorySpacing.xl),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(StoryRadius.xxlValue),
    ),
    this.titleStyle,
    this.subtitleStyle,
    this.spacing = StorySpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: StoryColors.brandGradient,
        borderRadius: borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                titleStyle ??
                StoryTextStyles.displayMedium(color: StoryColors.onOverlay),
          ),
          SizedBox(height: spacing),
          Text(
            subtitle,
            style:
                subtitleStyle ??
                StoryTextStyles.bodyMedium(color: StoryColors.onOverlayMuted),
          ),
        ],
      ),
    );
  }
}
