import 'dart:async';

import '../core/story_constants.dart';
import 'feed_playback_policy.dart';
import 'playback_engine.dart';

/// The slice of feed state + actions the shared recovery engine needs.
///
/// Implemented by the video feed controller and by the recommend feed body
/// (via same-library adapters). Keeps the engine host-agnostic: each host
/// keeps its own state fields, generation guards, resume mechanic
/// (`resumePlayback` vs `startPlayback`) and failure escalation, while the
/// decision choreography — guard chain, per-item budgeting, settle timing,
/// nudge-and-wait loop — lives here once.
abstract interface class FeedRecoveryHost {
  /// Host lifecycle gate evaluated at every decision point. [generation] is
  /// the call-time token (the recommend feed passes its play generation; the
  /// video feed ignores it).
  bool aliveForGeneration(int generation);

  /// Host playing flag (post-settle re-check).
  bool get isPlaying;

  // ── FeedPlaybackPolicy.shouldSkipUnexpectedPause inputs ──
  bool get userPaused;
  bool get visible;
  bool get activationRunning;
  bool get volumeDucked;
  bool get neighborLoadInFlight;
  bool get promoteInFlight;
  bool get ended;
  bool get buffering;
  bool get playbackFailed;

  /// Per-item recovery budget identity (video feed: episode number; recommend
  /// feed: `dramaId:episodeId` playback id). Empty disables recovery.
  String get boundIdentity;

  /// Active engine, or null when unusable.
  PlaybackEngine? get engine;

  /// True while still inside the post-(re)bind playback arm grace — recommend
  /// only; the video feed returns false.
  bool isPlaybackArmActive();

  /// Pre-settle "could be recoverable" gate (engine loaded and bound).
  bool get couldBeRecoverable;

  /// Post-settle strict gate (video feed: status ready + episode match;
  /// recommend: [FeedPlaybackPolicy.canResumeBoundSlot]).
  bool get readyForResume;

  /// Frame-stall readiness: the bound item has rendered a frame and is still
  /// loaded / visible.
  bool get readyForStallCheck;

  /// Timestamp of the last rendered frame of the bound item.
  DateTime? get lastFrameRenderedAt;

  /// True within the foreground grace window (stall recovery suppressed).
  bool isWithinForegroundGrace();

  /// Called when the guard chain skipped recovery. The recommend host
  /// restores the active player after a neighbor load here; the video feed
  /// does nothing.
  void onGuardSkip();

  /// Force-unmute then resume via [PlaybackEngine.resumeForFeed].
  Future<bool> resumeActivePlayback();

  /// Post-resume success side effects (video feed: force-unmute + reveal
  /// surface + notify; recommend: visibility re-check + replay guard).
  Future<void> onResumeSucceeded();

  /// Frame-stall escalation after the texture nudge failed, per attempt.
  /// Attempt 1: video feed force-reactivates, recommend replays. Attempt 2:
  /// the video feed surfaces a hard error.
  Future<void> onFrameStallEscalate({required int attempt});

  void logWarning(String message);
  void logDebug(String message);
}

/// 宿主向恢复引擎暴露的最小状态视图 —— 两个 feed 各自实现这些同语义 getter。
///
/// [FeedRecoveryHost] 其余成员（可见性、激活中、可恢复判定、恢复动作等）在
/// 两个 feed 里语义不同，留在宿主侧差异化实现；这里只提取**真正同语义**的
/// 纯转发状态，由 [FeedRecoveryHostForwarder] 统一映射到 [FeedRecoveryHost]。
abstract interface class FeedRecoveryHostView {
  /// 宿主当前播放中标记（两个 feed 均直接透传 `_isPlaying`）。
  bool get hostIsPlaying;

  /// 宿主播放引擎音量被压低标记（VideoFeed: swipe-duck；Recommend: 生命周期/duck）。
  bool get hostVolumeDucked;

  /// 当前绑定条目最后一次渲染帧的时间（两个 feed 均直接透传）。
  DateTime? get hostLastFrameRenderedAt;
}

/// 把 [FeedRecoveryHostView] 的状态视图映射为 [FeedRecoveryHost] 的默认实现。
///
/// 两个 feed 的 host adapter 通过 `with FeedRecoveryHostForwarder` 复用这段
/// 转发样板，只保留各自差异化的成员（aliveForGeneration、visible、ended、
/// readyForResume、resumeActivePlayback 等）。
mixin FeedRecoveryHostForwarder implements FeedRecoveryHost {
  /// 三个纯转发状态由宿主类实现（同时 `implements FeedRecoveryHostView`）。
  bool get hostIsPlaying;
  bool get hostVolumeDucked;
  DateTime? get hostLastFrameRenderedAt;

  @override
  bool get isPlaying => hostIsPlaying;

  @override
  bool get volumeDucked => hostVolumeDucked;

  @override
  DateTime? get lastFrameRenderedAt => hostLastFrameRenderedAt;
}

/// Shared unexpected-pause / frame-stall recovery choreography.
///
/// One instance per feed, owning the per-item attempt budgets. The decision
/// flow (guard chain → settle → re-guard → resume / nudge → wait → escalate)
/// is identical between the video feed and the recommend feed — only the
/// host-provided inputs and actions differ.
class FeedRecoveryEngine {
  FeedRecoveryEngine(this.host);

  final FeedRecoveryHost host;

  // Unexpected-pause budget (per bound identity).
  String? _pauseIdentity;
  int _pauseAttempts = 0;
  bool _pauseInFlight = false;

  // Frame-stall budget.
  int _stallAttempts = 0;
  bool _stallInFlight = false;

  /// A frame rendered for the bound item — resets the stall budget so a
  /// healthy playback cannot be force-restarted by stale counters.
  void notifyFrameRendered() {
    _stallAttempts = 0;
  }

  /// The feed switched to a new bound item — drop both attempt budgets so
  /// the fresh item starts with a clean slate.
  void resetBudgets() {
    _pauseIdentity = null;
    _pauseAttempts = 0;
    _stallAttempts = 0;
  }

  /// Playback started successfully — clear the unexpected-pause budget so a
  /// fresh play is treated as a new incident (recommend feed: resets the
  /// retry budget on every native playing event).
  void notifyPlaybackStarted() {
    _pauseIdentity = null;
    _pauseAttempts = 0;
  }

  /// Fire-and-forget with a debug log so non-critical recovery races stay
  /// visible (mirrors the hosts' own unawaited-logging helpers).
  void _fireAndForget(
    Future<void> Function() action, {
    required String reason,
  }) {
    unawaited(() async {
      try {
        await action();
      } catch (e) {
        host.logWarning('$reason failed: $e');
      }
    }());
  }

  /// Native paused the active engine without any feed-initiated pause path
  /// (e.g. an iOS audio-session interruption). Verify after a short settle
  /// that nothing legitimate explains it, then resume via the host mechanic.
  void maybeRecoverUnexpectedPause({required int generation}) {
    final skip = FeedPlaybackPolicy.shouldSkipUnexpectedPause(
      userPaused: host.userPaused,
      visible: host.visible,
      activateRunning: host.activationRunning,
      volumeDucked: host.volumeDucked,
      neighborLoadInFlight: host.neighborLoadInFlight,
      promoteInFlight: host.promoteInFlight,
      ended: host.ended,
      isBuffering: host.buffering,
      playbackError: host.playbackFailed,
    );
    if (skip) {
      host.onGuardSkip();
      return;
    }
    if (!host.aliveForGeneration(generation)) return;
    if (host.isPlaybackArmActive()) return;
    if (!host.couldBeRecoverable) return;
    final identity = host.boundIdentity;
    if (identity.isEmpty) return;
    if (_pauseIdentity != identity) {
      _pauseIdentity = identity;
      _pauseAttempts = 0;
    }
    if (_pauseAttempts >= FeedPlaybackPolicy.maxUnexpectedPauseAttempts) {
      return;
    }
    if (_pauseInFlight) return;
    _pauseInFlight = true;
    _fireAndForget(() async {
      try {
        await Future<void>.delayed(FeedPlaybackPolicy.unexpectedPauseSettle);
        if (!host.aliveForGeneration(generation)) return;
        if (FeedPlaybackPolicy.shouldSkipUnexpectedPause(
          userPaused: host.userPaused,
          visible: host.visible,
          activateRunning: host.activationRunning,
          volumeDucked: host.volumeDucked,
          neighborLoadInFlight: host.neighborLoadInFlight,
          promoteInFlight: host.promoteInFlight,
          ended: host.ended,
          isBuffering: host.buffering,
          playbackError: host.playbackFailed,
        )) {
          host.onGuardSkip();
          return;
        }
        if (host.isPlaying) return;
        if (host.boundIdentity != identity) return;
        if (!host.readyForResume) return;
        _pauseAttempts++;
        final attempt = _pauseAttempts;
        host.logWarning(
          'unexpected pause, resume identity=$identity attempt=$attempt',
        );
        final ok = await host.resumeActivePlayback();
        if (!host.aliveForGeneration(generation)) return;
        if (ok) {
          await host.onResumeSucceeded();
        }
      } finally {
        _pauseInFlight = false;
      }
    }, reason: 'unexpected-pause-recover-$_pauseAttempts');
  }

  /// Audio/time keep advancing but the native surface stops receiving
  /// frames. Nudge the texture, then wait for a new frame before escalating.
  void maybeRecoverFrameStall({
    required int generation,
    required PlaybackEngine engine,
  }) {
    if (!host.aliveForGeneration(generation) ||
        _stallInFlight ||
        !host.isPlaying ||
        host.userPaused ||
        host.ended ||
        host.volumeDucked ||
        host.activationRunning ||
        host.promoteInFlight) {
      return;
    }
    if (host.isWithinForegroundGrace()) return;
    if (!host.readyForStallCheck) return;
    final lastFrame = host.lastFrameRenderedAt;
    if (lastFrame == null ||
        DateTime.now().difference(lastFrame) <=
            StoryConstants.playerFrameStallThreshold) {
      return;
    }
    if (_stallAttempts >= 2) return;
    _stallInFlight = true;
    final attempt = ++_stallAttempts;
    _fireAndForget(() async {
      try {
        host.logWarning(
          'frame stall, nudge identity=${host.boundIdentity} attempt=$attempt',
        );
        final frameBeforeNudge = engine.frameSequence;
        await engine.nudgeTextureFrame();
        final recovered = await engine.waitForFrameAfter(
          frameBeforeNudge,
          timeout: StoryConstants.playerFrameRecoveryTimeout,
          shouldContinue: () =>
              host.aliveForGeneration(generation) &&
              identical(host.engine, engine),
        );
        if (!host.aliveForGeneration(generation)) return;
        if (!host.readyForStallCheck) return;
        if (recovered) {
          host.logDebug('frame recovered');
          return;
        }
        await host.onFrameStallEscalate(attempt: attempt);
      } finally {
        _stallInFlight = false;
      }
    }, reason: 'frame-stall-recover-$attempt');
  }
}
