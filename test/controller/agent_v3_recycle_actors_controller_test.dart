import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/agent_v3_recycle_actors_controller.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/config_repository.dart';
import 'package:story_app/src/repositories/mining_repository.dart';

class _MockMiningRepository extends Mock implements MiningRepository {}

class _MockConfigRepository extends Mock implements ConfigRepository {}

class _LoggedInAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
    ready: true,
    isLoggedIn: true,
    token: 'token',
    solanaAddress: 'wallet-address',
  );
}

void main() {
  test(
    'refreshes and paginates recycle actors with the requested query',
    () async {
      final repository = _MockMiningRepository();
      const firstActor = MiningActor(actorNftId: 'actor-1');
      const secondActor = MiningActor(actorNftId: 'actor-2');
      when(
        () => repository.refreshAllActors(
          sort: 'COMPUTING_POWER',
          pageSize: agentV3RecycleActorsPageSize,
        ),
      ).thenAnswer(
        (_) async => Result.success(
          const MiningActorPage(
            records: [firstActor],
            pageSize: agentV3RecycleActorsPageSize,
            totalPage: 2,
            totalRow: 2,
          ),
        ),
      );
      when(
        () => repository.listAllActors(
          sort: 'COMPUTING_POWER',
          pageNum: 2,
          pageSize: agentV3RecycleActorsPageSize,
        ),
      ).thenAnswer(
        (_) async => Result.success(
          const MiningActorPage(
            records: [secondActor],
            pageNumber: 2,
            pageSize: agentV3RecycleActorsPageSize,
            totalPage: 2,
            totalRow: 2,
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [miningRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        agentV3RecycleActorsControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final controller = container.read(
        agentV3RecycleActorsControllerProvider.notifier,
      );
      await controller.refresh();
      await controller.loadMore();

      final state = container.read(agentV3RecycleActorsControllerProvider);
      expect(state.actors, const [firstActor, secondActor]);
      expect(state.currentPage, 2);
      expect(state.hasMore, isFalse);
      verify(
        () =>
            repository.refreshAllActors(sort: 'COMPUTING_POWER', pageSize: 20),
      ).called(1);
      verify(
        () => repository.listAllActors(
          sort: 'COMPUTING_POWER',
          pageNum: 2,
          pageSize: 20,
        ),
      ).called(1);
    },
  );

  test('loads an estimate for the selected NFT address', () async {
    final repository = _MockMiningRepository();
    const actor = MiningActor(actorNftId: 'actor-nft-address');
    const estimate = ActorNftRecycleEstimateResponse(
      actorCollectionId: '90001',
      tokenId: '10001',
      assetId: '90001_10001',
      refundUsdcAmount: '80.0',
      refundAmountMinor: '80000000',
      refundTrainingManual: '4',
    );
    when(
      () => repository.getActorNftRecycleEstimate(
        nftAddress: 'actor-nft-address',
      ),
    ).thenAnswer((_) async => Result.success(estimate));

    final container = ProviderContainer(
      overrides: [miningRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(agentV3RecycleActorsControllerProvider.notifier)
        .getRecycleEstimate(actor);

    expect(result.dataOrNull, estimate);
    verify(
      () => repository.getActorNftRecycleEstimate(
        nftAddress: 'actor-nft-address',
      ),
    ).called(1);
  });

  test('rejects a recycle order whose signature payload changed', () async {
    final repository = _MockMiningRepository();
    final configRepository = _MockConfigRepository();
    const actor = MiningActor(actorNftId: 'actor-nft-address');
    const estimate = ActorNftRecycleEstimateResponse(
      actorCollectionId: '90001',
      tokenId: '10001',
      assetId: '90001_10001',
      refundUsdcAmount: '80.0',
      refundAmountMinor: '80000000',
      refundTrainingManual: '4',
    );
    final expiresAt = (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300)
        .toString();
    when(() => configRepository.getGlobalConfig(forceRefresh: true)).thenAnswer(
      (_) async => Result.success(
        const GlobalConfig(
          chainlinks: {
            'solana': ChainInfo(
              chainType: 'svm',
              rpc: ChainRpc(http: 'https://rpc.example.com'),
              contracts: ChainContracts(
                story: 'story-program',
                storyDelegator: 'delegator',
                spender: 'spender',
              ),
              tokens: {
                'USDC': WalletToken(symbol: 'USDC', address: 'usdc-mint'),
              },
            ),
          },
        ),
      ),
    );
    when(
      () => repository.createActorNftRecycleOrder(
        toAddress: 'wallet-address',
        nftAddress: 'actor-nft-address',
      ),
    ).thenAnswer(
      (_) async => Result.success(
        ActorNftRecycleOrderResponse(
          sig: 'signature',
          expiresAt: expiresAt,
          orderNo: 'order-1',
          assetId: '90001_10001',
          refundAmountMinor: '80000000',
          refundUsdcAmount: '80.0',
          refundTrainingManual: '4',
          payload:
              'actor_nft_burn|90001_10001|another-wallet|80000000|order-1|$expiresAt',
        ),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        miningRepositoryProvider.overrideWithValue(repository),
        configRepositoryProvider.overrideWithValue(configRepository),
        authControllerProvider.overrideWith(_LoggedInAuthController.new),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(agentV3RecycleActorsControllerProvider.notifier)
        .recycleActor(actor: actor, estimate: estimate);

    expect(result.isFailure, isTrue);
    expect(
      container
          .read(agentV3RecycleActorsControllerProvider)
          .recyclingActorNftId,
      isNull,
    );
    verify(
      () => repository.createActorNftRecycleOrder(
        toAddress: 'wallet-address',
        nftAddress: 'actor-nft-address',
      ),
    ).called(1);
  });
}
