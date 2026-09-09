import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/finance_dashboard_repository.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';
import 'usdc_ledger_history_state.dart';

/// USDC 收入流水「查看更多」完整列表页 Controller：下拉刷新 + 游标分页加载。
class UsdcLedgerHistoryController extends Notifier<UsdcLedgerHistoryState>
    with PaginationMixin<LedgerItem, UsdcLedgerHistoryState> {
  late FinanceDashboardRepository _repo;

  @override
  UsdcLedgerHistoryState build() {
    _repo = ref.read(financeDashboardRepositoryProvider);
    return const UsdcLedgerHistoryState();
  }

  @override
  PaginationState<LedgerItem> get pagination => state.pagination;

  @override
  bool get isLoading => state.isLoading;

  @override
  void setPaginationState(
    PaginationState<LedgerItem> pagination, {
    bool? isLoading,
  }) {
    state = state.copyWith(pagination: pagination, isLoading: isLoading);
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error);
  }

  @override
  Future<Result<PageDto<LedgerItem>>> fetchPage({String? mark}) {
    return _repo.getLedger(mark: mark);
  }
}
