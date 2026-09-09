import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/debouncer.dart';
import '../core/logging_request_policy_observer.dart';
import '../core/request_coalescer.dart';
import '../core/request_keys.dart';
import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../model/watch_history_model.dart';
import '../provider/auth_providers.dart';
import '../provider/core_providers.dart';
import '../provider/repository_providers.dart';
import '../repositories/drama_repository.dart';
import '../repositories/user_repository.dart';
import 'auth_controller.dart';

/// Global in-memory queue that batches watch-history reports (1–20 items).
class WatchHistoryBatchReporter extends Notifier<int>
    with WidgetsBindingObserver {
  @visibleForTesting
  static int maxBatchSize = StoryConstants.watchHistoryBatchMaxItems;

  @visibleForTesting
  static Duration flushDelay = StoryConstants.watchHistoryBatchFlushDelay;

  late AuthController _auth;
  late UserRepository _repository;

  final Map<int, int> _pending = {};
  final Debouncer _flushDebouncer =
      TimerDebouncer(observer: debugRequestPolicyObserver);
  late RequestCoalescer _flushCoalescer;

  @override
  int build() {
    // Capture during build — flush() is called from other providers' onDispose
    // and must not ref.read inside Riverpod life-cycle callbacks.
    _flushCoalescer = ref.read(requestCoalescerProvider);
    _auth = ref.read(authControllerProvider.notifier);
    _repository = ref.read(userRepositoryProvider);
    WidgetsBinding.instance.addObserver(this);
    ref.listen<String?>(currentUserIdProvider, (prev, next) {
      if (prev != next) {
        _clearPending();
      }
    });
    ref.onDispose(() {
      _flushDebouncer.cancelAll();
      WidgetsBinding.instance.removeObserver(this);
    });
    return _pending.length;
  }

  /// Queues one episode view. Duplicate ids keep the latest [watchedAt].
  void enqueue(int episodeId, {int? watchedAt}) {
    final at = watchedAt ?? DateTime.now().millisecondsSinceEpoch;
    final existing = _pending[episodeId];
    if (existing == null || at > existing) {
      _pending[episodeId] = at;
    }
    _syncPendingCountState();
    _scheduleDebouncedFlush();
    if (_pending.length >= maxBatchSize) {
      unawaited(flush());
    }
  }

  void _syncPendingCountState() {
    Future.microtask(() {
      if (!ref.mounted) return;
      state = _pending.length;
    });
  }

  @visibleForTesting
  int pendingCountForTest() => _pending.length;

  Future<void> flush() {
    if (_pending.isEmpty) return Future<void>.value();
    return _flushCoalescer.run(RequestKeys.watchHistoryFlush, _runFlush);
  }

  Future<void> _runFlush() async {
    _flushDebouncer.cancel(RequestKeys.watchHistoryFlush);

    await _auth.ready;
    if (!_auth.isLoggedIn) return;

    while (_pending.isNotEmpty && _auth.isLoggedIn) {
      final batch = _takeBatch(maxBatchSize);
      if (batch.isEmpty) break;

      final result = await _repository.reportWatchHistory(
        WatchHistoryReportRequest(items: batch),
      );
      if (result.isFailure) {
        _mergeBack(batch);
        StoryLogger.w(
          'Watch-history batch discarded after retries: ${result.errorOrNull}',
          tag: 'WatchHistory',
        );
        break;
      }
    }

    if (!ref.mounted) return;
    _syncPendingCountState();
    if (_pending.isNotEmpty) {
      _scheduleDebouncedFlush();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(flush());
    }
  }

  void _scheduleDebouncedFlush() {
    if (!ref.mounted) return;
    _flushDebouncer(
      RequestKeys.watchHistoryFlush,
      () {
        if (!ref.mounted) return;
        unawaited(flush());
      },
      delay: flushDelay,
    );
  }

  List<WatchHistoryReportItem> _takeBatch(int maxItems) {
    final keys = _pending.keys.take(maxItems).toList(growable: false);
    final batch = <WatchHistoryReportItem>[];
    for (final episodeId in keys) {
      final watchedAt = _pending.remove(episodeId);
      if (watchedAt == null) continue;
      batch.add(
        WatchHistoryReportItem(episodeId: episodeId, watchedAt: watchedAt),
      );
    }
    return batch;
  }

  void _mergeBack(List<WatchHistoryReportItem> items) {
    for (final item in items) {
      final existing = _pending[item.episodeId];
      if (existing == null || item.watchedAt > existing) {
        _pending[item.episodeId] = item.watchedAt;
      }
    }
  }

  void _clearPending() {
    _pending.clear();
    _flushDebouncer.cancel(RequestKeys.watchHistoryFlush);
    _syncPendingCountState();
  }
}

/// Reports one effective episode view to the authenticated user's history.
///
/// Callers own the effective-view policy (currently ≥1s play threshold).
/// This function validates the id and enqueues a batch flush handled by
/// [WatchHistoryBatchReporter].
void reportWatchHistory(Ref ref, String rawEpisodeId, EpisodeTrackEvent event) {
  final episodeId = int.tryParse(rawEpisodeId.trim());
  if (episodeId == null) {
    StoryLogger.w(
      'Watch-history report skipped: invalid episodeId=$rawEpisodeId',
      tag: 'WatchHistory',
    );
    return;
  }
  Future.microtask(() {
    if (!ref.mounted) return;
    ref.read(watchHistoryBatchReporterProvider.notifier).enqueue(episodeId);
  });
}

/// Global watch-history batch queue (API accepts 1–20 items per request).
final watchHistoryBatchReporterProvider =
    NotifierProvider<WatchHistoryBatchReporter, int>(
      WatchHistoryBatchReporter.new,
    );
