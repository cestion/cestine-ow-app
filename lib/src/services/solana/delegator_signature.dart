import 'dart:convert';
import 'dart:typed_data';

import 'package:bs58/bs58.dart';
import 'package:crypto/crypto.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../../core/result.dart';
import '../../core/story_logger.dart';
import 'solana_program_ids.dart';

const _signatureBytes = 64;
const _ed25519DataStart = 16;
const _currentInstructionIndex = 0xffff;

final _hexSignatureRe = RegExp(r'^(?:0x)?[0-9a-fA-F]{128}$');
final _leadingHexRe = RegExp(r'^0x');

/// API `sig` 字段：hex/base64/base58 → Ed25519 原始 64 字节。
Result<Uint8List> decodeDelegatorSignature(String signature) {
  final normalized = signature.trim().replaceAll(RegExp(r'\s'), '');

  Uint8List? bytes;
  if (_hexSignatureRe.hasMatch(normalized)) {
    final hex = normalized.replaceFirst(_leadingHexRe, '');
    bytes = Uint8List.fromList(
      List.generate(
        _signatureBytes,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  } else {
    bytes =
        _tryDecodeFixedLength(normalized, base64.decode) ??
        _tryDecodeFixedLength(normalized, base58.decode);
  }

  if (bytes == null || bytes.length != _signatureBytes) {
    return Result.failure(
      ApiError.business(
        -1,
        'sig 解码后须为 $_signatureBytes 字节，实际 ${bytes?.length ?? 0} 字节',
      ),
    );
  }
  return Result.success(bytes);
}

Uint8List? _tryDecodeFixedLength(
  String value,
  List<int> Function(String) decode,
) {
  try {
    final decoded = decode(value);
    if (decoded.length == _signatureBytes) {
      return Uint8List.fromList(decoded);
    }
  } catch (e) {
    StoryLogger.d(
      'Decode fixed-length signature failed',
      error: e,
      tag: 'Solana',
    );
  }
  return null;
}

/// Ed25519 预编译验签指令（须作为 Story 主指令的前一条）。
Result<Instruction> createDelegatorEd25519Instruction({
  required Ed25519HDPublicKey delegator,
  required String canonicalPayload,
  required Uint8List sig64,
}) {
  if (sig64.length != _signatureBytes) {
    return Result.failure(
      ApiError.business(-1, 'delegator sig must be 64 bytes'),
    );
  }

  final msgHash = sha256.convert(utf8.encode(canonicalPayload)).bytes;
  final publicKeyBytes = delegator.bytes;
  if (publicKeyBytes.length != 32) {
    return Result.failure(
      ApiError.business(-1, 'delegator public key must be 32 bytes'),
    );
  }

  const publicKeyOffset = _ed25519DataStart;
  const signatureOffset = publicKeyOffset + 32;
  const messageDataOffset = signatureOffset + _signatureBytes;
  final dataLength = messageDataOffset + msgHash.length;
  final data = Uint8List(dataLength);
  data[0] = 1;
  data[1] = 0;

  void writeU16Le(int offset, int value) {
    data[offset] = value & 0xff;
    data[offset + 1] = (value >> 8) & 0xff;
  }

  writeU16Le(2, signatureOffset);
  writeU16Le(4, _currentInstructionIndex);
  writeU16Le(6, publicKeyOffset);
  writeU16Le(8, _currentInstructionIndex);
  writeU16Le(10, messageDataOffset);
  writeU16Le(12, msgHash.length);
  writeU16Le(14, _currentInstructionIndex);

  data.setRange(publicKeyOffset, publicKeyOffset + 32, publicKeyBytes);
  data.setRange(signatureOffset, signatureOffset + _signatureBytes, sig64);
  data.setRange(messageDataOffset, messageDataOffset + msgHash.length, msgHash);

  return Result.success(
    Instruction(
      programId: SolanaProgramIds.ed25519,
      accounts: const [],
      data: ByteArray(data),
    ),
  );
}

/// 解码 Privy signMessage 返回的签名（base64 / base58）。
Result<Uint8List> decodeWalletMessageSignature(String signature) {
  final trimmed = signature.trim();
  final looksBase64 =
      trimmed.contains('=') || trimmed.contains('+') || trimmed.contains('/');
  if (looksBase64) {
    final base64Decoded = _tryDecodeFixedLength(trimmed, base64.decode);
    if (base64Decoded != null) return Result.success(base64Decoded);
  }
  final decoded =
      _tryDecodeFixedLength(trimmed, base58.decode) ??
      _tryDecodeFixedLength(trimmed, base64.decode);
  if (decoded != null) return Result.success(decoded);
  return Result.failure(
    ApiError.business(-1, 'Invalid wallet message signature format'),
  );
}
