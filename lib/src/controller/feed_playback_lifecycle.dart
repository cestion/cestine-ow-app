part of 'video_feed_controller.dart';

/// Playback lifecycle, completion handling, and tracking for
/// [VideoFeedController].
///
/// Control/action methods (togglePlayPause, retry, seekTo) stay in the main
/// class for mocktail compatibility. Only internal lifecycle helpers that are
/// never directly mocked live here.
extension FeedPlaybackLifecycle on VideoFeedController {
  // ─── Completion and auto-advance ───────────────────────────

  /// 消费自动进集请求（UI 动画完成后调用）
  void consumeAutoAdvance() {
    _autoAdvanceToEpisodeNo = null;
    _notify();
  }

  /// Called by the engine when an episode finishes playing.
  void handleCompletion() {
    // Pause/teardown under a covering route can still emit native completed.
    // Reporting 有效完播 then looks like "leave and come back → complete".
    if (!FeedPlaybackPolicy.shouldAcceptNaturalComplete(
      isPlaybackVisible: _visibility == FeedVisibility.active,
    )) {
      StoryLogger.d(
        'Feed drop completed reason=notVisible '
        'visibility=${_visibility.name} routeCovered=$_routeCovered '
        'ep=$_currentEpisodeNo '
        'pos=${_engine.position.inMilliseconds}',
        tag: 'play-report-api',
      );
      return;
    }
    if (FeedPlaybackPolicy.shouldIgnoreSpuriousComplete(
      hasPresentedFirstFrame: _engine.hasPresentedFirstFrame,
      position: _engine.position,
      duration: _engine.duration,
    )) {
      StoryLogger.w(
        'Feed ignore spurious complete ep=$_currentEpisodeNo '
        'pos=${_engine.position.inMilliseconds}',
        tag: 'Feed',
      );
      return;
    }
    // Final metrics tick at EOS — position may already be 0 after native seek.
    final engineDur = _engine.duration.inMilliseconds;
    final durMs = engineDur > 0 ? engineDur : _duration.inMilliseconds;
    _applyNaturalPlaybackEndMetrics(
      _engine.position.inMilliseconds,
      durMs,
    );
    final next = _currentEpisodeNo + 1;
    // Search works playlist: stay on the tapped episode, then advance the
    // outer works list. Search drama playlist keeps intra-drama auto-advance.
    final allowIntraDramaAdvance =
        _args.searchPlaylist.isEmpty || _args.searchDramaPlaylist;
    if (FeedPlaybackPolicy.shouldAutoAdvance(
          autoPlayEnabled: _autoPlayEnabled,
          overlayHoldsAdvance: overlayHoldsAdvance,
        ) &&
        allowIntraDramaAdvance &&
        next <= totalEpisodes) {
      maintainAdjacentNativePreloads();
      _autoAdvanceToEpisodeNo = next;
      _status = FeedPlaybackStatus.completed;
      _notify();
      return;
    }
    if (FeedPlaybackPolicy.shouldLoopCurrentItem(
      autoPlayEnabled: _autoPlayEnabled,
      overlayHoldsAdvance: overlayHoldsAdvance,
    )) {
      _unawaitedLogged(_replayFromStart(), reason: 'loop-current-episode');
      return;
    }
    _status = FeedPlaybackStatus.completed;
    _notify();
  }

  // ─── Episode metrics (有效播放 / 有效完播) ───────────────────

  void _resetEpisodeMetrics() {
    _episodeMetrics.reset();
  }

  void _onEpisodeMetricsTimeUpdate(int positionMs, int durationMs) {
    _applyEpisodeMetricsSignals(
      _episodeMetrics.onTimeUpdate(positionMs, durationMs),
    );
  }

  void _applyNaturalPlaybackEndMetrics(int positionMs, int durationMs) {
    final durationSec = durationMs > 0 ? durationMs / 1000.0 : null;
    final signals = _episodeMetrics.tracker.onNaturalPlaybackEnd(
      positionSeconds: positionMs > 0 ? positionMs / 1000.0 : null,
      durationSeconds: durationSec,
    );
    _applyEpisodeMetricsSignals(signals);
  }

  void _applyEpisodeMetricsSignals(PlaybackEpisodeMetricsSignals signals) {
    _episodeMetrics.applySignals(signals, fireTrack: _fireTrack);
  }

  void _fireTrack(EpisodeTrackEvent event) {
    _tracking.fireTrack(
      dramaId: _dramaId,
      episodeId: _currentPlay?.episodeId,
      event: event,
      type: contentType,
    );
  }

  // ─── Watch history ─────────────────────────────────────────

  void _maybeWatchTrack(int positionMs) {
    final episodeId = _currentPlay?.episodeId;
    if (!_watchHistoryGate.shouldReportPlay(
      positionMs: positionMs,
      episodeId: episodeId,
      episodeNo: _currentEpisodeNo,
    )) {
      return;
    }
    _watchHistoryGate.markReported(
      episodeId: episodeId,
      episodeNo: _currentEpisodeNo,
    );
    if (episodeId != null) {
      _reportCurrentEpisodeWatchHistory(episodeId);
    }
  }

  // ─── Watch progress ───────────────────────────────────────

  /// Save the active episode position to local storage (best-effort).
  Future<void> persistWatchProgress() async {
    if (!_alive) return;
    final ep = _loadedEpisodeNo ?? _currentEpisodeNo;
    if (ep < 1) return;
    try {
      await _engine.persistResume(ep);
      // Intra-episode scrub position is fine to keep; the continue-watching
      // cursor must not move for search「短剧」playlist (starts at ep 1).
      if (!FeedPersistPolicy.shouldPersistDramaCursor(_args)) return;
      _localRepo.cacheBox.put('current_episode_$_dramaId', ep);
    } catch (_) {
      // Engine may be mid-teardown during route pop.
    }
  }

  // ─── Resource management ───────────────────────────────────

  /// Detach all engines from native controllers and free coordinator slots.
  ///
  /// Call from [VideoFeedPage.dispose] **before** disposing the page-owned
  /// controllers so engines never pause/dispose an already-dead platform view.
  void releasePlayersOwnedByPage() {
    for (final e in _engines) {
      e?.relinquishControllerOwnership();
    }
    for (var i = 0; i < 3; i++) {
      _controllers[i] = null;
    }
  }

  // ─── Release ──────────────────────────────────────────────

  void dispose() {
    if (_disposed) return;
    unawaited(persistWatchProgress());
    _disposed = true;
    _switchGeneration++;
    _adjacentPreloadSettleTimer?.cancel();
    _adjacentPreloadSettleTimer = null;
    _prefetch.cancelAll();
    _slot.resetAll();
    _queuedActivateEpisode = null;
    _queuedActivateReason = null;
    playingListenable.dispose();
    userPausedListenable.dispose();
    // Controllers are owned by VideoFeedPage — never dispose them here
    // (double-dispose races crash native AVPlayer when returning to Detail).
    for (final e in _engines) {
      e?.dispose(disposeNativeController: false);
    }
    for (var i = 0; i < 3; i++) {
      _engines[i] = null;
      _controllers[i] = null;
    }
    _servicesReady = false;
    _episodeStates.clear();
  }
}
