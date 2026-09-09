import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/reward_repository.dart';
import 'income_state.dart';
import 'story_controller_mixin.dart';

class IncomeController extends Notifier<IncomeState>
    with StoryControllerMixin<IncomeState> {
  RewardRepository get _reward => ref.read(rewardRepositoryProvider);
  StreamSubscription<bool>? _authSub;

  @override
  IncomeState build() {
    final authNotifier = ref.read(authControllerProvider.notifier);
    _authSub = authNotifier.authStateChanges.listen((loggedIn) {
      if (!loggedIn) state = const IncomeState();
    });
    ref.onDispose(() => _authSub?.cancel());
    return const IncomeState();
  }

  @override
  IncomeState copyWithLoadingState({
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

  bool get isLoading => state.isLoading;
  String get errorMessage => state.errorMessage;

  Future<void> refreshRewardDetails({
    ListRewardDetailsFilter type = ListRewardDetailsFilter.all,
  }) async {
    if (!ref.read(authControllerProvider).isLoggedIn) return;

    state = state.copyWith(isLoading: true, clearLastError: true);
    final result = await _reward.listRewardDetails(type: type);
    if (!ref.mounted) return;

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        isStoryPageLoading: false,
        rewardDetailPage: result.dataOrNull,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        isStoryPageLoading: false,
        lastError: result.errorOrNull,
      );
    }
  }

  Future<void> loadMoreRewardDetails({
    required ListRewardDetailsFilter type,
  }) async {
    final currentPage = state.rewardDetailPage;
    if (!ref.read(authControllerProvider).isLoggedIn ||
        state.isLoading ||
        state.isStoryPageLoading ||
        currentPage?.hasMore != true) {
      return;
    }

    final mark = int.tryParse(currentPage?.mark ?? '');
    if (mark == null) return;

    state = state.copyWith(isStoryPageLoading: true, clearLastError: true);
    final result = await _reward.listRewardDetails(type: type, mark: mark);
    if (!ref.mounted) return;

    final nextPage = result.dataOrNull;
    if (result.isSuccess && nextPage != null) {
      state = state.copyWith(
        isStoryPageLoading: false,
        rewardDetailPage: RewardDetailPage(
          pageSize: nextPage.pageSize ?? currentPage?.pageSize,
          mark: nextPage.mark ?? currentPage?.mark,
          hasMore: nextPage.hasMore ?? false,
          list: [...?currentPage?.list, ...?nextPage.list],
        ),
      );
    } else {
      state = state.copyWith(
        isStoryPageLoading: false,
        lastError: result.errorOrNull,
      );
    }
  }

  Future<void> loadMoreUsdcIncome() async {
    final currentPage = state.usdcIncomePage;
    if (!ref.read(authControllerProvider).isLoggedIn ||
        state.isLoading ||
        state.isUsdcPageLoading ||
        currentPage?.hasMore != true) {
      return;
    }

    final mark = int.tryParse(currentPage?.mark ?? '');
    if (mark == null) return;

    state = state.copyWith(isUsdcPageLoading: true, clearLastError: true);
    final result = await _reward.getUsdcIncome(mark: mark);
    if (!ref.mounted) return;

    final nextPage = result.dataOrNull;
    if (result.isSuccess && nextPage != null) {
      state = state.copyWith(
        isUsdcPageLoading: false,
        usdcIncomePage: UsdcIncomePage(
          total: currentPage?.total ?? nextPage.total,
          pageSize: nextPage.pageSize ?? currentPage?.pageSize,
          mark: nextPage.mark ?? currentPage?.mark,
          hasMore: nextPage.hasMore ?? false,
          list: [...?currentPage?.list, ...?nextPage.list],
        ),
      );
    } else {
      state = state.copyWith(
        isUsdcPageLoading: false,
        lastError: result.errorOrNull,
      );
    }
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    if (!ref.read(authControllerProvider).isLoggedIn) return;

    final result = await withLoading(() async {
      if (!ref.mounted) return null;
      ref.read(userRepositoryProvider).invalidateBalances();
      final userRepo = ref.read(userRepositoryProvider);
      final results = await Future.wait<Object>([
        _reward.getTotalReward(),
        _reward.getUsdcIncome(),
        _reward.listRewardDetails(),
        userRepo.getBalances(),
        _reward.getWeeklyStats(),
        _reward.getSettlingReward(),
      ]);
      if (!ref.mounted) return null;

      final totalRewardRes = results[0] as Result<TotalReward>;
      final usdcIncomeRes = results[1] as Result<UsdcIncomePage>;
      final rewardDetailRes = results[2] as Result<RewardDetailPage>;
      final balancesRes = results[3] as Result<List<WalletBalance>>;
      final weeklyStatsRes = results[4] as Result<MiningWeeklyStats>;
      final settlingRewardRes = results[5] as Result<SettlingReward>;

      return {
        'totalReward': totalRewardRes.isSuccess
            ? totalRewardRes.dataOrNull
            : state.totalReward,
        'usdcIncomePage': usdcIncomeRes.isSuccess
            ? usdcIncomeRes.dataOrNull
            : state.usdcIncomePage,
        'rewardDetailPage': rewardDetailRes.isSuccess
            ? rewardDetailRes.dataOrNull
            : state.rewardDetailPage,
        'walletBalances': balancesRes.isSuccess
            ? (balancesRes.dataOrNull ?? [])
            : state.walletBalances,
        'weeklyStats': weeklyStatsRes.isSuccess
            ? weeklyStatsRes.dataOrNull
            : state.weeklyStats,
        'settlingReward': settlingRewardRes.isSuccess
            ? settlingRewardRes.dataOrNull
            : state.settlingReward,
      };
    });

    if (!ref.mounted) return;
    if (result.isSuccess && result.dataOrNull != null) {
      final data = result.dataOrNull!;
      state = state.copyWith(
        isStoryPageLoading: false,
        isUsdcPageLoading: false,
        totalReward: data['totalReward'] as TotalReward?,
        usdcIncomePage: data['usdcIncomePage'] as UsdcIncomePage?,
        rewardDetailPage: data['rewardDetailPage'] as RewardDetailPage?,
        walletBalances: data['walletBalances'] as List<WalletBalance>,
        weeklyStats: data['weeklyStats'] as MiningWeeklyStats?,
        settlingReward: data['settlingReward'] as SettlingReward?,
      );
    }
  }
}
