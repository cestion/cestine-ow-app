import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/video_url_helpers.dart';

void main() {
  group('VideoUrlHelpers.formatOf', () {
    test('detects HLS', () {
      expect(
        VideoUrlHelpers.formatOf(
          'https://cdn.example.com/drama/ep1/playlist.m3u8',
        ),
        VideoUrlFormat.hls,
      );
    });

    test('detects MP4', () {
      expect(
        VideoUrlHelpers.formatOf('https://cdn.example.com/drama/ep1/video.mp4'),
        VideoUrlFormat.mp4,
      );
    });
  });

  group('VideoUrlHelpers.preferPlaySource', () {
    const lowest =
        'https://one-story-dev.s3.us-east-2.amazonaws.com/mini-drama/test/1080p/7/Lark20260703-211122.m3u8';
    const mid =
        'https://one-story-dev.s3.us-east-2.amazonaws.com/mini-drama/test/1080p/8.m3u8';
    const highest =
        'https://one-story-dev.s3.us-east-2.amazonaws.com/mini-drama/test/1080p/9.m3u8';

    test('returns single URL unchanged', () {
      expect(VideoUrlHelpers.preferPlaySource(mid), mid);
    });

    test('picks smallest numeric path segment from a list', () {
      expect(VideoUrlHelpers.preferPlaySource([highest, lowest, mid]), lowest);
    });

    test('picks smallest numeric path segment from comma-separated string', () {
      expect(VideoUrlHelpers.preferPlaySource('$highest,$lowest,$mid'), lowest);
    });

    test('drops relative and non-http URLs', () {
      expect(VideoUrlHelpers.preferPlaySource('/relative/path.m3u8'), isNull);
      expect(
        VideoUrlHelpers.preferPlaySource('ftp://cdn.example.com/a.m3u8'),
        isNull,
      );
      expect(
        VideoUrlHelpers.preferPlaySource([
          '/relative.m3u8',
          'https://cdn.example.com/ok.m3u8',
        ]),
        'https://cdn.example.com/ok.m3u8',
      );
    });

    test('reads url field from map wrappers', () {
      expect(
        VideoUrlHelpers.preferPlaySource({
          'hlsUrl': 'https://cdn.example.com/from-map.m3u8',
        }),
        'https://cdn.example.com/from-map.m3u8',
      );
    });

    test('prefers CMAF ABR master over demuxed ladder variants', () {
      const master =
          'https://dev-video.actqa.com/mini-drama/streaming/hls/'
          '452230536492322816/episode/452230624379826176/cmaf/'
          '452230624379826176.m3u8';
      const v360 =
          'https://dev-video.actqa.com/mini-drama/streaming/hls/'
          '452230536492322816/episode/452230624379826176/cmaf/'
          '452230624379826176_360p.m3u8';
      const v480 =
          'https://dev-video.actqa.com/mini-drama/streaming/hls/'
          '452230536492322816/episode/452230624379826176/cmaf/'
          '452230624379826176_480p.m3u8';
      const audio =
          'https://dev-video.actqa.com/mini-drama/streaming/hls/'
          '452230536492322816/episode/452230624379826176/cmaf/'
          '452230624379826176_audio.m3u8';

      expect(VideoUrlHelpers.isLikelyHlsMasterPlaylist(master), isTrue);
      expect(VideoUrlHelpers.isLikelyHlsVariantPlaylist(v360), isTrue);
      expect(VideoUrlHelpers.isLikelyHlsVariantPlaylist(audio), isTrue);
      expect(
        VideoUrlHelpers.preferPlaySource([v480, audio, master, v360]),
        master,
      );
    });

    test('falls back to lowest height when only variants exist', () {
      const v360 = 'https://cdn.example.com/cmaf/asset_360p.m3u8';
      const v480 = 'https://cdn.example.com/cmaf/asset_480p.m3u8';
      const v720 = 'https://cdn.example.com/cmaf/asset_720p.m3u8';
      expect(VideoUrlHelpers.preferPlaySource([v720, v360, v480]), v360);
    });
  });

  group('VideoUrlHelpers.isHttpUrl', () {
    test('accepts http and https only', () {
      expect(VideoUrlHelpers.isHttpUrl('https://a.com/x.m3u8'), isTrue);
      expect(VideoUrlHelpers.isHttpUrl('http://a.com/x.mp4'), isTrue);
      expect(VideoUrlHelpers.isHttpUrl('/x.m3u8'), isFalse);
      expect(VideoUrlHelpers.isHttpUrl(''), isFalse);
      expect(VideoUrlHelpers.isHttpUrl('http://'), isFalse);
      expect(VideoUrlHelpers.isHttpUrl('https://'), isFalse);
      expect(VideoUrlHelpers.isHttpUrl('ftp://a.com/x.mp4'), isFalse);
    });
  });

  group('VideoUrlHelpers.requiresCloudFrontCookies', () {
    test('detects actqa / story.fun video hosts and streaming paths', () {
      expect(
        VideoUrlHelpers.requiresCloudFrontCookies(
          'https://video.actqa.com/mini-drama/streaming/hls/1/episode/1/1_hls.m3u8',
        ),
        isTrue,
      );
      expect(
        VideoUrlHelpers.requiresCloudFrontCookies(
          'https://d111111abcdef8.cloudfront.net/a.m3u8',
        ),
        isTrue,
      );
      expect(
        VideoUrlHelpers.requiresCloudFrontCookies(
          'https://cdn.example.com/episode-1.m3u8',
        ),
        isFalse,
      );
      expect(
        VideoUrlHelpers.requiresCloudFrontCookies(
          'https://static-images.actqa.com/cover.png',
        ),
        isFalse,
      );
    });

    test('excludes dev- prefix hosts (no signed cookies needed)', () {
      expect(
        VideoUrlHelpers.requiresCloudFrontCookies(
          'https://dev-video.actqa.com/mini-drama/streaming/hls/1/episode/1/1_hls.m3u8',
        ),
        isFalse,
      );
      expect(
        VideoUrlHelpers.requiresCloudFrontCookies(
          'https://dev-cdn.story.fun/video.m3u8',
        ),
        isFalse,
      );
    });
  });

  group('VideoUrlHelpers.preferPosterUrl', () {
    test('prefers firstFrameUrl over coverUrl', () {
      expect(
        VideoUrlHelpers.preferPosterUrl(
          firstFrameUrl: ' https://cdn.example/frame.jpg ',
          coverUrl: 'https://cdn.example/cover.jpg',
        ),
        'https://cdn.example/frame.jpg',
      );
    });

    test('falls back to coverUrl when firstFrame is empty', () {
      expect(
        VideoUrlHelpers.preferPosterUrl(
          firstFrameUrl: '  ',
          coverUrl: 'https://cdn.example/cover.jpg',
        ),
        'https://cdn.example/cover.jpg',
      );
      expect(VideoUrlHelpers.preferPosterUrl(), isNull);
    });
  });

  group('VideoUrlHelpers.shouldReplaceEpisodePoster', () {
    test('accepts first seed and identical updates', () {
      expect(
        VideoUrlHelpers.shouldReplaceEpisodePoster(
          existing: null,
          candidate: 'https://cdn.example/frame.jpg',
        ),
        isTrue,
      );
      expect(
        VideoUrlHelpers.shouldReplaceEpisodePoster(
          existing: 'https://cdn.example/frame.jpg',
          candidate: 'https://cdn.example/frame.jpg',
        ),
        isFalse,
      );
    });

    test('keeps seeded firstFrame when candidate is cover-only', () {
      expect(
        VideoUrlHelpers.shouldReplaceEpisodePoster(
          existing: 'https://cdn.example/frame.jpg',
          candidate: 'https://cdn.example/cover.jpg',
          coverOnlyUrl: 'https://cdn.example/cover.jpg',
        ),
        isFalse,
      );
    });

    test('allows upgrade when candidate is a real firstFrame poster', () {
      expect(
        VideoUrlHelpers.shouldReplaceEpisodePoster(
          existing: 'https://cdn.example/cover.jpg',
          candidate: 'https://cdn.example/frame.jpg',
          coverOnlyUrl: 'https://cdn.example/cover.jpg',
        ),
        isTrue,
      );
    });
  });
}
