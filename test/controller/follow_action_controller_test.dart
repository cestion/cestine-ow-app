import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/follow_action_controller.dart';
import 'package:story_app/src/controller/follow_status_store.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/story_constants.dart';
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
  const targetId = 'creator-1';
  late MockFollowRepo followRepo;

  setUp(() {
    followRepo = MockFollowRepo();
    when(
      () => followRepo.getBlockRelation(any()),
    ).thenAnswer((_) async => Result.success(BlockRelation.none));
    when(
      () => followRepo.follow(any()),
    ).thenAnswer((_) async => Result<void>.success(null));
  });

  ProviderContainer createContainer() => ProviderContainer(
    overrides: [
      followRepositoryProvider.overrideWithValue(followRepo),
      authControllerProvider.overrideWith(_LoggedInAuthController.new),
    ],
  );

  test('follow blocked when I blocked the target (blockedByMe)', () async {
    when(() => followRepo.getBlockRelation(targetId)).thenAnswer(
      (_) async => Result.success(const BlockRelation(blockedByMe: true)),
    );
    final container = createContainer();
    addTearDown(container.dispose);
    final controller = container.read(followActionControllerProvider.notifier);

    final result = await controller.follow(targetId);
    expect(result.isFailure, isTrue);
    expect(
      result.errorOrNull!.l10nArgs['message'],
      FollowBlockErrorMessages.blockedByMe,
    );
    verifyNever(() => followRepo.follow(any()));
  });

  test('follow blocked when target blocked me (blockedByTarget)', () async {
    when(() => followRepo.getBlockRelation(targetId)).thenAnswer(
      (_) async => Result.success(const BlockRelation(blockedByTarget: true)),
    );
    final container = createContainer();
    addTearDown(container.dispose);
    final controller = container.read(followActionControllerProvider.notifier);

    final result = await controller.follow(targetId);
    expect(result.isFailure, isTrue);
    expect(
      result.errorOrNull!.l10nArgs['message'],
      FollowBlockErrorMessages.blockedByTarget,
    );
    verifyNever(() => followRepo.follow(any()));
  });

  test('follow proceeds and marks following when no block relation', () async {
    final container = createContainer();
    addTearDown(container.dispose);
    final controller = container.read(followActionControllerProvider.notifier);

    final result = await controller.follow(targetId);
    expect(result.isSuccess, isTrue);
    verify(() => followRepo.follow(targetId)).called(1);
    expect(
      container.read(followStatusStoreProvider).isFollowing(targetId),
      isTrue,
    );
  });

  test('follow proceeds when block relation lookup fails', () async {
    when(() => followRepo.getBlockRelation(targetId)).thenAnswer(
      (_) async => Result<BlockRelation>.failure(ApiError.network('boom')),
    );
    final container = createContainer();
    addTearDown(container.dispose);
    final controller = container.read(followActionControllerProvider.notifier);

    final result = await controller.follow(targetId);
    expect(result.isSuccess, isTrue);
    verify(() => followRepo.follow(targetId)).called(1);
  });

  test('block auto-unfollows the target locally on success', () async {
    when(
      () => followRepo.block(targetId),
    ).thenAnswer((_) async => Result<void>.success(null));
    final container = createContainer();
    addTearDown(container.dispose);
    container
        .read(followStatusStoreProvider.notifier)
        .seedIfUnknown(targetId, true);
    expect(
      container.read(followStatusStoreProvider).isFollowing(targetId),
      isTrue,
    );

    final action = container.read(followActionControllerProvider.notifier);
    final result = await action.block(targetId);

    expect(result.isSuccess, isTrue);
    verify(() => followRepo.block(targetId)).called(1);
    expect(
      container.read(followStatusStoreProvider).isFollowing(targetId),
      isFalse,
    );
  });

  test('block keeps follow status when the block API fails', () async {
    when(
      () => followRepo.block(targetId),
    ).thenAnswer((_) async => Result<void>.failure(ApiError.network('boom')));
    final container = createContainer();
    addTearDown(container.dispose);
    container
        .read(followStatusStoreProvider.notifier)
        .seedIfUnknown(targetId, true);

    final action = container.read(followActionControllerProvider.notifier);
    final result = await action.block(targetId);

    expect(result.isFailure, isTrue);
    expect(
      container.read(followStatusStoreProvider).isFollowing(targetId),
      isTrue,
    );
  });

  test('unblock does not restore the follow status', () async {
    when(
      () => followRepo.unblock(targetId),
    ).thenAnswer((_) async => Result<void>.success(null));
    final container = createContainer();
    addTearDown(container.dispose);
    container
        .read(followStatusStoreProvider.notifier)
        .seedIfUnknown(targetId, true);
    container
        .read(followStatusStoreProvider.notifier)
        .setFollowing(targetId, false);

    final action = container.read(followActionControllerProvider.notifier);
    final result = await action.unblock(targetId);

    expect(result.isSuccess, isTrue);
    expect(
      container.read(followStatusStoreProvider).isFollowing(targetId),
      isFalse,
    );
  });
}
