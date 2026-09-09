import 'dart:math' as math;

/// Signals for whether the client should report play / complete to the API.
class PlaybackEpisodeMetricsSignals {
  const PlaybackEpisodeMetricsSignals({
    required this.reportPlay,
    required this.reportComplete,
  });

  final bool reportPlay;
  final bool reportComplete;

  static const empty = PlaybackEpisodeMetricsSignals(
    reportPlay: false,
    reportComplete: false,
  );
}

/// Tracks effective watch time and progress for PRD「有效播放 / 有效完播」判定。
///
/// Thresholds match Web `playEpisodeMetricsTracker.ts`. Flutter additionally
/// handles native `completed`, loop-wrap without `completed`, HLS duration
/// overshoot, and leave→return remount artifacts that the Web player does not
/// see.
///
/// ## 有效播放 (play)
/// Effective watch time ≥ `max(5, min(10, duration × 0.2))`.
/// Sub-threshold clips bundle play with complete when complete is reached.
///
/// ## 有效完播 (complete)
/// Both:
/// - max progress ratio ≥ 90%
/// - effective watch ≥ 60% of (possibly inferred) content duration
///
/// ## Watch accumulation
/// Only counts while started + playing. Forward seeks (>3s) and rewinds do not
/// add watch; sparse 1Hz ticks may credit up to 1.5s per gap.
///
/// ## End-of-stream
/// Native EOS / loop wrap may set progress to 100% and credit the remaining
/// tail, but only when the last real playhead was near the content end — or
/// the clip is short (metadata ≤5s, or observed playhead &lt;5s on inflated
/// metadata). Mid-clip remount/`completed` must not fabricate complete.
class PlaybackEpisodeMetricsTracker {
  static const double forwardSeekThresholdSeconds = 3;
  static const double maxDeltaPerTickSeconds = 1.5;
  static const double completeProgressThreshold = 0.9;

  /// PRD short VOD ceiling; also the play-threshold floor, so duration==5 must
  /// still take the short EOS path (playThreshold is exactly 5 at that length).
  static const double shortContentCeilingSeconds = 5;

  static double playThresholdSeconds(double durationSeconds) =>
      math.max(5, math.min(10, durationSeconds * 0.2));

  static double completeWatchThresholdSeconds(double durationSeconds) =>
      durationSeconds * 0.6;

  bool _isStarted = false;
  bool _isPlaying = false;
  double _effectiveWatchSeconds = 0;
  double _maxProgressRatio = 0;
  double? _previousTimeSeconds;
  double? _durationSeconds;
  double _observedMaxPositionSeconds = 0;

  void reset() {
    _isStarted = false;
    _isPlaying = false;
    _effectiveWatchSeconds = 0;
    _maxProgressRatio = 0;
    _previousTimeSeconds = null;
    _durationSeconds = null;
    _observedMaxPositionSeconds = 0;
  }

  void onPlayStart() {
    _isStarted = true;
    _isPlaying = true;
  }

  void onPause() {
    _isPlaying = false;
  }

  /// Native playback reached end-of-stream.
  ///
  /// Do not trust [positionSeconds] at EOS — the engine often seeks to 0
  /// before emitting `completed`. Use [_lastKnownPlayhead] instead.
  PlaybackEpisodeMetricsSignals onNaturalPlaybackEnd({
    // Call sites still pass this; value is intentionally unused (stale at EOS).
    double? positionSeconds,
    double? durationSeconds,
  }) {
    if (durationSeconds != null &&
        durationSeconds.isFinite &&
        durationSeconds > 0) {
      _durationSeconds = durationSeconds;
    }

    final duration = _durationSeconds;
    if (!_isStarted) {
      // Promote / neighbor prime can leave the engine already playing so no
      // fresh `playing` event reaches metrics — natural EOS still proves a
      // real first-pass watch.
      _isStarted = true;
    }
    if (duration == null || duration <= 0 || !duration.isFinite) {
      _isPlaying = false;
      return PlaybackEpisodeMetricsSignals.empty;
    }

    final from = _lastKnownPlayhead;
    final shortByPlayhead = _isShortByPlayhead(from, duration);
    if (!_shouldAcceptContentEnd(from: from, duration: duration)) {
      _isPlaying = false;
      return _reportSignals();
    }

    return _markContentEnded(
      metadataDuration: duration,
      from: from,
      forceShortInfer: shortByPlayhead,
      retainPlayheadAtEnd: true,
      stopPlaying: true,
    );
  }

  PlaybackEpisodeMetricsSignals onTimeUpdate(
    double currentTimeSeconds, [
    double? nextDurationSeconds,
  ]) {
    if (nextDurationSeconds != null &&
        nextDurationSeconds.isFinite &&
        nextDurationSeconds > 0) {
      _durationSeconds = nextDurationSeconds;
    }

    if (!_isStarted ||
        !_isPlaying ||
        _durationSeconds == null ||
        _durationSeconds! <= 0 ||
        !currentTimeSeconds.isFinite ||
        currentTimeSeconds < 0) {
      return _reportSignals();
    }

    final duration = _durationSeconds!;
    _observedMaxPositionSeconds = math.max(
      _observedMaxPositionSeconds,
      currentTimeSeconds,
    );

    if (_previousTimeSeconds != null) {
      final previous = _previousTimeSeconds!;
      final delta = currentTimeSeconds - previous;

      // Loop wrap fallback when native looping suppressed `completed`.
      if (delta < 0 &&
          currentTimeSeconds <= maxDeltaPerTickSeconds &&
          previous >= _observedMaxPositionSeconds - maxDeltaPerTickSeconds &&
          _isNearContentEnd(previous, duration)) {
        return _markContentEnded(
          metadataDuration: duration,
          from: previous,
          forceShortInfer: false,
          retainPlayheadAtEnd: false,
          // Keep playing so the next loop pass can keep accumulating watch.
          stopPlaying: false,
        );
      }

      if (delta > forwardSeekThresholdSeconds || delta < 0) {
        // Large forward seek or rewind — do not count this segment.
        _previousTimeSeconds = currentTimeSeconds;
        return _reportSignals();
      }

      if (delta > 0 && delta <= maxDeltaPerTickSeconds) {
        _effectiveWatchSeconds += delta;
      } else if (delta > maxDeltaPerTickSeconds) {
        // Native position is ~1Hz; under load a second can be skipped so
        // delta lands in (1.5s, 3s]. Credit the anti-cheat cap only.
        _effectiveWatchSeconds += maxDeltaPerTickSeconds;
      }
    }

    _maxProgressRatio = math.max(
      _maxProgressRatio,
      currentTimeSeconds / duration,
    );

    _previousTimeSeconds = currentTimeSeconds;
    return _reportSignals();
  }

  /// Last positive playhead. Native EOS often sets previous to 0 first.
  double? get _lastKnownPlayhead {
    final prev = _previousTimeSeconds;
    if (prev != null && prev > 0) return prev;
    if (_observedMaxPositionSeconds > 0) return _observedMaxPositionSeconds;
    return prev;
  }

  bool _isShortMetadata(double duration) =>
      duration <= shortContentCeilingSeconds;

  /// Inflated HLS metadata with a real sub-5s ending playhead.
  bool _isShortByPlayhead(double? from, double metadataDuration) =>
      from != null &&
      from > 0 &&
      from < shortContentCeilingSeconds &&
      !_isShortMetadata(metadataDuration);

  bool _shouldAcceptContentEnd({
    required double? from,
    required double duration,
  }) {
    if (_isShortMetadata(duration) || _isShortByPlayhead(from, duration)) {
      return true;
    }
    // Long VOD: reject mid-clip / remount `completed` with a known playhead.
    if (from != null && !_isNearContentEnd(from, duration)) {
      return false;
    }
    // from == null: long clip with zero ticks — allow through; watch stays 0
    // so complete still cannot fire.
    return true;
  }

  /// True when [position] is within the 90% gate or the last few seconds of
  /// [duration] (covers 1Hz ticks that miss an exact 90% sample).
  bool _isNearContentEnd(double position, double duration) {
    if (duration <= 0) return false;
    return position >= duration * completeProgressThreshold ||
        position >= duration - forwardSeekThresholdSeconds;
  }

  /// HLS metadata can exceed the real media length; infer a shorter duration
  /// only when the playhead is already near the metadata end.
  double _inferContentDuration(double metadataDuration) {
    final observed = math.max(
      _observedMaxPositionSeconds,
      math.max(_previousTimeSeconds ?? 0, _effectiveWatchSeconds),
    );
    if (observed <= 0) return metadataDuration;
    if (!_isNearContentEnd(observed, metadataDuration)) {
      return metadataDuration;
    }
    return math.min(
      metadataDuration,
      math.max(observed + maxDeltaPerTickSeconds, _effectiveWatchSeconds),
    );
  }

  /// Shared EOS / loop-wrap finalization.
  ///
  /// [retainPlayheadAtEnd]: natural EOS keeps playhead at the end; loop wrap
  /// resets to 0 so subsequent ticks accumulate a new pass.
  /// [stopPlaying]: natural EOS stops; loop wrap stays playing.
  PlaybackEpisodeMetricsSignals _markContentEnded({
    required double metadataDuration,
    required double? from,
    required bool forceShortInfer,
    required bool retainPlayheadAtEnd,
    required bool stopPlaying,
  }) {
    var inferredDuration = _inferContentDuration(metadataDuration);
    if (forceShortInfer && from != null && from > 0) {
      inferredDuration = math.min(
        metadataDuration,
        math.max(from + maxDeltaPerTickSeconds, _effectiveWatchSeconds),
      );
    }
    _durationSeconds = inferredDuration;
    _maxProgressRatio = math.max(_maxProgressRatio, 1.0);

    if (from != null) {
      final tail = inferredDuration - from;
      if (tail > 0) {
        _effectiveWatchSeconds += tail;
      }
    }
    // Short VOD: sparse ticks often leave watch too low for the 60% gate.
    // Applied on both EOS and wrap so first-pass short completes stay reliable.
    if (inferredDuration < playThresholdSeconds(inferredDuration)) {
      _effectiveWatchSeconds = math.max(
        _effectiveWatchSeconds,
        inferredDuration,
      );
    }

    _previousTimeSeconds = retainPlayheadAtEnd ? inferredDuration : 0;
    if (stopPlaying) {
      _isPlaying = false;
    }
    return _reportSignals();
  }

  PlaybackEpisodeMetricsSignals _reportSignals() {
    final duration = _durationSeconds;
    if (!_isStarted ||
        duration == null ||
        duration <= 0 ||
        !duration.isFinite) {
      return PlaybackEpisodeMetricsSignals.empty;
    }

    final playThreshold = playThresholdSeconds(duration);
    final completeWatchThreshold = completeWatchThresholdSeconds(duration);

    final reportComplete =
        _maxProgressRatio >= completeProgressThreshold &&
        _effectiveWatchSeconds >= completeWatchThreshold;
    // Videos shorter than the play threshold can never accumulate enough
    // watch time; bundle play with complete when complete is reached.
    final playReachable = duration >= playThreshold;
    final reportPlay =
        _effectiveWatchSeconds >= playThreshold ||
        (reportComplete && !playReachable);

    return PlaybackEpisodeMetricsSignals(
      reportPlay: reportPlay,
      reportComplete: reportComplete,
    );
  }
}
