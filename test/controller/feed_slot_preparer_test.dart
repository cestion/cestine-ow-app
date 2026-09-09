import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/feed_slot.dart';
import 'package:story_app/src/controller/feed_slot_preparer.dart';
import 'package:story_app/src/controller/playback_engine.dart';
import 'package:story_app/src/services/native_video_player_coordinator.dart';

class MockPlaybackEngine extends Mock implements PlaybackEngine {}

class MockNativeController extends Mock
    implements NativeVideoPlayerController {}

class _FakePrepareHost implements FeedSlotPrepareHost {
  bool mountedFlag = true;
  int notifyCalls = 0;
  int invalidateCalls = 0;
  int createEngineCalls = 0;
  int createNativeCalls = 0;

  @override
  bool get isMounted => mountedFlag;

  @override
  NativeVideoPlayerController createNativeController() {
    createNativeCalls++;
    return MockNativeController();
  }

  @override
  PlaybackEngine createEngine({
    required String bindWorkId,
    required String tag,
    required NativeVideoPlayerCoordinator coordinator,
  }) {
    createEngineCalls++;
    return MockPlaybackEngine();
  }

  @override
  void notifySlotChanged() => notifyCalls++;

  @override
  void invalidateSurfaceCache(NativeVideoPlayerController native) {
    invalidateCalls++;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(PlaybackEngineRole.active);
    registerFallbackValue(MockNativeController());
  });

  group('FeedSlotPreparer', () {
    test('returns null when generation is already stale', () async {
      final host = _FakePrepareHost();
      final preparer = FeedSlotPreparer(host);
      final slot = FeedSlot();

      final engine = await preparer.prepare(
        slot: slot,
        playbackId: 'a',
        bindWorkId: 'a',
        index: 0,
        coordinator: NativeVideoPlayerCoordinator.recommendInstance,
        tag: 'Test',
        role: PlaybackEngineRole.active,
        looping: false,
        generation: 1,
        currentGeneration: () => 2,
        allowSlot: (_) => true,
      );

      expect(engine, isNull);
      expect(host.createEngineCalls, 0);
    });

    test('returns null when slot is not allowed', () async {
      final host = _FakePrepareHost();
      final preparer = FeedSlotPreparer(host);
      final slot = FeedSlot();

      final engine = await preparer.prepare(
        slot: slot,
        playbackId: 'a',
        bindWorkId: 'a',
        index: 0,
        coordinator: NativeVideoPlayerCoordinator.recommendInstance,
        tag: 'Test',
        role: PlaybackEngineRole.preload,
        looping: false,
        generation: 1,
        currentGeneration: () => 1,
        allowSlot: (_) => false,
      );

      expect(engine, isNull);
      expect(host.createEngineCalls, 0);
    });

    test('reuses existing engine without creating a new one', () async {
      final existing = MockPlaybackEngine();
      final native = MockNativeController();
      when(() => existing.pause()).thenAnswer((_) async {});
      when(() => existing.cancelStaleLoad()).thenAnswer((_) async {});
      when(() => existing.rebindDrama(any())).thenReturn(null);
      when(
        () => existing.retargetSlot(
          tag: any(named: 'tag'),
          role: any(named: 'role'),
        ),
      ).thenReturn(null);
      when(() => existing.setLooping(any())).thenAnswer((_) async {});
      when(() => existing.nativeController).thenReturn(native);
      when(() => native.hasPlatformView).thenReturn(true);
      when(() => native.isInitialized).thenReturn(true);

      final host = _FakePrepareHost();
      final preparer = FeedSlotPreparer(host);
      final slot = FeedSlot()
        ..engine = existing
        ..native = native;

      final engine = await preparer.prepare(
        slot: slot,
        playbackId: 'b',
        bindWorkId: 'b',
        index: 1,
        coordinator: NativeVideoPlayerCoordinator.recommendInstance,
        tag: 'Test',
        role: PlaybackEngineRole.active,
        looping: true,
        generation: 3,
        currentGeneration: () => 3,
        allowSlot: (_) => true,
      );

      expect(identical(engine, existing), isTrue);
      expect(host.createEngineCalls, 0);
      expect(slot.playbackId, 'b');
      expect(slot.index, 1);
      expect(slot.surfaceReady, isTrue);
      expect(slot.frameReady, isFalse);
      verify(() => existing.rebindDrama('b')).called(1);
      verify(() => existing.setLooping(true)).called(1);
    });
  });
}
