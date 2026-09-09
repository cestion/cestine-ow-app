import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/page_dto.dart';
import 'pagination_state.dart';

/// Shared pagination logic for Notifier-based list controllers.
///
/// The mixin is immutable-state friendly: controllers expose their pagination
/// slice through [pagination] and apply updates through [setPaginationState],
/// while the mixin owns the refresh/loadMore lifecycle and cursor handling.
mixin PaginationMixin<T, ControllerState> on Notifier<ControllerState> {
  PaginationState<T> get pagination;
  bool get isLoading;
  void setPaginationState(PaginationState<T> pagination, {bool? isLoading});
  void setPaginationError(ApiError? error);

  List<T> get items => pagination.items;
  bool get hasMore => pagination.hasMore;
  String get mark => pagination.mark;

  /// Bumped each refresh so in-flight loadMore responses from a superseded
  /// generation are discarded instead of appended after the refreshed page.
  int _pageGeneration = 0;

  Future<Result<PageDto<T>>> fetchPage({String? mark});

  /// Pull-to-refresh / hard reload of the first page.
  ///
  /// Keeps existing [items] on screen until the new page arrives (stale-while-
  /// revalidate) so the list does not flash empty. On failure, previous items
  /// remain. First load (empty list) still shows the loading/empty UI as before.
  /// An in-flight loadMore is superseded: its flags are cleared and its stale
  /// response is dropped once this generation's page lands.
  Future<void> refresh() => reloadFirstPage();

  /// Reload page 1, superseding any in-flight [loadMore] / prior reload.
  ///
  /// Used by filter/sort changes that must discard pages 2…N without flashing
  /// a full-page skeleton ([showLoading] false keeps [isLoading] off).
  Future<void> reloadFirstPage({bool showLoading = true}) async {
    // Skip only when another *loading* reload is already in flight. A concurrent
    // loadMore — or a quiet filter reload — is intentionally superseded.
    if (showLoading && isLoading && !pagination.isPageLoading) return;

    final generation = ++_pageGeneration;
    // Reset cursor for page 1 without clearing items. Avoid isPageLoading so
    // list UIs that append a footer spinner do not show one under RefreshIndicator.
    setPaginationState(
      pagination.copyWith(hasMore: true, mark: '', isPageLoading: false),
      isLoading: showLoading,
    );
    try {
      final result = await fetchPage();
      if (!ref.mounted || generation != _pageGeneration) return;
      if (result.isFailure) {
        setPaginationError(result.errorOrNull);
        setPaginationState(pagination, isLoading: false);
        return;
      }

      final page = result.dataOrNull;
      if (page == null) {
        setPaginationState(pagination, isLoading: false);
        return;
      }

      // Replace (do not append) so page 1 does not keep rows from pages 2…N.
      setPaginationState(
        PaginationState<T>().appendPage(page),
        isLoading: false,
      );
    } catch (e, st) {
      StoryLogger.e(
        'PaginationMixin reloadFirstPage failed',
        error: e,
        stackTrace: st,
        tag: 'Pagination',
      );
      if (!ref.mounted || generation != _pageGeneration) return;
      setPaginationError(ApiError.unknown(e.toString()));
      setPaginationState(pagination, isLoading: false);
    }
  }

  Future<void> loadMore() async {
    final current = pagination;
    if (current.isPageLoading || isLoading || !current.hasMore) return;
    // After page 1, further pages need a cursor. An empty mark would repeat
    // the first-page URL and storm the API when scroll notifications keep
    // firing (common when extentAfter stays below the load-more threshold).
    if (current.items.isNotEmpty && current.mark.isEmpty) {
      setPaginationState(current.copyWith(hasMore: false));
      return;
    }

    final generation = _pageGeneration;
    setPaginationState(current.copyWith(isPageLoading: true), isLoading: true);
    try {
      final result = await fetchPage(mark: mark.isEmpty ? null : mark);
      if (!ref.mounted || generation != _pageGeneration) return;
      if (result.isFailure) {
        setPaginationError(result.errorOrNull);
        setPaginationState(
          pagination.copyWith(isPageLoading: false),
          isLoading: false,
        );
        return;
      }

      final page = result.dataOrNull;
      if (page == null) {
        setPaginationState(
          pagination.copyWith(isPageLoading: false),
          isLoading: false,
        );
        return;
      }

      setPaginationState(pagination.appendPage(page), isLoading: false);
    } catch (e, st) {
      StoryLogger.e(
        'PaginationMixin loadMore failed',
        error: e,
        stackTrace: st,
        tag: 'Pagination',
      );
      if (!ref.mounted || generation != _pageGeneration) return;
      setPaginationError(ApiError.unknown(e.toString()));
      setPaginationState(
        pagination.copyWith(isPageLoading: false),
        isLoading: false,
      );
    }
  }
}
