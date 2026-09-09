import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/story_logger.dart';
import 'evm_abi.dart';

/// Fetches ERC-20 balances via `eth_call` + `balanceOf(address)`.
class EvmTokenBalanceService {
  const EvmTokenBalanceService({this.client});

  final http.Client? client;

  /// Returns the on-chain token balance as a human-readable double.
  /// Missing / empty results resolve to `0`. RPC failures return `null`.
  Future<double?> getTokenBalance({
    required String rpcHttpUrl,
    required String ownerAddress,
    required String tokenAddress,
    required int decimals,
  }) async {
    final first = await _getTokenBalanceOnce(
      rpcHttpUrl: rpcHttpUrl,
      ownerAddress: ownerAddress,
      tokenAddress: tokenAddress,
      decimals: decimals,
    );
    if (first != null) return first;

    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _getTokenBalanceOnce(
      rpcHttpUrl: rpcHttpUrl,
      ownerAddress: ownerAddress,
      tokenAddress: tokenAddress,
      decimals: decimals,
    );
  }

  Future<double?> _getTokenBalanceOnce({
    required String rpcHttpUrl,
    required String ownerAddress,
    required String tokenAddress,
    required int decimals,
  }) async {
    final ownedClient = client == null;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.post(
        Uri.parse(rpcHttpUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'eth_call',
          'params': [
            {'to': tokenAddress, 'data': encodeBalanceOf(ownerAddress)},
            'latest',
          ],
        }),
      );
      if (response.statusCode != 200) {
        StoryLogger.w(
          'EVM balance RPC HTTP ${response.statusCode} for $tokenAddress',
          tag: 'EvmBalance',
        );
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final error = decoded['error'];
      if (error != null) {
        StoryLogger.w(
          'EVM balance RPC error for $tokenAddress: $error',
          tag: 'EvmBalance',
        );
        return null;
      }
      final result = decoded['result'];
      if (result is! String) return 0;
      return decodeTokenBalance(result, decimals);
    } on Exception catch (e) {
      StoryLogger.w(
        'Failed to fetch ERC-20 balance for $tokenAddress',
        error: e,
        tag: 'EvmBalance',
      );
      return null;
    } finally {
      if (ownedClient) httpClient.close();
    }
  }
}
