import 'package:equatable/equatable.dart';

import '../core/result.dart';
import 'pagination_state.dart';

/// Shared immutable state for either watch-history tab.
class WatchHistoryListState<T> extends Equatable {
  final bool isInitialized;
  final bool isLoading;
  final bool isClearing;
  final ApiError? lastError;
  final PaginationState<T> pagination;

  WatchHistoryListState({
    this.isInitialized = false,
    this.isLoading = false,
    this.isClearing = false,
    this.lastError,
    PaginationState<T>? pagination,
  }) : pagination = pagination ?? PaginationState<T>();

  List<T> get items => pagination.items;
  bool get hasMore => pagination.hasMore;
  String get mark => pagination.mark;
  bool get isPageLoading => pagination.isPageLoading;

  WatchHistoryListState<T> copyWith({
    bool? isInitialized,
    bool? isLoading,
    bool? isClearing,
    ApiError? lastError,
    bool clearLastError = false,
    PaginationState<T>? pagination,
  }) {
    return WatchHistoryListState<T>(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isClearing: isClearing ?? this.isClearing,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [
    isInitialized,
    isLoading,
    isClearing,
    lastError,
    pagination,
  ];
}
