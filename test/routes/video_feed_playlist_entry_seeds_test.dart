import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/routes/route_args.dart';
import 'package:story_app/src/routes/video_feed_playlist_entry_seeds.dart';

void main() {
  group('VideoFeedPlaylistEntrySeeds', () {
    test('mergePlay prefers play engagement over list-row chrome', () {
      const row = VideoFeedPlaylistEntry.drama(
        dramaId: 'd1',
        likedByMe: false,
        likeCount: 1,
        creatorName: 'Card',
      );
      const play = DramaPlayResponse(
        likedByMe: true,
        likeCount: 9,
        userId: 'author-1',
      );

      final merged = row.mergePlay(play);

      expect(merged.likedByMe, isTrue);
      expect(merged.likeCount, 9);
      expect(merged.creatorName, 'Card');
      expect(merged.creatorUserId, 'author-1');
    });

    test('shortVideoFromFeedItem carries engagement fields', () {
      final entry = VideoFeedPlaylistEntrySeeds.shortVideoFromFeedItem(
        const FeedItem(
          contentType: 'SHORT_VIDEO',
          episodeId: 'ep1',
          likedByMe: true,
          likeCount: 3,
        ),
        episodeId: 'ep1',
        title: 'T',
      );

      expect(entry.likedByMe, isTrue);
      expect(entry.likeCount, 3);
      expect(entry.episodeId, 'ep1');
    });
    test('fromDramaDetail carries roles for player rail', () {
      const role = RoleCharacter(
        name: '女主',
        boundActorCollectionId: 'ac2',
        boundActorName: '林晚',
      );
      final entry = VideoFeedPlaylistEntrySeeds.fromDramaDetail(
        const DramaDetail(id: 'd1', roles: [role]),
        dramaId: 'd1',
      );

      expect(entry.roles, hasLength(1));
      expect(entry.roles!.single.boundActorName, '林晚');
    });

    test('fromDramaListItem maps actorCollections to rail briefs', () {
      final entry = VideoFeedPlaylistEntrySeeds.fromDramaListItem(
        const DramaListItem(
          id: 'd1',
          actorCollections: [
            DramaActorCollection(
              id: 'ac1',
              name: '顾景渊',
              avatarUrl: 'https://cdn.example/a.png',
            ),
          ],
        ),
        dramaId: 'd1',
      );

      expect(entry.actors, hasLength(1));
      expect(entry.actors!.single.actorName, '顾景渊');
    });
  });
}
