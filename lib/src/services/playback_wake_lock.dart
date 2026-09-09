import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/story_logger.dart';

/// Pure policy for whether playback should hold the device awake.
abstract final class PlaybackWakeLockPolicy {
  PlaybackWakeLockPolicy._();

  /// Keep the screen on only while video is actively playing and the feed is
  /// visible to the user. Paused / background / covered → allow idle sleep.
  static bool shouldKeepScreenOn({
    required bool isPlaying,
    required bool isPlaybackVisible,
    required bool userPaused,
  }) {
    if (userPaused || !isPlaybackVisible) return false;
    return isPlaying;
  }
}

/// Platform channel for [PlaybackWakeLock].
abstract final class PlaybackWakeLockChannel {
  PlaybackWakeLockChannel._();

  static const MethodChannel _channel = MethodChannel(
    'com.cestine.officeapp/device',
  );

  static Future<void> setKeepScreenOn(bool keepOn) async {
    if (kIsWeb) return;
    await _channel.invokeMethod<void>('setKeepScreenOn', keepOn);
  }
}

/// Holds the device awake while short-form / drama video is playing.
///
/// Feeds call [apply] with the latest [PlaybackWakeLockPolicy] result; only
/// transitions toggle the platform channel.
class PlaybackWakeLock {
  PlaybackWakeLock._();

  static final PlaybackWakeLock instance = PlaybackWakeLock._();

  @visibleForTesting
  static PlaybackWakeLock Function()? debugOverride;

  static PlaybackWakeLock get current => debugOverride?.call() ?? instance;

  bool? _applied;
  Future<void> Function(bool keepOn)? _platformApply;

  @visibleForTesting
  void debugReset() {
    _applied = null;
    _platformApply = null;
  }

  @visibleForTesting
  void debugSetPlatformApply(Future<void> Function(bool keepOn)? apply) {
    _platformApply = apply;
  }

  @visibleForTesting
  bool? get debugApplied => _applied;

  /// Idempotent: only invokes the platform when [keepOn] changes.
  Future<void> apply({required bool keepOn}) async {
    if (_applied == keepOn) return;
    _applied = keepOn;
    final platform = _platformApply ?? PlaybackWakeLockChannel.setKeepScreenOn;
    try {
      await platform(keepOn);
    } catch (e, st) {
      // Never fail playback because the idle timer could not be toggled.
      StoryLogger.d(
        'PlaybackWakeLock.apply($keepOn) failed',
        error: e,
        stackTrace: st,
        tag: 'WakeLock',
      );
    }
  }

  Future<void> release() => apply(keepOn: false);
}
