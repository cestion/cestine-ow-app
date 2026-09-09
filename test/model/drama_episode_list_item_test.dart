import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/drama_episode_list_item.dart';

void main() {
  test('DramaEpisodeListItem parses string ids and counters', () {
    final item = DramaEpisodeListItem.fromJson(const {
      'episodeId': 440064535674023936,
      'dramaId': '10001',
      'episodeNo': '2',
      'title': '第2集',
      'description': '加密货币市场的至暗时刻。',
      'coverUrl': 'https://example.com/c.png',
      'likeCount': '678',
      'likedByMe': false,
    });

    expect(item.episodeId, '440064535674023936');
    expect(item.dramaId, '10001');
    expect(item.episodeNo, 2);
    expect(item.title, '第2集');
    expect(item.description, '加密货币市场的至暗时刻。');
    expect(item.coverUrl, 'https://example.com/c.png');
    expect(item.likeCount, 678);
    expect(item.likedByMe, isFalse);
  });

  test('DramaEpisodeListItem accepts coverImg when coverUrl is absent', () {
    final item = DramaEpisodeListItem.fromJson(const {
      'episodeId': '1',
      'coverImg': 'https://example.com/img.jpg',
    });
    expect(item.coverUrl, 'https://example.com/img.jpg');
  });

  test('DramaEpisodeListItem flattens nested dramaInfo and episodeInfo', () {
    final item = DramaEpisodeListItem.fromJson(const {
      'userId': '430265072761823232',
      'type': 'SHORT_DRAMA',
      'dramaInfo': {
        'dramaId': '436827434993672192',
        'title': '过得刚好',
        'coverUrl':
            'https://one-story-dev.s3.dualstack.us-east-2.amazonaws.com/cover.jpg',
      },
      'episodeInfo': {
        'episodeId': '436827435018838016',
        'episodeNo': 1,
        'title': '过得刚好',
        'description': '咯咯哒',
        'coverUrl':
            'https://one-story-dev.s3.dualstack.us-east-2.amazonaws.com/ep.jpg',
        'likeCount': '0',
        'likedByMe': false,
      },
    });

    expect(item.episodeId, '436827435018838016');
    expect(item.dramaId, '436827434993672192');
    expect(item.episodeNo, 1);
    expect(item.description, '咯咯哒');
    expect(item.likeCount, 0);
    expect(item.likedByMe, isFalse);
  });

  test('DramaEpisodeListItem prefers firstFrameUrl for posterUrl', () {
    final item = DramaEpisodeListItem.fromJson(const {
      'episodeId': '1',
      'coverUrl': 'https://example.com/c.png',
      'firstFrameUrl': 'https://example.com/frame.jpg',
    });
    expect(item.coverUrl, 'https://example.com/c.png');
    expect(item.firstFrameUrl, 'https://example.com/frame.jpg');
    expect(item.posterUrl, 'https://example.com/frame.jpg');
  });

  test('DramaEpisodeListItem toJson/fromJson round-trip', () {
    final original = DramaEpisodeListItem.fromJson(const {
      'episodeId': 'ep-1',
      'dramaId': 'd-1',
      'episodeNo': 1,
      'title': '第1集',
      'description': 'desc',
      'coverUrl': 'https://example.com/c.png',
      'firstFrameUrl': 'https://example.com/frame.jpg',
      'likeCount': 10,
      'likedByMe': true,
    });
    final restored = DramaEpisodeListItem.fromJson(original.toJson());
    expect(restored, original);
  });
}
