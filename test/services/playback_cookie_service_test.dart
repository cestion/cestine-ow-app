import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/services/cloudfront_cookie_service.dart';
import 'package:story_app/src/services/playback_cookie_service.dart';

class MockCloudFrontCookieService extends Mock
    implements CloudFrontCookieService {}

class MockDramaRepository extends Mock implements DramaRepository {}

void main() {
  late MockCloudFrontCookieService mockCloudfront;
  late MockDramaRepository mockDramaRepo;

  setUpAll(() {
    registerFallbackValue(CloudFrontCookieFamily.feed);
    registerFallbackValue(const CloudFrontSignedCookies());
  });

  setUp(() {
    mockCloudfront = MockCloudFrontCookieService();
    mockDramaRepo = MockDramaRepository();
    PlaybackCookieService.resetRefreshThrottle();
  });

  tearDown(() {
    reset(mockCloudfront);
    reset(mockDramaRepo);
  });

  // ── Helpers ──────────────────────────────────────────────────

  CloudFrontSignedCookies makeCookies({
    String policy = 'policy',
    String signature = 'sig',
    String keyPairId = 'key',
    int? expires,
  }) {
    return CloudFrontSignedCookies(
      policy: policy,
      signature: signature,
      keyPairId: keyPairId,
      expires:
          expires ??
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
    );
  }

  DramaPlayResponse makePlay({
    String url = 'https://cdn.example.com/ep.m3u8',
    CloudFrontSignedCookies? signedCookies,
  }) {
    return DramaPlayResponse(
      mediaAccessUrl: url,
      signedCookies: signedCookies,
    );
  }

  // ── applyCookiesIfNeeded ─────────────────────────────────────

  group('applyCookiesIfNeeded', () {
    test('calls prepareUnsignedPlayback and returns true when unsigned',
        () async {
      when(
        () => mockCloudfront.prepareUnsignedPlayback(
          any(),
          family: any(named: 'family'),
        ),
      ).thenAnswer((_) async => Result.success(null));

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.applyCookiesIfNeeded(
        makePlay(),
        'https://cdn.example.com/ep.m3u8',
      );

      expect(result, isTrue);
      verify(
        () => mockCloudfront.prepareUnsignedPlayback(
          'https://cdn.example.com/ep.m3u8',
        ),
      ).called(1);
    });

    test('returns true even when prepareUnsignedPlayback fails', () async {
      when(
        () => mockCloudfront.prepareUnsignedPlayback(
          any(),
          family: any(named: 'family'),
        ),
      ).thenAnswer(
        (_) async => Result.failure(ApiError.unknown('clearCookies failed')),
      );

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.applyCookiesIfNeeded(
        makePlay(),
        'https://cdn.example.com/ep.m3u8',
      );

      expect(result, isTrue); // Must not block unsigned play
    });

    test('skips prepareUnsignedPlayback for background path', () async {
      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.applyCookiesIfNeeded(
        makePlay(),
        'https://cdn.example.com/ep.m3u8',
        background: true,
      );

      expect(result, isTrue);
      verifyNever(
        () => mockCloudfront.prepareUnsignedPlayback(
          any(),
          family: any(named: 'family'),
        ),
      );
    });

    test('calls applyCookies for signed play', () async {
      final cookies = makeCookies();
      when(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: any(named: 'background'),
          family: any(named: 'family'),
        ),
      ).thenAnswer((_) async => Result.success(null));

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.applyCookiesIfNeeded(
        makePlay(signedCookies: cookies),
        'https://cdn.example.com/ep.m3u8',
      );

      expect(result, isTrue);
      verify(
        () => mockCloudfront.applyCookies(
          cookies,
          'https://cdn.example.com/ep.m3u8',
        ),
      ).called(1);
    });

    test('returns false when applyCookies fails for signed play', () async {
      when(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: any(named: 'background'),
          family: any(named: 'family'),
        ),
      ).thenAnswer(
        (_) async => Result.failure(ApiError.unknown('apply failed')),
      );

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.applyCookiesIfNeeded(
        makePlay(signedCookies: makeCookies()),
        'https://cdn.example.com/ep.m3u8',
      );

      expect(result, isFalse);
      verify(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: any(named: 'background'),
          family: any(named: 'family'),
        ),
      ).called(1);
    });

    test('retries once after timeout then succeeds', () async {
      var calls = 0;
      when(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: any(named: 'background'),
          family: any(named: 'family'),
        ),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          return Result.failure(ApiError.timeout('CloudFront cookie op timed out'));
        }
        return Result.success(null);
      });

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.applyCookiesIfNeeded(
        makePlay(signedCookies: makeCookies()),
        'https://cdn.example.com/ep.m3u8',
      );

      expect(result, isTrue);
      expect(calls, 2);
    });

    test('does not retry timeout on background path', () async {
      when(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: any(named: 'background'),
          family: any(named: 'family'),
        ),
      ).thenAnswer(
        (_) async =>
            Result.failure(ApiError.timeout('CloudFront cookie op timed out')),
      );

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.applyCookiesIfNeeded(
        makePlay(signedCookies: makeCookies()),
        'https://cdn.example.com/ep.m3u8',
        background: true,
      );

      expect(result, isFalse);
      verify(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: any(named: 'background'),
          family: any(named: 'family'),
        ),
      ).called(1);
    });

    test('passes background flag to applyCookies', () async {
      when(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: any(named: 'background'),
          family: any(named: 'family'),
        ),
      ).thenAnswer((_) async => Result.success(null));

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      await svc.applyCookiesIfNeeded(
        makePlay(signedCookies: makeCookies()),
        'https://cdn.example.com/ep.m3u8',
        background: true,
      );

      verify(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: true,
          family: any(named: 'family'),
        ),
      ).called(1);
    });
  });

  // ── promotePreloadedResource ─────────────────────────────────

  group('promotePreloadedResource', () {
    test('returns false when disposed', () async {
      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      )..disposed = true;

      final result = await svc.promotePreloadedResource(makePlay());
      expect(result, isFalse);
    });

    test('returns false when play is null', () async {
      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.promotePreloadedResource(null);
      expect(result, isFalse);
    });

    test('returns false when effectivePlayUrl is empty', () async {
      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.promotePreloadedResource(
        const DramaPlayResponse(),
      );
      expect(result, isFalse);
    });

    test('calls prepareUnsignedPlayback for unsigned play', () async {
      when(
        () => mockCloudfront.prepareUnsignedPlayback(
          any(),
          family: any(named: 'family'),
        ),
      ).thenAnswer((_) async => Result.success(null));

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.promotePreloadedResource(makePlay());
      expect(result, isTrue);
      verify(
        () => mockCloudfront.prepareUnsignedPlayback(
          any(),
          family: any(named: 'family'),
        ),
      ).called(1);
    });

    test('returns true when prepareUnsignedPlayback fails', () async {
      when(
        () => mockCloudfront.prepareUnsignedPlayback(
          any(),
          family: any(named: 'family'),
        ),
      ).thenAnswer(
        (_) async => Result.failure(ApiError.unknown('fail')),
      );

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.promotePreloadedResource(makePlay());
      expect(result, isTrue);
    });

    test('skips native call when already installed', () async {
      final cookies = makeCookies();
      const url = 'https://cdn.example.com/ep.m3u8';
      when(() => mockCloudfront.isInstalled(url, cookies)).thenReturn(true);

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.promotePreloadedResource(
        makePlay(signedCookies: cookies),
      );

      expect(result, isTrue);
      verifyNever(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: any(named: 'background'),
          family: any(named: 'family'),
        ),
      );
      verify(
        () => mockCloudfront.markActiveResource(
          cookies,
          url,
        ),
      );
    });

    test('delegates to applyCookies when not installed', () async {
      final cookies = makeCookies();
      const url = 'https://cdn.example.com/ep.m3u8';
      when(() => mockCloudfront.isInstalled(url, cookies)).thenReturn(false);
      when(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: any(named: 'background'),
          family: any(named: 'family'),
        ),
      ).thenAnswer((_) async => Result.success(null));

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.promotePreloadedResource(
        makePlay(signedCookies: cookies),
      );

      expect(result, isTrue);
      verify(
        () => mockCloudfront.applyCookies(
          cookies,
          url,
        ),
      ).called(1);
    });
  });

  // ── refreshCookiesIfNearExpiry ───────────────────────────────

  group('refreshCookiesIfNearExpiry', () {
    test('returns null when disposed', () async {
      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.refreshCookiesIfNearExpiry(
        episodeNo: 1,
        play: makePlay(signedCookies: makeCookies()),
        isDisposed: true,
      );

      expect(result, isNull);
    });

    test('returns null when play is null', () async {
      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.refreshCookiesIfNearExpiry(
        episodeNo: 1,
        play: null,
        isDisposed: false,
      );

      expect(result, isNull);
    });

    test('returns null when episodeNo is null', () async {
      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.refreshCookiesIfNearExpiry(
        episodeNo: null,
        play: makePlay(signedCookies: makeCookies()),
        isDisposed: false,
      );

      expect(result, isNull);
    });

    test('returns null when cookies are not near expiry', () async {
      final cookies = makeCookies(
        expires:
            DateTime.now()
                .add(const Duration(minutes: 30))
                .millisecondsSinceEpoch ~/
            1000,
      );

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.refreshCookiesIfNearExpiry(
        episodeNo: 1,
        play: makePlay(signedCookies: cookies),
        isDisposed: false,
      );

      expect(result, isNull);
    });

    test('fetches fresh play and applies when cookies near expiry', () async {
      final nearExpiry = makeCookies(
        expires:
            DateTime.now()
                .add(const Duration(minutes: 3))
                .millisecondsSinceEpoch ~/
            1000,
      );
      final freshCookies = makeCookies(
        policy: 'fresh-policy',
        signature: 'fresh-sig',
      );
      final freshPlay = makePlay(
        url: 'https://cdn.example.com/fresh.m3u8',
        signedCookies: freshCookies,
      );

      when(() => mockDramaRepo.getEpisodeDetail('d1', 1)).thenAnswer(
        (_) async => Result.success(freshPlay),
      );
      when(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: any(named: 'background'),
          family: any(named: 'family'),
        ),
      ).thenAnswer((_) async => Result.success(null));

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.refreshCookiesIfNearExpiry(
        episodeNo: 1,
        play: makePlay(signedCookies: nearExpiry),
        isDisposed: false,
      );

      expect(result, isNotNull);
      expect(result!.effectivePlayUrl, 'https://cdn.example.com/fresh.m3u8');
      verify(() => mockDramaRepo.getEpisodeDetail('d1', 1)).called(1);
    });

    test('returns null when repo fetch fails', () async {
      final nearExpiry = makeCookies(
        expires:
            DateTime.now()
                .add(const Duration(minutes: 3))
                .millisecondsSinceEpoch ~/
            1000,
      );

      when(() => mockDramaRepo.getEpisodeDetail('d1', 1)).thenAnswer(
        (_) async => Result.failure(ApiError.network('timeout')),
      );

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.refreshCookiesIfNearExpiry(
        episodeNo: 1,
        play: makePlay(signedCookies: nearExpiry),
        isDisposed: false,
      );

      expect(result, isNull);
    });

    test('returns null when applyCookies fails after refresh', () async {
      final nearExpiry = makeCookies(
        expires:
            DateTime.now()
                .add(const Duration(minutes: 3))
                .millisecondsSinceEpoch ~/
            1000,
      );
      final freshPlay = makePlay(signedCookies: makeCookies());

      when(() => mockDramaRepo.getEpisodeDetail('d1', 1)).thenAnswer(
        (_) async => Result.success(freshPlay),
      );
      when(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: any(named: 'background'),
          family: any(named: 'family'),
        ),
      ).thenAnswer(
        (_) async => Result.failure(ApiError.unknown('apply failed')),
      );

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      final result = await svc.refreshCookiesIfNearExpiry(
        episodeNo: 1,
        play: makePlay(signedCookies: nearExpiry),
        isDisposed: false,
      );

      expect(result, isNull);
    });

    test('uses custom episodeLoader when provided', () async {
      final nearExpiry = makeCookies(
        expires:
            DateTime.now()
                .add(const Duration(minutes: 3))
                .millisecondsSinceEpoch ~/
            1000,
      );
      final freshPlay = makePlay(signedCookies: makeCookies());
      Future<Result<DramaPlayResponse>> loader(int episodeNo) async =>
          Result.success(freshPlay);

      when(
        () => mockCloudfront.applyCookies(
          any(),
          any(),
          background: any(named: 'background'),
          family: any(named: 'family'),
        ),
      ).thenAnswer((_) async => Result.success(null));

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
        episodeLoader: loader,
      );

      final result = await svc.refreshCookiesIfNearExpiry(
        episodeNo: 2,
        play: makePlay(signedCookies: nearExpiry),
        isDisposed: false,
      );

      expect(result, isNotNull);
      verifyNever(() => mockDramaRepo.getEpisodeDetail(any(), any()));
    });
  });

  // ── clearCookies ─────────────────────────────────────────────

  group('clearCookies', () {
    test('delegates to cloudfront.clearCookies', () async {
      when(
        () => mockCloudfront.clearCookies(any()),
      ).thenAnswer((_) async => Result.success(null));

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      await svc.clearCookies('https://cdn.example.com/ep.m3u8');

      verify(
        () => mockCloudfront.clearCookies('https://cdn.example.com/ep.m3u8'),
      ).called(1);
    });
  });

  // ── rebindDrama / rebindFamily / releaseActiveFamily ─────────

  group('lifecycle', () {
    test('releaseActiveFamily delegates to cloudfront', () {
      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );

      svc.releaseActiveFamily();

      verify(
        () => mockCloudfront.releaseActiveFamily(CloudFrontCookieFamily.feed),
      );
    });

    test('rebindDrama does not throw', () {
      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );
      svc.rebindDrama('d2');
      expect(svc.disposed, isFalse);
    });

    test('rebindFamily changes family for cookie operations', () async {
      when(
        () => mockCloudfront.prepareUnsignedPlayback(
          any(),
          family: any(named: 'family'),
        ),
      ).thenAnswer((_) async => Result.success(null));

      final svc = PlaybackCookieService(
        cloudfront: mockCloudfront,
        dramaRepo: mockDramaRepo,
        dramaId: 'd1',
      );
      svc.rebindFamily(CloudFrontCookieFamily.recommend);

      await svc.applyCookiesIfNeeded(
        makePlay(),
        'https://cdn.example.com/ep.m3u8',
      );

      verify(
        () => mockCloudfront.prepareUnsignedPlayback(
          any(),
          family: CloudFrontCookieFamily.recommend,
        ),
      );
    });
  });
}
