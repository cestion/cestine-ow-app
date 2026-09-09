import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/profile_controller.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/story_sdk_config.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/user_repository.dart';
import 'package:story_app/src/services/privy_service.dart';

class MockUserRepo extends Mock implements UserRepository {}

class MockLocalRepo extends Mock implements StoryLocalRepository {}

class MockPrivyService extends Mock implements PrivyService {}

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  setUpAll(() {
    registerFallbackValue(const UserProfile());
  });

  late ProviderContainer container;
  late MockUserRepo userRepo;
  late MockLocalRepo localRepo;
  late MockPrivyService privy;
  late MockBox box;

  setUp(() {
    userRepo = MockUserRepo();
    localRepo = MockLocalRepo();
    privy = MockPrivyService();
    box = MockBox();

    // Stubs required for AuthController.build() token restoration.
    when(() => localRepo.cacheBox).thenReturn(box);
    when(
      () => box.put(any<dynamic>(), any<dynamic>()),
    ).thenAnswer((_) async {});
    when(() => box.delete(any<dynamic>())).thenAnswer((_) async {});
    when(() => box.get(any<dynamic>())).thenReturn(null);

    when(() => localRepo.getTokenAsync()).thenAnswer((_) async => null);
    when(() => localRepo.cachedToken).thenReturn(null);
    when(
      () => localRepo.getSolanaWalletAddressAsync(),
    ).thenAnswer((_) async => null);
    when(
      () => localRepo.getEthereumWalletAddressAsync(),
    ).thenAnswer((_) async => null);
    when(() => localRepo.getUser()).thenReturn(null);
    when(() => localRepo.getWatchlist()).thenReturn(const []);
    when(() => localRepo.saveToken(any())).thenAnswer((_) async {});
    when(() => localRepo.saveUser(any())).thenAnswer((_) async {});
    when(
      () => localRepo.saveSolanaWalletAddress(any()),
    ).thenAnswer((_) async {});
    when(
      () => localRepo.saveEthereumWalletAddress(any()),
    ).thenAnswer((_) async {});
    when(() => privy.ensureSolanaWallet()).thenAnswer(
      (_) async =>
          (success: true, address: 'sol' as String?, error: null as String?),
    );
    when(() => privy.ensureEthereumWallet()).thenAnswer(
      (_) async =>
          (success: true, address: '0xevm' as String?, error: null as String?),
    );
    when(() => privy.isSessionAuthenticated()).thenAnswer((_) async => true);
    when(
      () => privy.resolveSessionStatus(),
    ).thenAnswer((_) async => PrivySessionStatus.authenticated);

    container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(userRepo),
        localRepositoryProvider.overrideWithValue(localRepo),
        privyServiceProvider.overrideWithValue(privy),
        storySdkConfigProvider.overrideWithValue(const StorySdkConfig()),
        globalConfigProvider.overrideWith(
          (ref) => Future<Result<GlobalConfig>>.value(
            Result.success(const GlobalConfig()),
          ),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  ProfileController readController() =>
      container.read(profileControllerProvider.notifier);

  test('can rebuild after provider invalidation', () {
    readController();
    container.invalidate(profileControllerProvider);

    expect(readController, returnsNormally);
  });

  group('ProfileController.saveProfile', () {
    test('updates nickname only when avatarUrl is null', () async {
      when(
        () => userRepo.updateNickname(
          nickname: any(named: 'nickname'),
          profile: any(named: 'profile'),
        ),
      ).thenAnswer((_) async => Result<void>.success(null));

      final result = await readController().saveProfile(nickname: 'Alice');

      expect(result.isSuccess, true);
      verify(() => userRepo.updateNickname(nickname: 'Alice')).called(1);
      verifyNever(() => userRepo.updateAvatar(any()));
    });

    test('updates avatar only when nickname is null', () async {
      when(
        () => userRepo.updateAvatar('https://cdn/avatar.png'),
      ).thenAnswer((_) async => Result<void>.success(null));

      final result = await readController().saveProfile(
        avatarUrl: 'https://cdn/avatar.png',
      );

      expect(result.isSuccess, true);
      verify(() => userRepo.updateAvatar('https://cdn/avatar.png')).called(1);
      verifyNever(
        () => userRepo.updateNickname(
          nickname: any(named: 'nickname'),
          profile: any(named: 'profile'),
        ),
      );
    });

    test('updates both nickname and avatar', () async {
      when(
        () => userRepo.updateNickname(
          nickname: any(named: 'nickname'),
          profile: any(named: 'profile'),
        ),
      ).thenAnswer((_) async => Result<void>.success(null));
      when(
        () => userRepo.updateAvatar(any()),
      ).thenAnswer((_) async => Result<void>.success(null));

      final result = await readController().saveProfile(
        nickname: 'Bob',
        avatarUrl: 'https://cdn/b.png',
      );

      expect(result.isSuccess, true);
      verify(() => userRepo.updateNickname(nickname: 'Bob')).called(1);
      verify(() => userRepo.updateAvatar('https://cdn/b.png')).called(1);
    });

    test('updates nickname with profile intro together', () async {
      when(
        () => userRepo.updateNickname(
          nickname: any(named: 'nickname'),
          profile: any(named: 'profile'),
        ),
      ).thenAnswer((_) async => Result<void>.success(null));

      final result = await readController().saveProfile(
        nickname: 'story_user',
        bio: '热爱短剧',
      );

      expect(result.isSuccess, true);
      verify(
        () => userRepo.updateNickname(nickname: 'story_user', profile: '热爱短剧'),
      ).called(1);
    });

    test(
      'returns failure and skips avatar when nickname update fails',
      () async {
        final error = ApiError.network('boom');
        when(
          () => userRepo.updateNickname(
            nickname: any(named: 'nickname'),
            profile: any(named: 'profile'),
          ),
        ).thenAnswer((_) async => Result<void>.failure(error));

        final result = await readController().saveProfile(
          nickname: 'Bad',
          avatarUrl: 'https://cdn/x.png',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, error);
        verify(() => userRepo.updateNickname(nickname: 'Bad')).called(1);
        verifyNever(() => userRepo.updateAvatar(any()));
      },
    );
  });

  test('refresh(force: true) updates the account trust value', () async {
    await container.read(authControllerProvider.notifier).setToken('jwt');
    when(() => userRepo.getProfile(forceRefresh: true)).thenAnswer(
      (_) async => Result<UserProfile>.success(
        const UserProfile(userId: 'user1', trust: 0.5),
      ),
    );

    await readController().refresh(force: true);

    final profile = container.read(profileControllerProvider).user;
    expect(profile?.trust, 0.5);
    expect(profile?.isRiskAccount, isTrue);
    verify(() => userRepo.getProfile(forceRefresh: true)).called(1);
  });
}
