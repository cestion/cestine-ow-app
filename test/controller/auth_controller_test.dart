import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/story_sdk_config.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/actor_repository.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/repositories/mining_repository.dart';
import 'package:story_app/src/repositories/notification_repository.dart';
import 'package:story_app/src/repositories/user_repository.dart';
import 'package:story_app/src/services/privy_service.dart';

class MockUserRepo extends Mock implements UserRepository {}

class MockLocalRepo extends Mock implements StoryLocalRepository {}

class MockPrivyService extends Mock implements PrivyService {}

class MockDramaRepo extends Mock implements DramaRepository {}

class MockActorRepo extends Mock implements ActorRepository {}

class MockMiningRepo extends Mock implements MiningRepository {}

class MockNotificationRepo extends Mock implements NotificationRepository {}

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(
      const LoginRequest(privyToken: '', deviceType: LoginDeviceType.app),
    );
    registerFallbackValue(const UserProfile());
  });

  late ProviderContainer container;
  late MockUserRepo userRepo;
  late MockLocalRepo localRepo;
  late MockPrivyService privy;
  late MockDramaRepo dramaRepo;
  late MockActorRepo actorRepo;
  late MockMiningRepo miningRepo;
  late MockNotificationRepo notificationRepo;
  late MockBox box;

  setUp(() {
    userRepo = MockUserRepo();
    localRepo = MockLocalRepo();
    privy = MockPrivyService();
    dramaRepo = MockDramaRepo();
    actorRepo = MockActorRepo();
    miningRepo = MockMiningRepo();
    notificationRepo = MockNotificationRepo();
    box = MockBox();

    when(() => localRepo.cacheBox).thenReturn(box);
    when(
      () => box.put(any<dynamic>(), any<dynamic>()),
    ).thenAnswer((_) async {});
    when(() => box.delete(any<dynamic>())).thenAnswer((_) async {});
    when(() => box.get(any<dynamic>())).thenReturn(null);

    when(() => localRepo.getToken()).thenReturn(null);
    when(() => localRepo.cachedToken).thenReturn(null);
    when(() => localRepo.getTokenAsync()).thenAnswer((_) async => null);
    when(
      () => localRepo.getSolanaWalletAddressAsync(),
    ).thenAnswer((_) async => null);
    when(
      () => localRepo.getEthereumWalletAddressAsync(),
    ).thenAnswer((_) async => null);
    when(() => localRepo.getUser()).thenReturn(null);
    when(() => localRepo.getSolanaWalletAddress()).thenReturn(null);
    when(() => localRepo.getEthereumWalletAddress()).thenReturn(null);
    when(() => localRepo.clearToken()).thenAnswer((_) async {});
    when(() => localRepo.clearUser()).thenAnswer((_) async {});
    when(() => localRepo.clearSolanaWalletAddress()).thenAnswer((_) async {});
    when(() => localRepo.clearEthereumWalletAddress()).thenAnswer((_) async {});
    when(() => localRepo.clearCreateDramaDraft()).thenAnswer((_) async {});
    when(() => localRepo.clearPublishVideoDraft()).thenAnswer((_) async {});
    when(() => localRepo.saveToken(any())).thenAnswer((_) async {});
    when(() => localRepo.saveUser(any())).thenAnswer((_) async {});
    when(
      () => localRepo.saveSolanaWalletAddress(any()),
    ).thenAnswer((_) async {});
    when(
      () => localRepo.saveEthereumWalletAddress(any()),
    ).thenAnswer((_) async {});
    when(() => privy.ensureSolanaWallet()).thenAnswer(
      (_) async => (
        success: true,
        address: 'sol_addr' as String?,
        error: null as String?,
      ),
    );
    when(() => privy.ensureEthereumWallet()).thenAnswer(
      (_) async =>
          (success: true, address: '0xevm' as String?, error: null as String?),
    );
    when(() => privy.logout()).thenAnswer((_) async {});
    when(
      () => privy.resolveSessionStatus(),
    ).thenAnswer((_) async => PrivySessionStatus.authenticated);
    when(() => privy.isSessionAuthenticated()).thenAnswer((_) async => true);
    when(
      () => userRepo.logout(),
    ).thenAnswer((_) async => Result<void>.success(null));
    when(() => dramaRepo.clearUserScopedCaches()).thenAnswer((_) async {});
    when(() => actorRepo.clearUserScopedCaches()).thenAnswer((_) async {});
    when(() => miningRepo.clearUserScopedCaches()).thenAnswer((_) async {});
    when(
      () => notificationRepo.clearCachedFirstPages(),
    ).thenAnswer((_) async {});
    when(() => userRepo.clearProfileCache()).thenAnswer((_) async {});
    when(() => userRepo.seedCurrentProfile(any())).thenAnswer((_) async {});

    container = _createContainer(
      userRepo: userRepo,
      localRepo: localRepo,
      privy: privy,
      dramaRepo: dramaRepo,
      actorRepo: actorRepo,
      miningRepo: miningRepo,
      notificationRepo: notificationRepo,
    );
  });

  tearDown(() {
    container.dispose();
  });

  AuthController readAuth() => container.read(authControllerProvider.notifier);
  AuthState readState() => container.read(authControllerProvider);

  group('AuthController', () {
    test('initial state is not logged in', () {
      final state = readState();
      expect(state.isLoggedIn, false);
      expect(state.isLogging, false);
      expect(state.isLoggingOut, false);
      expect(state.profile, null);
      expect(state.token, null);
      expect(state.userId, null);
    });

    test('build is optimistically logged in when cachedToken exists', () {
      container.dispose();
      when(() => localRepo.cachedToken).thenReturn('user_jwt');
      when(() => localRepo.getUser()).thenReturn(
        const UserProfile(userId: 'otp_user', email: 'user@example.com'),
      );
      when(() => localRepo.getTokenAsync()).thenAnswer((_) async => 'user_jwt');
      // Keep Privy pending so restore does not finish immediately.
      when(() => privy.resolveSessionStatus()).thenAnswer(
        (_) => Future<PrivySessionStatus>.delayed(
          const Duration(days: 1),
          () => PrivySessionStatus.authenticated,
        ),
      );

      container = _createContainer(
        userRepo: userRepo,
        localRepo: localRepo,
        privy: privy,
        dramaRepo: dramaRepo,
        actorRepo: actorRepo,
        miningRepo: miningRepo,
        notificationRepo: notificationRepo,
      );

      final state = container.read(authControllerProvider);
      expect(state.isLoggedIn, true);
      expect(state.ready, false);
      expect(state.token, 'user_jwt');
      expect(state.profile?.userId, 'otp_user');
    });

    test('restore clears session when Privy is unauthenticated', () async {
      container.dispose();
      when(() => localRepo.cachedToken).thenReturn('user_jwt');
      when(() => localRepo.getTokenAsync()).thenAnswer((_) async => 'user_jwt');
      when(() => localRepo.getUser()).thenReturn(
        const UserProfile(userId: 'otp_user', email: 'user@example.com'),
      );
      when(
        () => privy.resolveSessionStatus(),
      ).thenAnswer((_) async => PrivySessionStatus.unauthenticated);

      container = _createContainer(
        userRepo: userRepo,
        localRepo: localRepo,
        privy: privy,
        dramaRepo: dramaRepo,
        actorRepo: actorRepo,
        miningRepo: miningRepo,
        notificationRepo: notificationRepo,
      );

      // Optimistic first frame.
      expect(container.read(authControllerProvider).isLoggedIn, true);

      await container.read(authControllerProvider.notifier).ready;
      final state = container.read(authControllerProvider);

      expect(state.isLoggedIn, false);
      expect(state.token, null);
      verify(() => localRepo.clearToken()).called(1);
      verify(() => localRepo.clearUser()).called(1);
    });

    test('restore keeps session when Privy status is unknown', () async {
      container.dispose();
      when(() => localRepo.cachedToken).thenReturn('user_jwt');
      when(() => localRepo.getTokenAsync()).thenAnswer((_) async => 'user_jwt');
      when(() => localRepo.getUser()).thenReturn(
        const UserProfile(userId: 'otp_user', email: 'user@example.com'),
      );
      when(
        () => privy.resolveSessionStatus(),
      ).thenAnswer((_) async => PrivySessionStatus.unknown);

      container = _createContainer(
        userRepo: userRepo,
        localRepo: localRepo,
        privy: privy,
        dramaRepo: dramaRepo,
        actorRepo: actorRepo,
        miningRepo: miningRepo,
        notificationRepo: notificationRepo,
      );

      expect(container.read(authControllerProvider).isLoggedIn, true);

      await container.read(authControllerProvider.notifier).ready;
      final state = container.read(authControllerProvider);

      expect(state.isLoggedIn, true);
      expect(state.token, 'user_jwt');
      expect(state.profile?.userId, 'otp_user');
      verifyNever(() => localRepo.clearToken());
      verifyNever(() => localRepo.clearUser());
      verifyNever(() => privy.logout());
    });

    test(
      'ensurePrivySessionReady keeps session when Privy is unknown',
      () async {
        container.dispose();
        when(() => localRepo.cachedToken).thenReturn('user_jwt');
        when(
          () => localRepo.getTokenAsync(),
        ).thenAnswer((_) async => 'user_jwt');
        when(() => localRepo.getUser()).thenReturn(
          const UserProfile(userId: 'otp_user', email: 'user@example.com'),
        );
        when(
          () => privy.resolveSessionStatus(),
        ).thenAnswer((_) async => PrivySessionStatus.unknown);

        container = _createContainer(
          userRepo: userRepo,
          localRepo: localRepo,
          privy: privy,
          dramaRepo: dramaRepo,
          actorRepo: actorRepo,
          miningRepo: miningRepo,
          notificationRepo: notificationRepo,
        );

        final auth = container.read(authControllerProvider.notifier);
        await auth.ready;

        final gate = await auth.ensurePrivySessionReady();
        expect(gate, PrivySessionGate.temporarilyUnavailable);
        expect(container.read(authControllerProvider).isLoggedIn, true);
        expect(container.read(authControllerProvider).token, 'user_jwt');
        verifyNever(() => localRepo.clearToken());
      },
    );

    test('restore prefers persisted token over initialToken', () async {
      container.dispose();
      when(() => localRepo.cachedToken).thenReturn('user_jwt');
      when(() => localRepo.getTokenAsync()).thenAnswer((_) async => 'user_jwt');
      when(() => localRepo.getUser()).thenReturn(
        const UserProfile(userId: 'otp_user', email: 'user@example.com'),
      );

      container = _createContainer(
        userRepo: userRepo,
        localRepo: localRepo,
        privy: privy,
        dramaRepo: dramaRepo,
        actorRepo: actorRepo,
        miningRepo: miningRepo,
        notificationRepo: notificationRepo,
        config: const StorySdkConfig(initialToken: 'dev_jwt'),
      );

      await container.read(authControllerProvider.notifier).ready;
      final state = container.read(authControllerProvider);

      expect(state.isLoggedIn, true);
      expect(state.token, 'user_jwt');
      expect(state.profile?.userId, 'otp_user');
      verifyNever(() => localRepo.saveToken('dev_jwt'));
    });

    test('restore falls back to initialToken when nothing persisted', () async {
      container.dispose();
      when(() => localRepo.getTokenAsync()).thenAnswer((_) async => null);
      when(() => localRepo.getUser()).thenReturn(null);
      when(() => localRepo.saveToken('dev_jwt')).thenAnswer((_) async {});

      container = _createContainer(
        userRepo: userRepo,
        localRepo: localRepo,
        privy: privy,
        dramaRepo: dramaRepo,
        actorRepo: actorRepo,
        miningRepo: miningRepo,
        notificationRepo: notificationRepo,
        config: const StorySdkConfig(initialToken: 'dev_jwt'),
      );

      await container.read(authControllerProvider.notifier).ready;
      final state = container.read(authControllerProvider);

      expect(state.isLoggedIn, true);
      expect(state.token, 'dev_jwt');
      verify(() => localRepo.saveToken('dev_jwt')).called(1);
    });

    test('authStateChanges stream emits on logout', () async {
      final auth = readAuth();
      final stream = auth.authStateChanges;
      final values = <bool>[];
      stream.listen(values.add);

      await auth.logout();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(values, contains(false));
    });

    test('sendOtp sets isLogging to true then false', () async {
      when(
        () => privy.sendEmailCode(any()),
      ).thenAnswer((_) async => (success: true, error: null as String?));

      final auth = readAuth();
      expect(readState().isLogging, false);

      final future = auth.sendOtp('test@example.com');
      expect(readState().isLogging, true);

      await future;
      expect(readState().isLogging, false);
    });

    test('sendOtp returns success', () async {
      when(
        () => privy.sendEmailCode(any()),
      ).thenAnswer((_) async => (success: true, error: null as String?));

      final auth = readAuth();
      final result = await auth.sendOtp('test@example.com');
      expect(result.ok, true);
      expect(readState().pendingEmail, 'test@example.com');
    });

    test('sendOtp returns failure', () async {
      when(
        () => privy.sendEmailCode(any()),
      ).thenAnswer((_) async => (success: false, error: 'Failed'));

      final auth = readAuth();
      final result = await auth.sendOtp('test@example.com');
      expect(result.ok, false);
      expect(result.err, 'Failed');
    });

    test('verifyOtp fails without pending email', () async {
      final auth = readAuth();
      final result = await auth.verifyOtp('123456');
      expect(result.ok, false);
      expect(result.err, AuthController.needCodeFirstErrorKey);
    });

    test('verifyOtp succeeds with valid code', () async {
      when(
        () => privy.sendEmailCode(any()),
      ).thenAnswer((_) async => (success: true, error: null as String?));
      final auth = readAuth();
      await auth.sendOtp('test@example.com');

      when(
        () => privy.verifyEmailCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenAnswer(
        (_) async =>
            (success: true, privyToken: 'token123', error: null as String?),
      );
      when(() => userRepo.login(any())).thenAnswer(
        (_) async => Result<LoginResponse>.success(
          const LoginResponse(
            token: 'jwt_token',
            userProfile: UserProfile(userId: 'user1'),
          ),
        ),
      );
      when(() => localRepo.saveToken(any())).thenAnswer((_) async {});
      when(() => localRepo.saveUser(any())).thenAnswer((_) async {});
      when(() => privy.ensureSolanaWallet()).thenAnswer(
        (_) async =>
            (success: true, address: 'sol_addr', error: null as String?),
      );
      when(() => privy.getCurrentAccessToken()).thenAnswer(
        (_) async =>
            (success: true, privyToken: 'token123', error: null as String?),
      );

      final result = await auth.verifyOtp('123456');
      expect(result.ok, true);
      expect(readState().isLoggedIn, true);
      expect(readState().token, 'jwt_token');
      expect(readState().userId, 'user1');
      final captured =
          verify(() => userRepo.login(captureAny())).captured.single
              as LoginRequest;
      expect(captured.deviceType, LoginDeviceType.app);
      expect(captured.privyToken, 'token123');
    });

    test('logout clears all state', () async {
      when(
        () => privy.sendEmailCode(any()),
      ).thenAnswer((_) async => (success: true, error: null as String?));
      final auth = readAuth();
      await auth.sendOtp('test@example.com');
      when(
        () => privy.verifyEmailCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenAnswer(
        (_) async =>
            (success: true, privyToken: 'token123', error: null as String?),
      );
      when(() => userRepo.login(any())).thenAnswer(
        (_) async => Result<LoginResponse>.success(
          const LoginResponse(
            token: 'jwt_token',
            userProfile: UserProfile(userId: 'user1'),
          ),
        ),
      );
      when(() => localRepo.saveToken(any())).thenAnswer((_) async {});
      when(() => localRepo.saveUser(any())).thenAnswer((_) async {});
      when(() => privy.ensureSolanaWallet()).thenAnswer(
        (_) async =>
            (success: true, address: 'sol_addr', error: null as String?),
      );
      when(() => privy.getCurrentAccessToken()).thenAnswer(
        (_) async =>
            (success: true, privyToken: 'token123', error: null as String?),
      );
      await auth.verifyOtp('123456');
      expect(readState().isLoggedIn, true);

      await auth.logout();
      expect(readState().isLoggedIn, false);
      expect(readState().token, null);
      expect(readState().profile, null);
      expect(readState().pendingEmail, '');
      expect(readState().solanaAddress, '');
      expect(readState().ethereumAddress, '');
    });

    test('updateProfile updates profile', () async {
      const newProfile = UserProfile(userId: 'user2', nickname: 'Test User');
      final auth = readAuth();
      auth.updateProfile(newProfile);
      expect(readState().profile, newProfile);
    });

    test(
      'solanaAddress falls back to profile walletAddress if empty',
      () async {
        expect(readAuth().solanaAddress, '');
        const profileWithWallet = UserProfile(
          userId: 'user2',
          walletAddress: 'sol_address_from_profile',
        );
        final auth = readAuth();
        auth.updateProfile(profileWithWallet);
        expect(readAuth().solanaAddress, 'sol_address_from_profile');
      },
    );
  });
}

ProviderContainer _createContainer({
  required MockUserRepo userRepo,
  required MockLocalRepo localRepo,
  required MockPrivyService privy,
  required MockDramaRepo dramaRepo,
  required MockActorRepo actorRepo,
  required MockMiningRepo miningRepo,
  required MockNotificationRepo notificationRepo,
  StorySdkConfig config = const StorySdkConfig(),
}) {
  return ProviderContainer(
    overrides: [
      userRepositoryProvider.overrideWithValue(userRepo),
      localRepositoryProvider.overrideWithValue(localRepo),
      privyServiceProvider.overrideWithValue(privy),
      dramaRepositoryProvider.overrideWithValue(dramaRepo),
      actorRepositoryProvider.overrideWithValue(actorRepo),
      miningRepositoryProvider.overrideWithValue(miningRepo),
      notificationRepositoryProvider.overrideWithValue(notificationRepo),
      storySdkConfigProvider.overrideWithValue(config),
      globalConfigProvider.overrideWith(
        (ref) => Future<Result<GlobalConfig>>.value(
          Result.success(const GlobalConfig()),
        ),
      ),
    ],
  );
}
