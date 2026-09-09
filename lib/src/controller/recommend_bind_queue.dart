import 'dart:async';

import '../model/recommend_feed_model.dart';
import 'feed_playback_policy.dart';
import 'feed_role_ring.dart';
import 'feed_slot.dart';
import 'playback_engine.dart';
import 'recommend_feed_state.dart';
import 'recommend_manual_retry_guard.dart';

/// Host hooks the bind queue needs from [RecommendFeedBody].
///
/// Keeps PageController / setState / Riverpod reads in the widget while the
/// queue owns generation and drain mutual exclusion.
abstract interface class RecommendBindHost {
  bool get isMounted;
  bool get isPlaybackVisible;
  RecommendFeedState readFeed();
  FeedSlot get activeSlot;
  FeedSlot get nextSlot;
  FeedSlot get prevSlot;
  void clearCoverRevealLatch();
  void setPlaying(bool value);
  Future<void> bindOrPromote(RecommendFeedState feed);
}

/// Latest-wins bind queue + play generation for the recommend feed.
///
/// Extracted from [RecommendFeedBody] so swipe/hide can invalidate in-flight
/// binds without touching UI code.
class RecommendBindQueue {
  RecommendBindQueue(this._host);

  final RecommendBindHost _host;

  int playGeneration = 0;
  int neighborRestoreGeneration = 0;
  bool bindRunning = false;
  int? queuedBindIndex;
  int? bindingIndex;
  String? bindingPlaybackId;

  void enqueue(RecommendFeedState feed) {
    final index = feed.currentIndex;
    final dramaId = feed.currentItem?.playbackId;
    if (FeedPlaybackPolicy.shouldInvalidateBindOnEnqueue(
      bindRunning: bindRunning,
      bindingIndex: bindingIndex,
      bindingDramaId: bindingPlaybackId,
      nextIndex: index,
      nextDramaId: dramaId,
      activeDramaId: _host.activeSlot.playbackId,
    )) {
      invalidateStaleBind();
    }
    queuedBindIndex = index;
    if (bindRunning) return;
    unawaited(drain());
  }

  /// Swipe / hide must fail in-flight `shouldContinue` immediately.
  void invalidateStaleBind() {
    playGeneration++;
    neighborRestoreGeneration++;
    queuedBindIndex = null;
    _host.clearCoverRevealLatch();
    _host.setPlaying(false);
    try {
      final engine = _host.activeSlot.engine;
      unawaited(engine?.setVolume(0));
      unawaited(engine?.pause());
      engine?.forceAbandonPendingLoad();
    } catch (_) {}
  }

  void clearQueueMarkers() {
    queuedBindIndex = null;
    bindingIndex = null;
    bindingPlaybackId = null;
  }

  bool bindTargetStillCurrent(RecommendFeedState snapshot) {
    if (!_host.isMounted) return false;
    final live = _host.readFeed();
    return FeedPlaybackPolicy.isBindTargetCurrent(
      snapshotIndex: snapshot.currentIndex,
      snapshotDramaId: snapshot.currentItem?.playbackId,
      liveIndex: live.currentIndex,
      liveDramaId: live.currentItem?.playbackId,
      liveHasPlay: live.currentPlay != null,
    );
  }

  bool bindStillCurrent(RecommendFeedState feed, int generation) =>
      _host.isMounted &&
      generation == playGeneration &&
      bindTargetStillCurrent(feed);

  bool engineGenAlive(int generation) =>
      _host.isMounted && generation == playGeneration;

  Future<void> drain() async {
    if (bindRunning) return;
    bindRunning = true;
    try {
      while (_host.isMounted &&
          _host.isPlaybackVisible &&
          queuedBindIndex != null) {
        queuedBindIndex = null;
        final feed = _host.readFeed();
        bindingIndex = feed.currentIndex;
        bindingPlaybackId = feed.currentItem?.playbackId;
        await _host.bindOrPromote(feed);
      }
    } finally {
      bindRunning = false;
      bindingIndex = null;
      bindingPlaybackId = null;
      if (_host.isMounted &&
          _host.isPlaybackVisible &&
          queuedBindIndex != null) {
        unawaited(drain());
      }
    }
  }
}

/// Neighbor-load guard window (iOS active AVPlayer pause during neighbor loadUrl).
class RecommendNeighborLoadGuard {
  DateTime? _until;

  void arm() {
    _until = DateTime.now().add(FeedPlaybackPolicy.neighborLoadGuard);
  }

  bool get isActive {
    final until = _until;
    return until != null && DateTime.now().isBefore(until);
  }

  bool isGuarded({
    required PlaybackEngine? next,
    required PlaybackEngine? prev,
  }) {
    if (_engineBusy(next) || _engineBusy(prev)) return true;
    return isActive;
  }

  bool _engineBusy(PlaybackEngine? engine) {
    if (engine == null) return false;
    return engine.hasPendingLoad || engine.isBuffering || engine.isLoadingMedia;
  }
}

/// Lifecycle mute → unmute serialization for recommend slots.
class RecommendLifecycleAudio {
  int generation = 0;
  Future<void>? muteInFlight;

  int beginMute() => ++generation;

  void trackMute(Future<void> mute, int gen) {
    muteInFlight = mute;
    unawaited(() async {
      try {
        await mute;
      } finally {
        // Clear by identity only — a bumped [generation] must not leave a
        // stale Future stuck in [muteInFlight] after resume abandons mute.
        if (identical(muteInFlight, mute)) {
          muteInFlight = null;
        }
      }
    }());
  }

  int beginResume() => ++generation;

  Future<void> awaitPendingMute() async {
    final pending = muteInFlight;
    if (pending != null) await pending;
  }

  bool isCurrent(int gen) => gen == generation;
}

/// Facade over bind queue, role ring, neighbor markers, and lifecycle audio.
///
/// Async promote / cold bind / prepareSlot stay on [RecommendFeedBody] and run
/// through [RecommendBindHost.bindOrPromote]; this type owns the shared state
/// and path decisions so Body does not re-invent slot math.
class RecommendPlaybackController {
  RecommendPlaybackController(RecommendBindHost host)
    : binds = RecommendBindQueue(host),
      _host = host;

  final RecommendBindHost _host;
  final RecommendBindQueue binds;
  final FeedRoleRing roles = FeedRoleRing();
  final RecommendNeighborMarkers neighbors = RecommendNeighborMarkers();
  final RecommendNeighborLoadGuard neighborLoad = RecommendNeighborLoadGuard();
  final RecommendLifecycleAudio lifecycleAudio = RecommendLifecycleAudio();
  final RecommendManualRetryGuard manualRetry = RecommendManualRetryGuard();

  bool promoteInFlight = false;

  int get playGeneration => binds.playGeneration;
  bool get bindRunning => binds.bindRunning;

  void enqueueBind(RecommendFeedState feed) => binds.enqueue(feed);

  void invalidateStaleBind() => binds.invalidateStaleBind();

  void clearQueueMarkers() => binds.clearQueueMarkers();

  bool bindTargetStillCurrent(RecommendFeedState snapshot) =>
      binds.bindTargetStillCurrent(snapshot);

  bool bindStillCurrent(RecommendFeedState feed, int generation) =>
      binds.bindStillCurrent(feed, generation);

  bool engineGenAlive(int generation) => binds.engineGenAlive(generation);

  bool neighborLoadGuarded({
    required PlaybackEngine? next,
    required PlaybackEngine? prev,
  }) => neighborLoad.isGuarded(next: next, prev: prev);

  void armNeighborLoadGuard() => neighborLoad.arm();

  void relinquishNeighborMarkers() => neighbors.relinquish();

  void resetRoles() => roles.reset();

  void rotateRoles({required bool goingForward}) {
    if (goingForward) {
      roles.rotateForward();
    } else {
      roles.rotateBackward();
    }
    neighbors.relinquish();
  }

  int beginPromoteGeneration() => ++binds.playGeneration;

  int beginColdBindGeneration() => ++binds.playGeneration;

  /// Shared path picker used by [RecommendActivatePipeline] — resume / promote / cold.
  RecommendActivateDecision chooseActivate(RecommendFeedState feed) {
    final item = feed.currentItem;
    if (item == null) {
      return const RecommendActivateDecision.coldBind();
    }
    final active = _host.activeSlot;
    final next = _host.nextSlot;
    final prev = _host.prevSlot;
    final canResume = FeedPlaybackPolicy.canResumeBoundSlot(
      slotPlaybackId: active.playbackId,
      itemPlaybackId: item.playbackId,
      surfaceReady: active.surfaceReady,
      hasEngine: active.engine != null,
      hasLoadedPlay: active.engine?.currentPlay != null,
      loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
        active.engine?.currentPlay,
      ),
    );
    final nextMatches = next.playbackId == item.playbackId;
    final prevMatches = prev.playbackId == item.playbackId;
    return FeedPlaybackPolicy.chooseRecommendActivate(
      canResumeActive: canResume,
      nextMatchesTarget: nextMatches,
      nextDecodedReady:
          nextMatches &&
          FeedPlaybackPolicy.slotHoldsDecodedItem(
            slotPlaybackId: next.playbackId,
            itemPlaybackId: item.playbackId,
            loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
              next.engine?.currentPlay,
            ),
            hasPendingLoad: next.engine?.hasPendingLoad ?? true,
            surfaceReady: next.surfaceReady,
            frameReady: next.frameReady,
          ),
      nextLoadInFlight:
          nextMatches &&
          neighbors.nextReady != null &&
          !neighbors.nextReady!.isCompleted,
      prevMatchesTarget: prevMatches,
      prevDecodedReady:
          prevMatches &&
          FeedPlaybackPolicy.slotHoldsDecodedItem(
            slotPlaybackId: prev.playbackId,
            itemPlaybackId: item.playbackId,
            loadedPlayPlaybackId: RecommendFeedItem.playbackIdOfPlay(
              prev.engine?.currentPlay,
            ),
            hasPendingLoad: prev.engine?.hasPendingLoad ?? true,
            surfaceReady: prev.surfaceReady,
            frameReady: prev.frameReady,
          ),
      prevLoadInFlight:
          prevMatches &&
          neighbors.prevReady != null &&
          !neighbors.prevReady!.isCompleted,
    );
  }
}
