import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/recommend_search_models.dart';

void main() {
  test('toDramaListItem keeps actor pay rates for the cast dialog', () {
    const item = FeedItem(
      dramaId: 'd-1',
      title: 'Demo',
      actors: [
        FeedActor(
          actorId: 'a-1',
          actorName: '刘亦菲 (Crystal Liu)',
          avatarUrl: 'https://example.com/a.png',
          storyPerHour: 6344,
          computingPower: 19.0,
        ),
        FeedActor(
          actorId: 'a-2',
          actorName: '顾景渊',
          avatarUrl: 'https://example.com/b.png',
          computingPower: 42.5,
        ),
      ],
    );

    final actors = item.toDramaListItem().actorCollections!;
    expect(actors, hasLength(2));
    expect(actors[0].hourlyRate, 6344);
    expect(actors[0].storyPerHour, 6344);
    expect(actors[1].hourlyRate, 42.5);
    expect(actors[1].computingPower, 42.5);
  });

  test('FeedItem maps search totalHeatValue onto the drama card', () {
    final item = FeedItem.fromJson(const {
      'contentType': 'drama_episode',
      'dramaId': '442094297974009856',
      'episodeId': '442094297986592769',
      'title': 'Demo111',
      'playCount': '10',
      'completeCount': '8',
      'totalHeatValue': 80.0,
    });

    expect(item.totalHeatValue, 80.0);
    expect(item.toDramaListItem().totalHeatValue, 80.0);
    expect(item.toDramaListItem().episodeId, isNull);
  });

  test('FeedItem maps search durationSec in seconds', () {
    final item = FeedItem.fromJson(const {
      'contentType': 'short_video',
      'durationSec': 90,
    });

    expect(item.durationSec, 90);
  });

  test('FeedItem uses swagger title, not dramaTitle', () {
    final item = FeedItem.fromJson(const {
      'contentType': 'drama_episode',
      'title': '凤骨琉璃',
      'description': '一曲凤骨琉璃，半世浮华若梦。',
      'dramaTitle': 'should-be-ignored',
      'dramaName': 'also-ignored',
    });

    expect(item.title, '凤骨琉璃');
    expect(item.description, '一曲凤骨琉璃，半世浮华若梦。');
    expect(item.toDramaListItem().dramaTitle, '凤骨琉璃');
  });

  test('RecommendSearchType sends swagger drama / all values', () {
    expect(RecommendSearchType.drama.apiValue, 'drama');
    expect(RecommendSearchType.all.apiValue, 'all');
    expect(RecommendSearchType.fromApi('drama'), RecommendSearchType.drama);
    expect(
      RecommendSearchType.fromApi('drama_episode'),
      RecommendSearchType.drama,
    );
    expect(
      RecommendSearchType.fromApi('SHORT_VIDEO'),
      RecommendSearchType.shortVideo,
    );
  });

  test('FeedItem flattens nested drama/episode search cards', () {
    final item = FeedItem.fromJson(const {
      'userId': '429208337494388736',
      'creatorName': 'SPIKE_TEST_EMAIL',
      'creatorAvatarUrl': 'https://example.com/a.png',
      'type': 'DRAMA_EPISODE',
      'drama': {
        'dramaId': '442480670898868224',
        'title': 'DRAMA GAS SP',
        'description': 'QWEQWE QWE1',
        'coverUrl': 'https://example.com/cover.png',
        'tags': ['Comedy'],
        'totalEpisodes': 1,
        'badge': 'COMMUNITY',
        'actorCollections': [
          {
            'actorCollectionId': '427634972790702080',
            'actorCollectionName': '长公主',
            'actorCollectionAvatar': 'https://example.com/x.jpg',
            'computingPower': 0.0019864559,
          },
        ],
      },
      'episode': {
        'episodeId': '442480670919839744',
        'episodeNo': 1,
        'contentType': 'SHORT_DRAMA',
        'durationSec': 4,
        'title': 'DRAMA GAS SP',
        'coverUrl': 'https://example.com/cover.png',
        'playCount': '3',
        'likeCount': '0',
        'mediaAccessUrl': 'https://dev-video.actqa.com/x.m3u8',
        'playbackType': 'HLS',
      },
    });

    expect(item.contentType, 'DRAMA_EPISODE');
    expect(item.isShortVideo, isFalse);
    expect(item.dramaId, '442480670898868224');
    expect(item.episodeId, '442480670919839744');
    expect(item.episodeNo, 1);
    expect(item.durationSec, 4);
    expect(item.title, 'DRAMA GAS SP');
    expect(item.coverUrl, 'https://example.com/cover.png');
    expect(item.mediaAccessUrl, 'https://dev-video.actqa.com/x.m3u8');
    expect(item.playCount, 3);
    expect(item.totalEpisodes, 1);
    expect(item.badge, 'COMMUNITY');
    expect(item.tags, ['Comedy']);
    expect(item.creatorId, '429208337494388736');
    expect(item.creatorName, 'SPIKE_TEST_EMAIL');
    expect(item.creatorAvatar, 'https://example.com/a.png');
    expect(item.actors, hasLength(1));
    expect(item.actors.single.actorId, '427634972790702080');
    expect(item.actors.single.actorName, '长公主');
    expect(item.toDramaListItem().id, '442480670898868224');
  });

  test('FeedItem flattens nested SHORT_VIDEO cards with drama null', () {
    final item = FeedItem.fromJson(const {
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
        'description': 'qeweqwdasdaads',
        'coverUrl': 'https://example.com/sv.png',
        'mediaAccessUrl': 'https://dev-video.actqa.com/sv.m3u8',
        'playbackType': 'HLS',
      },
    });

    expect(item.isShortVideo, isTrue);
    expect(item.dramaId, isNull);
    expect(item.episodeId, '447109289892757504');
    expect(item.title, 'test-video');
    expect(item.durationSec, 5);
    expect(item.coverUrl, 'https://example.com/sv.png');
    expect(item.creatorAvatar, 'https://example.com/a.png');
  });

  test('FeedItem prefers firstFrameUrl for posterUrl', () {
    final item = FeedItem.fromJson(const {
      'type': 'SHORT_VIDEO',
      'episode': {
        'episodeId': '1',
        'coverUrl': 'https://example.com/cover.png',
        'firstFrameUrl': 'https://example.com/frame.jpg',
      },
    });
    expect(item.coverUrl, 'https://example.com/cover.png');
    expect(item.firstFrameUrl, 'https://example.com/frame.jpg');
    expect(item.posterUrl, 'https://example.com/frame.jpg');
  });
}
