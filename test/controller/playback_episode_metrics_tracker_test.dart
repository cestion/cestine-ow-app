import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/playback_episode_metrics_tracker.dart';

void main() {
  group('PlaybackEpisodeMetricsTracker thresholds', () {
    test('playThresholdSeconds follows PRD formula', () {
      expect(PlaybackEpisodeMetricsTracker.playThresholdSeconds(15), 5);
      expect(PlaybackEpisodeMetricsTracker.playThresholdSeconds(30), 6);
      expect(PlaybackEpisodeMetricsTracker.playThresholdSeconds(60), 10);
      expect(PlaybackEpisodeMetricsTracker.playThresholdSeconds(120), 10);
    });

    test('completeWatchThresholdSeconds is 60% of duration', () {
      expect(
        PlaybackEpisodeMetricsTracker.completeWatchThresholdSeconds(100),
        60,
      );
    });

    test('playThreshold exceeds duration for videos under 5 seconds', () {
      expect(PlaybackEpisodeMetricsTracker.playThresholdSeconds(3), 5);
      expect(3 < PlaybackEpisodeMetricsTracker.playThresholdSeconds(3), isTrue);
      expect(4 < PlaybackEpisodeMetricsTracker.playThresholdSeconds(4), isTrue);
    });
  });

  group('PlaybackEpisodeMetricsTracker', () {
    late PlaybackEpisodeMetricsTracker tracker;

    setUp(() => tracker = PlaybackEpisodeMetricsTracker());

    void playTicks(double to, {double duration = 25, double step = 1}) {
      tracker.onPlayStart();
      for (double t = 0; t <= to; t += step) {
        tracker.onTimeUpdate(t, duration);
      }
    }

    test('does not report before play starts', () {
      final signals = tracker.onTimeUpdate(10, 100);
      expect(signals.reportPlay, isFalse);
      expect(signals.reportComplete, isFalse);
    });

    test('reports play after effective watch threshold', () {
      playTicks(5);
      final signals = tracker.onTimeUpdate(5, 25);
      expect(signals.reportPlay, isTrue);
      expect(signals.reportComplete, isFalse);
    });

    test('does not count large forward seek toward effective watch', () {
      tracker.onPlayStart();
      tracker.onTimeUpdate(0, 100);
      tracker.onTimeUpdate(1, 100);
      tracker.onTimeUpdate(90, 100);
      final signals = tracker.onTimeUpdate(91, 100);
      expect(signals.reportPlay, isFalse);
      expect(signals.reportComplete, isFalse);
    });

    test('credits capped watch when 1Hz ticks skip a second', () {
      tracker.onPlayStart();
      // 0→1→3 (missed second 2): old logic discarded delta=2 entirely.
      tracker.onTimeUpdate(0, 25);
      tracker.onTimeUpdate(1, 25);
      tracker.onTimeUpdate(3, 25);
      tracker.onTimeUpdate(4, 25);
      tracker.onTimeUpdate(5, 25);
      tracker.onTimeUpdate(6, 25);
      final signals = tracker.onTimeUpdate(7, 25);
      expect(signals.reportPlay, isTrue);
    });

    test('still rejects seeks above forward threshold', () {
      tracker.onPlayStart();
      tracker.onTimeUpdate(0, 25);
      tracker.onTimeUpdate(1, 25);
      // delta=4 > 3s seek gate — must not invent play from a scrub.
      tracker.onTimeUpdate(5, 25);
      final signals = tracker.onTimeUpdate(6, 25);
      expect(signals.reportPlay, isFalse);
    });

    test('reports complete when progress and watch thresholds met', () {
      tracker.onPlayStart();
      const duration = 100;
      for (var t = 0; t <= 90; t++) {
        tracker.onTimeUpdate(t.toDouble(), duration.toDouble());
      }
      final signals = tracker.onTimeUpdate(90, duration.toDouble());
      expect(signals.reportPlay, isTrue);
      expect(signals.reportComplete, isTrue);
    });

    test('does not report complete with high progress but low watch time', () {
      tracker.onPlayStart();
      tracker.onTimeUpdate(0, 100);
      tracker.onTimeUpdate(90, 100);
      final signals = tracker.onTimeUpdate(91, 100);
      expect(signals.reportComplete, isFalse);
    });

    test('pause stops accumulating effective watch time', () {
      tracker.onPlayStart();
      for (var t = 0; t <= 3; t++) {
        tracker.onTimeUpdate(t.toDouble(), 25);
      }
      tracker.onPause();
      final paused = tracker.onTimeUpdate(10, 25);
      expect(paused.reportPlay, isFalse);
      tracker.onPlayStart();
      for (var t = 4; t <= 9; t++) {
        tracker.onTimeUpdate(t.toDouble(), 25);
      }
      final afterResume = tracker.onTimeUpdate(9, 25);
      expect(afterResume.reportPlay, isTrue);
    });

    test('reset clears session state', () {
      playTicks(10);
      tracker.reset();
      final signals = tracker.onTimeUpdate(10, 100);
      expect(signals.reportPlay, isFalse);
    });

    test('reports play with complete when duration is below play threshold', () {
      tracker.onPlayStart();
      const duration = 3.0;
      for (var t = 0; t <= 3; t++) {
        tracker.onTimeUpdate(t.toDouble(), duration);
      }
      final signals = tracker.onTimeUpdate(3, duration);
      expect(signals.reportPlay, isTrue);
      expect(signals.reportComplete, isTrue);
    });

    test('does not bundle play with complete when play threshold is reachable', () {
      tracker.onPlayStart();
      tracker.onTimeUpdate(0, 100);
      tracker.onTimeUpdate(90, 100);
      final signals = tracker.onTimeUpdate(91, 100);
      expect(signals.reportPlay, isFalse);
      expect(signals.reportComplete, isFalse);
    });

    test('natural end credits tail watch and progress when playhead reset to 0', () {
      tracker.onPlayStart();
      const duration = 10.0;
      for (var t = 0; t <= 8; t++) {
        tracker.onTimeUpdate(t.toDouble(), duration);
      }
      final signals = tracker.onNaturalPlaybackEnd(
        positionSeconds: 0,
        durationSeconds: duration,
      );
      expect(signals.reportPlay, isTrue);
      expect(signals.reportComplete, isTrue);
    });

    test('natural end does not complete after seek-near-end with low watch time', () {
      tracker.onPlayStart();
      tracker.onTimeUpdate(0, 100);
      tracker.onTimeUpdate(95, 100);
      final signals = tracker.onNaturalPlaybackEnd(durationSeconds: 100);
      expect(signals.reportComplete, isFalse);
    });

    test('loop wrap reports complete when metadata duration is inflated', () {
      // Realistic HLS overshoot: metadata a few seconds longer than content.
      tracker.onPlayStart();
      const metadataDuration = 30.0;
      for (var t = 0; t <= 29; t++) {
        tracker.onTimeUpdate(t.toDouble(), metadataDuration);
      }
      final signals = tracker.onTimeUpdate(0, metadataDuration);
      expect(signals.reportPlay, isTrue);
      expect(signals.reportComplete, isTrue);
    });

    test(
      'loop wrap does not complete after mid-clip remount restart',
      () {
        tracker.onPlayStart();
        const metadataDuration = 300.0;
        for (var t = 0; t <= 29; t++) {
          tracker.onTimeUpdate(t.toDouble(), metadataDuration);
        }
        final signals = tracker.onTimeUpdate(0, metadataDuration);
        expect(signals.reportPlay, isTrue);
        expect(signals.reportComplete, isFalse);
      },
    );

    test('loop wrap reports complete when 1Hz ticks miss 90% before rewind', () {
      tracker.onPlayStart();
      const duration = 10.0;
      for (var t = 0; t <= 8; t++) {
        tracker.onTimeUpdate(t.toDouble(), duration);
      }
      final signals = tracker.onTimeUpdate(0, duration);
      expect(signals.reportPlay, isTrue);
      expect(signals.reportComplete, isTrue);
    });
  });

  group('first-pass natural EOS (short clip)', () {
    late PlaybackEpisodeMetricsTracker tracker;

    setUp(() => tracker = PlaybackEpisodeMetricsTracker());

    test('2s EOS without prior onPlayStart still reports play+complete', () {
      // Promote path: playing already happened under NeighborEngineListener.
      final signals = tracker.onNaturalPlaybackEnd(
        positionSeconds: 0,
        durationSeconds: 2,
      );
      expect(signals.reportComplete, isTrue);
      expect(signals.reportPlay, isTrue);
    });

    test('2s EOS with stale position 1.4 reports play+complete on first pass', () {
      tracker.onPlayStart();
      tracker.onTimeUpdate(0, 2);
      tracker.onTimeUpdate(1, 2);
      final signals = tracker.onNaturalPlaybackEnd(
        positionSeconds: 1.4,
        durationSeconds: 2,
      );
      expect(signals.reportComplete, isTrue);
      expect(signals.reportPlay, isTrue);
    });

    test('2s first tick without duration then EOS reports play+complete', () {
      tracker.onPlayStart();
      tracker.onTimeUpdate(0);
      final signals = tracker.onNaturalPlaybackEnd(
        positionSeconds: 0,
        durationSeconds: 2,
      );
      expect(signals.reportComplete, isTrue);
      expect(signals.reportPlay, isTrue);
    });

    test('2s EOS with playhead near end but sparse watch still completes', () {
      // Repro from device: posMs≈1998 durMs=2000, 1Hz ticks only counted ~1s
      // watch so tail credit was ≈0 and complete never fired.
      tracker.onPlayStart();
      tracker.onTimeUpdate(0, 2);
      tracker.onTimeUpdate(1, 2);
      tracker.onTimeUpdate(1.998, 2); // large jump, not fully counted as watch
      final signals = tracker.onNaturalPlaybackEnd(
        positionSeconds: 1.998,
        durationSeconds: 2,
      );
      expect(signals.reportComplete, isTrue);
      expect(signals.reportPlay, isTrue);
    });

    test('2s EOS after pause still reports play+complete', () {
      tracker.onPlayStart();
      tracker.onTimeUpdate(0, 2);
      tracker.onTimeUpdate(1, 2);
      tracker.onPause();
      final signals = tracker.onNaturalPlaybackEnd(
        positionSeconds: 0,
        durationSeconds: 2,
      );
      expect(signals.reportComplete, isTrue);
      expect(signals.reportPlay, isTrue);
    });

    test('2s loop wrap end→0 reports play+complete', () {
      tracker.onPlayStart();
      tracker.onTimeUpdate(0, 2);
      tracker.onTimeUpdate(1, 2);
      tracker.onTimeUpdate(2, 2);
      final signals = tracker.onTimeUpdate(0, 2);
      expect(signals.reportComplete, isTrue);
      expect(signals.reportPlay, isTrue);
    });

    test('long clip seek-near-end EOS does not complete', () {
      tracker.onPlayStart();
      tracker.onTimeUpdate(0, 100);
      tracker.onTimeUpdate(95, 100);
      final signals = tracker.onNaturalPlaybackEnd(
        positionSeconds: 98,
        durationSeconds: 100,
      );
      expect(signals.reportComplete, isFalse);
      expect(signals.reportPlay, isFalse);
    });

    test('long clip zero ticks then EOS does not fabricate complete', () {
      tracker.onPlayStart();
      final signals = tracker.onNaturalPlaybackEnd(durationSeconds: 100);
      expect(signals.reportComplete, isFalse);
    });

    test(
      'long clip after play: remount restart at 0 does not complete',
      () {
        // Repro: watch ~10s of 3min → 有效播放, leave profile / remount
        // restarts playhead at 0 while metrics session stays armed.
        tracker.onPlayStart();
        PlaybackEpisodeMetricsSignals? last;
        for (var i = 0; i <= 10; i++) {
          last = tracker.onTimeUpdate(i.toDouble(), 180);
        }
        expect(last!.reportPlay, isTrue);
        expect(last.reportComplete, isFalse);

        final afterReturn = tracker.onTimeUpdate(0, 180);
        expect(afterReturn.reportComplete, isFalse);
        expect(afterReturn.reportPlay, isTrue);
      },
    );

    test(
      'long clip after play: mid-clip natural EOS does not complete',
      () {
        tracker.onPlayStart();
        for (var i = 0; i <= 10; i++) {
          tracker.onTimeUpdate(i.toDouble(), 180);
        }
        final afterEos = tracker.onNaturalPlaybackEnd(
          positionSeconds: 0,
          durationSeconds: 180,
        );
        expect(afterEos.reportComplete, isFalse);
        expect(afterEos.reportPlay, isTrue);
      },
    );

    test('5s EOS after playhead reset to 0 still completes', () {
      // Engine often seeks to 0 before completed; duration==5 is not `< playThreshold`.
      tracker.onPlayStart();
      tracker.onTimeUpdate(0, 5);
      tracker.onTimeUpdate(1, 5);
      tracker.onTimeUpdate(2, 5);
      tracker.onTimeUpdate(3, 5);
      tracker.onTimeUpdate(4, 5);
      tracker.onTimeUpdate(0, 5); // seek-to-0 before EOS
      final signals = tracker.onNaturalPlaybackEnd(
        positionSeconds: 0,
        durationSeconds: 5,
      );
      expect(signals.reportComplete, isTrue);
      expect(signals.reportPlay, isTrue);
    });

    test('sub-5s clip with inflated metadata still completes on EOS', () {
      tracker.onPlayStart();
      tracker.onTimeUpdate(0, 60);
      tracker.onTimeUpdate(1, 60);
      tracker.onTimeUpdate(2, 60);
      tracker.onTimeUpdate(0, 60);
      final signals = tracker.onNaturalPlaybackEnd(
        positionSeconds: 0,
        durationSeconds: 60,
      );
      expect(signals.reportComplete, isTrue);
      expect(signals.reportPlay, isTrue);
    });
  });
}
