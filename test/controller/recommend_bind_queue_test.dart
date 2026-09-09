import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_slot.dart';
import 'package:story_app/src/controller/pagination_state.dart';
import 'package:story_app/src/controller/recommend_bind_queue.dart';
import 'package:story_app/src/controller/recommend_feed_state.dart';
import 'package:story_app/src/model/models.dart';

class _FakeBindHost implements RecommendBindHost {
  _FakeBindHost(this.feed);

  RecommendFeedState feed;
  final FeedSlot active = FeedSlot();
  bool mountedFlag = true;
  bool visible = true;
  int bindCalls = 0;
  int clearLatchCalls = 0;
  bool? lastPlaying;

  @override
  bool get isMounted => mountedFlag;

  @override
  bool get isPlaybackVisible => visible;

  @override
  RecommendFeedState readFeed() => feed;

  @override
  FeedSlot get activeSlot => active;

  @override
  FeedSlot get nextSlot => next;

  @override
  FeedSlot get prevSlot => prev;

  final FeedSlot next = FeedSlot();
  final FeedSlot prev = FeedSlot();

  @override
  void clearCoverRevealLatch() => clearLatchCalls++;

  @override
  void setPlaying(bool value) => lastPlaying = value;

  @override
  Future<void> bindOrPromote(RecommendFeedState feed) async {
    bindCalls++;
  }
}

RecommendFeedItem _item(String dramaId) => RecommendFeedItem(
  dramaId: dramaId,
  episodeId: 'ep-$dramaId',
  episodeNo: 1,
  title: dramaId,
  mediaAccessUrl: 'https://cdn.example/mini-drama/streaming/$dramaId.m3u8',
);

CloudFrontSignedCookies _cookies() {
  final expires = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
  return CloudFrontSignedCookies(
    policy: 'p',
    signature: 's',
    keyPairId: 'k',
    expires: expires,
  );
}

DramaPlayResponse _play(String dramaId) => DramaPlayResponse(
  dramaId: dramaId,
  episodeId: 'ep-$dramaId',
  episodeNo: 1,
  mediaAccessUrl: 'https://cdn.example/mini-drama/streaming/$dramaId.m3u8',
  signedCookies: _cookies(),
);

RecommendFeedState _feed({
  required int index,
  required List<String> ids,
}) {
  final items = ids.map(_item).toList();
  return RecommendFeedState(
    pagination: PaginationState(items: items, hasMore: false),
    currentIndex: index,
    currentPlay: _play(ids[index]),
  );
}

void main() {
  group('RecommendBindQueue', () {
    test('enqueue drains once and binds latest feed', () async {
      final host = _FakeBindHost(_feed(index: 0, ids: ['a', 'b']));
      final queue = RecommendBindQueue(host);

      queue.enqueue(host.feed);
      await Future<void>.delayed(Duration.zero);
      expect(queue.bindRunning, isFalse);
      expect(host.bindCalls, 1);
    });

    test('invalidate bumps generation and clears queue', () {
      final host = _FakeBindHost(_feed(index: 0, ids: ['a']));
      host.active.playbackId = 'a';
      final queue = RecommendBindQueue(host);
      queue.queuedBindIndex = 0;
      final gen = queue.playGeneration;

      queue.invalidateStaleBind();

      expect(queue.playGeneration, gen + 1);
      expect(queue.queuedBindIndex, isNull);
      expect(host.clearLatchCalls, 1);
      expect(host.lastPlaying, isFalse);
    });

    test('enqueue invalidates when target drama changes while idle', () {
      final host = _FakeBindHost(_feed(index: 0, ids: ['a', 'b']));
      host.active.playbackId = host.feed.currentItem!.playbackId;
      final queue = RecommendBindQueue(host);
      final gen = queue.playGeneration;

      host.feed = _feed(index: 1, ids: ['a', 'b']);
      queue.enqueue(host.feed);

      expect(queue.playGeneration, greaterThan(gen));
    });

    test('neighbor restore generation bumps with invalidate', () {
      final host = _FakeBindHost(_feed(index: 0, ids: ['a']));
      final queue = RecommendBindQueue(host);
      final restore = queue.neighborRestoreGeneration;
      queue.invalidateStaleBind();
      expect(queue.neighborRestoreGeneration, restore + 1);
    });
  });

  group('RecommendLifecycleAudio', () {
    test('resume generation abandons prior mute tracking', () async {
      final audio = RecommendLifecycleAudio();
      final muteGen = audio.beginMute();
      final mute = Future<void>.delayed(const Duration(milliseconds: 5));
      audio.trackMute(mute, muteGen);

      final resumeGen = audio.beginResume();
      expect(audio.isCurrent(muteGen), isFalse);
      expect(audio.isCurrent(resumeGen), isTrue);
      await mute;
      expect(audio.muteInFlight, isNull);
    });
  });

  group('RecommendNeighborLoadGuard', () {
    test('arm keeps guard active for policy window', () {
      final guard = RecommendNeighborLoadGuard();
      expect(guard.isActive, isFalse);
      guard.arm();
      expect(guard.isActive, isTrue);
      expect(guard.isGuarded(next: null, prev: null), isTrue);
    });
  });
}
