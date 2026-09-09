import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/actor_collection_model.dart';
import 'pagination_state.dart';

class UserProfileActorParam extends Equatable {
  /// `null` = current user (self profile).
  final String? userId;

  const UserProfileActorParam({this.userId});

  @override
  List<Object?> get props => [userId];
}

class UserProfileActorCollectionsState extends Equatable {
  final bool isLoading;
  final bool hasFetched;
  final ApiError? lastError;
  final PaginationState<ActorCollection> pagination;

  const UserProfileActorCollectionsState({
    this.isLoading = false,
    this.hasFetched = false,
    this.lastError,
    this.pagination = const PaginationState<ActorCollection>(),
  });

  List<ActorCollection> get items => pagination.items;
  bool get hasMore => pagination.hasMore;
  bool get isPageLoading => pagination.isPageLoading;

  UserProfileActorCollectionsState copyWith({
    bool? isLoading,
    bool? hasFetched,
    ApiError? lastError,
    bool clearLastError = false,
    PaginationState<ActorCollection>? pagination,
  }) {
    return UserProfileActorCollectionsState(
      isLoading: isLoading ?? this.isLoading,
      hasFetched: hasFetched ?? this.hasFetched,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [isLoading, hasFetched, lastError, pagination];
}
