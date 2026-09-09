import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';
import 'pagination_state.dart';

/// Status filter values accepted by `/api/mini-drama/creator/dramas?status=`.
/// `null` (all) is represented by [DramaManagementStatus.all] (no `apiValue`).
enum DramaManagementStatus {
  all,
  online,
  pendingReview,
  reviewRejected,
  offline;

  /// Whether an empty creator-management list should offer publishing.
  bool get showsEmptyPublishAction =>
      this == DramaManagementStatus.all || this == DramaManagementStatus.online;

  /// Value sent to the API; `null` means no `status` query param (全部).
  String? get apiValue {
    switch (this) {
      case DramaManagementStatus.all:
        return null;
      case DramaManagementStatus.online:
        return 'ONLINE';
      case DramaManagementStatus.pendingReview:
        return 'PENDING_REVIEW';
      case DramaManagementStatus.reviewRejected:
        return 'REVIEW_REJECTED';
      case DramaManagementStatus.offline:
        return 'OFFLINE';
    }
  }
}

/// Dialog kinds for the drama management tab.
enum DramaManagementDialog { closed, deleteDramaConfirm }

class DramaManagementState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final bool isMinting;
  final ApiError? mintError;
  final String? lastMintTxHash;
  final DramaManagementStatus currentStatus;
  final PaginationState<CreatorDrama> pagination;
  final DramaManagementDialog activeDialog;
  final bool isDeleting;
  final String? dramaToDelete;

  const DramaManagementState({
    this.isLoading = false,
    this.lastError,
    this.isMinting = false,
    this.mintError,
    this.lastMintTxHash,
    this.currentStatus = DramaManagementStatus.all,
    this.pagination = const PaginationState<CreatorDrama>(),
    this.activeDialog = DramaManagementDialog.closed,
    this.isDeleting = false,
    this.dramaToDelete,
  });

  String get errorMessage => lastError?.userMessage ?? '';

  List<CreatorDrama> get items => pagination.items;
  bool get hasMore => pagination.hasMore;
  String get mark => pagination.mark;
  bool get isPageLoading => pagination.isPageLoading;
  bool get hasPendingReview => items.any(
    (drama) => drama.status?.trim().toUpperCase() == 'PENDING_REVIEW',
  );

  DramaManagementState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    bool? isMinting,
    ApiError? mintError,
    bool clearMintError = false,
    String? lastMintTxHash,
    bool clearLastMintTxHash = false,
    DramaManagementStatus? currentStatus,
    PaginationState<CreatorDrama>? pagination,
    DramaManagementDialog? activeDialog,
    bool? isDeleting,
    String? dramaToDelete,
  }) {
    return DramaManagementState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      isMinting: isMinting ?? this.isMinting,
      mintError: clearMintError ? null : (mintError ?? this.mintError),
      lastMintTxHash: clearLastMintTxHash
          ? null
          : (lastMintTxHash ?? this.lastMintTxHash),
      currentStatus: currentStatus ?? this.currentStatus,
      pagination: pagination ?? this.pagination,
      activeDialog: activeDialog ?? this.activeDialog,
      isDeleting: isDeleting ?? this.isDeleting,
      dramaToDelete: dramaToDelete ?? this.dramaToDelete,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    lastError,
    isMinting,
    mintError,
    lastMintTxHash,
    currentStatus,
    pagination,
    activeDialog,
    isDeleting,
    dramaToDelete,
  ];
}
