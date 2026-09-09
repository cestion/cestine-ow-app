import 'dart:async';

/// Triple-slot role indices: active + next + prev.
///
/// Shared by the recommend feed (and any vertical feed that rotates roles
/// instead of remapping episode→slot). Episode player uses
/// [FeedSlotCoordinator.activeEngineIndex] + episode maps instead.
class FeedRoleRing {
  FeedRoleRing({this.active = 0, this.next = 1, this.prev = 2}) {
    assert({active, next, prev}.length == 3);
    assert(active >= 0 && active < 3);
    assert(next >= 0 && next < 3);
    assert(prev >= 0 && prev < 3);
  }

  int active;
  int next;
  int prev;

  /// Promote next → active; previous active becomes prev; old prev recycles to next.
  void rotateForward() {
    final recycled = prev;
    prev = active;
    active = next;
    next = recycled;
  }

  /// Promote prev → active; previous active becomes next; old next recycles to prev.
  void rotateBackward() {
    final recycled = next;
    next = active;
    active = prev;
    prev = recycled;
  }

  void reset() {
    active = 0;
    next = 1;
    prev = 2;
  }
}

/// Neighbor preload generation / ready markers for the recommend feed.
class RecommendNeighborMarkers {
  Completer<bool>? nextReady;
  Completer<bool>? prevReady;
  int nextGeneration = 0;
  int prevGeneration = 0;
  int nextTargetIndex = -1;
  int prevTargetIndex = -1;

  Completer<bool>? ready({required bool isNext}) =>
      isNext ? nextReady : prevReady;

  int generation({required bool isNext}) =>
      isNext ? nextGeneration : prevGeneration;

  int targetIndex({required bool isNext}) =>
      isNext ? nextTargetIndex : prevTargetIndex;

  void setTargetIndex(int index, {required bool isNext}) {
    if (isNext) {
      nextTargetIndex = index;
    } else {
      prevTargetIndex = index;
    }
  }

  void setReady(Completer<bool> ready, {required bool isNext}) {
    if (isNext) {
      nextReady = ready;
    } else {
      prevReady = ready;
    }
  }

  /// Complete [ready] if it is still the current marker.
  ///
  /// Returns `true` when this was a failed attempt that still owned the
  /// marker (caller should clear sticky slot identity for retry).
  bool finishReady(
    Completer<bool> ready, {
    required bool isNext,
    required bool success,
  }) {
    if (!identical(this.ready(isNext: isNext), ready)) return false;
    if (!ready.isCompleted) {
      ready.complete(success);
    }
    if (!success && identical(this.ready(isNext: isNext), ready)) {
      if (isNext) {
        nextReady = null;
      } else {
        prevReady = null;
      }
      return true;
    }
    return false;
  }

  int bumpGeneration({required bool isNext}) {
    if (isNext) {
      return ++nextGeneration;
    }
    return ++prevGeneration;
  }

  /// Bump gens and drop ready completers so in-flight preload fails
  /// `stillThisNeighbor` immediately.
  void relinquish() {
    nextGeneration++;
    prevGeneration++;
    nextReady = null;
    prevReady = null;
    nextTargetIndex = -1;
    prevTargetIndex = -1;
  }
}
