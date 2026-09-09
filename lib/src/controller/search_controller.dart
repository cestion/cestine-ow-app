import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import 'search_state.dart';
import 'story_controller_mixin.dart';

/// Min / max keyword length for recommend search (swagger 2~50).
const kSearchKeywordMinLen = 2;
const kSearchKeywordMaxLen = 50;

bool _markHasMore(String? mark, bool? hasMore) {
  if (hasMore != null) return hasMore;
  if (mark == null || mark.isEmpty || mark == '-1') return false;
  return true;
}

/// User search `CursorPageResponse`: `hasMore` plus terminal cursor `-1`.
bool _cursorPageHasMore(String? mark, bool? hasMore) {
  if (mark == '-1') return false;
  if (hasMore != null) return hasMore;
  return mark != null && mark.isNotEmpty;
}

class SearchController extends Notifier<SearchState>
    with StoryControllerMixin<SearchState> {
  int _searchId = 0;

  @override
  SearchState build() => const SearchState();

  @override
  SearchState copyWithLoadingState({
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

  /// Sets the initial / active tab without searching.
  void setActiveTab(SearchType type, {bool clearIfIdle = false}) {
    if (state.activeTab == type && !clearIfIdle) return;
    if (!state.hasSearched && clearIfIdle) {
      _searchId++;
      state = SearchState(activeTab: type);
      return;
    }
    state = state.copyWith(activeTab: type);
  }

  /// Syncs the draft keyword without triggering API.
  void syncKeyword(String kw) {
    if (state.keyword == kw) return;
    state = state.copyWith(keyword: kw);
  }

  /// Switch tab; fetch when the current keyword has no cache for that tab.
  Future<void> selectTab(SearchType type) async {
    if (state.activeTab == type) return;
    state = state.copyWith(activeTab: type);
    final kw = state.keyword.trim();
    if (!state.hasSearched || kw.isEmpty) return;
    if (state.hasCacheFor(type, kw)) return;
    await search(kw, resetResults: false);
  }

  /// Runs search for [state.activeTab] (or [tab] override).
  ///
  /// [resetResults] drops cached rows first so a repeat search of the same
  /// keyword shows loading, then fresh data. Tab switches pass `false` to keep
  /// other tabs' caches.
  ///
  /// Returns `false` when the keyword is rejected (too short / empty).
  Future<bool> search(
    String kw, {
    bool keepTab = true,
    bool resetResults = true,
  }) async {
    final keyword = kw.trim();
    if (keyword.isEmpty) {
      clear(keepTab: keepTab);
      return false;
    }
    if (keyword.length < kSearchKeywordMinLen ||
        keyword.length > kSearchKeywordMaxLen) {
      return false;
    }

    final tab = state.activeTab;
    final currentId = ++_searchId;
    state = state.copyWith(
      keyword: keyword,
      hasSearched: true,
      isLoading: true,
      isPageLoading: false,
      clearLastError: true,
      clearResults: resetResults,
    );

    final error = await _fetchPage(
      tab: tab,
      keyword: keyword,
      currentId: currentId,
      append: false,
    );

    if (!ref.mounted || currentId != _searchId) return true;

    if (error == null) {
      await ref.read(localRepositoryProvider).addSearchHistory(keyword);
      ref.read(searchHistoryControllerProvider.notifier).reload();
    }
    return true;
  }

  /// Loads the next page for [state.activeTab] when [hasMore] is true.
  Future<void> loadMore() => loadMoreFor(state.activeTab);

  /// Loads the next page for a fixed [tab] (playlist continuation must not
  /// follow a later UI tab switch).
  Future<void> loadMoreFor(SearchType tab) async {
    final keyword = state.keyword.trim();
    if (!state.hasSearched ||
        keyword.isEmpty ||
        state.isLoading ||
        state.isPageLoading ||
        !state.hasMoreFor(tab)) {
      return;
    }

    final currentId = _searchId;
    state = state.copyWith(isPageLoading: true, clearLastError: true);
    await _fetchPage(
      tab: tab,
      keyword: keyword,
      currentId: currentId,
      append: true,
    );
  }

  Future<ApiError?> _fetchPage({
    required SearchType tab,
    required String keyword,
    required int currentId,
    required bool append,
  }) async {
    final recommend = ref.read(recommendRepositoryProvider);
    final actorRepo = ref.read(actorRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    ApiError? error;

    switch (tab) {
      case SearchType.dramas:
        final result = await recommend.search(
          keyword: keyword,
          type: RecommendSearchType.drama.apiValue,
          cursor: append ? state.dramasCursor : null,
        );
        if (!ref.mounted || currentId != _searchId) return null;
        if (result.isFailure) {
          error = result.errorOrNull;
          state = state.copyWith(
            isLoading: false,
            isPageLoading: false,
            lastError: error,
          );
        } else {
          final data = result.dataOrNull;
          final next = data?.items ?? const <FeedItem>[];
          final cursor = data?.cursor ?? '';
          state = state.copyWith(
            dramas: append ? [...state.dramas, ...next] : next,
            dramasQuery: keyword,
            dramasCursor: cursor,
            dramasHasMore: data?.hasMore ?? false,
            isLoading: false,
            isPageLoading: false,
            clearLastError: true,
          );
        }
      case SearchType.works:
        final result = await recommend.search(
          keyword: keyword,
          type: RecommendSearchType.all.apiValue,
          cursor: append ? state.worksCursor : null,
        );
        if (!ref.mounted || currentId != _searchId) return null;
        if (result.isFailure) {
          error = result.errorOrNull;
          state = state.copyWith(
            isLoading: false,
            isPageLoading: false,
            lastError: error,
          );
        } else {
          final data = result.dataOrNull;
          final next = data?.items ?? const <FeedItem>[];
          final cursor = data?.cursor ?? '';
          state = state.copyWith(
            works: append ? [...state.works, ...next] : next,
            worksQuery: keyword,
            worksCursor: cursor,
            worksHasMore: data?.hasMore ?? false,
            isLoading: false,
            isPageLoading: false,
            clearLastError: true,
          );
        }
      case SearchType.actors:
        final mark = append ? state.actorsMark : null;
        final result = await actorRepo.searchActorCollections(
          keyword: keyword,
          mark: mark,
        );
        if (!ref.mounted || currentId != _searchId) return null;
        if (result.isFailure) {
          error = result.errorOrNull;
          state = state.copyWith(
            isLoading: false,
            isPageLoading: false,
            lastError: error,
          );
        } else {
          final page = result.dataOrNull;
          final next = page?.list ?? const <ActorCollection>[];
          final nextMark = page?.mark?.toString() ?? '';
          state = state.copyWith(
            actors: append ? [...state.actors, ...next] : next,
            actorsQuery: keyword,
            actorsMark: nextMark,
            actorsHasMore: _markHasMore(nextMark, page?.hasMore),
            isLoading: false,
            isPageLoading: false,
            clearLastError: true,
          );
        }
      case SearchType.users:
        // Swagger: mark int64, first page 0; response mark is the next cursor
        // (`-1` = no more).
        final mark = append ? state.usersMark : '0';
        if (append && (mark.isEmpty || mark == '-1')) {
          state = state.copyWith(
            isLoading: false,
            isPageLoading: false,
            usersHasMore: false,
          );
          return null;
        }
        final result = await userRepo.searchUsers(
          keyword: keyword,
          mark: mark.isEmpty ? '0' : mark,
        );
        if (!ref.mounted || currentId != _searchId) return null;
        if (result.isFailure) {
          error = result.errorOrNull;
          state = state.copyWith(
            isLoading: false,
            isPageLoading: false,
            lastError: error,
          );
        } else {
          final page = result.dataOrNull;
          final next = page?.list ?? const <UserSearchItem>[];
          final nextMark = page?.mark?.toString() ?? '';
          state = state.copyWith(
            users: append ? [...state.users, ...next] : next,
            usersQuery: keyword,
            usersMark: nextMark,
            usersHasMore: _cursorPageHasMore(nextMark, page?.hasMore),
            isLoading: false,
            isPageLoading: false,
            clearLastError: true,
          );
        }
    }
    return error;
  }

  void clear({bool keepTab = true}) {
    _searchId++;
    state = SearchState(
      activeTab: keepTab ? state.activeTab : SearchType.dramas,
    );
  }

  void patchUserRelation(String userId, FollowRelationStatus status) {
    final next = [
      for (final u in state.users)
        if (u.userId == userId) u.copyWith(relationStatus: status) else u,
    ];
    state = state.copyWith(users: next);
  }

  /// Reconciles one work in the cached search tabs without re-running search.
  ///
  /// Episode id is authoritative. [dramaId] is only a fallback for folded
  /// whole-drama search rows which do not carry a concrete episode id.
  bool patchWorkEngagement(DramaPlayResponse play) {
    final episodeId = play.episodeId?.trim() ?? '';
    final dramaId = play.dramaId?.trim() ?? '';
    if (episodeId.isEmpty && dramaId.isEmpty) return false;

    var changed = false;
    List<FeedItem> patch(List<FeedItem> items) {
      return [
        for (final item in items)
          if (_matchesPlay(item, episodeId: episodeId, dramaId: dramaId))
            () {
              final updated = item.copyWithEngagement(
                likedByMe: play.likedByMe,
                likeCount: play.likeCount,
                commentCount: play.commentCount,
                favoritedByMe: play.favoritedByMe,
                favoriteCount: play.favoriteCount,
              );
              if (updated != item) changed = true;
              return updated;
            }()
          else
            item,
      ];
    }

    final dramas = patch(state.dramas);
    final works = patch(state.works);
    if (!changed) return false;
    state = state.copyWith(dramas: dramas, works: works);
    return true;
  }

  bool _matchesPlay(
    FeedItem item, {
    required String episodeId,
    required String dramaId,
  }) {
    final itemEpisodeId = item.episodeId?.trim() ?? '';
    if (episodeId.isNotEmpty && itemEpisodeId == episodeId) return true;
    if (dramaId.isEmpty || itemEpisodeId.isNotEmpty) return false;
    return item.dramaId?.trim() == dramaId;
  }

  /// Replaces one actor search hit in place. No-op when the id is missing.
  void upsertActor(ActorCollection actor) {
    final id = actor.id;
    if (id == null || id.isEmpty) return;
    final actors = state.actors;
    final index = actors.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final next = List<ActorCollection>.from(actors);
    next[index] = actor;
    state = state.copyWith(actors: next);
  }
}

class SearchHistoryState extends Equatable {
  final List<String> items;

  const SearchHistoryState({this.items = const []});

  @override
  List<Object?> get props => [items];
}

class SearchHistoryController extends Notifier<SearchHistoryState> {
  @override
  SearchHistoryState build() {
    final local = ref.read(localRepositoryProvider);
    return SearchHistoryState(items: local.getSearchHistory());
  }

  void reload() {
    state = SearchHistoryState(
      items: ref.read(localRepositoryProvider).getSearchHistory(),
    );
  }

  Future<void> remove(String keyword) async {
    await ref.read(localRepositoryProvider).removeSearchHistory(keyword);
    reload();
  }

  /// Clears all history. Returns `true` when there was something to clear.
  Future<bool> clearAll() async {
    if (state.items.isEmpty) return false;
    await ref.read(localRepositoryProvider).clearSearchHistory();
    reload();
    return true;
  }
}

final searchHistoryControllerProvider =
    NotifierProvider.autoDispose<SearchHistoryController, SearchHistoryState>(
      SearchHistoryController.new,
    );
