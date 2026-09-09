import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/follow_models.dart';
import 'pagination_state.dart';

class FollowListParam extends Equatable {
  final String userId;
  final FollowListType type;

  const FollowListParam({required this.userId, required this.type});

  @override
  List<Object?> get props => [userId, type];
}

class FollowListState extends Equatable {
  final bool isLoading;

  /// True after the first refresh/loadMore attempt finishes (success or failure).
  /// Prevents treating the pristine provider state as an empty list.
  final bool hasFetched;
  final ApiError? lastError;
  final PaginationState<FollowListItem> pagination;

  const FollowListState({
    this.isLoading = false,
    this.hasFetched = false,
    this.lastError,
    this.pagination = const PaginationState<FollowListItem>(),
  });

  String get errorMessage => lastError?.userMessage ?? '';
  List<FollowListItem> get items => pagination.items;
  bool get hasMore => pagination.hasMore;
  String get mark => pagination.mark;
  bool get isPageLoading => pagination.isPageLoading;

  /// Mutuals list is only readable by the owner.
  bool get isMutualsForbidden => lastError is UnauthorizedError;

  FollowListState copyWith({
    bool? isLoading,
    bool? hasFetched,
    ApiError? lastError,
    bool clearLastError = false,
    PaginationState<FollowListItem>? pagination,
  }) {
    return FollowListState(
      isLoading: isLoading ?? this.isLoading,
      hasFetched: hasFetched ?? this.hasFetched,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [isLoading, hasFetched, lastError, pagination];
}
