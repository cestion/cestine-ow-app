import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/follow_status_store.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/follow_repository.dart';
import 'package:story_app/src/repositories/user_repository.dart';

class MockUserRepo extends Mock implements UserRepository {}

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
  const targetId = 'creator-1';

  late MockUserRepo userRepo;
  late MockFollowRepo followRepo;

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(userRepo),
        followRepositoryProvider.overrideWithValue(followRepo),
        authControllerProvider.overrideWith(_LoggedInAuthController.new),
      ],
    );
  }

  void stubFollowings(List<FollowListItem> items) {
    when(
      () => followRepo.listFollowings(
        userId: any(named: 'userId'),
        mark: any(named: 'mark'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer(
      (_) async => Result.success(PageDto(list: items, hasMore: false)),
    );
  }

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    userRepo = MockUserRepo();
    followRepo = MockFollowRepo();
    stubFollowings(const []);
    when(
      () => userRepo.getFollowRelation(targetId),
    ).thenAnswer((_) async => Result.success(FollowRelationStatus.none));
    when(
      () => userRepo.followUser(targetId),
    ).thenAnswer((_) async => Result.success(null));
    when(
      () => userRepo.unfollowUser(targetId),
    ).thenAnswer((_) async => Result.success(null));
  });

  test(
    'ensureLoaded uses a seeded follow flag, not the followings list',
    () async {
      final container = createContainer();
      addTearDown(container.dispose);
      container
          .read(followStatusStoreProvider.notifier)
          .seedIfUnknown(targetId, true);
      container.listen(followControllerProvider(targetId), (_, _) {});

      await container
          .read(followControllerProvider(targetId).notifier)
          .ensureLoaded();

      expect(
        container.read(followControllerProvider(targetId)).isFollowing,
        isTrue,
      );
      verifyNever(() => userRepo.getFollowRelation(targetId));
      verifyNever(
        () => followRepo.listFollowings(
          userId: any(named: 'userId'),
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
        ),
      );
    },
  );

  test(
    'ensureLoaded falls back to relation when the store does not know the user',
    () async {
      when(
        () => userRepo.getFollowRelation(targetId),
      ).thenAnswer((_) async => Result.success(FollowRelationStatus.following));
      final container = createContainer();
      addTearDown(container.dispose);
      container.listen(followControllerProvider(targetId), (_, _) {});

      await container
          .read(followControllerProvider(targetId).notifier)
          .ensureLoaded();

      expect(
        container.read(followControllerProvider(targetId)).isFollowing,
        isTrue,
      );
      verify(() => userRepo.getFollowRelation(targetId)).called(1);
      verifyNever(
        () => followRepo.listFollowings(
          userId: any(named: 'userId'),
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
        ),
      );
    },
  );

  test('toggle follows then unfollows', () async {
    final container = createContainer();
    addTearDown(container.dispose);
    container.listen(followControllerProvider(targetId), (_, _) {});
    final notifier = container.read(
      followControllerProvider(targetId).notifier,
    );
    await notifier.ensureLoaded();

    final followResult = await notifier.toggle();
    expect(followResult?.isSuccess, isTrue);
    expect(
      container.read(followControllerProvider(targetId)).isFollowing,
      isTrue,
    );
    verify(() => userRepo.followUser(targetId)).called(1);

    final unfollowResult = await notifier.toggle();
    expect(unfollowResult?.isSuccess, isTrue);
    expect(
      container.read(followControllerProvider(targetId)).isFollowing,
      isFalse,
    );
    verify(() => userRepo.unfollowUser(targetId)).called(1);
  });

  test('toggle rolls back when follow fails', () async {
    when(
      () => userRepo.followUser(targetId),
    ).thenAnswer((_) async => Result.failure(ApiError.network('nope')));
    final container = createContainer();
    addTearDown(container.dispose);
    container.listen(followControllerProvider(targetId), (_, _) {});
    final notifier = container.read(
      followControllerProvider(targetId).notifier,
    );
    await notifier.ensureLoaded();

    final result = await notifier.toggle();
    expect(result?.isFailure, isTrue);
    expect(
      container.read(followControllerProvider(targetId)).isFollowing,
      isFalse,
    );
    expect(
      container.read(followControllerProvider(targetId)).isMutating,
      isFalse,
    );
  });
}
