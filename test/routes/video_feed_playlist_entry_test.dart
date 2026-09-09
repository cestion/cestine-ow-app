import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/routes/route_args.dart';

void main() {
  group('VideoFeedPlaylistEntry.playbackKey', () {
    test('short videos key by episode id', () {
      expect(
        const VideoFeedPlaylistEntry.shortVideo(episodeId: 'e1').playbackKey,
        'SHORT_VIDEO:e1',
      );
    });

    test('whole-drama expand keys by drama id only', () {
      expect(
        const VideoFeedPlaylistEntry.drama(
          dramaId: 'd1',
          expandEpisodes: true,
          totalEpisodes: 3,
        ).playbackKey,
        'SHORT_DRAMA:d1',
      );
    });

    test('concrete drama episodes of the same series stay distinct', () {
      const a = VideoFeedPlaylistEntry.drama(dramaId: 'd1', episodeId: 'ep-1');
      const b = VideoFeedPlaylistEntry.drama(
        dramaId: 'd1',
        episodeId: 'ep-2',
        episodeNo: 2,
      );
      expect(a.playbackKey, 'SHORT_DRAMA:d1:ep-1');
      expect(b.playbackKey, 'SHORT_DRAMA:d1:ep-2');
      expect(a.playbackKey, isNot(b.playbackKey));
    });

    test('concrete episode without id falls back to episodeNo', () {
      expect(
        const VideoFeedPlaylistEntry.drama(
          dramaId: 'd1',
          episodeNo: 4,
        ).playbackKey,
        'SHORT_DRAMA:d1#4',
      );
    });
  });
}
