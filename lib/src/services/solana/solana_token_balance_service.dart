import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../core/story_logger.dart';

/// Fetches on-chain SPL token balances via Solana JSON-RPC.
///
/// Mirrors the web app's `useAppWalletTokenBalance` hook which queries
/// `getParsedTokenAccountsByOwner` / `getTokenAccountsByOwner` (not ATA +
/// `getTokenAccountBalance`) so that:
/// - missing token accounts resolve to `0` instead of RPC param errors
/// - Token / Token-2022 accounts for the mint are both discoverable
class SolanaTokenBalanceService {
  const SolanaTokenBalanceService();

  /// Returns the on-chain [tokenMint] balance for [ownerAddress] as a
  /// human-readable double. Returns `0` when the owner has no token account
  /// for this mint. Returns `null` only on unexpected RPC failures.
  Future<double?> getTokenBalance({
    required String rpcHttpUrl,
    required String ownerAddress,
    required String tokenMint,
  }) async {
    final first = await _getTokenBalanceOnce(
      rpcHttpUrl: rpcHttpUrl,
      ownerAddress: ownerAddress,
      tokenMint: tokenMint,
    );
    if (first != null) return first;

    // One retry absorbs transient TLS/handshake drops common on mobile RPC.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _getTokenBalanceOnce(
      rpcHttpUrl: rpcHttpUrl,
      ownerAddress: ownerAddress,
      tokenMint: tokenMint,
    );
  }

  Future<double?> _getTokenBalanceOnce({
    required String rpcHttpUrl,
    required String ownerAddress,
    required String tokenMint,
  }) async {
    try {
      final rpc = RpcClient(rpcHttpUrl);
      final result = await rpc.getTokenAccountsByOwner(
        ownerAddress,
        TokenAccountsFilter.byMint(tokenMint),
        encoding: Encoding.jsonParsed,
        commitment: Commitment.confirmed,
      );

      final accounts = result.value;
      if (accounts.isEmpty) return 0;

      final uiAmount = _uiAmountFromAccount(accounts.first.account);
      if (uiAmount != null) return uiAmount;

      StoryLogger.w(
        'Token account found but could not parse uiAmount for mint $tokenMint',
        tag: 'SolanaBalance',
      );
      return null;
    } on JsonRpcException catch (e) {
      // Missing mint — treat as zero (matches web `/could not find mint/i`).
      final message = e.message.toLowerCase();
      if (message.contains('could not find')) {
        return 0;
      }
      StoryLogger.w(
        'RPC error fetching SPL token balance for mint $tokenMint',
        error: e,
        tag: 'SolanaBalance',
      );
      return null;
    } on Exception catch (e) {
      StoryLogger.w(
        'Failed to fetch SPL token balance for mint $tokenMint',
        error: e,
        tag: 'SolanaBalance',
      );
      return null;
    } on Error catch (e) {
      StoryLogger.w(
        'Error fetching SPL token balance for mint $tokenMint',
        error: e,
        tag: 'SolanaBalance',
      );
      return null;
    }
  }

  static double? _uiAmountFromAccount(Account account) {
    final data = account.data;
    if (data is! ParsedAccountData) return null;

    final SplTokenProgramAccountData? parsed = switch (data) {
      ParsedSplTokenProgramAccountData(:final parsed) => parsed,
      ParsedSplToken2022ProgramAccountData(:final parsed) => parsed,
      _ => null,
    };
    if (parsed == null) return null;

    return switch (parsed) {
      TokenAccountData(:final info) =>
        double.tryParse(info.tokenAmount.uiAmountString ?? '') ?? 0,
      _ => null,
    };
  }
}
