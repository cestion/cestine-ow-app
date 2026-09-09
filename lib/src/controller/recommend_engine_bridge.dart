import 'package:better_native_video_player/better_native_video_player.dart';

import '../core/result.dart';
import '../model/models.dart';
import 'playback_engine.dart';
import 'playback_engine_listener.dart';

/// Active-slot event sink for [RecommendEngineBridge].
///
/// Generation is already validated by the bridge — handlers only implement
/// domain reactions (cover latch, recovery, tracking).
abstract interface class RecommendEngineEventSink {
  bool isGenerationCurrent(int generation);

  void onEngineDurationChanged(
    PlaybackEngine engine,
    int generation,
    Duration duration,
  );

  void onEnginePlayingChanged(
    PlaybackEngine engine,
    int generation,
    bool playing,
  );

  void onEnginePositionUpdate(
    PlaybackEngine engine,
    int generation,
    int positionMs,
    int durationMs,
  );

  void onEngineCompleted(PlaybackEngine engine, int generation);

  void onEnginePlaybackFailure(
    PlaybackEngine engine,
    int generation,
    Object error, {
    required bool isSwitch,
  });

  void onEngineError(PlaybackEngine engine, int generation, Object error);

  void onEngineFrameRendered(
    PlaybackEngine engine,
    int generation, {
    required bool isFirstFrame,
    required DateTime renderedAt,
  });
}

/// Generation-gated [PlaybackEngineListener] for the recommend active slot.
///
/// Owns engine→generation bookkeeping so position/frame hot callbacks do one
/// lookup + alive check before entering widget state.
class RecommendEngineBridge extends PlaybackEngineListener {
  RecommendEngineBridge(this._sink);

  final RecommendEngineEventSink _sink;
  final Map<PlaybackEngine, int> _generations = {};

  void attach(PlaybackEngine engine, int generation) {
    _generations[engine] = generation;
    engine.listener = this;
  }

  void detach(PlaybackEngine engine) {
    _generations.remove(engine);
  }

  void clear() => _generations.clear();

  int? _aliveGeneration(PlaybackEngine engine) {
    final generation = _generations[engine];
    if (generation == null) return null;
    if (!_sink.isGenerationCurrent(generation)) return null;
    return generation;
  }

  @override
  void onActivityEvent(PlaybackEngine engine, PlayerActivityEvent event) {}

  @override
  void onEpisodeResult(
    PlaybackEngine engine,
    Result<DramaPlayResponse> result,
  ) {}

  @override
  void onBufferingChanged(PlaybackEngine engine, bool isBuffering) {}

  @override
  void onDurationChanged(PlaybackEngine engine, Duration duration) {
    final generation = _aliveGeneration(engine);
    if (generation == null) return;
    _sink.onEngineDurationChanged(engine, generation, duration);
  }

  @override
  void onPlayingChanged(PlaybackEngine engine, bool isPlaying) {
    final generation = _aliveGeneration(engine);
    if (generation == null) return;
    _sink.onEnginePlayingChanged(engine, generation, isPlaying);
  }

  @override
  void onPositionUpdate(PlaybackEngine engine, int positionMs, int durationMs) {
    final generation = _aliveGeneration(engine);
    if (generation == null) return;
    _sink.onEnginePositionUpdate(engine, generation, positionMs, durationMs);
  }

  @override
  void onCompleted(PlaybackEngine engine) {
    final generation = _aliveGeneration(engine);
    if (generation == null) return;
    _sink.onEngineCompleted(engine, generation);
  }

  @override
  void onPlaybackFailure(
    PlaybackEngine engine,
    Object error, {
    required bool isSwitch,
  }) {
    final generation = _aliveGeneration(engine);
    if (generation == null) return;
    _sink.onEnginePlaybackFailure(
      engine,
      generation,
      error,
      isSwitch: isSwitch,
    );
  }

  @override
  void onError(PlaybackEngine engine, Object error) {
    final generation = _aliveGeneration(engine);
    if (generation == null) return;
    _sink.onEngineError(engine, generation, error);
  }

  @override
  void onFrameRendered(
    PlaybackEngine engine, {
    required bool isFirstFrame,
    required DateTime renderedAt,
  }) {
    final generation = _aliveGeneration(engine);
    if (generation == null) return;
    _sink.onEngineFrameRendered(
      engine,
      generation,
      isFirstFrame: isFirstFrame,
      renderedAt: renderedAt,
    );
  }
}
