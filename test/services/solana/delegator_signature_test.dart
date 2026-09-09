import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:solana/solana.dart';
import 'package:story_app/src/services/solana/delegator_signature.dart';
import 'package:story_app/src/core/result.dart';

void main() {
  group('DelegatorSignature', () {
    group('decodeDelegatorSignature', () {
      // 128 hex chars = 64 bytes
      const validHex =
          'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789'
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

      test('decodes hex signature (with 0x prefix)', () {
        final result = decodeDelegatorSignature('0x$validHex');
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!.length, 64);
      });

      test('decodes hex signature (without 0x prefix)', () {
        final result = decodeDelegatorSignature(validHex);
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!.length, 64);
      });

      test('fails on length mismatch', () {
        final result = decodeDelegatorSignature('abcd');
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ApiError>());
      });

      test('fails on invalid hex', () {
        final result = decodeDelegatorSignature(
          'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz'
          'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz',
        );
        // Would fail base64 decode, then fall through to base58
        expect(result.isFailure, isTrue);
      });

      test('decodes base64 signature of 64 bytes', () {
        final bytes = Uint8List.fromList(List.generate(64, (i) => i));
        final b64 = base64.encode(bytes.toList());
        final result = decodeDelegatorSignature(b64);
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, bytes);
      });
    });

    group('decodeWalletMessageSignature', () {
      test('returns failure for invalid format', () {
        final result = decodeWalletMessageSignature('');
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ApiError>());
      });

      test('returns failure for short input', () {
        final result = decodeWalletMessageSignature('abc');
        expect(result.isFailure, isTrue);
      });
    });

    group('createDelegatorEd25519Instruction', () {
      final delegator = Ed25519HDPublicKey.fromBase58(
        'Cs8KY3PiWrCMAytMsBRQo8EdGbticVtdvufLnb2UhXh',
      );
      const canonicalPayload = 'test_payload';
      final sig64 = Uint8List(64);
      final invalidSig = Uint8List(32);

      test('creates instruction with correct program ID', () {
        final result = createDelegatorEd25519Instruction(
          delegator: delegator,
          canonicalPayload: canonicalPayload,
          sig64: sig64,
        );

        expect(result.isSuccess, isTrue);
        final ix = result.dataOrNull!;
        expect(
          ix.programId.toBase58(),
          'Ed25519SigVerify111111111111111111111111111',
        );
      });

      test('instruction has no account metas', () {
        final result = createDelegatorEd25519Instruction(
          delegator: delegator,
          canonicalPayload: canonicalPayload,
          sig64: sig64,
        );

        final ix = result.dataOrNull!;
        expect(ix.accounts, isEmpty);
      });

      test('fails when sig is not 64 bytes', () {
        final result = createDelegatorEd25519Instruction(
          delegator: delegator,
          canonicalPayload: canonicalPayload,
          sig64: invalidSig,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ApiError>());
      });

      test('instruction data contains correct header', () {
        final result = createDelegatorEd25519Instruction(
          delegator: delegator,
          canonicalPayload: canonicalPayload,
          sig64: sig64,
        );

        final ix = result.dataOrNull!;
        final data = ix.data.toList();
        // header: flag=1, numSig=0 (Ed25519 precompile)
        expect(data[0], 1);
        expect(data[1], 0);
      });
    });
  });
}
