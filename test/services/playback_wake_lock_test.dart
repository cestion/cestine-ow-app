import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/services/playback_wake_lock.dart';

void main() {
  group('PlaybackWakeLockPolicy', () {
    test('keeps screen on only while visibly playing', () {
      expect(
        PlaybackWakeLockPolicy.shouldKeepScreenOn(
          isPlaying: true,
          isPlaybackVisible: true,
          userPaused: false,
        ),
        isTrue,
      );
      expect(
        PlaybackWakeLockPolicy.shouldKeepScreenOn(
          isPlaying: false,
          isPlaybackVisible: true,
          userPaused: false,
        ),
        isFalse,
      );
      expect(
        PlaybackWakeLockPolicy.shouldKeepScreenOn(
          isPlaying: true,
          isPlaybackVisible: false,
          userPaused: false,
        ),
        isFalse,
      );
      expect(
        PlaybackWakeLockPolicy.shouldKeepScreenOn(
          isPlaying: true,
          isPlaybackVisible: true,
          userPaused: true,
        ),
        isFalse,
      );
    });
  });

  group('PlaybackWakeLock', () {
    late PlaybackWakeLock lock;
    late List<bool> applied;

    setUp(() {
      lock = PlaybackWakeLock.instance;
      lock.debugReset();
      applied = <bool>[];
      lock.debugSetPlatformApply((keepOn) async {
        applied.add(keepOn);
      });
    });

    tearDown(() {
      lock.debugReset();
    });

    test('apply is idempotent across identical values', () async {
      await lock.apply(keepOn: true);
      await lock.apply(keepOn: true);
      await lock.apply(keepOn: false);
      await lock.apply(keepOn: false);
      expect(applied, [true, false]);
      expect(lock.debugApplied, isFalse);
    });

    test('release clears keep-on', () async {
      await lock.apply(keepOn: true);
      await lock.release();
      expect(applied, [true, false]);
    });
  });
}
