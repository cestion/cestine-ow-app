import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/chain_info_model.dart';
import 'package:story_app/src/model/init_config_model.dart';
import 'package:story_app/src/provider/config_providers.dart';

void main() {
  const solana = 'THmBcHfLtQtZ5WPV3UoudYmpPeQ1oEgsho';
  const ethereum = '0x1111111111111111111111111111111111111111';

  WalletNetworkOption option({
    required String key,
    String? name,
    String? chainType,
    String? depositChainType,
  }) {
    return WalletNetworkOption(
      key: key,
      chain: ChainInfo(name: name, chainType: chainType),
      deposit: depositChainType == null
          ? null
          : InitDepositConfig(chain: key, chainType: depositChainType),
    );
  }

  test('arbitrum stays EVM even if chainType is wrongly svm', () {
    final network = option(
      key: 'arbitrum-sepolia',
      name: 'Arbitrum Sepolia',
      chainType: 'svm',
    );
    expect(network.isEvm, isTrue);
    expect(network.isSvm, isFalse);
    expect(
      network.depositAddress(solanaAddress: solana, ethereumAddress: ethereum),
      ethereum,
    );
  });

  test('evm deposit never returns solana-shaped ethereumAddress', () {
    final network = option(
      key: 'ethereum-sepolia',
      name: 'Ethereum Sepolia',
      chainType: 'evm',
    );
    expect(
      network.depositAddress(solanaAddress: solana, ethereumAddress: solana),
      isEmpty,
    );
  });

  test('solana network still uses solana address', () {
    final network = option(
      key: 'solana-devnet',
      name: 'Solana Devnet',
      chainType: 'svm',
    );
    expect(network.isSvm, isTrue);
    expect(
      network.depositAddress(solanaAddress: solana, ethereumAddress: ethereum),
      solana,
    );
  });

  test('collectAllDepositTokens unions symbols across networks', () {
    const sol = WalletNetworkOption(
      key: 'solana-devnet',
      chain: ChainInfo(
        name: 'Solana Devnet',
        chainType: 'svm',
        tokens: {
          'usdc': WalletToken(symbol: 'USDC'),
          'story': WalletToken(symbol: 'STORY'),
        },
      ),
      deposit: InitDepositConfig(
        chain: 'solana-devnet',
        chainType: 'svm',
        tokens: [
          InitDepositTokenConfig(symbol: 'usdc'),
          InitDepositTokenConfig(symbol: 'story'),
        ],
      ),
    );
    const arb = WalletNetworkOption(
      key: 'arbitrum-sepolia',
      chain: ChainInfo(
        name: 'Arbitrum Sepolia',
        chainType: 'evm',
        tokens: {
          'usdc': WalletToken(symbol: 'USDC'),
          'usdt': WalletToken(symbol: 'USDT'),
        },
      ),
      deposit: InitDepositConfig(
        chain: 'arbitrum-sepolia',
        chainType: 'evm',
        tokens: [
          InitDepositTokenConfig(symbol: 'usdc'),
          InitDepositTokenConfig(symbol: 'usdt'),
        ],
      ),
    );
    final tokens = collectAllDepositTokens([sol, arb]);
    expect(tokens.map((t) => (t.symbol ?? '').toUpperCase()).toList(), [
      'USDC',
      'STORY',
      'USDT',
    ]);
  });
}
