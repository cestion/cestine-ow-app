import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/native_video_player_config.dart';

/// Warms the opt-in Android disk cache
/// ([NativeVideoPlayerConfig.androidEnableDiskCache]) for upcoming videos.
///
/// ```dart
/// NativeVideoPlayerConfig.global = const NativeVideoPlayerConfig(
///   androidEnableDiskCache: true,
/// );
/// // Later, e.g. when the next feed items become known:
/// await NativeVideoPlayerCache.precache(nextItem.videoUrl);
/// ```
abstract final class NativeVideoPlayerCache {
  static const MethodChannel _channel = MethodChannel('native_video_player');

  /// Pre-caches the start of [url] into the Android disk cache so a later
  /// `load()` starts without network round-trips.
  ///
  /// Progressive sources cache their first bytes; HLS warms the playlists
  /// plus leading segments. [maxBytes] overrides the
  /// [NativeVideoPlayerConfig.androidPrecacheBytes] budget; [headers] are
  /// sent with the cache-filling requests (use the same headers as the
  /// later `load()`).
  ///
  /// Returns true when the cache was warmed. Returns false — without any
  /// platform call — on non-Android platforms or when
  /// [NativeVideoPlayerConfig.androidEnableDiskCache] is off, and on any
  /// platform failure (precache must never break the app).
  static Future<bool> precache(
    String url, {
    Map<String, String>? headers,
    int? maxBytes,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    if (!NativeVideoPlayerConfig.global.androidEnableDiskCache) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('precacheVideo', {
        'url': url,
        if (headers != null) 'headers': headers,
        'precacheBytes':
            maxBytes ?? NativeVideoPlayerConfig.global.androidPrecacheBytes,
        'cacheMaxBytes':
            NativeVideoPlayerConfig.global.androidDiskCacheMaxBytes,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('NativeVideoPlayerCache.precache failed for $url: $e');
      return false;
    }
  }

  /// Bytes currently occupied by the Android SimpleCache directory.
  ///
  /// Returns 0 on non-Android platforms or if the plugin call fails.
  static Future<int> diskCacheBytes() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 0;
    }
    try {
      final result = await _channel.invokeMethod<int>('getDiskCacheBytes');
      return result ?? 0;
    } catch (e) {
      debugPrint('NativeVideoPlayerCache.diskCacheBytes failed: $e');
      return 0;
    }
  }

  /// Removes every resource from the Android SimpleCache.
  ///
  /// Safe while players are still attached (removes cache keys through the
  /// open SimpleCache instead of deleting open files). No-op on non-Android.
  static Future<void> clearDiskCache() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('clearDiskCache', {
        'cacheMaxBytes':
            NativeVideoPlayerConfig.global.androidDiskCacheMaxBytes,
      });
    } catch (e) {
      debugPrint('NativeVideoPlayerCache.clearDiskCache failed: $e');
    }
  }
}
