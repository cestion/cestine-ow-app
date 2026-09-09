import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

class IncomeState extends Equatable {
  final bool isLoading;
  final bool isStoryPageLoading;
  final bool isUsdcPageLoading;
  final ApiError? lastError;
  final List<WalletBalance> walletBalances;
  final TotalReward? totalReward;
  final SettlingReward? settlingReward;
  final UsdcIncomePage? usdcIncomePage;
  final RewardDetailPage? rewardDetailPage;
  final MiningWeeklyStats? weeklyStats;

  const IncomeState({
    this.isLoading = false,
    this.isStoryPageLoading = false,
    this.isUsdcPageLoading = false,
    this.lastError,
    this.walletBalances = const [],
    this.totalReward,
    this.settlingReward,
    this.usdcIncomePage,
    this.rewardDetailPage,
    this.weeklyStats,
  });

  String get errorMessage => lastError?.userMessage ?? '';

  /// 可领取 STORY：取 walletBalances 中 assetCode == 'STORY' 的 availableBalance
  double get storyBalance =>
      walletBalances
          .firstWhere(
            (b) => AssetCode.story.matches(b.assetCode),
            orElse: () => const WalletBalance(),
          )
          .availableBalance ??
      0.0;

  /// 可领取 USDC：取 walletBalances 中 assetCode == 'USDC' 的 availableBalance
  double get usdcBalance =>
      walletBalances
          .firstWhere(
            (b) => AssetCode.usdc.matches(b.assetCode),
            orElse: () => const WalletBalance(),
          )
          .availableBalance ??
      0.0;

  /// 累计 STORY 收益 = totalMiningReward + totalInviteReward（与 web 对齐）
  double get totalStoryEarnings {
    final mining = totalReward?.totalMiningReward ?? 0;
    final invite = totalReward?.totalInviteReward ?? 0;
    return mining + invite;
  }

  /// 结算中 STORY = miningReward + inviteReward
  double get settlingStoryEarnings => settlingReward?.totalStory ?? 0;

  /// 累计 USDC 收益：取 usdcIncome 首页 total 字段
  double get totalUsdcEarnings {
    final totalStr = usdcIncomePage?.total;
    if (totalStr == null || totalStr.isEmpty) return 0;
    return double.tryParse(totalStr) ?? 0;
  }

  /// STORY 收益明细列表
  List<RewardDetail> get storyRecords => rewardDetailPage?.list ?? const [];

  bool get hasMoreStoryRecords => rewardDetailPage?.hasMore ?? false;

  /// USDC 收益明细列表
  List<UsdcIncomeItem> get usdcRecords => usdcIncomePage?.list ?? const [];

  bool get hasMoreUsdcRecords => usdcIncomePage?.hasMore ?? false;

  IncomeState copyWith({
    bool? isLoading,
    bool? isStoryPageLoading,
    bool? isUsdcPageLoading,
    ApiError? lastError,
    bool clearLastError = false,
    List<WalletBalance>? walletBalances,
    TotalReward? totalReward,
    SettlingReward? settlingReward,
    UsdcIncomePage? usdcIncomePage,
    RewardDetailPage? rewardDetailPage,
    MiningWeeklyStats? weeklyStats,
  }) {
    return IncomeState(
      isLoading: isLoading ?? this.isLoading,
      isStoryPageLoading: isStoryPageLoading ?? this.isStoryPageLoading,
      isUsdcPageLoading: isUsdcPageLoading ?? this.isUsdcPageLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      walletBalances: walletBalances ?? this.walletBalances,
      totalReward: totalReward ?? this.totalReward,
      settlingReward: settlingReward ?? this.settlingReward,
      usdcIncomePage: usdcIncomePage ?? this.usdcIncomePage,
      rewardDetailPage: rewardDetailPage ?? this.rewardDetailPage,
      weeklyStats: weeklyStats ?? this.weeklyStats,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isStoryPageLoading,
    isUsdcPageLoading,
    lastError,
    walletBalances,
    totalReward,
    settlingReward,
    usdcIncomePage,
    rewardDetailPage,
    weeklyStats,
  ];
}
