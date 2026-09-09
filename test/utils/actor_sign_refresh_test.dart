import 'package:flutter_test/flutter_test.dart';
import 'package:solana/dto.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/services/solana/solana_transaction_confirm_service.dart';
import 'package:story_app/src/utils/actor_data_sync.dart';
import 'package:story_app/src/utils/actor_pricing.dart';

void main() {
  group('SolanaTransactionConfirmService.interpretStatus', () {
    test('null status is pending', () {
      expect(
        SolanaTransactionConfirmService.interpretStatus(null),
        SolanaConfirmStatus.pending,
      );
    });

    test('processed is pending', () {
      const status = SignatureStatus(
        slot: 1,
        confirmationStatus: Commitment.processed,
      );
      expect(
        SolanaTransactionConfirmService.interpretStatus(status),
        SolanaConfirmStatus.pending,
      );
    });

    test('confirmed without err is confirmed', () {
      const status = SignatureStatus(
        slot: 1,
        confirmationStatus: Commitment.confirmed,
      );
      expect(
        SolanaTransactionConfirmService.interpretStatus(status),
        SolanaConfirmStatus.confirmed,
      );
    });

    test('finalized without err is confirmed', () {
      const status = SignatureStatus(
        slot: 1,
        confirmationStatus: Commitment.finalized,
      );
      expect(
        SolanaTransactionConfirmService.interpretStatus(status),
        SolanaConfirmStatus.confirmed,
      );
    });

    test('err map is failed even if confirmed', () {
      const status = SignatureStatus(
        slot: 1,
        confirmationStatus: Commitment.confirmed,
        err: {'InstructionError': 1},
      );
      expect(
        SolanaTransactionConfirmService.interpretStatus(status),
        SolanaConfirmStatus.failed,
      );
    });
  });

  group('applyOptimisticActorSign', () {
    test('increments minted and decrements available for fixed pricing', () {
      const actor = ActorCollection(
        id: 'a1',
        pricingMode: 'FIXED',
        totalSupply: '100',
        mintedSupply: '10',
        availableSupply: '90',
        initialPriceUsdc: 1.5,
        currentPriceUsdc: 1.5,
      );

      final next = applyOptimisticActorSign(actor);
      expect(next.mintedSupply, '11');
      expect(next.availableSupply, '89');
      expect(next.currentPriceUsdc, 1.5);
      expect(next.displayCurrentPriceUsdc, 1.5);
    });

    test('recomputes bonding-curve next price after mint', () {
      const actor = ActorCollection(
        id: 'a1',
        pricingMode: 'BONDING_CURVE',
        totalSupply: '100',
        mintedSupply: '0',
        availableSupply: '100',
        initialPriceUsdc: 1,
        currentPriceUsdc: 1,
      );

      final next = applyOptimisticActorSign(actor);
      expect(next.mintedSupply, '1');
      expect(next.availableSupply, '99');
      final expected = getActorBondingCurvePrice(1, 1, 100);
      expect(next.currentPriceUsdc, expected);
      expect(next.displayCurrentPriceUsdc, expected);
    });
  });
}
