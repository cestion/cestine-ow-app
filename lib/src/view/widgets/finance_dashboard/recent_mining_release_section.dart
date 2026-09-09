import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../foundation/navigator.dart';
import '../../../routes/route_names.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import 'weekly_reward_list_item.dart';

/// 「近期挖矿释放」卡片：最多展示 5 条，末尾提供「查看更多」跳转到完整
/// 历史列表页（Figma node 6312:98138）。
class RecentMiningReleaseSection extends StatelessWidget {
  final List<WeeklyRewardItem> items;
  final bool isLoading;

  const RecentMiningReleaseSection({
    super.key,
    required this.items,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StorySpacing.base),
      decoration: BoxDecoration(
        color: StoryColors.cardOf(theme.brightness),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.storyReleaseTabMiningRelease,
                style: StoryTextStyles.titleMedium(
                  color: StoryColors.foregroundOf(theme.brightness),
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              OutlinedButton(
                onPressed: () => context.storyPush(RouteNames.storyReleaseHistory),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: StoryColors.dividerOf(theme.brightness),
                  ),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.financeDashboardViewMore,
                  style: StoryTextStyles.labelMedium(
                    color: StoryColors.foregroundOf(theme.brightness),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: StorySpacing.sm),
          if (isLoading && items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: StorySpacing.xl),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: StoryColors.brandTeal,
                  ),
                ),
              ),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: StorySpacing.xl),
              child: Center(
                child: Text(
                  l10n.searchNoData,
                  style: StoryTextStyles.bodySmall(
                    color: StoryColors.mutedForegroundOf(theme.brightness),
                  ),
                ),
              ),
            )
          else
            ...List.generate(items.length, (index) {
              return WeeklyRewardListItem(
                item: items[index],
                showDivider: index != items.length - 1,
              );
            }),
        ],
      ),
    );
  }
}
