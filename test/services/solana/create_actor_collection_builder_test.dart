import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:solana/solana.dart';
import 'package:story_app/src/services/solana/create_actor_collection_builder.dart';
import 'package:story_app/src/core/result.dart';

void main() {
  group('CreateActorCollectionBuilder', () {
    group('encodeCreateActorCollectionData', () {
      const assetId = '1';
      final validSig = Uint8List(64);
      final invalidSig = Uint8List(32);
      const canonicalPayload = 'payload';

      test('encodes valid data with correct discriminator and layout', () {
        final result = encodeCreateActorCollectionData(
          assetId: assetId,
          canonicalPayload: canonicalPayload,
          delegatorSig: validSig,
        );

        expect(result.isSuccess, isTrue);
        final data = result.dataOrNull!;

        // 8 bytes discriminator
        expect(data[0], 51);
        expect(data[1], 247);
        expect(data[2], 218);
        expect(data[3], 151);
        expect(data[4], 198);
        expect(data[5], 93);
        expect(data[6], 167);
        expect(data[7], 124);

        // length-prefixed assetId (1 = '1')
        expect(data[8], 1);
        expect(data[9], 0);
        expect(data[10], 0);
        expect(data[11], 0);
        expect(String.fromCharCodes(data.sublist(12, 13)), '1');

        // length-prefixed payload (7 = 'payload')
        expect(data[13], 7);
        expect(data[14], 0);
        expect(data[15], 0);
        expect(data[16], 0);
        expect(String.fromCharCodes(data.sublist(17, 24)), 'payload');

        // 64 bytes delegatorSig
        expect(data.sublist(24, 88), validSig);
      });

      test('fails when delegatorSig is not 64 bytes', () {
        final result = encodeCreateActorCollectionData(
          assetId: assetId,
          canonicalPayload: canonicalPayload,
          delegatorSig: invalidSig,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ApiError>());
      });

      test('encodes with multi-digit assetId', () {
        const longAssetId = '12345';
        final result = encodeCreateActorCollectionData(
          assetId: longAssetId,
          canonicalPayload: 'x',
          delegatorSig: validSig,
        );

        expect(result.isSuccess, isTrue);
        final data = result.dataOrNull!;
        // assetId length = 5
        expect(data[8], 5);
        expect(data[9], 0);
        expect(data[10], 0);
        expect(data[11], 0);
        expect(String.fromCharCodes(data.sublist(12, 17)), '12345');
      });
    });

    group('buildSetComputeUnitLimitInstruction', () {
      test('creates instruction with correct program id', () {
        final ix = buildSetComputeUnitLimitInstruction(400000);
        expect(
          ix.programId.toBase58(),
          'ComputeBudget111111111111111111111111111111',
        );
      });

      test('encodes units as u32 LE', () {
        const units = 400000;
        final ix = buildSetComputeUnitLimitInstruction(units);
        final data = ix.data.toList();
        // discriminator byte 2 for CU limit
        expect(data[0], 2);
        // 400000 = 0x61A80 in LE: 0x80, 0x1A, 0x06, 0x00
        expect(data[1], 0x80);
        expect(data[2], 0x1A);
        expect(data[3], 0x06);
        expect(data[4], 0x00);
      });
    });

    group('buildStoryNftMintComputeBudgetInstructions', () {
      test('single mint only sets compute unit limit', () {
        final ixs = buildStoryNftMintComputeBudgetInstructions();
        expect(ixs, hasLength(1));
        expect(ixs.first.data.toList()[0], 2);
      });

      test('batch mint adds request heap frame', () {
        final ixs = buildStoryNftMintComputeBudgetInstructions(mintCount: 2);
        expect(ixs, hasLength(2));
        expect(ixs[0].data.toList()[0], 2); // SetComputeUnitLimit
        expect(ixs[1].data.toList()[0], 1); // RequestHeapFrame
        final heapData = ixs[1].data.toList();
        // 256 * 1024 = 262144 = 0x40000 LE
        expect(heapData[1], 0x00);
        expect(heapData[2], 0x00);
        expect(heapData[3], 0x04);
        expect(heapData[4], 0x00);
      });
    });

    group('serializePartiallySignedCreateActorCollectionTransaction', () {
      test('returns error when user not found', () {
        final message = const Message(instructions: []).compileV0(
          recentBlockhash: '11111111111111111111111111111111',
          feePayer: Ed25519HDPublicKey.fromBase58(
            '11111111111111111111111111111111',
          ),
        );

        final result = serializePartiallySignedCreateActorCollectionTransaction(
          compiledMessage: message,
          userAddress: '5u8h3V2w3kuCdt2TpCq1UjgQoAYjQp3nVkAQTyg57',
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

        final result = serializePartiallySignedCreateActorCollectionTransaction(
          compiledMessage: message,
          userAddress: user.toBase58(),
          userSignature: sig,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!.isNotEmpty, isTrue);
      });
    });
  });
}
