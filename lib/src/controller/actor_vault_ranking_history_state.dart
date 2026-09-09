import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';
import 'pagination_state.dart';

/// 演员 IP 金库排行「查看更多」完整列表页状态：支持下拉刷新与游标分页。
class ActorVaultRankingHistoryState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final PaginationState<ActorVaultRankingItem> pagination;

  const ActorVaultRankingHistoryState({
    this.isLoading = false,
    this.lastError,
    this.pagination = const PaginationState<ActorVaultRankingItem>(),
  });

  String get errorMessage => lastError?.userMessage ?? '';
  List<ActorVaultRankingItem> get items => pagination.items;
  bool get hasMore => pagination.hasMore;
  String get mark => pagination.mark;
  bool get isPageLoading => pagination.isPageLoading;

  ActorVaultRankingHistoryState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    PaginationState<ActorVaultRankingItem>? pagination,
  }) {
    return ActorVaultRankingHistoryState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [isLoading, lastError, pagination];
}
