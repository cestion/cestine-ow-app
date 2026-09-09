import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/app_version_update_model.dart';
import 'package:story_app/src/repositories/app_version_repository.dart';

class _FakeApiClient extends StoryApiClient {
  _FakeApiClient(this._handler) : super(baseUrl: 'https://test.api/');

  final Future<Map<String, dynamic>> Function(String path, Map<String, dynamic>? query)
  _handler;

  @override
  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async {
    final data = decoder(await _handler(path, query));
    return Result<T>.success(data);
  }
}

void main() {
  group('AppVersionRepositoryImpl', () {
    test('checkUpdate sends channel and version_name query params', () async {
      Map<String, dynamic>? capturedQuery;
      final api = _FakeApiClient((path, query) async {
        capturedQuery = query;
        return {
          'need_update': true,
          'type': 'Remind',
          'version_name': '2.0.0',
          'download_url': 'https://example.com/app',
          'contents': {'en': 'Update notes'},
        };
      });
      final repo = AppVersionRepositoryImpl(api);

      final result = await repo.checkUpdate(
        channel: 'ios',
        versionName: '1.3.1',
      );

      expect(capturedQuery, {
        'channel': 'ios',
        'version_name': '1.3.1',
      });
      expect(result.isSuccess, isTrue);
      final response = result.dataOrNull!;
      expect(response, isA<AppVersionUpdateCheckResponse>());
      expect(response.needUpdate, isTrue);
      expect(response.type, 'Remind');
      expect(response.versionName, '2.0.0');
      expect(response.downloadUrl, 'https://example.com/app');
      expect(response.contents?.en, 'Update notes');
    });

    test('parses need_update false minimal payload', () async {
      final api = _FakeApiClient((path, query) async {
        return {'need_update': false};
      });
      final repo = AppVersionRepositoryImpl(api);

      final result = await repo.checkUpdate(
        channel: 'android',
        versionName: '9.9.9',
      );

      expect(result.dataOrNull?.needUpdate, isFalse);
      expect(result.dataOrNull?.versionName, isNull);
    });
  });
}
