import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/game_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/agent_v2_config_repository.dart';
import 'package:story_app/src/repositories/mining_repository.dart';
import 'package:story_app/src/repositories/reward_repository.dart';
import 'package:story_app/src/services/sponsor_service.dart';
import 'package:story_app/src/services/wallet_ledger.dart';

class MockMiningRepository extends Mock implements MiningRepository {}

class MockRewardRepository extends Mock implements RewardRepository {}

class MockAgentV2ConfigRepository extends Mock
    implements AgentV2ConfigRepository {}

class MockSponsorService extends Mock implements SponsorService {}

class FakeSponsorRefillParams extends Fake
    implements SponsorRefillActorStaminaParams {}

class TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
    ready: true,
    isLoggedIn: true,
    solanaAddress: 'wallet-address',
  );
}

MiningActor _actor({
  String nftId = 'nft-1',
  String name = 'Actor 1',
  int level = 1,
  String status = 'REST',
  int? stamina,
  int? actorCollectionId,
  int? actorTokenId,
}) {
  return MiningActor(
    actorNftId: nftId,
    actorName: name,
    level: level,
    status: status,
    stamina: stamina,
    actorCollectionId: actorCollectionId,
    actorTokenId: actorTokenId,
  );
}

MiningActorPage _page({
  required List<MiningActor> records,
  int pageNumber = 1,
  int totalPage = 1,
  int totalRow = 0,
}) {
  return MiningActorPage(
    records: records,
    pageNumber: pageNumber,
    pageSize: gameMyActorsPageSize,
    totalPage: totalPage,
    totalRow: totalRow == 0 ? records.length : totalRow,
  );
}

ProviderContainer _createContainer({
  required MockMiningRepository miningRepo,
  required MockRewardRepository rewardRepo,
  AgentV2ConfigRepository? configRepo,
}) {
  return ProviderContainer(
    overrides: [
      miningRepositoryProvider.overrideWithValue(miningRepo),
      rewardRepositoryProvider.overrideWithValue(rewardRepo),
      if (configRepo != null)
        agentV2ConfigRepositoryProvider.overrideWithValue(configRepo),
    ],
  );
}

void _stubRefreshSuccess({
  required MockMiningRepository miningRepo,
  required MockRewardRepository rewardRepo,
  List<MiningActor> deployed = const [],
  MiningActorPage? actorsPage,
  MiningWeeklyStats? weekly,
}) {
  when(
    () => miningRepo.listDeployedActors(),
  ).thenAnswer((_) async => Result.success(deployed));
  when(
    () => miningRepo.listAllActors(
      sort: any(named: 'sort'),
      pageNum: any(named: 'pageNum'),
      pageSize: any(named: 'pageSize'),
    ),
  ).thenAnswer(
    (_) async => Result.success(actorsPage ?? _page(records: const [])),
  );
  when(() => rewardRepo.getWeeklyStats()).thenAnswer(
    (_) async => Result.success(
      weekly ?? const MiningWeeklyStats(weeklyTotalOutput: 10),
    ),
  );
}

void main() {
  late MockMiningRepository miningRepo;
  late MockRewardRepository rewardRepo;

  setUpAll(() {
    registerFallbackValue(FakeSponsorRefillParams());
  });

  setUp(() {
    miningRepo = MockMiningRepository();
    rewardRepo = MockRewardRepository();

    when(() => miningRepo.dispose()).thenAnswer((_) async {});
    when(() => rewardRepo.dispose()).thenAnswer((_) async {});
    when(() => miningRepo.invalidateGameCache()).thenAnswer((_) async {});
    when(
      () => rewardRepo.invalidateWeeklyStatsCache(),
    ).thenAnswer((_) async {});
    when(
      () => miningRepo.refreshRestActors(
        pageNum: any(named: 'pageNum'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => Result.success(_page(records: const [])));
  });

  group('GameController', () {
    test('initial state is empty', () {
      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      final state = container.read(gameControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.myActors, isEmpty);
      expect(state.deployedActors, isEmpty);
      expect(state.sort, GameActorSort.computingPower);
      expect(state.staminaLimit, defaultGameStaminaLimit);
    });

    test('can rebuild after provider invalidation', () {
      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      container.read(gameControllerProvider);
      container.invalidate(gameControllerProvider);

      expect(() => container.read(gameControllerProvider), returnsNormally);
    });

    test(
      'refresh() populates deployed actors, my actors, and weekly stats',
      () async {
        final deployed = [_actor(nftId: 'd1', status: 'MINING')];
        final myActors = [_actor(nftId: 'a1'), _actor(nftId: 'a2')];
        _stubRefreshSuccess(
          miningRepo: miningRepo,
          rewardRepo: rewardRepo,
          deployed: deployed,
          actorsPage: _page(records: myActors, totalPage: 2, totalRow: 2),
          weekly: const MiningWeeklyStats(weeklyTotalOutput: 42),
        );

        final container = _createContainer(
          miningRepo: miningRepo,
          rewardRepo: rewardRepo,
        );
        addTearDown(container.dispose);
        container.listen(gameControllerProvider, (_, _) {});

        await container.read(gameControllerProvider.notifier).refresh();

        final state = container.read(gameControllerProvider);
        expect(state.isLoading, isFalse);
        expect(state.deployedActors, hasLength(1));
        expect(state.myActors, hasLength(2));
        expect(state.weeklyStats?.weeklyTotalOutput, 42);
        expect(state.hasMore, isTrue);
        expect(state.lastError, isNull);
      },
    );

    test('refresh(force: true) invalidates caches before fetching', () async {
      _stubRefreshSuccess(miningRepo: miningRepo, rewardRepo: rewardRepo);

      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      await container
          .read(gameControllerProvider.notifier)
          .refresh(force: true);

      verify(() => miningRepo.invalidateGameCache()).called(1);
      verify(() => rewardRepo.invalidateWeeklyStatsCache()).called(1);
    });

    test('refresh() keeps partial data when only weekly stats fails', () async {
      final deployed = [_actor(nftId: 'd1')];
      final myActors = [_actor(nftId: 'a1')];
      when(
        () => miningRepo.listDeployedActors(),
      ).thenAnswer((_) async => Result.success(deployed));
      when(
        () => miningRepo.listAllActors(
          sort: any(named: 'sort'),
          pageNum: any(named: 'pageNum'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => Result.success(_page(records: myActors)));
      when(
        () => rewardRepo.getWeeklyStats(),
      ).thenAnswer((_) async => Result.failure(ApiError.network('offline')));

      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      await container.read(gameControllerProvider.notifier).refresh();

      final state = container.read(gameControllerProvider);
      expect(state.deployedActors, hasLength(1));
      expect(state.myActors, hasLength(1));
      expect(state.lastError, isA<ApiError>());
    });

    test(
      'refreshAgentV2Config() resolves stamina limit from agent V2 config',
      () async {
        const config = GlobalConfig(
          init: InitConfig(actorNft: InitActorNftConfig(staminaLimit: 200)),
        );
        final configRepo = MockAgentV2ConfigRepository();
        when(() => configRepo.readCachedConfig()).thenReturn(null);
        when(
          () => configRepo.fetchLatestConfig(),
        ).thenAnswer((_) async => Result.success(config));

        final container = _createContainer(
          miningRepo: miningRepo,
          rewardRepo: rewardRepo,
          configRepo: configRepo,
        );
        addTearDown(container.dispose);
        container.listen(gameControllerProvider, (_, _) {});

        final controller = container.read(gameControllerProvider.notifier);
        await controller.refreshAgentV2Config();

        final state = container.read(gameControllerProvider);
        expect(state.staminaLimit, 200);
        expect(state.agentV2Config, isNotNull);
        expect(state.agentV2ConfigError, isNull);
      },
    );

    test('setSort() reloads actors with new sort', () async {
      final levelActors = [_actor(nftId: 'a1', level: 5)];
      when(
        () => miningRepo.listAllActors(
          sort: 'LEVEL',
          pageNum: any(named: 'pageNum'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => Result.success(_page(records: levelActors)));
      when(
        () => miningRepo.listAllActors(
          sort: 'HEAT',
          pageNum: any(named: 'pageNum'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => Result.success(_page(records: [_actor(nftId: 'a2')])),
      );

      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      await container
          .read(gameControllerProvider.notifier)
          .setSort(GameActorSort.heat);

      final state = container.read(gameControllerProvider);
      expect(state.sort, GameActorSort.heat);
      expect(state.myActors.single.nftId, 'a2');
      expect(state.isRefreshingList, isFalse);
    });

    test('setSort() is no-op when sort unchanged', () async {
      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      await container
          .read(gameControllerProvider.notifier)
          .setSort(GameActorSort.computingPower);

      verifyNever(
        () => miningRepo.listAllActors(
          sort: any(named: 'sort'),
          pageNum: any(named: 'pageNum'),
          pageSize: any(named: 'pageSize'),
        ),
      );
    });

    test('loadMore() appends actors and deduplicates by nftId', () async {
      when(
        () => miningRepo.listDeployedActors(),
      ).thenAnswer((_) async => Result.success(<MiningActor>[]));
      when(
        () => rewardRepo.getWeeklyStats(),
      ).thenAnswer((_) async => Result.success(const MiningWeeklyStats()));
      when(
        () => miningRepo.listAllActors(
          sort: 'COMPUTING_POWER',
          pageSize: gameMyActorsPageSize,
        ),
      ).thenAnswer(
        (_) async => Result.success(
          _page(
            records: [
              _actor(nftId: 'a1'),
              _actor(nftId: 'a2'),
            ],
            totalPage: 2,
            totalRow: 3,
          ),
        ),
      );
      when(
        () => miningRepo.listAllActors(
          sort: 'COMPUTING_POWER',
          pageNum: 2,
          pageSize: gameMyActorsPageSize,
        ),
      ).thenAnswer(
        (_) async => Result.success(
          _page(
            records: [
              _actor(nftId: 'a2'),
              _actor(nftId: 'a3'),
            ],
            pageNumber: 2,
            totalPage: 2,
            totalRow: 3,
          ),
        ),
      );

      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      final controller = container.read(gameControllerProvider.notifier);
      await controller.refresh();
      await controller.loadMore();

      final state = container.read(gameControllerProvider);
      expect(state.myActors.map((a) => a.nftId), ['a1', 'a2', 'a3']);
      expect(state.currentPage, 2);
      expect(state.hasMore, isFalse);
    });

    test('loadMore() is no-op when hasMore is false', () async {
      when(
        () => miningRepo.listDeployedActors(),
      ).thenAnswer((_) async => Result.success(<MiningActor>[]));
      when(
        () => rewardRepo.getWeeklyStats(),
      ).thenAnswer((_) async => Result.success(const MiningWeeklyStats()));
      when(
        () => miningRepo.listAllActors(
          sort: any(named: 'sort'),
          pageNum: any(named: 'pageNum'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => Result.success(_page(records: [_actor(nftId: 'a1')])),
      );

      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      await container.read(gameControllerProvider.notifier).refresh();
      await container.read(gameControllerProvider.notifier).loadMore();

      verify(
        () => miningRepo.listAllActors(
          sort: any(named: 'sort'),
          pageNum: any(named: 'pageNum'),
          pageSize: any(named: 'pageSize'),
        ),
      ).called(1);
    });

    test('deploy() returns false when deploy slots are full', () async {
      final deployed = List.generate(
        gameDeploySlotCount,
        (i) => _actor(nftId: 'd$i', status: 'MINING'),
      );
      _stubRefreshSuccess(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
        deployed: deployed,
      );

      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      await container.read(gameControllerProvider.notifier).refresh();

      final ok = await container
          .read(gameControllerProvider.notifier)
          .deploy('new-nft');

      expect(ok, isFalse);
      verifyNever(() => miningRepo.deployActor(any()));
    });

    test('deploy() succeeds and refreshes data', () async {
      _stubRefreshSuccess(miningRepo: miningRepo, rewardRepo: rewardRepo);
      when(
        () => miningRepo.deployActor('nft-new'),
      ).thenAnswer((_) async => Result.success(null));

      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      final ok = await container
          .read(gameControllerProvider.notifier)
          .deploy('nft-new');

      expect(ok, isTrue);
      verify(() => miningRepo.deployActor('nft-new')).called(1);
      verify(() => miningRepo.listDeployedActors()).called(1);
    });

    test('deploy() sets lastError on failure', () async {
      when(() => miningRepo.deployActor('nft-new')).thenAnswer(
        (_) async => Result.failure(ApiError.business(1, 'deploy failed')),
      );

      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      final ok = await container
          .read(gameControllerProvider.notifier)
          .deploy('nft-new');

      expect(ok, isFalse);
      expect(container.read(gameControllerProvider).lastError, isA<ApiError>());
    });

    test('rest() succeeds and refreshes data', () async {
      _stubRefreshSuccess(miningRepo: miningRepo, rewardRepo: rewardRepo);
      when(
        () => miningRepo.restActor('nft-1'),
      ).thenAnswer((_) async => Result.success(null));

      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      final ok = await container
          .read(gameControllerProvider.notifier)
          .rest('nft-1');

      expect(ok, isTrue);
      verify(() => miningRepo.restActor('nft-1')).called(1);
    });

    test(
      'replenish keeps full stamina when an immediate refresh is stale',
      () async {
        final actor = _actor(
          status: 'MINING',
          stamina: 12,
          actorCollectionId: 7,
          actorTokenId: 9,
        );
        _stubRefreshSuccess(
          miningRepo: miningRepo,
          rewardRepo: rewardRepo,
          deployed: [actor],
          actorsPage: _page(records: [actor]),
        );
        when(
          () => miningRepo.replenishStamina(
            actorNftId: actor.nftId,
            payAmount: 1,
            walletAddress: 'wallet-address',
          ),
        ).thenAnswer(
          (_) async => Result.success(
            const ReplenishResult(
              orderNo: 'order-1',
              canonicalPayload: 'payload',
              sig: 'signature',
              payToken: 'usdc-mint',
            ),
          ),
        );

        final sponsor = MockSponsorService();
        when(
          () => sponsor.submitSponsorRefillActorStamina(any()),
        ).thenAnswer((_) async => Result.success('transaction-signature'));

        const config = GlobalConfig(
          chainlinks: {
            'solana': ChainInfo(
              chainType: 'svm',
              contracts: ChainContracts(
                spender: 'spender',
                story: 'story-program',
                storyDelegator: 'delegator',
                storyTreasury: 'treasury',
              ),
              rpc: ChainRpc(http: 'https://rpc.example'),
            ),
          },
          init: InitConfig(
            deposit: [
              InitDepositConfig(
                chain: 'solana',
                api: 'https://sponsor.example',
              ),
            ],
            withdraw: [
              InitWithdrawConfig(
                chain: 'solana',
                tokens: [InitWithdrawTokenConfig(symbol: 'USDC')],
              ),
            ],
            actorNft: InitActorNftConfig(
              staminaLimit: 168,
              levels: {'1': InitActorNftLevelConfig(supplyFee: 1)},
            ),
          ),
        );
        final configRepo = MockAgentV2ConfigRepository();
        when(() => configRepo.readCachedConfig()).thenReturn(null);
        when(
          () => configRepo.fetchLatestConfig(),
        ).thenAnswer((_) async => Result.success(config));
        final container = ProviderContainer(
          overrides: [
            miningRepositoryProvider.overrideWithValue(miningRepo),
            rewardRepositoryProvider.overrideWithValue(rewardRepo),
            sponsorServiceProvider.overrideWithValue(sponsor),
            authControllerProvider.overrideWith(TestAuthController.new),
            agentV2ConfigRepositoryProvider.overrideWithValue(configRepo),
            walletLedgerProvider.overrideWithValue(
              WalletLedger(
                WalletSpendPort(
                  ensureUsdc: (_) async => Result.success(null),
                  ensureStory: (_) async => Result.success(null),
                  deduct: ({double usdc = 0, double story = 0}) {},
                  refresh: () async {},
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(gameControllerProvider, (_, _) {});

        final controller = container.read(gameControllerProvider.notifier);
        await controller.refresh();

        final ok = await controller.replenishStamina(actor);
        expect(ok, isTrue);
        expect(
          container.read(gameControllerProvider).deployedActors.single.stamina,
          168,
        );

        // The indexer still returns the pre-transaction value.
        await controller.refresh(force: true);

        final state = container.read(gameControllerProvider);
        expect(state.deployedActors.single.stamina, 168);
        expect(state.myActors.single.stamina, 168);
      },
    );

    test('getUpgradeMaterials() returns materials on success', () async {
      const materials = [ActorUpgradeMaterial(actorId: 'burn-1')];
      when(
        () => miningRepo.getUpgradeMaterials(actorNftId: 'nft-1'),
      ).thenAnswer((_) async => Result.success(materials));

      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      final result = await container
          .read(gameControllerProvider.notifier)
          .getUpgradeMaterials('nft-1');

      expect(result, materials);
    });

    test('getUpgradeMaterials() sets lastError on failure', () async {
      when(
        () => miningRepo.getUpgradeMaterials(actorNftId: 'nft-1'),
      ).thenAnswer((_) async => Result.failure(ApiError.network('offline')));

      final container = _createContainer(
        miningRepo: miningRepo,
        rewardRepo: rewardRepo,
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider, (_, _) {});

      final result = await container
          .read(gameControllerProvider.notifier)
          .getUpgradeMaterials('nft-1');

      expect(result, isEmpty);
      expect(container.read(gameControllerProvider).lastError, isA<ApiError>());
    });
  });

  group('mergeMiningActors', () {
    test('deduplicates by nftId preserving first occurrence order', () {
      final existing = [_actor(nftId: 'a1'), _actor(nftId: 'a2')];
      final incoming = [_actor(nftId: 'a2'), _actor(nftId: 'a3')];

      final merged = mergeMiningActors(existing, incoming);

      expect(merged.map((a) => a.nftId), ['a1', 'a2', 'a3']);
    });
  });
}
