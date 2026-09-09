import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import 'feed_media_prefetch.dart';
import '../services/video_precache_service.dart';

/// Handles prefetching of video metadata and segments for adjacent episodes.
class FeedPrefetchOrchestrator {
  final Ref _ref;
  final String _dramaId;
  final int _totalEpisodes;

  final void Function(int episodeNo) onPrefetchStarted;
  final void Function(int episodeNo, DramaPlayResponse play) onPrefetchSuccess;
  final void Function(int episodeNo, Object error) onPrefetchError;

  int _prefetchGeneration = 0;
  final List<Timer> _prefetchTimers = [];
  final Set<int> _diskWarmRequested = <int>{};

  FeedPrefetchOrchestrator({
    required this._ref,
    required this._dramaId,
    required this._totalEpisodes,
    required this.onPrefetchStarted,
    required this.onPrefetchSuccess,
    required this.onPrefetchError,
  });

  /// Metadata and segment warming are independent.
  ///
  /// Existing play metadata only skips a metadata-only request. When
  /// [warmDisk] is true we still resolve the cached play and precache its
  /// leading segments.
  static bool shouldPrefetch({
    required bool hasPlayData,
    required bool warmDisk,
  }) {
    return !hasPlayData || warmDisk;
  }

  void cancelAll() {
    _prefetchGeneration++;
    for (final t in _prefetchTimers) {
      t.cancel();
    }
    _prefetchTimers.clear();
    // Do NOT clear _diskWarmRequested — in-flight metadata requests that
    // return after generation bump should still complete their already-
    // budgeted disk warm I/O.  Entries are consumed (remove) when the
    // response arrives; the set is bounded by [_totalEpisodes].
  }

  void scheduleAdjacent({
    required int currentEpisode,
    required Set<int> nativePreloadedEpisodeNos,
    required Set<int> nativePreloadInFlightEpisodeNos,
    required bool Function(int episodeNo) hasPlayData,
    required DramaPlayResponse? Function(int episodeNo) playDataFor,
  }) {
    cancelAll();

    final generation = _prefetchGeneration;
    final connectivity = _ref.read(connectivityProvider);
    final isWifi = connectivity.isWifi;

    // Forward window: more aggressive on WiFi, conservative on cellular.
    final forwardWindow = isWifi
        ? StoryConstants.prefetchWindowWifi
        : StoryConstants.prefetchWindowCellular;
    // Backward window: always small (backward navigation is rare).
    const backwardWindow = StoryConstants.prefetchWindowBackward;

    // Connection-aware prefetch budget (WiFi: full, cellular: ¼).
    const cellularBudgetRatio = StoryConstants.prefetchCellularBudgetRatio;

    // Prefetch forward episodes in priority order (nearest first).
    for (var i = 1; i <= forwardWindow; i++) {
      final epNo = currentEpisode + i;
      if (epNo > _totalEpisodes) break;

      final nativeCovered = _isNativeCovered(
        epNo,
        nativePreloadedEpisodeNos,
        nativePreloadInFlightEpisodeNos,
      );
      // WiFi: disk heads within [prefetchDiskWindowWifi] (skip N+1 when
      // native already owns it; N+2 always gets a partial disk warm).
      // Farther forward rungs still get metadata. Cellular: only immediate
      // next when native misses.
      final withinDiskWindow = isWifi
          ? i <= StoryConstants.prefetchDiskWindowWifi
          : i == 1;
      final warmDisk =
          withinDiskWindow &&
          (isWifi ? (i > 1 || !nativeCovered) : !nativeCovered);

      if (hasPlayData(epNo) && !warmDisk) {
        continue;
      }
      if (!shouldPrefetch(hasPlayData: hasPlayData(epNo), warmDisk: warmDisk)) {
        continue;
      }

      final distance = i;
      _prefetchTimers.add(
        Timer(StoryDurations.prefetchInterRequestDelay * (i - 1), () {
          if (_prefetchGeneration == generation) {
            final stillNeedWarm =
                warmDisk &&
                (i > 1 ||
                    !_isNativeCovered(
                      epNo,
                      nativePreloadedEpisodeNos,
                      nativePreloadInFlightEpisodeNos,
                    ));
            final wifiDiskRatio =
                StoryConstants.prefetchDiskBudgetRatioForDistance(distance);
            _prefetchEpisode(
              epNo,
              budgetRatio: isWifi
                  ? wifiDiskRatio
                  : cellularBudgetRatio * wifiDiskRatio,
              warmDisk: stillNeedWarm,
              hasPlayData: hasPlayData,
              playDataFor: playDataFor,
              priority: i == 1
                  ? PrecachePriority.next
                  : i == 2
                      ? PrecachePriority.ahead
                      : PrecachePriority.background,
            );
          }
        }),
      );
    }

    // Prefetch previous episode (deferred, low priority, metadata only).
    if (currentEpisode > 1 && backwardWindow > 0) {
      final prev = currentEpisode - 1;
      if (!hasPlayData(prev)) {
        _prefetchTimers.add(
          Timer(StoryDurations.prefetchPreviousDelay, () {
            if (_prefetchGeneration == generation) {
              _prefetchEpisode(
                prev,
                budgetRatio: isWifi ? 1.0 : cellularBudgetRatio,
                warmDisk: false,
                hasPlayData: hasPlayData,
                playDataFor: playDataFor,
                priority: PrecachePriority.background,
              );
            }
          }),
        );
      }
    }
  }

  void warmNextFromProgress({
    required int positionMs,
    required int durationMs,
    required int currentEpisode,
    required Set<int> nativePreloadedEpisodeNos,
    required Set<int> nativePreloadInFlightEpisodeNos,
    required bool Function(int episodeNo) hasPlayData,
    required DramaPlayResponse? Function(int episodeNo) playDataFor,
  }) {
    if (durationMs <= 0) return;
    final ratio = positionMs / durationMs;
    if (ratio < StoryConstants.feedProgressWarmNextRatio) return;

    final next = currentEpisode + 1;
    if (next > _totalEpisodes) return;

    // Native preload already covers N+1 — avoid double disk warm.
    if (_isNativeCovered(
      next,
      nativePreloadedEpisodeNos,
      nativePreloadInFlightEpisodeNos,
    )) {
      return;
    }

    final isWifi = _ref.read(connectivityProvider).isWifi;
    _prefetchEpisode(
      next,
      budgetRatio: isWifi ? 1.0 : StoryConstants.prefetchCellularBudgetRatio,
      hasPlayData: hasPlayData,
      playDataFor: playDataFor,
      priority: PrecachePriority.next,
    );
  }

  void _prefetchEpisode(
    int episodeNo, {
    double budgetRatio = 1.0,
    bool warmDisk = true,
    required bool Function(int episodeNo) hasPlayData,
    required DramaPlayResponse? Function(int episodeNo) playDataFor,
    PrecachePriority priority = PrecachePriority.ahead,
  }) {
    if (episodeNo < 1 || episodeNo > _totalEpisodes) return;
    final existingPlay = playDataFor(episodeNo);
    if (existingPlay != null) {
      if (warmDisk) {
        _warmPlay(existingPlay, budgetRatio: budgetRatio, priority: priority);
      }
      return;
    }
    if (!shouldPrefetch(
      hasPlayData: hasPlayData(episodeNo),
      warmDisk: warmDisk,
    )) {
      return;
    }
    if (hasPlayData(episodeNo)) {
      // Metadata request already in flight. Remember that its eventual result
      // must also warm disk instead of launching a duplicate repository call.
      if (warmDisk) _diskWarmRequested.add(episodeNo);
      return;
    }

    final generation = _prefetchGeneration;
    onPrefetchStarted(episodeNo);

    _ref
        .read(dramaRepositoryProvider)
        .prefetchEpisode(_dramaId, episodeNo)
        .then((play) {
          if (play == null) {
            if (_prefetchGeneration == generation) {
              onPrefetchError(episodeNo, 'prefetch empty');
            }
            return;
          }
          // Deliver metadata only when generation matches (controller
          // still cares about this episode).
          if (_prefetchGeneration == generation) {
            onPrefetchSuccess(episodeNo, play);
          }
          // Complete disk warm regardless of generation — the I/O was
          // already budgeted and the result is useful even if the
          // controller has moved on to a different episode.
          if (warmDisk || _diskWarmRequested.remove(episodeNo)) {
            _warmPlay(play, budgetRatio: budgetRatio, priority: priority);
          }
        })
        .catchError((Object e) {
          if (_prefetchGeneration == generation) {
            StoryLogger.w('预加载失败: $episodeNo', error: e, tag: 'Feed');
            onPrefetchError(episodeNo, e);
          }
        });
  }

  void _warmPlay(
    DramaPlayResponse play, {
    required double budgetRatio,
    required PrecachePriority priority,
  }) {
    unawaited(
      FeedMediaPrefetch.warmPlay(
        play,
        budgetRatio: budgetRatio,
        priority: priority,
      ),
    );
  }

  bool _isNativeCovered(
    int episodeNo,
    Set<int> nativePreloadedEpisodeNos,
    Set<int> nativePreloadInFlightEpisodeNos,
  ) {
    return nativePreloadedEpisodeNos.contains(episodeNo) ||
        nativePreloadInFlightEpisodeNos.contains(episodeNo);
  }
}
