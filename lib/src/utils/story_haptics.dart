import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Player-safe haptics.
///
/// While [AVAudioSession] is in movie-playback mode, Flutter's
/// [HapticFeedback] impact styles are often swallowed on iPhone. We also
/// ping a tiny native channel that uses `AudioServicesPlaySystemSound`
/// (peek/pop) which still fires during playback.
class StoryHaptics {
  StoryHaptics._();

  static const MethodChannel _channel = MethodChannel(
    'com.cestine.officeapp/haptics',
  );

  /// Medium confirmation tap (follow, like, etc.).
  static Future<void> impact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('impact');
    } catch (_) {
      // Channel missing on Android / older builds — Dart haptic is enough.
    }
  }
}
