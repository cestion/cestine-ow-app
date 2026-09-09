import 'dart:io';

import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/foundation/hive_mixin.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/repositories/drama_repository.dart';

/// Manual test double for StoryApiClient that records calls and returns
/// pre-configured results. Avoids mocktail generic resolution issues.
class FakeApiClient extends StoryApiClient {
  final Map<String, dynamic> _stubs = {};
  int safeGetCallCount = 0;
  String? lastGetPath;
  Map<String, dynamic>? lastGetQuery;

  FakeApiClient() : super(baseUrl: 'https://test.api/') {
    // no-op override: skip the real HTTP client
  }

  void stubGet<T>(String path, Result<T> result) {
    // Use path prefix matching — store by path if exact, or use '*' as default
    _stubs[path] = result;
  }

  @override
  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async {
    safeGetCallCount++;
    lastGetPath = path;
    lastGetQuery = query;
    // Return matching stub or default failure
    final stub = _stubs[path] ?? _stubs['*'];
    if (stub != null) return stub as Result<T>;
    return Result<T>.failure(ApiError.network('unexpected call: $path'));
  }

  int safePostCallCount = 0;
  String? lastPostPath;
  dynamic lastPostBody;

  void stubPost<T>(String path, Result<T> result) {
    _stubs[path] = result;
  }

  @override
  Future<Result<T>> safePost<T>(
    String path, {
    dynamic body,
    required T Function(dynamic data) decoder,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool retry = false,
  }) async {
    safePostCallCount++;
    lastPostPath = path;
    lastPostBody = body;
    final stub = _stubs[path] ?? _stubs['*'];
    if (stub != null) return stub as Result<T>;
    return Result<T>.failure(ApiError.network('unexpected call: $path'));
  }

  int safeDeleteCallCount = 0;
  String? lastDeletePath;

  void stubDelete<T>(String path, Result<T> result) {
    _stubs[path] = result;
  }

  @override
  Future<Result<T>> safeDelete<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) decoder,
  }) async {
    safeDeleteCallCount++;
    lastDeletePath = path;
    final stub = _stubs[path] ?? _stubs['*'];
    if (stub != null) return stub as Result<T>;
    return Result<T>.failure(ApiError.network('unexpected call: $path'));
  }

  int safePutCallCount = 0;
  String? lastPutPath;
  dynamic lastPutBody;

  void stubPut<T>(String path, Result<T> result) {
    _stubs[path] = result;
  }

  @override
  Future<Result<T>> safePut<T>(
    String path, {
    dynamic body,
    required T Function(dynamic data) decoder,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool retry = false,
  }) async {
    safePutCallCount++;
    lastPutPath = path;
    lastPutBody = body;
    final stub = _stubs[path] ?? _stubs['*'];
    if (stub != null) return stub as Result<T>;
    return Result<T>.failure(ApiError.network('unexpected call: $path'));
  }
}

class FakeLocalRepo extends StoryLocalRepository with HiveMixin<dynamic> {
  @override
  String get boxName => 'drama_repository_test_cache';

  @override
  Box<dynamic> get cacheBox => box;

  @override
  Future<void> init() => initBox();

  @override
  Future<bool> reconcileEnv(String apiBaseUrl) async => false;

  @override
  Future<bool> reconcileSandboxInstall() async => false;

  // Unused stubs
  @override
  String? getToken() => null;
  @override
  String? get cachedToken => null;
  @override
  Future<String?> getTokenAsync() async => null;
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> clearToken() async {}
  @override
  UserProfile? getUser() => null;
  @override
  Future<void> saveUser(UserProfile user) async {}
  @override
  Future<void> clearUser() async {}
  @override
  List<String> getWatchlist() => [];
  @override
  Future<void> addToWatchlist(String dramaId) async {}
  @override
  Future<void> removeFromWatchlist(String dramaId) async {}
  @override
  Future<bool> toggleWatchlist(String dramaId) async => false;
  @override
  bool isFavorite(String dramaId) => false;
  @override
  List<String> getSearchHistory() => [];
  @override
  Future<void> addSearchHistory(String keyword) async {}
  @override
  Future<void> removeSearchHistory(String keyword) async {}
  @override
  Future<void> clearSearchHistory() async {}
  @override
  int getWatchProgress(String dramaId, int episodeNo) => 0;
  @override
  Future<void> saveWatchProgress(
    String dramaId,
    int episodeNo,
    int milliseconds,
  ) async {}
  @override
  Future<void> clearWatchProgress(String dramaId, int episodeNo) async {}
  @override
  String? getSolanaWalletAddress() => null;
  @override
  Future<String?> getSolanaWalletAddressAsync() async => null;
  @override
  Future<void> saveSolanaWalletAddress(String address) async {}
  @override
  Future<void> clearSolanaWalletAddress() async {}
  @override
  String? getEthereumWalletAddress() => null;
  @override
  Future<String?> getEthereumWalletAddressAsync() async => null;
  @override
  Future<void> saveEthereumWalletAddress(String address) async {}
  @override
  Future<void> clearEthereumWalletAddress() async {}
  @override
  LocaleInfo? getLocale() => null;
  @override
  Future<void> setLocale(LocaleInfo locale) async {}
  @override
  String getThemeMode() => 'system';
  @override
  Future<void> setThemeMode(String mode) async {}
  @override
  CreateDramaDraft? getCreateDramaDraft() => null;
  @override
  Future<void> saveCreateDramaDraft(CreateDramaDraft draft) async {}
  @override
  Future<void> clearCreateDramaDraft() async {}
  @override
  PublishVideoDraft? getPublishVideoDraft() => null;
  @override
  Future<void> savePublishVideoDraft(PublishVideoDraft draft) async {}
  @override
  Future<void> clearPublishVideoDraft() async {}
  @override
  Future<void> vacuumCache() async {}
  @override
  Future<void> purgeApiCache() async {}
  @override
  Future<void> dispose() => disposeBox();

  // New watch-history methods required by the abstract interface.
  @override
  List<String> getWatchHistoryDramaIds() => [];
  @override
  int? getLastWatchedEpisode(String dramaId) => null;
  @override
  Future<void> clearAllWatchProgress(String dramaId) async {}
  @override
  Future<int> getCacheFileSize() async => 0;
}

void main() {
  late FakeApiClient api;
  late FakeLocalRepo local;
  late DramaRepositoryImpl repo;

  setUpAll(() async {
    Hive.init('${Directory.systemTemp.path}/story_app_drama_repository_test');
  });

  setUp(() async {
    api = FakeApiClient();
    local = FakeLocalRepo();
    await local.init();
    await local.cacheBox.clear();
    repo = DramaRepositoryImpl(api, local);
  });

  tearDown(() async {
    await repo.dispose();
    await local.dispose();
  });

  group('DramaRepositoryImpl', () {
    group('getDetail', () {
      test('returns cached detail from local repo', () async {
        await local.cacheBox.put('drama_detail_drama-1_zh', <dynamic, dynamic>{
          'data': const DramaDetail(
            id: 'drama-1',
            title: 'Cached',
            tags: [],
          ).toJson(),
          'expiresAt': DateTime.now()
              .add(const Duration(minutes: 10))
              .millisecondsSinceEpoch,
        });

        final result = await repo.getDetail('drama-1');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.id, 'drama-1');
        expect(api.safeGetCallCount, 0);
      });

      test('fetches from API on cache miss and writes through', () async {
        api.stubGet(
          '*',
          Result.success(
            const DramaDetail(id: 'drama-2', title: 'API Drama', tags: []),
          ),
        );

        final result = await repo.getDetail('drama-2');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.id, 'drama-2');
        expect(local.cacheBox.containsKey('drama_detail_drama-2_zh'), isTrue);
      });
    });

    group('getEpisodeDetail', () {
      test('prefetches episode and returns from prefetch cache', () async {
        api.stubGet(
          '*',
          Result.success(
            const DramaPlayResponse(
              episodeId: 'ep-1',
              mediaAccessUrl: 'https://cdn.example.com/ep1.m3u8',
            ),
          ),
        );

        await repo.prefetchEpisode('drama-1', 1);

        final result = await repo.getEpisodeDetail('drama-1', 1);

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.episodeId, 'ep-1');
        // API called once by prefetch, not by getEpisodeDetail
        expect(api.safeGetCallCount, 1);
      });

      test('peekPrefetchedEpisode reads without consuming', () async {
        api.stubGet(
          '*',
          Result.success(
            const DramaPlayResponse(
              episodeId: 'ep-peek',
              mediaAccessUrl: 'https://cdn.example.com/peek.m3u8',
            ),
          ),
        );

        await repo.prefetchEpisode('drama-1', 3);
        final peeked = await repo.peekPrefetchedEpisode('drama-1', 3);
        expect(peeked?.episodeId, 'ep-peek');

        final result = await repo.getEpisodeDetail('drama-1', 3);
        expect(result.isSuccess, true);
        expect(result.dataOrNull?.episodeId, 'ep-peek');
      });

      test('falls back to Hive cache when prefetch misses', () async {
        api.stubGet(
          '*',
          Result<DramaPlayResponse>.failure(
            ApiError.network('should not be called'),
          ),
        );
        await local.cacheBox.put(
          'episode_play_drama-1_2_zh',
          <dynamic, dynamic>{
            'data': {
              'episodeId': 'ep-2',
              'mediaAccessUrl': 'https://cdn.example.com/ep2.m3u8',
            },
            'expiresAt': DateTime.now()
                .add(const Duration(minutes: 5))
                .millisecondsSinceEpoch,
          },
        );

        final result = await repo.getEpisodeDetail('drama-1', 2);

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.episodeId, 'ep-2');
      });

      test('calls network when all caches miss', () async {
        api.stubGet(
          '*',
          Result.success(
            const DramaPlayResponse(
              episodeId: 'ep-3',
              mediaAccessUrl: 'https://cdn.example.com/ep3.m3u8',
            ),
          ),
        );

        final result = await repo.getEpisodeDetail('drama-1', 3);

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.episodeId, 'ep-3');
        expect(api.safeGetCallCount, 1);
        expect(local.cacheBox.containsKey('episode_play_drama-1_3_zh'), isTrue);
      });

      test('negatively caches transcode-failed plays for 10 minutes', () async {
        api.stubGet(
          '*',
          Result<DramaPlayResponse>.failure(
            const BusinessError(121019, '剧集转码失败'),
          ),
        );

        final first = await repo.getEpisodeDetail('drama-fail', 1);
        expect(first.isFailure, true);
        expect((first.errorOrNull as BusinessError).code, 121019);
        expect(api.safeGetCallCount, 1);

        final second = await repo.getEpisodeDetail('drama-fail', 1);
        expect(second.isFailure, true);
        expect((second.errorOrNull as BusinessError).code, 121019);
        expect(api.safeGetCallCount, 1);

        await repo.prefetchEpisode('drama-fail', 1);
        expect(api.safeGetCallCount, 1);

        final refreshed = await repo.getEpisodeDetail(
          'drama-fail',
          1,
          forceRefresh: true,
        );
        expect(refreshed.isFailure, true);
        expect(api.safeGetCallCount, 2);
      });

      test('refetches unsigned CloudFront Hive hits once per process', () async {
        const unsignedUrl =
            'https://video.actqa.com/mini-drama/streaming/hls/1/episode/1/1_hls.m3u8';
        await local.cacheBox.put(
          'episode_play_drama-cf_1_zh',
          <dynamic, dynamic>{
            'data': {'episodeId': 'ep-unsigned', 'mediaAccessUrl': unsignedUrl},
            'expiresAt': DateTime.now()
                .add(const Duration(hours: 24))
                .millisecondsSinceEpoch,
          },
        );
        final expires =
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000;
        api.stubGet(
          '*',
          Result.success(
            DramaPlayResponse(
              episodeId: 'ep-signed',
              mediaAccessUrl: unsignedUrl,
              signedCookies: CloudFrontSignedCookies(
                policy: 'pol',
                signature: 'sig',
                keyPairId: 'kid',
                expires: expires,
              ),
            ),
          ),
        );

        final first = await repo.getEpisodeDetail('drama-cf', 1);
        expect(first.dataOrNull?.episodeId, 'ep-signed');
        expect(first.dataOrNull?.hasUsableSignedCookies, isTrue);
        expect(api.safeGetCallCount, 1);

        final second = await repo.getEpisodeDetail('drama-cf', 1);
        expect(second.dataOrNull?.episodeId, 'ep-signed');
        expect(api.safeGetCallCount, 1);
      });

      test(
        'does not refetch unsigned CloudFront after network confirms',
        () async {
          const unsignedUrl =
              'https://video.actqa.com/mini-drama/streaming/hls/1/episode/1/1_hls.m3u8';
          api.stubGet(
            '*',
            Result.success(
              const DramaPlayResponse(
                episodeId: 'ep-still-unsigned',
                mediaAccessUrl: unsignedUrl,
              ),
            ),
          );

          final first = await repo.getEpisodeDetail('drama-cf2', 1);
          expect(first.dataOrNull?.isUnsignedProtectedPlay, isTrue);
          expect(api.safeGetCallCount, 1);

          final second = await repo.getEpisodeDetail('drama-cf2', 1);
          expect(second.dataOrNull?.episodeId, 'ep-still-unsigned');
          expect(api.safeGetCallCount, 1);
        },
      );
    });

    group('listPublic', () {
      test('returns cached first page when available', () async {
        // Cache key format: drama_list_public_first|{lang}|{tagId}|{sort}
        await local.cacheBox.put(
          'drama_list_public_first|zh||',
          <dynamic, dynamic>{
            'data': [
              const DramaListItem(id: 'd-1', dramaTitle: 'Cached').toJson(),
            ],
            'expiresAt': DateTime.now()
                .add(const Duration(minutes: 5))
                .millisecondsSinceEpoch,
          },
        );

        final result = await repo.listPublic();

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.list?.first.id, 'd-1');
        expect(api.safeGetCallCount, 0);
      });

      test('passes completed_view sort through cache fetcher', () async {
        api.stubGet(
          '*',
          Result.success(
            const PageDto(
              list: [DramaListItem(id: 'cv-1', dramaTitle: 'Completed')],
              hasMore: false,
            ),
          ),
        );

        final result = await repo.listPublic(
          tagId: '406604473409880074',
          sort: 'completed_view',
        );

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.list?.first.id, 'cv-1');
        expect(api.safeGetCallCount, 1);
        expect(api.lastGetQuery?['sort'], 'completed_view');
        expect(api.lastGetQuery?['tagId'], '406604473409880074');
      });

      test('fetches from API when no cache', () async {
        api.stubGet(
          '*',
          Result.success(
            const PageDto(
              list: [DramaListItem(id: 'api-d-1', dramaTitle: 'API')],
              hasMore: false,
            ),
          ),
        );

        final result = await repo.listPublic();

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.list?.first.id, 'api-d-1');
        expect(api.safeGetCallCount, 1);
      });
    });

    group('updateDramaEditRevision', () {
      test('uses the creator drama PUT endpoint with unchanged body', () async {
        const request = DramaEditRequest(
          uploadSessionId: '21',
          title: 'Updated title',
          description: 'Updated description',
          coverObjectKey: 'covers/updated.webp',
          tagIds: ['3', '5'],
        );
        api.stubPut(
          '/api/mini-drama/creator/dramas/drama-1',
          Result.success(
            const CreatorDrama(id: 'drama-1', title: 'Updated title'),
          ),
        );

        final result = await repo.updateDramaEditRevision('drama-1', request);

        expect(result.isSuccess, true);
        expect(api.safePutCallCount, 1);
        expect(api.safePostCallCount, 0);
        expect(api.lastPutPath, '/api/mini-drama/creator/dramas/drama-1');
        expect(api.lastPutBody, request.toJson());
      });
    });

    group('Reviews and Ratings', () {
      test('getReviews calls public endpoint and returns PageDto', () async {
        final mockList = [
          const DramaReview(
            id: 'rev-1',
            userId: 'u-1',
            dramaId: 'd-1',
            rating: 5,
            reviewText: 'Awesome!',
          ),
        ];
        api.stubGet(
          '/api/mini-drama/public/dramas/d-1/reviews',
          Result.success(PageDto(list: mockList, hasMore: false)),
        );

        final result = await repo.getReviews(dramaId: 'd-1');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.list?.first.id, 'rev-1');
        expect(result.dataOrNull?.list?.first.reviewText, 'Awesome!');
      });

      test('getMyReview calls user endpoint and returns DramaReview', () async {
        const mockReview = DramaReview(
          id: 'rev-1',
          userId: 'u-1',
          dramaId: 'd-1',
          rating: 4,
          reviewText: 'Good',
        );
        api.stubGet(
          '/api/mini-drama/user/dramas/d-1/my-review',
          Result.success(mockReview),
        );

        final result = await repo.getMyReview(dramaId: 'd-1');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.id, 'rev-1');
        expect(result.dataOrNull?.rating, 4);
      });

      test(
        'submitReview calls user post endpoint and returns submitted DramaReview',
        () async {
          const mockReview = DramaReview(
            id: 'rev-1',
            userId: 'u-1',
            dramaId: 'd-1',
            rating: 5,
            reviewText: 'Superb',
          );
          api.stubPost(
            '/api/mini-drama/user/dramas/d-1/reviews',
            Result.success(mockReview),
          );

          final result = await repo.submitReview(
            dramaId: 'd-1',
            rating: 5,
            reviewText: 'Superb',
          );

          expect(result.isSuccess, true);
          expect(result.dataOrNull?.id, 'rev-1');
          expect(result.dataOrNull?.reviewText, 'Superb');
        },
      );

      test('getReviewsWithMyReview merges results correctly', () async {
        final mockList = [
          const DramaReview(
            id: 'rev-1',
            userId: 'u-1',
            dramaId: 'd-1',
            rating: 5,
            reviewText: 'Awesome!',
          ),
        ];
        const mockReview = DramaReview(
          id: 'rev-my',
          userId: 'u-my',
          dramaId: 'd-1',
          rating: 3,
        );

        api.stubGet(
          '/api/mini-drama/public/dramas/d-1/reviews',
          Result.success(PageDto(list: mockList, hasMore: false)),
        );
        api.stubGet(
          '/api/mini-drama/user/dramas/d-1/my-review',
          Result.success(mockReview),
        );

        final result = await repo.getReviewsWithMyReview(dramaId: 'd-1');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.reviews.list?.first.id, 'rev-1');
        expect(result.dataOrNull?.myReview?.id, 'rev-my');
      });

      test(
        'getReviewsWithMyReview tolerates getMyReview failure (e.g. guest users)',
        () async {
          final mockList = [
            const DramaReview(
              id: 'rev-1',
              userId: 'u-1',
              dramaId: 'd-1',
              rating: 5,
            ),
          ];

          api.stubGet(
            '/api/mini-drama/public/dramas/d-1/reviews',
            Result.success(PageDto(list: mockList, hasMore: false)),
          );
          api.stubGet(
            '/api/mini-drama/user/dramas/d-1/my-review',
            Result<DramaReview?>.failure(ApiError.unauthorized('unauthorized')),
          );

          final result = await repo.getReviewsWithMyReview(dramaId: 'd-1');

          expect(result.isSuccess, true);
          expect(result.dataOrNull?.reviews.list?.first.id, 'rev-1');
          expect(result.dataOrNull?.myReview, isNull);
        },
      );
    });

    group('short-video action paths', () {
      test('toggleEpisodeLike posts /short-videos/{id}/like', () async {
        api.stubPost(
          '/api/mini-drama/user/short-videos/ep-1/like',
          Result<void>.success(null),
        );
        final result = await repo.toggleEpisodeLike(
          'd-1',
          'ep-1',
          type: WorkContentType.shortVideo,
        );
        expect(result.isSuccess, isTrue);
        expect(api.lastPostPath, '/api/mini-drama/user/short-videos/ep-1/like');
      });

      test('toggleFavorite posts /short-videos/{id}/favorite', () async {
        api.stubPost(
          '/api/mini-drama/user/short-videos/ep-1/favorite',
          Result<void>.success(null),
        );
        final result = await repo.toggleFavorite(
          'd-1',
          type: WorkContentType.shortVideo,
          episodeId: 'ep-1',
          target: FavoriteTarget.work,
        );
        expect(result.isSuccess, isTrue);
        expect(
          api.lastPostPath,
          '/api/mini-drama/user/short-videos/ep-1/favorite',
        );
      });

      test(
        'toggleFavorite work posts /dramas/episodes/{id}/favorite for short drama',
        () async {
          api.stubPost(
            '/api/mini-drama/user/dramas/episodes/ep-1/favorite',
            Result<void>.success(null),
          );
          final result = await repo.toggleFavorite(
            'd-1',
            episodeId: 'ep-1',
            target: FavoriteTarget.work,
          );
          expect(result.isSuccess, isTrue);
          expect(
            api.lastPostPath,
            '/api/mini-drama/user/dramas/episodes/ep-1/favorite',
          );
        },
      );

      test('toggleFavorite drama posts /dramas/{id}/favorite', () async {
        api.stubPost(
          '/api/mini-drama/user/dramas/d-1/favorite',
          Result<void>.success(null),
        );
        final result = await repo.toggleFavorite('d-1');
        expect(result.isSuccess, isTrue);
        expect(api.lastPostPath, '/api/mini-drama/user/dramas/d-1/favorite');
      });

      test('track play posts /short-videos/{id}/play', () async {
        api.stubPost(
          '/api/mini-drama/user/short-videos/ep-1/play',
          Result<void>.success(null),
        );
        final result = await repo.trackEpisode(
          'd-1',
          'ep-1',
          EpisodeTrackEvent.play,
          deviceId: 'dev',
          type: WorkContentType.shortVideo,
        );
        expect(result.isSuccess, isTrue);
        expect(api.lastPostPath, '/api/mini-drama/user/short-videos/ep-1/play');
      });

      test('track complete posts /short-videos/{id}/complete', () async {
        api.stubPost(
          '/api/mini-drama/user/short-videos/ep-1/complete',
          Result<void>.success(null),
        );
        final result = await repo.trackEpisode(
          'd-1',
          'ep-1',
          EpisodeTrackEvent.complete,
          deviceId: 'dev',
          type: WorkContentType.shortVideo,
        );
        expect(result.isSuccess, isTrue);
        expect(
          api.lastPostPath,
          '/api/mini-drama/user/short-videos/ep-1/complete',
        );
      });

      test('reportEpisode posts /ugc/works/{id}/report', () async {
        api.stubPost(
          '/api/mini-drama/user/ugc/works/ep-1/report',
          Result<void>.success(null),
        );
        final result = await repo.reportEpisode(
          dramaId: 'd-1',
          episodeId: 'ep-1',
          reportType: 'vulgar_content',
          type: WorkContentType.shortVideo,
        );
        expect(result.isSuccess, isTrue);
        expect(api.lastPostPath, '/api/mini-drama/user/ugc/works/ep-1/report');
      });

      test('drama episode report also posts /ugc/works/{id}/report', () async {
        api.stubPost(
          '/api/mini-drama/user/ugc/works/ep-1/report',
          Result<void>.success(null),
        );
        final result = await repo.reportEpisode(
          dramaId: 'd-1',
          episodeId: 'ep-1',
          reportType: 'vulgar_content',
        );
        expect(result.isSuccess, isTrue);
        expect(api.lastPostPath, '/api/mini-drama/user/ugc/works/ep-1/report');
      });

      test('reportDrama posts /ugc/dramas/{id}/report', () async {
        api.stubPost(
          '/api/mini-drama/user/ugc/dramas/d-1/report',
          Result<void>.success(null),
        );
        final result = await repo.reportDrama(
          dramaId: 'd-1',
          reportType: 'vulgar_content',
        );
        expect(result.isSuccess, isTrue);
        expect(api.lastPostPath, '/api/mini-drama/user/ugc/dramas/d-1/report');
      });

      test('drama like still posts the short-drama path', () async {
        api.stubPost(
          '/api/mini-drama/user/dramas/d-1/episodes/ep-1/like',
          Result<void>.success(null),
        );
        final result = await repo.toggleEpisodeLike('d-1', 'ep-1');
        expect(result.isSuccess, isTrue);
        expect(
          api.lastPostPath,
          '/api/mini-drama/user/dramas/d-1/episodes/ep-1/like',
        );
      });
    });

    group('works comments and ugc reports', () {
      test('getEpisodeComments gets /public/works/{id}/comments', () async {
        api.stubGet(
          '/api/mini-drama/public/works/ep-1/comments',
          Result.success(
            const PageDto<StoryComment>(
              list: [StoryComment(commentId: 'c1', content: 'hi')],
              mark: '-1',
              hasMore: false,
            ),
          ),
        );
        final result = await repo.getEpisodeComments('ep-1');
        expect(result.isSuccess, isTrue);
        expect(api.lastGetPath, '/api/mini-drama/public/works/ep-1/comments');
      });

      test(
        'postEpisodeComment posts /user/works/{id}/comments with content',
        () async {
          api.stubPost(
            '/api/mini-drama/user/works/ep-1/comments',
            Result.success(const StoryComment(commentId: 'c1', content: 'hi')),
          );
          final result = await repo.postEpisodeComment('ep-1', 'hi');
          expect(result.isSuccess, isTrue);
          expect(api.lastPostPath, '/api/mini-drama/user/works/ep-1/comments');
          expect(api.lastPostBody, {'content': 'hi'});
        },
      );

      test('toggleCommentLike posts /user/comments/{id}/like', () async {
        api.stubPost(
          '/api/mini-drama/user/comments/c-1/like',
          Result<void>.success(null),
        );
        final result = await repo.toggleCommentLike('c-1', liked: true);
        expect(result.isSuccess, isTrue);
        expect(api.lastPostPath, '/api/mini-drama/user/comments/c-1/like');
      });

      test('toggleCommentLike deletes /user/comments/{id}/like', () async {
        api.stubDelete(
          '/api/mini-drama/user/comments/c-1/like',
          Result<void>.success(null),
        );
        final result = await repo.toggleCommentLike('c-1', liked: false);
        expect(result.isSuccess, isTrue);
        expect(api.lastDeletePath, '/api/mini-drama/user/comments/c-1/like');
      });

      test('getReportTypes gets /public/ugc/report-types', () async {
        api.stubGet(
          '/api/mini-drama/public/ugc/report-types',
          Result.success([
            const ReportTypeItem(id: '1', code: 'vulgar_content', name: '低俗色情'),
          ]),
        );
        final result = await repo.getReportTypes(scope: UgcReportScope.work);
        expect(result.isSuccess, isTrue);
        expect(api.lastGetPath, '/api/mini-drama/public/ugc/report-types');
        expect(api.lastGetQuery, {'scope': 'WORK'});
      });
    });

    test('listEpisodes gets /public/dramas/{id}/episodes', () async {
      api.stubGet(
        '/api/mini-drama/public/dramas/d-1/episodes',
        Result.success(
          const PageDto(
            list: [
              DramaEpisodeListItem(
                episodeId: 'ep-1',
                episodeNo: 1,
                title: '第1集',
                likeCount: 678,
              ),
            ],
            hasMore: false,
          ),
        ),
      );

      final result = await repo.listEpisodes('d-1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.list?.single.episodeId, 'ep-1');
      expect(api.lastGetPath, '/api/mini-drama/public/dramas/d-1/episodes');
      expect(api.lastGetQuery, {'mark': null, 'pageSize': 50});
    });

    test('listEpisodes serves first page from Hive cache', () async {
      await local.cacheBox.put(
        'drama_episodes_d-1|first|50|zh',
        <dynamic, dynamic>{
          'data': {
            'list': [
              const DramaEpisodeListItem(
                episodeId: 'ep-cached',
                episodeNo: 1,
                title: 'Cached',
              ).toJson(),
            ],
            'mark': 'm2',
            'hasMore': true,
            'pageSize': 50,
          },
          'expiresAt': DateTime.now()
              .add(const Duration(minutes: 5))
              .millisecondsSinceEpoch,
        },
      );

      final result = await repo.listEpisodes('d-1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.list?.single.episodeId, 'ep-cached');
      expect(result.dataOrNull?.mark, 'm2');
      expect(result.dataOrNull?.hasMore, isTrue);
      expect(api.safeGetCallCount, 0);
    });

    test('listEpisodes with mark bypasses cache', () async {
      await local.cacheBox.put(
        'drama_episodes_d-1|first|50|zh',
        <dynamic, dynamic>{
          'data': {
            'list': [
              const DramaEpisodeListItem(
                episodeId: 'ep-cached',
                episodeNo: 1,
              ).toJson(),
            ],
            'hasMore': false,
          },
          'expiresAt': DateTime.now()
              .add(const Duration(minutes: 5))
              .millisecondsSinceEpoch,
        },
      );
      api.stubGet(
        '/api/mini-drama/public/dramas/d-1/episodes',
        Result.success(
          const PageDto(
            list: [DramaEpisodeListItem(episodeId: 'ep-2', episodeNo: 2)],
            hasMore: false,
          ),
        ),
      );

      final result = await repo.listEpisodes('d-1', mark: 'm2');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.list?.single.episodeId, 'ep-2');
      expect(api.safeGetCallCount, 1);
      expect(api.lastGetQuery, {'mark': 'm2', 'pageSize': 50});
    });

    group('getCommentReplies', () {
      test('fetches first page from the replies endpoint', () async {
        api.stubGet(
          '*',
          Result.success(
            const PageDto<StoryComment>(
              list: [
                StoryComment(commentId: 'r1', content: 'reply', parentId: '1'),
              ],
              mark: '-1',
              hasMore: false,
            ),
          ),
        );

        final result = await repo.getCommentReplies('root-1');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.list?.first.commentId, 'r1');
        expect(api.safeGetCallCount, 1);
        expect(
          api.lastGetPath,
          '/api/mini-drama/public/comments/root-1/replies',
        );
      });

      test('serves cached first page from Hive without API call', () async {
        await local.cacheBox.put('comment_replies_root-1', <dynamic, dynamic>{
          'data': <String, dynamic>{
            'list': [
              const StoryComment(
                commentId: 'r-cached',
                content: 'cached reply',
              ).toJson(),
            ],
            'mark': 'next',
            'hasMore': true,
            'pageSize': 20,
          },
          'expiresAt': DateTime.now()
              .add(const Duration(minutes: 5))
              .millisecondsSinceEpoch,
        });

        final result = await repo.getCommentReplies('root-1');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.list?.first.commentId, 'r-cached');
        expect(result.dataOrNull?.mark, 'next');
        expect(api.safeGetCallCount, 0);
      });

      test(
        'paged request carries mark/pageSize to the replies endpoint',
        () async {
          api.stubGet(
            '*',
            Result.success(
              const PageDto<StoryComment>(
                list: [StoryComment(commentId: 'r2', content: 'page2')],
                mark: '-1',
                hasMore: false,
              ),
            ),
          );

          final result = await repo.getCommentReplies(
            'root-1',
            mark: 'cursor-2',
            pageSize: 10,
          );

          expect(result.isSuccess, true);
          expect(result.dataOrNull?.list?.first.commentId, 'r2');
          expect(api.safeGetCallCount, 1);
          expect(
            api.lastGetPath,
            '/api/mini-drama/public/comments/root-1/replies',
          );
        },
      );

      test(
        'terminal cursor "-1" returns an empty page without API call',
        () async {
          final result = await repo.getCommentReplies('root-1', mark: '-1');

          expect(result.isSuccess, true);
          expect(result.dataOrNull?.list, isEmpty);
          expect(result.dataOrNull?.hasMore, isFalse);
          expect(result.dataOrNull?.mark, '-1');
          expect(api.safeGetCallCount, 0);
        },
      );
    });

    group('postCommentReply', () {
      test('posts a reply to the user replies endpoint', () async {
        api.stubPost(
          '/api/mini-drama/user/comments/root-1/replies',
          Result.success(
            const StoryComment(
              commentId: 'r1',
              content: 'a reply',
              rootId: 'root-1',
              parentId: 'root-1',
            ),
          ),
        );

        final result = await repo.postCommentReply(
          'root-1',
          content: 'a reply',
        );

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.commentId, 'r1');
        expect(api.safePostCallCount, 1);
        expect(
          api.lastPostPath,
          '/api/mini-drama/user/comments/root-1/replies',
        );
        expect(api.lastPostBody, {'content': 'a reply'});
      });
    });
  });
}
