import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/story_constants.dart';
import 'package:story_app/src/core/video_url_helpers.dart';
import 'package:story_app/src/services/video_precache_service.dart';

void main() {
  group('VideoPrecacheService.bytesBudgetFor', () {
    test('episode HLS uses HLS budget', () {
      expect(
        VideoPrecacheService.bytesBudgetFor('https://cdn.example.com/a.m3u8'),
        StoryConstants.precacheBytesHls,
      );
    });

    test('episode MP4 uses MP4 budget', () {
      expect(
        VideoPrecacheService.bytesBudgetFor('https://cdn.example.com/a.mp4'),
        StoryConstants.precacheBytesMp4,
      );
    });

    test('banner HLS uses banner HLS budget', () {
      expect(
        VideoPrecacheService.bytesBudgetFor(
          'https://cdn.example.com/a.m3u8',
          context: VideoPrecacheContext.banner,
        ),
        StoryConstants.precacheBytesBannerHls,
      );
    });

    test('banner MP4 uses banner MP4 budget', () {
      expect(
        VideoPrecacheService.bytesBudgetFor(
          'https://cdn.example.com/a.mp4',
          context: VideoPrecacheContext.banner,
        ),
        StoryConstants.precacheBytesBannerMp4,
      );
    });

    test('recommend head uses 6s first-segment budget for HLS and MP4', () {
      expect(
        VideoPrecacheService.bytesBudgetFor(
          'https://cdn.example.com/a.m3u8',
          context: VideoPrecacheContext.recommendHead,
        ),
        StoryConstants.precacheBytesRecommendHead,
      );
      expect(
        VideoPrecacheService.bytesBudgetFor(
          'https://cdn.example.com/a.mp4',
          context: VideoPrecacheContext.recommendHead,
        ),
        StoryConstants.precacheBytesRecommendHead,
      );
    });

    test('unknown format falls back to default', () {
      expect(
        VideoPrecacheService.bytesBudgetFor('https://cdn.example.com/stream'),
        StoryConstants.precacheBytesDefault,
      );
    });
  });

  group('VideoPrecacheService warm TTL', () {
    const url = 'https://cdn.example.com/a.m3u8';

    tearDown(VideoPrecacheService.instance.debugClearWarmed);

    test('skips precacheUrl when the same URL was just warmed', () async {
      VideoPrecacheService.instance.debugMarkWarmed(
        url,
        context: VideoPrecacheContext.recommendHead,
      );
      expect(
        await VideoPrecacheService.instance.precacheUrl(
          url,
          context: VideoPrecacheContext.recommendHead,
        ),
        isTrue,
      );
    });

    test('expired warm is not treated as fresh', () {
      VideoPrecacheService.instance.debugMarkWarmed(
        url,
        context: VideoPrecacheContext.recommendHead,
        at: DateTime.now().subtract(const Duration(seconds: 61)),
      );
      expect(
        VideoPrecacheService.instance.debugIsFreshlyWarmed(
          url,
          context: VideoPrecacheContext.recommendHead,
        ),
        isFalse,
      );
    });

    test('different context does not share the warm stamp', () {
      VideoPrecacheService.instance.debugMarkWarmed(
        url,
        context: VideoPrecacheContext.recommendHead,
      );
      expect(VideoPrecacheService.instance.debugIsFreshlyWarmed(url), isFalse);
    });
  });

  group('VideoUrlHelpers via precache budgets', () {
    test('format detection is shared with helpers', () {
      expect(
        VideoUrlHelpers.formatOf('https://cdn.example.com/a.m3u8'),
        VideoUrlFormat.hls,
      );
      expect(
        VideoUrlHelpers.formatOf('https://cdn.example.com/a.mp4'),
        VideoUrlFormat.mp4,
      );
    });
  });
}
