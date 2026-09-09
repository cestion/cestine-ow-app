import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/config_providers.dart';
import 'package:story_app/src/view/withdraw_page.dart';

void main() {
  test('floorWithdrawAmount never rounds above the raw balance', () {
    // toStringAsFixed(2) would round 10.005 → "10.01" and fail amount <= balance.
    expect(floorWithdrawAmount(10.005), 10.00);
    expect(floorWithdrawAmount(9.999), 9.99);
    expect(floorWithdrawAmount(12.3456789), 12.34);
    expect(floorWithdrawAmount(0), 0);
    expect(floorWithdrawAmount(-1), 0);
  });

  test('floored max fill stays within balance after parse', () {
    const balance = 10.005;
    final fill = floorWithdrawAmount(balance);
    final parsed = double.parse(
      fill.toStringAsFixed(withdrawBalanceFractionDigits),
    );
    expect(parsed <= balance + 1e-9, isTrue);
    expect(double.parse(balance.toStringAsFixed(2)) <= balance + 1e-9, isFalse);
  });

  test('max fill uses full balance even when above typical config max', () {
    const balance = 25000.55;
    expect(
      floorWithdrawAmount(
        balance,
      ).toStringAsFixed(withdrawBalanceFractionDigits),
      '25000.55',
    );
  });

  test('withdraw input fraction digits by token', () {
    expect(withdrawInputFractionDigits('USDT'), 5);
    expect(withdrawInputFractionDigits('usdc'), 5);
    expect(withdrawInputFractionDigits('STORY'), 2);
    expect(withdrawInputFractionDigits('story'), 2);
    expect(withdrawBalanceFractionDigits, 2);
  });

  test('USDC/USDT max fill keeps up to 5 decimals without trailing zeros', () {
    const balance = 12.3456789;
    expect(formatWithdrawMaxFill(balance, 'USDC'), '12.34567');
    expect(formatWithdrawMaxFill(balance, 'USDT'), '12.34567');
    expect(formatWithdrawMaxFill(12.34000, 'USDC'), '12.34');
    expect(formatWithdrawMaxFill(12.30000, 'USDC'), '12.3');
    expect(formatWithdrawMaxFill(12.00000, 'USDC'), '12');
    expect(
      double.parse(formatWithdrawMaxFill(balance, 'USDC')) <= balance + 1e-12,
      isTrue,
    );
  });

  test('STORY max fill keeps up to 2 decimals without trailing zeros', () {
    expect(formatWithdrawMaxFill(12.3456789, 'STORY'), '12.34');
    expect(formatWithdrawMaxFill(12.30, 'STORY'), '12.3');
    expect(formatWithdrawMaxFill(12.00, 'STORY'), '12');
  });

  test('formatWithdrawMaxFill respects explicit inputScale override', () {
    expect(formatWithdrawMaxFill(1.234567, 'USDC', inputScale: 3), '1.234');
  });

  group('withdraw scale from init config', () {
    WalletNetworkOption networkWith({
      required String symbol,
      int? scale,
      int? inputScale,
    }) {
      return WalletNetworkOption(
        key: 'solana-devnet',
        chain: const ChainInfo(chainType: 'svm'),
        withdraw: InitWithdrawConfig(
          chain: 'solana-devnet',
          tokens: [
            InitWithdrawTokenConfig(
              symbol: symbol,
              scale: scale,
              inputScale: inputScale,
            ),
          ],
        ),
      );
    }

    test('uses config scale and inputScale when present', () {
      final network = networkWith(symbol: 'usdc', scale: 2, inputScale: 5);
      expect(network.withdrawTokenScale('USDC'), 2);
      expect(network.withdrawTokenInputScale('USDC'), 5);
    });

    test('falls back to defaults when scale fields missing', () {
      final usdc = networkWith(symbol: 'usdc');
      expect(usdc.withdrawTokenScale('USDC'), 2);
      expect(usdc.withdrawTokenInputScale('USDC'), 5);

      final story = networkWith(symbol: 'story');
      expect(story.withdrawTokenScale('STORY'), 2);
      expect(story.withdrawTokenInputScale('STORY'), 2);
    });

    test('InitWithdrawTokenConfig parses scale and inputScale from json', () {
      final token = InitWithdrawTokenConfig.fromJson(const {
        'scale': 2,
        'symbol': 'usdc',
        'inputScale': 5,
      });
      expect(token.symbol, 'usdc');
      expect(token.scale, 2);
      expect(token.inputScale, 5);
    });

    test('InitWithdrawTokenConfig accepts string scale values', () {
      final token = InitWithdrawTokenConfig.fromJson(const {
        'scale': '2',
        'symbol': 'story',
        'inputScale': '2',
      });
      expect(token.scale, 2);
      expect(token.inputScale, 2);
    });
  });
}
