import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/episode_play_handoff.dart';
import 'package:story_app/src/model/models.dart';

void main() {
  const play = DramaPlayResponse(
    episodeId: 'ep-1',
    mediaAccessUrl: 'https://cdn.example.com/ep1.m3u8',
  );

  tearDown(EpisodePlayHandoff.clear);

  test('offer and take returns play and startAt', () {
    EpisodePlayHandoff.offer(
      dramaId: 'd-1',
      episodeNo: 2,
      play: play,
      startAt: const Duration(seconds: 12),
    );

    expect(EpisodePlayHandoff.hasOffer(dramaId: 'd-1', episodeNo: 2), isTrue);

    final taken = EpisodePlayHandoff.take(dramaId: 'd-1', episodeNo: 2);
    expect(taken?.play.episodeId, 'ep-1');
    expect(taken?.startAt, const Duration(seconds: 12));
    expect(taken?.diskWarmed, isFalse);
    expect(EpisodePlayHandoff.hasOffer(dramaId: 'd-1', episodeNo: 2), isFalse);
  });

  test('offer preserves diskWarmed through take', () {
    EpisodePlayHandoff.offer(
      dramaId: 'd-1',
      episodeNo: 1,
      play: play,
      diskWarmed: true,
    );

    final taken = EpisodePlayHandoff.take(dramaId: 'd-1', episodeNo: 1);
    expect(taken?.diskWarmed, isTrue);
  });

  test('take returns null for mismatched drama or episode', () {
    EpisodePlayHandoff.offer(dramaId: 'd-1', episodeNo: 1, play: play);

    expect(EpisodePlayHandoff.take(dramaId: 'd-2', episodeNo: 1), isNull);
    expect(EpisodePlayHandoff.take(dramaId: 'd-1', episodeNo: 2), isNull);
  });
}
