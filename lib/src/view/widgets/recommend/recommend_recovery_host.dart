import 'dart:async';

import '../../../controller/feed_playback_policy.dart';
import '../../../controller/feed_recovery_engine.dart';
import '../../../controller/playback_engine.dart';
import '../../../core/story_logger.dart';
import '../../../model/recommend_feed_model.dart';

/// Recovery host for the recommend feed page.
///
/// Bridges [FeedRecoveryEngine] with the widget state to handle
/// unexpected pauses, frame stalls, and foreground resume.
class RecommendRecoveryHost
    with FeedRecoveryHostForwarder
    implements FeedRecoveryHostView {
  RecommendRecoveryHost(this._state);

  final RecommendFeedBodyState _state;

  @override
  bool get hostIsPlaying => _state.isPlaying;

  @override
  bool get hostVolumeDucked => _state.volumeDucked;

  @override
  DateTime? get hostLastFrameRenderedAt => _state.lastFrameRenderedAt;

  @override
  bool aliveForGeneration(int generation) =>
      _state.mounted && generation == _state.playGeneration;

  @override
  bool get userPaused => _state.isUserPaused;

  @override
  bool get visible => _state.isPlaybackVisible;

  @override
  bool get activationRunning => _state.bindRunning;

  @override
  bool get neighborLoadInFlight => _state.neighborLoadGuarded;

  @override
  bool get promoteInFlight => _state.promoteInFlight;

  @override
  bool get ended => _state.ended;

  @override
  bool get buffering => _state.activeEngine?.isBuffering ?? false;

  @override
  bool get playbackFailed => _state.playbackFailed;

  @override
  String get boundIdentity => _state.activePlaybackId ?? '';

  @override
  PlaybackEngine? get engine => _state.activeEngine;

  @override
  bool isPlaybackArmActive() {
    final armed = _state.playbackArmedAt;
    return armed != null &&
        DateTime.now().difference(armed) < FeedPlaybackPolicy.playbackArmGrace;
  }

  @override
  bool get couldBeRecoverable {
    final engine = _state.activeEngine;
    return engine != null && !engine.hasCompleted && !engine.hasPendingLoad;
  }

  @override
  bool get readyForResume {
    final engine = _state.activeEngine;
    if (engine == null || engine.hasCompleted || engine.hasPendingLoad) {
      return false;
    }
    return FeedPlaybackPolicy.canResumeBoundSlot(
      slotPlaybackId: _state.activePlaybackId,
      itemPlaybackId: _state.currentItemPlaybackId ?? '',
      surfaceReady: _state.activeSurfaceReady,
      hasEngine: true,
      hasLoadedPlay: engine.currentPlay != null,
      loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
        engine.currentPlay,
      ),
    );
  }

  @override
  bool get readyForStallCheck {
    final dramaId = _state.activePlaybackId;
    return dramaId != null && _state.lastFrameDramaId == dramaId;
  }

  @override
  bool isWithinForegroundGrace() {
    final resumeAt = _state.foregroundResumeAt;
    return resumeAt != null &&
        DateTime.now().difference(resumeAt) < const Duration(seconds: 3);
  }

  @override
  void onGuardSkip() {
    // Neighbor loadUrl paused Active while unexpected-pause recovery is
    // suppressed. Kick restore when Active is actually not playing — do not
    // require [_state.isPlaying] alone (it can lag one callback behind).
    if (!_state.neighborLoadGuarded || _state.playbackFailed) return;
    if (_state.isUserPaused || !_state.isPlaybackVisible || _state.ended) {
      return;
    }
    final engine = _state.activeEngine;
    if (engine != null && engine.isPlaying) return;
    unawaited(_state.restoreActiveAfterNeighborLoad());
  }

  @override
  Future<bool> resumeActivePlayback() async {
    final engine = _state.activeEngine!;
    await engine.setVolume(1.0, force: true);
    return engine.resumeForFeed(FeedResumeStyle.playCommandOnly);
  }

  @override
  Future<void> onResumeSucceeded() async {
    final engine = _state.activeEngine;
    if (!_state.isPlaybackVisible) {
      _state.pauseBecauseHidden();
      return;
    }
    if (engine == null || engine.hasCompleted) return;
    await engine.setVolume(1.0, force: true);
    _state.isPlaying = true;
  }

  @override
  Future<void> onFrameStallEscalate({required int attempt}) async {
    if (attempt != 1 || !_state.isPlaybackVisible) return;
    if (_state.isUserPaused) return;
    await _state.activeEngine?.resumeForFeed(FeedResumeStyle.playCommandOnly);
  }

  @override
  void logWarning(String message) => StoryLogger.w(message, tag: 'Rec');

  @override
  void logDebug(String message) => StoryLogger.d(message, tag: 'Rec');
}

/// Abstract interface for the state that [RecommendRecoveryHost] needs.
///
/// This decouples the recovery host from the concrete widget state,
/// making it testable and reusable.
abstract class RecommendFeedBodyState {
  bool get mounted;
  bool get isPlaying;
  set isPlaying(bool value);
  bool get volumeDucked;
  DateTime? get lastFrameRenderedAt;
  int get playGeneration;
  bool get isUserPaused;
  bool get isPlaybackVisible;
  bool get bindRunning;
  bool get neighborLoadGuarded;
  bool get promoteInFlight;
  bool get ended;
  bool get playbackFailed;
  String? get activePlaybackId;
  PlaybackEngine? get activeEngine;
  bool get activeSurfaceReady;
  String? get currentItemPlaybackId;
  String? get lastFrameDramaId;
  DateTime? get playbackArmedAt;
  DateTime? get foregroundResumeAt;
  Future<void> restoreActiveAfterNeighborLoad();
  void pauseBecauseHidden();
}
