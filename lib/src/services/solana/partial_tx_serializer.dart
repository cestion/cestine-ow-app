import 'dart:typed_data';

import 'package:solana/encoder.dart';

import '../../core/result.dart';
import 'unsigned_transaction.dart';

/// Serializes a partially-signed transaction (user signature at [userAddress]).
Result<String> serializePartiallySignedTransaction({
  required CompiledMessage compiledMessage,
  required String userAddress,
  required Uint8List userSignature,
}) {
  final accountKeys = compiledMessage.map(
    legacy: (m) => m.accountKeys,
    v0: (m) => m.accountKeys,
  );
  final sigCount = compiledMessage.requiredSignatureCount;
  final userIndex = accountKeys.indexWhere((k) => k.toBase58() == userAddress);
  if (userIndex < 0 || userIndex >= sigCount) {
    return Result.failure(
      ApiError.business(
        -1,
        userIndex < 0
            ? 'User not found in transaction signers'
            : 'User is not a required signer (index=$userIndex, sigCount=$sigCount)',
      ),
    );
  }

  final signatures = List<Signature>.generate(sigCount, (i) {
    if (i == userIndex) {
      return Signature(userSignature, publicKey: accountKeys[i]);
    }
    return Signature(kEmptySignature, publicKey: accountKeys[i]);
  });

  return Result.success(
    SignedTx(compiledMessage: compiledMessage, signatures: signatures).encode(),
  );
}
