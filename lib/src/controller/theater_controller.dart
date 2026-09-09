import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../data/repository/story_local_repository.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/drama_repository.dart';
import '../services/video_precache_service.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';
import 'story_controller_mixin.dart';
import 'theater_filter_controller.dart';
import 'theater_state.dart';

class TheaterController extends Notifier<TheaterState>
    with
        PaginationMixin<DramaListItem, TheaterState>,
        StoryControllerMixin<TheaterState> {
  late DramaRepository _drama;
  late StoryLocalRepository _local;

  @override
  TheaterState build() {
    _drama = ref.read(dramaRepositoryProvider);
    _local = ref.read(localRepositoryProvider);

    // Listen to language changes to trigger refresh safely without rebuilding the provider
    ref.listen<String>(localeCodeProvider, (prev, next) {
      if (prev != null && prev != next) {
        refresh();
      }
    });

    ref.listen(theaterFilterControllerProvider, (prev, next) {
      final tagChanged = prev?.selectedTagId != next.selectedTagId;
      final sortChanged = prev?.sort != next.sort;
      if (tagChanged || sortChanged) {
        reloadWithFilter();
      }
    });

    return const TheaterState();
  }

  @override
  TheaterState copyWithLoadingState({
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
  PaginationState<DramaListItem> get pagination => state.pagination;
  @override
  bool get isLoading => state.isLoading;
  String get errorMessage => state.errorMessage;

  @override
  void setPaginationState(
    PaginationState<DramaListItem> pagination, {
    bool? isLoading,
  }) {
    state = state.copyWith(pagination: pagination, isLoading: isLoading);
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error);
  }

  @override
  Future<Result<PageDto<DramaListItem>>> fetchPage({String? mark}) {
    final filter = ref.read(theaterFilterControllerProvider);
    final sort = ref
        .read(theaterFilterControllerProvider.notifier)
        .apiSortValue;
    return _drama.listPublic(
      mark: mark,
      tagId: filter.selectedTagId,
      sort: sort,
    );
  }

  @override
  Future<void> refresh() async {
    final filter = ref.read(theaterFilterControllerProvider);
    final sort = ref
        .read(theaterFilterControllerProvider.notifier)
        .apiSortValue;
    await _drama.invalidatePublicListCache(
      tagId: filter.selectedTagId,
      sort: sort,
    );
    await reloadFirstPage(showLoading: pagination.items.isEmpty);
  }

  /// Cold open of the short-drama home tab: prefer CacheChain hit, do not
  /// invalidate. Pull-to-refresh still uses [refresh].
  Future<void> ensureLoaded() async {
    if (pagination.items.isNotEmpty || isLoading) return;
    await reloadFirstPage();
  }

  /// Reload page 1 when filter (tag/sort) changes.
  ///
  /// Supersedes in-flight [loadMore] so pages 2…N from the previous filter
  /// cannot append onto the new first page. Keeps [isLoading] false so the
  /// full-page skeleton is not triggered.
  Future<void> reloadWithFilter() async {
    final filter = ref.read(theaterFilterControllerProvider);
    final sort = ref
        .read(theaterFilterControllerProvider.notifier)
        .apiSortValue;
    await _drama.invalidatePublicListCache(
      tagId: filter.selectedTagId,
      sort: sort,
    );
    await reloadFirstPage(showLoading: false);
  }

  Future<Result<DramaDetail>> getDetail(String id) => _drama.getDetail(id);
  Future<Result<DramaPlayResponse>> getEpisodeDetail(
    String dramaId,
    int epNo,
  ) => _drama.getEpisodeDetail(dramaId, epNo);
  bool isFavorite(String dramaId) => _local.isFavorite(dramaId);

  /// Warm episode-1 metadata + a small disk head. Call on tap / banner
  /// open only — viewport scroll must not enqueue this (each warm is a
  /// `getEpisodeDetail` plus up to 4MB HLS).
  void prefetchEpisode(String dramaId, int episodeNo) {
    final isWifi = ref.read(connectivityProvider).isWifi;
    unawaited(
      VideoPrecacheService.instance.prefetchAndWarm(
        _drama,
        dramaId,
        episodeNo,
        budgetRatio: isWifi ? 1.0 : 0.25,
        priority: PrecachePriority.next,
      ),
    );
  }

  /// Toggles favorite through the shared engagement store (single write path
  /// with optimistic update, rollback, and a per-drama double-tap guard).
  /// Returns the resulting favorite state.
  Future<bool> toggleFavorite(String id) async {
    final notifier = ref.read(dramaEngagementProvider(id).notifier);
    notifier.seed(favoritedByMe: _local.isFavorite(id));
    await notifier.toggleFavorite();
    if (!ref.mounted) return _local.isFavorite(id);
    return ref.read(dramaEngagementProvider(id)).favoritedByMe ??
        _local.isFavorite(id);
  }

  int getResume(String dramaId, int ep) => _local.getWatchProgress(dramaId, ep);
  Future<void> saveResume(String d, int e, int ms) =>
      _local.saveWatchProgress(d, e, ms);
  Future<void> clearResume(String d, int e) => _local.clearWatchProgress(d, e);
}
