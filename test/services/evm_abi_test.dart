import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/services/evm/evm_abi.dart';
import 'package:story_app/src/utils/validators.dart';

void main() {
  test('encodeBalanceOf pads owner address', () {
    expect(
      encodeBalanceOf('0xabcDEF1234567890abcDEF1234567890abcDEF12'),
      '0x70a08231000000000000000000000000abcdef1234567890abcdef1234567890abcdef12',
    );
  });

  test('encodeErc20Transfer encodes recipient and amount', () {
    expect(
      encodeErc20Transfer(
        '0x1111111111111111111111111111111111111111',
        BigInt.from(1000000),
      ),
      '0xa9059cbb0000000000000000000000001111111111111111111111111111111111111111'
      '00000000000000000000000000000000000000000000000000000000000f4240',
    );
  });

  test('parseTokenAmount and decodeTokenBalance round-trip USDC decimals', () {
    final raw = parseTokenAmount('12.34', 6);
    expect(raw, BigInt.from(12340000));
    expect(decodeTokenBalance('0x${raw.toRadixString(16)}', 6), 12.34);
  });

  test('isValidEthereumAddress accepts checksum and lowercase', () {
    expect(
      isValidEthereumAddress('0xabcDEF1234567890abcDEF1234567890abcDEF12'),
      isTrue,
    );
    expect(
      isValidEthereumAddress('0xabcdef1234567890abcdef1234567890abcdef12'),
      isTrue,
    );
    expect(
      isValidEthereumAddress('abcdef1234567890abcdef1234567890abcdef12'),
      isFalse,
    );
    expect(
      isValidEthereumAddress('So11111111111111111111111111111111111111112'),
      isFalse,
    );
  });
}
