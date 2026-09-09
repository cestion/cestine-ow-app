import 'dart:async';
import 'dart:io' show Platform;

import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/foundation.dart';

import '../core/story_constants.dart';
import '../core/story_dns_preheater.dart';
import '../core/story_logger.dart';
import '../core/video_url_helpers.dart';
import '../model/models.dart';
import '../repositories/drama_repository.dart';
import 'cloudfront_cookie_service.dart';
import 'ios_video_cache_service.dart';

/// Where the precache byte budget is applied.
enum VideoPrecacheContext { episode, banner, recommendHead }

/// Priority levels for precache tasks.
/// Higher priority tasks are dequeued first.
enum PrecachePriority {
  /// Currently playing episode — highest priority.
  active(3),

  /// Next episode (N+1) — high priority.
  next(2),

  /// Two ahead (N+2) — medium priority.
  ahead(1),

  /// Banner / recommend head — lowest priority.
  background(0);

  const PrecachePriority(this.value);

  /// Numeric value for comparison (higher = more urgent).
  final int value;
}

/// Format-aware wrapper around [NativeVideoPlayerCache.precache].
///
/// HLS warms the playlist plus leading segments; MP4 warms the file head
/// (moov + initial mdat). Signed CloudFront media sends Cookie headers on
/// the warm request and does not mutate the shared native cookie jar.
///
/// Concurrent calls for the same URL / episode are coalesced so Theater,
/// Feed, and Detail warmers do not stampede the network.
class VideoPrecacheService {
  VideoPrecacheService._();

  static final VideoPrecacheService instance = VideoPrecacheService._();

  final Map<String, Future<bool>> _precacheInflight = {};
  final Map<String, Future<bool>> _prefetchWarmInflight = {};
  final Map<String, DateTime> _warmedAt = {};

  /// Skip a second disk fill for the same URL within this window. Recommend
  /// head + neighbor prefetch otherwise re-hit the same HLS after every
  /// promote even though the previous fill already succeeded.
  static const Duration _warmTtl = Duration(seconds: 60);

  /// Warm-task throttle. Theater fires one warm per drama card that enters
  /// the viewport; without a cap a fast scroll launches dozens of concurrent
  /// multi-MB downloads that starve the playing stream (and on iOS pile onto
  /// the KTVHTTPCache proxy + serialized cookie queue) — enough to freeze
  /// the app. Cap at 2 so feed N+1 and N+2 disk fills can overlap without
  /// letting theater viewport storms monopolize the pipe.
  static const int _maxConcurrentWarms = 2;

  /// Pending warms beyond the running ones. When full the oldest queued task
  /// is dropped (resolved `false`): during scroll the newest requests match
  /// what the user is actually near. Sized for feed WiFi +5 head warms
  /// without immediately evicting N+1.
  static const int _maxQueuedWarms = 12;

  final List<_QueuedWarm> _warmQueue = [];
  int _activeWarms = 0;

  Future<bool> _scheduleWarm(
    Future<bool> Function() task, {
    PrecachePriority priority = PrecachePriority.background,
  }) {
    final queued = _QueuedWarm(task, priority: priority);
    _warmQueue.add(queued);
    // Sort by priority descending so highest priority tasks are at the front.
    _warmQueue.sort((a, b) => b.priority.value.compareTo(a.priority.value));
    if (_warmQueue.length > _maxQueuedWarms) {
      // Drop lowest priority (now at the end after sort).
      final dropped = _warmQueue.removeLast();
      dropped.completer.complete(false);
      StoryLogger.d(
        'precache queue full, dropped lowest priority task',
        tag: 'VideoPrecache',
      );
    }
    _pumpWarmQueue();
    return queued.completer.future;
  }

  void _pumpWarmQueue() {
    while (_activeWarms < _maxConcurrentWarms && _warmQueue.isNotEmpty) {
      final item = _warmQueue.removeAt(0);
      _activeWarms++;
      item
          .task()
          .then(item.completer.complete)
          .catchError((Object e, StackTrace st) {
            StoryLogger.w(
              'precache task failed',
              error: e,
              stackTrace: st,
              tag: 'VideoPrecache',
            );
            item.completer.complete(false);
          })
          .whenComplete(() {
            _activeWarms--;
            _pumpWarmQueue();
          });
    }
  }

  static int bytesBudgetFor(
    String url, {
    VideoPrecacheContext context = VideoPrecacheContext.episode,
    double budgetRatio = 1.0,
  }) {
    final format = VideoUrlHelpers.formatOf(url);
    final base = switch (context) {
      VideoPrecacheContext.banner => switch (format) {
        VideoUrlFormat.hls => StoryConstants.precacheBytesBannerHls,
        VideoUrlFormat.mp4 => StoryConstants.precacheBytesBannerMp4,
        VideoUrlFormat.unknown => StoryConstants.precacheBytesDefault,
      },
      VideoPrecacheContext.episode => switch (format) {
        VideoUrlFormat.hls => StoryConstants.precacheBytesHls,
        VideoUrlFormat.mp4 => StoryConstants.precacheBytesMp4,
        VideoUrlFormat.unknown => StoryConstants.precacheBytesDefault,
      },
      VideoPrecacheContext.recommendHead =>
        StoryConstants.precacheBytesRecommendHead,
    };
    return (base * budgetRatio).round();
  }

  static String _precacheKey(String url, VideoPrecacheContext context) =>
      '$url|${context.name}';

  bool _isFreshlyWarmed(String key) {
    final at = _warmedAt[key];
    if (at == null) return false;
    if (DateTime.now().difference(at) > _warmTtl) {
      _warmedAt.remove(key);
      return false;
    }
    return true;
  }

  @visibleForTesting
  void debugMarkWarmed(
    String url, {
    VideoPrecacheContext context = VideoPrecacheContext.episode,
    double budgetRatio = 1.0,
    DateTime? at,
  }) {
    _warmedAt[_precacheKey(url, context)] = at ?? DateTime.now();
  }

  @visibleForTesting
  void debugClearWarmed() => _warmedAt.clear();

  /// Whether [url] was disk-warmed recently (within [_warmTtl]).
  bool isFreshlyWarmed(
    String url, {
    VideoPrecacheContext context = VideoPrecacheContext.episode,
  }) => _isFreshlyWarmed(_precacheKey(url, context));

  @visibleForTesting
  bool debugIsFreshlyWarmed(
    String url, {
    VideoPrecacheContext context = VideoPrecacheContext.episode,
    double budgetRatio = 1.0,
  }) => _isFreshlyWarmed(_precacheKey(url, context));

  /// Pre-warm disk cache and DNS for [url].
  ///
  /// Returns whether the native cache reported success (false on iOS or when
  /// disk cache is disabled — callers should treat that as a no-op).
  Future<bool> precacheUrl(
    String url, {
    Map<String, String>? headers,
    CloudFrontSignedCookies? signedCookies,
    VideoPrecacheContext context = VideoPrecacheContext.episode,
    double budgetRatio = 1.0,
    PrecachePriority priority = PrecachePriority.background,
  }) {
    if (url.isEmpty || budgetRatio <= 0) return Future<bool>.value(false);

    final key = _precacheKey(url, context);
    if (_isFreshlyWarmed(key)) return Future<bool>.value(true);
    final existing = _precacheInflight[key];
    if (existing != null) return existing;

    final future = _scheduleWarm(
      () => _precacheUrlImpl(
        url,
        headers: headers,
        signedCookies: signedCookies,
        context: context,
        budgetRatio: budgetRatio,
      ),
      priority: priority,
    );
    _precacheInflight[key] = future;
    return future.whenComplete(() {
      if (identical(_precacheInflight[key], future)) {
        _precacheInflight.remove(key);
      }
    });
  }

  Future<bool> _precacheUrlImpl(
    String url, {
    Map<String, String>? headers,
    CloudFrontSignedCookies? signedCookies,
    required VideoPrecacheContext context,
    required double budgetRatio,
  }) async {
    StoryDnsPreheater.preheat(url);

    // Disk warm must not mutate the shared native CloudFront jar. Guest
    // recommend plays have no cookies; leftover Policy/Signature from a
    // theater warm 403 AVPlayer even though Dart HTTP precache succeeds.
    // Media3 / KTVHTTPCache honor the Cookie request header.
    final requestHeaders = <String, String>{...?headers};
    if ((requestHeaders['Cookie'] == null ||
            requestHeaders['Cookie']!.isEmpty) &&
        signedCookies != null &&
        signedCookies.isValid) {
      requestHeaders.addAll(
        CloudFrontCookieService.buildHeaders(
          DramaPlayResponse(mediaAccessUrl: url, signedCookies: signedCookies),
        ),
      );
    }

    final maxBytes = bytesBudgetFor(
      url,
      context: context,
      budgetRatio: budgetRatio,
    );
    final format = VideoUrlHelpers.formatOf(url);
    final ok = Platform.isIOS
        ? await IosVideoCacheService.instance.precache(
            url,
            headers: requestHeaders.isEmpty ? null : requestHeaders,
            maxBytes: maxBytes,
          )
        : await NativeVideoPlayerCache.precache(
            url,
            headers: requestHeaders.isEmpty ? null : requestHeaders,
            maxBytes: maxBytes,
          );
    StoryLogger.d(
      'precache url=$url format=$format context=$context '
      'bytes=$maxBytes ok=$ok',
      tag: 'VideoPrecache',
    );
    if (ok) {
      _warmedAt[_precacheKey(url, context)] = DateTime.now();
    }
    return ok;
  }

  /// Pre-warm using a resolved episode play response.
  Future<bool> precachePlay(
    DramaPlayResponse play, {
    VideoPrecacheContext context = VideoPrecacheContext.episode,
    double budgetRatio = 1.0,
    PrecachePriority priority = PrecachePriority.background,
  }) {
    final url = play.effectivePlayUrl;
    if (url == null || url.isEmpty) return Future<bool>.value(false);
    return precacheUrl(
      url,
      headers: CloudFrontCookieService.buildHeaders(play),
      signedCookies: play.signedCookies,
      context: context,
      budgetRatio: budgetRatio,
      priority: priority,
    );
  }

  /// Fetches episode play metadata then warms DNS + disk cache.
  Future<bool> prefetchAndWarm(
    DramaRepository repo,
    String dramaId,
    int episodeNo, {
    VideoPrecacheContext context = VideoPrecacheContext.episode,
    double budgetRatio = 1.0,
    PrecachePriority priority = PrecachePriority.background,
  }) {
    final key =
        '${dramaId}_$episodeNo|${context.name}|${budgetRatio.toStringAsFixed(2)}';
    final existing = _prefetchWarmInflight[key];
    if (existing != null) return existing;

    final future = _prefetchAndWarmImpl(
      repo,
      dramaId,
      episodeNo,
      context: context,
      budgetRatio: budgetRatio,
      priority: priority,
    );
    _prefetchWarmInflight[key] = future;
    return future.whenComplete(() {
      if (identical(_prefetchWarmInflight[key], future)) {
        _prefetchWarmInflight.remove(key);
      }
    });
  }

  Future<bool> _prefetchAndWarmImpl(
    DramaRepository repo,
    String dramaId,
    int episodeNo, {
    required VideoPrecacheContext context,
    required double budgetRatio,
    required PrecachePriority priority,
  }) async {
    try {
      final play = await repo.prefetchEpisode(dramaId, episodeNo);
      if (play == null) return false;
      return precachePlay(
        play,
        context: context,
        budgetRatio: budgetRatio,
        priority: priority,
      );
    } catch (e, st) {
      StoryLogger.w(
        'prefetchAndWarm failed drama=$dramaId ep=$episodeNo',
        error: e,
        stackTrace: st,
        tag: 'VideoPrecache',
      );
      return false;
    }
  }
}

class _QueuedWarm {
  final Future<bool> Function() task;
  final PrecachePriority priority;
  final Completer<bool> completer = Completer<bool>();

  _QueuedWarm(this.task, {this.priority = PrecachePriority.background});
}
