import 'dart:async';

import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/widgets.dart';

import '../core/story_constants.dart';
import '../core/story_logger.dart';
import 'native_video_player_coordinator.dart';

/// Thrown when [NativePlayerBootstrap.initialize] aborts because [isCurrent]
/// became false (focus/visibility lost) before the native view was ready.
class NativePlayerInitCancelled implements Exception {
  const NativePlayerInitCancelled();

  @override
  String toString() => 'NativePlayerInitCancelled';
}

/// Shared native player view-wait + initialize sequence.
class NativePlayerBootstrap {
  NativePlayerBootstrap._();

  /// Waits for the platform view to have a chance to build (one post-frame),
  /// then optionally settles for [extraDelay].
  static Future<void> waitForViewReady({
    Duration extraDelay = StoryDurations.playerViewReadyDelay,
  }) async {
    await _waitOnePostFrame();
    if (extraDelay > Duration.zero) {
      await Future<void>.delayed(extraDelay);
    }
  }

  static Future<void> _waitOnePostFrame() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );
  }

  /// Waits until [NativeVideoPlayer] has had time to register its platform
  /// view so [NativeVideoPlayerController.initialize] can take the fast path
  /// (`methodChannel + platformViewIds`) instead of hanging on the plugin's
  /// event-driven completer (which has **no internal timeout**).
  ///
  /// Prefer listening for the first activity callback (fired from
  /// [NativeVideoPlayerController.onPlatformViewCreated]) over blind delays:
  /// calling initialize() before the view is registered leaves
  /// `_isInitializing == true` forever after an external timeout, and every
  /// later initialize() joins that hung Completer.
  static Future<void> _waitForPlatformViewMount(
    NativeVideoPlayerController controller,
  ) async {
    // [isInitialized] can outlive a disposed Platform View — only a live
    // [hasPlatformView] means method calls will not hit NO_VIEW.
    if (controller.hasPlatformView) return;

    final mounted = Completer<void>();
    void onActivity(PlayerActivityEvent event) {
      if (controller.hasPlatformView && !mounted.isCompleted) {
        mounted.complete();
      }
    }

    controller.addActivityListener(onActivity);
    try {
      // Already-mounted views won't fire again — also settle a few frames.
      var frames = 0;
      final frameGate = Completer<void>();
      void onFrame(Duration _) {
        frames++;
        if (controller.hasPlatformView || frames >= 3 || mounted.isCompleted) {
          if (!frameGate.isCompleted) frameGate.complete();
          return;
        }
        WidgetsBinding.instance.scheduleFrameCallback(onFrame);
      }

      WidgetsBinding.instance.scheduleFrameCallback(onFrame);
      await Future.any<void>([
        mounted.future,
        frameGate.future,
      ]).timeout(const Duration(seconds: 2), onTimeout: () {});
      if (!controller.hasPlatformView) return;
      // Short settle so methodChannel + platformViewIds are both set before
      // initialize() probes the fast path.
      await Future<void>.delayed(const Duration(milliseconds: 32));
    } finally {
      controller.removeActivityListener(onActivity);
    }
  }

  /// Acquires the shared native player and initializes [controller].
  ///
  /// Important plugin behavior (better_native_video_player):
  /// - [NativeVideoPlayerController.initialize] waits on an internal
  ///   Completer with **no timeout** until a platform-view event arrives.
  /// - Calling initialize() before the view exists, then timing out externally,
  ///   leaves `_isInitializing == true`; a second call joins the same hung
  ///   Completer.
  /// - If the platform view already exists, initialize() returns immediately.
  ///
  /// So we always wait for mount hints first, call initialize **once** per
  /// attempt with a bounded timeout, and treat a late `isInitialized` as
  /// success when our timeout races the event.
  static Future<void> initialize(
    NativeVideoPlayerController controller, {
    required Object owner,
    NativeVideoPlayerCoordinator? coordinator,
    bool Function()? isCurrent,
    Duration viewReadyDelay = StoryDurations.playerViewReadyDelay,
    Duration timeout = StoryConstants.playerOperationTimeout,
  }) async {
    final c = coordinator ?? NativeVideoPlayerCoordinator.instance;
    await c.acquire(owner);
    try {
      if (isCurrent != null && !isCurrent()) {
        await c.release(owner);
        throw const NativePlayerInitCancelled();
      }

      await _waitForPlatformViewMount(controller);
      if (isCurrent != null && !isCurrent()) {
        await c.release(owner);
        throw const NativePlayerInitCancelled();
      }
      if (!controller.hasPlatformView) {
        StoryLogger.d(
          'Native bootstrap aborted: platform view not mounted',
          tag: 'NativePlayerBootstrap',
        );
        await c.release(owner);
        throw TimeoutException('platform view not mounted');
      }

      if (controller.isInitialized) {
        StoryLogger.d(
          'Native bootstrap skipped: controller already initialized',
          tag: 'NativePlayerBootstrap',
        );
      } else {
        StoryLogger.d(
          'Native bootstrap calling controller.initialize()',
          tag: 'NativePlayerBootstrap',
        );
        try {
          await _awaitWhileCurrent(
            controller.initialize(),
            isCurrent: isCurrent,
            timeout: timeout,
          );
        } on TimeoutException catch (e) {
          // Event may have completed just after our timeout deadline.
          if (controller.isInitialized) {
            StoryLogger.d(
              'Native bootstrap timed out but controller.isInitialized=true',
              tag: 'NativePlayerBootstrap',
            );
          } else {
            StoryLogger.e(
              'Native bootstrap timed out '
              '(platform view missing or event channel stuck)',
              error: e,
              tag: 'NativePlayerBootstrap',
            );
            // Unstick the plugin Completer so a later initialize() can retry
            // once the NativeVideoPlayer widget mounts.
            controller.abortPendingInitialize(error: e);
            await c.release(owner);
            rethrow;
          }
        }
      }

      if (isCurrent != null && !isCurrent()) {
        await c.release(owner);
        throw const NativePlayerInitCancelled();
      }

      final settle = viewReadyDelay < StoryDurations.playerViewReadyDelaySwitch
          ? viewReadyDelay
          : StoryDurations.playerViewReadyDelaySwitch;
      if (settle > Duration.zero) {
        await Future<void>.delayed(settle);
      }
    } on NativePlayerInitCancelled {
      await c.release(owner);
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e, stack) {
      StoryLogger.e(
        'Native player initialize failed',
        error: e,
        stackTrace: stack,
        tag: 'NativePlayerBootstrap',
      );
      await c.release(owner);
      rethrow;
    }
  }

  /// Completes [future] unless [isCurrent] becomes false or [timeout] elapses.
  static Future<void> _awaitWhileCurrent(
    Future<void> future, {
    bool Function()? isCurrent,
    required Duration timeout,
  }) async {
    if (isCurrent == null) {
      await future.timeout(timeout);
      return;
    }

    final cancelled = Completer<void>();
    final timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!isCurrent() && !cancelled.isCompleted) {
        cancelled.complete();
      }
    });

    try {
      await Future.any<void>([
        future,
        cancelled.future.then((_) {
          throw const NativePlayerInitCancelled();
        }),
      ]).timeout(timeout);
    } finally {
      timer.cancel();
    }
  }

  static Future<void> releaseOwner(
    Object owner, {
    NativeVideoPlayerCoordinator? coordinator,
  }) {
    final c = coordinator ?? NativeVideoPlayerCoordinator.instance;
    return c.release(owner);
  }
}
