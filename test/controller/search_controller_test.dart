import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/search_controller.dart';
import 'package:story_app/src/controller/search_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/actor_repository.dart';
import 'package:story_app/src/repositories/recommend_repository.dart';
import 'package:story_app/src/repositories/user_repository.dart';

class MockRecommendRepo extends Mock implements RecommendRepository {}

class MockActorRepo extends Mock implements ActorRepository {}

class MockUserRepo extends Mock implements UserRepository {}

class MockLocalRepo extends Mock implements StoryLocalRepository {}

ProviderContainer createContainer({
  RecommendRepository? recommendRepo,
  ActorRepository? actorRepo,
  UserRepository? userRepo,
  StoryLocalRepository? localRepo,
}) {
  return ProviderContainer(
    overrides: [
      if (recommendRepo != null)
        recommendRepositoryProvider.overrideWithValue(recommendRepo),
      if (actorRepo != null)
        actorRepositoryProvider.overrideWithValue(actorRepo),
      if (userRepo != null) userRepositoryProvider.overrideWithValue(userRepo),
      if (localRepo != null)
        localRepositoryProvider.overrideWithValue(localRepo),
    ],
  );
}

void main() {
  late MockRecommendRepo recommendRepo;
  late MockActorRepo actorRepo;
  late MockUserRepo userRepo;
  late MockLocalRepo localRepo;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    recommendRepo = MockRecommendRepo();
    actorRepo = MockActorRepo();
    userRepo = MockUserRepo();
    localRepo = MockLocalRepo();

    when(() => localRepo.getSearchHistory()).thenReturn([]);
    when(() => localRepo.addSearchHistory(any())).thenAnswer((_) async {});
    when(() => localRepo.removeSearchHistory(any())).thenAnswer((_) async {});
    when(() => localRepo.clearSearchHistory()).thenAnswer((_) async {});

    when(
      () => recommendRepo.search(
        keyword: any<String>(named: 'keyword'),
        type: any<String>(named: 'type'),
        size: any<int>(named: 'size'),
        cursor: any<String?>(named: 'cursor'),
      ),
    ).thenAnswer((_) async => Result.success(const RecommendSearchResponse()));

    when(
      () => actorRepo.searchActorCollections(
        keyword: any(named: 'keyword'),
        pageSize: any(named: 'pageSize'),
        mark: any(named: 'mark'),
      ),
    ).thenAnswer(
      (_) async => Result.success(const PageDto(list: [], hasMore: false)),
    );

    when(
      () => userRepo.searchUsers(
        keyword: any<String>(named: 'keyword'),
        pageSize: any<int>(named: 'pageSize'),
        mark: any<String>(named: 'mark'),
      ),
    ).thenAnswer(
      (_) async => Result.success(const PageDto(list: [], hasMore: false)),
    );
  });

  group('SearchController', () {
    test('initial state is empty', () {
      final container = createContainer(
        recommendRepo: recommendRepo,
        actorRepo: actorRepo,
        userRepo: userRepo,
        localRepo: localRepo,
      );
      final state = container.read(searchControllerProvider);
      expect(state.keyword, '');
      expect(state.hasSearched, false);
      expect(state.activeTab, SearchType.dramas);
      container.dispose();
    });

    test('search rejects keyword shorter than 2', () async {
      final container = createContainer(
        recommendRepo: recommendRepo,
        actorRepo: actorRepo,
        userRepo: userRepo,
        localRepo: localRepo,
      );
      final ok = await container
          .read(searchControllerProvider.notifier)
          .search('a');
      expect(ok, isFalse);
      verifyNever(
        () => recommendRepo.search(
          keyword: any<String>(named: 'keyword'),
          type: any<String>(named: 'type'),
          size: any<int>(named: 'size'),
          cursor: any<String?>(named: 'cursor'),
        ),
      );
      container.dispose();
    });

    test('search dramas calls recommend with drama', () async {
      final container = createContainer(
        recommendRepo: recommendRepo,
        actorRepo: actorRepo,
        userRepo: userRepo,
        localRepo: localRepo,
      );
      final notifier = container.read(searchControllerProvider.notifier);
      final ok = await notifier.search('luna');
      expect(ok, isTrue);
      verify(
        () => recommendRepo.search(
          keyword: 'luna',
          type: RecommendSearchType.drama.apiValue,
        ),
      ).called(1);
      verify(() => localRepo.addSearchHistory('luna')).called(1);
      expect(container.read(searchControllerProvider).hasSearched, isTrue);
      container.dispose();
    });

    test(
      'searching the same keyword clears old results then refetches',
      () async {
        final first = Completer<Result<RecommendSearchResponse>>();
        final second = Completer<Result<RecommendSearchResponse>>();
        var call = 0;
        when(
          () => recommendRepo.search(
            keyword: any<String>(named: 'keyword'),
            type: any<String>(named: 'type'),
            size: any<int>(named: 'size'),
            cursor: any<String?>(named: 'cursor'),
          ),
        ).thenAnswer((_) {
          call++;
          return call == 1 ? first.future : second.future;
        });

        final container = createContainer(
          recommendRepo: recommendRepo,
          actorRepo: actorRepo,
          userRepo: userRepo,
          localRepo: localRepo,
        );
        final notifier = container.read(searchControllerProvider.notifier);

        final firstSearch = notifier.search('luna');
        first.complete(
          Result.success(
            const RecommendSearchResponse(
              items: [FeedItem(dramaId: '1', title: 'a')],
            ),
          ),
        );
        await firstSearch;
        expect(container.read(searchControllerProvider).dramas, hasLength(1));

        final secondSearch = notifier.search('luna');
        final mid = container.read(searchControllerProvider);
        expect(mid.dramas, isEmpty);
        expect(mid.isLoading, isTrue);
        expect(mid.hasSearched, isTrue);

        second.complete(
          Result.success(
            const RecommendSearchResponse(
              items: [FeedItem(dramaId: '2', title: 'b')],
            ),
          ),
        );
        await secondSearch;
        final state = container.read(searchControllerProvider);
        expect(state.isLoading, isFalse);
        expect(state.dramas.map((e) => e.dramaId), ['2']);
        verify(
          () => recommendRepo.search(
            keyword: 'luna',
            type: RecommendSearchType.drama.apiValue,
          ),
        ).called(2);
        verify(() => localRepo.addSearchHistory('luna')).called(2);
        container.dispose();
      },
    );

    test('search retries the same keyword after a failed request', () async {
      var call = 0;
      when(
        () => recommendRepo.search(
          keyword: any<String>(named: 'keyword'),
          type: any<String>(named: 'type'),
          size: any<int>(named: 'size'),
          cursor: any<String?>(named: 'cursor'),
        ),
      ).thenAnswer((_) async {
        call++;
        if (call == 1) {
          return Result<RecommendSearchResponse>.failure(
            ApiError.unknown('boom'),
          );
        }
        return Result.success(const RecommendSearchResponse());
      });

      final container = createContainer(
        recommendRepo: recommendRepo,
        actorRepo: actorRepo,
        userRepo: userRepo,
        localRepo: localRepo,
      );
      final notifier = container.read(searchControllerProvider.notifier);
      expect(await notifier.search('luna'), isTrue);
      expect(container.read(searchControllerProvider).lastError, isNotNull);
      expect(await notifier.search('luna'), isTrue);
      expect(container.read(searchControllerProvider).lastError, isNull);
      verify(
        () => recommendRepo.search(
          keyword: 'luna',
          type: RecommendSearchType.drama.apiValue,
        ),
      ).called(2);
      verify(() => localRepo.addSearchHistory('luna')).called(1);
      container.dispose();
    });

    test('selectTab works fetches when cache miss', () async {
      final container = createContainer(
        recommendRepo: recommendRepo,
        actorRepo: actorRepo,
        userRepo: userRepo,
        localRepo: localRepo,
      );
      final notifier = container.read(searchControllerProvider.notifier);
      await notifier.search('luna');
      await notifier.selectTab(SearchType.works);
      verify(
        () => recommendRepo.search(
          keyword: 'luna',
          type: RecommendSearchType.all.apiValue,
        ),
      ).called(1);
      final state = container.read(searchControllerProvider);
      expect(state.activeTab, SearchType.works);
      expect(state.dramasQuery, 'luna');
      container.dispose();
    });

    test('loadMore dramas passes cursor and appends', () async {
      var call = 0;
      when(
        () => recommendRepo.search(
          keyword: any<String>(named: 'keyword'),
          type: any<String>(named: 'type'),
          size: any<int>(named: 'size'),
          cursor: any<String?>(named: 'cursor'),
        ),
      ).thenAnswer((invocation) async {
        call++;
        final cursor = invocation.namedArguments[#cursor] as String?;
        if (call == 1) {
          expect(cursor, isNull);
          return Result.success(
            const RecommendSearchResponse(
              items: [FeedItem(dramaId: '1', title: 'a')],
              cursor: 'c1',
              hasMore: true,
            ),
          );
        }
        expect(cursor, 'c1');
        return Result.success(
          const RecommendSearchResponse(
            items: [FeedItem(dramaId: '2', title: 'b')],
            cursor: 'c2',
          ),
        );
      });

      final container = createContainer(
        recommendRepo: recommendRepo,
        actorRepo: actorRepo,
        userRepo: userRepo,
        localRepo: localRepo,
      );
      final notifier = container.read(searchControllerProvider.notifier);
      await notifier.search('luna');
      var state = container.read(searchControllerProvider);
      expect(state.dramas, hasLength(1));
      expect(state.dramasHasMore, isTrue);
      expect(state.dramasCursor, 'c1');

      await notifier.loadMore();
      state = container.read(searchControllerProvider);
      expect(state.dramas, hasLength(2));
      expect(state.dramas.map((e) => e.dramaId), ['1', '2']);
      expect(state.dramasHasMore, isFalse);
      expect(state.dramasCursor, 'c2');
      container.dispose();
    });

    test('user search uses mark=0 then cursor, stops at -1', () async {
      var call = 0;
      when(
        () => userRepo.searchUsers(
          keyword: any<String>(named: 'keyword'),
          pageSize: any<int>(named: 'pageSize'),
          mark: any<String>(named: 'mark'),
        ),
      ).thenAnswer((invocation) async {
        call++;
        final mark = invocation.namedArguments[#mark] as String?;
        if (call == 1) {
          expect(mark, '0');
          return Result.success(
            const PageDto(
              list: [UserSearchItem(userId: 'u1', nickname: 'a')],
              mark: '123',
              hasMore: true,
            ),
          );
        }
        expect(mark, '123');
        return Result.success(
          const PageDto(
            list: [UserSearchItem(userId: 'u2', nickname: 'b')],
            mark: '-1',
            hasMore: false,
          ),
        );
      });

      final container = createContainer(
        recommendRepo: recommendRepo,
        actorRepo: actorRepo,
        userRepo: userRepo,
        localRepo: localRepo,
      );
      final notifier = container.read(searchControllerProvider.notifier);
      notifier.setActiveTab(SearchType.users);
      await notifier.search('rock');
      var state = container.read(searchControllerProvider);
      expect(state.users.map((e) => e.userId), ['u1']);
      expect(state.usersHasMore, isTrue);
      expect(state.usersMark, '123');

      await notifier.loadMore();
      state = container.read(searchControllerProvider);
      expect(state.users.map((e) => e.userId), ['u1', 'u2']);
      expect(state.usersHasMore, isFalse);
      expect(state.usersMark, '-1');

      await notifier.loadMore();
      verify(
        () => userRepo.searchUsers(
          keyword: 'rock',
          mark: any(named: 'mark'),
        ),
      ).called(2);
      container.dispose();
    });

    test('clear resets results but can keep tab', () async {
      final container = createContainer(
        recommendRepo: recommendRepo,
        actorRepo: actorRepo,
        userRepo: userRepo,
        localRepo: localRepo,
      );
      final notifier = container.read(searchControllerProvider.notifier);
      notifier.setActiveTab(SearchType.actors);
      await notifier.search('luna');
      notifier.clear();
      final state = container.read(searchControllerProvider);
      expect(state.hasSearched, isFalse);
      expect(state.activeTab, SearchType.actors);
      container.dispose();
    });
  });

  group('SearchHistoryController', () {
    test('remove and clearAll', () async {
      when(() => localRepo.getSearchHistory()).thenReturn(['a', 'b']);
      final container = createContainer(localRepo: localRepo);
      final history = container.read(searchHistoryControllerProvider.notifier);
      expect(container.read(searchHistoryControllerProvider).items, ['a', 'b']);

      when(() => localRepo.getSearchHistory()).thenReturn(['b']);
      await history.remove('a');
      verify(() => localRepo.removeSearchHistory('a')).called(1);
      expect(container.read(searchHistoryControllerProvider).items, ['b']);

      final cleared = await history.clearAll();
      expect(cleared, isTrue);
      verify(() => localRepo.clearSearchHistory()).called(1);
      when(() => localRepo.getSearchHistory()).thenReturn([]);
      history.reload();
      expect(container.read(searchHistoryControllerProvider).items, isEmpty);
      container.dispose();
    });
  });
}
