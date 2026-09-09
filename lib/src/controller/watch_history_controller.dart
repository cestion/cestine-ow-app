import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/user_repository.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';
import 'watch_history_state.dart';

/// Common cursor-pagination lifecycle shared by the two watch-history tabs.
abstract class WatchHistoryController<T>
    extends Notifier<WatchHistoryListState<T>>
    with PaginationMixin<T, WatchHistoryListState<T>> {
  UserRepository get _repository => ref.read(userRepositoryProvider);

  WatchHistoryClearScope get clearScope;

  bool _bootstrapped = false;

  @override
  WatchHistoryListState<T> build() {
    // Profile embeds only watch one content-type at a time; keepAlive so
    // switching drama ↔ video (or leaving the profile tab) does not wipe
    // the already-fetched grid before the next silent revalidate.
    ref.keepAlive();

    // Watch-history titles and other display fields are localized by the API
    // through Accept-Language. Refresh an already loaded tab when the app
    // language changes so kept-alive lists do not retain the previous locale.
    ref.listen<String>(localeCodeProvider, (previous, next) {
      if (previous == null || previous == next || !state.isInitialized) return;

      // A quiet reload supersedes an in-flight request as well. This matters
      // when the locale changes while the previous language is still loading.
      state = state.copyWith(clearLastError: true);
      unawaited(reloadFirstPage(showLoading: false));
    });

    if (_bootstrapped) {
      return state;
    }
    _bootstrapped = true;

    // Profile embeds only `ref.watch` this provider (no WatchHistoryContent
    // lifecycle). Kick off the first fetch when the provider is first bound,
    // otherwise the grid stays on the uninitialized skeleton forever.
    Future.microtask(() {
      if (ref.mounted) unawaited(ensureLoaded());
    });

    return WatchHistoryListState<T>();
  }

  @override
  PaginationState<T> get pagination => state.pagination;

  @override
  bool get isLoading => state.isLoading;

  @override
  void setPaginationState(PaginationState<T> pagination, {bool? isLoading}) {
    state = state.copyWith(pagination: pagination, isLoading: isLoading);
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error, clearLastError: error == null);
  }

  /// Loads a tab only once; explicit pull-to-refresh still calls [refresh].
  Future<void> ensureLoaded() async {
    if (state.isInitialized) return;
    state = state.copyWith(isInitialized: true);
    await refresh();
  }

  /// Loads on first use; subsequent visits quietly refresh page one.
  ///
  /// Keeps the previous grid painted (stale-while-revalidate) so profile /
  /// standalone tab switches do not flash the skeleton.
  Future<void> revalidate() async {
    if (!state.isInitialized) {
      await ensureLoaded();
      return;
    }
    await reloadFirstPage(showLoading: false);
  }

  @override
  Future<void> refresh() async {
    state = state.copyWith(clearLastError: true);
    await super.refresh();
  }

  /// Clears only the history represented by this controller.
  Future<Result<void>> clearHistory() async {
    if (state.isClearing) {
      return Result.failure(
        ApiError.unknown('Watch history is already being cleared'),
      );
    }

    state = state.copyWith(isClearing: true, clearLastError: true);
    final result = await _repository.clearWatchHistory(scope: clearScope);
    if (!ref.mounted) return result;

    if (result.isSuccess) {
      state = state.copyWith(
        isClearing: false,
        pagination: PaginationState<T>(hasMore: false),
        clearLastError: true,
      );
    } else {
      state = state.copyWith(isClearing: false, lastError: result.errorOrNull);
    }
    return result;
  }
}

class WatchHistoryDramaController
    extends WatchHistoryController<WatchHistoryDrama> {
  @override
  WatchHistoryClearScope get clearScope => WatchHistoryClearScope.drama;

  @override
  Future<Result<PageDto<WatchHistoryDrama>>> fetchPage({String? mark}) {
    return ref.read(userRepositoryProvider).getWatchHistoryDramas(mark: mark);
  }
}

class WatchHistoryVideoController
    extends WatchHistoryController<WatchHistoryVideo> {
  @override
  WatchHistoryClearScope get clearScope => WatchHistoryClearScope.video;

  @override
  Future<Result<PageDto<WatchHistoryVideo>>> fetchPage({String? mark}) {
    return ref.read(userRepositoryProvider).getWatchHistoryVideos(mark: mark);
  }
}
