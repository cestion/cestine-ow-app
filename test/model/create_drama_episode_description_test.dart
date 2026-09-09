import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/create_drama_draft_model.dart';
import 'package:story_app/src/model/create_drama_request_model.dart';

void main() {
  test('CreateEpisodeRequest serializes its description', () {
    const episode = CreateEpisodeRequest(
      durationSec: 90,
      description: '主角发现了一封来自未来的信。',
      episodeNo: 1,
      title: '第一集',
      videoObjectKey: 'dramas/episode-1.mp4',
      width: 1080,
      height: 1920,
    );

    expect(episode.toJson()['description'], '主角发现了一封来自未来的信。');
  });

  test('draft video preserves its description after restoration', () {
    const video = DraftVideoItem(
      name: 'episode-1.mp4',
      description: '主角发现了一封来自未来的信。',
    );

    final restored = DraftVideoItem.fromMap(video.toMap());

    expect(restored?.description, video.description);
  });
}
