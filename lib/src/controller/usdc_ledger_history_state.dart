import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';
import 'pagination_state.dart';

/// USDC 收入流水「查看更多」完整列表页状态：支持下拉刷新与游标分页。
class UsdcLedgerHistoryState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final PaginationState<LedgerItem> pagination;

  const UsdcLedgerHistoryState({
    this.isLoading = false,
    this.lastError,
    this.pagination = const PaginationState<LedgerItem>(),
  });

  String get errorMessage => lastError?.userMessage ?? '';
  List<LedgerItem> get items => pagination.items;
  bool get hasMore => pagination.hasMore;
  String get mark => pagination.mark;
  bool get isPageLoading => pagination.isPageLoading;

  UsdcLedgerHistoryState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    PaginationState<LedgerItem>? pagination,
  }) {
    return UsdcLedgerHistoryState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [isLoading, lastError, pagination];
}
