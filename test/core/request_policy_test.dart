import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/debouncer.dart';
import 'package:story_app/src/core/request_coalescer.dart';
import 'package:story_app/src/core/request_throttle.dart';

void main() {
  group('MemoryRequestCoalescer', () {
    test('concurrent run shares one future', () async {
      final coalescer = MemoryRequestCoalescer();
      var starts = 0;
      final gate = Completer<void>();

      Future<int> action() async {
        starts++;
        await gate.future;
        return 42;
      }

      final f1 = coalescer.run('k', action);
      final f2 = coalescer.run('k', action);
      expect(coalescer.isInflight('k'), isTrue);
      expect(starts, 1);

      gate.complete();
      expect(await Future.wait([f1, f2]), [42, 42]);
      expect(coalescer.isInflight('k'), isFalse);

      // After completion a new run is allowed.
      final f3 = coalescer.run('k', () async {
        starts++;
        return 7;
      });
      expect(await f3, 7);
      expect(starts, 2);
    });

    test(
      'invalidateAll drops map entry but does not cancel the action',
      () async {
        final coalescer = MemoryRequestCoalescer();
        final gate = Completer<void>();
        var completed = false;

        final future = coalescer.run('k', () async {
          await gate.future;
          completed = true;
          return 1;
        });
        expect(coalescer.isInflight('k'), isTrue);
        coalescer.invalidateAll();
        expect(coalescer.isInflight('k'), isFalse);

        // A new run can start while the old action is still finishing.
        final second = coalescer.run('k', () async => 2);
        gate.complete();
        expect(await future, 1);
        expect(await second, 2);
        expect(completed, isTrue);
      },
    );

    test('nested same-key run deadlocks (must not be used)', () async {
      final coalescer = MemoryRequestCoalescer();
      final nested = coalescer.run('k', () async {
        // Re-entering the same key awaits the outer future forever.
        return coalescer.run('k', () async => 1);
      });
      await Future<void>.delayed(Duration.zero);
      expect(coalescer.isInflight('k'), isTrue);
      var done = false;
      unawaited(nested.then((_) => done = true));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(done, isFalse);
      coalescer.invalidateAll();
    });

    test('observer receives start and hit', () async {
      final events = <String>[];
      final observer = _RecordingObserver(events);
      final coalescer = MemoryRequestCoalescer(observer: observer);
      final gate = Completer<void>();

      final f1 = coalescer.run('k', () async {
        await gate.future;
        return 1;
      });
      final f2 = coalescer.run('k', () async => 2);
      gate.complete();
      await Future.wait([f1, f2]);

      expect(events, ['start:k', 'hit:k']);
    });
  });

  group('MemoryRequestThrottle', () {
    test('tryClaim rejects inside the window', () {
      var now = DateTime(2026, 9, 3, 10);
      final throttle = MemoryRequestThrottle(clock: () => now);

      expect(throttle.tryClaim('tab'), isTrue);
      expect(throttle.tryClaim('tab'), isFalse);

      now = now.add(const Duration(seconds: 14));
      expect(throttle.tryClaim('tab'), isFalse);

      now = now.add(const Duration(seconds: 2));
      expect(throttle.tryClaim('tab'), isTrue);
    });

    test('reset allows an immediate claim', () {
      final throttle = MemoryRequestThrottle();
      expect(throttle.tryClaim('tab'), isTrue);
      expect(throttle.tryClaim('tab'), isFalse);
      throttle.reset('tab');
      expect(throttle.tryClaim('tab'), isTrue);
    });
  });

  group('TimerDebouncer', () {
    test('fires only the last action after delay', () async {
      final debouncer = TimerDebouncer(
        defaultDelay: const Duration(milliseconds: 50),
      );
      final fired = <int>[];

      debouncer('q', () => fired.add(1));
      debouncer('q', () => fired.add(2));
      debouncer('q', () => fired.add(3));

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(fired, [3]);
    });

    test('cancel prevents fire', () async {
      final debouncer = TimerDebouncer(
        defaultDelay: const Duration(milliseconds: 40),
      );
      var fired = false;
      debouncer('q', () => fired = true);
      debouncer.cancel('q');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(fired, isFalse);
    });

    test('flush runs pending immediately', () async {
      final debouncer = TimerDebouncer(
        defaultDelay: const Duration(seconds: 10),
      );
      var fired = false;
      debouncer('q', () => fired = true);
      await debouncer.flush('q');
      expect(fired, isTrue);
    });
  });
}

class _RecordingObserver implements RequestPolicyObserver {
  _RecordingObserver(this.events);

  final List<String> events;

  @override
  void onCoalesceHit(String key) => events.add('hit:$key');

  @override
  void onCoalesceStart(String key) => events.add('start:$key');

  @override
  void onThrottleReject(String key) => events.add('reject:$key');

  @override
  void onThrottleClaim(String key) => events.add('claim:$key');

  @override
  void onDebounceFire(String key) => events.add('debounce:$key');
}
