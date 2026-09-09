import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/wallet_balance_errors.dart';
import 'package:story_app/src/services/wallet_ledger.dart';

void main() {
  late double availableUsdc;
  late double availableStory;
  late int refreshCount;

  WalletLedger buildLedger() {
    return WalletLedger(
      WalletSpendPort(
        ensureUsdc: (required) async {
          if (availableUsdc + 1e-9 < required) {
            return Result.failure(
              ApiError.business(
                -1,
                WalletBalanceErrorMessages.insufficientUsdc,
              ),
            );
          }
          return Result.success(null);
        },
        ensureStory: (required) async {
          if (availableStory + 1e-9 < required) {
            return Result.failure(
              ApiError.business(
                -1,
                WalletBalanceErrorMessages.insufficientStory,
              ),
            );
          }
          return Result.success(null);
        },
        deduct: ({double usdc = 0, double story = 0}) {
          availableUsdc = (availableUsdc - usdc).clamp(0.0, double.infinity);
          availableStory = (availableStory - story).clamp(0.0, double.infinity);
        },
        refresh: () async {
          refreshCount++;
        },
      ),
    );
  }

  setUp(() {
    availableUsdc = 10;
    availableStory = 5;
    refreshCount = 0;
  });

  test('prepareSpend deducts on success', () async {
    final ledger = buildLedger();

    final result = await ledger.prepareSpend(
      const SpendQuote(asset: SpendAsset.usdc, amount: 3, reason: 'test'),
    );
    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull!.didDeduct, isTrue);
    expect(availableUsdc, 7);

    await ledger.commitSpend(result.dataOrNull!);
    expect(refreshCount, 1);
  });

  test('prepareSpend fails without deducting when insufficient', () async {
    availableUsdc = 1;
    final ledger = buildLedger();

    final result = await ledger.prepareSpend(
      const SpendQuote(asset: SpendAsset.usdc, amount: 3, reason: 'test'),
    );
    expect(result.isFailure, isTrue);
    expect(availableUsdc, 1);
  });

  test('softEstimate gates before authoritative amount', () async {
    availableUsdc = 2;
    final ledger = buildLedger();

    final result = await ledger.prepareSpend(
      const SpendQuote(
        asset: SpendAsset.usdc,
        amount: 1,
        softEstimate: 5,
        reason: 'test',
      ),
    );
    expect(result.isFailure, isTrue);
    expect(availableUsdc, 2);
  });

  test('ensureAffordable does not deduct', () async {
    final ledger = buildLedger();

    final result = await ledger.ensureAffordable(SpendAsset.usdc, 4);
    expect(result.isSuccess, isTrue);
    expect(availableUsdc, 10);
  });

  test('skips duplicate soft ensure when soft equals amount', () async {
    var ensureCalls = 0;
    final ledger = WalletLedger(
      WalletSpendPort(
        ensureUsdc: (required) async {
          ensureCalls++;
          return Result.success(null);
        },
        ensureStory: (_) async => Result.success(null),
        deduct: ({double usdc = 0, double story = 0}) {
          availableUsdc -= usdc;
        },
        refresh: () async {},
      ),
    );

    final result = await ledger.prepareSpend(
      const SpendQuote(
        asset: SpendAsset.usdc,
        amount: 2,
        softEstimate: 2,
        reason: 'test',
      ),
    );
    expect(result.isSuccess, isTrue);
    expect(ensureCalls, 1);
  });
}
