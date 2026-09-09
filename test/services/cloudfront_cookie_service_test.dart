import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/services/cloudfront_cookie_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.cestine.officeapp/cloudfront');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'background cookies restore the active resource after warming',
    () async {
      final activeCookies = CloudFrontSignedCookies(
        policy: 'active-policy',
        signature: 'active-signature',
        keyPairId: 'key',
        expires:
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      );
      final preloadCookies = CloudFrontSignedCookies(
        policy: 'preload-policy',
        signature: 'preload-signature',
        keyPairId: 'key',
        expires:
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      );
      const activeUrl = 'https://cdn.example.com/episode-1/master.m3u8';
      const preloadUrl = 'https://cdn.example.com/episode-2/master.m3u8';
      final service = CloudFrontCookieService.instance;

      expect(
        (await service.applyCookies(activeCookies, activeUrl)).isSuccess,
        isTrue,
      );
      calls.clear();

      expect(
        (await service.applyCookies(
          preloadCookies,
          preloadUrl,
          background: true,
        )).isSuccess,
        isTrue,
      );

      expect(
        calls
            .where((call) => call.method == 'applyCookies')
            .map(
              (call) =>
                  (call.arguments as Map<Object?, Object?>)['mediaAccessUrl'],
            ),
        <String>[preloadUrl, activeUrl],
      );

      expect(service.isInstalled(activeUrl, activeCookies), isTrue);
      expect(service.isInstalled(preloadUrl, preloadCookies), isFalse);

      await service.clearCookies(activeUrl);
      await service.clearCookies(preloadUrl);
    },
  );

  test('isInstalled matches last installed url and signature', () async {
    final cookies = CloudFrontSignedCookies(
      policy: 'p',
      signature: 's',
      keyPairId: 'k',
      expires:
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000,
    );
    const url = 'https://cdn.example.com/ep.m3u8';
    final service = CloudFrontCookieService.instance;

    expect(service.isInstalled(url, cookies), isFalse);
    expect((await service.applyCookies(cookies, url)).isSuccess, isTrue);
    expect(service.isInstalled(url, cookies), isTrue);
    expect(
      service.isInstalled(
        url,
        CloudFrontSignedCookies(
          policy: 'other',
          signature: 's',
          keyPairId: 'k',
          expires: cookies.expires,
        ),
      ),
      isFalse,
    );
    await service.clearCookies(url);
  });

  test('background apply does not markActiveResource', () async {
    final activeCookies = CloudFrontSignedCookies(
      policy: 'active-policy',
      signature: 'active-signature',
      keyPairId: 'key',
      expires:
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000,
    );
    final firstWarm = CloudFrontSignedCookies(
      policy: 'warm-1',
      signature: 'warm-1-sig',
      keyPairId: 'key',
      expires: activeCookies.expires,
    );
    final secondWarm = CloudFrontSignedCookies(
      policy: 'warm-2',
      signature: 'warm-2-sig',
      keyPairId: 'key',
      expires: activeCookies.expires,
    );
    const activeUrl = 'https://cdn.example.com/playing.m3u8';
    const warmUrlA = 'https://cdn.example.com/warm-a.m3u8';
    const warmUrlB = 'https://cdn.example.com/warm-b.m3u8';
    final service = CloudFrontCookieService.instance;

    expect(
      (await service.applyCookies(activeCookies, activeUrl)).isSuccess,
      isTrue,
    );

    expect(
      (await service.applyCookies(
        firstWarm,
        warmUrlA,
        background: true,
      )).isSuccess,
      isTrue,
    );
    expect(
      (await service.applyCookies(
        secondWarm,
        warmUrlB,
        background: true,
      )).isSuccess,
      isTrue,
    );

    // If either warm had stolen foreground ownership, the second restore
    // would leave warm-a or warm-b installed instead of the playing URL.
    expect(service.isInstalled(activeUrl, activeCookies), isTrue);
    expect(service.isInstalled(warmUrlA, firstWarm), isFalse);
    expect(service.isInstalled(warmUrlB, secondWarm), isFalse);
    expect(service.activeFamily, CloudFrontCookieFamily.feed);

    await service.clearCookies(activeUrl);
    await service.clearCookies(warmUrlA);
    await service.clearCookies(warmUrlB);
  });

  test('cross-family background apply skips jar mutation', () async {
    final feedCookies = CloudFrontSignedCookies(
      policy: 'feed-policy',
      signature: 'feed-signature',
      keyPairId: 'key',
      expires:
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000,
    );
    final recommendCookies = CloudFrontSignedCookies(
      policy: 'rec-policy',
      signature: 'rec-signature',
      keyPairId: 'key',
      expires: feedCookies.expires,
    );
    const feedUrl = 'https://cdn.example.com/feed.m3u8';
    const recommendUrl = 'https://cdn.example.com/rec.m3u8';
    final service = CloudFrontCookieService.instance;

    expect(
      (await service.applyCookies(feedCookies, feedUrl)).isSuccess,
      isTrue,
    );
    calls.clear();

    expect(
      (await service.applyCookies(
        recommendCookies,
        recommendUrl,
        background: true,
        family: CloudFrontCookieFamily.recommend,
      )).isSuccess,
      isTrue,
    );
    expect(calls, isEmpty);
    expect(service.isInstalled(feedUrl, feedCookies), isTrue);
    expect(service.activeFamily, CloudFrontCookieFamily.feed);

    service.releaseActiveFamily(CloudFrontCookieFamily.feed);
    expect(service.activeFamily, isNull);

    await service.clearCookies(feedUrl);
  });

  test(
    'unsigned foreground clears leftover cookies and blocks background apply',
    () async {
      final leftover = CloudFrontSignedCookies(
        policy: 'old-policy',
        signature: 'old-signature',
        keyPairId: 'key',
        expires:
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      );
      final neighbor = CloudFrontSignedCookies(
        policy: 'neighbor-policy',
        signature: 'neighbor-signature',
        keyPairId: 'key',
        expires: leftover.expires,
      );
      const leftoverUrl = 'https://cdn.example.com/old.m3u8';
      const unsignedUrl = 'https://cdn.example.com/open.m3u8';
      const neighborUrl = 'https://cdn.example.com/neighbor.m3u8';
      final service = CloudFrontCookieService.instance;

      expect(
        (await service.applyCookies(leftover, leftoverUrl)).isSuccess,
        isTrue,
      );
      calls.clear();

      expect(
        (await service.prepareUnsignedPlayback(
          unsignedUrl,
          family: CloudFrontCookieFamily.recommend,
        )).isSuccess,
        isTrue,
      );
      expect(service.hasUnsignedForeground, isTrue);
      expect(service.activeFamily, CloudFrontCookieFamily.recommend);
      expect(calls.where((call) => call.method == 'clearCookies'), isNotEmpty);
      calls.clear();

      expect(
        (await service.applyCookies(
          neighbor,
          neighborUrl,
          background: true,
          family: CloudFrontCookieFamily.recommend,
        )).isSuccess,
        isTrue,
      );
      expect(calls, isEmpty);
      expect(service.hasUnsignedForeground, isTrue);

      service.releaseActiveFamily(CloudFrontCookieFamily.recommend);
      expect(service.hasUnsignedForeground, isFalse);
    },
  );

  test(
    'unsigned playback still native-clears when Dart jar state is empty',
    () async {
      const unsignedUrl = 'https://cdn.example.com/open.m3u8';
      final service = CloudFrontCookieService.instance;
      service.releaseActiveFamily(CloudFrontCookieFamily.feed);
      service.releaseActiveFamily(CloudFrontCookieFamily.recommend);
      calls.clear();

      expect(
        (await service.prepareUnsignedPlayback(
          unsignedUrl,
          family: CloudFrontCookieFamily.recommend,
        )).isSuccess,
        isTrue,
      );
      expect(service.hasUnsignedForeground, isTrue);
      expect(calls.where((call) => call.method == 'clearCookies'), isNotEmpty);

      service.releaseActiveFamily(CloudFrontCookieFamily.recommend);
    },
  );
}
