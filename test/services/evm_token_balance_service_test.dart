import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:story_app/src/services/evm/evm_token_balance_service.dart';

void main() {
  test('getTokenBalance decodes eth_call result', () async {
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['method'], 'eth_call');
      return http.Response(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'result': '0x${BigInt.from(2500000).toRadixString(16)}',
        }),
        200,
      );
    });

    final service = EvmTokenBalanceService(client: client);
    final balance = await service.getTokenBalance(
      rpcHttpUrl: 'https://rpc.example',
      ownerAddress: '0xabcDEF1234567890abcDEF1234567890abcDEF12',
      tokenAddress: '0x1111111111111111111111111111111111111111',
      decimals: 6,
    );

    expect(balance, 2.5);
  });

  test('getTokenBalance returns null on RPC error', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'error': {'code': -32000, 'message': 'boom'},
        }),
        200,
      );
    });

    final service = EvmTokenBalanceService(client: client);
    final balance = await service.getTokenBalance(
      rpcHttpUrl: 'https://rpc.example',
      ownerAddress: '0xabcDEF1234567890abcDEF1234567890abcDEF12',
      tokenAddress: '0x1111111111111111111111111111111111111111',
      decimals: 6,
    );

    expect(balance, isNull);
  });
}
