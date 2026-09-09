import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/drama_model.dart';
import 'package:story_app/src/model/drama_play_response_model.dart';
import 'package:story_app/src/model/feed_playable_item.dart';
import 'package:story_app/src/model/recommend_feed_model.dart';
import 'package:story_app/src/model/work_content_type.dart';

void main() {
  group('RecommendFeedItem.toPlayable', () {
    const item = RecommendFeedItem(
      dramaId: 'drama_1',
      episodeId: 'ep_1',
      episodeNo: 2,
      title: 'card title',
      description: 'card desc',
      coverUrl: 'card cover',
      totalEpisodes: 8,
      creatorId: 'card_creator',
      creatorName: 'card creator',
      creatorAvatar: 'card avatar',
      contentType: 'SHORT_DRAMA',
    );

    test('maps card fields when no detail is provided', () {
      final playable = item.toPlayable();
      expect(playable.dramaId, 'drama_1');
      expect(playable.episodeId, 'ep_1');
      expect(playable.episodeNo, 2);
      expect(playable.totalEpisodes, 8);
      expect(playable.title, 'card title');
      expect(playable.description, 'card desc');
      expect(playable.coverUrl, 'card cover');
      expect(playable.creatorName, 'card creator');
      expect(playable.creatorAvatarUrl, 'card avatar');
      expect(playable.creatorUserId, 'card_creator');
      expect(playable.contentType, WorkContentType.shortDrama);
    });

    test('prefers detail over card fields when detail is provided', () {
      final playable = item.toPlayable(
        detail: const DramaDetail(
          id: 'drama_1',
          title: 'detail title',
          description: 'detail desc',
          coverUrl: 'detail cover',
          totalEpisodes: 12,
          userId: 'detail_creator',
          creatorName: 'detail creator',
          creatorAvatarUrl: 'detail avatar',
        ),
      );
      expect(playable.totalEpisodes, 12);
      expect(playable.title, 'detail title');
      expect(playable.description, 'detail desc');
      // Work poster stays on the card (firstFrame/cover); drama detail cover
      // is only a fallback when the card has no still.
      expect(playable.coverUrl, 'card cover');
      expect(playable.creatorName, 'detail creator');
      expect(playable.creatorAvatarUrl, 'detail avatar');
      expect(playable.creatorUserId, 'detail_creator');
      // Identity stays on the card.
      expect(playable.episodeId, 'ep_1');
      expect(playable.episodeNo, 2);
    });

    test('prefers play firstFrameUrl then card cover for poster', () {
      final playable = item.toPlayable(
        play: const DramaPlayResponse(
          dramaId: 'drama_1',
          episodeId: 'ep_1',
          firstFrameUrl: 'https://cdn.example/frame.jpg',
          coverUrl: 'https://cdn.example/play-cover.jpg',
        ),
      );
      expect(playable.coverUrl, 'https://cdn.example/frame.jpg');
    });

    test('card episode id wins; play payload fills a missing one', () {
      final withCard = item.toPlayable(
        play: const DramaPlayResponse(
          dramaId: 'drama_1',
          episodeId: 'ep_override',
          episodeNo: 9,
        ),
      );
      expect(withCard.episodeId, 'ep_1');

      final noCard =
          const RecommendFeedItem(
            dramaId: 'drama_1',
            episodeNo: 2,
            title: 'card title',
            totalEpisodes: 8,
            creatorId: 'card_creator',
            contentType: 'SHORT_DRAMA',
          ).toPlayable(
            play: const DramaPlayResponse(
              dramaId: 'drama_1',
              episodeId: 'ep_override',
              episodeNo: 9,
            ),
          );
      expect(noCard.episodeId, 'ep_override');
    });
  });

  group('DramaDetail.toPlayable', () {
    test('uses id / title / creator and applied episode overrides', () {
      final playable =
          const DramaDetail(
            id: 'drama_2',
            title: 'detail title',
            coverUrl: 'cover',
            totalEpisodes: 5,
            userId: 'creator_2',
            creatorName: 'creator',
            creatorAvatarUrl: 'avatar',
          ).toPlayable(
            episodeNo: 4,
            episodeId: 'ep_4',
            contentType: WorkContentType.shortVideo,
          );
      expect(playable.dramaId, 'drama_2');
      expect(playable.episodeId, 'ep_4');
      expect(playable.episodeNo, 4);
      expect(playable.totalEpisodes, 5);
      expect(playable.title, 'detail title');
      expect(playable.creatorUserId, 'creator_2');
      expect(playable.contentType, WorkContentType.shortVideo);
    });

    test('defaults episode number to 1 when not provided', () {
      final playable = const DramaDetail(id: 'drama_2').toPlayable();
      expect(playable.episodeNo, 1);
      expect(playable.totalEpisodes, 1);
      expect(playable.contentType, WorkContentType.shortDrama);
    });
  });

  group('DramaPlayResponse.toPlayable', () {
    test('maps identity and injects metadata not present on the payload', () {
      final playable =
          const DramaPlayResponse(
            dramaId: 'drama_3',
            episodeId: 'ep_3',
            episodeNo: 7,
          ).toPlayable(
            title: 'injected title',
            coverUrl: 'injected cover',
            creatorName: 'creator',
            creatorUserId: 'creator_3',
            contentType: WorkContentType.shortVideo,
          );
      expect(playable.dramaId, 'drama_3');
      expect(playable.episodeId, 'ep_3');
      expect(playable.episodeNo, 7);
      expect(playable.title, 'injected title');
      expect(playable.coverUrl, 'injected cover');
      expect(playable.creatorUserId, 'creator_3');
      expect(playable.contentType, WorkContentType.shortVideo);
    });

    test('does NOT seed creatorUserId from play.userId (viewer trap)', () {
      final playable = const DramaPlayResponse(
        dramaId: 'drama_3',
        episodeId: 'ep_3',
        userId: 'some_viewer_user_id',
      ).toPlayable();
      expect(playable.creatorUserId, isNull);
    });
  });

  group('FeedPlayableItem.basic', () {
    test('applies sane defaults', () {
      final playable = FeedPlayableItem.basic(dramaId: 'drama_4');
      expect(playable.dramaId, 'drama_4');
      expect(playable.episodeId, isNull);
      expect(playable.episodeNo, 1);
      expect(playable.totalEpisodes, 1);
      expect(playable.title, '');
      expect(playable.creatorUserId, isNull);
      expect(playable.contentType, WorkContentType.shortDrama);
    });
  });
}
