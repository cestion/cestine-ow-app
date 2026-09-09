import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:story_app/src/controller/theater_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/services/cloudfront_cookie_service.dart';

class MockDramaRepo extends Mock implements DramaRepository {}

class MockLocalRepo extends Mock implements StoryLocalRepository {}

ProviderContainer _createContainer({
  required DramaRepository dramaRepo,
  required StoryLocalRepository localRepo,
}) {
  return ProviderContainer(
    overrides: [
      dramaRepositoryProvider.overrideWithValue(dramaRepo),
      localRepositoryProvider.overrideWithValue(localRepo),
      cloudfrontCookieServiceProvider.overrideWithValue(
        CloudFrontCookieService.instance,
      ),
    ],
  );
}

void _stubListPublic(
  MockDramaRepo repo,
  Future<Result<PageDto<DramaListItem>>> Function() answer,
) {
  when(
    () => repo.listPublic(
      mark: any(named: 'mark'),
      tagId: any(named: 'tagId'),
      sort: any(named: 'sort'),
      pageSize: any(named: 'pageSize'),
    ),
  ).thenAnswer((_) => answer());
}

void main() {
  late MockDramaRepo dramaRepo;
  late MockLocalRepo localRepo;

  setUpAll(() {
    registerFallbackValue(const LocaleInfo(languageCode: 'zh'));
    registerFallbackValue(WorkContentType.shortDrama);
    registerFallbackValue(FavoriteTarget.drama);
  });

  setUp(() {
    dramaRepo = MockDramaRepo();
    localRepo = MockLocalRepo();

    // Default mock behavior for repository lifecycles if any
    when(() => dramaRepo.dispose()).thenAnswer((_) async {});
    when(() => localRepo.dispose()).thenAnswer((_) async {});
    when(
      () => dramaRepo.invalidatePublicListCache(
        tagId: any(named: 'tagId'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async {});
  });

  group('TheaterController', () {
    test('refresh() invalidates first-page cache before fetching', () async {
      _stubListPublic(
        dramaRepo,
        () async => Result<PageDto<DramaListItem>>.success(
          const PageDto(
            list: [DramaListItem(id: '1', dramaTitle: 'Drama 1')],
            hasMore: false,
          ),
        ),
      );

      final container = _createContainer(
        dramaRepo: dramaRepo,
        localRepo: localRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(theaterControllerProvider.notifier);
      await controller.refresh();

      verify(
        () => dramaRepo.invalidatePublicListCache(
          tagId: any(named: 'tagId'),
          sort: 'hot',
        ),
      ).called(1);
    });

    test('refresh() fetches page and populates state', () async {
      final items = [
        const DramaListItem(id: '1', dramaTitle: 'Drama 1'),
        const DramaListItem(id: '2', dramaTitle: 'Drama 2'),
      ];
      _stubListPublic(
        dramaRepo,
        () async => Result<PageDto<DramaListItem>>.success(
          PageDto(list: items, hasMore: true, mark: 'mark1'),
        ),
      );

      final container = _createContainer(
        dramaRepo: dramaRepo,
        localRepo: localRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(theaterControllerProvider.notifier);
      await controller.refresh();

      final state = container.read(theaterControllerProvider);
      expect(state.items, hasLength(2));
      expect(state.items.first.dramaTitle, 'Drama 1');
      expect(state.hasMore, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('loadMore() appends next page', () async {
      // First page
      _stubListPublic(
        dramaRepo,
        () async => Result<PageDto<DramaListItem>>.success(
          const PageDto(
            list: [DramaListItem(id: '1', dramaTitle: 'Drama 1')],
            hasMore: true,
            mark: 'mark1',
          ),
        ),
      );

      final container = _createContainer(
        dramaRepo: dramaRepo,
        localRepo: localRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(theaterControllerProvider.notifier);
      await controller.refresh();
      expect(container.read(theaterControllerProvider).items, hasLength(1));

      // Second page
      _stubListPublic(
        dramaRepo,
        () async => Result<PageDto<DramaListItem>>.success(
          const PageDto(
            list: [DramaListItem(id: '2', dramaTitle: 'Drama 2')],
            hasMore: false,
          ),
        ),
      );

      await controller.loadMore();
      final state = container.read(theaterControllerProvider);
      expect(state.items, hasLength(2));
      expect(state.hasMore, isFalse);
    });

    test('loadMore() does not fetch when hasMore is false', () async {
      _stubListPublic(
        dramaRepo,
        () async => Result<PageDto<DramaListItem>>.success(
          const PageDto(list: [], hasMore: false),
        ),
      );

      final container = _createContainer(
        dramaRepo: dramaRepo,
        localRepo: localRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(theaterControllerProvider.notifier);
      await controller.refresh();

      // Reset call count
      reset(dramaRepo);
      when(
        () => dramaRepo.invalidatePublicListCache(
          tagId: any(named: 'tagId'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async {});
      _stubListPublic(
        dramaRepo,
        () async => Result<PageDto<DramaListItem>>.success(
          const PageDto(list: [], hasMore: false),
        ),
      );

      await controller.loadMore();
      verifyNever(
        () => dramaRepo.listPublic(
          mark: any(named: 'mark'),
          tagId: any(named: 'tagId'),
          sort: any(named: 'sort'),
          pageSize: any(named: 'pageSize'),
        ),
      );
    });

    test('refresh() on API failure sets error message', () async {
      _stubListPublic(
        dramaRepo,
        () async => Result<PageDto<DramaListItem>>.failure(
          ApiError.network('Network error'),
        ),
      );

      final container = _createContainer(
        dramaRepo: dramaRepo,
        localRepo: localRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(theaterControllerProvider.notifier);
      await controller.refresh();

      final state = container.read(theaterControllerProvider);
      expect(state.errorMessage, contains('Network error'));
      expect(state.items, isEmpty);
    });

    test(
      'toggleFavorite() performs optimistic update and rollback on failure',
      () async {
        // Setup initial data
        _stubListPublic(
          dramaRepo,
          () async => Result<PageDto<DramaListItem>>.success(
            const PageDto(list: [DramaListItem(id: 'drama1')], hasMore: false),
          ),
        );

        when(() => localRepo.isFavorite('drama1')).thenReturn(false);
        when(
          () => localRepo.toggleWatchlist('drama1'),
        ).thenAnswer((_) async => true);
        when(
          () => dramaRepo.toggleFavorite(
            'drama1',
            type: any(named: 'type'),
            episodeId: any(named: 'episodeId'),
            target: any(named: 'target'),
          ),
        ).thenAnswer((_) async => Result<void>.success(null));

        final container = _createContainer(
          dramaRepo: dramaRepo,
          localRepo: localRepo,
        );
        addTearDown(container.dispose);

        final controller = container.read(theaterControllerProvider.notifier);
        await controller.refresh();

        // Toggle favorite
        final result = await controller.toggleFavorite('drama1');
        expect(result, isTrue);
        verify(() => localRepo.toggleWatchlist('drama1')).called(1);
        verify(
          () => dramaRepo.toggleFavorite(
            'drama1',
            type: any(named: 'type'),
            episodeId: any(named: 'episodeId'),
            target: any(named: 'target'),
          ),
        ).called(1);
      },
    );

    test('toggleFavorite() rolls back on server failure', () async {
      _stubListPublic(
        dramaRepo,
        () async => Result<PageDto<DramaListItem>>.success(
          const PageDto(list: [], hasMore: false),
        ),
      );

      when(() => localRepo.isFavorite('drama1')).thenReturn(false);
      when(
        () => localRepo.toggleWatchlist('drama1'),
      ).thenAnswer((_) async => true);
      when(
        () => dramaRepo.toggleFavorite(
          'drama1',
          type: any(named: 'type'),
          episodeId: any(named: 'episodeId'),
          target: any(named: 'target'),
        ),
      ).thenAnswer(
        (_) async =>
            Result<void>.failure(ApiError.business(500, 'Server error')),
      );

      final container = _createContainer(
        dramaRepo: dramaRepo,
        localRepo: localRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(theaterControllerProvider.notifier);
      await controller.refresh();

      await controller.toggleFavorite('drama1');
      // Verify rollback: toggleWatchlist called twice (optimistic + rollback)
      verify(() => localRepo.toggleWatchlist('drama1')).called(2);
    });

    test('isFavorite() delegates to local repository', () async {
      _stubListPublic(
        dramaRepo,
        () async => Result<PageDto<DramaListItem>>.success(
          const PageDto(list: [], hasMore: false),
        ),
      );
      when(() => localRepo.isFavorite('abc')).thenReturn(true);

      final container = _createContainer(
        dramaRepo: dramaRepo,
        localRepo: localRepo,
      );
      addTearDown(container.dispose);

      final controller = container.read(theaterControllerProvider.notifier);
      await controller.refresh();

      expect(controller.isFavorite('abc'), isTrue);
      verify(() => localRepo.isFavorite('abc')).called(1);
    });

    test('initial state has expected defaults', () {
      const state = TheaterState();
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isEmpty);
      expect(state.items, isEmpty);
      expect(state.hasMore, isTrue);
    });
  });
}
