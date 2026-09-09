import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';

import '../core/json_helpers.dart';
import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import '../api/story_api_client.dart';
import 'global_config_codec.dart';

abstract class ConfigRepository {
  /// Read the last known config without making a network request.
  ///
  /// Returns the in-memory snapshot first, then the Hive snapshot. The cached
  /// value may be stale by design; callers can render it immediately and
  /// refresh in the background with [getGlobalConfig].
  GlobalConfig? getCachedGlobalConfig();

  Future<Result<GlobalConfig>> getGlobalConfig({bool forceRefresh = false});

  /// Drop in-memory and Hive-persisted config so the next read hits the API.
  Future<void> invalidateCache();

  Future<void> dispose();
}

class ConfigRepositoryImpl implements ConfigRepository {
  static const String _configKeys =
      'chainlinks,init,mini-drama,banner,activity';

  /// Same-process reuse window. Cold start has empty memory → always hits network.
  static const Duration _memoryTtl = Duration(minutes: 5);

  /// Cap wait for config so weak networks fall back to Hive instead of hanging.
  static const Duration _fetchTimeout = Duration(seconds: 8);

  /// Hive cache key. Bumped to `config_global_v4` after fixing nested toJson
  /// for chainlinks (v3 could fail to persist / round-trip RPC + tokens).
  static const String _hiveKey = 'config_global_v4';

  final StoryApiClient _api;
  final Box<dynamic> _box;

  /// Current API host — used to reject Hive entries from another env after
  /// overwrite-install (same package id keeps Hive across builds).
  final String _apiBaseUrl;

  ConfigRepositoryImpl(this._api, this._box, {required String apiBaseUrl})
    : _apiBaseUrl = _normalizeApiBaseUrl(apiBaseUrl);

  // ── In-memory TTL cache ──────────────────────────────────────────────

  GlobalConfig? _cachedConfig;
  DateTime? _cachedAt;

  @override
  Future<void> dispose() async {
    _cachedConfig = null;
    _cachedAt = null;
  }

  @override
  Future<void> invalidateCache() async {
    _cachedConfig = null;
    _cachedAt = null;
    try {
      await _box.delete(_hiveKey);
      // Also drop previous keys so a rollback does not resurrect stale data.
      await _box.delete('config_global_v3');
      await _box.delete('config_global_v2');
    } catch (e) {
      StoryLogger.w(
        'Hive config invalidate failed',
        error: e,
        tag: 'ConfigRepo',
      );
    }
  }

  @override
  GlobalConfig? getCachedGlobalConfig() {
    final memoryConfig = _cachedConfig;
    if (memoryConfig != null) return memoryConfig;
    return _readHiveConfig();
  }

  @override
  Future<Result<GlobalConfig>> getGlobalConfig({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      // Skip memory only; keep Hive so a failed force-refresh can still fall back
      // unless the caller explicitly wiped storage via [invalidateCache].
      _cachedConfig = null;
      _cachedAt = null;
    }

    // 1. Same-process memory hit (not cold start).
    if (!forceRefresh && _cachedConfig != null && _cachedAt != null) {
      final age = DateTime.now().difference(_cachedAt!);
      if (age < _memoryTtl) {
        StoryLogger.d(
          'Returning in-memory global config (age ${age.inSeconds}s)',
          tag: 'ConfigRepo',
        );
        return Result.success(_cachedConfig!);
      }
      StoryLogger.d('In-memory global config expired', tag: 'ConfigRepo');
    }

    // 2. Network first — cold start and expired memory always reach here.
    final networkResult = await _fetchFromApi();
    if (networkResult.isSuccess && networkResult.dataOrNull != null) {
      await _persistSuccess(networkResult.dataOrNull!);
      return networkResult;
    }

    StoryLogger.w(
      'Global config network fetch failed '
      '(${networkResult.errorOrNull?.userMessage ?? 'unknown'}), '
      'trying Hive fallback',
      tag: 'ConfigRepo',
    );

    // 3. Fallback: last good Hive snapshot (no age limit).
    final hiveConfig = _readHiveConfig();
    if (hiveConfig != null) {
      _cachedConfig = hiveConfig;
      _cachedAt = DateTime.now();
      StoryLogger.d(
        'Returning Hive-persisted global config after network failure',
        tag: 'ConfigRepo',
      );
      return Result.success(hiveConfig);
    }

    return networkResult;
  }

  Future<Result<GlobalConfig>> _fetchFromApi() async {
    try {
      return await _api
          .safeGet(
            '/api/admin/v1/configs/keys/$_configKeys',
            decoder: decodeWith(GlobalConfig.fromJson),
          )
          .timeout(_fetchTimeout);
    } on TimeoutException catch (e, st) {
      StoryLogger.w(
        'Global config fetch timed out after ${_fetchTimeout.inSeconds}s',
        error: e,
        stackTrace: st,
        tag: 'ConfigRepo',
      );
      return Result.failure(ApiError.timeout('Config request timed out'));
    }
  }

  Future<void> _persistSuccess(GlobalConfig config) async {
    _cachedConfig = config;
    _cachedAt = DateTime.now();
    try {
      await _box.put(
        _hiveKey,
        jsonEncode({
          // Deep-convert nested models — GlobalConfig.toJson() is not
          // explicitToJson, so jsonEncode(toJson()) would throw / drop data.
          'data': globalConfigToJson(config),
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
          // Bind cache to API host so test/prod overwrite-installs don't mix.
          'apiBaseUrl': _apiBaseUrl,
        }),
      );
    } catch (e) {
      StoryLogger.w('Hive config write failed', error: e, tag: 'ConfigRepo');
    }
  }

  GlobalConfig? _readHiveConfig() {
    try {
      final raw = _box.get(_hiveKey);
      if (raw is! String) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedBaseUrl = map['apiBaseUrl'];
      // Missing or mismatched host → treat as miss (old env after overwrite).
      if (cachedBaseUrl is! String ||
          _normalizeApiBaseUrl(cachedBaseUrl) != _apiBaseUrl) {
        StoryLogger.w(
          'Ignoring Hive global config from different env '
          '(cached=$cachedBaseUrl, current=$_apiBaseUrl)',
          tag: 'ConfigRepo',
        );
        // Drop stale entry so later boots don't keep warning / reading it.
        unawaited(_box.delete(_hiveKey));
        return null;
      }
      final data = map['data'];
      if (data is! Map<String, dynamic>) return null;
      return GlobalConfig.fromJson(data);
    } catch (e) {
      StoryLogger.w('Hive config read failed', error: e, tag: 'ConfigRepo');
      return null;
    }
  }
}

String _normalizeApiBaseUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.endsWith('/')) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}
