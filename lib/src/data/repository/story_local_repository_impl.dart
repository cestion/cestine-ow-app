import 'dart:io' as io;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../../core/story_constants.dart';
import '../../core/story_logger.dart';
import '../../core/json_helpers.dart';
import '../../foundation/hive_mixin.dart';
import '../../model/models.dart';
import 'story_local_repository.dart';

class StoryLocalRepositoryImpl
    with HiveMixin<dynamic>
    implements StoryLocalRepository {
  StoryLocalRepositoryImpl({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  static const _tokenKey = 'userToken';
  static const _walletKey = 'solana_wallet_address';
  static const _evmWalletKey = 'evm_wallet_address';

  /// Hive stamp for the API host that wrote the rest of the box.
  static const envStampKey = '__env_api_base_url__';

  /// Survives only while the app sandbox exists. Missing after uninstall.
  static const sandboxInstallMarkerKey = '__sandbox_install_marker_v1__';

  /// Keys that survive an env switch (device preferences + install marker).
  static const _envPreserveKeys = {
    'locale',
    'themeMode',
    envStampKey,
    sandboxInstallMarkerKey,
  };

  /// Secure-storage key used by [DeviceIdService] (same plugin instance).
  static const _deviceIdSecureKey = 'device_id';

  @override
  String get boxName => 'story_local_cache';

  @override
  Box<dynamic> get cacheBox => box;

  String? _tokenCache;

  @override
  String? get cachedToken => _tokenCache;

  @override
  Future<void> init() async {
    await initBox();
    try {
      if (box.isOpen && box.length > 50) {
        box
            .compact()
            .then((_) {
              StoryLogger.i(
                'Hive box compacted successfully.',
                tag: 'StoryLocalRepository',
              );
            })
            .catchError((Object e) {
              StoryLogger.w(
                'Failed to compact Hive box asynchronously: $e',
                tag: 'StoryLocalRepository',
              );
            });
      }
    } catch (e) {
      StoryLogger.w(
        'Failed to initiate Hive box compaction: $e',
        tag: 'StoryLocalRepository',
      );
    }
  }

  @override
  Future<bool> reconcileSandboxInstall() async {
    if (!box.isOpen) return false;
    if (box.containsKey(sandboxInstallMarkerKey)) return false;

    // Empty Hive ⇒ uninstall wiped the sandbox (or brand-new install).
    // Non-empty Hive without marker ⇒ app update before this stamp existed.
    final freshSandbox = box.isEmpty;
    if (freshSandbox) {
      StoryLogger.w(
        'Fresh sandbox (no install marker); clearing Keychain/secure '
        'session leftovers so uninstall requires login again',
        tag: 'StoryLocalRepository',
      );
      await _clearSecureSessionLeftovers();
    }

    await box.put(sandboxInstallMarkerKey, 1);
    return freshSandbox;
  }

  @override
  Future<bool> reconcileEnv(String apiBaseUrl) async {
    if (!box.isOpen) return false;
    final normalized = _normalizeApiBaseUrl(apiBaseUrl);
    final previousRaw = box.get(envStampKey);
    final previous = previousRaw is String
        ? _normalizeApiBaseUrl(previousRaw)
        : null;

    if (previous == normalized) {
      return false;
    }

    // Stamp missing with an empty box → first install; just write stamp.
    // Stamp missing with data → legacy / other env; purge for safety.
    // Stamp present but different → overwrite-install env switch.
    final shouldPurge =
        previous != null ||
        box.keys.any((k) {
          return !_envPreserveKeys.contains(k.toString());
        });

    if (shouldPurge) {
      StoryLogger.w(
        'Env changed (was=${previous ?? 'unset'}, now=$normalized); '
        'purging env-scoped local cache',
        tag: 'StoryLocalRepository',
      );
      await _purgeEnvScopedData();
    }

    await box.put(envStampKey, normalized);
    return shouldPurge;
  }

  Future<void> _purgeEnvScopedData() async {
    final preserved = <String, dynamic>{};
    for (final key in _envPreserveKeys) {
      if (key == envStampKey) continue;
      if (box.containsKey(key)) {
        preserved[key] = box.get(key);
      }
    }

    await box.clear();
    if (preserved.isNotEmpty) {
      await box.putAll(preserved);
    }

    await _clearSecureSessionLeftovers();
  }

  /// Clears JWT / wallet / device-id leftovers that may survive uninstall
  /// via iOS Keychain (or Android backup of encrypted prefs).
  Future<void> _clearSecureSessionLeftovers() async {
    await clearToken();
    await clearSolanaWalletAddress();
    await clearEthereumWalletAddress();
    try {
      await _secureStorage.delete(key: _deviceIdSecureKey);
    } catch (e, st) {
      StoryLogger.w(
        'Failed to clear device_id from secure storage',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
    }
  }

  static String _normalizeApiBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  @override
  List<String> getWatchHistoryDramaIds() {
    if (!box.isOpen) return [];
    const prefix = 'watch_progress_';
    final dramaIds = <String>[];
    for (final key in box.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith(prefix)) {
        dramaIds.add(keyStr.substring(prefix.length));
      }
    }
    // Sort by last-touched: read the map's first key as a heuristic, but
    // in practice we just return in scan order (Hive LinkedHashMap preserves
    // insertion order for newly-inserted keys).
    return dramaIds;
  }

  @override
  int? getLastWatchedEpisode(String dramaId) {
    final raw = box.get('watch_progress_$dramaId');
    if (raw is! Map) return null;
    int maxEp = 0;
    for (final key in raw.keys) {
      final epStr = key.toString();
      if (epStr.startsWith('ep')) {
        final epNo = int.tryParse(epStr.substring(2));
        if (epNo != null && epNo > maxEp) maxEp = epNo;
      }
    }
    return maxEp > 0 ? maxEp : null;
  }

  @override
  Future<void> vacuumCache() async {
    if (!box.isOpen) return;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // ── Phase 1: Delete TTL-expired entries ──────────────────────
      final expiredKeys = <dynamic>[];
      // Collect cache entries (with a timestamp) for LRU eviction later.
      final cacheEntries = <MapEntry<dynamic /*key*/, int /*timestamp*/>>[];

      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw is! Map) continue;

        final expiresAt = asIntOrNull(raw['expiresAt']);
        if (expiresAt != null && now > expiresAt) {
          expiredKeys.add(key);
          continue;
        }
        final cachedAt = asIntOrNull(raw['cachedAt']);
        final ttlMs = asIntOrNull(raw['ttlMs']);
        if (cachedAt != null && ttlMs != null && now > cachedAt + ttlMs) {
          expiredKeys.add(key);
          continue;
        }

        // Collect as cache entry if it carries a timestamp
        // (expiresAt from HiveCacheLayer or cachedAt from LegacyHiveCacheLayer).
        final ts = cachedAt ?? expiresAt;
        if (ts != null) cacheEntries.add(MapEntry(key, ts));
      }

      if (expiredKeys.isNotEmpty) {
        await box.deleteAll(expiredKeys);
        StoryLogger.i(
          'vacuumCache: Purged ${expiredKeys.length} expired entries.',
          tag: 'StoryLocalRepository',
        );
      }

      // ── Phase 2: High-water mark — LRU eviction by file size ────
      final fileSize = await getCacheFileSize();

      if (fileSize > StoryConstants.hiveCacheHighWaterBytes) {
        // Sort by timestamp ascending (oldest first) → LRU-by-age.
        cacheEntries.sort((a, b) => a.value.compareTo(b.value));

        // Evict oldest 25 % of cache entries to bring size back down.
        final evictCount = (cacheEntries.length * 0.25).ceil();
        final evictKeys = cacheEntries
            .take(evictCount)
            .map((e) => e.key)
            .toList();

        if (evictKeys.isNotEmpty) {
          await box.deleteAll(evictKeys);
          StoryLogger.i(
            'vacuumCache: High-water (${fileSize ~/ (1024 * 1024)}MB > '
            '${StoryConstants.hiveCacheHighWaterBytes ~/ (1024 * 1024)}MB) evicted $evictCount oldest entries.',
            tag: 'StoryLocalRepository',
          );
        }
      }

      // ── Phase 3: Compact to reclaim dead bytes ──────────────────
      await box.compact();
      StoryLogger.i(
        'vacuumCache: Compacted (entries=${box.length}).',
        tag: 'StoryLocalRepository',
      );
    } catch (e) {
      StoryLogger.w(
        'Failed to vacuum Hive cache: $e',
        tag: 'StoryLocalRepository',
      );
    }
  }

  /// Regenerable CacheChain / display-cache prefixes. User prefs, watch
  /// progress, watchlist, search history and drafts are not listed here.
  static const apiCacheKeyPrefixes = [
    'drama_list_',
    'drama_detail_',
    'episode_play_',
    'creator_dramas_',
    'comments_',
    'drama_episodes_',
    'drama_tags_',
    'actor_public_',
    'actor_my_',
    'actor_collections_',
    'actor_collection_detail_',
    'mining_weekly_stats_',
    'mining_deployed_',
    'mining_all_',
    'mining_rest_',
    'user_profile_',
    'config_global',
    'wallet_balance_',
    'privy_signer_',
  ];

  @override
  Future<void> purgeApiCache() async {
    if (!box.isOpen) return;
    try {
      await vacuumCache();
      final keysToDelete = <dynamic>[];
      for (final key in box.keys) {
        final keyStr = key.toString();
        if (apiCacheKeyPrefixes.any((prefix) => keyStr.startsWith(prefix))) {
          keysToDelete.add(key);
        }
      }
      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
      }
      await box.compact();
      StoryLogger.i(
        'purgeApiCache: removed ${keysToDelete.length} keys '
        '(entries=${box.length}).',
        tag: 'StoryLocalRepository',
      );
    } catch (e) {
      StoryLogger.w(
        'Failed to purge Hive API cache: $e',
        tag: 'StoryLocalRepository',
      );
    }
  }

  @override
  Future<int> getCacheFileSize() async {
    try {
      final path = box.path;
      if (path == null) return 0;
      final file = io.File(path);
      if (await file.exists()) return await file.length();
    } catch (e) {
      StoryLogger.d(
        'Failed to read Hive box file size',
        error: e,
        tag: 'StoryLocalRepository',
      );
    }
    return 0;
  }

  @override
  String? getToken() {
    // Sync read from flutter_secure_storage is not supported on all platforms;
    // use getTokenAsync for guaranteed correctness, or cachedToken for the
    // in-memory value populated during init() or saveToken().
    return null;
  }

  @override
  Future<String?> getTokenAsync() async {
    if (_tokenCache != null) return _tokenCache;
    try {
      _tokenCache = await _secureStorage.read(key: _tokenKey);
      return _tokenCache;
    } catch (e, st) {
      StoryLogger.w(
        'Failed to read token from secure storage',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
      return null;
    }
  }

  @override
  Future<void> saveToken(String token) async {
    _tokenCache = token;
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e, st) {
      StoryLogger.e(
        'Failed to save token to secure storage',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
    }
  }

  @override
  Future<void> clearToken() async {
    _tokenCache = null;
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (e, st) {
      StoryLogger.w(
        'Failed to clear token from secure storage',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
    }
  }

  @override
  UserProfile? getUser() {
    final raw = box.get('userProfile');
    if (raw is Map) {
      try {
        return UserProfile.fromJson(Map<String, dynamic>.from(raw));
      } catch (e, st) {
        StoryLogger.w(
          'Failed to decode cached user',
          error: e,
          stackTrace: st,
          tag: 'StoryLocalRepository',
        );
      }
    }
    return null;
  }

  @override
  Future<void> saveUser(UserProfile user) async {
    await box.put('userProfile', user.toJson());
  }

  @override
  Future<void> clearUser() async {
    await box.delete('userProfile');
  }

  @override
  List<String> getWatchlist() {
    final raw = box.get('watchlist');
    if (raw is List) return raw.whereType<String>().toList();
    return [];
  }

  @override
  Future<void> addToWatchlist(String dramaId) async {
    final list = getWatchlist();
    if (!list.contains(dramaId)) {
      list.add(dramaId);
      await box.put('watchlist', list);
    }
  }

  @override
  Future<void> removeFromWatchlist(String dramaId) async {
    final list = getWatchlist()..remove(dramaId);
    await box.put('watchlist', list);
  }

  @override
  Future<bool> toggleWatchlist(String dramaId) async {
    if (isFavorite(dramaId)) {
      await removeFromWatchlist(dramaId);
      return false;
    }
    await addToWatchlist(dramaId);
    return true;
  }

  @override
  bool isFavorite(String dramaId) => getWatchlist().contains(dramaId);

  @override
  List<String> getSearchHistory() {
    final raw = box.get('search_history');
    if (raw is List) return raw.whereType<String>().toList();
    return [];
  }

  static const _searchHistoryLimit = 10;

  @override
  Future<void> addSearchHistory(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    final list = getSearchHistory()..remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > _searchHistoryLimit) {
      list.removeRange(_searchHistoryLimit, list.length);
    }
    await box.put('search_history', list);
  }

  @override
  Future<void> removeSearchHistory(String keyword) async {
    final list = getSearchHistory()..remove(keyword.trim());
    await box.put('search_history', list);
  }

  @override
  Future<void> clearSearchHistory() async {
    await box.delete('search_history');
  }

  @override
  int getWatchProgress(String dramaId, int episodeNo) {
    final raw = box.get('watch_progress_$dramaId');
    if (raw is Map) {
      final epKey = 'ep$episodeNo';
      final v = raw[epKey];
      if (v is int) return v;
      if (v is num) return v.toInt();
    }
    return 0;
  }

  @override
  Future<void> saveWatchProgress(
    String dramaId,
    int episodeNo,
    int milliseconds,
  ) async {
    final key = 'watch_progress_$dramaId';
    final raw = box.get(key);
    final map = (raw is Map)
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    map['ep$episodeNo'] = milliseconds;
    await box.put(key, map);
  }

  @override
  Future<void> clearWatchProgress(String dramaId, int episodeNo) async {
    final key = 'watch_progress_$dramaId';
    final raw = box.get(key);
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      map.remove('ep$episodeNo');
      await box.put(key, map);
    }
  }

  @override
  Future<void> clearAllWatchProgress(String dramaId) async {
    final key = 'watch_progress_$dramaId';
    if (box.containsKey(key)) {
      await box.delete(key);
    }
  }

  @override
  String? getSolanaWalletAddress() {
    return null; // Use getSolanaWalletAddressAsync for secure storage
  }

  @override
  Future<String?> getSolanaWalletAddressAsync() async {
    try {
      return await _secureStorage.read(key: _walletKey);
    } catch (e, st) {
      StoryLogger.w(
        'Failed to read wallet address from secure storage',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
      return null;
    }
  }

  @override
  Future<void> saveSolanaWalletAddress(String address) async {
    try {
      await _secureStorage.write(key: _walletKey, value: address);
    } catch (e, st) {
      StoryLogger.e(
        'Failed to save wallet address to secure storage',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
    }
  }

  @override
  Future<void> clearSolanaWalletAddress() async {
    try {
      await _secureStorage.delete(key: _walletKey);
    } catch (e, st) {
      StoryLogger.w(
        'Failed to clear wallet address from secure storage',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
    }
  }

  @override
  String? getEthereumWalletAddress() {
    return null;
  }

  @override
  Future<String?> getEthereumWalletAddressAsync() async {
    try {
      return await _secureStorage.read(key: _evmWalletKey);
    } catch (e, st) {
      StoryLogger.w(
        'Failed to read EVM wallet address from secure storage',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
      return null;
    }
  }

  @override
  Future<void> saveEthereumWalletAddress(String address) async {
    try {
      await _secureStorage.write(key: _evmWalletKey, value: address);
    } catch (e, st) {
      StoryLogger.e(
        'Failed to save EVM wallet address to secure storage',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
    }
  }

  @override
  Future<void> clearEthereumWalletAddress() async {
    try {
      await _secureStorage.delete(key: _evmWalletKey);
    } catch (e, st) {
      StoryLogger.w(
        'Failed to clear EVM wallet address from secure storage',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
    }
  }

  @override
  LocaleInfo? getLocale() {
    final raw = box.get('locale');
    if (raw is Map) {
      return LocaleInfo(
        languageCode: asStringOrNull(raw['languageCode']) ?? 'zh',
        countryCode: asStringOrNull(raw['countryCode']),
      );
    }
    return null;
  }

  @override
  Future<void> setLocale(LocaleInfo locale) async {
    await box.put('locale', {
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode,
    });
  }

  @override
  String getThemeMode() {
    final raw = box.get('themeMode');
    if (raw is String && ['light', 'dark', 'system'].contains(raw)) {
      return raw;
    }
    return 'system';
  }

  @override
  Future<void> setThemeMode(String mode) async {
    await box.put('themeMode', mode);
  }

  @override
  CreateDramaDraft? getCreateDramaDraft() {
    final raw = box.get('create_drama_draft');
    if (raw == null) return null;
    try {
      return CreateDramaDraft.fromMap(raw);
    } catch (e, st) {
      StoryLogger.w(
        'Failed to decode create drama draft',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
      return null;
    }
  }

  @override
  Future<void> saveCreateDramaDraft(CreateDramaDraft draft) async {
    try {
      await box.put('create_drama_draft', draft.toMap());
    } catch (e, st) {
      StoryLogger.w(
        'Failed to save create drama draft',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
    }
  }

  @override
  Future<void> clearCreateDramaDraft() async {
    try {
      await box.delete('create_drama_draft');
    } catch (e, st) {
      StoryLogger.w(
        'Failed to clear create drama draft',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
    }
  }

  @override
  PublishVideoDraft? getPublishVideoDraft() {
    final raw = box.get('publish_video_draft');
    if (raw == null) return null;
    try {
      return PublishVideoDraft.fromMap(raw);
    } catch (e, st) {
      StoryLogger.w(
        'Failed to decode publish video draft',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
      return null;
    }
  }

  @override
  Future<void> savePublishVideoDraft(PublishVideoDraft draft) async {
    try {
      await box.put('publish_video_draft', draft.toMap());
    } catch (e, st) {
      StoryLogger.w(
        'Failed to save publish video draft',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
    }
  }

  @override
  Future<void> clearPublishVideoDraft() async {
    try {
      await box.delete('publish_video_draft');
    } catch (e, st) {
      StoryLogger.w(
        'Failed to clear publish video draft',
        error: e,
        stackTrace: st,
        tag: 'StoryLocalRepository',
      );
    }
  }

  @override
  Future<void> dispose() async {
    await disposeBox();
    StoryLogger.d(
      'StoryLocalRepositoryImpl disposed',
      tag: 'StoryLocalRepository',
    );
  }
}
