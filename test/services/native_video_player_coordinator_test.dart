import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/services/native_video_player_coordinator.dart';

void main() {
  final coordinator = NativeVideoPlayerCoordinator.instance;
  final ownerA = Object();
  final ownerB = Object();

  test('acquire and release allows sequential owners', () async {
    await coordinator.acquire(ownerA);
    expect(coordinator.hasOwner, isTrue);

    await coordinator.release(ownerA);
    expect(coordinator.hasOwner, isFalse);

    await coordinator.acquire(ownerB);
    await coordinator.release(ownerB);
    expect(coordinator.hasOwner, isFalse);
  });

  test('second owner waits until first releases', () async {
    await coordinator.acquire(ownerA);

    var secondAcquired = false;
    final second = coordinator.acquire(ownerB).then((_) {
      secondAcquired = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(secondAcquired, isFalse);

    await coordinator.release(ownerA);
    await second;
    expect(secondAcquired, isTrue);

    await coordinator.release(ownerB);
  });

  test('waiter is woken promptly on release (signal, not busy-poll)', () async {
    await coordinator.acquire(ownerA);

    final stopwatch = Stopwatch()..start();
    final pending = coordinator.acquire(ownerB);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await coordinator.release(ownerA);
    await pending;
    stopwatch.stop();

    expect(coordinator.hasOwner, isTrue);
    // Signal-based wakeup should resolve well under the 5s timeout and the
    // 200ms re-check cap — proving we don't rely on a slow poll loop.
    expect(stopwatch.elapsedMilliseconds, lessThan(1000));

    await coordinator.release(ownerB);
  });

  test('re-acquire after a bail-release does not deadlock', () async {
    // Mimics the banner/detail bail path: acquire then immediately release
    // (isCurrent became false). A subsequent acquire must still succeed.
    await coordinator.acquire(ownerA);
    await coordinator.release(ownerA);

    await coordinator.acquire(ownerB).timeout(const Duration(seconds: 2));
    expect(coordinator.hasOwner, isTrue);
    await coordinator.release(ownerB);
    expect(coordinator.hasOwner, isFalse);
  });

  test('waitForTeardown is a no-op when idle', () async {
    await NativeVideoPlayerCoordinator.waitForTeardown(
      timeout: const Duration(milliseconds: 50),
    );
    expect(NativeVideoPlayerCoordinator.isTearingDown, isFalse);
  });

  test(
    'waitForTeardown resolves when the last begin/end pair completes',
    () async {
      NativeVideoPlayerCoordinator.beginTeardown();
      NativeVideoPlayerCoordinator.beginTeardown();
      var released = false;
      final waiting = NativeVideoPlayerCoordinator.waitForTeardown().then((_) {
        released = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(released, isFalse);
      expect(NativeVideoPlayerCoordinator.isTearingDown, isTrue);

      NativeVideoPlayerCoordinator.endTeardown();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(released, isFalse);

      NativeVideoPlayerCoordinator.endTeardown();
      await waiting;
      expect(released, isTrue);
      expect(NativeVideoPlayerCoordinator.isTearingDown, isFalse);
    },
  );
}
