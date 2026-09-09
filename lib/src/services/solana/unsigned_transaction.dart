import 'dart:typed_data';

import 'package:solana/encoder.dart';

import '../../core/result.dart';

const solanaTransactionMaxBytes = 1232;
const batchRefillTransactionTooLargeError =
    'gameBatchRefillTransactionTooLarge';

/// 多签场景（fee payer = sponsor、user = creator）中空占位签名（64 全零字节）。
/// 各 builder 共享此常量，避免重复定义。
final kEmptySignature = Uint8List(64);

Result<void> validateSolanaTransactionWireSize(Uint8List wireBytes) {
  if (wireBytes.length <= solanaTransactionMaxBytes) {
    return Result.success(null);
  }
  return Result.failure(
    ApiError.business(-1, batchRefillTransactionTooLargeError),
  );
}

/// Privy `signTransaction` 要求 wire 格式中签名数组长度等于 message 所需签名数。
/// 多签场景（fee payer = sponsor、用户 = creator）须预填全零占位签名，不能只传 `[0, message]`。
Uint8List buildUnsignedTransactionWireBytes(CompiledMessage compiledMessage) {
  final sigCount = compiledMessage.requiredSignatureCount;
  final accountKeys = compiledMessage.map(
    legacy: (m) => m.accountKeys,
    v0: (m) => m.accountKeys,
  );

  return Uint8List.fromList(
    SignedTx(
      compiledMessage: compiledMessage,
      signatures: [
        for (var i = 0; i < sigCount; i++)
          Signature(kEmptySignature, publicKey: accountKeys[i]),
      ],
    ).toByteArray().toList(),
  );
}
