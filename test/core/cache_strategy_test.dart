import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/cache_strategy.dart';
import 'package:story_app/src/core/result.dart';

void main() {
  group('MemoryCacheLayer', () {
    late MemoryCacheLayer<String, String> cache;

    setUp(() {
      cache = MemoryCacheLayer<String, String>(maxEntries: 3);
    });

    test('get returns null on miss', () async {
      expect(await cache.get('missing'), isNull);
    });

    test('set and get round-trip', () async {
      await cache.set('a', 'aval');
      expect(await cache.get('a'), 'aval');
    });

    test('LRU evicts oldest when maxEntries exceeded', () async {
      await cache.set('a', '1');
      await cache.set('b', '2');
      await cache.set('c', '3');
      await cache.set('d', '4');

      expect(await cache.get('a'), isNull);
      expect(await cache.get('b'), '2');
      expect(await cache.get('d'), '4');
    });

    test('get refreshes LRU order', () async {
      await cache.set('a', '1');
      await cache.set('b', '2');
      await cache.set('c', '3');
      await cache.get('a');
      await cache.set('d', '4');

      expect(await cache.get('a'), '1');
      expect(await cache.get('b'), isNull);
    });

    test('evict removes key', () async {
      await cache.set('a', '1');
      await cache.evict('a');
      expect(await cache.get('a'), isNull);
    });

    test('clear removes all entries', () async {
      await cache.set('a', '1');
      await cache.set('b', '2');
      await cache.clear();
      expect(await cache.get('a'), isNull);
      expect(await cache.get('b'), isNull);
    });

    test('set overwrites existing value', () async {
      await cache.set('a', '1');
      await cache.set('a', '2');
      expect(await cache.get('a'), '2');
    });
  });

  group('CacheChain', () {
    late MemoryCacheLayer<String, String> memory;
    late CacheChain<String, String> chain;
    int fetchCount = 0;

    setUp(() {
      fetchCount = 0;
      memory = MemoryCacheLayer<String, String>(maxEntries: 10);
    });

    test('returns from memory on hit, skips fetcher', () async {
      await memory.set('k', 'cached');
      chain = CacheChain(
        fetcher: (k) async {
          fetchCount++;
          return Result.success('from_network');
        },
        readLayers: [memory],
        writeLayers: [memory],
      );

      final result = await chain.get('k');
      expect(result.dataOrNull, 'cached');
      expect(fetchCount, 0);
    });

    test('put writes to write layers without fetching', () async {
      chain = CacheChain(
        fetcher: (k) async {
          fetchCount++;
          return Result.success('from_network');
        },
        readLayers: [memory],
        writeLayers: [memory],
      );

      await chain.put('k', 'seeded');
      final result = await chain.get('k');
      expect(result.dataOrNull, 'seeded');
      expect(fetchCount, 0);
    });

    test('fetches from source on miss and populates write layers', () async {
      chain = CacheChain(
        fetcher: (k) async => Result.success('from_network'),
        readLayers: [memory],
        writeLayers: [memory],
      );

      final result = await chain.get('k');
      expect(result.dataOrNull, 'from_network');
      expect(await memory.get('k'), 'from_network');
    });

    test('propagates fetcher failure without writing', () async {
      chain = CacheChain(
        fetcher: (k) async => Result.failure(ApiError.network('fail')),
        readLayers: [memory],
        writeLayers: [memory],
      );

      final result = await chain.get('k');
      expect(result.isFailure, true);
      expect(await memory.get('k'), isNull);
    });

    test('evict removes key from all layers', () async {
      await memory.set('k', 'v');
      chain = CacheChain(
        fetcher: (k) async => Result.success('x'),
        readLayers: [memory],
        writeLayers: [memory],
      );
      await chain.evict('k');
      expect(await memory.get('k'), isNull);
    });

    test('clear removes all keys from all layers', () async {
      await memory.set('a', '1');
      await memory.set('b', '2');
      chain = CacheChain(
        fetcher: (k) async => Result.success('x'),
        readLayers: [memory],
        writeLayers: [memory],
      );
      await chain.clear();
      expect(await memory.get('a'), isNull);
      expect(await memory.get('b'), isNull);
    });

    test('getCachedOnly returns local hit without fetching', () async {
      await memory.set('k', 'cached');
      chain = CacheChain(
        fetcher: (k) async {
          fetchCount++;
          return Result.success('from_network');
        },
        readLayers: [memory],
        writeLayers: [memory],
      );

      expect(await chain.getCachedOnly('k'), 'cached');
      expect(fetchCount, 0);
    });

    test('getCachedOnly returns null on miss without fetching', () async {
      chain = CacheChain(
        fetcher: (k) async {
          fetchCount++;
          return Result.success('from_network');
        },
        readLayers: [memory],
        writeLayers: [memory],
      );

      expect(await chain.getCachedOnly('missing'), isNull);
      expect(fetchCount, 0);
    });

    test('handles cache layer read error gracefully', () async {
      final badLayer = _FailingReadLayer();
      chain = CacheChain(
        fetcher: (k) async => Result.success('from_network'),
        readLayers: [badLayer, memory],
        writeLayers: [memory],
      );

      final result = await chain.get('k');
      expect(result.dataOrNull, 'from_network');
    });
  });
}

class _FailingReadLayer extends CacheLayer<String, String> {
  @override
  Future<String?> get(String key) async => throw Exception('read failure');
  @override
  Future<void> set(String key, String value) async {}
  @override
  Future<void> evict(String key) async {}
  @override
  Future<void> clear() async {}
}
