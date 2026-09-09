import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/cache_strategy.dart';
import 'package:story_app/src/model/recommend_feed_model.dart';
import 'package:story_app/src/services/playback_frame_cache_service.dart';

void main() {
  group('PlaybackFrameCacheService', () {
    test('peek returns hot memory entries after put', () async {
      final service = PlaybackFrameCacheService.instance;
      const key = 'test_playback_peek';
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      await service.put(key, bytes);
      expect(service.peek(key), bytes);

      await service.clear();
    });

    test('get returns memory without disk when hot', () async {
      final service = PlaybackFrameCacheService.instance;
      const key = 'test_playback_get';
      final bytes = Uint8List.fromList([9, 8, 7]);

      await service.put(key, bytes);
      final loaded = await service.get(key);
      expect(loaded, bytes);

      await service.clear();
    });

    test('revisions bump when a frame is stored', () async {
      final service = PlaybackFrameCacheService.instance;
      final before = service.revisions.value;
      await service.put('test_playback_rev', Uint8List.fromList([0, 1]));
      expect(service.revisions.value, greaterThan(before));

      await service.clear();
    });
  });

  group('frameCacheKey unified scheme', () {
    test('drama episode: dramaId:episodeId when both present and differ', () {
      expect(
        PlaybackFrameCacheService.frameCacheKey(
          dramaId: 'drama1',
          episodeId: 'ep9',
          episodeNo: 9,
        ),
        'drama1:ep9',
      );
    });

    test('short video: episodeId alone when no dramaId', () {
      expect(
        PlaybackFrameCacheService.frameCacheKey(
          dramaId: '',
          episodeId: 'sv_abc',
          episodeNo: 1,
        ),
        'sv_abc',
      );
    });

    test('short video: episodeId alone when dramaId == episodeId', () {
      expect(
        PlaybackFrameCacheService.frameCacheKey(
          dramaId: 'same_id',
          episodeId: 'same_id',
          episodeNo: 1,
        ),
        'same_id',
      );
    });

    test(
      'short drama fallback: dramaId_ep\$episodeNo when episodeId missing',
      () {
        expect(
          PlaybackFrameCacheService.frameCacheKey(
            dramaId: 'drama1',
            episodeNo: 3,
          ),
          'drama1_ep3',
        );
      },
    );

    test('dramaId only when nothing else is available', () {
      expect(
        PlaybackFrameCacheService.frameCacheKey(dramaId: 'drama1'),
        'drama1',
      );
    });

    test('trims surrounding whitespace', () {
      expect(
        PlaybackFrameCacheService.frameCacheKey(
          dramaId: '  drama1 ',
          episodeId: ' ep9 ',
          episodeNo: 9,
        ),
        'drama1:ep9',
      );
    });

    test('agrees with RecommendFeedItem.playbackId on the shared branches '
        '(cross-entry cache sharing guarantee)', () {
      // Drama episode: both builders emit dramaId:episodeId.
      expect(
        PlaybackFrameCacheService.frameCacheKey(
          dramaId: 'd1',
          episodeId: 'e2',
          episodeNo: 9,
        ),
        const RecommendFeedItem(dramaId: 'd1', episodeId: 'e2').playbackId,
      );
      // Short video without series id.
      expect(
        PlaybackFrameCacheService.frameCacheKey(
          dramaId: '',
          episodeId: 'e2',
          episodeNo: 9,
        ),
        const RecommendFeedItem(dramaId: '', episodeId: 'e2').playbackId,
      );
      // Short video where dramaId == episodeId.
      expect(
        PlaybackFrameCacheService.frameCacheKey(
          dramaId: 'same',
          episodeId: 'same',
          episodeNo: 9,
        ),
        const RecommendFeedItem(dramaId: 'same', episodeId: 'same').playbackId,
      );
    });
  });

  group('MemoryCacheLayer (frame cache backing)', () {
    test('evicts oldest entry when over maxEntries', () async {
      final cache = MemoryCacheLayer<String, Uint8List>(maxEntries: 2);
      await cache.set('a', Uint8List(1));
      await cache.set('b', Uint8List(2));
      await cache.set('c', Uint8List(3));

      expect(await cache.get('a'), isNull);
      expect(await cache.get('b'), isNotNull);
      expect(await cache.get('c'), isNotNull);
    });
  });
}
