import 'dart:async';

import 'package:flutter/services.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../foundation/telemetry.dart';
import '../model/models.dart';

/// Which playback surface currently owns the foreground CloudFront jar entry.
///
/// Background ops for a *different* family skip mutating the shared native
/// jar so recommend preload cannot clobber a live feed stream (and vice
/// versa). Same-family background preload still apply-B → restore-A.
enum CloudFrontCookieFamily { feed, recommend, banner, precache }

class CloudFrontCookieService {
  CloudFrontCookieService._();
  static final CloudFrontCookieService instance = CloudFrontCookieService._();

  static const MethodChannel _channel = MethodChannel(
    'com.cestine.officeapp/cloudfront',
  );

  /// Serializes all native cookie mutations. The native cookie store is a
  /// shared/global surface, so two concurrent `applyCookies` (e.g. the active
  /// episode vs a background precache warming a different episode) can race
  /// and leave the store holding the wrong resource's signature.
  Future<void> _cookieOp = Future<void>.value();

  /// Upper bound on any single native cookie mutation.
  ///
  /// If the iOS/Android method channel never completes (e.g. plugin paused on
  /// background isolate, race with native teardown), the queue must not
  /// block forever — every queued op after a hung one would otherwise pile up
  /// and freeze all [PlaybackEngine.applyPlayback] callers downstream.
  static const _opTimeout = Duration(seconds: 8);

  /// The foreground episode's signed cookies + URL. A background precache for
  /// a *different* resource re-asserts these after applying its own cookies so
  /// the currently-playing stream never ends up unauthorized (403).
  CloudFrontSignedCookies? _activeCookies;
  String? _activeUrl;
  CloudFrontCookieFamily? _activeFamily;

  /// Signature currently installed in the shared native cookie surface.
  ///
  /// This must track the *last installed* resource, not a per-URL history:
  /// background prefetch temporarily installs URL B and then restores active
  /// URL A. A per-URL cache would incorrectly skip restoring A because A had
  /// been applied sometime in the past, even though B is currently installed.
  String? _installedUrl;
  String? _installedSignature;

  CloudFrontCookieFamily? get activeFamily => _activeFamily;

  /// Foreground URL is playing without signed cookies. Leftover CloudFront
  /// cookies on `.actqa.com` 403 these requests; background apply must skip.
  bool get hasUnsignedForeground =>
      _activeFamily != null && _activeCookies == null && _activeUrl != null;

  /// Whether [mediaAccessUrl] + [cookies] already match the native jar.
  bool isInstalled(String mediaAccessUrl, CloudFrontSignedCookies cookies) {
    if (!cookies.isValid || mediaAccessUrl.isEmpty) return false;
    final signatureKey = '${cookies.policy}|${cookies.signature}';
    return _installedUrl == mediaAccessUrl &&
        _installedSignature == signatureKey;
  }

  /// Marks the resource that is (about to be) played in the foreground so
  /// background precache cookie application can restore it afterwards.
  ///
  /// Pass null/invalid [cookies] for an unsigned CDN URL — ownership stays
  /// so neighbor preload cannot install a foreign CloudFront-Policy.
  void markActiveResource(
    CloudFrontSignedCookies? cookies,
    String url, {
    CloudFrontCookieFamily family = CloudFrontCookieFamily.feed,
  }) {
    if (url.isEmpty) {
      _activeCookies = null;
      _activeUrl = null;
      _activeFamily = null;
      return;
    }
    _activeUrl = url;
    _activeFamily = family;
    _activeCookies = (cookies != null && cookies.isValid) ? cookies : null;
  }

  /// Drop foreground ownership when [family] leaves the screen (tab switch /
  /// dispose) so another family's background ops do not restore a stale URL.
  void releaseActiveFamily(CloudFrontCookieFamily family) {
    if (_activeFamily != family) return;
    _activeCookies = null;
    _activeUrl = null;
    _activeFamily = null;
  }

  /// 根据 CloudFront 签名 Cookie 构建 HTTP 请求头
  static Map<String, String> buildHeaders(DramaPlayResponse play) {
    if (play.signedCookies == null || !play.signedCookies!.isValid) return {};
    final cookies = play.signedCookies!;
    return {
      'Cookie':
          'CloudFront-Policy=${cookies.policy}; '
          'CloudFront-Signature=${cookies.signature}; '
          'CloudFront-Key-Pair-Id=${cookies.keyPairId}',
    };
  }

  /// Applies signed cookies for [mediaAccessUrl].
  ///
  /// When [background] is true (precache warming) and a different foreground
  /// resource is active, the active resource's cookies are re-applied
  /// afterwards to defend against the shared native cookie store being
  /// clobbered mid-playback.
  ///
  /// Cross-family background applies are skipped when another family owns
  /// the foreground — mutating the jar would race the live stream. Callers
  /// should prefer Cookie headers for that warm path.
  Future<Result<void>> applyCookies(
    CloudFrontSignedCookies cookies,
    String mediaAccessUrl, {
    bool background = false,
    CloudFrontCookieFamily family = CloudFrontCookieFamily.feed,
  }) {
    if (!cookies.isValid || mediaAccessUrl.isEmpty) {
      StoryLogger.w(
        'CloudFront cookies invalid or empty URL',
        tag: 'CloudFront',
      );
      return Future.value(
        Result.failure(
          ApiError.unknown('CloudFront cookies invalid or empty URL'),
        ),
      );
    }
    if (!background) {
      markActiveResource(cookies, mediaAccessUrl, family: family);
    } else if (_activeFamily != null && _activeFamily != family) {
      StoryLogger.d(
        'skip background cookie apply for $family '
        '(active family=$_activeFamily)',
        tag: 'CloudFront',
      );
      return Future.value(Result.success(null));
    } else if (hasUnsignedForeground) {
      // Native CF cookies are domain-wide. Installing a neighbor signature
      // while the active item has no cookies makes AVPlayer send the wrong
      // CloudFront-Policy → 403. Warm via Cookie headers instead.
      StoryLogger.d(
        'skip background cookie apply for $family '
        '(unsigned foreground=$_activeUrl)',
        tag: 'CloudFront',
      );
      return Future.value(Result.success(null));
    }
    return _enqueue(() async {
      final result = await _invokeApply(cookies, mediaAccessUrl);
      final activeUrl = _activeUrl;
      final activeCookies = _activeCookies;
      if (background &&
          activeUrl != null &&
          activeUrl != mediaAccessUrl &&
          activeCookies != null &&
          activeCookies.isValid &&
          // Do not restore if another family took the foreground mid-op.
          _activeFamily == family) {
        await _invokeApply(activeCookies, activeUrl);
      }
      return result;
    });
  }

  Future<Result<void>> _invokeApply(
    CloudFrontSignedCookies cookies,
    String mediaAccessUrl,
  ) async {
    final signatureKey = '${cookies.policy}|${cookies.signature}';
    if (_installedUrl == mediaAccessUrl &&
        _installedSignature == signatureKey) {
      StoryLogger.d(
        'CloudFront cookies already applied for $mediaAccessUrl (skipped)',
        tag: 'CloudFront',
      );
      return Result.success(null);
    }
    try {
      await _channel.invokeMethod<void>('applyCookies', {
        'policy': cookies.policy,
        'signature': cookies.signature,
        'keyPairId': cookies.keyPairId,
        'expires': cookies.expires,
        'mediaAccessUrl': mediaAccessUrl,
      });
      _installedUrl = mediaAccessUrl;
      _installedSignature = signatureKey;
      StoryLogger.d(
        'CloudFront cookies applied for $mediaAccessUrl',
        tag: 'CloudFront',
      );
      return Result.success(null);
    } catch (e, st) {
      StoryLogger.e(
        'applyCookies failed',
        error: e,
        stackTrace: st,
        tag: 'CloudFront',
      );
      return Result.failure(ApiError.unknown('applyCookies failed: $e'));
    }
  }

  /// Unsigned HLS still hits CloudFront. Leftover Policy/Signature cookies
  /// from a previous episode 403 harder than sending no cookies at all.
  Future<Result<void>> prepareUnsignedPlayback(
    String mediaAccessUrl, {
    CloudFrontCookieFamily family = CloudFrontCookieFamily.feed,
  }) {
    if (mediaAccessUrl.isEmpty) {
      return Future.value(Result.success(null));
    }
    StoryLogger.d(
      'prepare unsigned playback family=$family url=$mediaAccessUrl',
      tag: 'CloudFront',
    );
    markActiveResource(null, mediaAccessUrl, family: family);
    return _clearInstalledJar(mediaAccessUrl);
  }

  Future<Result<void>> clearCookies(String mediaAccessUrl) {
    if (mediaAccessUrl.isEmpty) {
      return Future.value(Result.success(null));
    }
    if (_activeUrl == mediaAccessUrl) {
      _activeCookies = null;
      _activeUrl = null;
      _activeFamily = null;
    }
    return _clearInstalledJar(mediaAccessUrl);
  }

  /// Native-clear CF cookies for [mediaAccessUrl]'s domain without dropping
  /// unsigned foreground ownership.
  Future<Result<void>> _clearInstalledJar(String mediaAccessUrl) {
    _installedUrl = null;
    _installedSignature = null;
    return _enqueue(() async {
      try {
        await _channel.invokeMethod<void>('clearCookies', {
          'mediaAccessUrl': mediaAccessUrl,
        });
        return Result.success(null);
      } catch (e, st) {
        StoryLogger.d(
          'clearCookies failed (best-effort)',
          error: e,
          stackTrace: st,
          tag: 'CloudFront',
        );
        return Result.failure(ApiError.unknown('clearCookies failed: $e'));
      }
    });
  }

  /// Runs [action] after any in-flight cookie mutation completes, keeping the
  /// shared native cookie store single-writer.
  ///
  /// Each op is wrapped in [_opTimeout] — a hung method channel call cannot
  /// block subsequent apply/clear ops forever (otherwise the whole feed
  /// laginfinitely waits on a single native freeze).
  Future<Result<void>> _enqueue(Future<Result<void>> Function() action) {
    final completer = Completer<Result<void>>();
    _cookieOp = _cookieOp.then((_) async {
      try {
        final result = await action().timeout(
          _opTimeout,
          onTimeout: () {
            StoryLogger.w(
              'CloudFront cookie op timed out after ${_opTimeout.inSeconds}s',
              tag: 'CloudFront',
            );
            StoryTelemetryRegistry.instance.event(
              'feed_cookie_op_timeout',
              properties: {
                'timeoutMs': _opTimeout.inMilliseconds,
              },
            );
            return Result.failure(
              ApiError.timeout('CloudFront cookie op timed out'),
            );
          },
        );
        completer.complete(result);
      } catch (e) {
        completer.complete(Result.failure(ApiError.unknown('$e')));
      }
    });
    return completer.future;
  }
}
