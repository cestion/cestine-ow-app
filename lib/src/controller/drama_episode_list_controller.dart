import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/request_coalescer.dart';
import '../core/request_keys.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import 'drama_episode_list_state.dart';

/// Paginated public episode list for a drama (picker sheet + detail tab).
class DramaEpisodeListController extends Notifier<DramaEpisodeListState> {
  DramaEpisodeListController(this._dramaId);

  final String _dramaId;
  String? _mark;

  /// Bumped on first-page loads so in-flight load-more results are discarded.
  int _loadEpoch = 0;

  late RequestCoalescer _coalescer;

  @override
  DramaEpisodeListState build() {
    _coalescer = ref.read(requestCoalescerProvider);
    Future<void>.microtask(load);
    return const DramaEpisodeListState(isLoading: true);
  }

  /// Reconciles the first page with the server.
  ///
  /// The first open has no snapshot and therefore shows the normal loading
  /// state. A reopened picker keeps rendering its retained items while this
  /// request runs silently.
  Future<void> synchronize() => load(forceRefresh: true);

  Future<void> load({bool more = false, bool forceRefresh = false}) {
    if (_dramaId.isEmpty) return Future.value();
    if (more) {
      if (!_hasMore || state.isLoadingMore || state.isLoading) {
        return Future.value();
      }
      // Load-more stays off the shared first-page key so synchronize() cannot
      // join a pagination future and silently drop forceRefresh.
      final epoch = _loadEpoch;
      return _load(more: true, forceRefresh: false, epoch: epoch);
    }
    // First-page re-entry while loading joins the same in-flight future.
    return _coalescer.run(
      RequestKeys.dramaEpisodeListFirst(_dramaId),
      () {
        _loadEpoch++;
        return _load(
          more: false,
          forceRefresh: forceRefresh,
          epoch: _loadEpoch,
        );
      },
    );
  }

  bool get _hasMore => state.hasMore;

  Future<void> _load({
    required bool more,
    required bool forceRefresh,
    required int epoch,
  }) async {
    final showInitialLoading = !more && state.items.isEmpty;
    state = state.copyWith(
      isLoading: more ? state.isLoading : showInitialLoading,
      isLoadingMore: more,
      clearError: !more,
    );

    final result = await ref
        .read(dramaRepositoryProvider)
        .listEpisodes(
          _dramaId,
          mark: more ? _mark : null,
          forceRefresh: !more && forceRefresh,
        );
    if (!ref.mounted || epoch != _loadEpoch) return;

    result.when(
      success: (page) {
        final next = page.list ?? const <DramaEpisodeListItem>[];
        _mark = page.mark;
        state = state.copyWith(
          items: more ? [...state.items, ...next] : next,
          hasMore: page.hasMore ?? false,
          isLoading: false,
          isLoadingMore: false,
          clearError: true,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: more ? null : error,
        );
      },
    );
  }
}
