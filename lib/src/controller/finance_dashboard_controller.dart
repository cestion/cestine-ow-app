import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import 'finance_dashboard_state.dart';
import 'story_controller_mixin.dart';

/// 平台资金看板顶部汇总 Controller：仅负责获取 USDC 总收入 + STORY 总释放。
///
/// 每个 TabView 子页面（USDC 收入明细 / 金库资金沉淀 / STORY 释放概览）拥有独立的
/// Controller，见 [usdc_income_detail_controller.dart]、[vault_funds_controller.dart]、
/// [story_release_overview_controller.dart]。
class FinanceDashboardController extends Notifier<FinanceDashboardState>
    with StoryControllerMixin<FinanceDashboardState> {
  @override
  FinanceDashboardState build() => const FinanceDashboardState();

  @override
  FinanceDashboardState copyWithLoadingState({
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
    final repo = ref.read(financeDashboardRepositoryProvider);
    state = state.copyWith(isLoading: true, clearLastError: true);

    final results = await Future.wait<Object>([
      repo.getIncomeStats(),
      repo.getTotalReleased(),
    ]);
    if (!ref.mounted) return;

    final incomeStatsResult = results[0] as Result<IncomeStats>;
    final totalReleasedResult = results[1] as Result<double>;

    if (incomeStatsResult.isSuccess && totalReleasedResult.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        totalUsdcIncome: incomeStatsResult.dataOrNull?.totalAmount ?? 0,
        totalStoryReleased: totalReleasedResult.dataOrNull ?? 0,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        lastError:
            incomeStatsResult.errorOrNull ?? totalReleasedResult.errorOrNull,
      );
    }
  }
}
