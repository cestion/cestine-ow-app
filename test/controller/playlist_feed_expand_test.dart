import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/playlist_feed_expand.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/routes/route_args.dart';

void main() {
  group('PlaylistFeedExpand', () {
    test('flattens short video + expanded drama + short video', () {
      final seed = PlaylistFeedExpand.seedFromArgs(
        const VideoFeedArgs(
          dramaId: 'd1',
          episodeNo: 1,
          title: 'B',
          searchPlaylist: [
            VideoFeedPlaylistEntry.shortVideo(episodeId: 'sv1', title: 'A'),
            VideoFeedPlaylistEntry.drama(
              dramaId: 'd1',
              title: 'B',
              totalEpisodes: 3,
              expandEpisodes: true,
            ),
            VideoFeedPlaylistEntry.shortVideo(episodeId: 'sv2', title: 'C'),
          ],
          searchPlaylistIndex: 1,
        ),
      );

      expect(seed.items.map((e) => e.title), ['A', 'B', 'B', 'B', 'C']);
      expect(seed.items.map((e) => e.episodeNo).toList(), [1, 1, 2, 3, 1]);
      // Selected work is drama at index 1 → first expanded episode.
      expect(seed.initialIndex, 1);
      expect(seed.items.map((e) => e.dramaId).toList(), [
        '',
        'd1',
        'd1',
        'd1',
        '',
      ]);
    });

    test('resolveEpisodeCounts fills missing totals', () async {
      final result = await PlaylistFeedExpand.resolveEpisodeCounts(
        const [
          VideoFeedPlaylistEntry.drama(dramaId: 'd1', expandEpisodes: true),
          VideoFeedPlaylistEntry.shortVideo(episodeId: 'sv1'),
        ],
        loadEpisodeCount: (id) async {
          expect(id, 'd1');
          return Result.success(2);
        },
      );

      expect(result.isSuccess, isTrue);
      final entries = result.dataOrNull!;
      expect(entries[0].totalEpisodes, 2);
      expect(entries[1].isShortVideo, isTrue);

      final flat = PlaylistFeedExpand.flattenEntries(entries);
      expect(flat.length, 3);
    });

    test('passes list-row engagement seeds into feed items', () {
      final seed = PlaylistFeedExpand.seedFromArgs(
        const VideoFeedArgs(
          dramaId: 'd1',
          episodeNo: 1,
          likedByMe: true,
          likeCount: 42,
          commentCount: 3,
          favoritedByMe: false,
          favoriteCount: 1,
          followedByMe: true,
          searchPlaylist: [
            VideoFeedPlaylistEntry.shortVideo(
              episodeId: 'sv1',
              likedByMe: false,
              likeCount: 9,
            ),
          ],
        ),
      );

      final item = seed.items.single;
      expect(item.likedByMe, isTrue);
      expect(item.likeCount, 42);
      expect(item.commentCount, 3);
      expect(item.favoritedByMe, isFalse);
      expect(item.favoriteCount, 1);
      expect(item.followedByMe, isTrue);
    });

    test('expanded drama episodes omit list-row engagement seeds', () {
      final seed = PlaylistFeedExpand.seedFromArgs(
        const VideoFeedArgs(
          dramaId: 'd1',
          episodeNo: 2,
          likedByMe: true,
          likeCount: 42,
          commentCount: 3,
          favoritedByMe: true,
          favoriteCount: 7,
          searchPlaylist: [
            VideoFeedPlaylistEntry.drama(
              dramaId: 'd1',
              title: 'Drama',
              totalEpisodes: 2,
              expandEpisodes: true,
              likedByMe: true,
              likeCount: 99,
            ),
          ],
        ),
      );

      expect(seed.items.length, 2);
      for (final item in seed.items) {
        expect(item.likedByMe, isNull);
        expect(item.likeCount, isNull);
        expect(item.commentCount, isNull);
        expect(item.favoritedByMe, isNull);
        expect(item.favoriteCount, isNull);
      }
    });

    test('passes role IP seeds into feed items', () {
      const actor = RecommendFeedActor(
        actorId: 'ac1',
        actorName: '顾景渊',
        avatarUrl: 'https://cdn.example/a.png',
      );
      const role = RoleCharacter(
        name: '男主',
        boundActorCollectionId: 'ac1',
        boundActorName: '顾景渊',
      );
      final seed = PlaylistFeedExpand.seedFromArgs(
        const VideoFeedArgs(
          dramaId: 'd1',
          episodeNo: 1,
          title: 'Drama',
          roles: [role],
          searchPlaylist: [
            VideoFeedPlaylistEntry.drama(
              dramaId: 'd1',
              title: 'Drama',
              actors: [actor],
            ),
          ],
        ),
      );

      final item = seed.items.single;
      expect(item.actors, isNotNull);
      expect(item.actors, hasLength(1));
      expect(item.actors!.single.actorId, 'ac1');
      expect(item.roles, hasLength(1));
      expect(item.roles!.single.boundActorCollectionId, 'ac1');
    });

    test('expanded drama episodes keep role IP seeds', () {
      const actor = RecommendFeedActor(actorId: 'ac1', actorName: 'IP');
      final seed = PlaylistFeedExpand.seedFromArgs(
        const VideoFeedArgs(
          dramaId: 'd1',
          episodeNo: 1,
          searchPlaylist: [
            VideoFeedPlaylistEntry.drama(
              dramaId: 'd1',
              totalEpisodes: 2,
              expandEpisodes: true,
              actors: [actor],
            ),
          ],
        ),
      );

      expect(seed.items.length, 2);
      for (final item in seed.items) {
        expect(item.actors, hasLength(1));
        expect(item.actors!.single.actorId, 'ac1');
      }
    });

    test('resolveEpisodeCounts fails instead of defaulting to 1', () async {
      final result = await PlaylistFeedExpand.resolveEpisodeCounts(
        const [
          VideoFeedPlaylistEntry.drama(dramaId: 'd1', expandEpisodes: true),
        ],
        loadEpisodeCount: (_) async =>
            Result.failure(ApiError.network('offline')),
      );
      expect(result.isFailure, isTrue);
    });
  });
}
