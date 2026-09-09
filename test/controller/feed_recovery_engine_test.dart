import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/feed_playback_policy.dart';
import 'package:story_app/src/controller/feed_recovery_engine.dart';
import 'package:story_app/src/controller/playback_engine.dart';

class _MockEngine extends Mock implements PlaybackEngine {}

/// Controllable host for driving the shared recovery engine's decision core.
///
/// Public fields with interface-getter names satisfy [FeedRecoveryHost]
/// directly, so tests tweak state by assignment.
class _Host implements FeedRecoveryHost {
  @override
  bool userPaused = false;
  @override
  bool visible = true;
  @override
  bool activationRunning = false;
  @override
  bool volumeDucked = false;
  @override
  bool neighborLoadInFlight = false;
  @override
  bool promoteInFlight = false;
  @override
  bool ended = false;
  @override
  bool playbackFailed = false;
  @override
  bool buffering = false;
  @override
  bool isPlaying = false;
  @override
  bool couldBeRecoverable = true;
  @override
  bool readyForResume = true;
  @override
  bool readyForStallCheck = true;
  bool readyStall = true;
  bool isWithinGrace = false;
  @override
  String boundIdentity = 'item_1';
  @override
  PlaybackEngine? engine;
  @override
  DateTime? lastFrameRenderedAt;
  bool resumeResult = true;

  bool alive = true;
  bool armActive = false;

  int resumeCalls = 0;
  int guardSkipCalls = 0;
  int resumeSucceededCalls = 0;
  final List<int> stallEscalates = [];

  @override
  bool aliveForGeneration(int generation) => alive;

  @override
  bool isPlaybackArmActive() => armActive;

  @override
  bool isWithinForegroundGrace() => isWithinGrace;

  @override
  void onGuardSkip() {
    guardSkipCalls++;
  }

  @override
  Future<bool> resumeActivePlayback() async {
    resumeCalls++;
    return resumeResult;
  }

  @override
  Future<void> onResumeSucceeded() async {
    resumeSucceededCalls++;
    isPlaying = true;
  }

  @override
  Future<void> onFrameStallEscalate({required int attempt}) async {
    stallEscalates.add(attempt);
  }

  @override
  void logWarning(String message) {}

  @override
  void logDebug(String message) {}
}

void main() {
  late _MockEngine engine;
  late _Host host;
  late FeedRecoveryEngine recovery;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    engine = _MockEngine();
    when(() => engine.isBuffering).thenReturn(false);
    when(() => engine.hasCompleted).thenReturn(false);
    when(() => engine.hasPendingLoad).thenReturn(false);
    when(() => engine.frameSequence).thenReturn(0);
    when(() => engine.nudgeTextureFrame()).thenAnswer((_) async {});
    when(
      () => engine.waitForFrameAfter(
        any(),
        timeout: any(named: 'timeout'),
        shouldContinue: any(named: 'shouldContinue'),
      ),
    ).thenAnswer((_) async => true);
    host = _Host()..engine = engine;
    recovery = FeedRecoveryEngine(host);
  });

  group('unexpected pause', () {
    test('recovers after the settle delay when nothing explains the pause', () {
      fakeAsync((async) {
        recovery.maybeRecoverUnexpectedPause(generation: 0);
        expect(host.resumeCalls, 0, reason: 'must wait for the settle delay');

        async.elapse(
          FeedPlaybackPolicy.unexpectedPauseSettle +
              const Duration(milliseconds: 20),
        );

        expect(host.resumeCalls, 1);
        expect(host.resumeSucceededCalls, 1);
        expect(host.isPlaying, isTrue);
      });
    });

    test('skips and notifies the host when the policy guard blocks', () {
      fakeAsync((async) {
        host.userPaused = true;

        recovery.maybeRecoverUnexpectedPause(generation: 0);
        async.flushMicrotasks();

        expect(host.guardSkipCalls, 1);
        expect(host.resumeCalls, 0);
      });
    });

    test('does not resume while still inside the playback arm grace', () {
      fakeAsync((async) {
        host.armActive = true;

        recovery.maybeRecoverUnexpectedPause(generation: 0);
        async.elapse(FeedPlaybackPolicy.unexpectedPauseSettle);

        expect(host.resumeCalls, 0);
      });
    });

    test('caps attempts per identity', () {
      fakeAsync((async) {
        host.resumeResult = false;

        recovery.maybeRecoverUnexpectedPause(generation: 0);
        async.elapse(
          FeedPlaybackPolicy.unexpectedPauseSettle +
              const Duration(milliseconds: 20),
        );
        expect(host.resumeCalls, 1);

        recovery.maybeRecoverUnexpectedPause(generation: 0);
        async.elapse(
          FeedPlaybackPolicy.unexpectedPauseSettle +
              const Duration(milliseconds: 20),
        );
        expect(host.resumeCalls, 2);

        // Budget exhausted for this identity.
        recovery.maybeRecoverUnexpectedPause(generation: 0);
        async.elapse(
          FeedPlaybackPolicy.unexpectedPauseSettle +
              const Duration(milliseconds: 20),
        );
        expect(host.resumeCalls, 2);
      });
    });

    test('a new bound identity gets a fresh budget', () {
      fakeAsync((async) {
        host.resumeResult = false;
        for (var i = 0; i < 2; i++) {
          recovery.maybeRecoverUnexpectedPause(generation: 0);
          async.elapse(
            FeedPlaybackPolicy.unexpectedPauseSettle +
                const Duration(milliseconds: 20),
          );
        }
        expect(host.resumeCalls, 2);

        host.boundIdentity = 'item_2';
        recovery.maybeRecoverUnexpectedPause(generation: 0);
        async.elapse(
          FeedPlaybackPolicy.unexpectedPauseSettle +
              const Duration(milliseconds: 20),
        );
        expect(host.resumeCalls, 3);
      });
    });

    test('playback started resets the pause budget', () {
      fakeAsync((async) {
        host.resumeResult = false;
        for (var i = 0; i < 2; i++) {
          recovery.maybeRecoverUnexpectedPause(generation: 0);
          async.elapse(
            FeedPlaybackPolicy.unexpectedPauseSettle +
                const Duration(milliseconds: 20),
          );
        }
        expect(host.resumeCalls, 2);

        recovery.notifyPlaybackStarted();
        recovery.maybeRecoverUnexpectedPause(generation: 0);
        async.elapse(
          FeedPlaybackPolicy.unexpectedPauseSettle +
              const Duration(milliseconds: 20),
        );
        expect(host.resumeCalls, 3);
      });
    });

    test('aborts when the host is no longer alive after the settle', () {
      fakeAsync((async) {
        recovery.maybeRecoverUnexpectedPause(generation: 0);
        host.alive = false;
        async.elapse(
          FeedPlaybackPolicy.unexpectedPauseSettle +
              const Duration(milliseconds: 20),
        );

        expect(host.resumeCalls, 0);
      });
    });
  });

  group('frame stall', () {
    void armStall() {
      host.isPlaying = true;
      host.lastFrameRenderedAt = DateTime.now().subtract(
        const Duration(seconds: 30),
      );
    }

    test('nudges the texture and does not escalate when a frame arrives', () {
      fakeAsync((async) {
        armStall();

        recovery.maybeRecoverFrameStall(generation: 0, engine: engine);
        async.flushMicrotasks();

        verify(() => engine.nudgeTextureFrame()).called(1);
        expect(host.stallEscalates, isEmpty);
      });
    });

    test('escalates the attempt when no frame arrives after the nudge', () {
      fakeAsync((async) {
        when(
          () => engine.waitForFrameAfter(
            any(),
            timeout: any(named: 'timeout'),
            shouldContinue: any(named: 'shouldContinue'),
          ),
        ).thenAnswer((_) async => false);
        armStall();

        recovery.maybeRecoverFrameStall(generation: 0, engine: engine);
        async.flushMicrotasks();

        expect(host.stallEscalates, [1]);
      });
    });

    test('suppressed while playing is not active', () {
      fakeAsync((async) {
        host.isPlaying = false;
        host.lastFrameRenderedAt = DateTime.now().subtract(
          const Duration(seconds: 30),
        );

        recovery.maybeRecoverFrameStall(generation: 0, engine: engine);
        async.flushMicrotasks();

        verifyNever(() => engine.nudgeTextureFrame());
        expect(host.stallEscalates, isEmpty);
      });
    });

    test('suppressed within the foreground grace window', () {
      fakeAsync((async) {
        armStall();
        host.isWithinGrace = true;

        recovery.maybeRecoverFrameStall(generation: 0, engine: engine);
        async.flushMicrotasks();

        verifyNever(() => engine.nudgeTextureFrame());
      });
    });

    test('ignored while no frame has ever rendered', () {
      fakeAsync((async) {
        host.isPlaying = true;
        host.lastFrameRenderedAt = null;

        recovery.maybeRecoverFrameStall(generation: 0, engine: engine);
        async.flushMicrotasks();

        verifyNever(() => engine.nudgeTextureFrame());
      });
    });

    test('a rendered frame resets the stall budget so retry is allowed', () {
      fakeAsync((async) {
        when(
          () => engine.waitForFrameAfter(
            any(),
            timeout: any(named: 'timeout'),
            shouldContinue: any(named: 'shouldContinue'),
          ),
        ).thenAnswer((_) async => false);
        armStall();

        recovery.maybeRecoverFrameStall(generation: 0, engine: engine);
        async.flushMicrotasks();
        expect(host.stallEscalates, [1]);

        // Second attempt still allowed, then the budget is exhausted.
        recovery.maybeRecoverFrameStall(generation: 0, engine: engine);
        async.flushMicrotasks();
        expect(host.stallEscalates, [1, 2]);

        recovery.maybeRecoverFrameStall(generation: 0, engine: engine);
        async.flushMicrotasks();
        expect(host.stallEscalates, [1, 2]);

        // A healthy frame resets the counter.
        recovery.notifyFrameRendered();
        recovery.maybeRecoverFrameStall(generation: 0, engine: engine);
        async.flushMicrotasks();
        expect(host.stallEscalates, [1, 2, 1]);
      });
    });

    test('resetBudgets drops both attempt budgets', () {
      fakeAsync((async) {
        host.resumeResult = false;
        for (var i = 0; i < 2; i++) {
          recovery.maybeRecoverUnexpectedPause(generation: 0);
          async.elapse(
            FeedPlaybackPolicy.unexpectedPauseSettle +
                const Duration(milliseconds: 20),
          );
        }
        expect(host.resumeCalls, 2);

        recovery.resetBudgets();
        recovery.maybeRecoverUnexpectedPause(generation: 0);
        async.elapse(
          FeedPlaybackPolicy.unexpectedPauseSettle +
              const Duration(milliseconds: 20),
        );
        expect(host.resumeCalls, 3);
      });
    });
  });
}
