import 'dart:async';

import '../core/result.dart';
import '../core/story_constants.dart';
import '../model/work_content_type.dart';

/// Machine-readable cause for a feed playback failure (log / toast / telemetry).
///
/// Keep the set small and stable — greppable in logcat via `failure=…`.
enum PlaybackFailureReason {
  /// First-frame wait timed out with no painted frame.
  noFrame,

  /// Native buffering watchdog fired.
  bufferingTimeout,

  /// CDN / cookie denied the media URL (403 / forbidden).
  unauthorized,

  /// Dart-side loadUrl / method-channel timeout.
  loadTimeout,

  /// Episode still transcoding (`121019`) or similar unplayable business code.
  transcodeUnplayable,

  /// Native player reported an error that is not one of the above.
  nativeError,

  /// Unclassified.
  unknown,
}

/// Shared playback decisions for short-drama feed and recommend.
///
/// Keep this file free of Flutter/Riverpod so both [VideoFeedController]
/// and [RecommendFeedBody] can share the same skip/wait rules without
/// merging their slot runtimes.
class FeedPlaybackPolicy {
  FeedPlaybackPolicy._();

  static const int maxUnexpectedPauseAttempts = 2;
  static const Duration unexpectedPauseSettle = Duration(milliseconds: 280);
  static const Duration playbackArmGrace = Duration(milliseconds: 800);

  /// After an await, picker/swipe activate must stop if the page is gone
  /// or a newer episode was queued.
  static bool isActivateSuperseded({
    required bool disposed,
    required int episodeNo,
    required int? queuedEpisode,
  }) {
    if (disposed) return true;
    return queuedEpisode != null && queuedEpisode != episodeNo;
  }

  /// HLS routinely spends longer than this in `waitingToPlay` with no
  /// `playing` event yet — kicking during that window fights the first play.
  static const Duration playAckRetryGap = Duration(milliseconds: 400);

  /// Delayed re-`play()` budget after loadUrl left the item paused.
  /// Two attempts (~0.8–1.2s) cover iOS ACK-while-paused without stretching
  /// into the 4s first-frame timeout. Extra kicks beyond this fight buffering.
  static const int playAckRetryAttempts = 2;

  /// Neighbor `loadUrl` keeps emitting paused/loading on the active player
  /// after Dart's preload future has already completed. Keep the unexpected-
  /// pause skip window open long enough for those late events.
  static const Duration neighborLoadGuard = Duration(milliseconds: 1600);

  /// Skip auto-resume when the pause is explained by UX or a neighbor loadUrl.
  ///
  /// [isBuffering] / [playbackError]: `play()` on a stalled or already-failed
  /// pipeline restarts the 12s buffering watchdog and freezes the last frame.
  static bool shouldSkipUnexpectedPause({
    required bool userPaused,
    required bool visible,
    required bool activateRunning,
    required bool volumeDucked,
    required bool neighborLoadInFlight,
    bool promoteInFlight = false,
    bool ended = false,
    bool isBuffering = false,
    bool playbackError = false,
  }) {
    if (!visible || userPaused || ended) return true;
    if (activateRunning || volumeDucked) return true;
    if (neighborLoadInFlight || promoteInFlight) return true;
    if (isBuffering || playbackError) return true;
    return false;
  }

  /// Adjacent swipe: never cold-loadUrl on active while a neighbor is
  /// already holding or decoding the target (dual-decode freeze).
  static AdjacentActivateChoice chooseAdjacentActivate({
    required bool neighborReady,
    required bool neighborLoadInFlight,
  }) {
    if (neighborReady) return AdjacentActivateChoice.swap;
    if (neighborLoadInFlight) return AdjacentActivateChoice.waitInFlight;
    return AdjacentActivateChoice.controlledCold;
  }

  /// Cover stays up until a painted frame or an explicit latch.
  /// Promoting then waiting for firstFrame behind a poster deadlocks
  /// `readyForDisplay`.
  static bool mayWaitForFirstFrame({required bool coverRevealed}) =>
      coverRevealed;

  /// iOS ACKs `play()` while the item is still paused after loadUrl.
  /// Kick play again instead of waiting 4s for frames on a paused player.
  ///
  /// [unauthorized] short-circuits the kicks: the CDN already refused this
  /// resource, so replaying the same URL only burns the retry gaps and the
  /// 4s frame wait on top of a failure we cannot recover from here.
  ///
  /// [isBuffering] / [isLoading] mean the first `play()` was accepted and
  /// the item is waiting for data — do **not** kick then (interrupts
  /// startup), but the kick **loop** should keep polling rather than exit:
  /// otherwise a brief loading window permanently skips the pause recovery.
  static bool shouldRetryPlayBeforeFrameWait({
    required bool isPlaying,
    required bool hasPresentedFirstFrame,
    required bool completed,
    bool unauthorized = false,
    bool isBuffering = false,
    bool isLoading = false,
  }) {
    if (kickLoopSatisfied(
      isPlaying: isPlaying,
      hasPresentedFirstFrame: hasPresentedFirstFrame,
      completed: completed,
      unauthorized: unauthorized,
    )) {
      return false;
    }
    if (isBuffering || isLoading) return false;
    return true;
  }

  /// Kick loop terminal states — stop polling, do not issue another play().
  static bool kickLoopSatisfied({
    required bool isPlaying,
    required bool hasPresentedFirstFrame,
    required bool completed,
    bool unauthorized = false,
  }) {
    if (completed || isPlaying || hasPresentedFirstFrame) return true;
    if (unauthorized) return true;
    return false;
  }

  /// First play is in flight — wait, do not re-play().
  static bool isStartupBusy({
    required bool isBuffering,
    required bool isLoading,
  }) =>
      isBuffering || isLoading;

  /// CloudFront / origin refused the media request (typically an unsigned or
  /// expired signed-cookie URL). Recovery is refetching credentials, never
  /// retrying the same URL.
  static bool isUnauthorizedMediaError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('do not have permission') ||
        lower.contains('403') ||
        lower.contains('forbidden') ||
        lower.contains('unauthorized');
  }

  /// Native [NativeVideoPlayerConfig.bufferingTimeout] synthesized this.
  /// Recovery is reload, never another `play()` on the paused pipeline.
  static bool isBufferingTimeoutError(Object error) {
    return error.toString().toLowerCase().contains('buffering timed out');
  }

  /// Natural EOS may fire while the feed is occluded (route push / tab /
  /// teardown dispose). Those must not count as 有效完播 — short clips with
  /// native loop off are especially noisy because dispose often emits
  /// `completed`, and metrics treat that as a strong first-pass finish.
  ///
  /// Sheet overlays ([isPlaybackVisible] still true) may still complete.
  static bool shouldAcceptNaturalComplete({
    required bool isPlaybackVisible,
  }) => isPlaybackVisible;

  /// Neighbor loadUrl / item replace can emit `completed` at t=0 right after
  /// a successful first frame. Auto-advancing then cold-loads the next card
  /// on top of a promote already in flight.
  ///
  /// Short clips (≤5s) often finish inside the long-arm grace with the
  /// playhead already reset to 0 — that must not be treated as spurious, or
  /// first-pass complete never fires.
  static bool shouldIgnoreSpuriousComplete({
    required bool hasPresentedFirstFrame,
    required Duration position,
    required Duration duration,
    DateTime? playbackArmedAt,
    DateTime? now,
  }) {
    if (!hasPresentedFirstFrame) return true;
    final posMs = position.inMilliseconds;
    final durMs = duration.inMilliseconds;
    final t = now ?? DateTime.now();
    final isShortClip = durMs > 0 && durMs <= 5000;
    final durationUnknown = durMs <= 0;
    final armGrace = (isShortClip || durationUnknown)
        ? const Duration(milliseconds: 400)
        : const Duration(seconds: 2);

    if (playbackArmedAt != null &&
        t.difference(playbackArmedAt) < armGrace &&
        posMs < 800) {
      return true;
    }
    // Native EOS often seeks to 0 before `completed`; only treat t≈0 as
    // spurious right after arming (neighbor loadUrl), not after real watch.
    // Skip for short / unknown duration — identical to legitimate EOS.
    if (!isShortClip &&
        !durationUnknown &&
        posMs < 400 &&
        durMs > 2000 &&
        playbackArmedAt != null &&
        t.difference(playbackArmedAt) < const Duration(seconds: 3)) {
      return true;
    }
    return false;
  }

  /// 连播 off: loop the current item. 连播 on: native `completed` so the
  /// feed can auto-advance (or pause on the last episode / last card).
  /// Comment / drama / character overlays hold auto-advance, so loop instead.
  static bool shouldLoopCurrentItem({
    required bool autoPlayEnabled,
    bool overlayHoldsAdvance = false,
  }) => !autoPlayEnabled || overlayHoldsAdvance;

  /// Native loop suppresses `PlayerActivityState.completed`. Short clips
  /// (<5s) must emit completed on the **first** pass so complete reports
  /// immediately; Dart replay handles repeat UX when auto-play is off.
  ///
  /// Unknown duration (`<=0`) also keeps native loop off — otherwise a 2s
  /// clip may start looping before duration arrives and never emit completed
  /// on the first pass.
  static bool shouldUseNativeLoop({
    required bool autoPlayEnabled,
    required Duration duration,
  }) {
    if (autoPlayEnabled) return false;
    final durMs = duration.inMilliseconds;
    if (durMs <= 0 || durMs < 5000) return false;
    return true;
  }

  /// Auto-advance to the next episode/card. Overlays (comments, 短剧,
  /// characters) keep the current item until dismissed.
  static bool shouldAutoAdvance({
    required bool autoPlayEnabled,
    required bool overlayHoldsAdvance,
  }) => autoPlayEnabled && !overlayHoldsAdvance;

  /// Recommend: fetch the next page only after the playhead is on the last card.
  static bool shouldLoadMoreAtLastItem({
    required int currentIndex,
    required int itemCount,
    required bool hasMore,
  }) {
    if (!hasMore || itemCount <= 0) return false;
    return currentIndex >= itemCount - 1;
  }

  /// External playlist: prefetch when the playhead is already inside the last
  /// **source work** (not only the last flattened episode), so a long drama at
  /// the end of the parent page does not delay loadMore until its final ep.
  static bool shouldPrefetchAtLastSourceWork({
    required int currentSourceIndex,
    required int sourceCount,
    required bool hasMore,
  }) {
    if (!hasMore || sourceCount <= 0) return false;
    return currentSourceIndex >= sourceCount - 1;
  }

  /// Stable source-work key for flattened recommend/playlist cards.
  static String sourceWorkKey({
    required String? contentType,
    required String dramaId,
    required String? episodeId,
  }) {
    final type = WorkContentType.fromApi(contentType);
    if (type.isShortVideo) {
      final ep = episodeId?.trim() ?? '';
      return ep.isEmpty ? 'short_video:' : 'short_video:$ep';
    }
    final drama = dramaId.trim();
    if (drama.isNotEmpty) return 'short_drama:$drama';
    final ep = episodeId?.trim() ?? '';
    return ep.isEmpty ? 'unknown:' : 'unknown:$ep';
  }

  /// Index of the source work that owns [flatIndex] within [sourceKeys].
  static int sourceIndexForFlatIndex({
    required List<String> sourceKeys,
    required int flatIndex,
  }) {
    if (sourceKeys.isEmpty || flatIndex < 0) return 0;
    final seen = <String>{};
    var index = 0;
    final end = flatIndex.clamp(0, sourceKeys.length - 1);
    for (var i = 0; i <= end; i++) {
      if (seen.add(sourceKeys[i])) {
        index = seen.length - 1;
      }
    }
    return index;
  }

  static int sourceCountForKeys(List<String> sourceKeys) {
    if (sourceKeys.isEmpty) return 0;
    return sourceKeys.toSet().length;
  }

  /// Recommend: toast when the user is already on the last card and the
  /// feed has no further page.
  static bool shouldToastNoMoreItems({
    required int currentIndex,
    required int itemCount,
    required bool hasMore,
  }) {
    if (itemCount <= 0 || hasMore) return false;
    return currentIndex >= itemCount - 1;
  }

  /// Episode detail `121019` — HLS is not ready. The feed card URL will not
  /// play either; skip rather than loadUrl-retrying a dead playlist.
  static bool isUnplayableTranscodeError(ApiError? error) =>
      error is BusinessError &&
      error.code == StoryConstants.episodeTranscodeFailedCode;

  /// After play() ACKs with no frame, reloading the same URL can burn
  /// [StoryConstants.playerOperationTimeout]. Retry only when native made
  /// real startup progress (playing, or buffering/loading) — a paused-forever
  /// ACK with no buffer means the URL/pipeline is dead. Sustained buffering
  /// without `playing` is often a surface / promote race; one reload is
  /// cheaper than an auth round-trip on the same unsigned URL.
  ///
  /// Never retry when [mediaUnauthorized]: CDN already refused the resource.
  static bool shouldRetryLoadAfterNoFrame({
    required bool didEnterPlaying,
    required bool hasPresentedFirstFrame,
    bool didBufferOrLoad = false,
    bool mediaUnauthorized = false,
  }) {
    if (hasPresentedFirstFrame || mediaUnauthorized) return false;
    return didEnterPlaying || didBufferOrLoad;
  }

  static bool isNoVideoFrameError(Object error) =>
      error is StateError &&
      error.message.contains('Native playback produced no video frame');

  /// Cookie / signed-URL recovery only helps CDN 403-style failures.
  /// `noFrame` while buffering is a surface/startup race — reload, do not
  /// refresh play metadata (unsigned `cookies=false` stays unsigned).
  static bool shouldAttemptAuthRecovery(PlaybackFailureReason reason) =>
      reason == PlaybackFailureReason.unauthorized;

  /// Maps a thrown / reported failure onto [PlaybackFailureReason] for logs.
  static PlaybackFailureReason classifyFailure(Object error) {
    // Unauthorized before noFrame: engine may wrap CDN refusal as a
    // no-frame StateError that still contains "unauthorized".
    if (isUnauthorizedMediaError(error.toString())) {
      return PlaybackFailureReason.unauthorized;
    }
    if (isNoVideoFrameError(error)) return PlaybackFailureReason.noFrame;
    if (isBufferingTimeoutError(error)) {
      return PlaybackFailureReason.bufferingTimeout;
    }
    if (error is TimeoutException) return PlaybackFailureReason.loadTimeout;
    if (isUnplayableTranscodeError(
      error is ApiError ? error : null,
    )) {
      return PlaybackFailureReason.transcodeUnplayable;
    }
    final text = error.toString().toLowerCase();
    if (text.contains('platformexception') ||
        text.contains('exoplayback') ||
        text.contains('avplayer') ||
        text.contains('coremedia') ||
        text.contains('load_error')) {
      return PlaybackFailureReason.nativeError;
    }
    return PlaybackFailureReason.unknown;
  }

  /// Recommend drain holds a snapshot for the whole `_bindOrPromote`. A swipe
  /// that only queues the next index leaves that snapshot stale.
  static bool isStaleFeedBind({
    required int snapshotIndex,
    required String? snapshotDramaId,
    required int liveIndex,
    required String? liveDramaId,
  }) {
    return snapshotIndex != liveIndex || snapshotDramaId != liveDramaId;
  }

  /// Bind may finish only while the snapshot is still the playhead and a
  /// play payload is present. Missing [liveHasPlay] means activate is still
  /// in flight — applying the old URL would uncover the new card.
  static bool isBindTargetCurrent({
    required int snapshotIndex,
    required String? snapshotDramaId,
    required int liveIndex,
    required String? liveDramaId,
    required bool liveHasPlay,
  }) {
    if (!liveHasPlay) return false;
    return !isStaleFeedBind(
      snapshotIndex: snapshotIndex,
      snapshotDramaId: snapshotDramaId,
      liveIndex: liveIndex,
      liveDramaId: liveDramaId,
    );
  }

  /// Bump `_playGeneration` as soon as a newer card is queued, not when the
  /// next bind starts — otherwise in-flight `loadUrl` / `migrateToActive`
  /// keep `shouldContinue == true`.
  static bool shouldInvalidateInFlightBind({
    required bool bindRunning,
    required int? bindingIndex,
    required String? bindingDramaId,
    required int nextIndex,
    required String? nextDramaId,
  }) {
    if (!bindRunning) return false;
    return bindingIndex != nextIndex || bindingDramaId != nextDramaId;
  }

  /// Enqueue-time invalidation: in-flight bind of another card, or an idle
  /// active slot still holding a different drama.
  ///
  /// Same-card `currentPlay` arriving while bind is running must not bump
  /// generation — that would abort the load we still want.
  static bool shouldInvalidateBindOnEnqueue({
    required bool bindRunning,
    required int? bindingIndex,
    required String? bindingDramaId,
    required int nextIndex,
    required String? nextDramaId,
    String? activeDramaId,
  }) {
    if (shouldInvalidateInFlightBind(
      bindRunning: bindRunning,
      bindingIndex: bindingIndex,
      bindingDramaId: bindingDramaId,
      nextIndex: nextIndex,
      nextDramaId: nextDramaId,
    )) {
      return true;
    }
    if (!bindRunning &&
        activeDramaId != null &&
        nextDramaId != null &&
        activeDramaId != nextDramaId) {
      return true;
    }
    return false;
  }

  /// Resume the active slot only when native already holds this playback
  /// identity (`dramaId:episodeId`). Slot and loaded-play ids must both match
  /// [itemPlaybackId] — `slot.playbackId` is retargeted in `_prepareSlot`
  /// while the AVPlayer item is still the previous card.
  static bool canResumeBoundSlot({
    required String? slotPlaybackId,
    required String itemPlaybackId,
    required bool surfaceReady,
    required bool hasEngine,
    required bool hasLoadedPlay,
    String? loadedPlayPlaybackId,
  }) {
    if (!hasEngine || !surfaceReady || slotPlaybackId != itemPlaybackId) {
      return false;
    }
    if (!hasLoadedPlay) return false;
    return (loadedPlayPlaybackId ?? slotPlaybackId) == itemPlaybackId;
  }

  /// Slot may uncover / count as ready only when native loaded play identity
  /// matches the card — `slot.playbackId` alone is retargeted before pixels
  /// catch up.
  static bool slotHoldsDecodedItem({
    required String? slotPlaybackId,
    required String itemPlaybackId,
    required String? loadedPlayPlaybackId,
    required bool hasPendingLoad,
    required bool surfaceReady,
    required bool frameReady,
  }) {
    if (!surfaceReady || !frameReady || hasPendingLoad) return false;
    if (slotPlaybackId != itemPlaybackId) return false;
    return loadedPlayPlaybackId == itemPlaybackId;
  }

  /// Neighbor preload may skip when native already holds a decoded frame, or
  /// a matching preload Completer is still in flight.
  ///
  /// Do not treat `episodeDataFromPlay` writing `currentPlay` alone as success.
  static bool shouldSkipNeighborPreload({
    required String? slotPlaybackId,
    required String itemPlaybackId,
    required String? loadedPlayPlaybackId,
    required bool frameReady,
    required bool hasPendingLoad,
    required bool hasInflightReady,
  }) {
    if (slotPlaybackId != itemPlaybackId) return false;
    if (hasInflightReady) return true;
    return frameReady &&
        loadedPlayPlaybackId == itemPlaybackId &&
        !hasPendingLoad;
  }

  /// Current-page cover. Mapping `surfaceReady` after a retarget is the
  /// previous card's platform view on the new index — keep the poster up
  /// until a painted frame (latch covers the post-loadUrl play() wait).
  static bool isCurrentPagePlayerReady({
    required bool slotMatchesDrama,
    required bool surfaceReady,
    required bool frameReady,
    bool loadedPlayMatches = true,
  }) {
    return slotMatchesDrama && loadedPlayMatches && surfaceReady && frameReady;
  }

  /// `loadUrl` / `migrateToActive` shouldContinue. Generation is bumped on
  /// enqueue invalidation so a swipe fails the in-flight task immediately.
  static bool shouldContinueFeedBind({
    required int generation,
    required int currentGeneration,
    required bool mounted,
    required bool snapshotStillCurrent,
  }) {
    return mounted && generation == currentGeneration && snapshotStillCurrent;
  }

  /// Whether a neighbor slot is ready for mid-swipe early-activate.
  ///
  /// **Semi-open**: settled matching media (`surfaceReady`, loaded id, no
  /// pending load) may *start* activate — cover latch hides until a frame.
  /// Still forbids pending load / identity mismatch (those fall into
  /// controlledCold dual-decode). Promote / uncover keep using the stricter
  /// [slotHoldsDecodedItem] (requires [frameReady]).
  static bool isNeighborReadyForEarlyActivate({
    required String? slotPlaybackId,
    required String? loadedPlayPlaybackId,
    required bool hasPendingLoad,
    required bool surfaceReady,
    required bool frameReady,
  }) {
    if (slotPlaybackId == null || slotPlaybackId.isEmpty) return false;
    if (hasPendingLoad || !surfaceReady) return false;
    if (loadedPlayPlaybackId != slotPlaybackId) return false;
    // frameReady optional for early-activate only.
    return true;
  }

  /// Short-drama early-activate gate.
  ///
  /// Painted frame is preferred; settled preload (mapped + load finished)
  /// is enough to start activate (semi-open) — pipeline waitInFlight / swap
  /// handles the rest under the poster.
  static bool isEpisodeReadyForEarlyActivate({
    required int episodeNo,
    required Set<int> frameReadyEpisodeNos,
    Set<int> settledEpisodeNos = const {},
  }) {
    if (episodeNo < 1) return false;
    if (frameReadyEpisodeNos.contains(episodeNo)) return true;
    return settledEpisodeNos.contains(episodeNo);
  }

  /// Whether identity change should enqueue a bind for an existing play.
  ///
  /// Auth recovery refreshes [currentPlay] then binds itself — enqueueing
  /// races a second cold load. Manual retry owns the cold bind after refresh,
  /// so its intermediate loading state must not enqueue.
  static bool shouldEnqueueBindOnIdentity({
    required bool hasCurrentPlay,
    required bool isPlayLoading,
    required bool authRecoveryInFlight,
    required bool manualRetryOwnsLoading,
  }) {
    if (!hasCurrentPlay) return false;
    if (authRecoveryInFlight) return false;
    if (manualRetryOwnsLoading && isPlayLoading) return false;
    return true;
  }

  /// Recommend bind path: resume active, promote a neighbor (swap / wait), or
  /// cold-load. Neighbor side reuses [chooseAdjacentActivate] so recommend and
  /// short-drama share the same ready / in-flight / cold trichotomy.
  static RecommendActivateDecision chooseRecommendActivate({
    required bool canResumeActive,
    required bool nextMatchesTarget,
    required bool nextDecodedReady,
    required bool nextLoadInFlight,
    required bool prevMatchesTarget,
    required bool prevDecodedReady,
    required bool prevLoadInFlight,
  }) {
    if (canResumeActive) {
      return const RecommendActivateDecision.resumeActive();
    }
    if (nextMatchesTarget) {
      final choice = chooseAdjacentActivate(
        neighborReady: nextDecodedReady,
        neighborLoadInFlight: nextLoadInFlight,
      );
      return RecommendActivateDecision.promote(
        forward: true,
        adjacent: choice,
      );
    }
    if (prevMatchesTarget) {
      final choice = chooseAdjacentActivate(
        neighborReady: prevDecodedReady,
        neighborLoadInFlight: prevLoadInFlight,
      );
      return RecommendActivateDecision.promote(
        forward: false,
        adjacent: choice,
      );
    }
    return const RecommendActivateDecision.coldBind();
  }

  /// 播放完成后的进集决策 —— 收敛 [_onPlaybackCompleted] 的 replay/next 判定，
  /// 供短剧 / 推荐两个 feed 共享。
  ///
  /// 当前行为：覆盖层持有 → 循环当前条目（replay）；连播开启且无覆盖 →
  /// 自动进集（advance）；连播关闭 → 循环当前条目（replay）。
  ///
  /// - [FeedAdvanceDecision.loopCurrent]: 循环当前条目。
  /// - [FeedAdvanceDecision.advanceNext]: 自动进集到下一个剧集/卡片。
  static FeedAdvanceDecision decideAdvance({
    required bool autoPlayEnabled,
    required bool overlayHoldsAdvance,
  }) {
    if (overlayHoldsAdvance) return FeedAdvanceDecision.loopCurrent;
    return autoPlayEnabled
        ? FeedAdvanceDecision.advanceNext
        : FeedAdvanceDecision.loopCurrent;
  }
}

enum AdjacentActivateChoice { swap, waitInFlight, controlledCold }

/// Result of [FeedPlaybackPolicy.chooseRecommendActivate].
class RecommendActivateDecision {
  const RecommendActivateDecision._(this.kind, {this.forward, this.adjacent});

  const RecommendActivateDecision.resumeActive()
    : this._(RecommendActivateKind.resumeActive);

  const RecommendActivateDecision.coldBind()
    : this._(RecommendActivateKind.coldBind);

  const RecommendActivateDecision.promote({
    required bool forward,
    required AdjacentActivateChoice adjacent,
  }) : this._(
         RecommendActivateKind.promoteNeighbor,
         forward: forward,
         adjacent: adjacent,
       );

  final RecommendActivateKind kind;
  final bool? forward;
  final AdjacentActivateChoice? adjacent;

  bool get isResume => kind == RecommendActivateKind.resumeActive;
  bool get isCold => kind == RecommendActivateKind.coldBind;
  bool get isPromote => kind == RecommendActivateKind.promoteNeighbor;
}

enum RecommendActivateKind { resumeActive, promoteNeighbor, coldBind }

/// 播放完成的进集决策结果（见 [FeedPlaybackPolicy.decideAdvance]）。
enum FeedAdvanceDecision { loopCurrent, advanceNext }
