import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';
import 'pagination_state.dart';

/// 「近期挖矿释放」查看更多完整列表页状态：支持下拉刷新与游标分页。
class StoryReleaseHistoryState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final PaginationState<WeeklyRewardItem> pagination;

  const StoryReleaseHistoryState({
    this.isLoading = false,
    this.lastError,
    this.pagination = const PaginationState<WeeklyRewardItem>(),
  });

  String get errorMessage => lastError?.userMessage ?? '';
  List<WeeklyRewardItem> get items => pagination.items;
  bool get hasMore => pagination.hasMore;
  String get mark => pagination.mark;
  bool get isPageLoading => pagination.isPageLoading;

  StoryReleaseHistoryState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    PaginationState<WeeklyRewardItem>? pagination,
  }) {
    return StoryReleaseHistoryState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [isLoading, lastError, pagination];
}
