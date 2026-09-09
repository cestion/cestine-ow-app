import 'dart:async';

import 'feed_playback_policy.dart';
import 'feed_scroll_activate_policy.dart';
import 'feed_scroll_activate_snapshot.dart';

/// Manages outgoing-audio duck state during PageView scroll.
class FeedScrollVolumeDucker {
  FeedScrollVolumeDucker({required this.onDuckChanged});

  final void Function(bool duck) onDuckChanged;

  bool _ducked = false;
  bool get isDucked => _ducked;

  void apply({required bool shouldDuck}) {
    if (shouldDuck) {
      if (!_ducked) {
        _ducked = true;
        onDuckChanged(true);
      }
      return;
    }
    if (_ducked) {
      _ducked = false;
      onDuckChanged(false);
    }
  }
}

/// Debounces fractional PageView scroll until settle (short-drama feed).
class FeedScrollSettleDebouncer {
  FeedScrollSettleDebouncer({
    this.debounce = const Duration(milliseconds: 80),
    required this.isMounted,
    required this.onSettle,
  });

  final Duration debounce;
  final bool Function() isMounted;
  final void Function(int targetIndex) onSettle;

  Timer? _timer;
  int? _pendingTarget;

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pendingTarget = null;
  }

  void dispose() => cancel();

  /// Call when [page] is not on a whole index.
  void schedule(int targetIndex, {required int? activatedIndex}) {
    if (targetIndex == activatedIndex) return;
    if (targetIndex == _pendingTarget) return;
    cancel();
    _pendingTarget = targetIndex;
    _timer = Timer(debounce, () {
      _pendingTarget = null;
      if (!isMounted()) return;
      onSettle(targetIndex);
    });
  }

  /// Call when [page] snapped to a whole index — cancels pending debounce.
  void onSnapped() => cancel();
}

/// Tracks scroll-direction bias for neighbor prefetch.
class FeedScrollPrefetchDirector {
  FeedScrollPrefetchDirector({required this.onDirectionChanged});

  final void Function(bool preferForward) onDirectionChanged;

  bool? _lastDirection;

  void apply(FeedScrollActivateSnapshot tick) {
    final direction = tick.preferForward;
    if (direction != null && direction != _lastDirection) {
      _lastDirection = direction;
      onDirectionChanged(direction);
    } else if (direction == null) {
      _lastDirection = null;
    }
  }
}

/// Early-activate commitment checks shared by triple-slot feeds.
class FeedPageScrollEarlyActivate {
  FeedPageScrollEarlyActivate._();

  static bool dramaCommittedToTarget({
    required double page,
    required int activeIndex,
    required int targetIndex,
    required int targetEpisode,
    required Set<int> frameReadyEpisodeNos,
    required Set<int> settledEpisodeNos,
    required int? alreadyActivatedIndex,
  }) {
    if (targetIndex == alreadyActivatedIndex) return false;
    if (!FeedPlaybackPolicy.isEpisodeReadyForEarlyActivate(
      episodeNo: targetEpisode,
      frameReadyEpisodeNos: frameReadyEpisodeNos,
      settledEpisodeNos: settledEpisodeNos,
    )) {
      return false;
    }
    return FeedScrollActivatePolicy.isCommittedTowardNeighbor(
          page: page,
          activeIndex: activeIndex,
          neighborIndex: targetIndex,
        ) &&
        page.round() == targetIndex;
  }

  /// Recommend bidirectional early activate for one neighbor slot.
  static int? recommendNeighborIndex({
    required double page,
    required int activeIndex,
    required int? neighborIndex,
    required bool neighborReady,
    required int? alreadyEarlyActivated,
    required bool goingForward,
    double? threshold,
  }) {
    return FeedScrollActivateSnapshot.analyze(
      page: page,
      activeIndex: activeIndex,
      inSkipDuckWindow: false,
      neighborIndex: neighborIndex,
      neighborReady: neighborReady,
      alreadyEarlyActivated: alreadyEarlyActivated,
      goingForward: goingForward,
      earlyThreshold: threshold,
    ).earlyActivateIndex;
  }
}
