import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_slot.dart';
import 'package:story_app/src/controller/pagination_state.dart';
import 'package:story_app/src/controller/recommend_activate_pipeline.dart';
import 'package:story_app/src/controller/recommend_bind_queue.dart';
import 'package:story_app/src/controller/recommend_feed_state.dart';
import 'package:story_app/src/model/models.dart';

class _Host implements RecommendActivateHost {
  _Host(this.feed) {
    _playback = RecommendPlaybackController(this);
  }

  RecommendFeedState feed;
  late final RecommendPlaybackController _playback;
  final FeedSlot activeSlotImpl = FeedSlot();
  final FeedSlot nextSlotImpl = FeedSlot();
  final FeedSlot prevSlotImpl = FeedSlot();
  final calls = <String>[];

  @override
  RecommendPlaybackController get playback => _playback;

  @override
  bool get isMounted => true;

  @override
  bool get isPlaybackVisible => true;

  @override
  RecommendFeedState readFeed() => feed;

  @override
  FeedSlot get activeSlot => activeSlotImpl;

  @override
  FeedSlot get nextSlot => nextSlotImpl;

  @override
  FeedSlot get prevSlot => prevSlotImpl;

  @override
  FeedSlot get active => activeSlotImpl;

  @override
  FeedSlot get next => nextSlotImpl;

  @override
  FeedSlot get prev => prevSlotImpl;

  @override
  void clearCoverRevealLatch() {}

  @override
  void setPlaying(bool value) {}

  @override
  Future<void> bindOrPromote(RecommendFeedState feed) async {}

  @override
  Future<void> resumeBoundActive({
    required RecommendFeedState feed,
    required String playbackId,
    required bool refreshCookies,
    required bool forceUnmute,
    int? generation,
  }) async {
    calls.add('resume');
  }

  @override
  Future<bool> tryPromoteNeighbor(
    FeedSlot neighbor, {
    required RecommendFeedState feed,
    required Completer<bool>? ready,
    bool alreadyReady = false,
  }) async {
    final tag = identical(neighbor, nextSlotImpl) ? 'next' : 'prev';
    if (alreadyReady) {
      calls.add('swap:$tag');
      return true;
    }
    if (ready != null) {
      calls.add('wait:$tag');
      final ok = await ready.future;
      if (ok) {
        calls.add('swapAfterWait:$tag');
        return true;
      }
    }
    calls.add('miss:$tag');
    return false;
  }

  @override
  Future<void> bindPlayback(RecommendFeedState feed) async {
    calls.add('cold');
  }
}

RecommendFeedItem _item(String id) => RecommendFeedItem(
  dramaId: id,
  episodeId: 'ep-$id',
  episodeNo: 1,
  title: id,
  mediaAccessUrl: 'https://cdn.example/$id.m3u8',
);

DramaPlayResponse _play(String id) => DramaPlayResponse(
  dramaId: id,
  episodeId: 'ep-$id',
  episodeNo: 1,
  mediaAccessUrl: 'https://cdn.example/$id.m3u8',
);

RecommendFeedState _feed(List<String> ids, int index) => RecommendFeedState(
  pagination: PaginationState(items: ids.map(_item).toList(), hasMore: false),
  currentIndex: index,
  currentPlay: _play(ids[index]),
);

void main() {
  group('RecommendActivatePipeline', () {
    test('falls to cold when no neighbor matches', () async {
      final host = _Host(_feed(['a', 'b'], 1));
      final pipeline = RecommendActivatePipeline(host);
      await pipeline.bindOrPromote(host.feed);
      expect(host.calls, ['cold']);
    });

    test('waits in-flight next instead of cold-loading', () async {
      final host = _Host(_feed(['a', 'b'], 1));
      final targetId = host.feed.currentItem!.playbackId;
      host.nextSlotImpl.playbackId = targetId;
      // Incomplete completer → chooseAdjacentActivate.waitInFlight
      final inflight = Completer<bool>();
      host.playback.neighbors.nextReady = inflight;

      final pipeline = RecommendActivatePipeline(host);
      final fut = pipeline.bindOrPromote(host.feed);
      await Future<void>.delayed(Duration.zero);
      expect(host.calls, ['wait:next']);
      expect(host.calls, isNot(contains('cold')));

      inflight.complete(true);
      await fut;
      expect(host.calls, ['wait:next', 'swapAfterWait:next']);
      expect(host.calls, isNot(contains('cold')));
    });

    test('primary wait miss still tries secondary then cold', () async {
      final host = _Host(_feed(['a', 'b'], 1));
      final targetId = host.feed.currentItem!.playbackId;
      host.nextSlotImpl.playbackId = targetId;
      final inflight = Completer<bool>();
      host.playback.neighbors.nextReady = inflight;

      final pipeline = RecommendActivatePipeline(host);
      final fut = pipeline.bindOrPromote(host.feed);
      await Future<void>.delayed(Duration.zero);
      inflight.complete(false);
      await fut;
      expect(host.calls, contains('wait:next'));
      expect(host.calls, contains('miss:next'));
      // Secondary prev does not match → cold
      expect(host.calls.last, 'cold');
    });
  });
}
