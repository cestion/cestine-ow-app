import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/income_controller.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/reward_repository.dart';
import 'package:story_app/src/repositories/user_repository.dart';

class MockRewardRepository extends Mock implements RewardRepository {}

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
  late IncomeController controller;
  late MockRewardRepository rewardRepo;
  late FakeAuthController fakeAuth;
  late MockUserRepository mockUser;

  setUp(() {
    rewardRepo = MockRewardRepository();
    fakeAuth = FakeAuthController();
    mockUser = MockUserRepository();

    registerFallbackValue(ListRewardDetailsFilter.all);

    when(
      () => rewardRepo.getTotalReward(),
    ).thenAnswer((_) async => Result<TotalReward>.success(const TotalReward()));
    when(
      () => rewardRepo.getUsdcIncome(
        mark: any(named: 'mark'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer(
      (_) async => Result<UsdcIncomePage>.success(const UsdcIncomePage()),
    );
    when(
      () => rewardRepo.listRewardDetails(
        type: any(named: 'type'),
        mark: any(named: 'mark'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer(
      (_) async => Result<RewardDetailPage>.success(const RewardDetailPage()),
    );
    when(
      () => mockUser.getBalances(),
    ).thenAnswer((_) async => Result<List<WalletBalance>>.success([]));
    when(() => rewardRepo.getWeeklyStats()).thenAnswer(
      (_) async => Result<MiningWeeklyStats>.success(const MiningWeeklyStats()),
    );
    when(() => rewardRepo.getSettlingReward()).thenAnswer(
      (_) async => Result<SettlingReward>.success(const SettlingReward()),
    );

    container = ProviderContainer(
      overrides: [
        rewardRepositoryProvider.overrideWithValue(rewardRepo),
        authControllerProvider.overrideWith(() => fakeAuth),
        userRepositoryProvider.overrideWithValue(mockUser),
      ],
    );
    controller = container.read(incomeControllerProvider.notifier);
    container.listen(incomeControllerProvider, (prev, next) {});
  });

  tearDown(() {
    container.dispose();
  });

  group('IncomeController', () {
    test('initial state has empty fields and is not loading', () {
      expect(controller.isLoading, false);
      expect(controller.errorMessage, '');
    });

    test('refresh does nothing when not logged in', () async {
      fakeAuth.setLoggedIn(false);

      await controller.refresh();

      verifyNever(() => rewardRepo.getTotalReward());
      verifyNever(
        () => rewardRepo.getUsdcIncome(
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
        ),
      );
      verifyNever(
        () => rewardRepo.listRewardDetails(
          type: any(named: 'type'),
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
        ),
      );
    });

    test(
      'refresh populates totalReward, usdcIncome, rewardDetails on success',
      () async {
        const totalReward = TotalReward(
          totalMiningReward: 100.0,
          totalInviteReward: 50.0,
        );
        const usdcPage = UsdcIncomePage(
          total: '200.5',
          list: [UsdcIncomeItem(id: 'u1', amount: '10.5', actorName: 'Nova')],
        );
        const rewardPage = RewardDetailPage(
          list: [
            RewardDetail(
              rewardTime: '1735689600000',
              type: RewardDetailType.mining,
              storyAmount: 1.25,
            ),
          ],
        );
        final balances = [
          const WalletBalance(assetCode: 'STORY', availableBalance: 12.34),
          const WalletBalance(assetCode: 'USDC', availableBalance: 56.78),
        ];

        when(
          () => rewardRepo.getTotalReward(),
        ).thenAnswer((_) async => Result<TotalReward>.success(totalReward));
        when(
          () => rewardRepo.getUsdcIncome(
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => Result<UsdcIncomePage>.success(usdcPage));
        when(
          () => rewardRepo.listRewardDetails(
            type: any(named: 'type'),
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => Result<RewardDetailPage>.success(rewardPage));
        when(() => mockUser.getBalances()).thenAnswer(
          (_) async => Result<List<WalletBalance>>.success(balances),
        );
        const weeklyStats = MiningWeeklyStats(weekInvitePool: 500.0);
        when(() => rewardRepo.getWeeklyStats()).thenAnswer(
          (_) async => Result<MiningWeeklyStats>.success(weeklyStats),
        );

        await controller.refresh();

        final state = container.read(incomeControllerProvider);
        expect(state.totalStoryEarnings, 150.0);
        expect(state.totalUsdcEarnings, 200.5);
        expect(state.storyRecords.length, 1);
        expect(state.usdcRecords.length, 1);
        expect(state.storyBalance, 12.34);
        expect(state.usdcBalance, 56.78);
        expect(state.weeklyStats?.weekInvitePool, 500.0);
      },
    );

    test('isLoading is false after refresh completes', () async {
      await controller.refresh();
      expect(controller.isLoading, false);
    });

    test('loadMoreRewardDetails appends the next STORY page', () async {
      const firstPage = RewardDetailPage(
        mark: '20',
        hasMore: true,
        list: [
          RewardDetail(
            rewardTime: '1',
            type: RewardDetailType.mining,
            storyAmount: 1,
          ),
        ],
      );
      const nextPage = RewardDetailPage(
        mark: '40',
        hasMore: false,
        list: [
          RewardDetail(
            rewardTime: '2',
            type: RewardDetailType.mining,
            storyAmount: 2,
          ),
        ],
      );
      when(
        () => rewardRepo.listRewardDetails(
          type: any(named: 'type'),
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => Result<RewardDetailPage>.success(firstPage));
      when(
        () => rewardRepo.listRewardDetails(
          type: ListRewardDetailsFilter.mining,
          mark: 20,
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => Result<RewardDetailPage>.success(nextPage));

      await controller.refresh();
      await controller.loadMoreRewardDetails(
        type: ListRewardDetailsFilter.mining,
      );

      final state = container.read(incomeControllerProvider);
      expect(state.storyRecords.map((item) => item.rewardTime), ['1', '2']);
      expect(state.rewardDetailPage?.mark, '40');
      expect(state.hasMoreStoryRecords, false);
      expect(state.isStoryPageLoading, false);
    });

    test('loadMoreUsdcIncome appends the next USDC page', () async {
      const firstPage = UsdcIncomePage(
        total: '30',
        mark: '20',
        hasMore: true,
        list: [UsdcIncomeItem(id: 'u1', amount: '10')],
      );
      const nextPage = UsdcIncomePage(
        mark: '40',
        hasMore: false,
        list: [UsdcIncomeItem(id: 'u2', amount: '20')],
      );
      when(
        () => rewardRepo.getUsdcIncome(
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => Result<UsdcIncomePage>.success(firstPage));
      when(
        () => rewardRepo.getUsdcIncome(
          mark: 20,
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => Result<UsdcIncomePage>.success(nextPage));

      await controller.refresh();
      await controller.loadMoreUsdcIncome();

      final state = container.read(incomeControllerProvider);
      expect(state.usdcRecords.map((item) => item.id), ['u1', 'u2']);
      expect(state.usdcIncomePage?.total, '30');
      expect(state.usdcIncomePage?.mark, '40');
      expect(state.hasMoreUsdcRecords, false);
      expect(state.isUsdcPageLoading, false);
    });

    test(
      'totalReward stays null when getTotalReward returns failure',
      () async {
        when(() => rewardRepo.getTotalReward()).thenAnswer(
          (_) async => Result<TotalReward>.failure(
            ApiError.network('totalReward failed'),
          ),
        );

        await controller.refresh();

        final state = container.read(incomeControllerProvider);
        expect(state.totalReward, isNull);
        expect(controller.isLoading, false);
      },
    );

    test('errorMessage is set when refresh throws an exception', () async {
      when(
        () => rewardRepo.getTotalReward(),
      ).thenThrow(Exception('network crash'));

      await controller.refresh();

      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNotEmpty);
    });

    test('clears state when auth changes to logged out', () async {
      const totalReward = TotalReward(totalMiningReward: 99.0);
      when(
        () => rewardRepo.getTotalReward(),
      ).thenAnswer((_) async => Result<TotalReward>.success(totalReward));

      await controller.refresh();
      expect(container.read(incomeControllerProvider).totalStoryEarnings, 99.0);

      fakeAuth.emitAuthChange(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(incomeControllerProvider).totalReward, isNull);
    });

    test('does not clear data on login event', () async {
      const totalReward = TotalReward(totalMiningReward: 50.0);
      when(
        () => rewardRepo.getTotalReward(),
      ).thenAnswer((_) async => Result<TotalReward>.success(totalReward));

      await controller.refresh();
      expect(container.read(incomeControllerProvider).totalStoryEarnings, 50.0);

      fakeAuth.emitAuthChange(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(incomeControllerProvider).totalStoryEarnings, 50.0);
    });

    test('dispose triggers ref.onDispose cleanly', () async {
      when(() => rewardRepo.getTotalReward()).thenAnswer(
        (_) async => Result<TotalReward>.success(
          const TotalReward(totalMiningReward: 1.0),
        ),
      );

      await controller.refresh();
      expect(() => container.dispose(), returnsNormally);

      fakeAuth.emitAuthChange(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
  });
}
