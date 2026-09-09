import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'story_logger.dart';

/// Detects the Android emulator image (ranchu / goldfish).
///
/// The emulator's `c2.goldfish.*` decoders recycle graphic buffers across
/// streams without clearing them. After a resolution change the new frame
/// only covers part of the buffer and the rest still shows the previous
/// video — a mismatched thumbnail pinned over the current feed card. Software
/// decoders (`c2.android.*`) use their own buffers and avoid the pool.
abstract final class AndroidEmulatorProbe {
  AndroidEmulatorProbe._();

  static const MethodChannel _channel = MethodChannel(
    'com.cestine.officeapp/device',
  );

  static bool _resolved = false;
  static bool _isEmulator = false;

  /// Last [detect] result; false until the probe runs.
  static bool get isEmulator => _isEmulator;

  /// Runs on the cold-start critical path: never throws, and spends at most
  /// [attempts] × [timeout] rather than delaying `StorySdk.initialize`. The
  /// first channel call of a cold start can lose the race with engine setup,
  /// so a miss is retried instead of silently downgrading to "physical".
  static Future<bool> detect({
    Duration timeout = const Duration(milliseconds: 400),
    int attempts = 3,
  }) async {
    if (_resolved) return _isEmulator;
    _resolved = true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        _isEmulator =
            await _channel.invokeMethod<bool>('isEmulator').timeout(timeout) ??
            false;
        return _isEmulator;
      } catch (error) {
        StoryLogger.d(
          'emulator probe attempt $attempt/$attempts failed: $error',
          tag: 'StorySdk',
        );
      }
    }
    StoryLogger.w(
      'emulator probe gave up; assuming physical device',
      tag: 'StorySdk',
    );
    return _isEmulator;
  }

  @visibleForTesting
  static void resetForTest() {
    _resolved = false;
    _isEmulator = false;
  }
}
