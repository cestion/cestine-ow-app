import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../core/result.dart';
import '../../core/story_logger.dart';

/// Outcome of inspecting one [SignatureStatus] snapshot.
enum SolanaConfirmStatus {
  /// Not yet found / still processing.
  pending,

  /// Reached `confirmed` or `finalized` with no on-chain error.
  confirmed,

  /// Signature exists but `err` is set.
  failed,
}

/// Waits until a Solana signature reaches `confirmed` / `finalized`.
///
/// Aligns with web `confirmSolanaTransaction` HTTP fallback
/// (`getSignatureStatuses` poll). App has no WSS path yet.
class SolanaTransactionConfirmService {
  const SolanaTransactionConfirmService({
    this.pollInterval = const Duration(seconds: 2),
    this.timeout = const Duration(seconds: 30),
    RpcClient Function(String rpcHttpUrl)? rpcClientFactory,
  }) : _rpcClientFactory = rpcClientFactory ?? RpcClient.new;

  final Duration pollInterval;
  final Duration timeout;
  final RpcClient Function(String rpcHttpUrl) _rpcClientFactory;

  /// Returns success with [signature] once confirmed on-chain.
  Future<Result<String>> confirm({
    required String rpcHttpUrl,
    required String signature,
    String action = 'transaction',
  }) async {
    final sig = signature.trim();
    if (sig.isEmpty) {
      return Result.failure(
        ApiError.business(-1, 'Missing transaction signature'),
      );
    }
    if (rpcHttpUrl.trim().isEmpty) {
      return Result.failure(
        ApiError.business(-1, 'Missing Solana RPC endpoint'),
      );
    }

    final rpc = _rpcClientFactory(rpcHttpUrl);
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      try {
        final result = await rpc.getSignatureStatuses([
          sig,
        ], searchTransactionHistory: true);
        final status = result.value.isEmpty ? null : result.value.first;
        switch (interpretStatus(status)) {
          case SolanaConfirmStatus.pending:
            break;
          case SolanaConfirmStatus.confirmed:
            StoryLogger.d(
              'Confirmed $action on-chain: $sig',
              tag: 'SolanaConfirm',
            );
            return Result.success(sig);
          case SolanaConfirmStatus.failed:
            return Result.failure(
              ApiError.business(
                -1,
                '$action transaction failed on-chain: ${status?.err}',
              ),
            );
        }
      } on Exception catch (e, st) {
        StoryLogger.w(
          'getSignatureStatuses failed while confirming $action',
          error: e,
          stackTrace: st,
          tag: 'SolanaConfirm',
        );
      } on Error catch (e, st) {
        StoryLogger.w(
          'getSignatureStatuses error while confirming $action',
          error: e,
          stackTrace: st,
          tag: 'SolanaConfirm',
        );
      }

      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) break;
      await Future<void>.delayed(
        remaining < pollInterval ? remaining : pollInterval,
      );
    }

    return Result.failure(
      ApiError.timeout(
        '$action confirmation timeout after ${timeout.inSeconds}s. '
        'Transaction may still succeed. Signature: $sig',
      ),
    );
  }

  /// Pure helper for unit tests / status evaluation.
  static SolanaConfirmStatus interpretStatus(SignatureStatus? status) {
    if (status == null) return SolanaConfirmStatus.pending;
    if (status.err != null) return SolanaConfirmStatus.failed;
    final confirmation = status.confirmationStatus;
    if (confirmation == Commitment.confirmed ||
        confirmation == Commitment.finalized) {
      return SolanaConfirmStatus.confirmed;
    }
    return SolanaConfirmStatus.pending;
  }
}
