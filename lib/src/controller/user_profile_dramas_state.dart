import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/user_profile_content_model.dart';
import '../model/work_content_type.dart';
import '../repositories/user_repository.dart';
import 'pagination_state.dart';

class UserProfileDramaParam extends Equatable {
  final String? userId;
  final ProfileDramaType type;
  final WorkContentType contentType;

  const UserProfileDramaParam({
    this.userId,
    required this.type,
    this.contentType = WorkContentType.shortDrama,
  });

  @override
  List<Object?> get props => [userId, type, contentType];
}

class UserProfileDramasState extends Equatable {
  final bool isLoading;
  final bool hasFetched;
  final ApiError? lastError;
  final PaginationState<UserProfileContentItem> pagination;

  const UserProfileDramasState({
    this.isLoading = false,
    this.hasFetched = false,
    this.lastError,
    this.pagination = const PaginationState<UserProfileContentItem>(),
  });

  List<UserProfileContentItem> get items => pagination.items;
  bool get hasMore => pagination.hasMore;
  bool get isPageLoading => pagination.isPageLoading;

  UserProfileDramasState copyWith({
    bool? isLoading,
    bool? hasFetched,
    ApiError? lastError,
    bool clearLastError = false,
    PaginationState<UserProfileContentItem>? pagination,
  }) {
    return UserProfileDramasState(
      isLoading: isLoading ?? this.isLoading,
      hasFetched: hasFetched ?? this.hasFetched,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [isLoading, hasFetched, lastError, pagination];
}
