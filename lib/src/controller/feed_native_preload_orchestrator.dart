part of 'video_feed_controller.dart';

/// Native preload orchestration for [VideoFeedController].
///
/// Owns the logic for choosing preload slots, scheduling adjacent native
/// preloads, executing the actual loadUrl on inactive engines, and
/// prefetch/warm coordination. Kept as a same-library extension to access
/// private controller fields while isolating preload coordination in one file.
extension FeedNativePreloadOrchestrator on VideoFeedController {
  /// Maintain adjacent native preloads after an episode change.
  void maintainAdjacentNativePreloads() {
    _removeStalePreloadEntries();
    final desired = <int>{
      if (_currentEpisodeNo > 1) _currentEpisodeNo - 1,
      if (_currentEpisodeNo < totalEpisodes) _currentEpisodeNo + 1,
    };
    for (var slot = 0; slot < 3; slot++) {
      final loadingEpisode = _slots[slot].loadingEpisodeNo;
      if (loadingEpisode != null && !desired.contains(loadingEpisode)) {
        // Abandon bookkeeping + Dart-side pending lock. Leaving
        // PlaybackEngine.hasPendingLoad set blocked every later swipe onto
        // that neighbor (choosePreloadSlot skipped pending engines).
        _slots[slot].reset();
        final engine = _engineForSlot(slot);
        if (engine.hasPendingLoad) {
          engine.forceAbandonPendingLoad();
        }
      }
    }
    startNativePreload(_currentEpisodeNo - 1);
    startNativePreload(_currentEpisodeNo + 1);
  }

  /// Decode [episodeNo] on one of the two inactive slots.
  ///
  /// Metadata prefetch ([_prefetchedEpisodeNos]) is intentionally NOT a skip
  /// condition — Hive/API cache is not a decoded native preload.
  void startNativePreload(int episodeNo, {bool force = false}) {
    if (episodeNo < 1 || episodeNo > totalEpisodes) return;
    if (_slot.isMappedOrLoading(episodeNo)) return;
    final slot = _choosePreloadSlot(episodeNo, force: force);
    if (slot == null || slot == _activeEngineIndex) return;

    final engine = _engineForSlot(slot);
    if (engine.currentEpisodeNo == episodeNo && engine.currentPlay != null) {
      _slot.mapEpisodeToSlot(episodeNo, slot);
      _notify();
      return;
    }
    // Do not stack a second loadUrl onto an engine that is still draining.
    if (engine.hasPendingLoad) {
      StoryLogger.d(
        'preload deferred ep=$episodeNo slot=$slot (native load draining)',
        tag: 'Feed',
      );
      // When the drain finishes, retry the desired adjacent preload once.
      final pending = engine;
      _unawaitedLogged(() async {
        await pending.cancelStaleLoad(waitBudget: Duration.zero);
        if (!_canContinue()) return;
        if (pending.hasPendingLoad) {
          pending.forceAbandonPendingLoad();
        }
        if (_slot.isMappedOrLoading(episodeNo)) return;
        final stillNeeded =
            (episodeNo - _currentEpisodeNo).abs() <= 1 ||
            (episodeNo - (_loadedEpisodeNo ?? _currentEpisodeNo)).abs() <= 1;
        if (!stillNeeded) return;
        startNativePreload(episodeNo, force: force);
      }(), reason: 'preload-after-drain-ep=$episodeNo');
      return;
    }

    final generation = ++_slots[slot].generation;
    _slots[slot].loadingEpisodeNo = episodeNo;
    _slot.unmapSlotsWhere((_, mappedSlot) => mappedSlot == slot);
    final future = _doNativePreload(episodeNo, slot, generation, engine);
    _slots[slot].inFlightFuture = future;
    _unawaitedLogged(
      future.then((_) {}).whenComplete(() {
        if (identical(_slots[slot].inFlightFuture, future)) {
          _slots[slot].inFlightFuture = null;
        }
      }),
      reason: 'native-preload-inflight-ep=$episodeNo',
    );
  }

  Future<bool> _doNativePreload(
    int episodeNo,
    int slot,
    int generation,
    PlaybackEngine engine,
  ) async {
    try {
      final fetched = await resolveEpisodeDataCommon(
        episodeNo,
        forPreload: true,
      );
      if (fetched == null ||
          !_canContinue(() => generation == _slots[slot].generation)) {
        if (generation == _slots[slot].generation) {
          _slots[slot].loadingEpisodeNo = null;
        }
        return false;
      }
      if (engine.nativeController == null) {
        if (generation == _slots[slot].generation) {
          _slots[slot].loadingEpisodeNo = null;
        }
        return false;
      }

      // Header-only warm: do not pre-apply into the shared jar (preloadEpisode
      // already skips jar when Cookie headers are present).
      if (!_canContinue(() => generation == _slots[slot].generation)) {
        return false;
      }

      final ok = await engine.preloadEpisode(
        play: fetched.play,
        url: fetched.url,
        headers: fetched.headers,
        episodeNo: episodeNo,
      );

      if (generation != _slots[slot].generation) {
        // Load may have finished, but this generation was superseded — drop.
        return false;
      }

      if (ok) {
        // Mute-play prime steals the shared decoder from the visible card
        // (frozen texture + continuing audio). Recommend always skips it;
        // drama skips while the active slot is actually playing.
        final activePlaying =
            _isPlaying &&
            _status == FeedPlaybackStatus.ready &&
            _currentEpisodeNo > 0;
        if (!activePlaying) {
          await engine.primePreloadFirstFrame(
            shouldContinue: () => generation == _slots[slot].generation,
          );
        } else {
          StoryLogger.d(
            'skip preload prime ep=$episodeNo: active playing',
            tag: 'Feed',
          );
        }
        if (generation == _slots[slot].generation &&
            engine.hasPresentedFirstFrame) {
          _captureEpisodeFrame(engine, episodeNo);
        }
      }

      if (generation != _slots[slot].generation) {
        return false;
      }

      _slots[slot].loadingEpisodeNo = null;
      if (ok && _alive) {
        _slot.mapEpisodeToSlot(episodeNo, slot);
        StoryLogger.d(
          '🎯 就绪: 第 $episodeNo 集已预加载到 slot=$slot '
          'frame=${engine.hasPresentedFirstFrame}',
          tag: 'Feed',
        );
        _notify();
        return true;
      }
      return false;
    } catch (e, st) {
      StoryLogger.w(
        'Native preload failed ep=$episodeNo',
        error: e,
        stackTrace: st,
        tag: 'Feed',
      );
      if (generation == _slots[slot].generation) {
        _slots[slot].loadingEpisodeNo = null;
      }
      return false;
    }
  }

  // ─── Prefetch coordination ─────────────────────────────────

  void prefetchAdjacent(int currentEpisode) {
    _prefetch.scheduleAdjacent(
      currentEpisode: currentEpisode,
      nativePreloadedEpisodeNos: preloadedEpisodeNos,
      nativePreloadInFlightEpisodeNos: _nativePreloadInFlightEpisodeNos,
      hasPlayData: (epNo) =>
          _episodeStates[epNo]?.play != null ||
          _episodeStates[epNo]?.isPrefetching == true,
      playDataFor: (epNo) => _episodeStates[epNo]?.play,
    );
  }

  /// Bounds the in-memory episode state map to avoid unbounded growth.
  void evictDistantStates(int currentEpisode) {
    // Only the in-memory play-metadata map is bounded here. The native disk
    // segment cache is managed by Media3's shared SimpleCache LRU, capped by
    // StorySdk's androidDiskCacheMaxBytes (250MB) — there is no per-URL evict
    // API, so distant segments are reclaimed by native LRU, not from here.
    const window = StoryConstants.episodeStateEvictWindow;
    final before = _episodeStates.length;
    _episodeStates.removeWhere((ep, _) => (ep - currentEpisode).abs() > window);
    if (_episodeStates.length != before) {
      _episodeStatesDirty = true;
    }
  }

  /// Disk-warm N+1 once the user is deep into the current episode, without
  /// replacing the native inactive slot (keeps reverse-swipe swap ready).
  void maybeWarmNextFromProgress(int positionMs, int durationMs) {
    if (durationMs <= 0) return;
    if (positionMs / durationMs < StoryConstants.feedProgressWarmNextRatio) {
      return;
    }
    final next = _currentEpisodeNo + 1;
    if (next > totalEpisodes) return;
    if (_progressWarmedNextEpisode == next) return;
    if (_slot.isMappedOrLoading(next)) return;
    _progressWarmedNextEpisode = next;

    _prefetch.warmNextFromProgress(
      positionMs: positionMs,
      durationMs: durationMs,
      currentEpisode: _currentEpisodeNo,
      nativePreloadedEpisodeNos: preloadedEpisodeNos,
      nativePreloadInFlightEpisodeNos: _nativePreloadInFlightEpisodeNos,
      hasPlayData: (epNo) =>
          _episodeStates[epNo]?.play != null ||
          _episodeStates[epNo]?.isPrefetching == true,
      playDataFor: (epNo) => _episodeStates[epNo]?.play,
    );
  }
}
