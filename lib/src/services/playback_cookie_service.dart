// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:meta/meta.dart';

import '../core/result.dart';
import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import '../repositories/drama_repository.dart';
import 'cloudfront_cookie_service.dart';

/// Manages CloudFront signed-cookie lifecycle for [PlaybackEngine].
///
/// Responsibilities:
/// - Applying cookies before loadUrl or preload.
/// - Promoting a preloaded resource's cookies to foreground.
/// - Silently refreshing near-expiry cookies mid-playback.
/// - Clearing cookies from the previous URL when switching episodes.
///
/// Kept stateless where possible — [currentPlay] and other engine-owned
/// state are passed in as method parameters rather than stored here.
class PlaybackCookieService {
  final CloudFrontCookieService _cloudfront;
  final DramaRepository _dramaRepo;
  String _dramaId;
  CloudFrontCookieFamily _family;
  final Future<Result<DramaPlayResponse>> Function(int episodeNo)?
  _episodeLoader;

  /// Global throttle for cookie refresh checks — shared across ALL engines
  /// so 3 engines don't each hit the network every 30s.
  static int _globalLastRefreshCheckMs = 0;
  static const Duration _globalRefreshCheckInterval = Duration(seconds: 30);

  /// Resets the global throttle so the next [refreshCookiesIfNearExpiry]
  /// call is not suppressed by a previous test's timestamp.
  @visibleForTesting
  static void resetRefreshThrottle() => _globalLastRefreshCheckMs = 0;

  PlaybackCookieService({
    required CloudFrontCookieService cloudfront,
    required DramaRepository dramaRepo,
    required String dramaId,
    Future<Result<DramaPlayResponse>> Function(int episodeNo)? episodeLoader,
    CloudFrontCookieFamily family = CloudFrontCookieFamily.feed,
  }) : _cloudfront = cloudfront,
       _dramaRepo = dramaRepo,
       _dramaId = dramaId,
       _episodeLoader = episodeLoader,
       _family = family;

  // -- Mutable state owned by this service -----------------------

  bool _cookieRefreshInFlight = false;
  DateTime? _lastCookieRefreshAttempt;

  /// The URL whose cookies should be cleared on the next episode switch.
  String? urlToClear;

  bool disposed = false;

  /// Point cookie-auth refetch at a new drama without recreating the engine.
  void rebindDrama(String nextDramaId) {
    _dramaId = nextDramaId;
  }

  void rebindFamily(CloudFrontCookieFamily family) {
    _family = family;
  }

  /// Drop jar ownership when this player family leaves the screen.
  void releaseActiveFamily() {
    _cloudfront.releaseActiveFamily(_family);
  }

  // -- Public API ------------------------------------------------

  /// Apply CloudFront cookies for [play]'s URL.
  ///
  /// Pass [background] `true` for inactive-slot / preload paths so the
  /// shared CloudFront cookie jar is not re-marked as the foreground
  /// resource.
  Future<bool> applyCookiesIfNeeded(
    DramaPlayResponse play,
    String url, {
    bool background = false,
  }) async {
    if (play.signedCookies == null || !play.signedCookies!.isValid) {
      if (!background) {
        final result = await _cloudfront.prepareUnsignedPlayback(
          url,
          family: _family,
        );
        if (result.isFailure) {
          StoryLogger.w('Unsigned cookie jar clear failed', tag: 'CookieSvc');
        }
        // Unsigned play on an open CDN never requires cookie approval.
        // Clearing is best-effort; failure must not block playback.
      }
      return true;
    }
    StoryLogger.d(
      '--- Applying cookies${background ? ' (background)' : ''} ---',
      tag: 'CookieSvc',
    );
    final result = await _cloudfront.applyCookies(
      play.signedCookies!,
      url,
      background: background,
      family: _family,
    );
    if (result.isSuccess) {
      StoryLogger.d('✅ Cookies applied', tag: 'CookieSvc');
      return true;
    }
    // One short retry after timeout — the queue is free and a hung
    // MethodChannel often recovers. Avoid burning applyPlayback's full
    // retry budget on repeated 8s waits (weak-net "frozen start").
    final err = result.errorOrNull;
    if (err is TimeoutError && !background) {
      await Future<void>.delayed(StoryDurations.cookieApplyRetryGap);
      final retry = await _cloudfront.applyCookies(
        play.signedCookies!,
        url,
        background: background,
        family: _family,
      );
      if (retry.isSuccess) {
        StoryLogger.d('✅ Cookies applied (retry after timeout)', tag: 'CookieSvc');
        return true;
      }
    }
    StoryLogger.w('Cookies application failed', tag: 'CookieSvc');
    return false;
  }

  /// Mark the preloaded resource as foreground (promote cookies).
  ///
  /// Fast path: if the native jar already holds this URL + signature, only
  /// [CloudFrontCookieService.markActiveResource] runs (no MethodChannel).
  Future<bool> promotePreloadedResource(DramaPlayResponse? play) {
    final url = play?.effectivePlayUrl;
    if (disposed || play == null || url == null || url.isEmpty) {
      return Future<bool>.value(false);
    }
    final cookies = play.signedCookies;
    if (cookies == null || !cookies.isValid) {
      return _cloudfront
          .prepareUnsignedPlayback(url, family: _family)
          .then((_) => true);
    }
    if (_cloudfront.isInstalled(url, cookies)) {
      _cloudfront.markActiveResource(cookies, url, family: _family);
      StoryLogger.d('promote cookies skipped (already installed)');
      return Future<bool>.value(true);
    }
    return applyCookiesIfNeeded(play, url);
  }

  /// Silently refetch play metadata and re-apply cookies when near expiry.
  ///
  /// Returns the fresh [DramaPlayResponse] if cookies were successfully
  /// refreshed, or `null` if no refresh was needed/failed.
  Future<DramaPlayResponse?> refreshCookiesIfNearExpiry({
    required int? episodeNo,
    required DramaPlayResponse? play,
    required bool isDisposed,
  }) async {
    if (isDisposed || _cookieRefreshInFlight) return null;
    // Global throttle: all engines share one check window so N engines don't
    // each hit the network every 30s.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _globalLastRefreshCheckMs <
        _globalRefreshCheckInterval.inMilliseconds) {
      return null;
    }
    _globalLastRefreshCheckMs = nowMs;

    final cookies = play?.signedCookies;
    if (play == null || cookies == null || episodeNo == null) return null;
    if (!cookies.isNearExpiry) return null;

    // isNearExpiry can stay true for a long window — do not re-fetch every
    // second (causes loading↔playing flicker + log spam).
    final now = DateTime.now();
    final last = _lastCookieRefreshAttempt;
    if (last != null && now.difference(last) < const Duration(minutes: 2)) {
      return null;
    }
    _lastCookieRefreshAttempt = now;

    _cookieRefreshInFlight = true;
    try {
      StoryLogger.d(
        'Silent cookie refresh (near expiry) episode=$episodeNo',
        tag: 'CookieSvc',
      );
      final loader = _episodeLoader;
      if (loader == null) {
        _dramaRepo.clearPrefetchCache(_dramaId, episodeNo);
      }
      final result = loader != null
          ? await loader(episodeNo)
          : await _dramaRepo.getEpisodeDetail(_dramaId, episodeNo);
      if (disposed || result.isFailure) return null;
      final fresh = result.dataOrNull;
      if (fresh == null) return null;
      final url = fresh.effectivePlayUrl;
      if (url == null || url.isEmpty) return null;
      final ok = await applyCookiesIfNeeded(fresh, url);
      if (!ok || disposed) return null;
      urlToClear = fresh.signedCookies != null ? url : null;
      StoryLogger.d('✅ Silent cookie refresh applied', tag: 'CookieSvc');
      return fresh;
    } catch (e, st) {
      StoryLogger.w(
        'Silent cookie refresh failed',
        error: e,
        stackTrace: st,
        tag: 'CookieSvc',
      );
      return null;
    } finally {
      _cookieRefreshInFlight = false;
    }
  }

  /// Request cookie service to clear cookies for [url].
  Future<void> clearCookies(String url) async {
    await _cloudfront.clearCookies(url);
  }
}
