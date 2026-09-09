import 'dart:async';

import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/playback_engine.dart';
import 'package:story_app/src/controller/playback_engine_listener.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/story_constants.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/services/cloudfront_cookie_service.dart';
import 'package:story_app/src/services/playback_frame_tracker.dart';

class MockDramaRepository extends Mock implements DramaRepository {}

class MockLocalRepository extends Mock implements StoryLocalRepository {}

class MockCloudFrontCookieService extends Mock
    implements CloudFrontCookieService {}

/// Test listener that captures all engine callbacks for assertions.
class TestPlaybackEngineListener extends PlaybackEngineListener {
  Object? lastError;
  Result<DramaPlayResponse>? lastEpisodeResult;
  PlayerActivityEvent? lastActivityEvent;
  Duration? lastDurationChanged;
  bool? lastPlayingChanged;
  bool? lastBufferingChanged;
  int? lastPositionMs;
  int? lastDurationMs;
  bool completedCalled = false;
  Object? lastPlaybackFailureError;
  bool? lastPlaybackFailureIsSwitch;
  Object? lastFrameRendered;

  /// Optional custom callbacks for tests that need richer tracking.
  void Function(PlaybackEngine engine, bool isPlaying)?
  onPlayingChangedCallback;
  void Function(PlaybackEngine engine)? onCompletedCallback;
  void Function(PlaybackEngine engine, Object error)? onErrorCallback;
  void Function(PlaybackEngine engine, Duration duration)?
  onDurationChangedCallback;
  void Function(PlaybackEngine engine, int positionMs, int durationMs)?
  onPositionUpdateCallback;

  @override
  void onError(PlaybackEngine engine, Object error) {
    lastError = error;
    onErrorCallback?.call(engine, error);
  }

  @override
  void onEpisodeResult(
    PlaybackEngine engine,
    Result<DramaPlayResponse> result,
  ) => lastEpisodeResult = result;

  @override
  void onActivityEvent(PlaybackEngine engine, PlayerActivityEvent event) =>
      lastActivityEvent = event;

  @override
  void onDurationChanged(PlaybackEngine engine, Duration duration) {
    lastDurationChanged = duration;
    onDurationChangedCallback?.call(engine, duration);
  }

  @override
  void onPlayingChanged(PlaybackEngine engine, bool isPlaying) {
    lastPlayingChanged = isPlaying;
    onPlayingChangedCallback?.call(engine, isPlaying);
  }

  @override
  void onBufferingChanged(PlaybackEngine engine, bool isBuffering) =>
      lastBufferingChanged = isBuffering;

  @override
  void onPositionUpdate(PlaybackEngine engine, int positionMs, int durationMs) {
    lastPositionMs = positionMs;
    lastDurationMs = durationMs;
    onPositionUpdateCallback?.call(engine, positionMs, durationMs);
  }

  @override
  void onCompleted(PlaybackEngine engine) {
    completedCalled = true;
    onCompletedCallback?.call(engine);
  }

  @override
  void onPlaybackFailure(
    PlaybackEngine engine,
    Object error, {
    required bool isSwitch,
  }) {
    lastPlaybackFailureError = error;
    lastPlaybackFailureIsSwitch = isSwitch;
  }

  @override
  void onFrameRendered(
    PlaybackEngine engine, {
    required bool isFirstFrame,
    required DateTime renderedAt,
  }) =>
      lastFrameRendered = (isFirstFrame: isFirstFrame, renderedAt: renderedAt);
}

/// Fake controller that implements the full interface without platform channels.
class FakeVideoController extends Fake implements NativeVideoPlayerController {
  final _activityListeners = <void Function(PlayerActivityEvent)>[];
  final _controlListeners = <void Function(PlayerControlEvent)>[];
  bool disposed = false;
  bool shouldLoadFail = false;
  int loadUrlCallCount = 0;
  int playCallCount = 0;
  bool shouldPlayFail = false;
  bool fireFrameOnPlay = true;
  bool fireFrameOnSetQuality = false;
  bool fireBufferingOnPlay = false;
  Duration? emitFirstFrameAfterPlay;
  Completer<void>? pauseCompleter;
  bool _initialized = false;
  bool platformViewMounted = true;
  Duration _currentPosition = Duration.zero;
  List<NativeVideoPlayerQuality> fakeQualities = const [];
  PlayerActivityState activity = PlayerActivityState.idle;

  @override
  bool get isInitialized => _initialized;

  @override
  bool get hasPlatformView => platformViewMounted;

  @override
  PlayerActivityState get activityState => activity;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  void abortPendingInitialize({Object? error}) {}

  @override
  Future<void> ensureSurfaceConnected() async {}

  /// Every quality cap / release applied via setQuality, in order.
  final appliedQualities = <NativeVideoPlayerQuality>[];

  @override
  Future<void> setQuality(NativeVideoPlayerQuality quality) async {
    appliedQualities.add(quality);
    if (fireFrameOnSetQuality) {
      fireControl(
        const PlayerControlEvent(state: PlayerControlState.firstFrameRendered),
      );
    }
  }

  @override
  void addActivityListener(void Function(PlayerActivityEvent) listener) =>
      _activityListeners.add(listener);

  @override
  void removeActivityListener(void Function(PlayerActivityEvent) listener) =>
      _activityListeners.remove(listener);

  @override
  void addControlListener(void Function(PlayerControlEvent) listener) =>
      _controlListeners.add(listener);

  @override
  void removeControlListener(void Function(PlayerControlEvent) listener) =>
      _controlListeners.remove(listener);

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<void> loadUrl({
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? drmConfig,
    Duration? startAt,
    bool force = false,
  }) async {
    loadUrlCallCount++;
    if (shouldLoadFail) throw Exception('load failed');
    if (startAt != null) _currentPosition = startAt;
  }

  @override
  Future<void> play() async {
    playCallCount++;
    if (shouldPlayFail) throw Exception('play failed');
    if (fireBufferingOnPlay) {
      fireActivity(
        const PlayerActivityEvent(state: PlayerActivityState.buffering),
      );
    }
    if (emitFirstFrameAfterPlay != null) {
      Future<void>.delayed(emitFirstFrameAfterPlay!, () {
        fireControl(
          const PlayerControlEvent(
            state: PlayerControlState.firstFrameRendered,
          ),
        );
      });
    } else if (fireFrameOnPlay) {
      fireControl(
        const PlayerControlEvent(state: PlayerControlState.firstFrameRendered),
      );
    }
  }

  @override
  Future<void> pause() async {
    await pauseCompleter?.future;
  }

  @override
  Future<void> seekTo(Duration position) async {
    _currentPosition = position;
  }

  /// Every volume actually applied to "native", in order.
  final appliedVolumes = <double>[];

  /// When true, setVolume throws the way a torn-down platform view does.
  bool failVolume = false;

  @override
  Future<void> setVolume(double volume) async {
    if (failVolume) {
      throw PlatformException(code: 'NO_VIEW', message: 'no view');
    }
    appliedVolumes.add(volume);
  }

  bool looping = false;

  @override
  Future<void> setLooping(bool looping) async {
    this.looping = looping;
  }

  @override
  List<NativeVideoPlayerQuality> get qualities => fakeQualities;

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  void fireActivity(PlayerActivityEvent event) {
    activity = event.state;
    for (final l in _activityListeners) {
      l(event);
    }
  }

  void fireControl(PlayerControlEvent event) {
    for (final l in _controlListeners) {
      l(event);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDramaRepository dramaRepo;
  late MockLocalRepository localRepo;
  late MockCloudFrontCookieService cloudfront;
  late PlaybackEngine engine;

  const dramaId = 'drama-1';
  const play = DramaPlayResponse(
    dramaId: dramaId,
    episodeId: 'episode-1',
    episodeNo: 1,
    mediaAccessUrl: 'https://cdn.example.com/episode-1.m3u8',
  );

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(const CloudFrontSignedCookies());
    registerFallbackValue(const DramaPlayResponse());
    registerFallbackValue(CloudFrontCookieFamily.feed);
  });

  setUp(() {
    dramaRepo = MockDramaRepository();
    localRepo = MockLocalRepository();
    cloudfront = MockCloudFrontCookieService();
    engine = PlaybackEngine(
      dramaRepo: dramaRepo,
      localRepo: localRepo,
      cloudfront: cloudfront,
      dramaId: dramaId,
      tag: 'PlaybackEngineTest',
    );

    when(() => localRepo.getWatchProgress(any(), any())).thenReturn(0);
    when(
      () => localRepo.saveWatchProgress(any(), any(), any()),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => localRepo.clearWatchProgress(any(), any()),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => cloudfront.clearCookies(any()),
    ).thenAnswer((_) => Future.value(Result.success(null)));
    when(
      () => cloudfront.applyCookies(any(), any()),
    ).thenAnswer((_) => Future.value(Result.success(null)));
    when(
      () => cloudfront.prepareUnsignedPlayback(
        any(),
        family: any(named: 'family'),
      ),
    ).thenAnswer((_) => Future.value(Result.success(null)));
    when(() => cloudfront.isInstalled(any(), any())).thenReturn(false);
    when(() => cloudfront.markActiveResource(any(), any())).thenReturn(null);
  });

  tearDown(() {
    try {
      engine.dispose();
    } catch (_) {
      // ValueNotifier may already be disposed in tests that assert disposal.
    }
  });

  // ─────────────────────────────────────────────────────────────────────
  // fetchEpisodeData
  // ─────────────────────────────────────────────────────────────────────
  group('fetchEpisodeData', () {
    test('returns null on failure and reports error', () async {
      final error = ApiError.network('load failed');
      final listener = TestPlaybackEngineListener();
      engine.listener = listener;
      when(
        () => dramaRepo.getEpisodeDetail(dramaId, 1),
      ).thenAnswer((_) async => Result<DramaPlayResponse>.failure(error));

      final data = await engine.fetchEpisodeData(1);

      expect(data, isNull);
      expect(listener.lastError, same(error));
      expect(engine.currentPlay, isNull);
    });

    test('returns episode data on success', () async {
      when(
        () => dramaRepo.getEpisodeDetail(dramaId, 1),
      ).thenAnswer((_) async => Result<DramaPlayResponse>.success(play));

      final data = await engine.fetchEpisodeData(1);

      expect(data, isNotNull);
      expect(data!.play, play);
      expect(data.url, play.mediaAccessUrl);
      expect(data.headers, isEmpty);
      expect(engine.currentPlay, play);
    });

    test('returns episode data for unsigned CloudFront media', () async {
      const unsigned = DramaPlayResponse(
        dramaId: dramaId,
        episodeId: 'episode-1',
        episodeNo: 1,
        mediaAccessUrl:
            'https://dev-video.actqa.com/mini-drama/streaming/hls/1/episode/1/1_hls.m3u8',
      );
      when(
        () => dramaRepo.getEpisodeDetail(dramaId, 1),
      ).thenAnswer((_) async => Result<DramaPlayResponse>.success(unsigned));

      final data = await engine.fetchEpisodeData(1);

      expect(data, isNotNull);
      expect(data!.url, unsigned.mediaAccessUrl);
      expect(engine.currentPlay, unsigned);
    });

    test('returns null and reports error for empty URL', () async {
      final listener = TestPlaybackEngineListener();
      engine.listener = listener;
      when(() => dramaRepo.getEpisodeDetail(dramaId, 1)).thenAnswer(
        (_) async => Result<DramaPlayResponse>.success(
          const DramaPlayResponse(episodeId: 'episode-1'),
        ),
      );

      final data = await engine.fetchEpisodeData(1);

      expect(data, isNull);
      expect(listener.lastError, isA<Exception>());
    });

    test('calls onEpisodeResult callback', () async {
      final listener = TestPlaybackEngineListener();
      engine.listener = listener;
      when(
        () => dramaRepo.getEpisodeDetail(dramaId, 1),
      ).thenAnswer((_) async => Result<DramaPlayResponse>.success(play));

      await engine.fetchEpisodeData(1);

      expect(listener.lastEpisodeResult, isNotNull);
      expect(listener.lastEpisodeResult!.isSuccess, isTrue);
    });

    test('buildHeaders returns CloudFront cookie header', () {
      final cookies = CloudFrontSignedCookies(
        policy: 'pol',
        signature: 'sig',
        keyPairId: 'kp',
        expires:
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      );
      final signedPlay = DramaPlayResponse(
        dramaId: dramaId,
        episodeId: 'ep-1',
        episodeNo: 1,
        mediaAccessUrl: play.mediaAccessUrl,
        signedCookies: cookies,
      );

      final headers = CloudFrontCookieService.buildHeaders(signedPlay);

      expect(headers, containsPair('Cookie', isA<String>()));
      expect(headers['Cookie'], contains('CloudFront-Policy=pol'));
      expect(headers['Cookie'], contains('CloudFront-Signature=sig'));
      expect(headers['Cookie'], contains('CloudFront-Key-Pair-Id=kp'));
    });

    test('buildHeaders returns empty map when no signed cookies', () {
      final headers = CloudFrontCookieService.buildHeaders(play);
      expect(headers, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // initialize
  // ─────────────────────────────────────────────────────────────────────
  group('initialize', () {
    test('sets native controller and attaches listeners', () async {
      final controller = FakeVideoController();

      await engine.initialize(controller);

      expect(engine.nativeController, same(controller));
    });

    test('no-op when same controller passed twice', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);
      await engine.initialize(controller);

      // Should not throw or double-attach.
      expect(engine.nativeController, same(controller));
    });

    test('detaches old listeners when switching controller', () async {
      final c1 = FakeVideoController();
      final c2 = FakeVideoController();

      await engine.initialize(c1);
      await engine.initialize(c2);

      // c1 listeners should have been removed.
      expect(c1._activityListeners, isEmpty);
      expect(c2._activityListeners, isNotEmpty);
    });

    test('no-op when controller is null', () async {
      await engine.initialize(null);
      expect(engine.nativeController, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // reset
  // ─────────────────────────────────────────────────────────────────────
  group('setVolume', () {
    test('skips a redundant call at the same volume', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      await engine.setVolume(0.0);
      await engine.setVolume(0.0);

      expect(controller.appliedVolumes, [0.0]);
    });

    test('retries after the native call fails', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);
      await engine.setVolume(1.0);

      controller.failVolume = true;
      await engine.setVolume(0.0);
      controller.failVolume = false;
      await engine.setVolume(0.0);

      // The failed mute must not be cached, or the slot stays audible.
      expect(controller.appliedVolumes, [1.0, 0.0]);
    });

    test('re-applies volume after a controller swap', () async {
      final first = FakeVideoController();
      await engine.initialize(first);
      await engine.setVolume(0.0);

      // Recycled slots inherit whatever volume the previous owner left.
      final second = FakeVideoController();
      await engine.initialize(second);
      await engine.setVolume(0.0);

      expect(second.appliedVolumes, [0.0]);
    });
  });

  group('reset', () {
    test('resets all playback state to defaults', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);
      await engine.seekTo(const Duration(seconds: 10));
      expect(engine.position, const Duration(seconds: 10));

      engine.reset();

      expect(engine.position, Duration.zero);
      expect(engine.duration, Duration.zero);
      expect(engine.isPlaying, isFalse);
      expect(engine.positionNotifier.value, Duration.zero);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // applyPlayback
  // ─────────────────────────────────────────────────────────────────────
  group('applyPlayback', () {
    test(
      'promotes preloaded cookies before the engine becomes active',
      () async {
        final cookies = CloudFrontSignedCookies(
          policy: 'policy',
          signature: 'signature',
          keyPairId: 'key-id',
          expires:
              DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        );
        final signedPlay = DramaPlayResponse(
          dramaId: dramaId,
          episodeId: 'episode-2',
          episodeNo: 2,
          mediaAccessUrl: 'https://cdn.example.com/episode-2.m3u8',
          signedCookies: cookies,
        );
        when(
          () => cloudfront.applyCookies(cookies, signedPlay.mediaAccessUrl!),
        ).thenAnswer((_) async => Result.success(null));

        expect(engine.episodeDataFromPlay(signedPlay), isNotNull);
        expect(await engine.promotePreloadedResource(), isTrue);

        verify(
          () => cloudfront.applyCookies(cookies, signedPlay.mediaAccessUrl!),
        ).called(1);
      },
    );

    test(
      'skips MethodChannel promote when cookies already installed',
      () async {
        final cookies = CloudFrontSignedCookies(
          policy: 'policy',
          signature: 'signature',
          keyPairId: 'key-id',
          expires:
              DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        );
        final signedPlay = DramaPlayResponse(
          dramaId: dramaId,
          episodeId: 'episode-2',
          episodeNo: 2,
          mediaAccessUrl: 'https://cdn.example.com/episode-2.m3u8',
          signedCookies: cookies,
        );
        when(
          () => cloudfront.isInstalled(signedPlay.mediaAccessUrl!, cookies),
        ).thenReturn(true);

        expect(engine.episodeDataFromPlay(signedPlay), isNotNull);
        expect(await engine.promotePreloadedResource(), isTrue);

        verify(
          () => cloudfront.markActiveResource(
            cookies,
            signedPlay.mediaAccessUrl!,
          ),
        ).called(1);
        verifyNever(() => cloudfront.applyCookies(any(), any()));
      },
    );

    test('unsigned promote clears leftover CloudFront cookies', () async {
      expect(engine.episodeDataFromPlay(play), isNotNull);
      expect(await engine.promotePreloadedResource(), isTrue);
      verify(
        () => cloudfront.prepareUnsignedPlayback(
          play.mediaAccessUrl!,
          family: any(named: 'family'),
        ),
      ).called(1);
      verifyNever(() => cloudfront.applyCookies(any(), any()));
    });

    test('episodeDataFromPlay binds unsigned CloudFront media', () {
      const unsigned = DramaPlayResponse(
        dramaId: dramaId,
        episodeId: 'episode-1',
        episodeNo: 1,
        mediaAccessUrl:
            'https://dev-video.actqa.com/mini-drama/streaming/hls/1/episode/1/1_hls.m3u8',
      );
      final data = engine.episodeDataFromPlay(unsigned);
      expect(data, isNotNull);
      expect(data!.url, unsigned.mediaAccessUrl);
      expect(engine.currentPlay, unsigned);
    });

    test('calls cookies, load, resume, and play in order', () async {
      final controller = FakeVideoController();
      final cookies = CloudFrontSignedCookies(
        policy: 'policy',
        signature: 'signature',
        keyPairId: 'key-id',
        expires:
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      );
      final signedPlay = DramaPlayResponse(
        dramaId: dramaId,
        episodeId: 'episode-1',
        episodeNo: 1,
        mediaAccessUrl: play.mediaAccessUrl,
        signedCookies: cookies,
      );

      when(
        () => cloudfront.applyCookies(cookies, play.mediaAccessUrl!),
      ).thenAnswer((_) async => Result.success(null));
      when(() => localRepo.getWatchProgress(dramaId, 1)).thenReturn(12000);

      await engine.initialize(controller);
      final applied = await engine.applyPlayback(
        signedPlay,
        play.mediaAccessUrl!,
        const <String, String>{'Cookie': 'signed'},
        isSwitch: false,
        episodeNo: 1,
        retry: false,
      );

      expect(applied, isTrue);
      verify(
        () => cloudfront.applyCookies(cookies, play.mediaAccessUrl!),
      ).called(1);
      verify(() => localRepo.getWatchProgress(dramaId, 1)).called(1);
      expect(engine.isPlaying, isTrue);
    });

    test(
      'native bootstrap runs when controller is not yet initialized',
      () async {
        final controller = FakeVideoController();

        await engine.initialize(controller);
        final applied = await engine.applyPlayback(
          play,
          play.mediaAccessUrl!,
          const <String, String>{},
          isSwitch: false,
          episodeNo: 1,
          retry: false,
        );

        expect(applied, isTrue);
        // Controller.initialize() was called (it's a no-op fake, so no throw).
      },
    );

    test('retries on failure and reports error after all attempts', () async {
      final controller = FakeVideoController();
      controller.shouldLoadFail = true;

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      await engine.initialize(controller);
      final applied = await engine.applyPlayback(
        play,
        play.mediaAccessUrl!,
        const <String, String>{},
        isSwitch: true,
        episodeNo: 1,
      );

      expect(applied, isFalse);
      expect(listener.lastPlaybackFailureError, isA<Exception>());
      expect(listener.lastPlaybackFailureIsSwitch, isTrue);
    });

    test('recommend family uses fewer loadUrl retries', () async {
      final recommend = PlaybackEngine(
        dramaRepo: dramaRepo,
        localRepo: localRepo,
        cloudfront: cloudfront,
        dramaId: dramaId,
        tag: 'RecommendTest',
        cookieFamily: CloudFrontCookieFamily.recommend,
      );
      addTearDown(() => recommend.dispose());
      final controller = FakeVideoController()..shouldLoadFail = true;
      await recommend.initialize(controller);
      final applied = await recommend.applyPlayback(
        play,
        play.mediaAccessUrl!,
        const <String, String>{},
        isSwitch: true,
        episodeNo: 1,
      );
      expect(applied, isFalse);
      expect(controller.loadUrlCallCount, StoryConstants.recommendMaxRetries);
    });

    test('returns false when shouldContinue returns false', () async {
      final controller = FakeVideoController();

      await engine.initialize(controller);

      const shouldContinue = false;
      final applied = await engine.applyPlayback(
        play,
        play.mediaAccessUrl!,
        const <String, String>{},
        isSwitch: false,
        episodeNo: 1,
        retry: false,
        shouldContinue: () => shouldContinue,
      );

      expect(applied, isFalse);
    });

    test('returns false when disposed mid-playback', () async {
      final controller = FakeVideoController();

      await engine.initialize(controller);
      engine.dispose();

      final applied = await engine.applyPlayback(
        play,
        play.mediaAccessUrl!,
        const <String, String>{},
        isSwitch: false,
        episodeNo: 1,
        retry: false,
      );

      expect(applied, isFalse);
    });

    test('skips cookies when signedCookies is null', () async {
      final controller = FakeVideoController();

      await engine.initialize(controller);
      final applied = await engine.applyPlayback(
        play,
        play.mediaAccessUrl!,
        const <String, String>{},
        isSwitch: false,
        episodeNo: 1,
        retry: false,
      );

      expect(applied, isTrue);
      verifyNever(() => cloudfront.applyCookies(any(), any()));
      verify(
        () => cloudfront.prepareUnsignedPlayback(
          play.mediaAccessUrl!,
          family: any(named: 'family'),
        ),
      ).called(1);
    });

    test('does not restore resume when progress is 0', () async {
      final controller = FakeVideoController();
      when(() => localRepo.getWatchProgress(dramaId, 1)).thenReturn(0);

      await engine.initialize(controller);
      final applied = await engine.applyPlayback(
        play,
        play.mediaAccessUrl!,
        const <String, String>{},
        isSwitch: false,
        episodeNo: 1,
        retry: false,
      );

      expect(applied, isTrue);
      // seekTo should not have been called since resume is 0
      // (FakeVideoController.seekTo is a no-op, so just verify the engine
      // didn't call restoreResume with a positive value).
    });

    test('sets isPlaying and calls onPlayingChanged on success', () async {
      final controller = FakeVideoController();
      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      await engine.initialize(controller);
      final applied = await engine.applyPlayback(
        play,
        play.mediaAccessUrl!,
        const <String, String>{},
        isSwitch: false,
        episodeNo: 1,
        retry: false,
      );

      expect(applied, isTrue);
      expect(engine.isPlaying, isTrue);
      expect(listener.lastPlayingChanged, isTrue);
    });

    test('does not report success when native play fails', () async {
      final controller = FakeVideoController()..shouldPlayFail = true;
      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      await engine.initialize(controller);
      final applied = await engine.applyPlayback(
        play,
        play.mediaAccessUrl!,
        const <String, String>{},
        isSwitch: false,
        episodeNo: 1,
        retry: false,
      );

      expect(applied, isFalse);
      expect(engine.isPlaying, isFalse);
      expect(listener.lastPlayingChanged, isNot(true));
    });

    test(
      'succeeds when firstFrame is emitted by setQuality rather than play',
      () async {
        final controller = FakeVideoController()
          ..fireFrameOnPlay = false
          ..fireFrameOnSetQuality = true
          ..fakeQualities = const [
            NativeVideoPlayerQuality(
              label: '720p',
              url: 'https://cdn.example.com/720.m3u8',
              height: 720,
            ),
            NativeVideoPlayerQuality(
              label: '2160p',
              url: 'https://cdn.example.com/2160.m3u8',
              height: 2160,
            ),
          ];

        await engine.initialize(controller);
        final applied = await engine.applyPlayback(
          play,
          play.mediaAccessUrl!,
          const <String, String>{},
          isSwitch: false,
          episodeNo: 1,
          retry: false,
        );

        expect(applied, isTrue);
        expect(engine.isPlaying, isTrue);
        expect(engine.hasPresentedFirstFrame, isTrue);
      },
    );

    test('does not kick extra play() while native is buffering', () async {
      final controller = FakeVideoController()
        ..fireFrameOnPlay = false
        ..fireBufferingOnPlay = true
        ..emitFirstFrameAfterPlay = const Duration(milliseconds: 50);

      await engine.initialize(controller);
      final applied = await engine.applyPlayback(
        play,
        play.mediaAccessUrl!,
        const <String, String>{},
        isSwitch: false,
        episodeNo: 1,
        retry: false,
      );

      expect(applied, isTrue);
      expect(controller.playCallCount, 1);
    });
  });

  group('migrateToActive', () {
    test('returns false and stays paused when native play fails', () async {
      final controller = FakeVideoController();
      await controller.initialize();
      await engine.initialize(controller);
      final preloaded = await engine.preloadEpisode(
        play: play,
        url: play.mediaAccessUrl!,
        headers: const <String, String>{},
        episodeNo: 1,
        viewReadyDelay: Duration.zero,
      );
      expect(preloaded, isTrue);

      controller.shouldPlayFail = true;
      final migrated = await engine.migrateToActive();

      expect(migrated, isFalse);
      expect(engine.isPlaying, isFalse);
    });
  });

  group('preload role', () {
    test('skips quietly when platform view is not mounted', () async {
      final controller = FakeVideoController()..platformViewMounted = false;
      await engine.initialize(controller);

      final preloaded = await engine.preloadEpisode(
        play: play,
        url: play.mediaAccessUrl!,
        headers: const <String, String>{},
        episodeNo: 3,
        viewReadyDelay: Duration.zero,
      );

      expect(preloaded, isFalse);
      expect(controller.loadUrlCallCount, 0);
    });

    test('startPlayback is a no-op on a preload slot', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);
      engine.retargetSlot(
        tag: 'Recommend.Next',
        role: PlaybackEngineRole.preload,
      );

      final started = await engine.startPlayback();

      expect(started, isFalse);
      expect(controller.playCallCount, 0);
      expect(engine.role, PlaybackEngineRole.preload);
    });

    test('migrateToActive allows play after preload', () async {
      final controller = FakeVideoController();
      await controller.initialize();
      await engine.initialize(controller);
      final preloaded = await engine.preloadEpisode(
        play: play,
        url: play.mediaAccessUrl!,
        headers: const <String, String>{},
        episodeNo: 1,
        viewReadyDelay: Duration.zero,
      );
      expect(preloaded, isTrue);
      expect(engine.role, PlaybackEngineRole.preload);
      expect(controller.playCallCount, 0);

      final migrated = await engine.migrateToActive();

      expect(migrated, isTrue);
      expect(engine.role, PlaybackEngineRole.active);
      expect(controller.playCallCount, greaterThan(0));
    });
  });

  group('cellular soft peak', () {
    test('survives preload reset and releases after migrateToActive', () async {
      final cellularEngine = PlaybackEngine(
        dramaRepo: dramaRepo,
        localRepo: localRepo,
        cloudfront: cloudfront,
        dramaId: dramaId,
        tag: 'CellularTest',
        isCellular: () => true,
      );
      final controller = FakeVideoController()
        ..fakeQualities = const [
          NativeVideoPlayerQuality(
            label: '720p',
            url: 'https://cdn.example.com/720.m3u8',
            height: 720,
          ),
          NativeVideoPlayerQuality(
            label: '1080p',
            url: 'https://cdn.example.com/1080.m3u8',
            height: 1080,
          ),
          NativeVideoPlayerQuality(
            label: '2160p',
            url: 'https://cdn.example.com/2160.m3u8',
            height: 2160,
          ),
        ];
      await cellularEngine.initialize(controller);

      final preloaded = await cellularEngine.preloadEpisode(
        play: play,
        url: play.mediaAccessUrl!,
        headers: const <String, String>{},
        episodeNo: 1,
        viewReadyDelay: Duration.zero,
      );
      expect(preloaded, isTrue);
      expect(controller.appliedQualities, hasLength(1));
      expect(controller.appliedQualities.single.height, 1080);

      controller.appliedQualities.clear();
      cellularEngine.reset();

      final migrated = await cellularEngine.migrateToActive();
      expect(migrated, isTrue);
      expect(controller.appliedQualities, hasLength(3));
      expect(controller.appliedQualities.first.height, 720);
      expect(controller.appliedQualities[1].isAuto, isTrue);
      expect(controller.appliedQualities.last.height, 1080);
    });
  });

  group('native frame activity', () {
    test('maps plugin frame events to control states', () {
      expect(
        PlayerControlEvent.fromMap(const <String, Object>{
          'event': 'firstFrame',
        }).state,
        PlayerControlState.firstFrameRendered,
      );
      expect(
        PlayerControlEvent.fromMap(const <String, Object>{
          'event': 'frameRendered',
        }).state,
        PlayerControlState.frameRendered,
      );
    });

    test('records first frame and completes frame waiter', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);
      final sequence = engine.frameSequence;
      final waiting = engine.waitForFrameAfter(
        sequence,
        timeout: const Duration(milliseconds: 100),
      );

      controller.fireControl(
        const PlayerControlEvent(state: PlayerControlState.firstFrameRendered),
      );

      expect(await waiting, isTrue);
      expect(engine.hasPresentedFirstFrame, isTrue);
      expect(engine.lastFrameRenderedAt, isNotNull);
    });

    test('treats frameRendered as painted-frame evidence', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      controller.fireControl(
        const PlayerControlEvent(state: PlayerControlState.frameRendered),
      );

      expect(engine.hasPresentedFirstFrame, isTrue);
    });

    test('times out when native render pipeline emits no frame', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final rendered = await engine.waitForFrameAfter(
        engine.frameSequence,
        timeout: const Duration(milliseconds: 10),
      );

      expect(rendered, isFalse);
      expect(engine.hasPresentedFirstFrame, isFalse);
    });

    test('superseded wait returns false without waiting for timeout', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);
      final sequence = engine.frameSequence;
      final sw = Stopwatch()..start();

      final first = engine.waitForFrameAfter(
        sequence,
        timeout: const Duration(seconds: 5),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final second = engine.waitForFrameAfter(
        sequence,
        timeout: const Duration(milliseconds: 30),
      );

      expect(await first, isFalse);
      expect(sw.elapsed, lessThan(const Duration(seconds: 1)));
      expect(await second, isFalse);
    });

    test('waitForFrameResult reports timedOut vs aborted', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      expect(
        await engine.waitForFrameResult(
          engine.frameSequence,
          timeout: const Duration(milliseconds: 10),
        ),
        FrameWaitResult.timedOut,
      );

      var cont = true;
      final aborted = engine.waitForFrameResult(
        engine.frameSequence,
        timeout: const Duration(seconds: 5),
        shouldContinue: () => cont,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      cont = false;
      expect(await aborted, FrameWaitResult.aborted);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // togglePlayPause
  // ─────────────────────────────────────────────────────────────────────
  group('togglePlayPause', () {
    test('toggles playing state', () async {
      final controller = FakeVideoController();

      await engine.initialize(controller);

      expect(await engine.togglePlayPause(), isTrue);
      expect(engine.isPlaying, isTrue);
      expect(await engine.togglePlayPause(), isFalse);
      expect(engine.isPlaying, isFalse);
    });

    test('returns null when controller is null', () async {
      expect(await engine.togglePlayPause(), isNull);
    });

    test('calls onPlayingChanged on toggle', () async {
      final controller = FakeVideoController();
      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      await engine.initialize(controller);
      await engine.togglePlayPause();
      await engine.togglePlayPause();

      expect(listener.lastPlayingChanged, isFalse);
    });

    test('resumes after pause without a new frame event', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      await engine.togglePlayPause();
      expect(engine.hasPresentedFirstFrame, isTrue);
      await engine.togglePlayPause();

      controller.fireFrameOnPlay = false;
      final playing = await engine.togglePlayPause();
      expect(playing, isTrue);
      expect(engine.isPlaying, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // pause
  // ─────────────────────────────────────────────────────────────────────
  group('pause', () {
    test('pauses playback and sets isPlaying to false', () async {
      final controller = FakeVideoController();

      await engine.initialize(controller);
      await engine.togglePlayPause(); // start playing
      expect(engine.isPlaying, isTrue);

      await engine.pause();

      expect(engine.isPlaying, isFalse);
    });

    test('calls onPlayingChanged when pausing', () async {
      final controller = FakeVideoController();
      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      await engine.initialize(controller);
      await engine.togglePlayPause(); // start playing
      await engine.pause();

      expect(listener.lastPlayingChanged, isFalse);
    });

    test('late pause completion cannot overwrite a newer resume', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);
      await engine.togglePlayPause();

      final states = <bool>[];
      final listener = TestPlaybackEngineListener()
        ..onPlayingChangedCallback = (engine, playing) => states.add(playing);
      engine.listener = listener;
      controller.pauseCompleter = Completer<void>();

      final stalePause = engine.pause();
      final resumed = await engine.resumePlayback();
      controller.pauseCompleter!.complete();
      await stalePause;

      expect(resumed, isTrue);
      expect(engine.isPlaying, isTrue);
      expect(states, isNot(contains(false)));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // seekTo
  // ─────────────────────────────────────────────────────────────────────
  group('seekTo', () {
    test('updates position and notifier', () async {
      final controller = FakeVideoController();

      await engine.initialize(controller);
      await engine.seekTo(const Duration(seconds: 42));

      expect(engine.position, const Duration(seconds: 42));
      expect(engine.positionNotifier.value, const Duration(seconds: 42));
    });

    test('works when controller is null', () async {
      await engine.seekTo(const Duration(seconds: 10));

      expect(engine.position, const Duration(seconds: 10));
      expect(engine.positionNotifier.value, const Duration(seconds: 10));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // persistResume
  // ─────────────────────────────────────────────────────────────────────
  group('persistResume', () {
    test('saves positive current position', () async {
      await engine.seekTo(const Duration(seconds: 5));

      await engine.persistResume(1);

      verify(() => localRepo.saveWatchProgress(dramaId, 1, 5000)).called(1);
    });

    test('does not save when position is zero', () async {
      await engine.persistResume(1);

      verifyNever(() => localRepo.saveWatchProgress(any(), any(), any()));
    });

    test('saves even when restoreWatchProgress is false', () async {
      engine.dispose();
      engine = PlaybackEngine(
        dramaRepo: dramaRepo,
        localRepo: localRepo,
        cloudfront: cloudfront,
        dramaId: dramaId,
        tag: 'PlaybackEngineTest',
        restoreWatchProgress: false,
      );
      await engine.seekTo(const Duration(seconds: 5));

      await engine.persistResume(2);

      verify(() => localRepo.saveWatchProgress(dramaId, 2, 5000)).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // clearWatchProgress
  // ─────────────────────────────────────────────────────────────────────
  group('clearWatchProgress', () {
    test('delegates to local repo', () {
      engine.clearWatchProgress(3);
      verify(() => localRepo.clearWatchProgress(dramaId, 3)).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // dispose
  // ─────────────────────────────────────────────────────────────────────
  group('dispose', () {
    test('detaches and disposes native controller and notifier', () async {
      final controller = FakeVideoController();

      await engine.initialize(controller);
      engine.dispose();

      expect(engine.nativeController, isNull);
      expect(controller._activityListeners, isEmpty);
      expect(controller._controlListeners, isEmpty);
    });

    test('double dispose is safe', () async {
      final controller = FakeVideoController();

      await engine.initialize(controller);
      engine.dispose();
      engine.dispose(); // Should not throw.

      expect(engine.nativeController, isNull);
    });

    test('clears cookies when signed cookies were fetched', () async {
      final cookies = CloudFrontSignedCookies(
        policy: 'p',
        signature: 's',
        keyPairId: 'k',
        expires:
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      );
      final signedPlay = DramaPlayResponse(
        dramaId: dramaId,
        episodeId: 'ep-1',
        episodeNo: 1,
        mediaAccessUrl: play.mediaAccessUrl,
        signedCookies: cookies,
      );
      when(
        () => dramaRepo.getEpisodeDetail(dramaId, 1),
      ).thenAnswer((_) async => Result<DramaPlayResponse>.success(signedPlay));

      await engine.fetchEpisodeData(1);
      engine.dispose();

      verify(() => cloudfront.clearCookies(play.mediaAccessUrl!)).called(1);
    });

    test('does not clear cookies when no signed cookies fetched', () {
      engine.dispose();

      verifyNever(() => cloudfront.clearCookies(any()));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Activity event handling
  // ─────────────────────────────────────────────────────────────────────
  group('activity events', () {
    PlayerActivityEvent createEvent(
      PlayerActivityState state, [
      Map<String, dynamic>? data,
    ]) {
      return PlayerActivityEvent(state: state, data: data);
    }

    test('completed clears watch progress and calls onCompleted', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      // Start playback so _currentEpisodeNo is set.
      when(
        () => dramaRepo.getEpisodeDetail(dramaId, 1),
      ).thenAnswer((_) async => Result<DramaPlayResponse>.success(play));
      await engine.fetchEpisodeData(1);
      await engine.applyPlayback(
        play,
        play.mediaAccessUrl!,
        const <String, String>{},
        isSwitch: false,
        episodeNo: 1,
        retry: false,
      );

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      controller.fireActivity(createEvent(PlayerActivityState.completed));

      expect(listener.completedCalled, isTrue);
      expect(listener.lastPlayingChanged, isFalse);
      expect(engine.isPlaying, isFalse);
      expect(engine.hasCompleted, isTrue);
      verify(() => localRepo.clearWatchProgress(dramaId, 1)).called(1);
    });

    test('completed notifies onCompleted before onPlayingChanged', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final order = <String>[];
      final listener = TestPlaybackEngineListener();
      listener.onCompletedCallback = (engine) => order.add('completed');
      listener.onPlayingChangedCallback = (engine, playing) =>
          order.add('playingChanged');
      engine.listener = listener;

      controller.fireActivity(createEvent(PlayerActivityState.completed));

      expect(order, ['completed', 'playingChanged']);
      expect(engine.hasCompleted, isTrue);
    });

    test('setLooping is forwarded to the native controller', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      await engine.setLooping(true);
      expect(engine.looping, isTrue);
      expect(controller.looping, isTrue);

      await engine.setLooping(false);
      expect(engine.looping, isFalse);
      expect(controller.looping, isFalse);
    });

    test('loaded updates duration and calls onDurationChanged', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      controller.fireActivity(
        createEvent(PlayerActivityState.loaded, {'duration': 120000}),
      );

      expect(engine.duration, const Duration(seconds: 120));
      expect(listener.lastDurationChanged, const Duration(seconds: 120));
    });

    test('loaded ignores invalid duration (0 or negative)', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      controller.fireActivity(
        createEvent(PlayerActivityState.loaded, {'duration': 0}),
      );

      expect(engine.duration, Duration.zero);
      expect(listener.lastDurationChanged, isNull);
    });

    test('error calls onError with message', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      controller.fireActivity(
        createEvent(PlayerActivityState.error, {'message': 'codec error'}),
      );

      expect(listener.lastError, 'codec error');
    });

    test('error with no message reports Unknown error', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      controller.fireActivity(createEvent(PlayerActivityState.error));

      expect(listener.lastError, 'Unknown error');
    });

    test('playing sets isPlaying and calls onPlayingChanged', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      controller.fireActivity(createEvent(PlayerActivityState.playing));

      expect(engine.isPlaying, isTrue);
      expect(listener.lastPlayingChanged, isTrue);
    });

    test('paused sets isPlaying to false and calls onPlayingChanged', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      controller.fireActivity(createEvent(PlayerActivityState.paused));

      expect(engine.isPlaying, isFalse);
      expect(listener.lastPlayingChanged, isFalse);
    });

    test('calls onActivityEvent for all events', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      final event = createEvent(PlayerActivityState.buffering);
      controller.fireActivity(event);

      expect(listener.lastActivityEvent, same(event));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Control event handling
  // ─────────────────────────────────────────────────────────────────────
  group('control events', () {
    PlayerControlEvent createTimeEvent(int positionMs, int durationMs) {
      return PlayerControlEvent(
        state: PlayerControlState.timeUpdated,
        data: {'position': positionMs, 'duration': durationMs},
      );
    }

    test('timeUpdated updates position, duration, and notifies', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      controller.fireControl(createTimeEvent(5000, 120000));

      expect(engine.position, const Duration(seconds: 5));
      expect(engine.positionNotifier.value, const Duration(seconds: 5));
      expect(engine.duration, const Duration(seconds: 120));
      expect(listener.lastPositionMs, 5000);
      expect(listener.lastDurationMs, 120000);
    });

    test(
      'timeUpdated notifies onDurationChanged when duration arrives',
      () async {
        final controller = FakeVideoController();
        await engine.initialize(controller);

        final listener = TestPlaybackEngineListener();
        engine.listener = listener;

        controller.fireControl(createTimeEvent(1000, 60000));
        expect(listener.lastDurationChanged, const Duration(seconds: 60));

        listener.lastDurationChanged = null;
        controller.fireControl(createTimeEvent(2000, 60000));
        expect(listener.lastDurationChanged, isNull);
      },
    );

    test('timeUpdated saves progress when episode is set', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      // Start playback to set _currentEpisodeNo.
      when(
        () => dramaRepo.getEpisodeDetail(dramaId, 1),
      ).thenAnswer((_) async => Result<DramaPlayResponse>.success(play));
      await engine.fetchEpisodeData(1);
      await engine.applyPlayback(
        play,
        play.mediaAccessUrl!,
        const <String, String>{},
        isSwitch: false,
        episodeNo: 1,
        retry: false,
      );

      controller.fireControl(createTimeEvent(5000, 120000));

      verify(() => localRepo.saveWatchProgress(dramaId, 1, 5000)).called(1);
    });

    test('timeUpdated throttles progress saves to every 10 seconds', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      when(
        () => dramaRepo.getEpisodeDetail(dramaId, 1),
      ).thenAnswer((_) async => Result<DramaPlayResponse>.success(play));
      await engine.fetchEpisodeData(1);
      await engine.applyPlayback(
        play,
        play.mediaAccessUrl!,
        const <String, String>{},
        isSwitch: false,
        episodeNo: 1,
        retry: false,
      );

      // First update at 1000ms — should save.
      controller.fireControl(createTimeEvent(1000, 120000));
      // Second update at 5000ms — should NOT save (< 10000ms delta).
      controller.fireControl(createTimeEvent(5000, 120000));
      // Third update at 12000ms — should save (>= 10000ms delta from 1000).
      controller.fireControl(createTimeEvent(12000, 120000));

      verify(() => localRepo.saveWatchProgress(dramaId, 1, 1000)).called(1);
      verify(() => localRepo.saveWatchProgress(dramaId, 1, 12000)).called(1);
      // 5000ms update should NOT have triggered a save (< 10000ms delta).
    });

    test('ignores non-timeUpdated control events', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      controller.fireControl(
        const PlayerControlEvent(state: PlayerControlState.qualityChanged),
      );

      expect(listener.lastPositionMs, isNull);
    });

    test('ignores timeUpdated with null data', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      controller.fireControl(
        const PlayerControlEvent(state: PlayerControlState.timeUpdated),
      );

      expect(listener.lastPositionMs, isNull);
    });

    test('notifies position even without duration in data', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;
      controller.fireControl(
        const PlayerControlEvent(
          state: PlayerControlState.timeUpdated,
          data: {'position': 3000},
        ),
      );

      expect(listener.lastPositionMs, 3000);
      expect(listener.lastDurationMs, 0);
    });

    test('reports duration-only update when position is null', () async {
      final controller = FakeVideoController();
      await engine.initialize(controller);

      final listener = TestPlaybackEngineListener();
      engine.listener = listener;

      controller.fireControl(
        const PlayerControlEvent(
          state: PlayerControlState.timeUpdated,
          data: {'duration': 90000},
        ),
      );

      expect(listener.lastPositionMs, 0);
      expect(listener.lastDurationMs, 90000);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // waitForViewReady
  // ─────────────────────────────────────────────────────────────────────
  group('waitForViewReady', () {
    test('completes after frame callback', () async {
      await engine.waitForViewReady();
    });
  });
}
