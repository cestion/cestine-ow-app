import 'dart:async';

import '../core/story_constants.dart';
import '../core/story_logger.dart';

/// Outcome of [PlaybackFrameTracker.waitForFrameAfter].
enum FrameWaitResult {
  /// [frameSequence] advanced past the caller's snapshot.
  presented,

  /// Waiter was replaced, disposed, or [shouldContinue] flipped. Not a
  /// decoder failure — callers must not retry as "no video frame".
  aborted,

  /// Timeout elapsed with no new frame while the wait was still wanted.
  timedOut,
}

/// Tracks native video frame events and exposes frame-sequence-based waiting.
///
/// Extracted from [PlaybackEngine] to keep frame-sequencing logic
/// self-contained. Owned by [PlaybackEngine] and wired through its
/// native-control event handlers.
class PlaybackFrameTracker {
  int frameSequence = 0;
  bool hasPresentedFirstFrame = false;
  DateTime? lastFrameRenderedAt;

  void Function({required bool isFirstFrame, required DateTime renderedAt})?
  onFrameRendered;

  final List<Completer<void>> _frameWaiters = <Completer<void>>[];
  bool _disposed = false;
  int _waitGeneration = 0;

  /// Mark the tracker as disposed so pending [waitForFrameAfter]
  /// completions are released.
  void markDisposed() {
    _disposed = true;
    for (final waiter in List<Completer<void>>.from(_frameWaiters)) {
      if (!waiter.isCompleted) waiter.complete();
    }
    _frameWaiters.clear();
  }

  /// Called by the native control-event handler when a frame is rendered.
  void recordFrame({required bool isFirstFrame, required DateTime renderedAt}) {
    if (_disposed) return;
    frameSequence++;
    // Any painted frame is enough to unmount the cover. Some platforms emit
    // `frameRendered` without a distinct `firstFrameRendered` event.
    hasPresentedFirstFrame = true;
    lastFrameRenderedAt = renderedAt;
    final pending = List<Completer<void>>.from(_frameWaiters);
    for (final waiter in pending) {
      if (!waiter.isCompleted) waiter.complete();
    }
    onFrameRendered?.call(isFirstFrame: isFirstFrame, renderedAt: renderedAt);
  }

  /// Waits until [frameSequence] exceeds [afterSequence].
  ///
  /// A painted frame always wins, even if a newer wait superseded this one.
  /// Superseded / aborted waits do not log a timeout — that warning is
  /// reserved for a still-wanted play that actually produced no frame.
  Future<FrameWaitResult> waitForFrameAfter(
    int afterSequence, {
    Duration timeout = StoryConstants.playerFirstFrameTimeout,
    bool Function()? shouldContinue,
  }) async {
    if (_disposed) return FrameWaitResult.aborted;
    if (shouldContinue != null && !shouldContinue()) {
      return FrameWaitResult.aborted;
    }
    if (frameSequence > afterSequence) return FrameWaitResult.presented;

    final gen = ++_waitGeneration;
    _completePendingWaiters();

    final waiter = Completer<void>();
    _frameWaiters.add(waiter);
    Timer? poll;
    if (shouldContinue != null) {
      poll = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (waiter.isCompleted) return;
        if (_disposed || gen != _waitGeneration || !shouldContinue()) {
          waiter.complete();
        }
      });
    }
    try {
      if (frameSequence > afterSequence && !waiter.isCompleted) {
        waiter.complete();
      }
      await waiter.future.timeout(timeout);
      if (frameSequence > afterSequence) return FrameWaitResult.presented;
      return FrameWaitResult.aborted;
    } on TimeoutException {
      if (frameSequence > afterSequence) return FrameWaitResult.presented;
      if (_disposed || gen != _waitGeneration) {
        return FrameWaitResult.aborted;
      }
      if (shouldContinue != null && !shouldContinue()) {
        return FrameWaitResult.aborted;
      }
      StoryLogger.w(
        'No native video frame after ${timeout.inMilliseconds}ms',
        tag: 'FrameTracker',
      );
      return FrameWaitResult.timedOut;
    } finally {
      poll?.cancel();
      _frameWaiters.remove(waiter);
    }
  }

  void _completePendingWaiters() {
    for (final waiter in List<Completer<void>>.from(_frameWaiters)) {
      if (!waiter.isCompleted) waiter.complete();
    }
    _frameWaiters.clear();
  }

  /// Reset frame evidence before a new loadUrl.
  void resetFrameEvidence() {
    hasPresentedFirstFrame = false;
    lastFrameRenderedAt = null;
  }
}
