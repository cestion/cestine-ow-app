import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/user_repository.dart';
import 'drama_nft_state.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';
import 'story_controller_mixin.dart';

/// Controller backing the 「短剧NFT」tab on the creator page.
///
/// Loads owned drama NFT positions via `/api/userWallet/dramaNft/positions`
/// with server-side cursor pagination. Replaces the previous
/// `CreatorController.nftPagination` slice so [CreatorController] can focus on
/// actor management, the published-drama count metric, and the owned-NFT
/// count metric (see [CreatorState.ownedNftCount]).
class DramaNftController extends Notifier<DramaNftState>
    with
        PaginationMixin<NftPosition, DramaNftState>,
        StoryControllerMixin<DramaNftState> {
  UserRepository get _user => ref.read(userRepositoryProvider);
  final Map<String, NftPosition> _pendingMints = {};
  bool _isRefreshing = false;

  @override
  DramaNftState build() {
    final authNotifier = ref.read(authControllerProvider.notifier);
    final authSub = authNotifier.authStateChanges.listen((loggedIn) {
      if (!loggedIn) {
        _pendingMints.clear();
        state = state.copyWith(
          pagination: const PaginationState<NftPosition>(),
        );
      }
    });
    ref.onDispose(authSub.cancel);
    return const DramaNftState();
  }

  @override
  DramaNftState copyWithLoadingState({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return state.copyWith(
      isLoading: isLoading,
      lastError: lastError,
      clearLastError: clearLastError,
    );
  }

  @override
  PaginationState<NftPosition> get pagination => state.pagination;
  @override
  bool get isLoading => state.isLoading;

  @override
  void setPaginationState(
    PaginationState<NftPosition> pagination, {
    bool? isLoading,
  }) {
    state = state.copyWith(
      pagination: pagination.copyWith(
        items: _mergePendingMints(pagination.items),
      ),
      isLoading: isLoading,
    );
  }

  /// Immediately prepends a locally-created NFT position after the mint
  /// transaction is submitted successfully.
  ///
  /// The optimistic item stays in [_pendingMints] across stale first-page
  /// responses. A later normal refresh replaces it only when the backend
  /// returns an item with the same drama id.
  void addPendingMint(CreatorDrama drama, {String? nftContractAddress}) {
    final dramaId = drama.id?.trim();
    if (dramaId == null || dramaId.isEmpty) return;

    final pendingMint = NftPosition(
      id: dramaId,
      dramaId: dramaId,
      nftContractAddress: nftContractAddress ?? drama.nftContractAddress,
      dramaName: drama.title,
      coverUrl: drama.coverUrl,
      episodeCount: drama.totalEpisodes,
      description: drama.description,
      createdAt: drama.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );

    final previousPendingMints = Map<String, NftPosition>.of(_pendingMints)
      ..remove(dramaId);
    _pendingMints
      ..clear()
      ..[dramaId] = pendingMint
      ..addAll(previousPendingMints);

    setPaginationState(state.pagination);
  }

  List<NftPosition> _mergePendingMints(List<NftPosition> items) {
    if (_pendingMints.isEmpty) return _deduplicateNfts(items);

    return _deduplicateNfts([
      ..._pendingMints.values,
      ...items.where((item) {
        final dramaId = item.dramaId;
        return dramaId == null || !_pendingMints.containsKey(dramaId);
      }),
    ]);
  }

  /// Cursor pages may overlap, so keep the first position for each backend
  /// identifier while preserving the API order. Items without an identifier
  /// fall back to value equality so unrelated positions are not discarded.
  List<NftPosition> _deduplicateNfts(List<NftPosition> items) {
    final ids = <String>{};
    final unidentifiedItems = <NftPosition>{};
    return items
        .where((nft) {
          final id = nft.id;
          if (id != null && id.isNotEmpty) {
            return ids.add(id);
          }
          return unidentifiedItems.add(nft);
        })
        .toList(growable: false);
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error);
  }

  /// Refreshes the first page while retaining optimistic mints that the
  /// eventually-consistent positions endpoint has not returned yet.
  @override
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    state = state.copyWith(isLoading: true, clearLastError: true);

    try {
      final result = await _user.getDramaNftPositions();
      if (!ref.mounted) return;

      if (result.isFailure) {
        state = state.copyWith(isLoading: false, lastError: result.errorOrNull);
        return;
      }

      final page = result.dataOrNull;
      if (page == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final serverItems = page.list ?? const <NftPosition>[];
      final serverDramaIds = serverItems
          .map((item) => item.dramaId)
          .whereType<String>()
          .toSet();
      _pendingMints.removeWhere(
        (dramaId, _) => serverDramaIds.contains(dramaId),
      );

      setPaginationState(
        PaginationState<NftPosition>(
          items: serverItems,
          hasMore: page.hasMore ?? false,
          mark: page.mark?.toString() ?? '',
        ),
        isLoading: false,
      );
      state = state.copyWith(clearLastError: true);
    } catch (error, stackTrace) {
      StoryLogger.e(
        'Drama NFT refresh failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'DramaNft',
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        lastError: ApiError.unknown(error.toString()),
      );
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Future<Result<PageDto<NftPosition>>> fetchPage({String? mark}) async {
    return _user.getDramaNftPositions(mark: mark);
  }
}
