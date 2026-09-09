import 'dart:async';
import 'dart:collection';
import 'package:hive/hive.dart';

import 'json_helpers.dart';
import 'result.dart';
import 'story_logger.dart';

// ignore_for_file: prefer_initializing_formals
// Private field assignment from public params is intentional.

/// ──────────────────────────────────────────────
/// Cache abstraction for repository caching
/// ──────────────────────────────────────────────

/// Generic cache layer interface.
abstract class CacheLayer<K, V> {
  Future<V?> get(K key);
  Future<void> set(K key, V value);
  Future<void> evict(K key);
  Future<void> clear();
}

/// In-memory LRU cache with max-size eviction and optional TTL.
class MemoryCacheLayer<K, V> extends CacheLayer<K, V> {
  final int maxEntries;
  final Duration? defaultTtl;
  final LinkedHashMap<K, V> _cache = LinkedHashMap();
  final Map<K, int> _expiresAt = {};

  MemoryCacheLayer({this.maxEntries = 50, this.defaultTtl});

  bool _isExpired(K key) {
    final expiresAt = _expiresAt[key];
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch > expiresAt;
  }

  @override
  Future<V?> get(K key) async => peek(key);

  /// Synchronous LRU read for stale-while-revalidate first paint.
  V? peek(K key) {
    if (_isExpired(key)) {
      _cache.remove(key);
      _expiresAt.remove(key);
      return null;
    }
    final value = _cache[key];
    if (value != null) {
      _cache.remove(key);
      _cache[key] = value;
    }
    return value;
  }

  @override
  Future<void> set(K key, V value, {Duration? ttl}) async {
    final effectiveTtl = ttl ?? defaultTtl;
    // LinkedHashMap 的 `[key]=value` 对已存在 key 不会改变插入顺序，
    // refresh 同一 key 后 oldest 仍是它本身，导致它被下次 evict 而不是较老
    // 项。先 remove 再 set,把新访问过的 key 推到队尾,保持正确的 LRU 顺序。
    _cache.remove(key);
    _cache[key] = value;
    if (_cache.length > maxEntries) {
      final oldest = _cache.keys.first;
      _cache.remove(oldest);
      _expiresAt.remove(oldest);
    }
    if (effectiveTtl != null) {
      _expiresAt[key] = DateTime.now().add(effectiveTtl).millisecondsSinceEpoch;
    }
  }

  @override
  Future<void> evict(K key) async {
    _cache.remove(key);
    _expiresAt.remove(key);
  }

  @override
  Future<void> clear() async {
    _cache.clear();
    _expiresAt.clear();
  }
}

/// Hive-backed persistent cache with optional TTL.
class HiveCacheLayer<V> extends CacheLayer<String, V> {
  final Box<dynamic> _box;
  final Duration defaultTtl;
  final String _prefix;
  final V Function(Object? data)? _decoder;
  final Object? Function(V value)? _encoder;

  HiveCacheLayer({
    required Box<dynamic> box,
    this.defaultTtl = const Duration(minutes: 5),
    String prefix = 'cache_',
    V Function(Object? data)? decoder,
    Object? Function(V value)? encoder,
  }) : _box = box,
       _prefix = prefix,
       _decoder = decoder,
       _encoder = encoder;

  String _key(String raw) => '$_prefix$raw';

  @override
  Future<V?> get(String key) async => peekSync(key);

  /// Synchronous Hive read for cold-start SWR without awaiting the event loop.
  V? peekSync(String key) {
    final raw = _box.get(_key(key));
    if (raw is! Map) return null;
    final expiresAt = asIntOrNull(raw['expiresAt']);
    if (expiresAt != null &&
        DateTime.now().millisecondsSinceEpoch > expiresAt) {
      unawaited(_box.delete(_key(key)));
      return null;
    }
    final data = raw['data'];
    final decoder = _decoder;
    if (decoder != null) return decoder(data);
    if (data is V) return data;
    return null;
  }

  @override
  Future<void> set(String key, V value, {Duration? ttl}) async {
    final encoder = _encoder;
    await _box.put(_key(key), <dynamic, dynamic>{
      'data': encoder == null ? value : encoder(value),
      'expiresAt': DateTime.now().add(ttl ?? defaultTtl).millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> evict(String key) async {
    await _box.delete(_key(key));
  }

  @override
  Future<void> clear() async {
    final keys = _box.keys
        .where((k) => k.toString().startsWith(_prefix))
        .toList();
    for (final k in keys) {
      await _box.delete(k);
    }
  }
}

/// Legacy Hive cache format support (compatible with existing cached data).
class LegacyHiveCacheLayer<V> extends CacheLayer<String, V> {
  final Box<dynamic> _box;
  final Duration defaultTtl;
  final String _prefix;

  LegacyHiveCacheLayer({
    required Box<dynamic> box,
    this.defaultTtl = const Duration(minutes: 5),
    String prefix = 'cache_',
  }) : _box = box,
       _prefix = prefix;

  String _key(String raw) => '$_prefix$raw';

  @override
  Future<V?> get(String key) async {
    final raw = _box.get(_key(key));
    if (raw is Map) {
      // Legacy format: {data, cachedAt, ttlMs}
      final cachedAt = asIntOrNull(raw['cachedAt']);
      final ttlMs = asIntOrNull(raw['ttlMs']);
      if (cachedAt != null &&
          ttlMs != null &&
          DateTime.now().millisecondsSinceEpoch > cachedAt + ttlMs) {
        await _box.delete(_key(key));
        return null;
      }
      // Legacy: data stored in `data` field
      final data = raw['data'];
      if (data is V) return data;
      // Legacy: raw map IS the value (no `data` wrapper)
      if (data == null &&
          raw.containsKey('cachedAt') == false &&
          raw.containsKey('ttlMs') == false) {
        return raw as V;
      }
    }
    if (raw is V) return raw;
    return null;
  }

  @override
  Future<void> set(String key, V value, {Duration? ttl}) async {
    final effectiveTtl = ttl ?? defaultTtl;
    await _box.put(_key(key), <dynamic, dynamic>{
      'data': value,
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
      'ttlMs': effectiveTtl.inMilliseconds,
    });
  }

  @override
  Future<void> evict(String key) async {
    await _box.delete(_key(key));
  }

  @override
  Future<void> clear() async {
    final keys = _box.keys
        .where((k) => k.toString().startsWith(_prefix))
        .toList();
    for (final k in keys) {
      await _box.delete(k);
    }
  }
}

/// Multi-layer read-through cache.
///
/// Tries layers in order (e.g. memory → Hive → network).
/// Returns the first hit. On miss, fetches via [fetcher] and populates
/// all writeable layers.
///
/// [fetchTimeout] is a safety net for the in-flight dedup map: if a
/// fetch hangs beyond this duration, the caller returns a timeout error
/// and subsequent requests for the same key will retry instead of
/// waiting forever on the stale future. Defaults to 90s (60s API
/// receive + 15s connect + 15s buffer).
class CacheChain<K, V> {
  final List<CacheLayer<K, V>> _readLayers;
  final List<CacheLayer<K, V>> _writeLayers;
  final Future<Result<V>> Function(K key) fetcher;
  final Map<K, Future<Result<V>>> _inFlight = {};
  final Duration fetchTimeout;

  CacheChain({
    required this.fetcher,
    List<CacheLayer<K, V>> readLayers = const [],
    List<CacheLayer<K, V>> writeLayers = const [],
    this.fetchTimeout = const Duration(seconds: 90),
  }) : _readLayers = readLayers,
       _writeLayers = writeLayers;

  /// Read-through: check layers → fetch → populate.
  Future<Result<V>> get(K key) async {
    for (var i = 0; i < _readLayers.length; i++) {
      final layer = _readLayers[i];
      try {
        final cached = await layer.get(key);
        if (cached != null) {
          // Promote Hive hits into faster memory layers.
          for (var j = 0; j < i; j++) {
            _readLayers[j].set(key, cached).catchError((Object e) {
              StoryLogger.w(
                'Cache layer promote error',
                error: e,
                tag: 'CacheChain',
              );
            });
          }
          return Result.success(cached);
        }
      } catch (e) {
        StoryLogger.w('Cache layer read error', error: e, tag: 'CacheChain');
      }
    }

    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = _fetchAndPopulate(key);
    _inFlight[key] = future;
    try {
      return await future.timeout(fetchTimeout);
    } on TimeoutException {
      _inFlight.remove(key);
      StoryLogger.w(
        'CacheChain fetch timed out for key=$key',
        tag: 'CacheChain',
      );
      return Result<V>.failure(
        ApiError.timeout('Cache fetch timed out after $fetchTimeout'),
      );
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Local-only lookup: memory → Hive (etc.), never hits the network.
  ///
  /// Returns `null` on miss. Does not populate layers from a fetcher.
  Future<V?> getCachedOnly(K key) async {
    for (var i = 0; i < _readLayers.length; i++) {
      final layer = _readLayers[i];
      try {
        final cached = await layer.get(key);
        if (cached != null) {
          for (var j = 0; j < i; j++) {
            _readLayers[j].set(key, cached).catchError((Object e) {
              StoryLogger.w(
                'Cache layer promote error',
                error: e,
                tag: 'CacheChain',
              );
            });
          }
          return cached;
        }
      } catch (e) {
        StoryLogger.w('Cache layer read error', error: e, tag: 'CacheChain');
      }
    }
    return null;
  }

  Future<Result<V>> _fetchAndPopulate(K key) async {
    final result = await fetcher(key);
    if (result.isSuccess) {
      final value = result.dataOrNull;
      if (value == null) return result;
      for (final layer in _writeLayers) {
        layer.set(key, value).catchError((Object e) {
          StoryLogger.w('Cache layer write error', error: e, tag: 'CacheChain');
        });
      }
    }
    return result;
  }

  /// Write value into all write layers without fetching.
  Future<void> put(K key, V value) async {
    for (final layer in _writeLayers) {
      try {
        await layer.set(key, value);
      } catch (e) {
        StoryLogger.w('Cache layer put error', error: e, tag: 'CacheChain');
      }
    }
  }

  /// Evict key from all layers.
  Future<void> evict(K key) async {
    for (final layer in [..._readLayers, ..._writeLayers]) {
      try {
        await layer.evict(key);
      } catch (e) {
        StoryLogger.w('Cache evict error', error: e, tag: 'CacheChain');
      }
    }
  }

  /// Clear all layers.
  Future<void> clear() async {
    for (final layer in [..._readLayers, ..._writeLayers]) {
      try {
        await layer.clear();
      } catch (e) {
        StoryLogger.w('Cache clear error', error: e, tag: 'CacheChain');
      }
    }
  }
}

/// Convenience: TTL cache backed by Hive only.
class TtlCache<V> {
  final LegacyHiveCacheLayer<V> _layer;

  TtlCache({
    required Box<dynamic> box,
    Duration defaultTtl = const Duration(minutes: 5),
    String prefix = 'ttl_',
  }) : _layer = LegacyHiveCacheLayer(
         box: box,
         defaultTtl: defaultTtl,
         prefix: prefix,
       );

  Future<V?> get(String key) => _layer.get(key);
  Future<void> set(String key, V value, {Duration? ttl}) =>
      _layer.set(key, value, ttl: ttl);
  Future<void> evict(String key) => _layer.evict(key);
  Future<void> clear() => _layer.clear();
}

/// Unchecked convenience for non-nullable gets.
extension TtlCacheX<T> on TtlCache<T> {
  Future<T> require(String key) async {
    final value = await get(key);
    if (value == null) throw StateError('Cache miss: $key');
    return value;
  }
}
