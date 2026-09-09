import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/follow_relation.dart';
import 'package:story_app/src/model/page_dto.dart';
import 'package:story_app/src/model/watch_history_model.dart';
import 'package:story_app/src/model/work_content_type.dart';
import 'package:story_app/src/repositories/user_repository.dart';

class _FakeApiClient extends StoryApiClient {
  _FakeApiClient(this.payload, {this.getDelay = Duration.zero})
    : super(baseUrl: 'https://test.api/');

  final dynamic payload;
  final Duration getDelay;
  int getCallCount = 0;
  String? lastGetPath;
  Map<String, dynamic>? lastGetQuery;
  String? lastPostPath;
  String? lastDeletePath;
  Map<String, dynamic>? lastDeleteQuery;

  @override
  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async {
    getCallCount++;
    lastGetPath = path;
    lastGetQuery = query;
    if (getDelay > Duration.zero) {
      await Future<void>.delayed(getDelay);
    }
    try {
      return Result<T>.success(decoder(payload));
    } catch (error) {
      return Result<T>.failure(ApiError.parse(error.toString()));
    }
  }

  @override
  Future<Result<T>> safePost<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
    bool retry = false,
  }) async {
    lastPostPath = path;
    return Result<T>.success(decoder(null));
  }

  @override
  Future<Result<T>> safeDelete<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) decoder,
  }) async {
    lastDeletePath = path;
    lastDeleteQuery = query;
    return Result<T>.success(decoder(null));
  }
}

void main() {
  group('UserRepositoryImpl.getDramaNftCount', () {
    test('parses a string total without decoding NFT list items', () async {
      final api = _FakeApiClient({
        'total': ' 7 ',
        // Deliberately malformed for NftPosition.fromJson. Count decoding must
        // remain independent from list-item schema changes.
        'list': [
          {'dramaId': 123},
        ],
      });
      final repository = UserRepositoryImpl(api);

      final result = await repository.getDramaNftCount();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 7);
      expect(api.lastGetPath, '/api/userWallet/dramaNft/positions');
      expect(api.lastGetQuery, {'pageSize': 1});
    });

    test('returns a parse failure when total is missing', () async {
      final repository = UserRepositoryImpl(
        _FakeApiClient({'list': <Object?>[]}),
      );

      final result = await repository.getDramaNftCount();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ParseError>());
    });
  });

  group('UserRepositoryImpl follow APIs', () {
    test('followUser posts /api/userWallet/follow/{id}', () async {
      final api = _FakeApiClient(null);
      final repository = UserRepositoryImpl(api);

      final result = await repository.followUser('u-9');

      expect(result.isSuccess, isTrue);
      expect(api.lastPostPath, '/api/userWallet/follow/u-9');
    });

    test('unfollowUser deletes /api/userWallet/follow/{id}', () async {
      final api = _FakeApiClient(null);
      final repository = UserRepositoryImpl(api);

      final result = await repository.unfollowUser('u-9');

      expect(result.isSuccess, isTrue);
      expect(api.lastDeletePath, '/api/userWallet/follow/u-9');
    });

    test('getFollowRelation parses status', () async {
      final api = _FakeApiClient({'status': 'MUTUAL'});
      final repository = UserRepositoryImpl(api);

      final result = await repository.getFollowRelation('u-9');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, FollowRelationStatus.mutual);
      expect(api.lastGetPath, '/api/userWallet/users/u-9/relation');
    });
  });

  group('UserRepositoryImpl.getRecentWatchHistory', () {
    const payload = [
      {
        'kind': 'DRAMA',
        'watchedAt': 1723356789000,
        'drama': {
          'dramaId': 1001,
          'dramaTitle': 'Drama',
          'dramaCoverUrl': 'https://example.com/drama.jpg',
          'totalEpisodes': 44,
          'badge': 'OFFICIAL',
          'actorCollections': [
            {
              'actorCollectionId': 9,
              'actorCollectionName': 'Actor',
              'actorCollectionAvatar': 'https://example.com/actor.jpg',
              'badge': 'OFFICIAL',
              'trust': 80,
              'computingPower': 12,
            },
          ],
          'lastEpisodeId': 20003,
          'lastEpisodeNo': 3,
          'watchProgressText': '3/44集',
        },
        'video': {
          'episodeId': 30001,
          'dramaId': 1001,
          'episodeNo': 5,
          'contentType': 'SHORT_DRAMA',
          'title': 'Episode 5',
          'coverUrl': 'https://example.com/episode.jpg',
          'description': 'Description',
          'likeCount': 128,
        },
      },
    ];

    test('requests the default limit and parses nested data', () async {
      final api = _FakeApiClient(payload);
      final repository = UserRepositoryImpl(api);

      final result = await repository.getRecentWatchHistory();

      expect(result.isSuccess, isTrue);
      expect(api.lastGetPath, '/api/mini-drama/user/watch-history/recent');
      expect(api.lastGetQuery, {'limit': 3});
      final item = result.dataOrNull!.single;
      expect(item, isA<WatchHistoryItem>());
      expect(item.drama?.dramaId, '1001');
      expect(item.drama?.actorCollections.single.id, '9');
      expect(item.video?.episodeId, '30001');
      expect(item.video?.contentType, WorkContentType.shortDrama);
    });

    test('caps limit at the API maximum', () async {
      final api = _FakeApiClient(const <Object?>[]);
      final repository = UserRepositoryImpl(api);

      await repository.getRecentWatchHistory(limit: 99);

      expect(api.lastGetQuery, {'limit': 10});
    });
  });

  group('UserRepositoryImpl paginated watch history', () {
    test(
      'getWatchHistoryVideos omits the first-page mark and parses page',
      () async {
        final api = _FakeApiClient({
          'pageSize': 20,
          'mark': '1723356789000_30001',
          'list': const [
            {
              'episodeId': 30001,
              'dramaId': 1001,
              'episodeNo': 5,
              'contentType': 'SHORT_DRAMA',
              'title': 'Episode 5',
              'coverUrl': 'https://example.com/episode.jpg',
              'description': 'Description',
              'likeCount': 128,
            },
          ],
          'hasMore': true,
        });
        final repository = UserRepositoryImpl(api);

        final result = await repository.getWatchHistoryVideos();

        expect(result.isSuccess, isTrue);
        expect(api.lastGetPath, '/api/mini-drama/user/watch-history/videos');
        expect(api.lastGetQuery, {'pageSize': 20});
        final page = result.dataOrNull!;
        expect(page, isA<PageDto<WatchHistoryVideo>>());
        expect(page.mark, '1723356789000_30001');
        expect(page.hasMore, isTrue);
        expect(page.list!.single.episodeId, '30001');
        expect(page.list!.single.contentType, WorkContentType.shortDrama);
      },
    );

    test('getWatchHistoryDramas sends cursor and caps page size', () async {
      final api = _FakeApiClient({
        'pageSize': 100,
        'mark': '1723356789000_1001',
        'list': const [
          {
            'dramaId': 1001,
            'dramaTitle': 'Drama',
            'dramaCoverUrl': 'https://example.com/drama.jpg',
            'totalEpisodes': 44,
            'badge': 'OFFICIAL',
            'actorCollections': [
              {
                'actorCollectionId': 9,
                'actorCollectionName': 'Actor',
                'actorCollectionAvatar': 'https://example.com/actor.jpg',
                'badge': 'OFFICIAL',
                'trust': 80,
                'computingPower': 12,
              },
            ],
            'lastEpisodeId': 20003,
            'lastEpisodeNo': 3,
            'watchProgressText': '3/44集',
          },
        ],
        'hasMore': false,
      });
      final repository = UserRepositoryImpl(api);

      final result = await repository.getWatchHistoryDramas(
        mark: 'previous_cursor',
        pageSize: 101,
      );

      expect(result.isSuccess, isTrue);
      expect(api.lastGetPath, '/api/mini-drama/user/watch-history/dramas');
      expect(api.lastGetQuery, {'mark': 'previous_cursor', 'pageSize': 100});
      final drama = result.dataOrNull!.list!.single;
      expect(drama.dramaId, '1001');
      expect(drama.lastEpisodeId, '20003');
      expect(drama.watchProgressText, '3/44集');
      expect(drama.actorCollections.single.id, '9');
    });

    test('clearWatchHistory sends the requested scope', () async {
      final api = _FakeApiClient(null);
      final repository = UserRepositoryImpl(api);

      final result = await repository.clearWatchHistory(
        scope: WatchHistoryClearScope.video,
      );

      expect(result.isSuccess, isTrue);
      expect(api.lastDeletePath, '/api/mini-drama/user/watch-history');
      expect(api.lastDeleteQuery, {'scope': 'VIDEO'});
    });

    test('clearWatchHistory defaults to all history', () async {
      final api = _FakeApiClient(null);
      final repository = UserRepositoryImpl(api);

      await repository.clearWatchHistory();

      expect(api.lastDeleteQuery, {'scope': 'ALL'});
    });
  });

  group('UserRepositoryImpl.getProfile forceRefresh coalescing', () {
    test('concurrent forceRefresh shares one network call', () async {
      final api = _FakeApiClient({
        'id': 1,
        'userId': 'u-1',
        'nickname': 'Tester',
        'isDeleted': '0',
      }, getDelay: const Duration(milliseconds: 40));
      final repository = UserRepositoryImpl(api);

      final results = await Future.wait([
        repository.getProfile(forceRefresh: true),
        repository.getProfile(forceRefresh: true),
        repository.getProfile(forceRefresh: true),
      ]);

      expect(api.getCallCount, 1);
      expect(api.lastGetPath, '/api/userWallet/userInfo');
      for (final result in results) {
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.userId, 'u-1');
      }
    });

    test(
      'clearProfileCache during forceRefresh skips stale cache put',
      () async {
        final api = _FakeApiClient({
          'id': 1,
          'userId': 'u-old',
          'nickname': 'Old',
          'isDeleted': '0',
        }, getDelay: const Duration(milliseconds: 40));
        final repository = UserRepositoryImpl(api);

        final inflight = repository.getProfile(forceRefresh: true);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await repository.clearProfileCache();
        await inflight;

        expect(api.getCallCount, 1);
        // Stale put must not resurrect the cleared cache entry.
        await repository.getProfile();
        expect(api.getCallCount, 2);
      },
    );
  });
}
