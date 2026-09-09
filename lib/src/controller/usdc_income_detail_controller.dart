import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/finance_dashboard_repository.dart';
import 'story_controller_mixin.dart';
import 'usdc_income_detail_state.dart';

/// USDC 收入明细 Tab 的独立 Controller。
///
/// 拉取 `FinanceDashboardRepository.getIncomeStats()`（签约费/购买体力费/
/// 合成升级费/手续费/二级版税明细）与 `FinanceDashboardRepository.getLedger()`
/// （近期 USDC 收入流水，仅取前 5 条用于本 Tab 的预览列表）。
class UsdcIncomeDetailController extends Notifier<UsdcIncomeDetailState>
    with StoryControllerMixin<UsdcIncomeDetailState> {
  late FinanceDashboardRepository _repo;

  @override
  UsdcIncomeDetailState build() {
    _repo = ref.read(financeDashboardRepositoryProvider);
    return const UsdcIncomeDetailState();
  }

  @override
  UsdcIncomeDetailState copyWithLoadingState({
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

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearLastError: true);

    final results = await Future.wait<Object>([
      _repo.getIncomeStats(),
      _repo.getLedger(pageSize: 5),
    ]);
    if (!ref.mounted) return;

    final incomeStatsResult = results[0] as Result<IncomeStats>;
    final ledgerResult = results[1] as Result<PageDto<LedgerItem>>;

    if (incomeStatsResult.isSuccess && ledgerResult.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        incomeStats: incomeStatsResult.dataOrNull,
        recentLedger: ledgerResult.dataOrNull?.list ?? const [],
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        lastError: incomeStatsResult.errorOrNull ?? ledgerResult.errorOrNull,
      );
    }
  }
}
