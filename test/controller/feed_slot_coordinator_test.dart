import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/feed_slot_coordinator.dart';
import 'package:story_app/src/controller/playback_engine.dart';
import 'package:story_app/src/model/models.dart';

class MockPlaybackEngine extends Mock implements PlaybackEngine {}

void main() {
  group('FeedSlotCoordinator ready identity', () {
    late List<MockPlaybackEngine> engines;
    late FeedSlotCoordinator coordinator;

    setUp(() {
      engines = List<MockPlaybackEngine>.generate(
        3,
        (_) => MockPlaybackEngine(),
      );
      coordinator = FeedSlotCoordinator((slot) => engines[slot]);
    });

    test('rejects and removes mapping when engine holds another episode', () {
      const actualPlay = DramaPlayResponse(episodeNo: 4);
      when(() => engines[2].currentEpisodeNo).thenReturn(4);
      when(() => engines[2].currentPlay).thenReturn(actualPlay);
      coordinator.episodeToSlot[3] = 2;

      expect(coordinator.readySlotForEpisode(3), isNull);
      expect(coordinator.episodeToSlot.containsKey(3), isFalse);
      expect(coordinator.isMappedOrLoading(3), isFalse);
    });

    test('returns mapping when engine identity matches target', () {
      const actualPlay = DramaPlayResponse(episodeNo: 3);
      when(() => engines[2].currentEpisodeNo).thenReturn(3);
      when(() => engines[2].currentPlay).thenReturn(actualPlay);
      when(() => engines[2].hasPendingLoad).thenReturn(false);
      coordinator.episodeToSlot[3] = 2;

      expect(coordinator.readySlotForEpisode(3), 2);
      expect(coordinator.isMappedOrLoading(3), isTrue);
    });

    test('rejects matching mapping while a native load is still pending', () {
      const actualPlay = DramaPlayResponse(episodeNo: 3);
      when(() => engines[2].currentEpisodeNo).thenReturn(3);
      when(() => engines[2].currentPlay).thenReturn(actualPlay);
      when(() => engines[2].hasPendingLoad).thenReturn(true);
      coordinator.episodeToSlot[3] = 2;

      expect(coordinator.readySlotForEpisode(3), isNull);
      expect(coordinator.episodeToSlot.containsKey(3), isFalse);
    });

    test('finds a decoded inactive episode even when its mapping was lost', () {
      const actualPlay = DramaPlayResponse(episodeNo: 3);
      coordinator.activeEngineIndex = 0;
      when(() => engines[1].currentEpisodeNo).thenReturn(3);
      when(() => engines[1].currentPlay).thenReturn(actualPlay);
      when(() => engines[1].hasPendingLoad).thenReturn(false);

      expect(coordinator.slotForEpisode(3), 1);
      expect(coordinator.isMappedOrLoading(3), isTrue);
    });

    test('never chooses a slot reserved by activation', () {
      coordinator.activeEngineIndex = 0;
      coordinator.slots[1].activationReserved = true;
      for (final engine in engines) {
        when(() => engine.hasPendingLoad).thenReturn(false);
        when(() => engine.currentEpisodeNo).thenReturn(null);
      }

      expect(
        coordinator.choosePreloadSlot(5, currentEpisodeNo: 2, force: true),
        2,
      );
    });

    test('force preload falls back to a wedged inactive slot', () {
      coordinator.activeEngineIndex = 0;
      for (final engine in engines) {
        when(() => engine.currentEpisodeNo).thenReturn(null);
      }
      when(() => engines[0].hasPendingLoad).thenReturn(false);
      when(() => engines[1].hasPendingLoad).thenReturn(true);
      when(() => engines[2].hasPendingLoad).thenReturn(true);

      // Non-force preload must never pick a slot with a pending native load.
      expect(coordinator.choosePreloadSlot(5, currentEpisodeNo: 2), isNull);
      // force=true is the activation last resort: it hands back a wedged
      // inactive slot so the caller can forceAbandon + reuse it instead of
      // leaving swipe activation stuck in cancelStaleLoad retries forever.
      expect(
        coordinator.choosePreloadSlot(5, currentEpisodeNo: 2, force: true),
        1,
      );
    });
  });
}
