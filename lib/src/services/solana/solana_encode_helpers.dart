import 'dart:convert';
import 'dart:typed_data';

import '../../core/result.dart';

List<int> u32Le(int value) => [
  value & 0xff,
  (value >> 8) & 0xff,
  (value >> 16) & 0xff,
  (value >> 24) & 0xff,
];

Result<void> validateDelegatorSignature(Uint8List delegatorSig) {
  if (delegatorSig.length != 64) {
    return Result.failure(
      ApiError.business(-1, 'delegator sig must be 64 bytes'),
    );
  }
  return Result.success(null);
}

Result<void> validateOrderHash(Uint8List orderHash) {
  if (orderHash.length != 32) {
    return Result.failure(ApiError.business(-1, 'orderHash must be 32 bytes'));
  }
  return Result.success(null);
}

/// Encodes `[discriminator][u32 assetId len][assetId][u32 payload len][payload][sig64]`.
Result<Uint8List> encodeAssetIdPayloadInstructionData({
  required List<int> discriminator,
  required String assetId,
  required String canonicalPayload,
  required Uint8List delegatorSig,
}) {
  final sigCheck = validateDelegatorSignature(delegatorSig);
  if (sigCheck.isFailure) {
    return Result.failure(sigCheck.errorOrNull!);
  }

  final assetIdBytes = utf8.encode(assetId);
  final payloadBytes = utf8.encode(canonicalPayload);
  return Result.success(
    Uint8List.fromList([
      ...discriminator,
      ...u32Le(assetIdBytes.length),
      ...assetIdBytes,
      ...u32Le(payloadBytes.length),
      ...payloadBytes,
      ...delegatorSig,
    ]),
  );
}
