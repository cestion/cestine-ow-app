import 'package:equatable/equatable.dart';

import '../core/result.dart';

/// 平台资金看板顶部汇总状态：仅承载 USDC 总收入 / STORY 总释放两项数据。
class FinanceDashboardState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final double totalUsdcIncome;
  final double totalStoryReleased;

  const FinanceDashboardState({
    this.isLoading = false,
    this.lastError,
    this.totalUsdcIncome = 0,
    this.totalStoryReleased = 0,
  });

  String get errorMessage => lastError?.userMessage ?? '';

  FinanceDashboardState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    double? totalUsdcIncome,
    double? totalStoryReleased,
  }) {
    return FinanceDashboardState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      totalUsdcIncome: totalUsdcIncome ?? this.totalUsdcIncome,
      totalStoryReleased: totalStoryReleased ?? this.totalStoryReleased,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    lastError,
    totalUsdcIncome,
    totalStoryReleased,
  ];
}
