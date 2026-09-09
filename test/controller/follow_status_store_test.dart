import 'dart:async';

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
  late MockFollowRepo followRepo;

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        followRepositoryProvider.overrideWithValue(followRepo),
        authControllerProvider.overrideWith(_LoggedInAuthController.new),
      ],
    );
  }

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    followRepo = MockFollowRepo();
  });

  test('ensureLoaded pages followings into a set', () async {
    when(
      () => followRepo.listFollowings(
        userId: any(named: 'userId'),
        mark: any(named: 'mark'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((invocation) async {
      final mark = invocation.namedArguments[#mark] as String?;
      if (mark == null || mark.isEmpty || mark == '0') {
        return Result.success(
          const PageDto(
            list: [
              FollowListItem(userId: 'a'),
              FollowListItem(userId: 'b'),
            ],
            hasMore: true,
            mark: 'next',
          ),
        );
      }
      return Result.success(
        const PageDto(list: [FollowListItem(userId: 'c')], hasMore: false),
      );
    });

    final container = createContainer();
    addTearDown(container.dispose);

    await container.read(followStatusStoreProvider.notifier).ensureLoaded();
    final state = container.read(followStatusStoreProvider);

    expect(state.loaded, isTrue);
    expect(state.failed, isFalse);
    expect(state.followingIds, {'a', 'b', 'c'});
    expect(state.isFollowing('b'), isTrue);
    expect(state.isFollowing('z'), isFalse);
    expect(state.knows('b'), isTrue);
    verify(
      () => followRepo.listFollowings(
        userId: any(named: 'userId'),
        mark: any(named: 'mark'),
        pageSize: any(named: 'pageSize'),
      ),
    ).called(2);
  });

  test('setFollowing updates membership without refetch', () async {
    when(
      () => followRepo.listFollowings(
        userId: any(named: 'userId'),
        mark: any(named: 'mark'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer(
      (_) async => Result.success(const PageDto(list: [], hasMore: false)),
    );

    final container = createContainer();
    addTearDown(container.dispose);
    await container.read(followStatusStoreProvider.notifier).ensureLoaded();

    container.read(followStatusStoreProvider.notifier).setFollowing('u1', true);
    expect(container.read(followStatusStoreProvider).isFollowing('u1'), isTrue);

    container
        .read(followStatusStoreProvider.notifier)
        .setFollowing('u1', false);
    expect(
      container.read(followStatusStoreProvider).isFollowing('u1'),
      isFalse,
    );
    verify(
      () => followRepo.listFollowings(
        userId: any(named: 'userId'),
        mark: any(named: 'mark'),
        pageSize: any(named: 'pageSize'),
      ),
    ).called(1);
  });

  test('seedIfUnknown writes once and does not clobber a later toggle', () {
    final container = createContainer();
    addTearDown(container.dispose);
    final store = container.read(followStatusStoreProvider.notifier);

    store.seedIfUnknown('u1', false);
    expect(container.read(followStatusStoreProvider).knows('u1'), isTrue);
    expect(
      container.read(followStatusStoreProvider).isFollowing('u1'),
      isFalse,
    );

    store.setFollowing('u1', true);
    store.seedIfUnknown('u1', false);
    expect(container.read(followStatusStoreProvider).isFollowing('u1'), isTrue);
  });

  test('account switch discards in-flight hydrate writeback', () async {
    final gate = Completer<void>();
    when(
      () => followRepo.listFollowings(
        userId: any(named: 'userId'),
        mark: any(named: 'mark'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async {
      await gate.future;
      return Result.success(
        const PageDto(list: [FollowListItem(userId: 'old-follow')], hasMore: false),
      );
    });

    final auth = _MutableAuthController();
    final container = ProviderContainer(
      overrides: [
        followRepositoryProvider.overrideWithValue(followRepo),
        authControllerProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);

    final hydrate = container.read(followStatusStoreProvider.notifier).ensureLoaded();
    await Future<void>.delayed(Duration.zero);
    auth.switchUser('other');
    gate.complete();
    await hydrate;

    final state = container.read(followStatusStoreProvider);
    expect(state.followingIds.contains('old-follow'), isFalse);
  });
}

class _MutableAuthController extends AuthController {
  AuthState _state = const AuthState(
    ready: true,
    isLoggedIn: true,
    profile: UserProfile(userId: 'me'),
  );

  @override
  AuthState build() => _state;

  void switchUser(String userId) {
    _state = AuthState(
      ready: true,
      isLoggedIn: true,
      profile: UserProfile(userId: userId),
    );
    state = _state;
  }
}
