import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/drama_model.dart';
import 'package:story_app/src/model/drama_play_response_model.dart';
import 'package:story_app/src/model/recommend_feed_model.dart';
import 'package:story_app/src/model/work_content_type.dart';

void main() {
  test('RecommendFeedItem parses string counters from gateway payload', () {
    final item = RecommendFeedItem.fromJson(const {
      'contentType': 'drama_episode',
      'dramaId': '10001',
      'episodeId': 'ep-1',
      'episodeNo': 1,
      'title': 'Demo',
      'likeCount': '33',
      'commentCount': '8',
      'favoriteCount': '10',
      'playCount': '120',
      'creatorId': 'u-1',
      'creatorName': 'Pixel',
      'creatorAvatar': 'https://example.com/a.png',
      'followedByMe': true,
      'actors': [
        {'actorId': 'a-1', 'actorName': '沈清秋', 'storyPerHour': '8562'},
      ],
    });

    expect(item.dramaId, '10001');
    expect(item.playbackId, '10001:ep-1');
    expect(item.bindWorkId, '10001');
    expect(item.id, '10001:ep-1');
    expect(item.likeCount, 33);
    expect(item.commentCount, 8);
    expect(item.favoriteCount, 10);
    expect(item.playCount, 120);
    expect(item.workType, WorkContentType.shortDrama);
    expect(item.favoriteTargetId, 'ep-1');
    expect(item.creatorAvatar, 'https://example.com/a.png');
    expect(item.followedByMe, isTrue);
    expect(item.actors, isNotNull);
    expect(item.actors!.single.actorName, '沈清秋');
    expect(item.actors!.single.storyPerHour, 8562);
    expect(item.actors!.single.hourlyRate, 8562);
  });

  test('RecommendFeedItem parses drama badge from feed payload', () {
    expect(
      RecommendFeedItem.fromJson(const {
        'dramaId': '1',
        'contentType': 'drama_episode',
        'badge': 'OFFICIAL',
      }).badge,
      'OFFICIAL',
    );
    expect(
      RecommendFeedItem.fromJson(const {
        'dramaId': '1',
        'contentType': 'drama_episode',
        'badge': null,
      }).badge,
      isNull,
    );
    expect(
      RecommendFeedItem.fromJson(const {
        'dramaId': '1',
        'contentType': 'drama_episode',
        'badge': 'partner',
      }).badge,
      'partner',
    );
  });

  test('RecommendFeedActor hourlyRate falls back to computingPower', () {
    final actor = RecommendFeedActor.fromJson(const {
      'actorId': 'a-1',
      'actorName': '沈清秋',
      'computingPower': 19.0032,
    });
    expect(actor.storyPerHour, isNull);
    expect(actor.unitPrice, isNull);
    expect(actor.hourlyRate, 19.0032);
  });

  test('RecommendFeedActor prefers unitPrice over computingPower', () {
    final actor = RecommendFeedActor.fromJson(const {
      'actorId': 'a-1',
      'computingPower': 19,
      'nft': {'unitPrice': 0.01},
    });
    expect(actor.hourlyRate, 0.01);
  });

  test('RecommendFeedActor skips zero storyPerHour and uses unitPrice', () {
    final actor = RecommendFeedActor.fromJson(const {
      'actorId': 'a-1',
      'storyPerHour': 0,
      'nft': {'unitPrice': 0.01},
    });
    expect(actor.hourlyRate, 0.01);
  });

  test(
    'RecommendFeedActor keeps zero hourlyRate when there is no fallback',
    () {
      final actor = RecommendFeedActor.fromJson(const {
        'actorId': 'a-1',
        'storyPerHour': 0,
      });
      expect(actor.hourlyRate, 0);
    },
  );

  test('RecommendFeedActor reads nested boundActorCollection rates', () {
    final actor = RecommendFeedActor.fromJson(const {
      'actorId': 'a-1',
      'actorName': '兵马俑',
      'boundActorCollection': {
        'id': 'c-1',
        'computingPower': 19.0032,
        'nft': {'unitPrice': 0.01},
      },
    });
    expect(actor.hourlyRate, 0.01);
    expect(actor.computingPower, 19.0032);
  });

  test('RecommendFeedItem maps roles when actors is omitted', () {
    final item = RecommendFeedItem.fromJson(const {
      'dramaId': '1',
      'roles': [
        {
          'id': 'r-1',
          'name': '兵马俑',
          'boundActorCollection': {
            'id': 'c-1',
            'name': '王一博',
            'avatar': 'https://actor.jpg',
            'computingPower': 42.5,
          },
        },
      ],
    });
    expect(item.actors, hasLength(1));
    expect(item.actors!.single.actorName, '王一博');
    expect(item.actors!.single.hourlyRate, 42.5);
  });

  test('forRail overlays detail role rates onto feed actors', () {
    final rail = RecommendFeedActor.forRail(
      feedActors: const [
        RecommendFeedActor(actorId: 'c-1', actorName: '王一博', storyPerHour: 0),
      ],
      roles: [
        RoleCharacter.fromMap(const {
          'id': 'r-1',
          'boundActorCollection': {
            'id': 'c-1',
            'nft': {'unitPrice': 0.01},
          },
        }),
      ],
    );
    expect(rail.single.hourlyRate, 0.01);
    // Player STORY/h skips NFT unitPrice; explicit zero storyPerHour is kept.
    expect(rail.single.payRate, 0);
  });

  test('forRail payRate prefers computingPower over nft.unitPrice', () {
    final rail = RecommendFeedActor.forRail(
      feedActors: const [RecommendFeedActor(actorId: 'c-1', actorName: '王一博')],
      roles: [
        RoleCharacter.fromMap(const {
          'id': 'r-1',
          'boundActorCollection': {
            'id': 'c-1',
            'computingPower': 19,
            'nft': {'unitPrice': 0.01},
          },
        }),
      ],
    );
    expect(rail.single.hourlyRate, 0.01);
    expect(rail.single.payRate, 19);
  });

  test('forRail uses bound roles when feed actors are empty', () {
    final rail = RecommendFeedActor.forRail(
      feedActors: const [],
      roles: [
        RoleCharacter.fromMap(const {
          'id': 'r-1',
          'name': '兵马俑',
          'boundActorCollection': {
            'id': 'c-1',
            'name': '王一博',
            'avatar': 'https://actor.jpg',
            'computingPower': 19,
          },
        }),
      ],
    );
    expect(rail, hasLength(1));
    expect(rail.single.actorName, '王一博');
    expect(rail.single.hourlyRate, 19);
  });

  test('forRail appends bound roles missing from the feed actors list', () {
    final rail = RecommendFeedActor.forRail(
      feedActors: const [
        RecommendFeedActor(actorId: 'c-1', actorName: 'A'),
        RecommendFeedActor(actorId: 'c-2', actorName: 'B'),
        RecommendFeedActor(actorId: 'c-3', actorName: 'C'),
      ],
      roles: [
        for (final id in ['c-1', 'c-2', 'c-3', 'c-4', 'c-5'])
          RoleCharacter.fromMap({
            'id': 'r-$id',
            'boundActorCollection': {'id': id, 'name': 'Role $id'},
          }),
      ],
    );
    expect(rail.map((a) => a.actorId), ['c-1', 'c-2', 'c-3', 'c-4', 'c-5']);
  });

  test('toPlayResponse maps feed mediaAccessUrl without cookies', () {
    final item = RecommendFeedItem.fromJson(const {
      'contentType': 'drama_episode',
      'dramaId': '425507660539351040',
      'episodeId': '425507660589682688',
      'episodeNo': 1,
      'likeCount': '4',
      'commentCount': '0',
      'favoriteCount': '12',
      'mediaAccessUrl':
          'https://video.actqa.com/mini-drama/streaming/hls/425507551755882496/episode/425507613324070912/425507613324070912_hls.m3u8',
    });

    final play = item.toPlayResponse();
    expect(play, isNotNull);
    expect(play!.dramaId, item.dramaId);
    expect(play.episodeId, item.episodeId);
    expect(play.episodeNo, 1);
    expect(play.playbackType, 'hls');
    expect(play.effectivePlayUrl, item.mediaAccessUrl);
    expect(play.signedCookies, isNull);
    expect(play.likeCount, 4);
    expect(play.favoriteCount, 12);
    expect(play.isUnsignedProtectedPlay, isTrue);
    expect(play.hasUsableSignedCookies, isFalse);
  });

  test('toPlayResponse keeps valid signedCookies from the feed card', () {
    final item = RecommendFeedItem.fromJson(const {
      'dramaId': '1',
      'episodeId': 'ep-1',
      'episodeNo': 1,
      'mediaAccessUrl':
          'https://dev-video.actqa.com/mini-drama/streaming/hls/1/episode/1/1_hls.m3u8',
      'signedCookies': {
        'policy': 'policy-value',
        'signature': 'signature-value',
        'keyPairId': 'KID',
        'expires': 1893456000,
      },
    });

    final play = item.toPlayResponse();
    expect(play, isNotNull);
    expect(play!.signedCookies, isNotNull);
    expect(play.signedCookies!.policy, 'policy-value');
    expect(play.signedCookies!.keyPairId, 'KID');
    expect(play.signedCookies!.isValid, isTrue);
    expect(play.isUnsignedProtectedPlay, isFalse);
    expect(play.hasUsableSignedCookies, isTrue);
  });

  test('toPlayResponse drops invalid signedCookies', () {
    final item = RecommendFeedItem.fromJson(const {
      'dramaId': '1',
      'episodeId': 'ep-1',
      'mediaAccessUrl': 'https://cdn.example.com/ep.m3u8',
      'signedCookies': {'policy': '', 'signature': 'sig'},
    });

    final play = item.toPlayResponse();
    expect(play, isNotNull);
    expect(play!.signedCookies, isNull);
  });

  test('toPlayResponse is null when mediaAccessUrl is missing', () {
    final item = RecommendFeedItem.fromJson(const {
      'dramaId': '1',
      'episodeId': 'ep-1',
    });
    expect(item.toPlayResponse(), isNull);
  });

  test('withEngagement replaces only the interaction fields', () {
    final item = RecommendFeedItem.fromJson(const {
      'dramaId': '1',
      'episodeId': 'ep-1',
      'title': 'Demo',
      'mediaAccessUrl': 'https://cdn.example.com/ep.m3u8',
      'likeCount': 4,
      'commentCount': 2,
      'favoriteCount': 7,
      'likedByMe': false,
      'favoritedByMe': false,
    });

    final patched = item.withEngagement(
      likedByMe: true,
      likeCount: 5,
      favoritedByMe: true,
      favoriteCount: 8,
      commentCount: 3,
    );

    expect(patched.likedByMe, isTrue);
    expect(patched.likeCount, 5);
    expect(patched.favoritedByMe, isTrue);
    expect(patched.favoriteCount, 8);
    expect(patched.commentCount, 3);
    expect(patched.title, 'Demo');
    expect(patched.mediaAccessUrl, item.mediaAccessUrl);
    expect(patched.episodeId, 'ep-1');
  });

  test('withEngagement keeps current values for omitted fields', () {
    final item = RecommendFeedItem.fromJson(const {
      'dramaId': '1',
      'likeCount': 4,
      'favoriteCount': 7,
      'likedByMe': true,
    });

    final patched = item.withEngagement(commentCount: 1);

    expect(patched.commentCount, 1);
    expect(patched.likeCount, 4);
    expect(patched.favoriteCount, 7);
    expect(patched.likedByMe, isTrue);
  });

  test('withEngagement applies an unliked toggle result', () {
    final item = RecommendFeedItem.fromJson(const {
      'dramaId': '1',
      'likeCount': 5,
      'likedByMe': true,
    });

    final patched = item.withEngagement(likedByMe: false, likeCount: 4);

    expect(patched.likedByMe, isFalse);
    expect(patched.likeCount, 4);
  });

  test('toPlayResponse carries the card interaction fields', () {
    final item = RecommendFeedItem.fromJson(const {
      'dramaId': '1',
      'episodeId': 'ep-1',
      'mediaAccessUrl': 'https://cdn.example.com/ep.m3u8',
      'likeCount': 4,
      'commentCount': 2,
      'likedByMe': true,
      'favoritedByMe': false,
    });

    final play = item.toPlayResponse();
    expect(play!.likeCount, 4);
    expect(play.commentCount, 2);
    expect(play.likedByMe, isTrue);
    expect(play.favoritedByMe, isFalse);
  });

  test('RecommendFeedPage maps cursor pagination', () {
    final page = RecommendFeedPage.fromJson(const {
      'sessionId': 's-1',
      'cursor': 'c-2',
      'hasMore': true,
      'source': 'cold_start',
      'items': [
        {'dramaId': '1', 'title': 'A'},
        {'dramaId': '2', 'title': 'B'},
      ],
    });

    expect(page.cursor, 'c-2');
    expect(page.hasMore, isTrue);
    expect(page.items.map((e) => e.dramaId), ['1', '2']);
  });

  test('RecommendFeedPage infers hasMore from cursor when omitted', () {
    final page = RecommendFeedPage.fromJson(const {
      'cursor': 'c-2',
      'items': [
        {'dramaId': '1'},
      ],
    });
    expect(page.hasMore, isTrue);

    final done = RecommendFeedPage.fromJson(const {
      'hasMore': false,
      'cursor': 'c-2',
      'items': [
        {'dramaId': '1'},
      ],
    });
    expect(done.hasMore, isFalse);
  });

  test('short_video contentType keys favorite on episodeId', () {
    final item = RecommendFeedItem.fromJson(const {
      'contentType': 'short_video',
      'dramaId': '',
      'episodeId': 'sv-9',
      'title': 'Clip',
    });
    expect(item.workType, WorkContentType.shortVideo);
    expect(item.favoriteTargetId, 'sv-9');
    expect(item.playbackId, 'sv-9');
    expect(item.bindWorkId, 'sv-9');
    expect(item.id, 'sv-9');
    expect(item.hasPlayableIdentity, isTrue);
  });

  test('short drama playbackId includes episodeId', () {
    final ep1 = RecommendFeedItem.fromJson(const {
      'contentType': 'drama_episode',
      'dramaId': 'd-1',
      'episodeId': 'e-1',
      'episodeNo': 1,
    });
    final ep2 = RecommendFeedItem.fromJson(const {
      'contentType': 'drama_episode',
      'dramaId': 'd-1',
      'episodeId': 'e-2',
      'episodeNo': 2,
    });
    expect(ep1.playbackId, 'd-1:e-1');
    expect(ep2.playbackId, 'd-1:e-2');
    expect(ep1.playbackId, isNot(ep2.playbackId));
    expect(ep1.bindWorkId, 'd-1');
    expect(ep2.bindWorkId, 'd-1');
    expect(
      RecommendFeedItem.playbackIdOfPlay(
        const DramaPlayResponse(dramaId: 'd-1', episodeId: 'e-2'),
      ),
      'd-1:e-2',
    );
  });

  test('short drama without episodeId uses episode number identity', () {
    const item = RecommendFeedItem(
      contentType: 'SHORT_DRAMA',
      dramaId: 'd-1',
      episodeNo: 3,
    );

    expect(item.playbackId, 'd-1:episode:3');
  });

  test('RecommendFeedItem flattens nested drama/episode feed cards', () {
    final item = RecommendFeedItem.fromJson(const {
      'userId': '418189573877915648',
      'creatorName': 'Pixel',
      'creatorAvatarUrl': 'https://example.com/a.png',
      'followedByMe': false,
      'type': 'DRAMA_EPISODE',
      'drama': {
        'dramaId': '427595238412468224',
        'title': 'DRAMA TEST SP 01',
        'description': 'ASDQWE',
        'coverUrl': 'https://example.com/cover.png',
        'contentType': 'SHORT_DRAMA',
        'tags': ['Comedy'],
        'totalEpisodes': 1,
        'badge': 'COMMUNITY',
        'actorCollections': [
          {
            'actorCollectionId': '427634972790702080',
            'actorCollectionName': '长公主',
            'actorCollectionAvatar': 'https://example.com/x.jpg',
            'badge': 'COMMUNITY',
            'trust': 1.0,
            'computingPower': 0.0019864559,
          },
        ],
      },
      'episode': {
        'episodeId': '427595238437634048',
        'episodeNo': 1,
        'contentType': 'SHORT_DRAMA',
        'durationSec': 4,
        'title': 'DRAMA TEST SP 01',
        'coverUrl': 'https://example.com/cover.png',
        'playCount': '14',
        'likeCount': '3',
        'commentCount': '0',
        'favoriteCount': '0',
        'mediaAccessUrl':
            'https://dev-video.actqa.com/mini-drama/streaming/hls/x.m3u8',
        'playbackType': 'HLS',
      },
    });

    expect(item.dramaId, '427595238412468224');
    expect(item.episodeId, '427595238437634048');
    expect(item.episodeNo, 1);
    expect(item.title, 'DRAMA TEST SP 01');
    expect(item.workType, WorkContentType.shortDrama);
    expect(item.playbackId, '427595238412468224:427595238437634048');
    expect(item.bindWorkId, '427595238412468224');
    expect(item.creatorId, '418189573877915648');
    expect(item.creatorAvatar, 'https://example.com/a.png');
    expect(item.likeCount, 3);
    expect(item.commentCount, 0);
    expect(item.favoriteCount, 0);
    expect(item.playCount, 14);
    expect(item.tags, ['Comedy']);
    expect(item.badge, 'COMMUNITY');
    expect(item.actors, hasLength(1));
    expect(item.actors!.single.actorId, '427634972790702080');
    expect(item.actors!.single.actorName, '长公主');
    expect(item.actors!.single.computingPower, 0.0019864559);
    final play = item.toPlayResponse();
    expect(play, isNotNull);
    expect(play!.dramaId, item.bindWorkId);
    expect(play.episodeId, item.episodeId);
    expect(RecommendFeedItem.playbackIdOfPlay(play), item.playbackId);
    expect(play.effectivePlayUrl, item.mediaAccessUrl);
  });

  test('RecommendFeedPage keeps nested SHORT_VIDEO items without drama', () {
    final page = RecommendFeedPage.fromJson(const {
      'sessionId': 's-1',
      'cursor': 'c-2',
      'hasMore': true,
      'items': [
        {
          'userId': '429208337494388736',
          'creatorName': 'SPIKE_TEST_EMAIL',
          'creatorAvatarUrl': 'https://example.com/a.png',
          'type': 'SHORT_VIDEO',
          'drama': null,
          'episode': {
            'episodeId': '447109289892757504',
            'episodeNo': 1,
            'contentType': 'SHORT_VIDEO',
            'durationSec': 5,
            'title': 'test-video',
            'coverUrl': 'https://example.com/sv.png',
            'mediaAccessUrl': 'https://dev-video.actqa.com/sv.m3u8',
            'playbackType': 'HLS',
          },
        },
      ],
    });

    expect(page.items, hasLength(1));
    final item = page.items.single;
    expect(item.workType, WorkContentType.shortVideo);
    expect(item.dramaId, isEmpty);
    expect(item.episodeId, '447109289892757504');
    expect(item.playbackId, '447109289892757504');
    expect(item.title, 'test-video');
    expect(item.hasPlayableIdentity, isTrue);
    expect(item.toPlayResponse()?.dramaId, '447109289892757504');
  });
}
