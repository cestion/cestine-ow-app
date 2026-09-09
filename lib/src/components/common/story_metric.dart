import 'package:flutter/material.dart';

import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';

/// A compact label-value metric display.
class StoryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const StoryMetric({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: StoryTextStyles.caption()),
      const SizedBox(height: StorySpacing.xxs),
      Text(
        value,
        style: StoryTextStyles.labelMedium(
          color:
              color ?? StoryColors.foregroundOf(Theme.of(context).brightness),
        ),
      ),
    ],
  );
}

/// An expanded label-value metric that takes available width.
class StoryMetricExpanded extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const StoryMetricExpanded({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: StoryTextStyles.caption()),
        const SizedBox(height: StorySpacing.xxs),
        Text(
          value,
          style: StoryTextStyles.labelMedium(
            color:
                color ?? StoryColors.foregroundOf(Theme.of(context).brightness),
          ),
        ),
      ],
    ),
  );
}
