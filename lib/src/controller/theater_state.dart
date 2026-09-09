import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';
import 'pagination_state.dart';

class TheaterState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final PaginationState<DramaListItem> pagination;

  const TheaterState({
    this.isLoading = false,
    this.lastError,
    this.pagination = const PaginationState<DramaListItem>(),
  });

  String get errorMessage => lastError?.userMessage ?? '';

  List<DramaListItem> get items => pagination.items;
  bool get hasMore => pagination.hasMore;
  String get mark => pagination.mark;
  bool get isPageLoading => pagination.isPageLoading;

  TheaterState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    PaginationState<DramaListItem>? pagination,
  }) {
    return TheaterState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [isLoading, lastError, pagination];
}
