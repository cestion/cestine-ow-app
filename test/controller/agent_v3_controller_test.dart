import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/agent_v3_controller.dart';
import 'package:story_app/src/controller/agent_v3_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/story_env.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/mining_repository.dart';
import 'package:story_app/src/repositories/reward_repository.dart';
import 'package:story_app/src/repositories/user_repository.dart';

class _MockMiningRepository extends Mock implements MiningRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockRewardRepository extends Mock implements RewardRepository {}

class _SeededAgentV3Controller extends AgentV3Controller {
  @override
  AgentV3State build() => const AgentV3State(
    deployedActors: [
      MiningActor(actorNftId: 'recycled-actor'),
      MiningActor(actorNftId: 'remaining-actor'),
    ],
  );
}

class _SeededRefillAgentV3Controller extends AgentV3Controller {
  @override
  AgentV3State build() => AgentV3State(
    assets: UserAssets(const [
      WalletBalance(assetCode: 'STAMINA_PACK', availableBalance: 33),
    ]),
    actorNftConfig: const InitActorNftConfig(
      staminaLimit: 168,
      levels: {'2': InitActorNftLevelConfig(staminaPackAmount: 2)},
    ),
    deployedActors: const [
      MiningActor(actorNftId: '90001_10001', level: 2, stamina: 120),
    ],
  );
}

class _SeededRestAgentV3Controller extends AgentV3Controller {
  @override
  AgentV3State build() => const AgentV3State(
    deployedActors: [
      MiningActor(actorNftId: '90001_10001', actorName: 'Actor 1'),
      MiningActor(actorNftId: '90001_10002', actorName: 'Actor 2'),
    ],
  );
}

class _SeededClaimAgentV3Controller extends AgentV3Controller {
  @override
  AgentV3State build() => AgentV3State(
    assets: UserAssets(const [
      WalletBalance(assetCode: 'STORY', availableBalance: 469),
      WalletBalance(assetCode: 'STAMINA_PACK', availableBalance: 3),
    ]),
  );
}

void main() {
  test('enables card purchases in test but keeps production blocked', () {
    const config = GlobalConfig(
      chainlinks: {
        'solana': ChainInfo(
          chainType: 'svm',
          contracts: ChainContracts(
            story: 'CJEnSe9eJ3s8qLQNdWrcHQpp6199s4NohcBBHZ3UeRQL',
          ),
        ),
      },
    );

    expect(
      isCardPurchaseContractEnabled(env: StoryEnv.test, config: config),
      isTrue,
    );
    expect(
      isCardPurchaseContractEnabled(env: StoryEnv.production, config: config),
      isFalse,
    );
  });

  test('stamina pack purchase uses the backend card type', () {
    final request = CardPurchaseOrderRequest.forType(
      walletAddress: 'wallet-address',
      type: CardPurchaseType.energyPack,
      quantity: 2,
    );

    expect(request.toJson(), {
      'walletAddress': 'wallet-address',
      'cardType': 'STAMINA_PACK',
      'quantity': 2,
    });
  });

  test('stamina pack price remains compatible with legacy config key', () {
    const config = GlobalConfig(
      init: InitConfig(
        consumableItems: {
          'ENERGY_PACK': InitConsumableItemConfig(
            price: InitConsumableItemPrice(amount: '1.25', currency: 'USDC'),
          ),
        },
      ),
    );

    expect(
      resolveCardPurchaseUnitPrice(config, CardPurchaseType.energyPack),
      '1.25',
    );
  });

  test(
    'hides a recycled actor immediately and filters stale reconciliation data',
    () async {
      final repository = _MockMiningRepository();
      var refreshCount = 0;
      when(repository.invalidateGameCache).thenAnswer((_) async {});
      when(repository.refreshDeployedActors).thenAnswer((_) async {
        refreshCount++;
        return Result.success(
          refreshCount == 1
              ? const [
                  MiningActor(actorNftId: 'recycled-actor'),
                  MiningActor(actorNftId: 'remaining-actor'),
                ]
              : const [MiningActor(actorNftId: 'remaining-actor')],
        );
      });

      final container = ProviderContainer(
        overrides: [
          miningRepositoryProvider.overrideWithValue(repository),
          agentV3ControllerProvider.overrideWith(_SeededAgentV3Controller.new),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        agentV3ControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      container
          .read(agentV3ControllerProvider.notifier)
          .markActorRecycleSubmitted(
            'recycled-actor',
            maxAttempts: 2,
            retryDelay: Duration.zero,
          );

      expect(
        container
            .read(agentV3ControllerProvider)
            .deployedActors
            .map((actor) => actor.nftId),
        ['remaining-actor'],
      );

      await pumpEventQueue(times: 10);

      expect(
        container
            .read(agentV3ControllerProvider)
            .deployedActors
            .map((actor) => actor.nftId),
        ['remaining-actor'],
      );
      verify(repository.invalidateGameCache).called(1);
      verify(repository.refreshDeployedActors).called(2);
    },
  );

  test('refills stamina and refreshes the centralized pack balance', () async {
    final miningRepository = _MockMiningRepository();
    final userRepository = _MockUserRepository();
    when(
      () =>
          miningRepository.replenishStaminaWithPack(actorNftId: '90001_10001'),
    ).thenAnswer(
      (_) async => Result.success(
        const StaminaRefillResult(
          actorNftId: '90001_10001',
          beforeStamina: 120,
          afterStamina: 168,
        ),
      ),
    );
    when(() => userRepository.getAssets(forceRefresh: true)).thenAnswer(
      (_) async => Result.success(
        UserAssets(const [
          WalletBalance(assetCode: 'STAMINA_PACK', availableBalance: 31),
        ]),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        miningRepositoryProvider.overrideWithValue(miningRepository),
        userRepositoryProvider.overrideWithValue(userRepository),
        agentV3ControllerProvider.overrideWith(
          _SeededRefillAgentV3Controller.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      agentV3ControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final result = await container
        .read(agentV3ControllerProvider.notifier)
        .refillStaminaWithPack(
          const MiningActor(actorNftId: '90001_10001', level: 2, stamina: 120),
        );

    expect(result.isSuccess, isTrue);
    final state = container.read(agentV3ControllerProvider);
    expect(state.deployedActors.single.stamina, 168);
    expect(state.assets?.staminaPack, 31);
    verify(
      () =>
          miningRepository.replenishStaminaWithPack(actorNftId: '90001_10001'),
    ).called(1);
    verify(() => userRepository.getAssets(forceRefresh: true)).called(1);
  });

  test(
    'rests one actor through the shared V2 endpoint and updates V3',
    () async {
      final miningRepository = _MockMiningRepository();
      final rewardRepository = _MockRewardRepository();
      when(
        () => miningRepository.restActor('90001_10001'),
      ).thenAnswer((_) async => Result<void>.success(null));
      when(() => rewardRepository.refreshWeeklyStats()).thenAnswer(
        (_) async =>
            Result.success(const MiningWeeklyStats(weeklyTotalOutput: 12)),
      );

      final container = ProviderContainer(
        overrides: [
          miningRepositoryProvider.overrideWithValue(miningRepository),
          rewardRepositoryProvider.overrideWithValue(rewardRepository),
          agentV3ControllerProvider.overrideWith(
            _SeededRestAgentV3Controller.new,
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        agentV3ControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final result = await container
          .read(agentV3ControllerProvider.notifier)
          .restActor(const MiningActor(actorNftId: '90001_10001'));
      await pumpEventQueue();

      expect(result.isSuccess, isTrue);
      expect(
        container
            .read(agentV3ControllerProvider)
            .deployedActors
            .map((actor) => actor.nftId),
        ['90001_10002'],
      );
      expect(
        container
            .read(agentV3ControllerProvider)
            .weeklyStats
            ?.weeklyTotalOutput,
        12,
      );
      verify(() => miningRepository.restActor('90001_10001')).called(1);
    },
  );

  test('claims STORY in place and clears the claimable balance', () async {
    final rewardRepository = _MockRewardRepository();
    final userRepository = _MockUserRepository();
    when(
      () => rewardRepository.claim(
        assetCode: 'STORY',
        amount: 469,
        toAddress: 'solana-wallet',
      ),
    ).thenAnswer(
      (_) async => Result.success(
        const WithdrawCreateResponse(orderNo: 'withdraw-order'),
      ),
    );
    when(() => userRepository.getAssets(forceRefresh: true)).thenAnswer(
      (_) async => Result.success(
        UserAssets(const [
          WalletBalance(assetCode: 'STORY', availableBalance: 0),
          WalletBalance(assetCode: 'STAMINA_PACK', availableBalance: 3),
        ]),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        rewardRepositoryProvider.overrideWithValue(rewardRepository),
        userRepositoryProvider.overrideWithValue(userRepository),
        agentV3ControllerProvider.overrideWith(
          _SeededClaimAgentV3Controller.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      agentV3ControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final result = await container
        .read(agentV3ControllerProvider.notifier)
        .claimStory(toAddress: 'solana-wallet');

    expect(result.isSuccess, isTrue);
    expect(container.read(agentV3ControllerProvider).claimableStory, 0);
    expect(container.read(agentV3ControllerProvider).assets?.staminaPack, 3);
    verify(
      () => rewardRepository.claim(
        assetCode: 'STORY',
        amount: 469,
        toAddress: 'solana-wallet',
      ),
    ).called(1);
    verify(() => userRepository.getAssets(forceRefresh: true)).called(1);
  });

  test('rests all actors through the shared V2 batch endpoint', () async {
    final miningRepository = _MockMiningRepository();
    final rewardRepository = _MockRewardRepository();
    when(
      () => miningRepository.restAllActors(),
    ).thenAnswer((_) async => Result<void>.success(null));
    when(
      () => rewardRepository.refreshWeeklyStats(),
    ).thenAnswer((_) async => Result.success(const MiningWeeklyStats()));

    final container = ProviderContainer(
      overrides: [
        miningRepositoryProvider.overrideWithValue(miningRepository),
        rewardRepositoryProvider.overrideWithValue(rewardRepository),
        agentV3ControllerProvider.overrideWith(
          _SeededRestAgentV3Controller.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      agentV3ControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final result = await container
        .read(agentV3ControllerProvider.notifier)
        .restAllActors();
    await pumpEventQueue();

    expect(result.isSuccess, isTrue);
    expect(container.read(agentV3ControllerProvider).deployedActors, isEmpty);
    verify(() => miningRepository.restAllActors()).called(1);
  });
}
