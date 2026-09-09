import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/playback_quality_policy.dart';
import 'package:story_app/src/core/story_constants.dart';

void main() {
  NativeVideoPlayerQuality q({
    required String label,
    required int height,
    int? bitrate,
    int? width,
  }) {
    return NativeVideoPlayerQuality(
      label: label,
      url: 'https://cdn.example.com/$label.m3u8',
      height: height,
      width: width ?? (height * 9 ~/ 16),
      bitrate: bitrate,
    );
  }

  group('PlaybackQualityPolicy.startupMaxHeight', () {
    test('uses cellular soft peak on mobile', () {
      expect(
        PlaybackQualityPolicy.startupMaxHeight(isCellular: true),
        StoryConstants.cellularSoftPeakVideoHeight,
      );
    });

    test('uses hard ceiling on Wi‑Fi / other', () {
      expect(
        PlaybackQualityPolicy.startupMaxHeight(isCellular: false),
        StoryConstants.maxPlaybackVideoHeight,
      );
    });
  });

  group('PlaybackQualityPolicy.shouldReleaseSoftPeak', () {
    test('only when cellular applied a stricter-than-hard cap', () {
      expect(
        PlaybackQualityPolicy.shouldReleaseSoftPeak(
          isCellular: true,
          appliedMaxHeight: StoryConstants.cellularSoftPeakVideoHeight,
        ),
        isTrue,
      );
      expect(
        PlaybackQualityPolicy.shouldReleaseSoftPeak(
          isCellular: false,
          appliedMaxHeight: StoryConstants.cellularSoftPeakVideoHeight,
        ),
        isFalse,
      );
      expect(
        PlaybackQualityPolicy.shouldReleaseSoftPeak(
          isCellular: true,
          appliedMaxHeight: StoryConstants.maxPlaybackVideoHeight,
        ),
        isFalse,
      );
    });
  });

  group('PlaybackQualityPolicy.chooseUnderMaxHeight', () {
    test('returns null for single-rung or no-op ladders', () {
      expect(
        PlaybackQualityPolicy.chooseUnderMaxHeight(
          qualities: [q(label: '720', height: 720)],
          maxHeight: 1080,
        ),
        isNull,
      );
      expect(
        PlaybackQualityPolicy.chooseUnderMaxHeight(
          qualities: [
            q(label: '360', height: 360),
            q(label: '480', height: 480),
          ],
          maxHeight: 480,
        ),
        isNull,
      );
    });

    test('picks highest rung under soft peak when taller rungs exist', () {
      final chosen = PlaybackQualityPolicy.chooseUnderMaxHeight(
        qualities: [
          q(label: '360', height: 360, bitrate: 400000),
          q(label: '480', height: 480, bitrate: 700000),
          q(label: '720', height: 720, bitrate: 1500000),
          q(label: '1080', height: 1080, bitrate: 3000000),
          NativeVideoPlayerQuality.auto(),
        ],
        maxHeight: 480,
      );
      expect(chosen?.height, 480);
    });

    test('falls back to lowest when every rung exceeds the cap', () {
      final chosen = PlaybackQualityPolicy.chooseUnderMaxHeight(
        qualities: [
          q(label: '720', height: 720),
          q(label: '1080', height: 1080),
        ],
        maxHeight: 480,
      );
      expect(chosen?.height, 720);
    });

    test('hard ceiling prefers 1080 over 4K', () {
      final chosen = PlaybackQualityPolicy.chooseUnderMaxHeight(
        qualities: [
          q(label: '720', height: 720),
          q(label: '1080', height: 1080),
          q(label: '2160', height: 2160),
        ],
        maxHeight: 1080,
      );
      expect(chosen?.height, 1080);
    });
  });
}
