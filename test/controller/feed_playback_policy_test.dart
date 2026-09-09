import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_playback_policy.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/story_constants.dart';

void main() {
  group('FeedPlaybackPolicy.shouldSkipUnexpectedPause', () {
    test('skips when a neighbor loadUrl is in flight', () {
      expect(
        FeedPlaybackPolicy.shouldSkipUnexpectedPause(
          userPaused: false,
          visible: true,
          activateRunning: false,
          volumeDucked: false,
          neighborLoadInFlight: true,
        ),
        isTrue,
      );
    });

    test('skips during promote / user pause / hidden', () {
      expect(
        FeedPlaybackPolicy.shouldSkipUnexpectedPause(
          userPaused: true,
          visible: true,
          activateRunning: false,
          volumeDucked: false,
          neighborLoadInFlight: false,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldSkipUnexpectedPause(
          userPaused: false,
          visible: false,
          activateRunning: false,
          volumeDucked: false,
          neighborLoadInFlight: false,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldSkipUnexpectedPause(
          userPaused: false,
          visible: true,
          activateRunning: false,
          volumeDucked: false,
          neighborLoadInFlight: false,
          promoteInFlight: true,
        ),
        isTrue,
      );
    });

    test('skips when the clip has already ended', () {
      expect(
        FeedPlaybackPolicy.shouldSkipUnexpectedPause(
          userPaused: false,
          visible: true,
          activateRunning: false,
          volumeDucked: false,
          neighborLoadInFlight: false,
          ended: true,
        ),
        isTrue,
      );
    });

    test('allows resume when the pause is unexplained', () {
      expect(
        FeedPlaybackPolicy.shouldSkipUnexpectedPause(
          userPaused: false,
          visible: true,
          activateRunning: false,
          volumeDucked: false,
          neighborLoadInFlight: false,
        ),
        isFalse,
      );
    });

    test('skips while buffering or after a playback error', () {
      expect(
        FeedPlaybackPolicy.shouldSkipUnexpectedPause(
          userPaused: false,
          visible: true,
          activateRunning: false,
          volumeDucked: false,
          neighborLoadInFlight: false,
          isBuffering: true,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldSkipUnexpectedPause(
          userPaused: false,
          visible: true,
          activateRunning: false,
          volumeDucked: false,
          neighborLoadInFlight: false,
          playbackError: true,
        ),
        isTrue,
      );
    });
  });

  group('FeedPlaybackPolicy.chooseAdjacentActivate', () {
    test('does not cold-load while a neighbor is ready or decoding', () {
      expect(
        FeedPlaybackPolicy.chooseAdjacentActivate(
          neighborReady: true,
          neighborLoadInFlight: false,
        ),
        AdjacentActivateChoice.swap,
      );
      expect(
        FeedPlaybackPolicy.chooseAdjacentActivate(
          neighborReady: false,
          neighborLoadInFlight: true,
        ),
        AdjacentActivateChoice.waitInFlight,
      );
      expect(
        FeedPlaybackPolicy.chooseAdjacentActivate(
          neighborReady: false,
          neighborLoadInFlight: false,
        ),
        AdjacentActivateChoice.controlledCold,
      );
    });
  });

  test('must not wait for firstFrame behind an unrevealed cover', () {
    expect(
      FeedPlaybackPolicy.mayWaitForFirstFrame(coverRevealed: false),
      isFalse,
    );
    expect(
      FeedPlaybackPolicy.mayWaitForFirstFrame(coverRevealed: true),
      isTrue,
    );
  });

  test('retries play when loadUrl left the item paused with no frame', () {
    expect(
      FeedPlaybackPolicy.shouldRetryPlayBeforeFrameWait(
        isPlaying: false,
        hasPresentedFirstFrame: false,
        completed: false,
      ),
      isTrue,
    );
    expect(
      FeedPlaybackPolicy.shouldRetryPlayBeforeFrameWait(
        isPlaying: true,
        hasPresentedFirstFrame: false,
        completed: false,
      ),
      isFalse,
    );
    expect(
      FeedPlaybackPolicy.shouldRetryPlayBeforeFrameWait(
        isPlaying: false,
        hasPresentedFirstFrame: true,
        completed: false,
      ),
      isFalse,
    );
    expect(
      FeedPlaybackPolicy.shouldRetryPlayBeforeFrameWait(
        isPlaying: false,
        hasPresentedFirstFrame: false,
        completed: false,
        isBuffering: true,
      ),
      isFalse,
    );
    expect(
      FeedPlaybackPolicy.kickLoopSatisfied(
        isPlaying: false,
        hasPresentedFirstFrame: false,
        completed: false,
      ),
      isFalse,
    );
    expect(
      FeedPlaybackPolicy.kickLoopSatisfied(
        isPlaying: false,
        hasPresentedFirstFrame: false,
        completed: false,
        unauthorized: true,
      ),
      isTrue,
    );
    expect(
      FeedPlaybackPolicy.isStartupBusy(isBuffering: true, isLoading: false),
      isTrue,
    );
    expect(FeedPlaybackPolicy.playAckRetryAttempts, 2);
    expect(
      FeedPlaybackPolicy.shouldRetryPlayBeforeFrameWait(
        isPlaying: false,
        hasPresentedFirstFrame: false,
        completed: false,
        isLoading: true,
      ),
      isFalse,
    );
  });

  test('ignores completed at t=0 right after arming playback', () {
    final armed = DateTime(2026, 1, 1, 12);
    expect(
      FeedPlaybackPolicy.shouldIgnoreSpuriousComplete(
        hasPresentedFirstFrame: true,
        position: Duration.zero,
        duration: const Duration(seconds: 30),
        playbackArmedAt: armed,
        now: armed.add(const Duration(milliseconds: 400)),
      ),
      isTrue,
    );
    expect(
      FeedPlaybackPolicy.shouldIgnoreSpuriousComplete(
        hasPresentedFirstFrame: true,
        position: const Duration(seconds: 28),
        duration: const Duration(seconds: 30),
        playbackArmedAt: armed,
        now: armed.add(const Duration(seconds: 28)),
      ),
      isFalse,
    );
    expect(
      FeedPlaybackPolicy.shouldIgnoreSpuriousComplete(
        hasPresentedFirstFrame: false,
        position: const Duration(seconds: 10),
        duration: const Duration(seconds: 30),
      ),
      isTrue,
    );
    expect(
      FeedPlaybackPolicy.shouldIgnoreSpuriousComplete(
        hasPresentedFirstFrame: true,
        position: Duration.zero,
        duration: const Duration(seconds: 30),
        playbackArmedAt: armed,
        now: armed.add(const Duration(seconds: 30)),
      ),
      isFalse,
    );
  });

  test('does not ignore real short-clip EOS with playhead reset to 0', () {
    final armed = DateTime(2026, 1, 1, 12);
    expect(
      FeedPlaybackPolicy.shouldIgnoreSpuriousComplete(
        hasPresentedFirstFrame: true,
        position: Duration.zero,
        duration: const Duration(seconds: 2),
        playbackArmedAt: armed,
        now: armed.add(const Duration(seconds: 2)),
      ),
      isFalse,
    );
    expect(
      FeedPlaybackPolicy.shouldIgnoreSpuriousComplete(
        hasPresentedFirstFrame: true,
        position: Duration.zero,
        duration: const Duration(seconds: 2),
        playbackArmedAt: armed,
        now: armed.add(const Duration(milliseconds: 200)),
      ),
      isTrue,
    );
  });

  test('does not ignore EOS when duration is still unknown', () {
    final armed = DateTime(2026, 1, 1, 12);
    expect(
      FeedPlaybackPolicy.shouldIgnoreSpuriousComplete(
        hasPresentedFirstFrame: true,
        position: Duration.zero,
        duration: Duration.zero,
        playbackArmedAt: armed,
        now: armed.add(const Duration(milliseconds: 1800)),
      ),
      isFalse,
    );
  });

  group('FeedPlaybackPolicy.shouldAcceptNaturalComplete', () {
    test('rejects EOS while feed is occluded / suspended', () {
      expect(
        FeedPlaybackPolicy.shouldAcceptNaturalComplete(
          isPlaybackVisible: false,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldAcceptNaturalComplete(
          isPlaybackVisible: true,
        ),
        isTrue,
      );
    });
  });

  group('FeedPlaybackPolicy.shouldUseNativeLoop', () {
    test('disables native loop for short / unknown duration', () {
      expect(
        FeedPlaybackPolicy.shouldUseNativeLoop(
          autoPlayEnabled: false,
          duration: const Duration(seconds: 2),
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldUseNativeLoop(
          autoPlayEnabled: false,
          duration: Duration.zero,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldUseNativeLoop(
          autoPlayEnabled: false,
          duration: const Duration(seconds: 30),
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldUseNativeLoop(
          autoPlayEnabled: true,
          duration: const Duration(seconds: 2),
        ),
        isFalse,
      );
    });
  });

  group('FeedPlaybackPolicy recommend end-of-feed', () {
    test('loadMore only when the playhead is on the last card', () {
      expect(
        FeedPlaybackPolicy.shouldLoadMoreAtLastItem(
          currentIndex: 0,
          itemCount: 10,
          hasMore: true,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldLoadMoreAtLastItem(
          currentIndex: 9,
          itemCount: 10,
          hasMore: true,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldLoadMoreAtLastItem(
          currentIndex: 0,
          itemCount: 1,
          hasMore: true,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldLoadMoreAtLastItem(
          currentIndex: 9,
          itemCount: 10,
          hasMore: false,
        ),
        isFalse,
      );
    });

    test('toast only on the last card when hasMore is false', () {
      expect(
        FeedPlaybackPolicy.shouldToastNoMoreItems(
          currentIndex: 0,
          itemCount: 10,
          hasMore: false,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldToastNoMoreItems(
          currentIndex: 9,
          itemCount: 10,
          hasMore: false,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldToastNoMoreItems(
          currentIndex: 9,
          itemCount: 10,
          hasMore: true,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldToastNoMoreItems(
          currentIndex: 0,
          itemCount: 0,
          hasMore: false,
        ),
        isFalse,
      );
    });

    test('prefetch when playhead enters the last source work', () {
      expect(
        FeedPlaybackPolicy.shouldPrefetchAtLastSourceWork(
          currentSourceIndex: 0,
          sourceCount: 2,
          hasMore: true,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldPrefetchAtLastSourceWork(
          currentSourceIndex: 1,
          sourceCount: 2,
          hasMore: true,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldPrefetchAtLastSourceWork(
          currentSourceIndex: 1,
          sourceCount: 2,
          hasMore: false,
        ),
        isFalse,
      );
    });

    test('source index counts unique works across expanded episodes', () {
      final keys = [
        FeedPlaybackPolicy.sourceWorkKey(
          contentType: 'short_video',
          dramaId: '',
          episodeId: 'sv1',
        ),
        FeedPlaybackPolicy.sourceWorkKey(
          contentType: 'drama_episode',
          dramaId: 'd1',
          episodeId: null,
        ),
        FeedPlaybackPolicy.sourceWorkKey(
          contentType: 'drama_episode',
          dramaId: 'd1',
          episodeId: null,
        ),
        FeedPlaybackPolicy.sourceWorkKey(
          contentType: 'drama_episode',
          dramaId: 'd1',
          episodeId: null,
        ),
      ];
      expect(FeedPlaybackPolicy.sourceCountForKeys(keys), 2);
      expect(
        FeedPlaybackPolicy.sourceIndexForFlatIndex(
          sourceKeys: keys,
          flatIndex: 0,
        ),
        0,
      );
      expect(
        FeedPlaybackPolicy.sourceIndexForFlatIndex(
          sourceKeys: keys,
          flatIndex: 2,
        ),
        1,
      );
      expect(
        FeedPlaybackPolicy.shouldPrefetchAtLastSourceWork(
          currentSourceIndex: FeedPlaybackPolicy.sourceIndexForFlatIndex(
            sourceKeys: keys,
            flatIndex: 1,
          ),
          sourceCount: FeedPlaybackPolicy.sourceCountForKeys(keys),
          hasMore: true,
        ),
        isTrue,
      );
    });
  });

  group('FeedPlaybackPolicy unauthorized media', () {
    test('recognizes CloudFront denial phrasing', () {
      expect(
        FeedPlaybackPolicy.isUnauthorizedMediaError(
          'You do not have permission to access the requested resource.',
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isUnauthorizedMediaError('HTTP 403 Forbidden'),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isUnauthorizedMediaError('Unauthorized'),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isUnauthorizedMediaError('The network timed out'),
        isFalse,
      );
    });

    test('stops kicking play once the CDN refused the URL', () {
      expect(
        FeedPlaybackPolicy.shouldRetryPlayBeforeFrameWait(
          isPlaying: false,
          hasPresentedFirstFrame: false,
          completed: false,
          unauthorized: true,
        ),
        isFalse,
      );
    });

    test('still kicks play for an ordinary paused ACK', () {
      expect(
        FeedPlaybackPolicy.shouldRetryPlayBeforeFrameWait(
          isPlaying: false,
          hasPresentedFirstFrame: false,
          completed: false,
        ),
        isTrue,
      );
    });

    test('treats the stalled-playback watchdog as a buffering timeout', () {
      expect(
        FeedPlaybackPolicy.isBufferingTimeoutError(
          'Buffering timed out after 12s',
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isBufferingTimeoutError('codec error'),
        isFalse,
      );
    });
  });

  group('FeedPlaybackPolicy unplayable / no-frame retry', () {
    test('treats 121019 as unplayable transcode', () {
      expect(
        FeedPlaybackPolicy.isUnplayableTranscodeError(
          const BusinessError(121019, '剧集转码失败'),
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isUnplayableTranscodeError(
          const BusinessError(100400, 'bad cursor'),
        ),
        isFalse,
      );
      expect(FeedPlaybackPolicy.isUnplayableTranscodeError(null), isFalse);
    });

    test('reloads when play started or buffering made progress', () {
      expect(
        FeedPlaybackPolicy.shouldRetryLoadAfterNoFrame(
          didEnterPlaying: false,
          hasPresentedFirstFrame: false,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldRetryLoadAfterNoFrame(
          didEnterPlaying: true,
          hasPresentedFirstFrame: false,
        ),
        isTrue,
      );
      // Sustained buffering without `playing` (user log: buffering×N then
      // 4s noFrame) — allow one more loadUrl for surface races.
      expect(
        FeedPlaybackPolicy.shouldRetryLoadAfterNoFrame(
          didEnterPlaying: false,
          didBufferOrLoad: true,
          hasPresentedFirstFrame: false,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldRetryLoadAfterNoFrame(
          didEnterPlaying: false,
          didBufferOrLoad: true,
          mediaUnauthorized: true,
          hasPresentedFirstFrame: false,
        ),
        isFalse,
      );
    });

    test('classifyFailure maps known error shapes', () {
      expect(
        FeedPlaybackPolicy.classifyFailure(
          StateError('Native playback produced no video frame'),
        ),
        PlaybackFailureReason.noFrame,
      );
      expect(
        FeedPlaybackPolicy.classifyFailure(
          StateError(
            'Native playback produced no video frame (unauthorized)',
          ),
        ),
        PlaybackFailureReason.unauthorized,
      );
      expect(
        FeedPlaybackPolicy.shouldAttemptAuthRecovery(
          PlaybackFailureReason.noFrame,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldAttemptAuthRecovery(
          PlaybackFailureReason.unauthorized,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.classifyFailure(
          StateError('Playback buffering timed out'),
        ),
        PlaybackFailureReason.bufferingTimeout,
      );
      expect(
        FeedPlaybackPolicy.classifyFailure(
          'You do not have permission to access the requested resource.',
        ),
        PlaybackFailureReason.unauthorized,
      );
      expect(
        FeedPlaybackPolicy.classifyFailure(
          TimeoutException('loadUrl'),
        ),
        PlaybackFailureReason.loadTimeout,
      );
      expect(
        FeedPlaybackPolicy.classifyFailure(
          const BusinessError(121019, 'transcoding'),
        ),
        PlaybackFailureReason.transcodeUnplayable,
      );
      expect(
        FeedPlaybackPolicy.classifyFailure(
          'PlatformException(LOAD_ERROR, boom, null, null)',
        ),
        PlaybackFailureReason.nativeError,
      );
    });
  });

  group('FeedPlaybackPolicy.shouldLoopCurrentItem', () {
    test('loops when autoplay is off', () {
      expect(
        FeedPlaybackPolicy.shouldLoopCurrentItem(autoPlayEnabled: false),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldLoopCurrentItem(autoPlayEnabled: true),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldLoopCurrentItem(
          autoPlayEnabled: true,
          overlayHoldsAdvance: true,
        ),
        isTrue,
      );
    });
  });

  group('FeedPlaybackPolicy.shouldAutoAdvance', () {
    test('advances only when autoplay is on and no overlay is holding', () {
      expect(
        FeedPlaybackPolicy.shouldAutoAdvance(
          autoPlayEnabled: true,
          overlayHoldsAdvance: false,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldAutoAdvance(
          autoPlayEnabled: true,
          overlayHoldsAdvance: true,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldAutoAdvance(
          autoPlayEnabled: false,
          overlayHoldsAdvance: false,
        ),
        isFalse,
      );
    });
  });

  test('staggered native dispose waits for the pop transition', () {
    expect(
      StoryDurations.nativePlayerDisposeAfterPop.inMilliseconds,
      greaterThanOrEqualTo(400),
    );
    expect(
      StoryDurations.nativePlayerDisposeStagger.inMilliseconds,
      inInclusiveRange(80, 200),
    );
  });

  group('FeedPlaybackPolicy recommend bind invalidation', () {
    test('in-flight bind is stale when index or drama changes', () {
      expect(
        FeedPlaybackPolicy.shouldInvalidateInFlightBind(
          bindRunning: true,
          bindingIndex: 0,
          bindingDramaId: 'a',
          nextIndex: 1,
          nextDramaId: 'b',
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isStaleFeedBind(
          snapshotIndex: 0,
          snapshotDramaId: 'a',
          liveIndex: 1,
          liveDramaId: 'b',
        ),
        isTrue,
      );
    });

    test('same card play payload does not invalidate the in-flight bind', () {
      expect(
        FeedPlaybackPolicy.shouldInvalidateInFlightBind(
          bindRunning: true,
          bindingIndex: 2,
          bindingDramaId: 'a',
          nextIndex: 2,
          nextDramaId: 'a',
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldInvalidateBindOnEnqueue(
          bindRunning: true,
          bindingIndex: 2,
          bindingDramaId: 'a',
          nextIndex: 2,
          nextDramaId: 'a',
          activeDramaId: 'a',
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldInvalidateInFlightBind(
          bindRunning: false,
          bindingIndex: 0,
          bindingDramaId: 'a',
          nextIndex: 1,
          nextDramaId: 'b',
        ),
        isFalse,
      );
    });

    test(
      'index-only or drama-only change still invalidates in-flight bind',
      () {
        expect(
          FeedPlaybackPolicy.shouldInvalidateInFlightBind(
            bindRunning: true,
            bindingIndex: 0,
            bindingDramaId: 'a',
            nextIndex: 1,
            nextDramaId: 'a',
          ),
          isTrue,
        );
        expect(
          FeedPlaybackPolicy.shouldInvalidateInFlightBind(
            bindRunning: true,
            bindingIndex: 0,
            bindingDramaId: 'a',
            nextIndex: 0,
            nextDramaId: 'b',
          ),
          isTrue,
        );
        expect(
          FeedPlaybackPolicy.isStaleFeedBind(
            snapshotIndex: 3,
            snapshotDramaId: 'a',
            liveIndex: 3,
            liveDramaId: 'b',
          ),
          isTrue,
        );
        expect(
          FeedPlaybackPolicy.isStaleFeedBind(
            snapshotIndex: 0,
            snapshotDramaId: 'a',
            liveIndex: 0,
            liveDramaId: 'a',
          ),
          isFalse,
        );
      },
    );

    test('idle slot holding another drama invalidates on enqueue', () {
      expect(
        FeedPlaybackPolicy.shouldInvalidateBindOnEnqueue(
          bindRunning: false,
          bindingIndex: null,
          bindingDramaId: null,
          nextIndex: 1,
          nextDramaId: 'b',
          activeDramaId: 'a',
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldInvalidateBindOnEnqueue(
          bindRunning: false,
          bindingIndex: null,
          bindingDramaId: null,
          nextIndex: 0,
          nextDramaId: 'a',
          activeDramaId: 'a',
        ),
        isFalse,
      );
    });

    test('bind target requires a live play payload', () {
      expect(
        FeedPlaybackPolicy.isBindTargetCurrent(
          snapshotIndex: 1,
          snapshotDramaId: 'b',
          liveIndex: 1,
          liveDramaId: 'b',
          liveHasPlay: false,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.isBindTargetCurrent(
          snapshotIndex: 1,
          snapshotDramaId: 'b',
          liveIndex: 1,
          liveDramaId: 'b',
          liveHasPlay: true,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isBindTargetCurrent(
          snapshotIndex: 0,
          snapshotDramaId: 'a',
          liveIndex: 1,
          liveDramaId: 'b',
          liveHasPlay: true,
        ),
        isFalse,
      );
    });

    test('retargeted slot without a loaded play must not resume', () {
      expect(
        FeedPlaybackPolicy.canResumeBoundSlot(
          slotPlaybackId: 'b',
          itemPlaybackId: 'b',
          surfaceReady: true,
          hasEngine: true,
          hasLoadedPlay: false,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.canResumeBoundSlot(
          slotPlaybackId: 'b',
          itemPlaybackId: 'b',
          surfaceReady: true,
          hasEngine: true,
          hasLoadedPlay: true,
          loadedPlayPlaybackId: 'b',
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.canResumeBoundSlot(
          slotPlaybackId: 'b',
          itemPlaybackId: 'b',
          surfaceReady: true,
          hasEngine: true,
          hasLoadedPlay: true,
          loadedPlayPlaybackId: 'a',
        ),
        isFalse,
      );
    });

    test('mapped surface without a frame is not current-page ready', () {
      expect(
        FeedPlaybackPolicy.isCurrentPagePlayerReady(
          slotMatchesDrama: true,
          surfaceReady: true,
          frameReady: false,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.isCurrentPagePlayerReady(
          slotMatchesDrama: true,
          surfaceReady: true,
          frameReady: true,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isCurrentPagePlayerReady(
          slotMatchesDrama: true,
          surfaceReady: true,
          frameReady: true,
          loadedPlayMatches: false,
        ),
        isFalse,
      );
    });

    test('decoded slot must match loaded play identity', () {
      expect(
        FeedPlaybackPolicy.slotHoldsDecodedItem(
          slotPlaybackId: 'b',
          itemPlaybackId: 'b',
          loadedPlayPlaybackId: 'a',
          hasPendingLoad: false,
          surfaceReady: true,
          frameReady: true,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.slotHoldsDecodedItem(
          slotPlaybackId: 'b',
          itemPlaybackId: 'b',
          loadedPlayPlaybackId: 'b',
          hasPendingLoad: true,
          surfaceReady: true,
          frameReady: true,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.slotHoldsDecodedItem(
          slotPlaybackId: 'b',
          itemPlaybackId: 'b',
          loadedPlayPlaybackId: 'b',
          hasPendingLoad: false,
          surfaceReady: true,
          frameReady: true,
        ),
        isTrue,
      );
    });

    test('early-activate is semi-open: settled load without frame may start', () {
      // Pending / bad identity still blocked (dual-decode / wrong card).
      expect(
        FeedPlaybackPolicy.isNeighborReadyForEarlyActivate(
          slotPlaybackId: 'n1',
          loadedPlayPlaybackId: 'n1',
          hasPendingLoad: true,
          surfaceReady: true,
          frameReady: false,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.isNeighborReadyForEarlyActivate(
          slotPlaybackId: 'n1',
          loadedPlayPlaybackId: 'other',
          hasPendingLoad: false,
          surfaceReady: true,
          frameReady: false,
        ),
        isFalse,
      );
      // Settled matching media — cover latch hides until paint.
      expect(
        FeedPlaybackPolicy.isNeighborReadyForEarlyActivate(
          slotPlaybackId: 'n1',
          loadedPlayPlaybackId: 'n1',
          hasPendingLoad: false,
          surfaceReady: true,
          frameReady: false,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isNeighborReadyForEarlyActivate(
          slotPlaybackId: 'n1',
          loadedPlayPlaybackId: 'n1',
          hasPendingLoad: false,
          surfaceReady: true,
          frameReady: true,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isNeighborReadyForEarlyActivate(
          slotPlaybackId: null,
          loadedPlayPlaybackId: 'n1',
          hasPendingLoad: false,
          surfaceReady: true,
          frameReady: true,
        ),
        isFalse,
      );
    });

    test('short-drama early-activate allows settled preload without frame', () {
      expect(
        FeedPlaybackPolicy.isEpisodeReadyForEarlyActivate(
          episodeNo: 3,
          frameReadyEpisodeNos: const {},
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.isEpisodeReadyForEarlyActivate(
          episodeNo: 3,
          frameReadyEpisodeNos: const {},
          settledEpisodeNos: const {3},
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isEpisodeReadyForEarlyActivate(
          episodeNo: 3,
          frameReadyEpisodeNos: const {3},
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.isEpisodeReadyForEarlyActivate(
          episodeNo: 0,
          frameReadyEpisodeNos: const {0},
          settledEpisodeNos: const {0},
        ),
        isFalse,
      );
    });

    test('swipe bumps generation and fails in-flight shouldContinue', () {
      const started = 4;
      expect(
        FeedPlaybackPolicy.shouldContinueFeedBind(
          generation: started,
          currentGeneration: started,
          mounted: true,
          snapshotStillCurrent: true,
        ),
        isTrue,
      );
      expect(
        FeedPlaybackPolicy.shouldContinueFeedBind(
          generation: started,
          currentGeneration: started + 1,
          mounted: true,
          snapshotStillCurrent: true,
        ),
        isFalse,
        reason: 'enqueue invalidation must fail loadUrl immediately',
      );
      expect(
        FeedPlaybackPolicy.shouldContinueFeedBind(
          generation: started,
          currentGeneration: started,
          mounted: true,
          snapshotStillCurrent: false,
        ),
        isFalse,
      );
      expect(
        FeedPlaybackPolicy.shouldContinueFeedBind(
          generation: started,
          currentGeneration: started,
          mounted: false,
          snapshotStillCurrent: true,
        ),
        isFalse,
      );
    });
  });

  test('isNoVideoFrameError matches native empty-frame StateError', () {
    expect(
      FeedPlaybackPolicy.isNoVideoFrameError(
        StateError('Native playback produced no video frame'),
      ),
      isTrue,
    );
    expect(
      FeedPlaybackPolicy.isNoVideoFrameError(
        StateError('controller was disposed'),
      ),
      isFalse,
    );
    expect(FeedPlaybackPolicy.isNoVideoFrameError('no video frame'), isFalse);
  });

  group('FeedPlaybackPolicy.decideAdvance', () {
    test('auto-play on, no overlay hold -> advance next', () {
      expect(
        FeedPlaybackPolicy.decideAdvance(
          autoPlayEnabled: true,
          overlayHoldsAdvance: false,
        ),
        FeedAdvanceDecision.advanceNext,
      );
    });

    test('auto-play off -> loop current regardless of overlay', () {
      expect(
        FeedPlaybackPolicy.decideAdvance(
          autoPlayEnabled: false,
          overlayHoldsAdvance: false,
        ),
        FeedAdvanceDecision.loopCurrent,
      );
      expect(
        FeedPlaybackPolicy.decideAdvance(
          autoPlayEnabled: false,
          overlayHoldsAdvance: true,
        ),
        FeedAdvanceDecision.loopCurrent,
      );
    });

    test('overlay holds advance -> loop current even when auto-play on', () {
      expect(
        FeedPlaybackPolicy.decideAdvance(
          autoPlayEnabled: true,
          overlayHoldsAdvance: true,
        ),
        FeedAdvanceDecision.loopCurrent,
      );
    });

    test('decideAdvance is consistent with shouldAutoAdvance/shouldLoop', () {
      for (final autoPlay in [true, false]) {
        for (final holds in [true, false]) {
          final decision = FeedPlaybackPolicy.decideAdvance(
            autoPlayEnabled: autoPlay,
            overlayHoldsAdvance: holds,
          );
          final shouldAdvance = FeedPlaybackPolicy.shouldAutoAdvance(
            autoPlayEnabled: autoPlay,
            overlayHoldsAdvance: holds,
          );
          final shouldLoop = FeedPlaybackPolicy.shouldLoopCurrentItem(
            autoPlayEnabled: autoPlay,
            overlayHoldsAdvance: holds,
          );
          expect(
            decision == FeedAdvanceDecision.advanceNext,
            shouldAdvance,
            reason:
                'advanceNext must match shouldAutoAdvance '
                '(autoPlay=$autoPlay holds=$holds)',
          );
          expect(
            decision == FeedAdvanceDecision.loopCurrent,
            shouldLoop,
            reason:
                'loopCurrent must match shouldLoopCurrentItem '
                '(autoPlay=$autoPlay holds=$holds)',
          );
        }
      }
    });
  });
}
