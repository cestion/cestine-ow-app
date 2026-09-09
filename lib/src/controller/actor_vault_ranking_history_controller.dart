import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/finance_dashboard_repository.dart';
import 'actor_vault_ranking_history_state.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';

/// 演员 IP 金库排行「查看更多」完整列表页 Controller：下拉刷新 + 游标分页加载。
class ActorVaultRankingHistoryController
    extends Notifier<ActorVaultRankingHistoryState>
    with PaginationMixin<ActorVaultRankingItem, ActorVaultRankingHistoryState> {
  late FinanceDashboardRepository _repo;

  @override
  ActorVaultRankingHistoryState build() {
    _repo = ref.read(financeDashboardRepositoryProvider);
    return const ActorVaultRankingHistoryState();
  }

  @override
  PaginationState<ActorVaultRankingItem> get pagination => state.pagination;

  @override
  bool get isLoading => state.isLoading;

  @override
  void setPaginationState(
    PaginationState<ActorVaultRankingItem> pagination, {
    bool? isLoading,
  }) {
    state = state.copyWith(pagination: pagination, isLoading: isLoading);
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error);
  }

  @override
  Future<Result<PageDto<ActorVaultRankingItem>>> fetchPage({String? mark}) {
    return _repo.getActorVaultRanking(mark: mark);
  }
}
