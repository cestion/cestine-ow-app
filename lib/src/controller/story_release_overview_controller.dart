import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../provider/app_providers.dart';
import '../repositories/finance_dashboard_repository.dart';
import 'story_controller_mixin.dart';
import 'story_release_overview_state.dart';

/// STORY 释放概览 Tab 的独立 Controller。
///
/// 「近期挖矿释放」二级 Tab 拉取 `FinanceDashboardRepository.listWeeklyRewards()`
/// 前 [previewCount] 条用于本 Tab 的预览列表，完整列表见 `StoryReleaseHistoryPage`。
/// 「STORY 总量分配」二级 Tab 暂无设计稿/接口，维持占位展示。
class StoryReleaseOverviewController extends Notifier<StoryReleaseOverviewState>
    with StoryControllerMixin<StoryReleaseOverviewState> {
  static const int previewCount = 5;

  late FinanceDashboardRepository _repo;

  @override
  StoryReleaseOverviewState build() {
    _repo = ref.read(financeDashboardRepositoryProvider);
    return const StoryReleaseOverviewState();
  }

  @override
  StoryReleaseOverviewState copyWithLoadingState({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return state.copyWith(
      isLoading: isLoading,
      lastError: lastError,
      clearLastError: clearLastError,
    );
  }

  /// 切换二级 Tab；首次进入「近期挖矿释放」时才拉取数据。
  void selectTab(int index) {
    if (state.selectedTab == index) return;
    state = state.copyWith(selectedTab: index);
    if (index == StoryReleaseTab.miningRelease &&
        state.recentReleases.isEmpty) {
      refresh();
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearLastError: true);
    final result = await _repo.listWeeklyRewards(pageSize: previewCount);
    if (!ref.mounted) return;
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        recentReleases: result.dataOrNull?.list ?? const [],
      );
    } else {
      state = state.copyWith(isLoading: false, lastError: result.errorOrNull);
    }
  }
}
