import 'dart:typed_data';

import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../../core/result.dart';

class StoryTransactionBuildResult {
  final CompiledMessage compiledMessage;
  final Uint8List messageBytes;
  final String blockhash;

  const StoryTransactionBuildResult({
    required this.compiledMessage,
    required this.messageBytes,
    required this.blockhash,
  });
}

/// Shared V0 message assembly for Story sponsor transactions.
///
/// Generated bindings create program instructions. This composer owns the
/// network blockhash and transaction-level instruction ordering.
class StoryTransactionComposer {
  const StoryTransactionComposer();

  Future<Result<StoryTransactionBuildResult>> composeSponsorV0({
    required String rpcHttpUrl,
    required Ed25519HDPublicKey sponsor,
    required List<Instruction> instructions,
    List<Instruction> computeBudgetInstructions = const [],
    List<Instruction> setupInstructions = const [],
  }) async {
    if (instructions.isEmpty) {
      return Result.failure(
        ApiError.validation('At least one program instruction is required'),
      );
    }

    try {
      final rpc = RpcClient(rpcHttpUrl);
      final latestBlockhash = await rpc.getLatestBlockhash(
        commitment: Commitment.confirmed,
      );
      return Result.success(
        compileSponsorV0(
          sponsor: sponsor,
          recentBlockhash: latestBlockhash.value.blockhash,
          instructions: instructions,
          computeBudgetInstructions: computeBudgetInstructions,
          setupInstructions: setupInstructions,
        ),
      );
    } on FormatException catch (error) {
      return Result.failure(
        ApiError.validation(
          'Invalid Solana transaction input: ${error.message}',
        ),
      );
    } catch (error) {
      return Result.failure(
        ApiError.network(
          'Failed to prepare Story transaction: $error',
          exception: error is Exception ? error : null,
        ),
      );
    }
  }

  StoryTransactionBuildResult compileSponsorV0({
    required Ed25519HDPublicKey sponsor,
    required String recentBlockhash,
    required List<Instruction> instructions,
    List<Instruction> computeBudgetInstructions = const [],
    List<Instruction> setupInstructions = const [],
  }) {
    final orderedInstructions = <Instruction>[
      ...computeBudgetInstructions,
      ...setupInstructions,
      ...instructions,
    ];
    final compiledMessage = Message(
      instructions: orderedInstructions,
    ).compileV0(recentBlockhash: recentBlockhash, feePayer: sponsor);
    return StoryTransactionBuildResult(
      compiledMessage: compiledMessage,
      messageBytes: Uint8List.fromList(
        compiledMessage.toByteArray().toList(growable: false),
      ),
      blockhash: recentBlockhash,
    );
  }
}
