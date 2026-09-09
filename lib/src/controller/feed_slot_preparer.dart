import 'dart:async';

import 'package:better_native_video_player/better_native_video_player.dart';

import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../services/native_video_player_coordinator.dart';
import 'feed_slot.dart';
import 'playback_engine.dart';

/// UI / DI hooks for [FeedSlotPreparer].
///
/// Keeps Flutter setState and Riverpod engine construction out of the shared
/// choreography so recommend (and any future lazy feed) can reuse the same
/// pause → rebind → initialize → waitForViewReady → eagerInitialize order
/// that matches [VideoFeedPage] mount timing.
abstract interface class FeedSlotPrepareHost {
  bool get isMounted;

  /// Allocate a native controller id for a brand-new slot.
  NativeVideoPlayerController createNativeController();

  /// Build a [PlaybackEngine] bound to [coordinator] / [bindWorkId].
  PlaybackEngine createEngine({
    required String bindWorkId,
    required String tag,
    required NativeVideoPlayerCoordinator coordinator,
  });

  /// Notify the widget tree after slot identity / surface flags change.
  void notifySlotChanged();

  /// Drop any cached Platform View for a replaced native controller.
  void invalidateSurfaceCache(NativeVideoPlayerController native);
}

/// Shared prepare pipeline: wait teardown → reuse or create → view ready.
class FeedSlotPreparer {
  FeedSlotPreparer(this._host);

  final FeedSlotPrepareHost _host;

  Future<PlaybackEngine?> prepare({
    required FeedSlot slot,
    required String playbackId,
    required String bindWorkId,
    required int index,
    required NativeVideoPlayerCoordinator coordinator,
    required String tag,
    required PlaybackEngineRole role,
    required bool looping,
    required int generation,
    required int Function() currentGeneration,
    required bool Function(FeedSlot slot) allowSlot,
    String logTag = 'Feed',
  }) async {
    if (NativeVideoPlayerCoordinator.isTearingDown) {
      await NativeVideoPlayerCoordinator.waitForTeardown(
        timeout: const Duration(seconds: 90),
      );
    }
    if (NativeVideoPlayerCoordinator.isTearingDown ||
        !_alive(generation, currentGeneration) ||
        !allowSlot(slot)) {
      return null;
    }

    final existing = slot.engine;
    final existingNative = slot.native;
    if (existing != null && existingNative != null) {
      return _reuseExisting(
        slot: slot,
        engine: existing,
        native: existingNative,
        playbackId: playbackId,
        bindWorkId: bindWorkId,
        index: index,
        tag: tag,
        role: role,
        looping: looping,
        generation: generation,
        currentGeneration: currentGeneration,
        allowSlot: allowSlot,
      );
    }

    return _createNew(
      slot: slot,
      playbackId: playbackId,
      bindWorkId: bindWorkId,
      index: index,
      coordinator: coordinator,
      tag: tag,
      role: role,
      looping: looping,
      generation: generation,
      currentGeneration: currentGeneration,
      logTag: logTag,
    );
  }

  Future<PlaybackEngine?> _reuseExisting({
    required FeedSlot slot,
    required PlaybackEngine engine,
    required NativeVideoPlayerController native,
    required String playbackId,
    required String bindWorkId,
    required int index,
    required String tag,
    required PlaybackEngineRole role,
    required bool looping,
    required int generation,
    required int Function() currentGeneration,
    required bool Function(FeedSlot slot) allowSlot,
  }) async {
    try {
      await engine.pause();
    } catch (_) {}
    if (!allowSlot(slot)) return null;
    try {
      await engine.cancelStaleLoad();
    } catch (_) {}
    if (!allowSlot(slot)) return null;

    engine.rebindDrama(bindWorkId);
    engine.retargetSlot(tag: tag, role: role);
    unawaited(engine.setLooping(looping));

    if (engine.nativeController == null) {
      await engine.initialize(native);
      if (!_alive(generation, currentGeneration) || !allowSlot(slot)) {
        return null;
      }
    }

    slot
      ..playbackId = playbackId
      ..index = index
      ..frameReady = false
      ..surfaceReady = true;
    if (_host.isMounted) _host.notifySlotChanged();

    if (!native.hasPlatformView) {
      final viewOk = await engine.waitForPlatformView(
        timeout: const Duration(milliseconds: 800),
      );
      if (!viewOk) {
        await engine.waitForViewReady(
          extraDelay: StoryDurations.playerViewReadyDelaySwitch,
        );
      }
      if (!_alive(generation, currentGeneration) || !allowSlot(slot)) {
        return null;
      }
    }
    if (!native.isInitialized) {
      engine.invalidateNativeInitialization();
    }
    return engine;
  }

  Future<PlaybackEngine?> _createNew({
    required FeedSlot slot,
    required String playbackId,
    required String bindWorkId,
    required int index,
    required NativeVideoPlayerCoordinator coordinator,
    required String tag,
    required PlaybackEngineRole role,
    required bool looping,
    required int generation,
    required int Function() currentGeneration,
    required String logTag,
  }) async {
    final native = _host.createNativeController();
    final engine = _host.createEngine(
      bindWorkId: bindWorkId,
      tag: tag,
      coordinator: coordinator,
    );
    engine.retargetSlot(tag: tag, role: role);
    unawaited(engine.setLooping(looping));

    slot
      ..native = native
      ..engine = engine
      ..playbackId = playbackId
      ..index = index
      ..surfaceReady = false
      ..frameReady = false;
    _host.invalidateSurfaceCache(native);
    if (_host.isMounted) _host.notifySlotChanged();

    await engine.initialize(native);
    if (!_alive(generation, currentGeneration)) return null;

    // Mount the platform view, then wait a frame before bootstrap — same
    // order as VideoFeedPage (avoid initialize-before-view).
    slot.surfaceReady = true;
    if (_host.isMounted) _host.notifySlotChanged();
    await engine.waitForViewReady(
      extraDelay: StoryDurations.playerViewReadyDelaySwitch,
    );
    if (!_alive(generation, currentGeneration)) return null;

    try {
      await engine.eagerInitialize();
    } catch (e) {
      StoryLogger.d(
        '$tag eagerInitialize failed (applyPlayback will retry)',
        error: e,
        tag: logTag,
      );
    }
    if (!_alive(generation, currentGeneration)) return null;
    return engine;
  }

  bool _alive(int generation, int Function() currentGeneration) =>
      _host.isMounted && generation == currentGeneration();
}
