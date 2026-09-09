import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/user_profile_actor_collections_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/actor_repository.dart';

class MockActorRepo extends Mock implements ActorRepository {}

class _LoggedInAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
    ready: true,
    isLoggedIn: true,
    profile: UserProfile(userId: 'me'),
  );
}

void main() {
  late MockActorRepo actorRepo;

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        actorRepositoryProvider.overrideWithValue(actorRepo),
        authControllerProvider.overrideWith(_LoggedInAuthController.new),
      ],
    );
  }

  setUp(() {
    actorRepo = MockActorRepo();
  });

  test('self profile uses profile actor-collections API', () async {
    when(
      () => actorRepo.listProfileActorCollections(
        userId: any(named: 'userId'),
        mark: any(named: 'mark'),
      ),
    ).thenAnswer(
      (_) async => Result.success(
        const PageDto(
          list: [ActorCollection(id: 'ip-1', name: 'Luna', userId: 'me')],
          hasMore: false,
        ),
      ),
    );

    final container = createContainer();
    addTearDown(container.dispose);
    const param = UserProfileActorParam();
    container.listen(userProfileActorCollectionsProvider(param), (_, _) {});

    final controller = container.read(
      userProfileActorCollectionsProvider(param).notifier,
    );
    await controller.refresh();

    final state = container.read(userProfileActorCollectionsProvider(param));
    expect(state.hasFetched, isTrue);
    expect(state.items.single.id, 'ip-1');
    verify(
      () => actorRepo.listProfileActorCollections(
        userId: 'me',
        mark: any(named: 'mark'),
      ),
    ).called(greaterThanOrEqualTo(1));
  });

  test('other profile requests that user id', () async {
    when(
      () => actorRepo.listProfileActorCollections(
        userId: any(named: 'userId'),
        mark: any(named: 'mark'),
      ),
    ).thenAnswer(
      (_) async => Result.success(
        const PageDto(
          list: [ActorCollection(id: 'ip-2', name: 'Nova')],
          hasMore: false,
        ),
      ),
    );

    final container = createContainer();
    addTearDown(container.dispose);
    const param = UserProfileActorParam(userId: 'other');
    container.listen(userProfileActorCollectionsProvider(param), (_, _) {});

    await container
        .read(userProfileActorCollectionsProvider(param).notifier)
        .refresh();

    final state = container.read(userProfileActorCollectionsProvider(param));
    expect(state.items.single.id, 'ip-2');
    verify(
      () => actorRepo.listProfileActorCollections(
        userId: 'other',
        mark: any(named: 'mark'),
      ),
    ).called(greaterThanOrEqualTo(1));
  });
}
