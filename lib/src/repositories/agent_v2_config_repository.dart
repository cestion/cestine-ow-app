import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';

import '../api/story_api_client.dart';
import '../core/json_helpers.dart';
import '../core/request_coalescer.dart';
import '../core/request_keys.dart';
import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import 'global_config_codec.dart';

abstract class AgentV2ConfigRepository {
  /// Last network-validated config for an immediate stale-while-revalidate UI.
  GlobalConfig? readCachedConfig();

  /// Fetches only Agent V2 dependencies. `safeGet` already performs bounded
  /// retry with exponential backoff for transient failures. Once a request
  /// succeeds, later calls in the same app lifecycle reuse that result.
  Future<Result<GlobalConfig>> fetchLatestConfig();

  Future<void> clearCache();
}

class AgentV2ConfigRepositoryImpl implements AgentV2ConfigRepository {
  static const _configKeys = 'chainlinks,init';
  static const _hiveKey = 'agent_v2_config_v1';

  final StoryApiClient _api;
  final Box<dynamic> _box;
  final String _apiBaseUrl;
  final RequestCoalescer _coalescer;
  GlobalConfig? _cachedConfig;
  GlobalConfig? _successfulConfig;

  AgentV2ConfigRepositoryImpl(
    this._api,
    this._box, {
    required String apiBaseUrl,
    RequestCoalescer? coalescer,
  }) : _apiBaseUrl = _normalizeApiBaseUrl(apiBaseUrl),
       _coalescer = coalescer ?? MemoryRequestCoalescer();

  @override
  GlobalConfig? readCachedConfig() {
    final memory = _cachedConfig;
    if (memory != null) return memory;

    try {
      final raw = _box.get(_hiveKey);
      if (raw is! String) return null;
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      if (_normalizeApiBaseUrl(envelope['apiBaseUrl'] as String? ?? '') !=
          _apiBaseUrl) {
        unawaited(_box.delete(_hiveKey));
        return null;
      }
      final data = envelope['data'];
      if (data is! Map<String, dynamic>) return null;
      final config = GlobalConfig.fromJson(data);
      if (!_isValid(config)) return null;
      _cachedConfig = config;
      return config;
    } catch (error) {
      StoryLogger.w(
        'Agent V2 config cache read failed',
        error: error,
        tag: 'AgentV2ConfigRepo',
      );
      return null;
    }
  }

  @override
  Future<Result<GlobalConfig>> fetchLatestConfig() {
    final successfulConfig = _successfulConfig;
    if (successfulConfig != null) {
      return Future.value(Result.success(successfulConfig));
    }

    return _coalescer.run(
      RequestKeys.agentV2Config,
      _fetchLatestConfigFromNetwork,
    );
  }

  Future<Result<GlobalConfig>> _fetchLatestConfigFromNetwork() async {
    final result = await _api.safeGet(
      '/api/admin/v1/configs/keys/$_configKeys',
      decoder: decodeWith(GlobalConfig.fromJson),
    );
    final config = result.dataOrNull;
    if (result.isFailure || config == null) return result;
    if (!_isValid(config)) {
      return Result.failure(
        ApiError.business(-1, 'Agent V2 config incomplete'),
      );
    }

    _successfulConfig = config;
    _cachedConfig = config;
    try {
      await _box.put(
        _hiveKey,
        jsonEncode({
          'data': globalConfigToJson(config),
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
          'apiBaseUrl': _apiBaseUrl,
        }),
      );
    } catch (error) {
      // Network data remains usable even if persistence fails.
      StoryLogger.w(
        'Agent V2 config cache write failed',
        error: error,
        tag: 'AgentV2ConfigRepo',
      );
    }
    return Result.success(config);
  }

  @override
  Future<void> clearCache() async {
    _successfulConfig = null;
    _cachedConfig = null;
    await _box.delete(_hiveKey);
  }

  bool _isValid(GlobalConfig config) {
    final staminaLimit = config.init?.actorNft?.staminaLimit;
    return staminaLimit != null && staminaLimit > 0;
  }
}

String _normalizeApiBaseUrl(String url) {
  final trimmed = url.trim();
  return trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
