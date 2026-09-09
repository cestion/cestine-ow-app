import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_persist_policy.dart';
import 'package:story_app/src/model/work_content_type.dart';
import 'package:story_app/src/routes/route_args.dart';

void main() {
  group('FeedPersistPolicy', () {
    test('persists short drama from theater/detail', () {
      expect(
        FeedPersistPolicy.shouldPersistDramaCursor(
          const VideoFeedArgs(dramaId: 'd1', episodeNo: 1),
        ),
        isTrue,
      );
    });

    test('skips short video', () {
      expect(
        FeedPersistPolicy.shouldPersistDramaCursor(
          const VideoFeedArgs(
            dramaId: '',
            episodeId: 'sv1',
            contentType: WorkContentType.shortVideo,
            episodeNo: 1,
          ),
        ),
        isFalse,
      );
    });

    test('skips search drama playlist', () {
      expect(
        FeedPersistPolicy.shouldPersistDramaCursor(
          const VideoFeedArgs(
            dramaId: 'd1',
            episodeNo: 1,
            searchDramaPlaylist: true,
          ),
        ),
        isFalse,
      );
    });

    test('aligns persistWatchProgress cursor gate with page resume policy', () {
      // Short video and search-drama playlist must not write current_episode_*.
      expect(
        FeedPersistPolicy.shouldPersistDramaCursor(
          const VideoFeedArgs(
            dramaId: 'd1',
            episodeNo: 3,
            searchDramaPlaylist: true,
          ),
        ),
        isFalse,
      );
      expect(
        FeedPersistPolicy.shouldPersistDramaCursor(
          const VideoFeedArgs(
            dramaId: '',
            episodeId: 'sv1',
            contentType: WorkContentType.shortVideo,
            episodeNo: 1,
          ),
        ),
        isFalse,
      );
    });
  });
}
