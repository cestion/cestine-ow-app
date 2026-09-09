import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/utils/validators.dart';

void main() {
  group('parseWalletAddressFromScan', () {
    const sol = 'DYw8jCTfwHNRJhhmFcbXvVDTqWMEVFBX6ZKUmG5CNSKK';
    const eth = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0';

    test('parses bare solana and ethereum addresses', () {
      expect(parseWalletAddressFromScan(sol, preferEvm: false), sol);
      expect(parseWalletAddressFromScan(eth, preferEvm: true), eth);
    });

    test('parses solana: and ethereum: URI schemes', () {
      expect(
        parseWalletAddressFromScan('solana:$sol?amount=1.5', preferEvm: false),
        sol,
      );
      expect(
        parseWalletAddressFromScan(
          'ethereum:$eth@1?value=1e18',
          preferEvm: true,
        ),
        eth,
      );
      expect(
        parseWalletAddressFromScan('ethereum:pay-$eth@42161', preferEvm: true),
        eth,
      );
    });

    test('prefers the active chain family when both could match', () {
      expect(parseWalletAddressFromScan(eth, preferEvm: false), eth);
      expect(parseWalletAddressFromScan(sol, preferEvm: true), sol);
    });

    test('returns null for garbage', () {
      expect(
        parseWalletAddressFromScan('not-an-address', preferEvm: false),
        isNull,
      );
      expect(parseWalletAddressFromScan('   ', preferEvm: true), isNull);
    });
  });
}
