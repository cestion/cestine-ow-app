import 'dart:io';

import 'package:flutter/services.dart';

import '../core/story_logger.dart';
import '../core/video_url_helpers.dart';

/// iOS AVPlayer disk cache backed by a localhost KTVHTTPCache proxy.
///
/// Android keeps using better_native_video_player's Media3 SimpleCache.
class IosVideoCacheService {
  IosVideoCacheService._();

  static final IosVideoCacheService instance = IosVideoCacheService._();

  static const MethodChannel _channel = MethodChannel(
    'com.cestine.officeapp/video_cache',
  );

  Future<bool>? _initializing;
  bool _initSucceeded = false;
  int _initFailures = 0;

  Future<bool> initialize() {
    if (!Platform.isIOS) return Future<bool>.value(false);
    if (_initSucceeded) return Future<bool>.value(true);
    // Allow a few retries after transient MissingPluginException (hot restart
    // / late channel registration) instead of caching a permanent false.
    final inFlight = _initializing;
    if (inFlight != null) return inFlight;
    final attempt = _initializeImpl();
    _initializing = attempt;
    return attempt;
  }

  Future<bool> _initializeImpl() async {
    try {
      final ok =
          await _channel.invokeMethod<bool>('initialize', {
            'maxCacheBytes': 250 * 1024 * 1024,
          }) ??
          false;
      _initSucceeded = ok;
      if (!ok) {
        _initializing = null;
      }
      return ok;
    } catch (error, stackTrace) {
      _initFailures++;
      _initializing = null;
      StoryLogger.w(
        'iOS video cache initialization failed (attempt=$_initFailures)',
        error: error,
        stackTrace: stackTrace,
        tag: 'IosVideoCache',
      );
      return false;
    }
  }

  final Map<String, String> _proxyUrlCache = {};

  /// Drop a cached proxy mapping so the next resolve can fall back to origin.
  void invalidateProxy(String url) {
    _proxyUrlCache.remove(url);
  }

  /// Returns a localhost proxy URL on iOS, otherwise [url].
  ///
  /// HLS (`.m3u8`) always plays from the origin URL: KTVHTTPCache proxying
  /// master playlists is a frequent source of AVPlayer "unsupported URL".
  Future<String> resolvePlaybackUrl(String url) async {
    if (!Platform.isIOS) return url;
    if (!VideoUrlHelpers.isHttpUrl(url)) return url;
    if (VideoUrlHelpers.formatOf(url) == VideoUrlFormat.hls) return url;

    // Stable per-session cache: the KTVHTTPCache proxy URL is deterministic
    // for the same source URL, and episodes are loaded at most once per
    // session (applyPlayback + preloadEpisode share the same URL).
    final cached = _proxyUrlCache[url];
    if (cached != null) return cached;
    if (!await initialize()) {
      _proxyUrlCache[url] = url;
      return url;
    }
    try {
      final proxy = await _channel.invokeMethod<String>('proxyUrl', {
        'url': url,
      });
      // Empty / non-http proxy strings must not be cached — AVPlayer then
      // fails with "unsupported URL" and retries keep hitting the poison
      // mapping.
      final result = (proxy != null && VideoUrlHelpers.isHttpUrl(proxy))
          ? proxy
          : url;
      if (result == url && proxy != null && proxy != url) {
        StoryLogger.w(
          'iOS proxy URL rejected, using origin host=${Uri.tryParse(url)?.host}',
          tag: 'IosVideoCache',
        );
      }
      _proxyUrlCache[url] = result;
      return result;
    } catch (error) {
      StoryLogger.d(
        'iOS proxy URL fallback to origin',
        error: error,
        tag: 'IosVideoCache',
      );
      _proxyUrlCache[url] = url;
      return url;
    }
  }

  /// Warms the iOS proxy cache without blocking playback startup.
  Future<bool> precache(
    String url, {
    Map<String, String>? headers,
    required int maxBytes,
  }) async {
    if (!Platform.isIOS || !await initialize()) return false;
    if (!VideoUrlHelpers.isHttpUrl(url)) return false;
    try {
      return await _channel.invokeMethod<bool>('precache', {
            'url': url,
            'headers': headers ?? const <String, String>{},
            'maxBytes': maxBytes,
          }) ??
          false;
    } catch (error, stackTrace) {
      StoryLogger.w(
        'iOS video precache failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'IosVideoCache',
      );
      return false;
    }
  }

  /// Bytes currently held by KTVHTTPCache. Returns 0 off iOS or on failure.
  Future<int> cacheBytes() async {
    if (!Platform.isIOS) return 0;
    try {
      return await _channel.invokeMethod<int>('cacheSize') ?? 0;
    } catch (error) {
      StoryLogger.d(
        'iOS video cache size failed',
        error: error,
        tag: 'IosVideoCache',
      );
      return 0;
    }
  }

  /// Deletes all KTVHTTPCache resources and the in-memory proxy URL map.
  Future<void> clearCache() async {
    if (!Platform.isIOS) return;
    _proxyUrlCache.clear();
    try {
      await _channel.invokeMethod<void>('cacheClear');
    } catch (error, stackTrace) {
      StoryLogger.w(
        'iOS video cache clear failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'IosVideoCache',
      );
    }
  }
}
