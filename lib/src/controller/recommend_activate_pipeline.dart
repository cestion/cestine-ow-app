import 'dart:async';

import 'feed_activate_orchestrator.dart';
import 'feed_playback_policy.dart';
import 'feed_slot.dart';
import 'recommend_bind_queue.dart';
import 'recommend_feed_state.dart';

/// Host hooks for [RecommendActivatePipeline].
///
/// Keeps Platform View / setState / Riverpod in the widget; the pipeline owns
/// resume → promote → cold orchestration (parallel to short-drama
/// [FeedActivationPipeline], not merged with it).
abstract interface class RecommendActivateHost implements RecommendBindHost {
  RecommendPlaybackController get playback;

  FeedSlot get active;
  FeedSlot get next;
  FeedSlot get prev;

  Future<void> resumeBoundActive({
    required RecommendFeedState feed,
    required String playbackId,
    required bool refreshCookies,
    required bool forceUnmute,
    int? generation,
  });

  Future<bool> tryPromoteNeighbor(
    FeedSlot neighbor, {
    required RecommendFeedState feed,
    required Completer<bool>? ready,
    bool alreadyReady = false,
  });

  Future<void> bindPlayback(RecommendFeedState feed);
}

/// Recommend activate orchestration: soft-resume, neighbor promote, cold bind.
class RecommendActivatePipeline implements RecommendActivateOrchestrator {
  RecommendActivatePipeline(this._host);

  final RecommendActivateHost _host;

  RecommendPlaybackController get _playback => _host.playback;

  @override
  Future<void> bindOrPromote(RecommendFeedState target, {bool force = false}) =>
      bindOrPromoteFromState(target);

  Future<void> bindOrPromoteFromState(RecommendFeedState feed) async {
    final item = feed.currentItem;
    if (item == null || feed.currentPlay == null) return;
    if (!_playback.bindTargetStillCurrent(feed)) return;

    final decision = _playback.chooseActivate(feed);
    if (decision.isResume) {
      await _host.resumeBoundActive(
        feed: feed,
        playbackId: item.playbackId,
        refreshCookies: true,
        forceUnmute: false,
      );
      return;
    }

    if (decision.isPromote) {
      final forward = decision.forward!;
      final primary = forward ? _host.next : _host.prev;
      final primaryReady = forward
          ? _playback.neighbors.nextReady
          : _playback.neighbors.prevReady;
      if (await _host.tryPromoteNeighbor(
        primary,
        feed: feed,
        ready: primaryReady,
        alreadyReady: decision.adjacent == AdjacentActivateChoice.swap,
      )) {
        return;
      }
      if (!_playback.bindTargetStillCurrent(feed)) return;

      // Same as the legacy next-then-prev scan: primary miss still tries the
      // opposite neighbor before cold-loading.
      final secondary = forward ? _host.prev : _host.next;
      final secondaryReady = forward
          ? _playback.neighbors.prevReady
          : _playback.neighbors.nextReady;
      if (await _host.tryPromoteNeighbor(
        secondary,
        feed: feed,
        ready: secondaryReady,
      )) {
        return;
      }
      if (!_playback.bindTargetStillCurrent(feed)) return;
    }

    await _host.bindPlayback(feed);
  }
}
