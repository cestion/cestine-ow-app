import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/playlist_continuation.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/routes/route_args.dart';

void main() {
  group('PlaylistContinuationStore', () {
    late PlaylistContinuationStore store;

    setUp(() {
      store = PlaylistContinuationStore();
    });

    test('register / get / unregister are idempotent', () {
      final continuation = CallbackPlaylistContinuation(
        hasMoreCallback: () => true,
        loadMoreCallback: () async => Result.success(
          const PlaylistContinuationPage(entries: [], hasMore: false),
        ),
      );

      final id = store.register(continuation);
      expect(id, isNotEmpty);
      expect(store.get(id), same(continuation));
      expect(store.debugLength, 1);

      store.unregister(id);
      expect(store.get(id), isNull);
      expect(store.debugLength, 0);

      store.unregister(id);
      store.unregister(null);
      store.unregister('  ');
      expect(store.debugLength, 0);
    });

    test('clear removes every registration', () {
      store.register(
        CallbackPlaylistContinuation(
          hasMoreCallback: () => false,
          loadMoreCallback: () async => Result.success(
            const PlaylistContinuationPage(entries: [], hasMore: false),
          ),
        ),
      );
      store.register(
        CallbackPlaylistContinuation(
          hasMoreCallback: () => true,
          loadMoreCallback: () async => Result.success(
            const PlaylistContinuationPage(
              entries: [VideoFeedPlaylistEntry.shortVideo(episodeId: '1')],
              hasMore: false,
            ),
          ),
        ),
      );
      expect(store.debugLength, 2);
      store.clear();
      expect(store.debugLength, 0);
    });
  });
}
