import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/wallet_balance_errors.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/services/evm/evm_token_balance_service.dart';
import 'package:story_app/src/services/solana/solana_token_balance_service.dart';

class MockLocalRepo extends Mock implements StoryLocalRepository {}

class MockBox extends Mock implements Box<dynamic> {}

class MockBalanceService extends Mock implements SolanaTokenBalanceService {}

class MockEvmBalanceService extends Mock implements EvmTokenBalanceService {}

void main() {
  const address = 'So11111111111111111111111111111111111111112';
  const usdcMint = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';
  const storyMint = 'Story1111111111111111111111111111111111111';

  late MockLocalRepo localRepo;
  late MockBox box;
  late MockBalanceService balanceService;
  late MockEvmBalanceService evmBalanceService;

  const chain = ChainInfo(
    chainType: 'svm',
    rpc: ChainRpc(http: 'https://api.devnet.solana.com'),
    tokens: {
      'usdc': WalletToken(address: usdcMint, symbol: 'USDC', decimals: 6),
      'story': WalletToken(address: storyMint, symbol: 'STORY', decimals: 9),
    },
  );

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        localRepositoryProvider.overrideWithValue(localRepo),
        solanaTokenBalanceServiceProvider.overrideWithValue(balanceService),
        evmTokenBalanceServiceProvider.overrideWithValue(evmBalanceService),
        // WalletBalanceNotifier._doRefresh resolves the SVM chain from the
        // global config (chainlinks), not the legacy svmChainProvider.
        globalConfigProvider.overrideWith(
          (ref) async =>
              Result.success(const GlobalConfig(chainlinks: {'solana': chain})),
        ),
      ],
    );
  }

  setUp(() {
    localRepo = MockLocalRepo();
    box = MockBox();
    balanceService = MockBalanceService();
    evmBalanceService = MockEvmBalanceService();
    when(() => localRepo.cacheBox).thenReturn(box);
    when(() => box.get(any<dynamic>())).thenReturn(null);
    when(
      () => box.put(any<dynamic>(), any<dynamic>()),
    ).thenAnswer((_) async => 0);
    when(
      () => localRepo.getSolanaWalletAddressAsync(),
    ).thenAnswer((_) async => address);
  });

  test('ensureUsdc refreshes then fails when balance is too low', () async {
    when(
      () => balanceService.getTokenBalance(
        rpcHttpUrl: any(named: 'rpcHttpUrl'),
        ownerAddress: any(named: 'ownerAddress'),
        tokenMint: usdcMint,
      ),
    ).thenAnswer((_) async => 1.5);
    when(
      () => balanceService.getTokenBalance(
        rpcHttpUrl: any(named: 'rpcHttpUrl'),
        ownerAddress: any(named: 'ownerAddress'),
        tokenMint: storyMint,
      ),
    ).thenAnswer((_) async => 0);

    final container = createContainer();
    addTearDown(container.dispose);
    container.listen(onChainWalletBalanceProvider, (_, _) {});

    final result = await container
        .read(onChainWalletBalanceProvider.notifier)
        .ensureUsdc(2);

    expect(result.isFailure, isTrue);
    expect(
      result.errorOrNull?.l10nArgs['message'],
      WalletBalanceErrorMessages.insufficientUsdc,
    );
    expect(container.read(onChainWalletBalanceProvider).usdcBalance, 1.5);
  });

  test('ensureUsdc succeeds after a fresh refresh', () async {
    when(
      () => balanceService.getTokenBalance(
        rpcHttpUrl: any(named: 'rpcHttpUrl'),
        ownerAddress: any(named: 'ownerAddress'),
        tokenMint: usdcMint,
      ),
    ).thenAnswer((_) async => 5);
    when(
      () => balanceService.getTokenBalance(
        rpcHttpUrl: any(named: 'rpcHttpUrl'),
        ownerAddress: any(named: 'ownerAddress'),
        tokenMint: storyMint,
      ),
    ).thenAnswer((_) async => 0);

    final container = createContainer();
    addTearDown(container.dispose);
    container.listen(onChainWalletBalanceProvider, (_, _) {});

    final result = await container
        .read(onChainWalletBalanceProvider.notifier)
        .ensureUsdc(2);

    expect(result.isSuccess, isTrue);
    expect(container.read(onChainWalletBalanceProvider).usdcBalance, 5);
  });

  test('refresh keeps previous balances when RPC returns null', () async {
    when(
      () => balanceService.getTokenBalance(
        rpcHttpUrl: any(named: 'rpcHttpUrl'),
        ownerAddress: any(named: 'ownerAddress'),
        tokenMint: usdcMint,
      ),
    ).thenAnswer((_) async => 752.08);
    when(
      () => balanceService.getTokenBalance(
        rpcHttpUrl: any(named: 'rpcHttpUrl'),
        ownerAddress: any(named: 'ownerAddress'),
        tokenMint: storyMint,
      ),
    ).thenAnswer((_) async => 13.26);

    final container = createContainer();
    addTearDown(container.dispose);
    container.listen(onChainWalletBalanceProvider, (_, _) {});

    await container.read(onChainWalletBalanceProvider.notifier).refresh();
    expect(container.read(onChainWalletBalanceProvider).usdcBalance, 752.08);
    expect(container.read(onChainWalletBalanceProvider).storyBalance, 13.26);

    when(
      () => balanceService.getTokenBalance(
        rpcHttpUrl: any(named: 'rpcHttpUrl'),
        ownerAddress: any(named: 'ownerAddress'),
        tokenMint: usdcMint,
      ),
    ).thenAnswer((_) async => null);
    when(
      () => balanceService.getTokenBalance(
        rpcHttpUrl: any(named: 'rpcHttpUrl'),
        ownerAddress: any(named: 'ownerAddress'),
        tokenMint: storyMint,
      ),
    ).thenAnswer((_) async => null);

    await container.read(onChainWalletBalanceProvider.notifier).refresh();
    expect(container.read(onChainWalletBalanceProvider).usdcBalance, 752.08);
    expect(container.read(onChainWalletBalanceProvider).storyBalance, 13.26);
  });

  test('refresh updates only successful token and keeps the other', () async {
    when(
      () => balanceService.getTokenBalance(
        rpcHttpUrl: any(named: 'rpcHttpUrl'),
        ownerAddress: any(named: 'ownerAddress'),
        tokenMint: usdcMint,
      ),
    ).thenAnswer((_) async => 10);
    when(
      () => balanceService.getTokenBalance(
        rpcHttpUrl: any(named: 'rpcHttpUrl'),
        ownerAddress: any(named: 'ownerAddress'),
        tokenMint: storyMint,
      ),
    ).thenAnswer((_) async => 5);

    final container = createContainer();
    addTearDown(container.dispose);
    container.listen(onChainWalletBalanceProvider, (_, _) {});

    await container.read(onChainWalletBalanceProvider.notifier).refresh();

    when(
      () => balanceService.getTokenBalance(
        rpcHttpUrl: any(named: 'rpcHttpUrl'),
        ownerAddress: any(named: 'ownerAddress'),
        tokenMint: usdcMint,
      ),
    ).thenAnswer((_) async => null);
    when(
      () => balanceService.getTokenBalance(
        rpcHttpUrl: any(named: 'rpcHttpUrl'),
        ownerAddress: any(named: 'ownerAddress'),
        tokenMint: storyMint,
      ),
    ).thenAnswer((_) async => 8);

    await container.read(onChainWalletBalanceProvider.notifier).refresh();
    expect(container.read(onChainWalletBalanceProvider).usdcBalance, 10);
    expect(container.read(onChainWalletBalanceProvider).storyBalance, 8);
  });

  test(
    'refresh loads EVM balances without mixing into Solana spendables',
    () async {
      const ethAddress = '0xabcDEF1234567890abcDEF1234567890abcDEF12';
      const evmUsdc = '0x1111111111111111111111111111111111111111';
      const evmStory = '0x2222222222222222222222222222222222222222';
      const evmChain = ChainInfo(
        chainType: 'evm',
        chainId: 11155111,
        rpc: ChainRpc(http: 'https://rpc.sepolia.example'),
        tokens: {
          'usdc': WalletToken(address: evmUsdc, symbol: 'USDC', decimals: 6),
          'story': WalletToken(
            address: evmStory,
            symbol: 'STORY',
            decimals: 18,
          ),
        },
      );

      when(
        () => localRepo.getEthereumWalletAddressAsync(),
      ).thenAnswer((_) async => ethAddress);
      when(
        () => balanceService.getTokenBalance(
          rpcHttpUrl: any(named: 'rpcHttpUrl'),
          ownerAddress: any(named: 'ownerAddress'),
          tokenMint: usdcMint,
        ),
      ).thenAnswer((_) async => 3);
      when(
        () => balanceService.getTokenBalance(
          rpcHttpUrl: any(named: 'rpcHttpUrl'),
          ownerAddress: any(named: 'ownerAddress'),
          tokenMint: storyMint,
        ),
      ).thenAnswer((_) async => 4);
      when(
        () => evmBalanceService.getTokenBalance(
          rpcHttpUrl: any(named: 'rpcHttpUrl'),
          ownerAddress: ethAddress,
          tokenAddress: evmUsdc,
          decimals: 6,
        ),
      ).thenAnswer((_) async => 88.5);
      when(
        () => evmBalanceService.getTokenBalance(
          rpcHttpUrl: any(named: 'rpcHttpUrl'),
          ownerAddress: ethAddress,
          tokenAddress: evmStory,
          decimals: 18,
        ),
      ).thenAnswer((_) async => 9);

      final container = ProviderContainer(
        overrides: [
          localRepositoryProvider.overrideWithValue(localRepo),
          solanaTokenBalanceServiceProvider.overrideWithValue(balanceService),
          evmTokenBalanceServiceProvider.overrideWithValue(evmBalanceService),
          globalConfigProvider.overrideWith(
            (ref) async => Result.success(
              const GlobalConfig(
                chainlinks: {'solana': chain, 'ethereum': evmChain},
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(onChainWalletBalanceProvider, (_, _) {});

      await container.read(onChainWalletBalanceProvider.notifier).refresh();
      final state = container.read(onChainWalletBalanceProvider);
      expect(state.usdcBalance, 3);
      expect(state.storyBalance, 4);
      expect(state.evmUsdcBalance, 88.5);
      expect(state.evmStoryBalance, 9);
    },
  );
}
