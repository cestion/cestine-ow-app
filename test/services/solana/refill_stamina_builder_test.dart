import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:solana/solana.dart';
import 'package:story_app/src/services/solana/refill_stamina_builder.dart';
import 'package:story_app/src/core/result.dart';

void main() {
  group('RefillStaminaBuilder', () {
    group('encodeRefillActorStaminaData', () {
      const assetId = '1_42';
      final validSig = Uint8List(64);
      final invalidSig = Uint8List(32);
      final validHash = Uint8List(32);
      final invalidHash = Uint8List(16);
      const canonicalPayload = 'payload';

      test('encodes valid data with correct discriminator and layout', () {
        final result = encodeRefillActorStaminaData(
          assetId: assetId,
          orderHash: validHash,
          canonicalPayload: canonicalPayload,
          delegatorSig: validSig,
        );

        expect(result.isSuccess, isTrue);
        final data = result.dataOrNull!;

        // 8 bytes discriminator
        expect(data[0], 48);
        expect(data[1], 197);
        expect(data[2], 12);
        expect(data[3], 133);
        expect(data[4], 10);
        expect(data[5], 207);
        expect(data[6], 227);
        expect(data[7], 120);

        // length-prefixed assetId (4 = '1_42')
        expect(data[8], 4);
        expect(data[9], 0);
        expect(data[10], 0);
        expect(data[11], 0);
        expect(String.fromCharCodes(data.sublist(12, 16)), '1_42');

        // 32 bytes orderHash
        expect(data.sublist(16, 48), validHash);

        // length-prefixed payload (7 = 'payload')
        expect(data[48], 7);
        expect(data[49], 0);
        expect(data[50], 0);
        expect(data[51], 0);
        expect(String.fromCharCodes(data.sublist(52, 59)), 'payload');

        // 64 bytes delegatorSig
        expect(data.sublist(59, 123), validSig);
      });

      test('fails when orderHash is not 32 bytes', () {
        final result = encodeRefillActorStaminaData(
          assetId: assetId,
          orderHash: invalidHash,
          canonicalPayload: canonicalPayload,
          delegatorSig: validSig,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ApiError>());
      });

      test('fails when delegatorSig is not 64 bytes', () {
        final result = encodeRefillActorStaminaData(
          assetId: assetId,
          orderHash: validHash,
          canonicalPayload: canonicalPayload,
          delegatorSig: invalidSig,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ApiError>());
      });
    });

    group('serializePartiallySignedRefillTransaction', () {
      test('returns error when user not found in account keys', () {
        final message = const Message(instructions: []).compileV0(
          recentBlockhash: '11111111111111111111111111111111',
          feePayer: Ed25519HDPublicKey.fromBase58(
            '11111111111111111111111111111111',
          ),
        );

        final result = serializePartiallySignedRefillTransaction(
          compiledMessage: message,
          userAddress: '5u8h3Z2w3kuCdt2TpCq1UjgQoAYjQp3nVQqQTyg57',
          userSignature: Uint8List(64),
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ApiError>());
      });

      test('succeeds when user is fee payer', () {
        final user = Ed25519HDPublicKey.fromBase58(
          'Cs8KY3PiWrCMAytMsBRQo8EdGbticVtdvufLnb2UhXh',
        );
        final sig = Uint8List.fromList(List.generate(64, (i) => i));

        final message = const Message(instructions: []).compileV0(
          recentBlockhash: '11111111111111111111111111111111',
          feePayer: user,
        );

        final result = serializePartiallySignedRefillTransaction(
          compiledMessage: message,
          userAddress: user.toBase58(),
          userSignature: sig,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isA<String>());
        expect(result.dataOrNull!.isNotEmpty, isTrue);
      });
    });
  });
}
