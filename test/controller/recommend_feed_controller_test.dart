import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/recommend_feed_controller.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/story_constants.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/repositories/recommend_repository.dart';

class MockRecommendRepo extends Mock implements RecommendRepository {}

class MockDramaRepo extends Mock implements DramaRepository {}

class _GuestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(ready: true);
}

class _LocaleZh extends LocaleCodeNotifier {
  @override
  String build() => 'zh';
}

RecommendFeedItem _item(
  String dramaId, {
  String? title,
  String? creatorId,
  String? creatorAvatar,
  String? contentType,
}) => RecommendFeedItem(
  dramaId: dramaId,
  episodeId: 'ep-$dramaId',
  episodeNo: 1,
  title: title ?? dramaId,
  creatorId: creatorId,
  creatorAvatar: creatorAvatar,
  contentType: contentType,
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

void main() {
  late MockRecommendRepo recommendRepo;
  late MockDramaRepo dramaRepo;

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        recommendRepositoryProvider.overrideWithValue(recommendRepo),
        dramaRepositoryProvider.overrideWithValue(dramaRepo),
        authControllerProvider.overrideWith(_GuestAuthController.new),
        localeCodeProvider.overrideWith(_LocaleZh.new),
      ],
    );
    // autoDispose: keep alive while async hydrate / activateIndex completes.
    final sub = container.listen(
      recommendFeedControllerProvider,
      (_, _) {},
    );
    addTearDown(sub.close);
    return container;
  }

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    recommendRepo = MockRecommendRepo();
    dramaRepo = MockDramaRepo();
    when(
      () => dramaRepo.peekPrefetchedEpisode(any(), any()),
    ).thenAnswer((_) async => null);
    when(() => dramaRepo.getDetail(any())).thenAnswer(
      (invocation) async => Result.success(
        DramaDetail(id: invocation.positionalArguments[0] as String),
      ),
    );
    when(() => dramaRepo.dispose()).thenAnswer((_) async {});
    when(
      () => recommendRepo.peekCachedFirstPageSync(subject: any(named: 'subject')),
    ).thenReturn(null);
    when(
      () => recommendRepo.peekCachedFirstPage(subject: any(named: 'subject')),
    ).thenAnswer((_) async => null);
  });

  void stubFeedPages({
    required List<RecommendFeedItem> first,
    List<RecommendFeedItem> second = const [],
    bool firstHasMore = true,
  }) {
    when(
      () => recommendRepo.fetchFeed(
        cursor: any(named: 'cursor'),
        subject: any(named: 'subject'),
      ),
    ).thenAnswer((invocation) async {
      final cursor = invocation.namedArguments[#cursor] as String?;
      if (cursor == null || cursor.isEmpty) {
        return Result.success(
          PageDto(
            list: first,
            hasMore: firstHasMore,
            mark: firstHasMore ? 'next' : null,
          ),
        );
      }
      return Result.success(PageDto(list: second, hasMore: false));
    });
  }

  void stubSignedPlay() {
    when(() => dramaRepo.getEpisodeDetail(any(), any())).thenAnswer((
      invocation,
    ) async {
      final dramaId = invocation.positionalArguments[0] as String;
      return Result.success(_play(dramaId));
    });
  }

  test(
    'loadMoreIfAtEnd only fetches when the playhead is on the last card',
    () async {
      stubFeedPages(first: [_item('d1'), _item('d2')], second: [_item('d3')]);
      stubSignedPlay();

      final container = createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        recommendFeedControllerProvider.notifier,
      );

      await controller.refresh();
      expect(
        container.read(recommendFeedControllerProvider).items,
        hasLength(2),
      );

      expect(await controller.loadMoreIfAtEnd(index: 0), isFalse);
      expect(
        container.read(recommendFeedControllerProvider).items,
        hasLength(2),
      );

      final appended = await controller.loadMoreIfAtEnd(index: 1);
      expect(appended, isTrue);
      expect(
        container.read(recommendFeedControllerProvider).items,
        hasLength(3),
      );
    },
  );

  test(
    'onPageChanged is a no-op when the same card already has play',
    () async {
      stubFeedPages(first: [_item('d1'), _item('d2')], firstHasMore: false);
      stubSignedPlay();

      final container = createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        recommendFeedControllerProvider.notifier,
      );

      await controller.refresh();
      await controller.activateIndex(0);
      clearInteractions(dramaRepo);
      await controller.onPageChanged(0);
      verifyNever(() => dramaRepo.getEpisodeDetail(any(), any()));
    },
  );

  test(
    'a newer activateIndex wins over a slower previous episode-detail',
    () async {
      stubFeedPages(first: [_item('d1'), _item('d2')], firstHasMore: false);

      final d1Started = Completer<void>();
      final d1Gate = Completer<void>();
      when(() => dramaRepo.getEpisodeDetail(any(), any())).thenAnswer((
        invocation,
      ) async {
        final dramaId = invocation.positionalArguments[0] as String;
        if (dramaId == 'd1') {
          if (!d1Started.isCompleted) d1Started.complete();
          await d1Gate.future;
          return Result.success(_play('d1'));
        }
        return Result.success(_play('d2'));
      });

      final container = createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        recommendFeedControllerProvider.notifier,
      );

      final refreshFuture = controller.refresh();
      await d1Started.future;
      await controller.onPageChanged(1);

      final afterSwipe = container.read(recommendFeedControllerProvider);
      expect(afterSwipe.currentIndex, 1);
      expect(afterSwipe.currentPlay?.dramaId, 'd2');

      d1Gate.complete();
      await refreshFuture;

      final settled = container.read(recommendFeedControllerProvider);
      expect(settled.currentIndex, 1);
      expect(settled.currentPlay?.dramaId, 'd2');
    },
  );

  test(
    'activateIndex skips drama detail when card chrome is complete',
    () async {
      stubFeedPages(
        first: [
          _item(
            'd1',
            creatorId: 'creator-1',
            creatorAvatar: 'https://cdn.example/avatar.png',
          ),
        ],
        firstHasMore: false,
      );
      stubSignedPlay();

      final container = createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        recommendFeedControllerProvider.notifier,
      );

      await controller.refresh();
      expect(
        container.read(recommendFeedControllerProvider).items,
        hasLength(1),
      );
      await pumpEventQueue();
      await pumpEventQueue();

      verifyNever(() => dramaRepo.getDetail(any()));
    },
  );

  test(
    'activateIndex hydrates sparse creator with a single drama detail',
    () async {
      stubFeedPages(first: [_item('d1')], firstHasMore: false);
      stubSignedPlay();
      when(() => dramaRepo.getDetail('d1')).thenAnswer(
        (_) async => Result.success(
          const DramaDetail(
            id: 'd1',
            userId: 'creator-1',
            creatorName: 'Creator One',
            creatorAvatarUrl: 'https://cdn.example/creator.png',
          ),
        ),
      );

      final container = createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        recommendFeedControllerProvider.notifier,
      );

      await controller.refresh();
      expect(
        container.read(recommendFeedControllerProvider).items,
        hasLength(1),
      );
      await pumpEventQueue();
      await pumpEventQueue();

      verify(() => dramaRepo.getDetail('d1')).called(1);
      final item = container.read(recommendFeedControllerProvider).items[0];
      expect(item.creatorId, 'creator-1');
      expect(item.creatorName, 'Creator One');
      expect(item.creatorAvatar, 'https://cdn.example/creator.png');
    },
  );

  test('transcode failure 121019 leaves the card unbound', () async {
    stubFeedPages(first: [_item('d1')], firstHasMore: false);
    when(() => dramaRepo.getEpisodeDetail(any(), any())).thenAnswer(
      (_) async => Result.failure(
        const BusinessError(StoryConstants.episodeTranscodeFailedCode, '转码失败'),
      ),
    );

    final container = createContainer();
    addTearDown(container.dispose);
    final controller = container.read(recommendFeedControllerProvider.notifier);

    await controller.refresh();
    await controller.activateIndex(0);
    final state = container.read(recommendFeedControllerProvider);

    expect(state.currentPlay, isNull);
    expect(state.isPlayLoading, isFalse);
    expect(
      state.lastError,
      isA<BusinessError>().having(
        (e) => e.code,
        'code',
        StoryConstants.episodeTranscodeFailedCode,
      ),
    );
    expect(controller.isUntranscoded(_item('d1')), isTrue);
  });

  test('ensureLoaded uses sync cache peek on cold start', () async {
    final cached = PageDto<RecommendFeedItem>(
      list: [_item('d1', title: 'Cached')],
      hasMore: true,
      mark: 'next',
    );
    when(
      () => recommendRepo.peekCachedFirstPageSync(subject: any(named: 'subject')),
    ).thenReturn(cached);
    stubFeedPages(first: [_item('d1', title: 'Fresh')], firstHasMore: false);
    stubSignedPlay();

    final container = createContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      recommendFeedControllerProvider.notifier,
    );

    await controller.ensureLoaded();

    final state = container.read(recommendFeedControllerProvider);
    expect(state.items, isNotEmpty);
    verify(
      () => recommendRepo.peekCachedFirstPageSync(subject: any(named: 'subject')),
    ).called(1);
    verifyNever(
      () => recommendRepo.peekCachedFirstPage(subject: any(named: 'subject')),
    );
  });

  test('ensureLoaded SWR revalidate activates the first card once', () async {
    final cached = PageDto<RecommendFeedItem>(
      list: [_item('d1', title: 'Cached')],
      hasMore: true,
      mark: 'next',
    );
    when(
      () => recommendRepo.peekCachedFirstPageSync(subject: any(named: 'subject')),
    ).thenReturn(cached);
    stubFeedPages(first: [_item('d1', title: 'Fresh')], firstHasMore: false);
    stubSignedPlay();

    final container = createContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      recommendFeedControllerProvider.notifier,
    );

    await controller.ensureLoaded();

    verify(() => dramaRepo.getEpisodeDetail('d1', any())).called(1);
    verify(
      () => recommendRepo.fetchFeed(
        cursor: any(named: 'cursor'),
        subject: any(named: 'subject'),
      ),
    ).called(1);
  });
}
