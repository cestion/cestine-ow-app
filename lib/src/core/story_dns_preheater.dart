import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'story_logger.dart';

/// Utility to warm DNS cache by resolving hosts asynchronously.
abstract final class StoryDnsPreheater {
  static final Map<String, DateTime> _preheatedHosts = {};
  static const int _maxCacheSize = 50;
  static const Duration _ttl = Duration(minutes: 30);

  /// Resolves the hostname of the given [url] in the background.
  /// Deduplicates by host with a 30-minute TTL and 50 host limit.
  static Future<void> preheat(String url) async {
    if (kIsWeb) return;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return;
      }
    } catch (_) {
      // Platform check may fail on some environments (e.g. web fallback)
    }

    try {
      final host = Uri.parse(url).host;
      if (host.isEmpty) return;

      final now = DateTime.now();
      final lastPreheated = _preheatedHosts[host];
      if (lastPreheated != null && now.difference(lastPreheated) < _ttl) {
        return;
      }

      // Evict oldest if limit reached (FIFO)
      if (_preheatedHosts.length >= _maxCacheSize &&
          !_preheatedHosts.containsKey(host)) {
        _preheatedHosts.remove(_preheatedHosts.keys.first);
      }

      _preheatedHosts[host] = now;
      await InternetAddress.lookup(host).timeout(const Duration(seconds: 3));
      StoryLogger.d('DNS preheated for $host', tag: 'DnsPreheater');
    } catch (_) {
      // Ignore preheat lookup exceptions
    }
  }
}
