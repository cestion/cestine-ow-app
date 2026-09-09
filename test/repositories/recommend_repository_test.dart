import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/repositories/recommend_repository.dart';
import 'package:story_app/src/services/device_id_service.dart';

class _CapturingApiClient extends StoryApiClient {
  _CapturingApiClient({this.items = const []}) : super(baseUrl: 'https://example.com');

  final List<Map<String, dynamic>> items;

  Map<String, dynamic>? lastQuery;
  Map<String, String>? lastHeaders;

  @override
  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async {
    lastQuery = query;
    lastHeaders = headers;
    return Result.success(
      decoder({
        'cursor': null,
        'hasMore': false,
        'items': items,
      }),
    );
  }
}

class _FakeDeviceId extends DeviceIdService {
  @override
  String? get cachedRawDeviceId => 'fake-device';

  @override
  Future<String> getDeviceId() async => 'app-fake-device';

  @override
  Future<String> getRawDeviceId() async => 'fake-device';
}

void main() {
  test('fetchFeed sends Device-ID and omits userId', () async {
    final api = _CapturingApiClient();
    final repo = RecommendRepositoryImpl(api, _FakeDeviceId());

    await repo.fetchFeed();

    expect(api.lastQuery?.containsKey('userId'), isFalse);
    expect(api.lastQuery?['size'], 10);
    expect(api.lastHeaders?['Device-ID'], 'app-fake-device');
  });

  test('fetchFeed forwards cursor when paging', () async {
    final api = _CapturingApiClient();
    final repo = RecommendRepositoryImpl(api, _FakeDeviceId());

    await repo.fetchFeed(cursor: 'abc', size: 20);

    expect(api.lastQuery?['cursor'], 'abc');
    expect(api.lastQuery?['size'], 20);
    expect(api.lastQuery?.containsKey('userId'), isFalse);
  });

  test('peekCachedFirstPageSync returns cached first page from memory', () async {
    final api = _CapturingApiClient(
      items: [
        {
          'dramaId': 'd1',
          'episodeId': 'ep1',
          'episodeNo': 1,
          'title': 'Cached drama',
          'coverUrl': 'https://cdn.example/cover.jpg',
          'mediaAccessUrl': 'https://cdn.example/v.m3u8',
        },
      ],
    );
    final repo = RecommendRepositoryImpl(api, _FakeDeviceId());

    await repo.fetchFeed();

    final syncHit = repo.peekCachedFirstPageSync(subject: 'guest');
    expect(syncHit, isNotNull);
    expect(syncHit!.list, hasLength(1));
    expect(syncHit.list!.first.title, 'Cached drama');
    expect(syncHit.list!.first.coverUrl, 'https://cdn.example/cover.jpg');
  });
}
