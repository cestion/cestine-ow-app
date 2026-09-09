import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/routes/route_args.dart';

void main() {
  group('VideoFeedArgs route serialization', () {
    test('round-trips top-level actors and roles', () {
      const actor = RecommendFeedActor(
        actorId: 'ac1',
        actorName: '顾景渊',
        avatarUrl: 'https://cdn.example/a.png',
        storyPerHour: 120,
      );
      const role = RoleCharacter(
        name: '男主',
        boundActorCollectionId: 'ac1',
        boundActorName: '顾景渊',
      );
      const args = VideoFeedArgs(
        dramaId: 'd1',
        episodeNo: 2,
        title: 'Drama',
        creatorUserId: 'u1',
        actors: [actor],
        roles: [role],
      );

      final restored = VideoFeedArgs.fromMap(args.toMap());

      expect(restored.dramaId, 'd1');
      expect(restored.episodeNo, 2);
      expect(restored.actors, hasLength(1));
      expect(restored.actors!.single.actorId, 'ac1');
      expect(restored.actors!.single.storyPerHour, 120);
      expect(restored.roles, hasLength(1));
      expect(restored.roles!.single.boundActorCollectionId, 'ac1');
    });

    test('round-trips searchPlaylist entry actors and roles', () {
      const actor = RecommendFeedActor(actorId: 'ac2', actorName: '林晚');
      const role = RoleCharacter(
        name: '女主',
        boundActorCollectionId: 'ac2',
        boundActorName: '林晚',
      );
      const args = VideoFeedArgs(
        dramaId: 'd1',
        episodeNo: 1,
        searchPlaylist: [
          VideoFeedPlaylistEntry.drama(
            dramaId: 'd1',
            title: 'Drama',
            actors: [actor],
            roles: [role],
          ),
        ],
      );

      final restored = VideoFeedArgs.fromMap(args.toMap());
      final entry = restored.searchPlaylist.single;

      expect(entry.actors, hasLength(1));
      expect(entry.actors!.single.actorName, '林晚');
      expect(entry.roles, hasLength(1));
      expect(entry.roles!.single.name, '女主');
    });

    test('VideoFeedPlaylistEntry round-trips independently', () {
      const entry = VideoFeedPlaylistEntry.drama(
        dramaId: 'd1',
        actors: [RecommendFeedActor(actorId: 'ac1')],
        roles: [
          RoleCharacter(
            boundActorCollectionId: 'ac1',
            boundActorName: 'IP',
          ),
        ],
      );

      final restored = VideoFeedPlaylistEntry.fromMap(entry.toMap());

      expect(restored.actors!.single.actorId, 'ac1');
      expect(restored.roles!.single.boundActorName, 'IP');
    });
  });
}
