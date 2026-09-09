import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controller/story_release_overview_state.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import 'recent_mining_release_section.dart';
import 'story_allocation_section.dart';
import 'story_release_segment_tabs.dart';

/// STORY 释放概览 Tab（Figma node 6312:98138）。
///
/// 顶部为「STORY 总量分配 / 近期挖矿释放」二级导航（[StoryReleaseSegmentTabs]，
/// 非 TabBar/TabController 实现），切换时若目标数据尚未加载会展示加载 Widget；
/// 「近期挖矿释放」内容为最多 5 条预览列表（[RecentMiningReleaseSection]），
/// 数据来自 [storyReleaseOverviewControllerProvider]。「STORY 总量分配」内容为
/// [StoryAllocationSection]，数据来自 [globalConfigProvider] 中的
/// [InitConfig.mining]。
class StoryReleaseOverviewTab extends ConsumerStatefulWidget {
  const StoryReleaseOverviewTab({super.key});

  @override
  ConsumerState<StoryReleaseOverviewTab> createState() =>
      _StoryReleaseOverviewTabState();
}

class _StoryReleaseOverviewTabState
    extends ConsumerState<StoryReleaseOverviewTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyReleaseOverviewControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyReleaseOverviewControllerProvider);
    final controller = ref.read(
      storyReleaseOverviewControllerProvider.notifier,
    );

    return ListView(
      padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
      children: [
        StoryReleaseSegmentTabs(
          selectedIndex: state.selectedTab,
          onChanged: controller.selectTab,
        ),
        const SizedBox(height: StorySpacing.base),
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: StorySpacing.xxl),
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
        else if (state.selectedTab == StoryReleaseTab.allocation)
          const StoryAllocationSection()
        else
          RecentMiningReleaseSection(
            items: state.recentReleases,
            isLoading: state.isLoading,
          ),
      ],
    );
  }
}
