import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/feed_media_load.dart';
import 'package:story_app/src/controller/feed_playback_policy.dart';
import 'package:story_app/src/controller/playback_engine.dart';
import 'package:story_app/src/model/models.dart';

class MockPlaybackEngine extends Mock implements PlaybackEngine {}

void main() {
  group('FeedMediaLoad.resolveHttpEpisodeData', () {
    late MockPlaybackEngine engine;

    setUp(() {
      engine = MockPlaybackEngine();
    });

    test('returns ok when play payload has http url', () async {
      const play = DramaPlayResponse(
        dramaId: 'd',
        episodeNo: 1,
        mediaAccessUrl: 'https://cdn.example/a.m3u8',
      );
      when(() => engine.episodeDataFromPlay(play)).thenReturn(
        const PlaybackEpisodeData(
          play: play,
          url: 'https://cdn.example/a.m3u8',
          headers: {},
        ),
      );

      final result = await FeedMediaLoad.resolveHttpEpisodeData(
        engine: engine,
        play: play,
        episodeNo: 1,
      );

      expect(result.hasData, isTrue);
      expect(result.rejectedUrl, isFalse);
      verifyNever(() => engine.fetchEpisodeData(any()));
    });

    test('marks rejectedUrl for non-http play url', () async {
      const play = DramaPlayResponse(
        dramaId: 'd',
        episodeNo: 1,
        mediaAccessUrl: 'file://local',
      );
      when(() => engine.episodeDataFromPlay(play)).thenReturn(
        const PlaybackEpisodeData(
          play: play,
          url: 'file://local',
          headers: {},
        ),
      );

      final result = await FeedMediaLoad.resolveHttpEpisodeData(
        engine: engine,
        play: play,
        episodeNo: 1,
      );

      expect(result.hasData, isFalse);
      expect(result.rejectedUrl, isTrue);
    });

    test('falls back to fetch when play data missing', () async {
      const play = DramaPlayResponse(dramaId: 'd', episodeNo: 2);
      when(() => engine.episodeDataFromPlay(play)).thenReturn(null);
      when(() => engine.fetchEpisodeData(2)).thenAnswer(
        (_) async => const PlaybackEpisodeData(
          play: play,
          url: 'https://cdn.example/b.m3u8',
          headers: {},
        ),
      );

      final result = await FeedMediaLoad.resolveHttpEpisodeData(
        engine: engine,
        play: play,
        episodeNo: 2,
      );

      expect(result.hasData, isTrue);
      expect(result.data!.url, 'https://cdn.example/b.m3u8');
    });

    test('optional peekCachedPlay runs before network fetch', () async {
      const peeked = DramaPlayResponse(
        dramaId: 'd',
        episodeNo: 3,
        mediaAccessUrl: 'https://cdn.example/peek.m3u8',
      );
      when(() => engine.episodeDataFromPlay(peeked)).thenReturn(
        const PlaybackEpisodeData(
          play: peeked,
          url: 'https://cdn.example/peek.m3u8',
          headers: {},
        ),
      );

      final result = await FeedMediaLoad.resolveHttpEpisodeData(
        engine: engine,
        play: null,
        episodeNo: 3,
        peekCachedPlay: (ep) async {
          expect(ep, 3);
          return peeked;
        },
      );

      expect(result.hasData, isTrue);
      expect(result.data!.url, 'https://cdn.example/peek.m3u8');
      verifyNever(() => engine.fetchEpisodeData(any()));
    });
  });

  group('FeedPlaybackPolicy.shouldSkipNeighborPreload', () {
    test('skips when decoded frame already matches', () {
      expect(
        FeedPlaybackPolicy.shouldSkipNeighborPreload(
          slotPlaybackId: 'a',
          itemPlaybackId: 'a',
          loadedPlayPlaybackId: 'a',
          frameReady: true,
          hasPendingLoad: false,
          hasInflightReady: false,
        ),
        isTrue,
      );
    });

    test('skips when matching preload is in flight', () {
      expect(
        FeedPlaybackPolicy.shouldSkipNeighborPreload(
          slotPlaybackId: 'a',
          itemPlaybackId: 'a',
          loadedPlayPlaybackId: null,
          frameReady: false,
          hasPendingLoad: true,
          hasInflightReady: true,
        ),
        isTrue,
      );
    });

    test('does not skip for a different card', () {
      expect(
        FeedPlaybackPolicy.shouldSkipNeighborPreload(
          slotPlaybackId: 'a',
          itemPlaybackId: 'b',
          loadedPlayPlaybackId: 'a',
          frameReady: true,
          hasPendingLoad: false,
          hasInflightReady: false,
        ),
        isFalse,
      );
    });
  });

  group('FeedMediaLoad.applyColdPlayback', () {
    late MockPlaybackEngine engine;

    setUp(() {
      engine = MockPlaybackEngine();
      registerFallbackValue(Duration.zero);
      registerFallbackValue(
        const DramaPlayResponse(
          dramaId: 'd',
          episodeNo: 1,
          mediaAccessUrl: 'https://cdn.example/a.m3u8',
        ),
      );
    });

    test('forwards startAt to applyPlayback', () async {
      const play = DramaPlayResponse(
        dramaId: 'd',
        episodeNo: 1,
        mediaAccessUrl: 'https://cdn.example/a.m3u8',
      );
      const data = PlaybackEpisodeData(
        play: play,
        url: 'https://cdn.example/a.m3u8',
        headers: {'Cookie': 'x'},
      );
      when(() => engine.preApplyCookies(play, data.url)).thenAnswer(
        (_) async => true,
      );
      when(
        () => engine.applyPlayback(
          play,
          data.url,
          data.headers,
          isSwitch: any(named: 'isSwitch'),
          episodeNo: any(named: 'episodeNo'),
          cookiePreApplied: any(named: 'cookiePreApplied'),
          shouldContinue: any(named: 'shouldContinue'),
          viewReadyDelay: any(named: 'viewReadyDelay'),
          startAt: any(named: 'startAt'),
        ),
      ).thenAnswer((_) async => true);

      const startAt = Duration(seconds: 42);
      final ok = await FeedMediaLoad.applyColdPlayback(
        engine: engine,
        data: data,
        episodeNo: 1,
        isSwitch: false,
        shouldContinue: () => true,
        startAt: startAt,
      );

      expect(ok, isTrue);
      final captured = verify(
        () => engine.applyPlayback(
          play,
          data.url,
          data.headers,
          isSwitch: false,
          episodeNo: 1,
          cookiePreApplied: any(named: 'cookiePreApplied'),
          shouldContinue: any(named: 'shouldContinue'),
          viewReadyDelay: any(named: 'viewReadyDelay'),
          startAt: captureAny(named: 'startAt'),
        ),
      ).captured;
      expect(captured.single, startAt);
    });
  });
}
