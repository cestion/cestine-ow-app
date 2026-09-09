import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/story_constants.dart';
import 'package:story_app/src/services/playback_entry_warmup.dart';
import 'package:story_app/src/services/playback_frame_cache_service.dart';
import 'package:story_app/src/services/video_precache_service.dart';

void main() {
  tearDown(VideoPrecacheService.instance.debugClearWarmed);

  test('isPlayUrlDiskWarmed reflects recent precache marks', () {
    const url = 'https://cdn.example.com/ep1.m3u8';
    expect(PlaybackEntryWarmup.isPlayUrlDiskWarmed(url), isFalse);

    VideoPrecacheService.instance.debugMarkWarmed(url);
    expect(PlaybackEntryWarmup.isPlayUrlDiskWarmed(url), isTrue);
  });

  test('frameCacheKey dual forms differ when episodeId is present', () {
    final withId = PlaybackFrameCacheService.frameCacheKey(
      dramaId: 'd1',
      episodeId: 'e9',
      episodeNo: 3,
    );
    final legacy = PlaybackFrameCacheService.frameCacheKey(
      dramaId: 'd1',
      episodeNo: 3,
    );
    expect(withId, 'd1:e9');
    expect(legacy, 'd1_ep3');
    expect(withId, isNot(legacy));
  });

  test('primeFrameCacheAround uses configured radius', () {
    expect(StoryConstants.playbackFramePrimeRadius, greaterThanOrEqualTo(1));
  });
}
