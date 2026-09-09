import '../api/story_api_client.dart';
import '../core/json_helpers.dart';
import '../core/result.dart';
import '../model/app_version_update_model.dart';

abstract class AppVersionRepository {
  Future<Result<AppVersionUpdateCheckResponse>> checkUpdate({
    required String channel,
    required String versionName,
  });

  Future<void> dispose();
}

class AppVersionRepositoryImpl implements AppVersionRepository {
  static const _path = '/api/admin/v1/app-version-updates/check';

  final StoryApiClient _api;

  AppVersionRepositoryImpl(this._api);

  @override
  Future<Result<AppVersionUpdateCheckResponse>> checkUpdate({
    required String channel,
    required String versionName,
  }) {
    return _api.safeGet(
      _path,
      query: {
        'channel': channel,
        'version_name': versionName,
      },
      decoder: decodeWith(AppVersionUpdateCheckResponse.fromJson),
    );
  }

  @override
  Future<void> dispose() async {}
}
