import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/drama_nft_controller.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/user_repository.dart';

class MockUserRepository extends Mock implements UserRepository {}

/// Fake AuthController for testing that provides controllable auth state.
/// Shared shape with [CreatorController]'s test fixture.
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
  late DramaNftController controller;
  late MockUserRepository userRepo;
  late FakeAuthController fakeAuth;

  setUp(() {
    userRepo = MockUserRepository();
    fakeAuth = FakeAuthController();

    // Default: empty success response with no next page.
    when(
      () => userRepo.getDramaNftPositions(mark: any(named: 'mark')),
    ).thenAnswer(
      (_) async => Result<PageDto<NftPosition>>.success(
        const PageDto(list: [], total: 0, hasMore: false),
      ),
    );

    container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(userRepo),
        authControllerProvider.overrideWith(() => fakeAuth),
      ],
    );
    controller = container.read(dramaNftControllerProvider.notifier);
    // Permanent listener prevents autoDispose during async gaps
    container.listen(dramaNftControllerProvider, (prev, next) {});
  });

  tearDown(() {
    container.dispose();
  });

  group('DramaNftController', () {
    // ─── Initial state ────────────────────────────────────────────

    test('initial state has empty nfts', () {
      final state = container.read(dramaNftControllerProvider);
      expect(state.myNfts, isEmpty);
      expect(state.hasMoreNfts, isTrue); // PaginationState default hasMore=true
      expect(state.isLoading, false);
    });

    test('can rebuild after provider invalidation', () {
      container.invalidate(dramaNftControllerProvider);

      expect(() => container.read(dramaNftControllerProvider), returnsNormally);
    });

    // ─── Success path ─────────────────────────────────────────────

    test('refresh populates myNfts list with returned items', () async {
      final nfts = [
        const NftPosition(
          id: '430203228660391936',
          dramaId: '430203228660391936',
          dramaName: '长安如梦',
          episodeCount: 33,
        ),
      ];
      when(
        () => userRepo.getDramaNftPositions(mark: any(named: 'mark')),
      ).thenAnswer(
        (_) async => Result<PageDto<NftPosition>>.success(
          PageDto(list: nfts, total: 1, hasMore: false),
        ),
      );

      await controller.refresh();

      final state = container.read(dramaNftControllerProvider);
      expect(state.myNfts.length, 1);
      expect(state.myNfts.first.dramaName, '长安如梦');
      expect(state.myNfts.first.episodeCount, 33);
      expect(state.hasMoreNfts, false);
    });

    test('removes duplicate NFT positions across cursor pages', () async {
      when(
        () => userRepo.getDramaNftPositions(mark: any(named: 'mark')),
      ).thenAnswer((invocation) async {
        final mark = invocation.namedArguments[#mark] as String?;
        if (mark == null) {
          return Result<PageDto<NftPosition>>.success(
            const PageDto(
              list: [NftPosition(id: '1', dramaId: '1', dramaName: '短剧一')],
              mark: 'next-page',
              hasMore: true,
            ),
          );
        }
        return Result<PageDto<NftPosition>>.success(
          const PageDto(
            list: [
              NftPosition(id: '1', dramaId: '1', dramaName: '短剧一'),
              NftPosition(id: '2', dramaId: '2', dramaName: '短剧二'),
            ],
            hasMore: false,
          ),
        );
      });

      await controller.refresh();
      await controller.loadMore();

      final nfts = container.read(dramaNftControllerProvider).myNfts;
      expect(nfts.map((nft) => nft.id), ['1', '2']);
    });

    test('removes identical NFT positions without an id', () async {
      const duplicate = NftPosition(dramaName: '缺少 ID 的短剧');
      when(
        () => userRepo.getDramaNftPositions(mark: any(named: 'mark')),
      ).thenAnswer(
        (_) async => Result<PageDto<NftPosition>>.success(
          const PageDto(list: [duplicate, duplicate], hasMore: false),
        ),
      );

      await controller.refresh();

      expect(container.read(dramaNftControllerProvider).myNfts, [duplicate]);
    });

    // ─── Optimistic mint ──────────────────────────────────────────

    test('prepends an optimistic mint with creator drama fields', () {
      controller.addPendingMint(
        const CreatorDrama(
          id: 'new-drama',
          title: '新铸短剧',
          description: '简介',
          coverUrl: 'https://example.com/cover.jpg',
          totalEpisodes: 12,
          createdAt: 123,
        ),
        nftContractAddress: 'wallet-address',
      );

      final optimistic = container
          .read(dramaNftControllerProvider)
          .myNfts
          .single;
      expect(optimistic.id, 'new-drama');
      expect(optimistic.dramaId, 'new-drama');
      expect(optimistic.dramaName, '新铸短剧');
      expect(optimistic.description, '简介');
      expect(optimistic.coverUrl, 'https://example.com/cover.jpg');
      expect(optimistic.episodeCount, 12);
      expect(optimistic.nftContractAddress, 'wallet-address');
      expect(optimistic.createdAt, 123);
      expect(optimistic.status, isNull);
    });

    test('keeps pending mint first when refresh response is stale', () async {
      controller.addPendingMint(
        const CreatorDrama(id: 'pending', title: '临时短剧'),
      );
      when(
        () => userRepo.getDramaNftPositions(mark: any(named: 'mark')),
      ).thenAnswer(
        (_) async => Result<PageDto<NftPosition>>.success(
          const PageDto(
            list: [
              NftPosition(
                id: 'existing',
                dramaId: 'existing',
                dramaName: '已有短剧',
              ),
            ],
            hasMore: false,
          ),
        ),
      );

      await controller.refresh();

      final nfts = container.read(dramaNftControllerProvider).myNfts;
      expect(nfts.map((nft) => nft.dramaId), ['pending', 'existing']);
    });

    test('places the newest pending mint before earlier pending mints', () {
      controller.addPendingMint(
        const CreatorDrama(id: 'first', title: '第一次铸造'),
      );
      controller.addPendingMint(
        const CreatorDrama(id: 'second', title: '第二次铸造'),
      );

      final nfts = container.read(dramaNftControllerProvider).myNfts;
      expect(nfts.map((nft) => nft.dramaId), ['second', 'first']);
    });

    test('replaces pending mint when server returns the same drama', () async {
      controller.addPendingMint(
        const CreatorDrama(id: 'minted', title: '临时标题'),
      );
      const serverNft = NftPosition(
        id: 'minted',
        dramaId: 'minted',
        dramaName: '服务端标题',
        nftContractAddress: 'server-contract',
      );
      when(
        () => userRepo.getDramaNftPositions(mark: any(named: 'mark')),
      ).thenAnswer(
        (_) async => Result<PageDto<NftPosition>>.success(
          const PageDto(list: [serverNft], hasMore: false),
        ),
      );

      await controller.refresh();

      final nfts = container.read(dramaNftControllerProvider).myNfts;
      expect(nfts, [serverNft]);
    });

    // ─── Error handling ───────────────────────────────────────────

    test('fetchPage failure sets lastError and keeps myNfts empty', () async {
      when(
        () => userRepo.getDramaNftPositions(mark: any(named: 'mark')),
      ).thenAnswer(
        (_) async => Result<PageDto<NftPosition>>.failure(
          ApiError.network('nft failed'),
        ),
      );

      await controller.refresh();

      final state = container.read(dramaNftControllerProvider);
      expect(state.myNfts, isEmpty);
      expect(state.errorMessage, isNotEmpty);
      expect(state.isLoading, false);
    });

    // ─── Auth-dependent: cache clear on logout ────────────────────

    test('clears pagination when auth state changes to logged out', () async {
      final nfts = [
        const NftPosition(id: '1', dramaId: '1', dramaName: '长安如梦'),
      ];
      when(
        () => userRepo.getDramaNftPositions(mark: any(named: 'mark')),
      ).thenAnswer(
        (_) async => Result<PageDto<NftPosition>>.success(
          PageDto(list: nfts, total: 1, hasMore: false),
        ),
      );

      await controller.refresh();
      expect(container.read(dramaNftControllerProvider).myNfts, isNotEmpty);

      // Simulate logout via auth state stream
      fakeAuth.emitAuthChange(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(dramaNftControllerProvider);
      expect(state.myNfts, isEmpty);
    });

    test('does not clear data on login event (authState = true)', () async {
      final nfts = [
        const NftPosition(id: '1', dramaId: '1', dramaName: '长安如梦'),
      ];
      when(
        () => userRepo.getDramaNftPositions(mark: any(named: 'mark')),
      ).thenAnswer(
        (_) async => Result<PageDto<NftPosition>>.success(
          PageDto(list: nfts, total: 1, hasMore: false),
        ),
      );

      await controller.refresh();
      expect(container.read(dramaNftControllerProvider).myNfts.length, 1);

      // Login event should NOT clear data
      fakeAuth.emitAuthChange(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(dramaNftControllerProvider).myNfts.length, 1);
    });

    // ─── Dispose ─────────────────────────────────────────────────

    test(
      'dispose triggers ref.onDispose and closes cleanly without error',
      () async {
        final nfts = [
          const NftPosition(id: '1', dramaId: '1', dramaName: '长安如梦'),
        ];
        when(
          () => userRepo.getDramaNftPositions(mark: any(named: 'mark')),
        ).thenAnswer(
          (_) async => Result<PageDto<NftPosition>>.success(
            PageDto(list: nfts, total: 1, hasMore: false),
          ),
        );

        await controller.refresh();
        expect(container.read(dramaNftControllerProvider).myNfts.length, 1);

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
