import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/finance_dashboard_repository.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';
import 'story_release_history_state.dart';

/// 「近期挖矿释放」查看更多完整列表页 Controller：下拉刷新 + 游标分页加载。
class StoryReleaseHistoryController extends Notifier<StoryReleaseHistoryState>
    with PaginationMixin<WeeklyRewardItem, StoryReleaseHistoryState> {
  late FinanceDashboardRepository _repo;

  @override
  StoryReleaseHistoryState build() {
    _repo = ref.read(financeDashboardRepositoryProvider);
    return const StoryReleaseHistoryState();
  }

  @override
  PaginationState<WeeklyRewardItem> get pagination => state.pagination;

  @override
  bool get isLoading => state.isLoading;

  @override
  void setPaginationState(
    PaginationState<WeeklyRewardItem> pagination, {
    bool? isLoading,
  }) {
    state = state.copyWith(pagination: pagination, isLoading: isLoading);
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error);
  }

  @override
  Future<Result<PageDto<WeeklyRewardItem>>> fetchPage({String? mark}) {
    return _repo.listWeeklyRewards(mark: mark);
  }
}
