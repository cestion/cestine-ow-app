import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

/// 金库资金沉淀 Tab 状态（Figma node 6312:96340）。
///
/// [ranking] 为「演员 IP 金库排行」预览列表（最多 5 条），完整列表见
/// `ActorVaultRankingHistoryPage`。
class VaultFundsState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final ActorVaultStats? stats;
  final List<ActorVaultRankingItem> ranking;

  const VaultFundsState({
    this.isLoading = false,
    this.lastError,
    this.stats,
    this.ranking = const [],
  });

  VaultFundsState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    ActorVaultStats? stats,
    List<ActorVaultRankingItem>? ranking,
  }) => VaultFundsState(
    isLoading: isLoading ?? this.isLoading,
    lastError: clearLastError ? null : (lastError ?? this.lastError),
    stats: stats ?? this.stats,
    ranking: ranking ?? this.ranking,
  );

  @override
  List<Object?> get props => [isLoading, lastError, stats, ranking];
}
