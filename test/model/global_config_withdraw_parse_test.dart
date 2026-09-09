import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/global_config_model.dart';

void main() {
  test('GlobalConfig parses withdraw min/max as int or string', () {
    const payload = {
      'chainlinks': {
        'solana-devnet': {
          'chainId': 3,
          'name': 'Solana Devnet',
          'chainType': 'svm',
          'rpc': {
            'http':
                'https://autumn-misty-snow.solana-devnet.quiknode.pro/example',
            'wss': 'wss://autumn-misty-snow.solana-devnet.quiknode.pro/example',
          },
          'tokens': {
            'usdc': {
              'symbol': 'USDC',
              'address': 'CVhJj93zY1MeTH5C52xScaCCr88fttBdVzGN2QqNCA2Y',
              'decimals': 6,
              'fullSymbol': 'USD Coin',
            },
            'story': {
              'symbol': 'Story',
              'address': '5ANvSqZqcm2uXqtdEyX6UDZp8jykKvehmQrF1pRVgRsh',
              'decimals': 9,
              'fullSymbol': 'Story',
            },
          },
        },
      },
      'init': {
        'withdraw': [
          {
            'chain': 'solana-devnet',
            // Test gateway returns numeric min/max (not strings).
            'tokens': [
              {
                'max': 200,
                'min': 2,
                'scale': 2,
                'symbol': 'usdc',
                'inputScale': 5,
              },
              {
                'max': 20000,
                'min': 20,
                'scale': 2,
                'symbol': 'story',
                'inputScale': 2,
              },
            ],
          },
        ],
        'deposit': [
          {
            'chain': 'solana-devnet',
            'chainType': 'svm',
            'tokens': [
              {'min': 0, 'symbol': 'usdc', 'scale': '2', 'exchange_rate': 1},
            ],
          },
        ],
      },
    };

    final cfg = GlobalConfig.fromJson(
      jsonDecode(jsonEncode(payload)) as Map<String, dynamic>,
    );

    expect(cfg.chainlinks, isNotNull);
    final svm = cfg.chainlinks!['solana-devnet'];
    expect(svm?.chainType, 'svm');
    expect(svm?.rpc?.http, contains('solana-devnet'));
    expect(svm?.tokens?['usdc']?.address, isNotEmpty);
    expect(svm?.tokens?['story']?.address, isNotEmpty);

    final withdraw = cfg.init!.withdraw!.single.tokens!;
    expect(withdraw[0].min, '2');
    expect(withdraw[0].max, '200');
    expect(withdraw[1].min, '20');
    expect(withdraw[1].max, '20000');

    expect(cfg.init!.deposit!.single.tokens!.single.min, '0');
  });
}
