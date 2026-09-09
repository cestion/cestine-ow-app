import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/creator_controller.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/actor_repository.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/repositories/user_repository.dart';

class MockDramaRepository extends Mock implements DramaRepository {}

class MockActorRepository extends Mock implements ActorRepository {}

class MockUserRepository extends Mock implements UserRepository {}

/// Fake AuthController for testing that provides controllable auth state.
class FakeAuthController extends Notifier<AuthState> implements AuthController {
  final StreamController<bool> _authChanges =
      StreamController<bool>.broadcast();

  final Completer<void> _readyCompleter = Completer<void>()..complete();

  bool _loggedIn = true;

  @override
  AuthState build() => AuthState(ready: true, isLoggedIn: _loggedIn);

  @override
  void completeReady() {}

  void setLoggedIn(bool value) {
    _loggedIn = value;
    state = state.copyWith(isLoggedIn: value);
  }

  /// Emit an auth state change event to the [authStateChanges] stream.
  void emitAuthChange(bool value) => _authChanges.add(value);

  @override
  Stream<bool> get authStateChanges => _authChanges.stream;

  @override
  bool get isLoggedIn => _loggedIn;

  @override
  String? get accessToken => state.token;

  @override
  String? get userId => state.userId;

  @override
  Future<String?> getAccessToken() async => state.token;

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  Future<void> logout() async {
    _loggedIn = false;
    state = state.copyWith(isLoggedIn: false);
    _authChanges.add(false);
  }

  @override
  Future<PrivySessionGate> ensurePrivySessionReady() async =>
      isLoggedIn ? PrivySessionGate.ready : PrivySessionGate.needsReauth;

  @override
  String get pendingEmail => state.pendingEmail;

  @override
  String get solanaAddress => state.effectiveSolanaAddress;

  @override
  String get ethereumAddress => state.ethereumAddress;

  @override
  Future<void> ensureWallets() async {}

  @override
  Future<void> syncWalletAddressesFromStorage() async {}

  @override
  bool get isLogging => state.isLogging;

  @override
  bool get isLoggingOut => state.isLoggingOut;

  @override
  UserProfile? get profile => state.profile;

  @override
  Future<({bool ok, String? err})> sendOtp(String email) async =>
      (ok: true, err: null);

  @override
  Future<({bool ok, String? err})> verifyOtp(String code) async =>
      (ok: true, err: null);

  @override
  void updateProfile(UserProfile newProfile) {
    state = state.copyWith(profile: newProfile);
  }

  @override
  Future<void> setToken(String token) async {
    state = state.copyWith(token: token, isLoggedIn: true);
  }

  @override
  Future<Result<void>> updateNickname({
    required String nickname,
    String? profile,
  }) async => Result.success(null);

  @override
  Future<Result<void>> updateAvatar(String avatarUrl) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteAccount() async => Result.success(null);

  @override
  Future<Result<void>> cancelAccountDeletion() async => Result.success(null);
}

void main() {
  late ProviderContainer container;
  late CreatorController controller;
  late MockDramaRepository dramaRepo;
  late MockActorRepository actorRepo;
  late MockUserRepository userRepo;
  late FakeAuthController fakeAuth;

  setUp(() {
    dramaRepo = MockDramaRepository();
    actorRepo = MockActorRepository();
    userRepo = MockUserRepository();
    fakeAuth = FakeAuthController();

    // Default: empty success responses
    when(() => actorRepo.listMyActors()).thenAnswer(
      (_) async => Result<PageDto<Actor>>.success(
        const PageDto(list: [], hasMore: false),
      ),
    );
    when(
      () => dramaRepo.getOnlineDramaCount(),
    ).thenAnswer((_) async => Result<int>.success(0));
    when(
      () => userRepo.getDramaNftCount(),
    ).thenAnswer((_) async => Result<int>.success(0));

    container = ProviderContainer(
      overrides: [
        dramaRepositoryProvider.overrideWithValue(dramaRepo),
        actorRepositoryProvider.overrideWithValue(actorRepo),
        userRepositoryProvider.overrideWithValue(userRepo),
        authControllerProvider.overrideWith(() => fakeAuth),
      ],
    );
    controller = container.read(creatorControllerProvider.notifier);
    // Permanent listener prevents autoDispose during async gaps
    container.listen(creatorControllerProvider, (prev, next) {});
  });

  tearDown(() {
    container.dispose();
  });

  group('CreatorController', () {
    // ─── Initial state ────────────────────────────────────────────

    test('initial state has empty lists and is not loading', () {
      expect(controller.myActors, isEmpty);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, '');
    });

    test('can rebuild after provider invalidation', () {
      container.invalidate(creatorControllerProvider);

      expect(() => container.read(creatorControllerProvider), returnsNormally);
    });

    // ─── Load guard ───────────────────────────────────────────────

    test('load does nothing when not logged in', () async {
      fakeAuth.setLoggedIn(false);

      await controller.load();

      verifyNever(() => actorRepo.listMyActors());
      verifyNever(() => dramaRepo.getOnlineDramaCount());
      verifyNever(() => userRepo.getDramaNftCount());
      expect(controller.myActors, isEmpty);
    });

    // ─── Success path ─────────────────────────────────────────────

    test('load populates myActors and metric counts on success', () async {
      final actors = [const Actor(id: '10', name: 'Actor X')];

      when(() => actorRepo.listMyActors()).thenAnswer(
        (_) async => Result<PageDto<Actor>>.success(
          PageDto(list: actors, hasMore: false),
        ),
      );
      when(
        () => dramaRepo.getOnlineDramaCount(),
      ).thenAnswer((_) async => Result<int>.success(3));
      when(
        () => userRepo.getDramaNftCount(),
      ).thenAnswer((_) async => Result<int>.success(7));

      await controller.load();

      expect(controller.myActors.length, 1);
      expect(controller.myActors.first.name, 'Actor X');
      final state = container.read(creatorControllerProvider);
      expect(state.onlineDramaCount, 3);
      expect(state.ownedNftCount, 7);
    });

    test('load replaces previous data on subsequent calls', () async {
      when(() => actorRepo.listMyActors()).thenAnswer(
        (_) async => Result<PageDto<Actor>>.success(
          const PageDto(
            list: [Actor(id: '10', name: 'Actor X')],
            hasMore: false,
          ),
        ),
      );
      when(
        () => dramaRepo.getOnlineDramaCount(),
      ).thenAnswer((_) async => Result<int>.success(1));
      await controller.load();
      expect(controller.myActors.length, 1);

      when(() => actorRepo.listMyActors()).thenAnswer(
        (_) async => Result<PageDto<Actor>>.success(
          const PageDto(
            list: [
              Actor(id: '11', name: 'Actor Y'),
              Actor(id: '12', name: 'Actor Z'),
            ],
            hasMore: false,
          ),
        ),
      );
      when(
        () => dramaRepo.getOnlineDramaCount(),
      ).thenAnswer((_) async => Result<int>.success(2));
      await controller.load();
      expect(controller.myActors.length, 2);
      expect(controller.myActors.first.id, '11');
    });

    // ─── refreshOnlineDramaCount ─────────────────────────────────

    test(
      'refreshOnlineDramaCount updates count without touching myActors',
      () async {
        final actors = [const Actor(id: '10', name: 'Actor X')];
        when(() => actorRepo.listMyActors()).thenAnswer(
          (_) async => Result<PageDto<Actor>>.success(
            PageDto(list: actors, hasMore: false),
          ),
        );
        when(
          () => dramaRepo.getOnlineDramaCount(),
        ).thenAnswer((_) async => Result<int>.success(2));
        await controller.load();
        expect(container.read(creatorControllerProvider).onlineDramaCount, 2);

        // Simulate a new drama being created: server count now 3.
        when(
          () => dramaRepo.getOnlineDramaCount(),
        ).thenAnswer((_) async => Result<int>.success(3));

        await controller.refreshOnlineDramaCount();

        final state = container.read(creatorControllerProvider);
        expect(state.onlineDramaCount, 3);
        // myActors must NOT be re-fetched by refreshOnlineDramaCount.
        verify(() => actorRepo.listMyActors()).called(1);
        // isLoading must NOT flip during refreshOnlineDramaCount.
        expect(state.isLoading, false);
      },
    );

    test('refreshOnlineDramaCount no-op when not logged in', () async {
      fakeAuth.setLoggedIn(false);
      await controller.refreshOnlineDramaCount();
      verifyNever(() => dramaRepo.getOnlineDramaCount());
    });

    // ─── refreshOwnedNftCount ─────────────────────────────────────

    test(
      'refreshOwnedNftCount updates count without touching myActors or onlineCount',
      () async {
        final actors = [const Actor(id: '10', name: 'Actor X')];
        when(() => actorRepo.listMyActors()).thenAnswer(
          (_) async => Result<PageDto<Actor>>.success(
            PageDto(list: actors, hasMore: false),
          ),
        );
        when(
          () => dramaRepo.getOnlineDramaCount(),
        ).thenAnswer((_) async => Result<int>.success(5));
        when(
          () => userRepo.getDramaNftCount(),
        ).thenAnswer((_) async => Result<int>.success(3));
        await controller.load();
        expect(container.read(creatorControllerProvider).ownedNftCount, 3);

        // Simulate a new drama NFT being minted: server count now 4.
        when(
          () => userRepo.getDramaNftCount(),
        ).thenAnswer((_) async => Result<int>.success(4));

        await controller.refreshOwnedNftCount();

        final state = container.read(creatorControllerProvider);
        expect(state.ownedNftCount, 4);
        // myActors and onlineDramaCount must NOT be re-fetched.
        verify(() => actorRepo.listMyActors()).called(1);
        verify(() => dramaRepo.getOnlineDramaCount()).called(1);
        expect(state.onlineDramaCount, 5);
        expect(state.isLoading, false);
      },
    );

    test(
      'optimistic NFT increment is not rolled back by a stale refresh',
      () async {
        when(
          () => userRepo.getDramaNftCount(),
        ).thenAnswer((_) async => Result<int>.success(3));
        await controller.load();

        final response = Completer<Result<int>>();
        when(
          () => userRepo.getDramaNftCount(),
        ).thenAnswer((_) => response.future);

        final refresh = controller.refreshOwnedNftCount(
          optimisticIncrement: true,
        );
        expect(container.read(creatorControllerProvider).ownedNftCount, 4);

        response.complete(Result<int>.success(3));
        await refresh;

        expect(container.read(creatorControllerProvider).ownedNftCount, 4);

        when(
          () => userRepo.getDramaNftCount(),
        ).thenAnswer((_) async => Result<int>.success(3));
        await controller.refreshOwnedNftCount();

        expect(container.read(creatorControllerProvider).ownedNftCount, 4);
      },
    );

    test(
      'optimistic NFT increment accepts a newer higher server count',
      () async {
        when(
          () => userRepo.getDramaNftCount(),
        ).thenAnswer((_) async => Result<int>.success(3));
        await controller.load();

        when(
          () => userRepo.getDramaNftCount(),
        ).thenAnswer((_) async => Result<int>.success(5));

        await controller.refreshOwnedNftCount(optimisticIncrement: true);

        expect(container.read(creatorControllerProvider).ownedNftCount, 5);
      },
    );

    test('refreshOwnedNftCount no-op when not logged in', () async {
      fakeAuth.setLoggedIn(false);
      await controller.refreshOwnedNftCount();
      verifyNever(() => userRepo.getDramaNftCount());
    });

    // ─── Loading state ────────────────────────────────────────────

    test('isLoading is false after load completes', () async {
      await controller.load();
      expect(controller.isLoading, false);
    });

    // ─── Error handling ───────────────────────────────────────────

    test('myActors stays empty when actor repo returns failure', () async {
      when(() => actorRepo.listMyActors()).thenAnswer(
        (_) async =>
            Result<PageDto<Actor>>.failure(ApiError.network('actor failed')),
      );

      await controller.load();

      expect(controller.myActors, isEmpty);
    });

    test('errorMessage is set when load throws an exception', () async {
      when(
        () => actorRepo.listMyActors(),
      ).thenThrow(Exception('network crash'));

      await controller.load();

      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNotEmpty);
    });

    // ─── Auth-dependent: cache clear on logout ────────────────────

    test('clears myActors when auth state changes to logged out', () async {
      final actors = [const Actor(id: '10', name: 'Actor X')];

      when(() => actorRepo.listMyActors()).thenAnswer(
        (_) async => Result<PageDto<Actor>>.success(
          PageDto(list: actors, hasMore: false),
        ),
      );
      when(
        () => userRepo.getDramaNftCount(),
      ).thenAnswer((_) async => Result<int>.success(4));

      await controller.load();
      expect(controller.myActors, isNotEmpty);
      expect(container.read(creatorControllerProvider).ownedNftCount, 4);

      // Simulate logout via auth state stream
      fakeAuth.emitAuthChange(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.myActors, isEmpty);
      expect(container.read(creatorControllerProvider).ownedNftCount, 0);
    });

    test('does not clear data on login event (authState = true)', () async {
      final actors = [const Actor(id: '10', name: 'Actor X')];
      when(() => actorRepo.listMyActors()).thenAnswer(
        (_) async => Result<PageDto<Actor>>.success(
          PageDto(list: actors, hasMore: false),
        ),
      );

      await controller.load();
      expect(controller.myActors.length, 1);

      // Login event should NOT clear data
      fakeAuth.emitAuthChange(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.myActors.length, 1);
    });

    // ─── Dispose ─────────────────────────────────────────────────

    test(
      'dispose triggers ref.onDispose and closes cleanly without error',
      () async {
        final actors = [const Actor(id: '10', name: 'Actor X')];
        when(() => actorRepo.listMyActors()).thenAnswer(
          (_) async => Result<PageDto<Actor>>.success(
            PageDto(list: actors, hasMore: false),
          ),
        );

        await controller.load();
        expect(controller.myActors.length, 1);

        // Dispose triggers ref.onDispose which cancels the auth subscription
        // Should not throw
        expect(() => container.dispose(), returnsNormally);

        // After dispose, the auth state controller can be safely closed
        // without affecting any Notifier state
        fakeAuth.emitAuthChange(false);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
    );
  });
}
