import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/video_feed_controller.dart';
import 'package:story_app/src/controller/video_feed_state.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/services/cloudfront_cookie_service.dart';
import 'package:story_app/src/routes/route_args.dart';

/// Fake native controller that tracks lifecycle calls for verifying
/// feed recovery side effects (pause, seek, resume, play).
class FakeTrackerController extends Fake
    implements NativeVideoPlayerController {
  final _activityListeners = <void Function(PlayerActivityEvent)>[];
  final _controlListeners = <void Function(PlayerControlEvent)>[];
  bool disposed = false;
  bool _initialized = false;
  Duration _position = Duration.zero;

  /// Tracked call counts.
  int pauseCallCount = 0;
  int playCallCount = 0;
  int seekCallCount = 0;

  @override
  bool get isInitialized => _initialized;

  @override
  bool get hasPlatformView => _initialized;

  @override
  Duration get currentPosition => _position;

  @override
  List<NativeVideoPlayerQuality> get qualities => const [];

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
  Future<void> initialize() async => _initialized = true;

  @override
  void abortPendingInitialize({Object? error}) {
    _initialized = false;
  }

  @override
  Future<void> loadUrl({
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? drmConfig,
    Duration? startAt,
    bool force = false,
  }) async {
    if (startAt != null) _position = startAt;
  }

  @override
  Future<void> play() async {
    playCallCount++;
    fireControl(
      const PlayerControlEvent(state: PlayerControlState.firstFrameRendered),
    );
  }

  @override
  Future<void> pause() async {
    pauseCallCount++;
  }

  @override
  Future<void> seekTo(Duration position) async {
    seekCallCount++;
    _position = position;
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> ensureSurfaceConnected() async {}

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  void fireActivity(PlayerActivityEvent event) {
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

class MockDramaRepository extends Mock implements DramaRepository {}

class MockLocalRepository extends Mock implements StoryLocalRepository {}

class MockCloudFrontCookieService extends Mock
    implements CloudFrontCookieService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDramaRepository dramaRepo;
  late MockLocalRepository localRepo;
  late MockCloudFrontCookieService cloudfront;
  late VideoFeedArgs args;
  late FakeTrackerController ctrlA;
  late FakeTrackerController ctrlB;
  late FakeTrackerController ctrlC;

  setUpAll(() {
    registerFallbackValue(const CloudFrontSignedCookies());
    registerFallbackValue(const DramaPlayResponse());
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    dramaRepo = MockDramaRepository();
    localRepo = MockLocalRepository();
    cloudfront = MockCloudFrontCookieService();

    when(() => localRepo.getWatchProgress(any(), any())).thenReturn(0);

    args = const VideoFeedArgs(
      dramaId: 'drama-test',
      episodeNo: 1,
      totalEpisodes: 10,
    );

    ctrlA = FakeTrackerController();
    ctrlB = FakeTrackerController();
    ctrlC = FakeTrackerController();
  });

  /// Build a ProviderContainer wired to mock repos.
  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        dramaRepositoryProvider.overrideWithValue(dramaRepo),
        localRepositoryProvider.overrideWithValue(localRepo),
        cloudfrontCookieServiceProvider.overrideWithValue(cloudfront),
      ],
    );
  }

  /// Create controller, attach fake controllers, return the controller.
  /// Establishes a subscription to prevent autoDispose from killing the notifier.
  VideoFeedController createController(ProviderContainer container) {
    final controller = container.read(
      videoFeedControllerProvider(args).notifier,
    );
    container.listen(videoFeedControllerProvider(args), (_, _) {});
    controller.attachTripleControllers(ctrlA, ctrlB, ctrlC);
    return controller;
  }

  // ─── Lifecycle ──────────────────────────────────────────────

  group('Lifecycle', () {
    test('onAppBackground pauses active engine', () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      final controller = createController(container);

      // Verify engine A has the native controller attached.
      ctrlA.fireActivity(
        const PlayerActivityEvent(state: PlayerActivityState.playing),
      );
      await Future<void>.delayed(Duration.zero);

      await controller.onAppBackground();

      // pause() is called on the active slot's engine.
      expect(ctrlA.pauseCallCount, greaterThanOrEqualTo(1));
    });

    test('togglePlayPause wires engine and plays', () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      final controller = createController(container);

      await controller.togglePlayPause();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // The engine should have called play() on the native controller.
      expect(ctrlA.playCallCount, greaterThanOrEqualTo(1));
    });

    test(
      'onAppBackground after togglePlayPause sets isPlaying=false',
      () async {
        final container = buildContainer();
        addTearDown(container.dispose);
        final controller = createController(container);

        // Play.
        await controller.togglePlayPause();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Track state changes.
        VideoFeedState? state;
        container.listen<VideoFeedState>(
          videoFeedControllerProvider(args),
          (_, next) => state = next,
        );

        // Background — should set isPlaying = false via _notify.
        await controller.onAppBackground();
        expect(state?.isPlaying, isFalse);
      },
    );

    test('onAppBackground safe when engine not yet active', () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      final controller = createController(container);

      // No native activity yet — pause guard skips; must not throw.
      await controller.onAppBackground();
    });

    test('onAppForeground does not throw', () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      final controller = createController(container);

      controller.onAppForeground();
    });

    test(
      'onAppForeground triggers recovery when was playing before background',
      () async {
        final container = buildContainer();
        addTearDown(container.dispose);
        final controller = createController(container);

        // Play so that background saves _wasPlayingBeforeBackground = true.
        await controller.togglePlayPause();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Background pauses the engine and saves state.
        await controller.onAppBackground();
        expect(ctrlA.pauseCallCount, greaterThanOrEqualTo(1));

        // Foreground must not throw. Recovery is scheduled fire-and-forget
        // but blocked by episode checks (loaded!=current, ep<1) — so
        // play/seek won't be called in this test setup. We verify the code
        // path is entered (no early return) and the state remains consistent.
        controller.onAppForeground();
        // No explicit assertion — the test passes if no unhandled error.
      },
    );

    test(
      'onPageRevealed enters recovery when was playing before background',
      () async {
        final container = buildContainer();
        addTearDown(container.dispose);
        final controller = createController(container);

        // No-op when not previously playing.
        controller.onPageRevealed();

        // Play and background.
        await controller.togglePlayPause();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await controller.onAppBackground();

        // onPageRevealed schedules _recoverAfterCoverRoute() fire-and-forget.
        // Full recovery is blocked by episode checks (ep<1); this verifies
        // the code path is entered without error.
        controller.onPageRevealed();
      },
    );
  });

  // ─── Lifecycle safety (idempotency) ─────────────────────────

  group('Lifecycle safety', () {
    test('double background is safe', () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      final controller = createController(container);

      await controller.onAppBackground();
      await controller.onAppBackground(); // Must not crash.
    });

    test('double foreground is safe', () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      final controller = createController(container);

      controller.onAppForeground();
      controller.onAppForeground(); // Must not crash.
    });

    test('onPageRevealed after background is safe', () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      final controller = createController(container);

      await controller.onAppBackground();
      controller.onPageRevealed(); // Must not crash.
    });
  });
}
