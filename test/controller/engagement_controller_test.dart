import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/engagement_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/story_constants.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/repositories/follow_repository.dart';
import 'package:story_app/src/services/drama_engagement_service.dart';

class MockDramaRepo extends Mock implements DramaRepository {}

class MockLocalRepo extends Mock implements StoryLocalRepository {}

class MockEngagementService extends Mock implements DramaEngagementService {}

class MockFollowRepo extends Mock implements FollowRepository {}

class _LoggedInAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
    ready: true,
    isLoggedIn: true,
    profile: UserProfile(userId: 'me'),
  );
}

void main() {
  const dramaId = 'drama-1';
  const episodeKey = EpisodeEngagementKey(
    dramaId: dramaId,
    episodeId: 'episode-1',
    episodeNo: 3,
  );

  late MockDramaRepo dramaRepo;
  late MockLocalRepo localRepo;
  late MockEngagementService engagementService;
  late MockFollowRepo followRepo;

  setUpAll(() {
    registerFallbackValue(WorkContentType.shortDrama);
    registerFallbackValue(FavoriteTarget.drama);
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        dramaRepositoryProvider.overrideWithValue(dramaRepo),
        localRepositoryProvider.overrideWithValue(localRepo),
        dramaEngagementServiceProvider.overrideWithValue(engagementService),
      ],
    );
  }

  /// Container with block pre-check dependencies (auth + follow relation).
  ProviderContainer createBlockAwareContainer() {
    return ProviderContainer(
      overrides: [
        dramaRepositoryProvider.overrideWithValue(dramaRepo),
        localRepositoryProvider.overrideWithValue(localRepo),
        dramaEngagementServiceProvider.overrideWithValue(engagementService),
        followRepositoryProvider.overrideWithValue(followRepo),
        authControllerProvider.overrideWith(_LoggedInAuthController.new),
      ],
    );
  }

  setUp(() {
    dramaRepo = MockDramaRepo();
    localRepo = MockLocalRepo();
    engagementService = MockEngagementService();
    followRepo = MockFollowRepo();
    when(() => localRepo.isFavorite(any())).thenReturn(false);
    when(
      () => followRepo.getBlockRelation(any()),
    ).thenAnswer((_) async => Result.success(BlockRelation.none));
    when(
      () => dramaRepo.patchCachedEpisodePlay(
        any(),
        any(),
        likedByMe: any(named: 'likedByMe'),
        likeCount: any(named: 'likeCount'),
        favoritedByMe: any(named: 'favoritedByMe'),
        commentCountDelta: any(named: 'commentCountDelta'),
      ),
    ).thenAnswer((_) async {});
  });

  group('DramaEngagementController', () {
    test('seed fills only missing fields', () {
      final container = createContainer();
      addTearDown(container.dispose);
      container.listen(dramaEngagementProvider(dramaId), (_, _) {});
      final notifier = container.read(
        dramaEngagementProvider(dramaId).notifier,
      );

      notifier.seed(favoritedByMe: true, favoriteCount: 10);
      notifier.seed(favoritedByMe: false, favoriteCount: 99);

      final state = container.read(dramaEngagementProvider(dramaId));
      expect(state.favoritedByMe, isTrue);
      expect(state.favoriteCount, 10);
    });

    test('applyServer overwrites and syncs watchlist removal', () async {
      when(() => localRepo.isFavorite(dramaId)).thenReturn(true);
      when(
        () => localRepo.removeFromWatchlist(dramaId),
      ).thenAnswer((_) async {});
      final container = createContainer();
      addTearDown(container.dispose);
      container.listen(dramaEngagementProvider(dramaId), (_, _) {});
      final notifier = container.read(
        dramaEngagementProvider(dramaId).notifier,
      );

      // Local hint says favorited; server says no — server wins.
      expect(
        container.read(dramaEngagementProvider(dramaId)).favoritedByMe,
        isTrue,
      );
      notifier.applyServer(favoritedByMe: false, favoriteCount: 5);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(dramaEngagementProvider(dramaId));
      expect(state.favoritedByMe, isFalse);
      expect(state.favoriteCount, 5);
      verify(() => localRepo.removeFromWatchlist(dramaId)).called(1);
    });

    test('toggleFavorite applies optimistic update and commits', () async {
      when(
        () => engagementService.toggleDramaFavorite(dramaId),
      ).thenAnswer((_) async => Result<void>.success(null));
      final container = createContainer();
      addTearDown(container.dispose);
      container.listen(dramaEngagementProvider(dramaId), (_, _) {});
      final notifier = container.read(
        dramaEngagementProvider(dramaId).notifier,
      );
      notifier.seed(favoritedByMe: false, favoriteCount: 7);

      final result = await notifier.toggleFavorite(episodeNo: 1);

      expect(result, isNotNull);
      expect(result!.isSuccess, isTrue);
      final state = container.read(dramaEngagementProvider(dramaId));
      expect(state.favoritedByMe, isTrue);
      expect(state.favoriteCount, 8);
      expect(state.isMutating, isFalse);
    });

    test('toggleFavorite rolls back on failure', () async {
      when(
        () => engagementService.toggleDramaFavorite(dramaId),
      ).thenAnswer((_) async => Result<void>.failure(ApiError.network('down')));
      when(
        () => engagementService.revertWatchlistToggle(dramaId),
      ).thenAnswer((_) async => true);
      final container = createContainer();
      addTearDown(container.dispose);
      container.listen(dramaEngagementProvider(dramaId), (_, _) {});
      final notifier = container.read(
        dramaEngagementProvider(dramaId).notifier,
      );
      notifier.seed(favoritedByMe: true, favoriteCount: 8);

      final result = await notifier.toggleFavorite(episodeNo: 1);

      expect(result!.isFailure, isTrue);
      final state = container.read(dramaEngagementProvider(dramaId));
      expect(state.favoritedByMe, isTrue);
      expect(state.favoriteCount, 8);
      verify(() => engagementService.revertWatchlistToggle(dramaId)).called(1);
    });

    test('toggleFavorite is guarded against double taps', () async {
      when(() => engagementService.toggleDramaFavorite(dramaId)).thenAnswer((
        _,
      ) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return Result<void>.success(null);
      });
      final container = createContainer();
      addTearDown(container.dispose);
      container.listen(dramaEngagementProvider(dramaId), (_, _) {});
      final notifier = container.read(
        dramaEngagementProvider(dramaId).notifier,
      );
      notifier.seed(favoritedByMe: false, favoriteCount: 0);

      final first = notifier.toggleFavorite(episodeNo: 1);
      final second = await notifier.toggleFavorite(episodeNo: 1);

      expect(second, isNull);
      expect((await first)!.isSuccess, isTrue);
      verify(() => engagementService.toggleDramaFavorite(dramaId)).called(1);
    });

    test(
      'toggleFavorite blocked when I blocked the drama author (blockedByMe)',
      () async {
        when(() => followRepo.getBlockRelation('author-1')).thenAnswer(
          (_) async => Result.success(const BlockRelation(blockedByMe: true)),
        );
        final container = createBlockAwareContainer();
        addTearDown(container.dispose);
        container.listen(dramaEngagementProvider(dramaId), (_, _) {});
        final notifier = container.read(
          dramaEngagementProvider(dramaId).notifier,
        );
        notifier.seed(favoritedByMe: false, favoriteCount: 7);

        final result = await notifier.toggleFavorite(authorUserId: 'author-1');

        expect(result!.isFailure, isTrue);
        expect(
          result.errorOrNull!.l10nArgs['message'],
          FavoriteBlockErrorMessages.blockedByMe,
        );
        final state = container.read(dramaEngagementProvider(dramaId));
        expect(state.favoritedByMe, isFalse);
        expect(state.favoriteCount, 7);
        verifyNever(() => engagementService.toggleDramaFavorite(dramaId));
      },
    );

    test(
      'toggleFavorite blocked when the author blocked me (blockedByTarget)',
      () async {
        when(() => followRepo.getBlockRelation('author-1')).thenAnswer(
          (_) async =>
              Result.success(const BlockRelation(blockedByTarget: true)),
        );
        final container = createBlockAwareContainer();
        addTearDown(container.dispose);
        container.listen(dramaEngagementProvider(dramaId), (_, _) {});
        final notifier = container.read(
          dramaEngagementProvider(dramaId).notifier,
        );
        notifier.seed(favoritedByMe: false, favoriteCount: 7);

        final result = await notifier.toggleFavorite(authorUserId: 'author-1');

        expect(result!.isFailure, isTrue);
        expect(
          result.errorOrNull!.l10nArgs['message'],
          FavoriteBlockErrorMessages.blockedByTarget,
        );
        verifyNever(() => engagementService.toggleDramaFavorite(dramaId));
      },
    );

    test(
      'toggleFavorite unfavoriting is not blocked by a block relation',
      () async {
        when(() => followRepo.getBlockRelation('author-1')).thenAnswer(
          (_) async =>
              Result.success(const BlockRelation(blockedByTarget: true)),
        );
        when(
          () => engagementService.toggleDramaFavorite(dramaId),
        ).thenAnswer((_) async => Result<void>.success(null));
        final container = createBlockAwareContainer();
        addTearDown(container.dispose);
        container.listen(dramaEngagementProvider(dramaId), (_, _) {});
        final notifier = container.read(
          dramaEngagementProvider(dramaId).notifier,
        );
        notifier.seed(favoritedByMe: true, favoriteCount: 8);

        final result = await notifier.toggleFavorite(authorUserId: 'author-1');

        expect(result!.isSuccess, isTrue);
        final state = container.read(dramaEngagementProvider(dramaId));
        expect(state.favoritedByMe, isFalse);
        expect(state.favoriteCount, 7);
      },
    );

    test(
      'toggleFavorite proceeds when no block relation with the author',
      () async {
        when(
          () => engagementService.toggleDramaFavorite(dramaId),
        ).thenAnswer((_) async => Result<void>.success(null));
        final container = createBlockAwareContainer();
        addTearDown(container.dispose);
        container.listen(dramaEngagementProvider(dramaId), (_, _) {});
        final notifier = container.read(
          dramaEngagementProvider(dramaId).notifier,
        );
        notifier.seed(favoritedByMe: false, favoriteCount: 7);

        final result = await notifier.toggleFavorite(authorUserId: 'author-1');

        expect(result!.isSuccess, isTrue);
        verify(() => followRepo.getBlockRelation('author-1')).called(1);
        verify(() => engagementService.toggleDramaFavorite(dramaId)).called(1);
      },
    );

    test(
      'submitRating commits and refreshes authoritative avgRating',
      () async {
        const review = DramaReview(
          id: 'r1',
          userId: 'u1',
          dramaId: dramaId,
          rating: 4,
        );
        when(
          () => dramaRepo.submitReview(
            dramaId: dramaId,
            rating: 4,
            reviewText: any(named: 'reviewText'),
          ),
        ).thenAnswer((_) async => Result<DramaReview>.success(review));
        when(() => dramaRepo.getDetail(dramaId, forceRefresh: true)).thenAnswer(
          (_) async => Result<DramaDetail>.success(
            const DramaDetail(id: dramaId, avgRating: 4.3),
          ),
        );
        final container = createContainer();
        addTearDown(container.dispose);
        container.listen(dramaEngagementProvider(dramaId), (_, _) {});
        final notifier = container.read(
          dramaEngagementProvider(dramaId).notifier,
        );
        notifier.seed(avgRating: 3.8);

        final result = await notifier.submitRating(4);

        expect(result!.isSuccess, isTrue);
        final state = container.read(dramaEngagementProvider(dramaId));
        expect(state.myRating, 4);
        expect(state.avgRating, 4.3);
        expect(state.isMutating, isFalse);
        verify(
          () => dramaRepo.getDetail(dramaId, forceRefresh: true),
        ).called(1);
      },
    );

    test('submitRating rolls back myRating on failure', () async {
      when(
        () => dramaRepo.submitReview(
          dramaId: dramaId,
          rating: 2,
          reviewText: any(named: 'reviewText'),
        ),
      ).thenAnswer(
        (_) async => Result<DramaReview>.failure(ApiError.network('down')),
      );
      final container = createContainer();
      addTearDown(container.dispose);
      container.listen(dramaEngagementProvider(dramaId), (_, _) {});
      final notifier = container.read(
        dramaEngagementProvider(dramaId).notifier,
      );
      notifier.seed(myRating: 5, avgRating: 4.6);

      final result = await notifier.submitRating(2);

      expect(result!.isFailure, isTrue);
      final state = container.read(dramaEngagementProvider(dramaId));
      expect(state.myRating, 5);
      expect(state.avgRating, 4.6);
      expect(state.isMutating, isFalse);
      verifyNever(() => dramaRepo.getDetail(dramaId, forceRefresh: true));
    });

    test(
      'submitRating blocked when I blocked the drama author (blockedByMe)',
      () async {
        when(() => followRepo.getBlockRelation('author-1')).thenAnswer(
          (_) async => Result.success(const BlockRelation(blockedByMe: true)),
        );
        final container = createBlockAwareContainer();
        addTearDown(container.dispose);
        container.listen(dramaEngagementProvider(dramaId), (_, _) {});
        final notifier = container.read(
          dramaEngagementProvider(dramaId).notifier,
        );
        notifier.seed(avgRating: 3.8);

        final result = await notifier.submitRating(4, authorUserId: 'author-1');

        expect(result!.isFailure, isTrue);
        expect(
          result.errorOrNull!.l10nArgs['message'],
          RatingBlockErrorMessages.blockedByMe,
        );
        final state = container.read(dramaEngagementProvider(dramaId));
        expect(state.myRating, isNull);
        expect(state.isMutating, isFalse);
        verifyNever(
          () => dramaRepo.submitReview(
            dramaId: dramaId,
            rating: any(named: 'rating'),
            reviewText: any(named: 'reviewText'),
          ),
        );
      },
    );

    test(
      'submitRating blocked when the author blocked me (blockedByTarget)',
      () async {
        when(() => followRepo.getBlockRelation('author-1')).thenAnswer(
          (_) async =>
              Result.success(const BlockRelation(blockedByTarget: true)),
        );
        final container = createBlockAwareContainer();
        addTearDown(container.dispose);
        container.listen(dramaEngagementProvider(dramaId), (_, _) {});
        final notifier = container.read(
          dramaEngagementProvider(dramaId).notifier,
        );
        notifier.seed(avgRating: 3.8);

        final result = await notifier.submitRating(4, authorUserId: 'author-1');

        expect(result!.isFailure, isTrue);
        expect(
          result.errorOrNull!.l10nArgs['message'],
          RatingBlockErrorMessages.blockedByTarget,
        );
        verifyNever(
          () => dramaRepo.submitReview(
            dramaId: dramaId,
            rating: any(named: 'rating'),
            reviewText: any(named: 'reviewText'),
          ),
        );
      },
    );

    test(
      'submitRating proceeds when no block relation with the author',
      () async {
        const review = DramaReview(
          id: 'r1',
          userId: 'u1',
          dramaId: dramaId,
          rating: 4,
        );
        when(
          () => dramaRepo.submitReview(
            dramaId: dramaId,
            rating: 4,
            reviewText: any(named: 'reviewText'),
          ),
        ).thenAnswer((_) async => Result<DramaReview>.success(review));
        when(() => dramaRepo.getDetail(dramaId, forceRefresh: true)).thenAnswer(
          (_) async => Result<DramaDetail>.success(
            const DramaDetail(id: dramaId, avgRating: 4.3),
          ),
        );
        final container = createBlockAwareContainer();
        addTearDown(container.dispose);
        container.listen(dramaEngagementProvider(dramaId), (_, _) {});
        final notifier = container.read(
          dramaEngagementProvider(dramaId).notifier,
        );
        notifier.seed(avgRating: 3.8);

        final result = await notifier.submitRating(4, authorUserId: 'author-1');

        expect(result!.isSuccess, isTrue);
        verify(() => followRepo.getBlockRelation('author-1')).called(1);
        verify(
          () => dramaRepo.submitReview(
            dramaId: dramaId,
            rating: 4,
            reviewText: any(named: 'reviewText'),
          ),
        ).called(1);
        final state = container.read(dramaEngagementProvider(dramaId));
        expect(state.myRating, 4);
        expect(state.avgRating, 4.3);
      },
    );
  });

  group('EpisodeEngagementController', () {
    test(
      'toggleWorkFavorite treats null count as 0 so first favorite shows 1',
      () async {
        when(
          () => engagementService.toggleWorkFavorite(
            dramaId: dramaId,
            episodeId: 'episode-1',
            episodeNo: any(named: 'episodeNo'),
            favoritedByMe: any(named: 'favoritedByMe'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) async => Result<void>.success(null));
        final container = createContainer();
        addTearDown(container.dispose);
        container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
        final notifier = container.read(
          episodeEngagementProvider(episodeKey).notifier,
        );
        notifier.seed(favoritedByMe: false);

        final result = await notifier.toggleWorkFavorite();

        expect(result!.isSuccess, isTrue);
        final state = container.read(episodeEngagementProvider(episodeKey));
        expect(state.favoritedByMe, isTrue);
        expect(state.favoriteCount, 1);
      },
    );

    test(
      'toggleLike applies optimistic update and rolls back on failure',
      () async {
        when(
          () => engagementService.toggleEpisodeLike(
            dramaId: dramaId,
            episodeId: 'episode-1',
            episodeNo: any(named: 'episodeNo'),
            likedByMe: any(named: 'likedByMe'),
            likeCount: any(named: 'likeCount'),
            type: any(named: 'type'),
          ),
        ).thenAnswer(
          (_) async => Result<void>.failure(ApiError.network('down')),
        );
        final container = createContainer();
        addTearDown(container.dispose);
        container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
        final notifier = container.read(
          episodeEngagementProvider(episodeKey).notifier,
        );
        notifier.seed(likedByMe: false, likeCount: 4, commentCount: 2);

        final result = await notifier.toggleLike();

        expect(result!.isFailure, isTrue);
        final state = container.read(episodeEngagementProvider(episodeKey));
        expect(state.likedByMe, isFalse);
        expect(state.likeCount, 4);
      },
    );

    test('onCommentPosted bumps count and patches episode-play cache', () {
      final container = createContainer();
      addTearDown(container.dispose);
      container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
      final notifier = container.read(
        episodeEngagementProvider(episodeKey).notifier,
      );
      notifier.seed(commentCount: 42);

      notifier.onCommentPosted();

      expect(
        container.read(episodeEngagementProvider(episodeKey)).commentCount,
        43,
      );
      verify(
        () =>
            dramaRepo.patchCachedEpisodePlay(dramaId, 3, commentCountDelta: 1),
      ).called(1);
    });

    test(
      'applyServer arriving mid-mutation reconciles after a failed toggle',
      () async {
        when(
          () => engagementService.toggleEpisodeLike(
            dramaId: dramaId,
            episodeId: 'episode-1',
            episodeNo: any(named: 'episodeNo'),
            likedByMe: any(named: 'likedByMe'),
            likeCount: any(named: 'likeCount'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return Result<void>.failure(ApiError.network('down'));
        });
        final container = createContainer();
        addTearDown(container.dispose);
        container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
        final notifier = container.read(
          episodeEngagementProvider(episodeKey).notifier,
        );
        notifier.seed(likedByMe: false, likeCount: 4);

        final toggling = notifier.toggleLike();
        // A fresh server fetch lands while the mutation is in flight.
        notifier.applyServer(likedByMe: true, likeCount: 9, commentCount: 3);
        await toggling;

        // Mutation failed → reconcile to the mid-flight server payload
        // instead of the stale pre-mutation snapshot.
        final state = container.read(episodeEngagementProvider(episodeKey));
        expect(state.likedByMe, isTrue);
        expect(state.likeCount, 9);
        expect(state.commentCount, 3);
      },
    );

    test('applyServer is skipped while a mutation is in flight', () async {
      when(
        () => engagementService.toggleEpisodeLike(
          dramaId: dramaId,
          episodeId: 'episode-1',
          episodeNo: any(named: 'episodeNo'),
          likedByMe: any(named: 'likedByMe'),
          likeCount: any(named: 'likeCount'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return Result<void>.success(null);
      });
      final container = createContainer();
      addTearDown(container.dispose);
      container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
      final notifier = container.read(
        episodeEngagementProvider(episodeKey).notifier,
      );
      notifier.seed(likedByMe: false, likeCount: 4);

      final toggling = notifier.toggleLike();
      notifier.applyServer(likedByMe: false, likeCount: 4); // stale fetch
      await toggling;

      final state = container.read(episodeEngagementProvider(episodeKey));
      expect(state.likedByMe, isTrue);
      expect(state.likeCount, 5);
    });

    test(
      'toggleLike blocked when I blocked the work author (blockedByMe)',
      () async {
        when(() => followRepo.getBlockRelation('author-1')).thenAnswer(
          (_) async => Result.success(const BlockRelation(blockedByMe: true)),
        );
        final container = createBlockAwareContainer();
        addTearDown(container.dispose);
        container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
        final notifier = container.read(
          episodeEngagementProvider(episodeKey).notifier,
        );
        notifier.seed(likedByMe: false, likeCount: 4);

        final result = await notifier.toggleLike(authorUserId: 'author-1');

        expect(result!.isFailure, isTrue);
        expect(
          result.errorOrNull!.l10nArgs['message'],
          LikeBlockErrorMessages.blockedByMe,
        );
        final state = container.read(episodeEngagementProvider(episodeKey));
        expect(state.likedByMe, isFalse);
        expect(state.likeCount, 4);
        expect(
          state.lastError!.l10nArgs['message'],
          LikeBlockErrorMessages.blockedByMe,
        );
        verifyNever(
          () => engagementService.toggleEpisodeLike(
            dramaId: any(named: 'dramaId'),
            episodeId: any(named: 'episodeId'),
            episodeNo: any(named: 'episodeNo'),
            likedByMe: any(named: 'likedByMe'),
            likeCount: any(named: 'likeCount'),
            type: any(named: 'type'),
          ),
        );
      },
    );

    test(
      'toggleLike blocked when the author blocked me (blockedByTarget)',
      () async {
        when(() => followRepo.getBlockRelation('author-1')).thenAnswer(
          (_) async =>
              Result.success(const BlockRelation(blockedByTarget: true)),
        );
        final container = createBlockAwareContainer();
        addTearDown(container.dispose);
        container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
        final notifier = container.read(
          episodeEngagementProvider(episodeKey).notifier,
        );
        notifier.seed(likedByMe: false, likeCount: 4);

        final result = await notifier.toggleLike(authorUserId: 'author-1');

        expect(result!.isFailure, isTrue);
        expect(
          result.errorOrNull!.l10nArgs['message'],
          LikeBlockErrorMessages.blockedByTarget,
        );
        verifyNever(
          () => engagementService.toggleEpisodeLike(
            dramaId: any(named: 'dramaId'),
            episodeId: any(named: 'episodeId'),
            episodeNo: any(named: 'episodeNo'),
            likedByMe: any(named: 'likedByMe'),
            likeCount: any(named: 'likeCount'),
            type: any(named: 'type'),
          ),
        );
      },
    );

    test('toggleLike unliking is not blocked by a block relation', () async {
      when(() => followRepo.getBlockRelation('author-1')).thenAnswer(
        (_) async => Result.success(const BlockRelation(blockedByTarget: true)),
      );
      when(
        () => engagementService.toggleEpisodeLike(
          dramaId: dramaId,
          episodeId: 'episode-1',
          episodeNo: any(named: 'episodeNo'),
          likedByMe: false,
          likeCount: any(named: 'likeCount'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => Result<void>.success(null));
      final container = createBlockAwareContainer();
      addTearDown(container.dispose);
      container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
      final notifier = container.read(
        episodeEngagementProvider(episodeKey).notifier,
      );
      notifier.seed(likedByMe: true, likeCount: 5);

      final result = await notifier.toggleLike(authorUserId: 'author-1');

      expect(result!.isSuccess, isTrue);
      final state = container.read(episodeEngagementProvider(episodeKey));
      expect(state.likedByMe, isFalse);
      expect(state.likeCount, 4);
    });

    test(
      'toggleLike proceeds when no block relation with the author',
      () async {
        when(
          () => engagementService.toggleEpisodeLike(
            dramaId: dramaId,
            episodeId: 'episode-1',
            episodeNo: any(named: 'episodeNo'),
            likedByMe: true,
            likeCount: any(named: 'likeCount'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) async => Result<void>.success(null));
        final container = createBlockAwareContainer();
        addTearDown(container.dispose);
        container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
        final notifier = container.read(
          episodeEngagementProvider(episodeKey).notifier,
        );
        notifier.seed(likedByMe: false, likeCount: 4);

        final result = await notifier.toggleLike(authorUserId: 'author-1');

        expect(result!.isSuccess, isTrue);
        verify(() => followRepo.getBlockRelation('author-1')).called(1);
        verify(
          () => engagementService.toggleEpisodeLike(
            dramaId: dramaId,
            episodeId: 'episode-1',
            episodeNo: any(named: 'episodeNo'),
            likedByMe: true,
            likeCount: any(named: 'likeCount'),
            type: any(named: 'type'),
          ),
        ).called(1);
      },
    );

    test(
      'toggleWorkFavorite blocked when I blocked the author (blockedByMe)',
      () async {
        when(() => followRepo.getBlockRelation('author-1')).thenAnswer(
          (_) async => Result.success(const BlockRelation(blockedByMe: true)),
        );
        final container = createBlockAwareContainer();
        addTearDown(container.dispose);
        container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
        final notifier = container.read(
          episodeEngagementProvider(episodeKey).notifier,
        );
        notifier.seed(favoritedByMe: false, favoriteCount: 4);

        final result = await notifier.toggleWorkFavorite(
          authorUserId: 'author-1',
        );

        expect(result!.isFailure, isTrue);
        expect(
          result.errorOrNull!.l10nArgs['message'],
          FavoriteBlockErrorMessages.blockedByMe,
        );
        final state = container.read(episodeEngagementProvider(episodeKey));
        expect(state.favoritedByMe, isFalse);
        expect(state.favoriteCount, 4);
        expect(
          state.lastError!.l10nArgs['message'],
          FavoriteBlockErrorMessages.blockedByMe,
        );
        verifyNever(
          () => engagementService.toggleWorkFavorite(
            dramaId: any(named: 'dramaId'),
            episodeId: any(named: 'episodeId'),
            episodeNo: any(named: 'episodeNo'),
            favoritedByMe: any(named: 'favoritedByMe'),
            type: any(named: 'type'),
          ),
        );
      },
    );

    test(
      'toggleWorkFavorite blocked when the author blocked me (blockedByTarget)',
      () async {
        when(() => followRepo.getBlockRelation('author-1')).thenAnswer(
          (_) async =>
              Result.success(const BlockRelation(blockedByTarget: true)),
        );
        final container = createBlockAwareContainer();
        addTearDown(container.dispose);
        container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
        final notifier = container.read(
          episodeEngagementProvider(episodeKey).notifier,
        );
        notifier.seed(favoritedByMe: false, favoriteCount: 4);

        final result = await notifier.toggleWorkFavorite(
          authorUserId: 'author-1',
        );

        expect(result!.isFailure, isTrue);
        expect(
          result.errorOrNull!.l10nArgs['message'],
          FavoriteBlockErrorMessages.blockedByTarget,
        );
        verifyNever(
          () => engagementService.toggleWorkFavorite(
            dramaId: any(named: 'dramaId'),
            episodeId: any(named: 'episodeId'),
            episodeNo: any(named: 'episodeNo'),
            favoritedByMe: any(named: 'favoritedByMe'),
            type: any(named: 'type'),
          ),
        );
      },
    );

    test('toggleWorkFavorite unfavoriting is not blocked', () async {
      when(() => followRepo.getBlockRelation('author-1')).thenAnswer(
        (_) async => Result.success(const BlockRelation(blockedByTarget: true)),
      );
      when(
        () => engagementService.toggleWorkFavorite(
          dramaId: dramaId,
          episodeId: 'episode-1',
          episodeNo: any(named: 'episodeNo'),
          favoritedByMe: false,
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => Result<void>.success(null));
      final container = createBlockAwareContainer();
      addTearDown(container.dispose);
      container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
      final notifier = container.read(
        episodeEngagementProvider(episodeKey).notifier,
      );
      notifier.seed(favoritedByMe: true, favoriteCount: 5);

      final result = await notifier.toggleWorkFavorite(
        authorUserId: 'author-1',
      );

      expect(result!.isSuccess, isTrue);
      final state = container.read(episodeEngagementProvider(episodeKey));
      expect(state.favoritedByMe, isFalse);
      expect(state.favoriteCount, 4);
    });

    test('toggleWorkFavorite proceeds when no block relation', () async {
      when(
        () => engagementService.toggleWorkFavorite(
          dramaId: dramaId,
          episodeId: 'episode-1',
          episodeNo: any(named: 'episodeNo'),
          favoritedByMe: true,
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => Result<void>.success(null));
      final container = createBlockAwareContainer();
      addTearDown(container.dispose);
      container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
      final notifier = container.read(
        episodeEngagementProvider(episodeKey).notifier,
      );
      notifier.seed(favoritedByMe: false, favoriteCount: 4);

      final result = await notifier.toggleWorkFavorite(
        authorUserId: 'author-1',
      );

      expect(result!.isSuccess, isTrue);
      verify(() => followRepo.getBlockRelation('author-1')).called(1);
      verify(
        () => engagementService.toggleWorkFavorite(
          dramaId: dramaId,
          episodeId: 'episode-1',
          episodeNo: any(named: 'episodeNo'),
          favoritedByMe: true,
          type: any(named: 'type'),
        ),
      ).called(1);
    });
  });

  group('EpisodeEngagementKey.forEpisode', () {
    test('empty dramaId falls back to episodeId for provider identity', () {
      final fromCard = EpisodeEngagementKey.forEpisode(
        dramaId: '',
        episodeId: 'episode-1',
      );
      final fromToggle = EpisodeEngagementKey.forEpisode(
        dramaId: 'episode-1',
        episodeId: 'episode-1',
      );
      expect(fromCard, equals(fromToggle));
    });
  });

  group('EpisodeEngagementController.applyVisible', () {
    test('overwrites retained stale likedByMe from the visible card', () {
      final container = createBlockAwareContainer();
      addTearDown(container.dispose);
      container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
      final notifier = container.read(
        episodeEngagementProvider(episodeKey).notifier,
      );
      notifier.seed(likedByMe: true, likeCount: 9);

      notifier.applyVisible(likedByMe: false, likeCount: 8);

      final state = container.read(episodeEngagementProvider(episodeKey));
      expect(state.likedByMe, isFalse);
      expect(state.likeCount, 8);
    });

    test('toggleLike honors likedByMeBaseline over stale store', () async {
      when(
        () => engagementService.toggleEpisodeLike(
          dramaId: dramaId,
          episodeId: 'episode-1',
          episodeNo: any(named: 'episodeNo'),
          likedByMe: true,
          likeCount: any(named: 'likeCount'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => Result<void>.success(null));
      final container = createBlockAwareContainer();
      addTearDown(container.dispose);
      container.listen(episodeEngagementProvider(episodeKey), (_, _) {});
      final notifier = container.read(
        episodeEngagementProvider(episodeKey).notifier,
      );
      notifier.seed(likedByMe: true, likeCount: 5);

      final result = await notifier.toggleLike(likedByMeBaseline: false);

      expect(result!.isSuccess, isTrue);
      final state = container.read(episodeEngagementProvider(episodeKey));
      expect(state.likedByMe, isTrue);
      expect(state.likeCount, 6);
    });
  });
}
