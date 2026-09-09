import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/user_profile_content_model.dart';
import 'package:story_app/src/view/widgets/profile/profile_playback_entry_mapper.dart';

void main() {
  group('UserProfileContentItem.toDramaListItem poster', () {
    test('episode row prefers firstFrameUrl over drama cover', () {
      const item = UserProfileContentItem(
        type: 'SHORT_DRAMA',
        drama: UserProfileContentDrama(
          id: 'drama-1',
          title: 'Drama',
          coverUrl: 'https://cdn.example/drama-cover.jpg',
          contentType: 'SHORT_DRAMA',
          totalEpisodes: 10,
        ),
        episode: UserProfileContentEpisode(
          id: 'ep-1',
          episodeNo: 3,
          contentType: 'SHORT_DRAMA',
          coverUrl: 'https://cdn.example/ep-cover.jpg',
          firstFrameUrl: 'https://cdn.example/ep-frame.jpg',
        ),
      );

      expect(
        item.toDramaListItem().dramaCoverUrl,
        'https://cdn.example/ep-frame.jpg',
      );
      expect(item.episode!.posterUrl, 'https://cdn.example/ep-frame.jpg');
    });

    test('whole-series row keeps drama cover', () {
      const item = UserProfileContentItem(
        type: 'SHORT_DRAMA',
        drama: UserProfileContentDrama(
          id: 'drama-1',
          title: 'Drama',
          coverUrl: 'https://cdn.example/drama-cover.jpg',
          contentType: 'SHORT_DRAMA',
          totalEpisodes: 10,
        ),
      );

      expect(
        item.toDramaListItem().dramaCoverUrl,
        'https://cdn.example/drama-cover.jpg',
      );
    });
  });

  group('ProfilePlaybackEntryMapper', () {
    test('playlist coverUrl seeds firstFrameUrl for liked episode', () {
      const item = UserProfileContentItem(
        type: 'SHORT_DRAMA',
        likedByMe: true,
        drama: UserProfileContentDrama(
          id: 'drama-1',
          title: 'Drama',
          coverUrl: 'https://cdn.example/drama-cover.jpg',
          contentType: 'SHORT_DRAMA',
          totalEpisodes: 10,
        ),
        episode: UserProfileContentEpisode(
          id: 'ep-1',
          episodeNo: 2,
          contentType: 'SHORT_DRAMA',
          coverUrl: 'https://cdn.example/ep-cover.jpg',
          firstFrameUrl: 'https://cdn.example/ep-frame.jpg',
        ),
      );

      final entry = ProfilePlaybackEntryMapper.fromItem(
        item,
        resolveResumeEpisode: (_, _) => 1,
      );

      expect(entry, isNotNull);
      expect(entry!.coverUrl, 'https://cdn.example/ep-frame.jpg');
      expect(entry.expandEpisodes, isFalse);
      expect(entry.episodeId, 'ep-1');

      final args = entry.toFeedArgs(playlist: [entry], playlistIndex: 0);
      expect(args.coverUrl, 'https://cdn.example/ep-frame.jpg');
      expect(args.episodeCoverUrl, 'https://cdn.example/ep-frame.jpg');
    });

    test('short video coverUrl prefers firstFrameUrl', () {
      const item = UserProfileContentItem(
        type: 'SHORT_VIDEO',
        episode: UserProfileContentEpisode(
          id: 'sv-1',
          episodeNo: 1,
          contentType: 'SHORT_VIDEO',
          coverUrl: 'https://cdn.example/sv-cover.jpg',
          firstFrameUrl: 'https://cdn.example/sv-frame.jpg',
        ),
      );

      final entry = ProfilePlaybackEntryMapper.fromItem(
        item,
        resolveResumeEpisode: (_, _) => 1,
      );

      expect(entry, isNotNull);
      expect(entry!.isShortVideo, isTrue);
      expect(entry.coverUrl, 'https://cdn.example/sv-frame.jpg');
    });
  });
}
