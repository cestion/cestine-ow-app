import 'dart:async';

import '../core/story_constants.dart';
import '../core/story_logger.dart';

/// Serializes native video player ownership across banner and feed.
///
/// Only one native player should be active at a time within a given
/// coordinator instance. Call [acquire] before initialize/loadUrl and
/// [release] after dispose/pause teardown.
///
/// Acquisition is *pull-based*: a waiter claims the slot the moment it becomes
/// free. This self-heals when a waiter is granted the slot but immediately
/// bails (releasing right after), and avoids the lost-wakeup that a strict
/// push/hand-off queue suffers when an owner relinquishes a pending request.
/// Waiters block on a release signal (with a short re-check cap) instead of
/// busy-spinning.
class NativeVideoPlayerCoordinator {
  NativeVideoPlayerCoordinator._();

  static final NativeVideoPlayerCoordinator instance =
      NativeVideoPlayerCoordinator._();

  /// Separate coordinator for banner preview slides so that banner handoff
  /// operations (serialized through [_BannerPlayerHandoff]) never block
  /// the full-screen feed player from acquiring the main player slot.
  static final NativeVideoPlayerCoordinator bannerInstance =
      NativeVideoPlayerCoordinator._();

  /// Dedicated coordinator for the feed's previous-episode preload player.
  ///
  /// The feed owns three controllers simultaneously: current, previous and
  /// next. Separate coordinators let all three platform views bootstrap
  /// without competing for one ownership token.
  static final NativeVideoPlayerCoordinator feedPreloadInstance =
      NativeVideoPlayerCoordinator._();

  /// Dedicated coordinator for the feed's next-episode preload player.
  static final NativeVideoPlayerCoordinator feedNextPreloadInstance =
      NativeVideoPlayerCoordinator._();

  /// Dedicated coordinator for the theater Recommend (For You) home feed.
  ///
  /// Keeps recommend bootstrap off both the main feed slot and the banner
  /// preview slot so IndexedStack tab switches cannot serialize against them.
  static final NativeVideoPlayerCoordinator recommendInstance =
      NativeVideoPlayerCoordinator._();

  /// Silent next-item preload for the Recommend home feed.
  static final NativeVideoPlayerCoordinator recommendPreloadInstance =
      NativeVideoPlayerCoordinator._();

  /// Silent previous-item preload for the Recommend home feed (N-1).
  static final NativeVideoPlayerCoordinator recommendPrevInstance =
      NativeVideoPlayerCoordinator._();

  Object? _owner;

  /// Completers waiting to be woken when the player is released. Woken en
  /// masse; each waiter then re-checks ownership (pull model).
  final List<Completer<void>> _releaseSignals = <Completer<void>>[];

  /// Cross-family native teardown (e.g. drama-feed AVPlayers disposing after
  /// pop). Recommend must not `loadUrl` / `play` until this drops to zero —
  /// deallocating AVPlayer mid-play leaves the successor paused with no
  /// frames (play() ACK, 4s FrameTracker timeout).
  static int _teardownCount = 0;
  static final List<Completer<void>> _teardownSignals = <Completer<void>>[];

  static bool get isTearingDown => _teardownCount > 0;

  static void beginTeardown() => _teardownCount++;

  static void endTeardown() {
    if (_teardownCount <= 0) return;
    _teardownCount--;
    if (_teardownCount > 0) return;
    final pending = List<Completer<void>>.from(_teardownSignals);
    _teardownSignals.clear();
    for (final c in pending) {
      if (!c.isCompleted) c.complete();
    }
  }

  static Future<void> waitForTeardown({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (_teardownCount <= 0) return;
    final done = Completer<void>();
    _teardownSignals.add(done);
    // Lost-wakeup: teardown may have finished between the check and the add.
    if (_teardownCount <= 0) {
      _teardownSignals.remove(done);
      return;
    }
    try {
      await done.future.timeout(timeout);
    } on TimeoutException {
      StoryLogger.w(
        'waitForTeardown timed out with count=$_teardownCount',
        tag: 'NativePlayer',
      );
    } finally {
      _teardownSignals.remove(done);
    }
  }

  /// Cap on how long a waiter blocks before re-checking, so a missed signal
  /// can never wedge acquisition permanently.
  static const Duration _recheckInterval = Duration(milliseconds: 200);

  bool get hasOwner => _owner != null;

  /// Wait until no other owner holds the player, then claim [owner].
  ///
  /// If another owner does not release within 5s (hung bootstrap / abandoned
  /// dispose), steal the slot so feed entry cannot wedge permanently.
  Future<void> acquire(Object owner) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (_owner != null && _owner != owner) {
      if (DateTime.now().isAfter(deadline)) {
        StoryLogger.w(
          'NativeVideoPlayerCoordinator.acquire stealing stale owner '
          'after timeout',
          tag: 'NativePlayer',
        );
        _owner = null;
        _wakeWaiters();
        break;
      }
      await _waitForRelease();
    }
    if (_owner == owner) return;
    _owner = owner;
  }

  /// Release [owner] and wake any waiters so the next one can claim the slot.
  Future<void> release(
    Object owner, {
    Duration settleDelay = StoryDurations.nativePlayerReleaseDelay,
  }) async {
    if (_owner != owner) return;
    _owner = null;
    _wakeWaiters();
    if (settleDelay > Duration.zero) {
      await Future<void>.delayed(settleDelay);
    }
  }

  /// Synchronously clear ownership (no settle delay).
  ///
  /// Used by Feed dual-player teardown so the next acquire (banner / feed)
  /// observes idle before async native controller dispose finishes.
  void releaseNow(Object owner) {
    if (_owner != owner) return;
    _owner = null;
    _wakeWaiters();
  }

  /// Wait until the player slot is free (used before acquire when no owner id).
  ///
  /// Returns `true` when idle within [timeout], `false` if still owned when
  /// the deadline elapses. Callers must not start overlapping init on `false`.
  Future<bool> waitUntilIdle({
    Duration timeout = StoryDurations.nativePlayerHandoffDelay,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (_owner != null) {
      if (DateTime.now().isAfter(deadline)) {
        return false;
      }
      await _waitForRelease();
    }
    await Future<void>.delayed(StoryDurations.nativePlayerReleaseDelay);
    return _owner == null;
  }

  Future<void> _waitForRelease() async {
    final signal = Completer<void>();
    _releaseSignals.add(signal);
    await signal.future.timeout(_recheckInterval, onTimeout: () {});
    _releaseSignals.remove(signal);
  }

  void _wakeWaiters() {
    if (_releaseSignals.isEmpty) return;
    final pending = List<Completer<void>>.from(_releaseSignals);
    _releaseSignals.clear();
    for (final c in pending) {
      if (!c.isCompleted) c.complete();
    }
  }
}
