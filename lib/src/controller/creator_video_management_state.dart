import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';
import 'drama_management_state.dart';
import 'pagination_state.dart';

class CreatorVideoManagementState extends Equatable {
  final bool isLoading;
  final bool isDeleting;
  final ApiError? lastError;
  final DramaManagementStatus currentStatus;
  final PaginationState<CreatorShortVideo> pagination;

  const CreatorVideoManagementState({
    this.isLoading = false,
    this.isDeleting = false,
    this.lastError,
    this.currentStatus = DramaManagementStatus.all,
    this.pagination = const PaginationState<CreatorShortVideo>(),
  });

  List<CreatorShortVideo> get items => pagination.items;
  bool get hasMore => pagination.hasMore;
  bool get isPageLoading => pagination.isPageLoading;

  CreatorVideoManagementState copyWith({
    bool? isLoading,
    bool? isDeleting,
    ApiError? lastError,
    bool clearLastError = false,
    DramaManagementStatus? currentStatus,
    PaginationState<CreatorShortVideo>? pagination,
  }) {
    return CreatorVideoManagementState(
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      currentStatus: currentStatus ?? this.currentStatus,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isDeleting,
    lastError,
    currentStatus,
    pagination,
  ];
}
