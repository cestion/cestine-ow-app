import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';
import 'pagination_state.dart';

/// State backing the 「短剧NFT」tab on the creator page.
///
/// Mirrors [DramaManagementState]: an immutable slice holding pagination
/// (`/api/userWallet/dramaNft/positions`) and shared loading/error flags.
///
/// The total owned NFT count (`PageDto.total`) is now owned by
/// [CreatorState.ownedNftCount] so it loads alongside the published-drama
/// count metric on the creator page.
class DramaNftState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final PaginationState<NftPosition> pagination;

  const DramaNftState({
    this.isLoading = false,
    this.lastError,
    this.pagination = const PaginationState<NftPosition>(),
  });

  List<NftPosition> get myNfts => pagination.items;
  bool get hasMoreNfts => pagination.hasMore;

  String get errorMessage => lastError?.userMessage ?? '';

  DramaNftState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    PaginationState<NftPosition>? pagination,
  }) {
    return DramaNftState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [isLoading, lastError, pagination];
}
