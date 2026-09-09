import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/finance_dashboard_repository.dart';
import 'story_controller_mixin.dart';
import 'vault_funds_state.dart';

/// 金库资金沉淀 Tab 的独立 Controller。
///
/// 拉取 `FinanceDashboardRepository.getActorVaultStats()`（总资金/覆盖演员IP
/// 数量）与 `FinanceDashboardRepository.getActorVaultRanking()`（演员 IP 金库
/// 排行，仅取前 [previewCount] 条用于本 Tab 的预览列表）。
class VaultFundsController extends Notifier<VaultFundsState>
    with StoryControllerMixin<VaultFundsState> {
  static const int previewCount = 10;

  late FinanceDashboardRepository _repo;

  @override
  VaultFundsState build() {
    _repo = ref.read(financeDashboardRepositoryProvider);
    return const VaultFundsState();
  }

  @override
  VaultFundsState copyWithLoadingState({
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
      _repo.getActorVaultStats(),
      _repo.getActorVaultRanking(pageSize: previewCount),
    ]);
    if (!ref.mounted) return;

    final statsResult = results[0] as Result<ActorVaultStats>;
    final rankingResult = results[1] as Result<PageDto<ActorVaultRankingItem>>;

    if (statsResult.isSuccess && rankingResult.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        stats: statsResult.dataOrNull,
        ranking: rankingResult.dataOrNull?.list ?? const [],
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        lastError: statsResult.errorOrNull ?? rankingResult.errorOrNull,
      );
    }
  }
}
