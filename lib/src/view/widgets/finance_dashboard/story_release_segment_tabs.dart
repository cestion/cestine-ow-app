import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_text_styles.dart';

/// STORY 释放概览二级导航：STORY 总量分配 / 近期挖矿释放（Figma node
/// 6312:98079）。选项宽度跟随文案，文案过长时支持水平滑动。
class StoryReleaseSegmentTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const StoryReleaseSegmentTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final labels = [
      l10n.storyReleaseTabAllocation,
      l10n.storyReleaseTabMiningRelease,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Padding(
            padding: EdgeInsets.only(
              right: index == labels.length - 1 ? 0 : 20,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: StoryColors.actorHeroBadgeBgOf(theme.brightness),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  labels[index],
                  maxLines: 1,
                  softWrap: false,
                  style: selected
                      ? StoryTextStyles.titleMedium(
                          color: StoryColors.foregroundOf(theme.brightness),
                        ).copyWith(height: 20 / 14)
                      : StoryTextStyles.bodyMedium(
                          color: StoryColors.mutedForegroundOf(
                            theme.brightness,
                          ),
                        ).copyWith(height: 20 / 14),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
