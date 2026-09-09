import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/actor_repository.dart';
import 'nft_state.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';
import 'story_controller_mixin.dart';

class NftController extends Notifier<NftState>
    with
        PaginationMixin<ActorCollection, NftState>,
        StoryControllerMixin<NftState> {
  late final ActorRepository _actor;

  @override
  NftState build() {
    _actor = ref.read(actorRepositoryProvider);
    return const NftState();
  }

  @override
  NftState copyWithLoadingState({
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

  ActorCollectionSort get sort => state.sort;
  String get searchQuery => state.searchQuery;
  List<ActorCollection> get displayItems => state.displayItems;
  @override
  PaginationState<ActorCollection> get pagination => state.pagination;
  @override
  bool get isLoading => state.isLoading;
  String get errorMessage => state.errorMessage;

  @override
  void setPaginationState(
    PaginationState<ActorCollection> pagination, {
    bool? isLoading,
  }) {
    state = state.copyWith(pagination: pagination, isLoading: isLoading);
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error);
  }

  /// Replaces one plaza item in place. No-op when the id is not in the list.
  void upsertActor(ActorCollection actor) {
    final id = actor.id;
    if (id == null || id.isEmpty) return;
    final items = pagination.items;
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final next = List<ActorCollection>.from(items);
    next[index] = actor;
    setPaginationState(pagination.copyWith(items: next));
  }

  @override
  Future<Result<PageDto<ActorCollection>>> fetchPage({String? mark}) =>
      _actor.listActorCollections(mark: mark, sort: sort);

  /// Loads the first page when the feed is still empty and not in-flight.
  Future<void> ensureLoaded() async {
    if (items.isNotEmpty || isLoading || pagination.isPageLoading) return;
    await refresh();
  }

  @override
  Future<void> refresh({bool force = false}) async {
    if (force) {
      await _actor.invalidateActorCollectionsCache(sort: sort);
    }
    setPaginationState(
      const PaginationState<ActorCollection>(),
      isLoading: false,
    );
    await loadMore();
  }

  Future<void> setSort(ActorCollectionSort newSort) async {
    final nextSort = switch ((newSort, sort)) {
      (ActorCollectionSort.priceAsc, ActorCollectionSort.priceAsc) =>
        ActorCollectionSort.priceDesc,
      (ActorCollectionSort.priceDesc, ActorCollectionSort.priceDesc) =>
        ActorCollectionSort.priceAsc,
      _ => newSort,
    };
    if (nextSort == sort) return;
    final reload = nextSort.value != sort.value;
    state = state.copyWith(sort: nextSort);
    if (reload) await refresh();
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query.trim());
    await refresh();
  }

  Future<Result<ActorCollection>> getCollectionDetail(String id) =>
      _actor.getActorCollectionDetail(id);
  Future<Result<Actor>> getDetail(String id) => _actor.getDetail(id);
  Future<Result<PageDto<DramaListItem>>> getCastDramas(
    String id, {
    String? mark,
  }) => _actor.getCastDramas(id, mark: mark);
}
