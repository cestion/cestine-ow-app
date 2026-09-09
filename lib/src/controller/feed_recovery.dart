part of 'video_feed_controller.dart';

/// Playback recovery and app-lifecycle management for the video feed.
///
/// Unexpected-pause recovery: native pauses the active engine without any
/// feed-initiated pause path (e.g. iOS audio session interruption). After a
/// short settle, verify nothing legitimate explains it, then auto-resume.
///
/// Frame-stall recovery: audio/time advances but the video surface stops
/// receiving frames. Nudge the native texture; if that fails, force-reload
/// the episode.
///
/// Auth recovery: when loadUrl succeeds but playback stalls (stale 403
/// cookies), clear the episode cache and refetch.
///
/// Lifecycle: suspend/resume the active engine on app background/foreground
/// and on cover-route push/pop.
///
/// Same-library extension keeps private controller fields accessible while
/// concentrating recovery logic in one file.
///
/// NOTE: Instance fields for recovery/lifecycle state are declared in
/// [VideoFeedController] (the main file) — this extension only defines
/// methods.
extension FeedRecovery on VideoFeedController {
  /// Native paused the active engine without any pause path of ours running.
  ///
  /// Seen at cold entry: playback starts, then an iOS audio-session
  /// interruption (e.g. the theater banner AVPlayer being torn down) pauses
  /// the player one event later — playing → paused — and the feed sits on a
  /// frozen first frame. Verify after a short settle that nothing legitimate
  /// (user pause, route cover, activation, buffering) explains it, then
  /// resume. Budgeted per episode so a genuinely broken stream cannot ping-
  /// pong play/pause forever.
  ///
  /// Choreography lives in the shared [FeedRecoveryEngine]; this controller
  /// supplies state + actions via [_VideoFeedRecoveryHost].
  void _maybeRecoverUnexpectedPause() {
    _recovery.maybeRecoverUnexpectedPause(generation: 0);
  }

  bool get _neighborNativeLoadInFlight {
    if (_nativePreloadInFlightEpisodeNos.isNotEmpty) return true;
    for (final slot in _inactiveSlots) {
      if (_engineForSlotOrNull(slot)?.hasPendingLoad == true) return true;
    }
    return false;
  }

  /// Detects the failure mode where audio/time keep advancing but the native
  /// video surface stops receiving frames. Decision flow lives in the shared
  /// [FeedRecoveryEngine].
  void _maybeRecoverFrameStall(PlaybackEngine engine) {
    _recovery.maybeRecoverFrameStall(generation: 0, engine: engine);
  }

  /// Called when the active engine exhausts loadUrl retries — clear the stale
  /// cache and refetch, once per episode.
  Future<void> _recoverFromStaleAuthOnce({required bool isSwitch}) async {
    if (!_canContinue(() => _authPhase == AuthRecoveryPhase.idle)) return;
    _authPhase = AuthRecoveryPhase.attempted;
    final episodeNo = _currentEpisodeNo;
    final generation = _switchGeneration;
    _episodeStates.remove(episodeNo);
    StoryLogger.w(
      'Attempting stale-auth recovery for episode=$episodeNo',
      tag: 'Feed',
    );
    try {
      final ok = await _engine.recoverFromStaleAuth(
        episodeNo: episodeNo,
        isSwitch: isSwitch,
        shouldContinue: () => _isCurrentGeneration(generation),
      );
      if (!ok || !_isCurrentGeneration(generation)) {
        _status = FeedPlaybackStatus.error;
        _error ??= StateError('Playback recovery failed');
        _notify();
        return;
      }
      final play = _engine.currentPlay;
      if (play != null) {
        _markEpisodeReady(episodeNo, play);
      } else if (_alive) {
        _status = FeedPlaybackStatus.error;
        _error ??= StateError('Playback recovery returned no play');
        _notify();
      }
    } finally {
      _pendingAuthRecovery = null;
    }
  }

  /// Cookie/auth recovery cannot fix hung bootstrap or wedged pending loads.
  bool _shouldAttemptStaleAuthRecovery(Object error) {
    final msg = error.toString();
    if (msg.contains('Native load still pending')) return false;
    if (msg.contains('platform view missing')) return false;
    if (msg.contains('force-abandon')) return false;
    if (msg.contains('initialize aborted')) return false;
    return true;
  }

  // ─── Lifecycle ──────────────────────────────────────────────

  /// Suspend when a route is pushed over the feed (drama detail, login,
  /// report…). Idempotent when RouteAware and [PlaybackAuthRouteObserver]
  /// both fire for the same cover.
  Future<void> onRouteCovered() async {
    if (_routeCovered) {
      await _pauseAllSlotsForSuspend();
      _isPlaying = false;
      if (_alive) _notify();
      return;
    }
    _routeCovered = true;
    await _suspendPlayback(visibility: FeedVisibility.routeCovered);
  }

  Future<void> onAppBackground() async {
    await _suspendPlayback(visibility: FeedVisibility.background);
  }

  Future<void> _suspendPlayback({required FeedVisibility visibility}) async {
    if (_visibility == visibility && visibility == FeedVisibility.background) {
      return;
    }
    // First suspend in a chain records whether we were playing. Nested
    // route→app-background must not clear the flag with a false.
    if (_visibility == FeedVisibility.active) {
      _wasPlayingBeforeBackground = _isPlaying;
    }
    _visibility = visibility;
    _suspendedAt = DateTime.now();
    final gen = ++_lifecycleGeneration;

    if (_alive && _servicesReady) {
      // Pause every slot — neighbors keep buffering in background and iOS
      // then fires "The network connection was lost" on A/B/C together.
      final pause = _pauseAllSlotsForSuspend();
      _suspendInFlight = pause;
      try {
        await pause;
        await persistWatchProgress();
      } finally {
        if (identical(_suspendInFlight, pause)) {
          _suspendInFlight = null;
        }
      }
    }
    if (gen != _lifecycleGeneration) return;
    _isPlaying = false;
    if (_alive) _notify();
  }

  Future<void> _pauseAllSlotsForSuspend() async {
    final futures = <Future<void>>[];
    for (var slot = 0; slot < 3; slot++) {
      final engine = _engineForSlotOrNull(slot);
      if (engine?.nativeController == null) continue;
      futures.add(() async {
        try {
          await engine!.setVolume(0.0);
          // Skip the native pause() call when the engine is already paused —
          // avoids an unnecessary MethodChannel round-trip on suspend chains
          // (e.g. route push during backgrounding fires this twice).
          if (engine.isPlaying) {
            await engine.pause();
          }
        } catch (_) {
          // Disposed / NO_VIEW — ignore.
        }
      }());
    }
    if (futures.isEmpty) return;
    await Future.wait(futures);
  }

  void onAppForeground() {
    // Still covered by a pushed route — stay suspended; [onPageRevealed]
    // will resume when the covering route pops.
    if (_routeCovered) {
      _visibility = FeedVisibility.routeCovered;
      StoryLogger.d(
        'foreground ignored: feed still route-covered',
        tag: 'Feed',
      );
      return;
    }
    _visibility = FeedVisibility.active;
    if (!_wasPlayingBeforeBackground || _isUserPaused) {
      // Suspend muted volume to 0; restore even when staying paused so the
      // next tap-to-play is not silent.
      _unawaitedLogged(
        _restoreVolumeAfterSuspend(),
        reason: 'foreground-restore-volume',
      );
      return;
    }
    final gen = ++_lifecycleGeneration;
    _unawaitedLogged(_resumeAfterForeground(gen), reason: 'foreground-resume');
  }

  /// Called when a route above the feed is popped (e.g. drama detail / report).
  ///
  /// Soft resume with a seek kick; never remount the platform view here —
  /// disposing the view while method-channel calls are in flight wedges
  /// play/pause forever and freezes the activate queue.
  ///
  /// Idempotent when RouteAware and an explicit cover (report push) both
  /// reveal — the second call is ignored.
  void onPageRevealed() {
    if (!_routeCovered) return;
    _routeCovered = false;
    _visibility = FeedVisibility.active;
    if (!_wasPlayingBeforeBackground || _isUserPaused) {
      _unawaitedLogged(
        _restoreVolumeAfterSuspend(),
        reason: 'page-revealed-restore-volume',
      );
      // Platform views were remounted empty; refresh the last frame without
      // auto-playing so a user-paused return is not a permanent black tile.
      _unawaitedLogged(
        _refreshPausedSurfaceAfterRemount(),
        reason: 'page-revealed-paused-surface',
      );
      if (_alive) _notify();
      return;
    }
    final gen = ++_lifecycleGeneration;
    _unawaitedLogged(_recoverAfterCoverRoute(gen), reason: 'page-revealed');
  }

  /// Remount after login / detail: reconnect + texture nudge while staying
  /// paused so the native surface is not a permanent blank tile.
  Future<void> _refreshPausedSurfaceAfterRemount() async {
    final pendingSuspend = _suspendInFlight;
    if (pendingSuspend != null) {
      await pendingSuspend;
    }
    if (!_alive || _visibility != FeedVisibility.active) return;
    try {
      await _engine.ensureSurfaceConnected();
      await _engine.nudgeTextureFrame();
    } catch (_) {
      // Disposed / NO_VIEW — cover handles the UI.
    }
  }

  /// Await in-flight suspend mute, then force-unmute the active slot.
  Future<void> _restoreVolumeAfterSuspend() async {
    final pendingSuspend = _suspendInFlight;
    if (pendingSuspend != null) {
      await pendingSuspend;
    }
    if (!_alive || _visibility != FeedVisibility.active) return;
    try {
      await _engine.setVolume(1.0, force: true);
    } catch (_) {
      // Disposed / NO_VIEW — ignore.
    }
  }

  Future<void> _resumeAfterForeground(int gen) async {
    // Let any in-flight background pause finish first — otherwise a late
    // native pause lands after play() and freezes the first frame.
    final pendingSuspend = _suspendInFlight;
    if (pendingSuspend != null) {
      await pendingSuspend;
    }
    if (!_isCurrentLifecycle(gen)) return;

    final strategy = _foregroundResumeStrategy();
    StoryLogger.d(
      'foreground resume strategy=$strategy '
      'needsReload=$_needsForegroundReload '
      'suspendedMs=${_suspendedAt == null ? -1 : DateTime.now().difference(_suspendedAt!).inMilliseconds}',
      tag: 'Feed',
    );

    if (strategy == ForegroundResumeStrategy.force || _needsForegroundReload) {
      _needsForegroundReload = false;
      await _forceReactivateCurrent(reason: 'foreground');
      return;
    }

    final ok = await _kickAndResumeActive(
      reason: 'foreground',
      brief: strategy == ForegroundResumeStrategy.brief,
      gen: gen,
    );
    if (!_isCurrentLifecycle(gen)) return;
    if (ok) return;
    await _forceReactivateCurrent(reason: 'foreground');
  }

  Future<void> _recoverAfterCoverRoute(int gen) async {
    if (!_alive || _isUserPaused) return;
    final pendingSuspend = _suspendInFlight;
    if (pendingSuspend != null) {
      await pendingSuspend;
    }
    if (!_isCurrentLifecycle(gen)) return;
    final ep = _currentEpisodeNo;
    if (ep < 1) return;

    await silenceExceptEpisode(ep);
    if (!_alive || _isUserPaused || !_isCurrentLifecycle(gen)) return;

    if (_needsForegroundReload) {
      _needsForegroundReload = false;
      await _forceReactivateCurrent(reason: 'page-revealed');
      return;
    }

    final strategy = _foregroundResumeStrategy();
    if (strategy == ForegroundResumeStrategy.force) {
      await _forceReactivateCurrent(reason: 'page-revealed');
      return;
    }

    final ok = await _kickAndResumeActive(
      reason: 'page-revealed',
      brief: strategy == ForegroundResumeStrategy.brief,
      gen: gen,
    );
    if (!_isCurrentLifecycle(gen)) return;
    if (ok) return;
    await _forceReactivateCurrent(reason: 'page-revealed');
  }

  bool _isCurrentLifecycle(int gen) => _alive && gen == _lifecycleGeneration;

  ForegroundResumeStrategy _foregroundResumeStrategy() {
    final since = _suspendedAt;
    if (since == null) return ForegroundResumeStrategy.soft;
    final elapsed = DateTime.now().difference(since);
    if (elapsed <= StoryDurations.foregroundBriefBackground) {
      return ForegroundResumeStrategy.brief;
    }
    if (elapsed >= StoryDurations.foregroundLongBackground) {
      return ForegroundResumeStrategy.force;
    }
    return ForegroundResumeStrategy.soft;
  }

  /// Soft play (+ optional texture nudge). Avoid seek-to-same: on HLS that
  /// commonly forces a fresh rebuffer right after backgrounding and leaves
  /// the UI stuck in loading when the 4s first-frame wait expires.
  Future<bool> _kickAndResumeActive({
    required String reason,
    required int gen,
    bool brief = false,
  }) async {
    if (!_alive || _isUserPaused) return false;
    if (!_isCurrentLifecycle(gen)) return false;
    // Resume only when the active engine matches the pager episode. When a
    // cover route interrupted mid-activation (loaded ≠ current), resuming
    // would play the outgoing engine off-screen — force reactivate instead.
    if (_loadedEpisodeNo != _currentEpisodeNo) {
      StoryLogger.d(
        'kickAndResume ($reason) skipped: loaded=$_loadedEpisodeNo '
        '≠ current=$_currentEpisodeNo',
        tag: 'Feed',
      );
      return false;
    }
    final engine = _engine;
    if (engine.currentEpisodeNo != _currentEpisodeNo) {
      StoryLogger.w(
        'kickAndResume ($reason) skipped: engine=${engine.currentEpisodeNo} '
        '≠ current=$_currentEpisodeNo',
        tag: 'Feed',
      );
      return false;
    }
    if (engine.nativeController == null) {
      StoryLogger.d(
        'kickAndResume ($reason) skipped: no native controller',
        tag: 'Feed',
      );
      return false;
    }

    // Stall recovery can race soft resume right after foreground; mute it
    // briefly so we do not force-reactivate twice.
    _foregroundResumeAt = DateTime.now();

    try {
      if (!brief) {
        final cookiesOk = await engine.prepareCookiesForForegroundResume();
        if (!cookiesOk) return false;
        if (!_alive || _isUserPaused || !_isCurrentLifecycle(gen)) return false;
      } else {
        // Brief path: skip full cookie refresh but still bail if the
        // signed CloudFront cookies are expired — a 403 mid-resume is
        // worse than taking the slower force-reactivate path.
        final cookies = engine.currentPlay?.signedCookies;
        if (cookies != null && !cookies.isValid) {
          StoryLogger.d(
            'brief resume skipped: cookies expired',
            tag: 'Feed',
          );
          return false;
        }
      }

      await engine.ensureSurfaceConnected();
      if (!_isCurrentLifecycle(gen)) return false;
      await engine.setVolume(1.0, force: true);

      final frameBudget = brief
          ? StoryDurations.foregroundBriefFrameBudget
          : StoryDurations.foregroundSoftFrameBudget;
      var resumed = await engine.resumeForFeed(
        FeedResumeStyle.waitForFrame,
        frameTimeout: frameBudget,
      );
      if (!_isCurrentLifecycle(gen)) return false;
      if (resumed && _alive) {
        // Re-assert after play(): a late suspend setVolume(0) or iOS audio
        // session flap must not leave the feed silent while frames advance.
        await engine.setVolume(1.0, force: true);
        _isPlaying = true;
        _isUserPaused = false;
        _status = FeedPlaybackStatus.ready;
        _needsForegroundReload = false;
        // Soft resume often skips a fresh `playing` activity event.
        _episodeMetrics.onPlayStart();
        _revealPlayerSurface();
        _notify();
        return true;
      }

      if (brief) {
        // Brief path failed — fall through to soft/force without nudge burn.
        return false;
      }

      // First play produced no frame — pause so we do not leave a runaway
      // buffer under a loading UI, then nudge + retry once.
      StoryLogger.w(
        'kickAndResume ($reason) first play produced no frame; nudge+retry',
        tag: 'Feed',
      );
      try {
        await engine.pause();
      } catch (_) {}
      if (!_alive || _isUserPaused || !_isCurrentLifecycle(gen)) return false;
      await engine.ensureSurfaceConnected();
      await engine.nudgeTextureFrame();
      resumed = await engine.resumeForFeed(
        FeedResumeStyle.waitForFrame,
        frameTimeout: frameBudget,
      );
      if (!_isCurrentLifecycle(gen)) return false;
      if (resumed && _alive) {
        await engine.setVolume(1.0, force: true);
        _isPlaying = true;
        _isUserPaused = false;
        _status = FeedPlaybackStatus.ready;
        _needsForegroundReload = false;
        _revealPlayerSurface();
        _notify();
        return true;
      }
      try {
        await engine.pause();
      } catch (_) {}
    } catch (e) {
      StoryLogger.d('kickAndResume ($reason) failed: $e', tag: 'Feed');
    }
    return false;
  }

  Future<void> _forceReactivateCurrent({required String reason}) async {
    if (!_alive) return;
    final ep = _currentEpisodeNo;
    if (ep < 1) return;
    // Bypass the ready short-circuit in [_enqueueActivate] / [_activateEpisode].
    _loadedEpisodeNo = null;
    _status = FeedPlaybackStatus.loading;
    _hidePlayerSurface();
    _notify();
    await _enqueueActivate(ep, reason: reason);
  }
}
