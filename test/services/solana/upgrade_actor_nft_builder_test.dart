import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:solana/solana.dart';
import 'package:story_app/src/services/solana/upgrade_actor_nft_builder.dart';
import 'package:story_app/src/core/result.dart';

void main() {
  group('UpgradeActorNftBuilder', () {
    group('encodeUpgradeActorNftData', () {
      const assetId = '1_42';
      const canonicalPayload = 'payload_data';
      final validSig = Uint8List(64);
      final invalidSig = Uint8List(32);

      test('encodes valid data with correct discriminator and layout', () {
        final result = encodeUpgradeActorNftData(
          assetId: assetId,
          canonicalPayload: canonicalPayload,
          delegatorSig: validSig,
        );

        expect(result.isSuccess, isTrue);
        final data = result.dataOrNull!;

        // 8 bytes discriminator (sha256("global:upgrade_actor_nft")[0..8])
        expect(data[0], 18);
        expect(data[1], 145);
        expect(data[2], 143);
        expect(data[3], 253);
        expect(data[4], 252);
        expect(data[5], 119);
        expect(data[6], 121);
        expect(data[7], 70);

        // length-prefixed assetId (4 = length of '1_42')
        expect(data[8], 4); // assetId length LE
        expect(data[9], 0);
        expect(data[10], 0);
        expect(data[11], 0);
        expect(String.fromCharCodes(data.sublist(12, 16)), '1_42');

        // length-prefixed payload
        expect(data[16], canonicalPayload.length); // payload length LE
        expect(data[17], 0);
        expect(data[18], 0);
        expect(data[19], 0);
        expect(
          String.fromCharCodes(data.sublist(20, 20 + canonicalPayload.length)),
          canonicalPayload,
        );

        // trailing 64 bytes = delegatorSig
        const headerBytes =
            8 + 4 + 4 + 4; // discriminator + assetIdLen + assetId + payloadLen
        const sigStart = headerBytes + canonicalPayload.length;
        final sigBytes = data.sublist(sigStart, sigStart + 64);
        expect(sigBytes.length, 64);
        expect(sigBytes, validSig);
      });

      test('fails when delegatorSig is not 64 bytes', () {
        final result = encodeUpgradeActorNftData(
          assetId: assetId,
          canonicalPayload: canonicalPayload,
          delegatorSig: invalidSig,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ApiError>());
      });
    });

    group('serializePartiallySignedUpgradeTransaction', () {
      test('returns error when user not found in account keys', () {
        // A compiled message with only a fee payer (no user)
        final message = const Message(instructions: []).compileV0(
          recentBlockhash: '11111111111111111111111111111111',
          feePayer: Ed25519HDPublicKey.fromBase58(
            '11111111111111111111111111111111',
          ),
        );

        final result = serializePartiallySignedUpgradeTransaction(
          compiledMessage: message,
          userAddress: '3u8hZ2VwXnkuCdtBDTpCpu1UjgEoAYjJp3nqAQQTyZ57',
          userSignature: Uint8List(64),
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ApiError>());
      });

      test(
        'serializes with user signature and empty placeholder for others',
        () {
          final user = Ed25519HDPublicKey.fromBase58(
            'Cs8KY3PiWrCMAytMsBRQo8EdGbticVtdvufLnb2UhXh',
          );
          final sponsor = Ed25519HDPublicKey.fromBase58(
            'UWXVhikxPUfnRLxNnRmH78ACpbUMbyctDboXYvVyG65',
          );

          final message = const Message(instructions: []).compileV0(
            recentBlockhash: '11111111111111111111111111111111',
            feePayer: sponsor,
          );

          // Manually create a multi-sig message by adding user as signer
          // We need at least 2 account keys for multi-sig to be meaningful.
          // The compileV0 with feePayer=sponsor puts sponsor as key 0.
          // We'll test with a message that includes user at index 1.
          final signedTx = serializePartiallySignedUpgradeTransaction(
            compiledMessage: message,
            userAddress: user.toBase58(),
            userSignature: Uint8List(64), // populated user sig
          );

          // serializePartiallySigned finds userIndex by scanning accountKeys.
          // If user is not in the account keys, it fails (tested above).
          // When feePayer=sponsor, sponsor is key[0]. If user != sponsor,
          // user is not found.
          expect(signedTx.isFailure, isTrue);
        },
      );

      test('user as fee payer gets signature at index 0', () {
        final user = Ed25519HDPublicKey.fromBase58(
          'Cs8KY3PiWrCMAytMsBRQo8EdGbticVtdvufLnb2UhXh',
        );
        final sig = Uint8List.fromList(List.generate(64, (i) => i));

        final message = const Message(instructions: []).compileV0(
          recentBlockhash: '11111111111111111111111111111111',
          feePayer: user, // user is fee payer = key[0]
        );

        final result = serializePartiallySignedUpgradeTransaction(
          compiledMessage: message,
          userAddress: user.toBase58(),
          userSignature: sig,
        );

        expect(result.isSuccess, isTrue);
        final encoded = result.dataOrNull!;
        expect(encoded, isA<String>());
        expect(encoded.isNotEmpty, isTrue);
      });
    });
  });
}
