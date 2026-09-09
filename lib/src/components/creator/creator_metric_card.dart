import 'package:flutter/material.dart';

import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../widgets/story_loading.dart';

/// Metric card for creator overview section.
///
/// Matches design (node 5792:81172): rounded-12, px-16 py-10,
/// centered content, gap-4, 12px title / 18px bold value.
class CreatorMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isLoading;

  const CreatorMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.base,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: StoryColors.cardOf(theme.brightness),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              letterSpacing: 0.04,
              color: StoryColors.mutedForegroundOf(theme.brightness),
            ),
          ),
          const SizedBox(height: StorySpacing.xs),
          if (isLoading)
            const StoryLoading.inline()
          else
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 26 / 18,
                letterSpacing: -0.04,
                color: StoryColors.foregroundOf(theme.brightness),
              ),
            ),
        ],
      ),
    );
  }
}
