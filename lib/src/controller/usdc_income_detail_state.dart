import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

/// USDC 收入明细 Tab 状态：费用明细统计 + 最近 USDC 收入流水预览。
class UsdcIncomeDetailState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final IncomeStats? incomeStats;
  final List<LedgerItem> recentLedger;

  const UsdcIncomeDetailState({
    this.isLoading = false,
    this.lastError,
    this.incomeStats,
    this.recentLedger = const [],
  });

  UsdcIncomeDetailState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    IncomeStats? incomeStats,
    List<LedgerItem>? recentLedger,
  }) {
    return UsdcIncomeDetailState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      incomeStats: incomeStats ?? this.incomeStats,
      recentLedger: recentLedger ?? this.recentLedger,
    );
  }

  @override
  List<Object?> get props => [isLoading, lastError, incomeStats, recentLedger];
}
