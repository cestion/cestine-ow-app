import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/playlist_continuation_sync.dart';
import 'package:story_app/src/routes/route_args.dart';

void main() {
  VideoFeedPlaylistEntry? entryFor(String id) {
    if (id.startsWith('skip')) return null;
    return VideoFeedPlaylistEntry.shortVideo(episodeId: id);
  }

  group('collectUnseenPlaylistEntries', () {
    test('returns only unseen mapped entries and mutates seenKeys', () {
      final seen = {'SHORT_VIDEO:a'};
      final entries = collectUnseenPlaylistEntries<String>(
        items: const ['a', 'b', 'skip-x', 'c', 'b'],
        seenKeys: seen,
        toEntry: entryFor,
      );

      expect(entries.map((e) => e.episodeId), ['b', 'c']);
      expect(seen, {'SHORT_VIDEO:a', 'SHORT_VIDEO:b', 'SHORT_VIDEO:c'});
    });
  });

  group('syncPlaylistContinuation', () {
    test('returns parent-gap rows without calling loadMore', () async {
      var loadCalls = 0;
      final seen = {'SHORT_VIDEO:a'};
      final page = await syncPlaylistContinuation<String>(
        items: const ['a', 'b', 'c'],
        hasMore: true,
        isPageLoading: false,
        seenKeys: seen,
        toEntry: entryFor,
        loadMore: () async {
          loadCalls++;
        },
        readItems: () => const ['a', 'b', 'c'],
        readHasMore: () => true,
        readIsPageLoading: () => false,
      );

      expect(loadCalls, 0);
      expect(page.entries.map((e) => e.episodeId), ['b', 'c']);
      expect(page.hasMore, isTrue);
    });

    test('loadMore then converges hasMore when still empty', () async {
      var loadCalls = 0;
      final seen = {'SHORT_VIDEO:a', 'SHORT_VIDEO:b'};
      final items = <String>['a', 'b'];
      final page = await syncPlaylistContinuation<String>(
        items: items,
        hasMore: true,
        isPageLoading: false,
        seenKeys: seen,
        toEntry: entryFor,
        loadMore: () async {
          loadCalls++;
          // Parent grew but every new row is filtered out.
          items.addAll(const ['skip-1', 'skip-2']);
        },
        readItems: () => items,
        readHasMore: () => true,
        readIsPageLoading: () => false,
      );

      expect(loadCalls, 1);
      expect(page.entries, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('waits for in-flight parent load then diffs full list', () async {
      var loadCalls = 0;
      var loading = true;
      final seen = {'SHORT_VIDEO:a'};
      final items = <String>['a'];

      // Simulate parent finishing a grid loadMore shortly after we sync.
      Future<void>.delayed(const Duration(milliseconds: 30), () {
        items.addAll(const ['b', 'c']);
        loading = false;
      });

      final page = await syncPlaylistContinuation<String>(
        items: items,
        hasMore: true,
        isPageLoading: true,
        seenKeys: seen,
        toEntry: entryFor,
        loadMore: () async {
          loadCalls++;
        },
        readItems: () => items,
        readHasMore: () => true,
        readIsPageLoading: () => loading,
        pollInterval: const Duration(milliseconds: 10),
        loadingTimeout: const Duration(seconds: 1),
      );

      expect(loadCalls, 0);
      expect(page.entries.map((e) => e.episodeId), ['b', 'c']);
      expect(page.hasMore, isTrue);
    });

    test('keeps distinct concrete episodes of the same drama', () async {
      VideoFeedPlaylistEntry? toEntry(String raw) {
        final parts = raw.split(':');
        return VideoFeedPlaylistEntry.drama(
          dramaId: parts[0],
          episodeId: parts[1],
          episodeNo: int.parse(parts[2]),
        );
      }

      final seen = {'SHORT_DRAMA:d1:ep-1'};
      final page = await syncPlaylistContinuation<String>(
        items: const ['d1:ep-1:1', 'd1:ep-2:2', 'd1:ep-3:3'],
        hasMore: false,
        isPageLoading: false,
        seenKeys: seen,
        toEntry: toEntry,
        loadMore: () async {},
        readItems: () => const ['d1:ep-1:1', 'd1:ep-2:2', 'd1:ep-3:3'],
        readHasMore: () => false,
        readIsPageLoading: () => false,
      );

      expect(page.entries.map((e) => e.episodeId), ['ep-2', 'ep-3']);
      expect(page.hasMore, isFalse);
    });

    test('hasMore false with no unseen rows returns empty page', () async {
      var loadCalls = 0;
      final seen = {'SHORT_VIDEO:a'};
      final page = await syncPlaylistContinuation<String>(
        items: const ['a'],
        hasMore: false,
        isPageLoading: false,
        seenKeys: seen,
        toEntry: entryFor,
        loadMore: () async {
          loadCalls++;
        },
        readItems: () => const ['a'],
        readHasMore: () => false,
        readIsPageLoading: () => false,
      );

      expect(loadCalls, 0);
      expect(page.entries, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });
}
