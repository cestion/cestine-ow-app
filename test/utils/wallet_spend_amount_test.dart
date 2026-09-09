import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/utils/wallet_spend_amount.dart';

void main() {
  group('parseUsdcAmount', () {
    test('parses human amounts', () {
      expect(parseUsdcAmount('1'), 1);
      expect(parseUsdcAmount('1.5'), 1.5);
      expect(parseUsdcAmount('0'), 0);
    });

    test('parses minor units', () {
      expect(parseUsdcAmount('1000000'), 1);
      expect(parseUsdcAmount('1500000'), 1.5);
    });

    test('returns null for invalid input', () {
      expect(parseUsdcAmount(null), isNull);
      expect(parseUsdcAmount(''), isNull);
      expect(parseUsdcAmount('abc'), isNull);
    });
  });

  group('resolveMintFeeUsdc', () {
    test('uses digest fee then fallback', () {
      expect(resolveMintFeeUsdc('2'), 2);
      expect(resolveMintFeeUsdc(null), 1);
      expect(resolveMintFeeUsdc('1000000'), 1);
    });
  });

  group('resolveActorSignChargeUsdc', () {
    test('prefers slippage total then total then fallback', () {
      expect(
        resolveActorSignChargeUsdc(
          totalPriceWithSlippage: 1.1,
          totalPrice: 1.0,
          fallbackUsdc: 0.9,
        ),
        1.1,
      );
      expect(
        resolveActorSignChargeUsdc(totalPrice: 1.0, fallbackUsdc: 0.9),
        1.0,
      );
      expect(resolveActorSignChargeUsdc(fallbackUsdc: 0.9), 0.9);
      expect(resolveActorSignChargeUsdc(), 0);
    });
  });
}
