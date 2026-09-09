part of 'video_feed_controller.dart';

/// Result of [_prepareColdActivation] shared by activate paths.
typedef ColdActivationPrep = ({PlaybackEpisodeData fetched, bool alreadyKnown});

/// Episode activation pipeline for [VideoFeedController].
///
/// Drama-side counterpart of [RecommendActivatePipeline] — implements the same
/// resume → promote → cold choreography via [FeedActivateOrchestrator] but
/// keyed by episode number instead of flat card index.
///
/// Owns enqueue / neighbor-swap / jump / controlled-cold / preload-swap.
/// Same-library extension keeps private controller fields accessible while
/// concentrating activation strategy in one file (lower regression radius).
extension FeedActivationPipeline on VideoFeedController {
  Future<void> _enqueueActivate(int episodeNo, {required String reason}) async {
    if (!_canContinue()) return;
    if (episodeNo < 1 || episodeNo > totalEpisodes) return;
    if (episodeNo == _currentEpisodeNo && _isActiveEpisodeReady) {
      return;
    }
    // Activating means the feed is front-and-center again (picker jump /
    // detail pop) — unexpected-pause recovery must be armed for the new
    // episode even if onPageRevealed never ran.
    _visibility = FeedVisibility.active;
    // Episode change dismisses the user-pause affordance so swipe does not
    // keep flashing the center play button from the previous page.
    if (_isUserPaused) {
      _isUserPaused = false;
      _notify();
    }
    _queuedActivateEpisode = episodeNo;
    _queuedActivateReason = reason;
    // Stop audible bleed immediately — PageView may already show the next
    // page while cookie promote / swap is still in flight.
    await silenceExceptEpisode(episodeNo);
    if (!_canContinue()) return;
    if (_activateRunning) return;
    _activateRunning = true;
    try {
      while (_canContinue()) {
        final target = _queuedActivateEpisode;
        final queuedReason = _queuedActivateReason ?? reason;
        if (target == null) break;
        _queuedActivateEpisode = null;
        _queuedActivateReason = null;
        // Re-assert silence for the latest target (rapid fling coalescing).
        await silenceExceptEpisode(target);
        if (!_canContinue()) return;
        await _activateEpisode(target, reason: queuedReason);
      }
    } on StateError catch (e) {
      if (_disposed || e.message.contains('disposed')) return;
      rethrow;
    } finally {
      _activateRunning = false;
    }
  }

  /// Advance pager identity + status before an activate path settles.
  void _beginActivateSelecting(
    int episodeNo, {
    FeedPlaybackStatus status = FeedPlaybackStatus.loading,
  }) {
    if (_currentEpisodeNo != episodeNo) {
      _lastFrameRenderedAt = null;
      _lastFrameEpisode = null;
      _recovery.resetBudgets();
    }
    _currentEpisodeNo = episodeNo;
    _status = status;
    _autoAdvanceToEpisodeNo = null;
    _error = null;
    _notify();
  }

  Future<void> _activateEpisode(int episodeNo, {required String reason}) async {
    if (!_canContinue()) return;
    if (episodeNo < 1 || episodeNo > totalEpisodes) return;
    if (episodeNo == _loadedEpisodeNo && _status == FeedPlaybackStatus.ready) {
      // 已经加载且就绪，只需更新当前页
      if (episodeNo != _currentEpisodeNo) {
        _currentEpisodeNo = episodeNo;
        _autoAdvanceToEpisodeNo = null;
        _notify();
      }
      return;
    }

    _beginFeedActivateTelemetry(
      episodeNo,
      episodeId: _episodeStates[episodeNo]?.play?.episodeId ??
          _currentPlay?.episodeId,
    );

    // ─── Preload swap fast path ──────────────────────────────
    // Prefer swapping a neighbor that already holds / is loading the target.
    // Early-activate often fires while native preload is still in-flight; the
    // old cold path cancelled that work and reloaded on active (~3s+), also
    // destroying the outgoing episode needed for reverse swipe.
    final swapped = await _tryActivateFromNeighbor(episodeNo, reason: reason);
    if (swapped) return;
    if (_isActivateSuperseded(episodeNo)) return;

    final loaded = _loadedEpisodeNo;
    final isAdjacent = loaded != null && (episodeNo - loaded).abs() == 1;
    if (isAdjacent) {
      // Keep the outgoing episode decoded on the current slot: load the
      // destination onto an inactive slot, then swap.
      var neighborReady = await _loadAdjacentOntoNeighbor(
        episodeNo,
        reason: reason,
      );
      if (!neighborReady && !_isActivateSuperseded(episodeNo)) {
        neighborReady = await _loadAdjacentOntoNeighbor(
          episodeNo,
          reason: '$reason-retry',
        );
      }
      if (neighborReady) {
        _clearAdjacentRetry(episodeNo);
        return;
      }
      if (_isActivateSuperseded(episodeNo)) return;

      // Neighbor loads failed → one more swap attempt if preload finished
      // during the failed loads, else controlled cold (keep reverse).
      final lateNeighbor = await _tryActivateFromNeighbor(
        episodeNo,
        reason: '$reason-adjacent-rescue',
      );
      if (lateNeighbor) {
        _clearAdjacentRetry(episodeNo);
        return;
      }
      if (_isActivateSuperseded(episodeNo)) return;

      StoryLogger.w(
        '邻集邻槽失败，受控冷路径 episode=$episodeNo reverse=$loaded',
        tag: 'Feed',
      );
      final coldOk = await _activateAdjacentControlledCold(
        episodeNo,
        reverseEpisode: loaded,
        reason: '$reason-adjacent-cold',
      );
      if (coldOk) {
        _clearAdjacentRetry(episodeNo);
        return;
      }
      if (_isActivateSuperseded(episodeNo)) return;

      // Cold also failed — show buffering (spinner) while one more attempt
      // is scheduled; `_scheduleAdjacentRetry` will force cold again after
      // its budget, or bounce the pager identity stays on [episodeNo].
      StoryLogger.w('邻集受控冷路径失败，进入恢复缓冲 episode=$episodeNo', tag: 'Feed');
      _beginActivateSelecting(episodeNo, status: FeedPlaybackStatus.buffering);
      _scheduleAdjacentRetry(episodeNo, reason: reason);
      return;
    }

    _clearAdjacentRetry(episodeNo);

    // Jump / non-adjacent: race a silent preload on an inactive slot so a
    // quick hit can still swap instead of always paying full cold loadUrl.
    final jumped = await _tryJumpViaSilentPreload(episodeNo, reason: reason);
    if (jumped) return;
    if (_isActivateSuperseded(episodeNo)) return;

    final switchStopwatch = Stopwatch()..start();
    final generation = ++_switchGeneration;
    // Non-adjacent cold path only. Keep any slot already working on
    // the destination episode — never cancel the target then reload it.
    final previousEpisodeNo = _loadedEpisodeNo;

    StoryLogger.d('=== 切换剧集 (reason=$reason) ===', tag: 'Feed');
    StoryLogger.d('$previousEpisodeNo → $episodeNo', tag: 'Feed');

    final prep = await _prepareColdActivation(
      episodeNo,
      generation: generation,
      keepPreloads: {episodeNo},
    );
    if (prep == null) return;

    // Last chance: neighbor preload often finishes during metadata resolve.
    // Without this we cold-loadUrl on active while slot B already holds the
    // episode (seen as path=cold + "预加载完成" for the same ep — A/V freeze risk).
    final rescued = await _tryActivateFromNeighbor(
      episodeNo,
      reason: '$reason-cold-rescue',
    );
    if (rescued) return;
    if (_isActivateSuperseded(episodeNo)) return;
    if (!_isCurrentGeneration(generation)) return;

    await _runColdApplyPlayback(
      episodeNo: episodeNo,
      prep: prep,
      generation: generation,
      reason: reason,
      pathLabel: 'cold',
      stopwatch: switchStopwatch,
      reportFailure: true,
      fetchDetail: true,
    );
  }

  /// Cookie → prefetch → applyPlayback → markReady shared by cold paths.
  Future<bool> _runColdApplyPlayback({
    required int episodeNo,
    required ColdActivationPrep prep,
    required int generation,
    required String reason,
    required String pathLabel,
    Stopwatch? stopwatch,
    bool reportFailure = false,
    bool fetchDetail = false,
  }) async {
    final cookieFut = _engine.preApplyCookies(
      prep.fetched.play,
      prep.fetched.url,
    );
    prefetchAdjacent(episodeNo);

    final ok = await _engine.applyPlayback(
      prep.fetched.play,
      prep.fetched.url,
      prep.fetched.headers,
      isSwitch: true,
      episodeNo: episodeNo,
      shouldContinue: () => _isCurrentGeneration(generation),
      cookiePreApplied: cookieFut,
      viewReadyDelay: prep.alreadyKnown
          ? StoryDurations.playerViewReadyDelaySwitch
          : StoryDurations.playerViewReadyDelay,
    );
    if (!ok || !_isCurrentGeneration(generation)) {
      if (reportFailure) {
        await _failActivationIfStillLoading(
          episodeNo,
          generation: generation,
          fallbackError: StateError('Episode switch failed'),
        );
      }
      return false;
    }

    _markEpisodeReady(episodeNo, prep.fetched.play);
    if (fetchDetail) fetchDramaDetail();
    final fromNeighbor =
        pathLabel.contains('preload') ||
        pathLabel.contains('swap') ||
        pathLabel.contains('jump');
    _reportFeedActivateTelemetry(fromNeighbor: fromNeighbor);
    FeedActivateMetrics.record(pathLabel);
    if (stopwatch != null) {
      StoryLogger.d(
        'episode_switch_ms=${stopwatch.elapsedMilliseconds} '
        'episode=$episodeNo path=$pathLabel reason=$reason',
        tag: 'Feed',
      );
    }
    return true;
  }

  /// After applyPlayback fails, await auth recovery then surface error if
  /// this episode is still the pending selection.
  Future<void> _failActivationIfStillLoading(
    int episodeNo, {
    int? generation,
    required Object fallbackError,
  }) async {
    bool stillPending() {
      if (!_alive) return false;
      if (generation != null && !_isCurrentGeneration(generation)) return false;
      if (_loadedEpisodeNo == episodeNo) return false;
      return _status == FeedPlaybackStatus.loading ||
          _status == FeedPlaybackStatus.buffering;
    }

    if (!stillPending()) return;
    final recovery = _pendingAuthRecovery;
    if (recovery != null) await recovery;
    if (!stillPending()) return;
    _status = FeedPlaybackStatus.error;
    _error ??= fallbackError;
    _notify();
  }

  /// Swap if [episodeNo] is already decoded or still loading on a neighbor.
  Future<bool> _tryActivateFromNeighbor(
    int episodeNo, {
    required String reason,
  }) async {
    var slot = _slot.readySlotForEpisode(episodeNo);
    slot ??= _slot.findInactiveSlotHolding(episodeNo);
    if (slot != null && _engineForSlot(slot).nativeController != null) {
      _slot.mapEpisodeToSlot(episodeNo, slot);
      return _activateFromPreload(
        episodeNo,
        preloadedSlot: slot,
        reason: reason,
      );
    }

    final inFlightSlot = _slot.findSlotLoadingEpisode(episodeNo);
    if (inFlightSlot == null) return false;

    _beginActivateSelecting(episodeNo);
    return _awaitThenActivateFromPreload(
      episodeNo,
      slot: inFlightSlot,
      reason: reason,
      // Hard cap — waiting forever under a poster feels worse than cold.
      raceBudget: StoryDurations.waitInFlightRaceBudget,
      allowFallbackSlot: true,
      requireNativeController: true,
    );
  }

  /// Adjacent miss: decode on an inactive slot, then swap (keeps reverse).
  Future<bool> _loadAdjacentOntoNeighbor(
    int episodeNo, {
    required String reason,
  }) async {
    StoryLogger.d('邻集经邻槽加载 episode=$episodeNo (reason=$reason)', tag: 'Feed');
    _beginActivateSelecting(episodeNo);

    // Drain every inactive slot that can accept the destination. Prefer a
    // free slot; only then attempt wedged-slot recovery on the best candidate.
    await _drainInactiveSlotsForAdjacent(episodeNo);
    if (!_canContinue(() => !_isActivateSuperseded(episodeNo))) return false;

    var slot = _choosePreloadSlot(episodeNo, force: true);
    if (slot != null && _engineForSlot(slot).hasPendingLoad) {
      final recovered = await _engineForSlot(slot).tryRecoverWedgedLoad();
      if (!_canContinue()) return false;
      if (!recovered) {
        // Try the other inactive slot before giving up.
        final other = _inactiveSlots.where((s) => s != slot).toList();
        for (final candidate in other) {
          if (!_engineForSlot(candidate).hasPendingLoad) {
            slot = candidate;
            break;
          }
          if (await _engineForSlot(candidate).tryRecoverWedgedLoad()) {
            if (!_canContinue()) return false;
            slot = candidate;
            break;
          }
        }
      }
      if (!_canContinue()) return false;
      if (slot != null && _engineForSlot(slot).hasPendingLoad) {
        StoryLogger.d(
          '邻槽仍在 draining，无法加载 episode=$episodeNo slot=$slot',
          tag: 'Feed',
        );
        return false;
      }
    }

    startNativePreload(episodeNo, force: true);
    slot = _slot.slotForEpisode(episodeNo);
    if (slot == null) return false;

    return _awaitThenActivateFromPreload(episodeNo, slot: slot, reason: reason);
  }

  /// Await in-flight native preload (optionally racing a budget), then swap.
  ///
  /// Returns `true` when the request was handled (success, supersede, or
  /// abort). Returns `false` only when the caller should try another path.
  Future<bool> _awaitThenActivateFromPreload(
    int episodeNo, {
    required int slot,
    required String reason,
    Duration? raceBudget,
    bool allowFallbackSlot = false,
    bool requireNativeController = false,
  }) async {
    final ready = raceBudget == null
        ? await _awaitInFlightPreload(episodeNo, slot)
        : await Future.any<bool>([
            _awaitInFlightPreload(episodeNo, slot),
            Future<bool>.delayed(raceBudget, () => false),
          ]);
    if (!ready || !_alive) return false;
    if (_isActivateSuperseded(episodeNo)) return true;
    final readySlot =
        _slot.readySlotForEpisode(episodeNo) ??
        (allowFallbackSlot ? slot : null);
    if (readySlot == null) return false;
    if (requireNativeController &&
        _engineForSlot(readySlot).nativeController == null) {
      return false;
    }
    return _activateFromPreload(
      episodeNo,
      preloadedSlot: readySlot,
      reason: reason,
    );
  }

  Future<void> _drainInactiveSlotsForAdjacent(int episodeNo) async {
    for (final slot in _inactiveSlots) {
      if (!_canContinue()) return;
      final engine = _engineForSlot(slot);
      if (!engine.hasPendingLoad) continue;
      // Brief chance for a just-finishing loadUrl, then unlock the slot.
      // Swipe activation cannot wait multi-second cancelStaleLoad loops —
      // both neighbors were previously left wedged forever.
      await engine.cancelStaleLoad(
        waitBudget: Duration.zero,
        extendedWait: const Duration(milliseconds: 400),
      );
      if (!_canContinue(() => !_isActivateSuperseded(episodeNo))) return;
      if (engine.hasPendingLoad) {
        engine.forceAbandonPendingLoad();
      }
    }
  }

  void _clearAdjacentRetry(int episodeNo) {
    if (_adjacentRetryEpisode == episodeNo) {
      _adjacentRetryEpisode = null;
      _adjacentRetryCount = 0;
    }
  }

  void _scheduleAdjacentRetry(int episodeNo, {required String reason}) {
    if (_adjacentRetryEpisode != episodeNo) {
      _adjacentRetryEpisode = episodeNo;
      _adjacentRetryCount = 0;
    }
    // One delayed retry, then force controlled-cold via enqueue. Avoid long
    // silent limbos where the pager page and loaded surface diverge.
    if (_adjacentRetryCount >= 1) {
      StoryLogger.d('邻集恢复重试已达上限 episode=$episodeNo', tag: 'Feed');
      _unawaitedLogged(
        _enqueueActivate(episodeNo, reason: '$reason-adjacent-cold-trigger'),
        reason: 'adjacent-cold-trigger',
      );
      return;
    }
    _adjacentRetryCount++;
    final attempt = _adjacentRetryCount;
    _unawaitedLogged(() async {
      await Future<void>.delayed(StoryDurations.adjacentRetryBaseDelay);
      if (!_canContinue(() => !_isActivateSuperseded(episodeNo))) return;
      if (episodeNo == _loadedEpisodeNo &&
          _status == FeedPlaybackStatus.ready) {
        _clearAdjacentRetry(episodeNo);
        return;
      }
      if (_currentEpisodeNo != episodeNo) return;
      // Hard deadline: if still not loaded, skip soft retry and go cold.
      if (_loadedEpisodeNo != episodeNo) {
        await _enqueueActivate(
          episodeNo,
          reason: '$reason-adjacent-cold-timeout',
        );
        return;
      }
      await _enqueueActivate(episodeNo, reason: '$reason-adjacent-retry');
    }(), reason: 'adjacent-retry-$attempt');
  }

  /// Picker / non-adjacent: briefly race silent preload before cold path.
  Future<bool> _tryJumpViaSilentPreload(
    int episodeNo, {
    required String reason,
  }) async {
    // Drop far-away in-flight preloads (e.g. ep 7 still decoding while we
    // jump to ep 1) — overlapping iOS decode freezes the active texture.
    _invalidateInactivePreloads(exceptEpisodes: {episodeNo});
    await silenceExceptEpisode(episodeNo);
    if (!_canContinue()) return false;

    // Already decoded on a neighbor — swap immediately (no race budget).
    final readyNow =
        _slot.readySlotForEpisode(episodeNo) ??
        _slot.findInactiveSlotHolding(episodeNo);
    if (readyNow != null && _engineForSlot(readyNow).nativeController != null) {
      _slot.mapEpisodeToSlot(episodeNo, readyNow);
      StoryLogger.d(
        '跳远直接命中已预载 swap episode=$episodeNo slot=$readyNow',
        tag: 'Feed',
      );
      return _activateFromPreload(
        episodeNo,
        preloadedSlot: readyNow,
        reason: '$reason-jump-ready',
      );
    }

    startNativePreload(episodeNo, force: true);
    final slot = _slot.slotForEpisode(episodeNo);
    if (slot == null) return false;

    // In-flight: await fully. A short race then cold-loadUrl on active while
    // the neighbor finishes is the freeze-prone dual-decode pattern in logs.
    final awaitingInFlight = _slots[slot].inFlightFuture != null;
    final swapped = await _awaitThenActivateFromPreload(
      episodeNo,
      slot: slot,
      reason: '$reason-jump-preload',
      raceBudget: awaitingInFlight
          ? null
          : StoryDurations.jumpPreloadRaceBudget,
      allowFallbackSlot: awaitingInFlight,
    );
    if (swapped &&
        _loadedEpisodeNo == episodeNo &&
        _isPlaying &&
        _status == FeedPlaybackStatus.ready) {
      StoryLogger.d(
        '跳远命中静载 swap episode=$episodeNo '
        'slot=${_slot.episodeForSlot(episodeNo) ?? slot}',
        tag: 'Feed',
      );
    }
    return swapped;
  }

  /// Prepare state for a cold-path episode switch.
  ///
  /// Resets playback, checks episode cache status, and resolves episode data.
  /// Returns `null` if the activation was superseded or data resolution failed.
  Future<ColdActivationPrep?> _prepareColdActivation(
    int episodeNo, {
    required int generation,
    required Set<int> keepPreloads,
  }) async {
    if (!_canContinue()) return null;
    _invalidateInactivePreloads(exceptEpisodes: keepPreloads);

    final engine = _engineForSlotOrNull(_activeEngineIndex);
    if (engine == null) return null;
    await engine.pause();
    if (!_canContinue()) return null;
    engine.reset();
    _resetPlaybackForEpisode(episodeNo, playing: false);
    final alreadyKnown =
        _playedEpisodeNos.contains(episodeNo) ||
        _episodeStates[episodeNo]?.play != null ||
        _prefetchedEpisodeNos.contains(episodeNo);
    // Cached / already-watched episodes: keep cover without spinner (UI treats
    // `loading` as non-blocking). First-time misses still use buffering.
    if (!alreadyKnown) _hidePlayerSurface();
    _status = alreadyKnown
        ? FeedPlaybackStatus.loading
        : FeedPlaybackStatus.buffering;
    _error = null;
    _autoAdvanceToEpisodeNo = null;
    _notify();

    final fetched = await resolveEpisodeDataCommon(
      episodeNo,
      forPreload: false,
    );
    if (fetched == null || !_isCurrentGeneration(generation)) return null;
    // Fast-scroll guard: if the user has already scrolled past this
    // episode, skip loading — the next _activateEpisode will take over.
    if (_currentEpisodeNo != episodeNo) return null;

    return (fetched: fetched, alreadyKnown: alreadyKnown);
  }

  /// Adjacent fallback: load on active while keeping the reverse neighbor.
  Future<bool> _activateAdjacentControlledCold(
    int episodeNo, {
    required int reverseEpisode,
    required String reason,
  }) async {
    if (!_canContinue()) return false;
    final switchStopwatch = Stopwatch()..start();
    final generation = ++_switchGeneration;

    StoryLogger.d(
      '=== 邻集受控冷路径 (reason=$reason) $reverseEpisode → $episodeNo ===',
      tag: 'Feed',
    );

    final prep = await _prepareColdActivation(
      episodeNo,
      generation: generation,
      keepPreloads: {episodeNo, reverseEpisode},
    );
    if (prep == null) return false;

    return _runColdApplyPlayback(
      episodeNo: episodeNo,
      prep: prep,
      generation: generation,
      reason: reason,
      pathLabel: 'adjacent-controlled-cold',
      stopwatch: switchStopwatch,
    );
  }

  bool _isActivateSuperseded(int episodeNo) {
    return FeedPlaybackPolicy.isActivateSuperseded(
      disposed: _disposed,
      episodeNo: episodeNo,
      queuedEpisode: _queuedActivateEpisode,
    );
  }

  Future<bool> _awaitInFlightPreload(int episodeNo, int slot) async {
    final existing = _slots[slot].inFlightFuture;
    if (existing != null) {
      try {
        final ok = await existing.timeout(
          StoryConstants.playerOperationTimeout,
        );
        if (!ok) return false;
      } catch (e) {
        StoryLogger.d(
          'await in-flight preload timed out/failed ep=$episodeNo slot=$slot',
          error: e,
          tag: 'Feed',
        );
        return false;
      }
    }
    if (!_canContinue()) return false;
    if (_slot.readySlotForEpisode(episodeNo) == slot) return true;
    final engine = _engineForSlot(slot);
    if (engine.currentEpisodeNo == episodeNo && engine.currentPlay != null) {
      _slot.mapEpisodeToSlot(episodeNo, slot);
      return true;
    }
    return false;
  }

  /// Fast-path: swap the preloaded engine into the active slot.
  ///
  /// Returns `true` when this path handled the request (success, error, or
  /// aborted because a newer swipe superseded it). Returns `false` only when
  /// the caller should try another activation strategy.
  Future<bool> _activateFromPreload(
    int episodeNo, {
    required int preloadedSlot,
    required String reason,
  }) async {
    final preload = _engineForSlot(preloadedSlot);
    final slotState = _slots[preloadedSlot];
    final loadingEpisode = slotState.loadingEpisodeNo;
    if (preload.hasPendingLoad ||
        (loadingEpisode != null && loadingEpisode != episodeNo)) {
      _slot.unmapSlotsWhere((_, slot) => slot == preloadedSlot);
      slotState.reset();
      StoryLogger.w(
        '拒绝繁忙槽位切换 target=$episodeNo loading=$loadingEpisode '
        'slot=$preloadedSlot pending=${preload.hasPendingLoad} reason=$reason',
        tag: 'Feed',
      );
      return false;
    }
    final actualEpisode = preload.currentEpisodeNo;
    if (actualEpisode != episodeNo || preload.currentPlay == null) {
      _slot.unmapSlotsWhere((_, slot) => slot == preloadedSlot);
      StoryLogger.w(
        '拒绝陈旧槽位切换 target=$episodeNo actual=$actualEpisode '
        'slot=$preloadedSlot reason=$reason',
        tag: 'Feed',
      );
      return false;
    }
    // Reserve synchronously before the first await. Otherwise a preload timer
    // can select this still-inactive slot while cookies/audio are settling,
    // then its late loadUrl overwrites the newly active episode.
    slotState.activationReserved = true;

    final switchStopwatch = Stopwatch()..start();
    StoryLogger.d(
      '=== 预加载切换 episode=$episodeNo (reason=$reason) ===',
      tag: 'Feed',
    );

    // Invalidate any in-flight cold-path applyPlayback / older migrate.
    final generation = ++_switchGeneration;
    // Clear pager duck — volume/resume must not target the outgoing engine.
    _volumeDucked = false;

    final previousEpisodeNo = _currentEpisodeNo;
    final previousActiveSlot = _activeEngineIndex;
    final oldActive = _engine;

    bool stillWanted() => _canContinue(
      () =>
          generation == _switchGeneration && !_isActivateSuperseded(episodeNo),
    );

    // Silence BY SLOT (not episode). Episode-based silence can pause the
    // preload engine when currentEpisodeNo briefly lags, then migrateToActive
    // play()-while-recovering freezes the video track with audio continuing.
    final promoteFut = preload.promotePreloadedResource();
    await silenceExceptSlot(preloadedSlot);
    if (!stillWanted()) {
      slotState.activationReserved = false;
      _unawaitedLogged(promoteFut, reason: 'promote-after-supersede');
      return true;
    }
    oldActive.reset();

    final cookiesReady = await promoteFut;
    if (!stillWanted()) {
      slotState.activationReserved = false;
      return true;
    }
    if (!cookiesReady) {
      slotState.activationReserved = false;
      _status = FeedPlaybackStatus.error;
      _error = StateError('Failed to promote preloaded media cookies');
      _notify();
      return true;
    }

    // Zero scrubber state before the active slot rotates so overlays never
    // render previous-episode position against duration=0 (snaps to 100%).
    _position = Duration.zero;
    _duration = Duration.zero;
    preload.reset();

    // Rotate active slot + pager identity before play. Do NOT commit
    // `_loadedEpisodeNo` yet — if a newer swipe supersedes mid-migrate we
    // must not claim success (logs showed "跳远命中" then target paused).
    // Surface layout uses engine.currentEpisodeNo for the active slot.
    // Keep cover up until migrate + texture nudge finish — revealing the
    // stale paused sample looks like "audio plays, picture frozen".
    _activeEngineIndex = preloadedSlot;
    slotState.activationReserved = false;
    _slot.unmapEpisode(episodeNo);
    _currentEpisodeNo = episodeNo;
    _lastFrameRenderedAt = null;
    _lastFrameEpisode = null;
    _recovery.resetBudgets();
    _playerSurfaceVisible = false;
    _notify();

    // Let the Positioned surface settle on-screen before play(). One frame is
    // enough; skipping this is a common frozen-video + continuing-audio mode.
    // Hard timeout: endOfFrame can hang if the pipeline is already wedged.
    try {
      await WidgetsBinding.instance.endOfFrame.timeout(
        const Duration(milliseconds: 500),
      );
    } on TimeoutException {
      StoryLogger.d('endOfFrame timed out before migrate', tag: 'Feed');
    }
    if (!stillWanted()) return true;

    // Activate the preloaded engine: unmute + play + texture nudge.
    final migrated = await preload.migrateToActive(shouldContinue: stillWanted);
    if (!stillWanted()) {
      // Mute only — pause-after-play freezes the next swap onto this slot.
      await preload.setVolume(0.0);
      return true;
    }
    if (!migrated) {
      _isPlaying = false;
      _status = FeedPlaybackStatus.error;
      _error = StateError('Preloaded player failed to start');
      _playerSurfaceVisible = false;
      _notify();
      return true;
    }

    // Commit loaded only after play actually started.
    _loadedEpisodeNo = episodeNo;
    setCurrentPlay(preload.currentPlay);
    _resetPlaybackForEpisode(episodeNo, playing: true);
    _status = FeedPlaybackStatus.ready;
    // Match recommend: uncover only when migrate painted a frame.
    _playerSurfaceVisible = preload.hasPresentedFirstFrame;
    _volumeDucked = false;
    // Re-assert audible volume after migrate — pager duck may have raced
    // during animateToPage auto-advance and left the new slot at 0.
    await preload.setVolume(1.0);
    _playedEpisodeNos.add(episodeNo);
    _prefetchedEpisodeNos.remove(episodeNo);
    _setsDirty = true;
    _prefetch.cancelAll();

    // Old active is now the immediately adjacent reverse slot.
    if (previousEpisodeNo >= 1 &&
        previousEpisodeNo <= totalEpisodes &&
        oldActive.currentEpisodeNo == previousEpisodeNo) {
      _slot.mapEpisodeToSlot(previousEpisodeNo, previousActiveSlot);
    }
    _removeStalePreloadEntries();
    _notify();

    prefetchAdjacent(episodeNo);
    _scheduleAdjacentNativePreloads();

    _reportFeedActivateTelemetry(fromNeighbor: true);
    FeedActivateMetrics.record(
      reason.contains('jump') ? 'jump-ready' : 'preload-swap',
    );
    StoryLogger.d(
      'episode_switch_ms=${switchStopwatch.elapsedMilliseconds} '
      'episode=$episodeNo path=preload-swap reason=$reason',
      tag: 'Feed',
    );
    StoryLogger.d('✅ 预加载切换完成: 第 $episodeNo 集', tag: 'Feed');
    return true;
  }
}
