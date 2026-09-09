import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:solana/solana.dart';
import 'package:story_app/src/services/solana/mint_actor_nft_builder.dart';
import 'package:story_app/src/core/result.dart';

void main() {
  group('MintActorNftBuilder', () {
    group('encodeBatchMintActorNftData', () {
      final validSig = Uint8List(64);
      final invalidSig = Uint8List(32);
      const canonicalPayload = 'payload';

      test('encodes valid data with correct discriminator and layout', () {
        const mintCount = 3;
        final result = encodeBatchMintActorNftData(
          mintCount: mintCount,
          canonicalPayload: canonicalPayload,
          delegatorSig: validSig,
        );

        expect(result.isSuccess, isTrue);
        final data = result.dataOrNull!;

        // 8 bytes discriminator
        expect(data[0], 88);
        expect(data[1], 201);
        expect(data[2], 32);
        expect(data[3], 83);
        expect(data[4], 171);
        expect(data[5], 30);
        expect(data[6], 229);
        expect(data[7], 71);

        // mintCount as single byte
        expect(data[8], mintCount);

        // length-prefixed payload (7 = 'payload')
        expect(data[9], 7);
        expect(data[10], 0);
        expect(data[11], 0);
        expect(data[12], 0);
        expect(String.fromCharCodes(data.sublist(13, 20)), 'payload');

        // 64 bytes delegatorSig
        expect(data.sublist(20, 84), validSig);
      });

      test('fails when delegatorSig is not 64 bytes', () {
        final result = encodeBatchMintActorNftData(
          mintCount: 1,
          canonicalPayload: canonicalPayload,
          delegatorSig: invalidSig,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ApiError>());
      });

      test('encodes with minimal mintCount of 1', () {
        final result = encodeBatchMintActorNftData(
          mintCount: 1,
          canonicalPayload: 'x',
          delegatorSig: validSig,
        );

        expect(result.isSuccess, isTrue);
        final data = result.dataOrNull!;
        expect(data[8], 1); // mintCount = 1
      });
    });

    group('buildActorAssetId', () {
      test('joins collection and token with underscore', () {
        expect(buildActorAssetId('5', 12), '5_12');
        expect(buildActorAssetId('col', 0), 'col_0');
      });
    });

    group('buildBatchMintActorNftInstruction', () {
      test('marks config writable for latest_order_no updates', () {
        final programId = Ed25519HDPublicKey.fromBase58(
          '11111111111111111111111111111111',
        );
        final creator = Ed25519HDPublicKey.fromBase58(
          'Cs8KY3PiWrCMAytMsBRQo8EdGbticVtdvufLnb2UhXh',
        );
        final sponsor = Ed25519HDPublicKey.fromBase58(
          'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA',
        );
        final config = Ed25519HDPublicKey.fromBase58(
          'Sysvar1nstructions1111111111111111111111111',
        );
        final collectionInfo = Ed25519HDPublicKey.fromBase58(
          'SysvarC1ock11111111111111111111111111111111',
        );
        final collectionMint = Ed25519HDPublicKey.fromBase58(
          'SysvarRent111111111111111111111111111111111',
        );
        final payTokenMint = Ed25519HDPublicKey.fromBase58(
          'So11111111111111111111111111111111111111112',
        );
        final creatorPay = Ed25519HDPublicKey.fromBase58(
          'Stake11111111111111111111111111111111111111',
        );
        final treasury = Ed25519HDPublicKey.fromBase58(
          'Vote111111111111111111111111111111111111111',
        );
        final vault = Ed25519HDPublicKey.fromBase58(
          'Config1111111111111111111111111111111111111',
        );
        final asset = Ed25519HDPublicKey.fromBase58(
          'MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr',
        );

        final ix = buildBatchMintActorNftInstruction(
          programId: programId,
          creator: creator,
          sponsor: sponsor,
          config: config,
          collectionInfo: collectionInfo,
          collectionMint: collectionMint,
          payTokenMint: payTokenMint,
          creatorPayAccount: creatorPay,
          treasuryTokenAccount: treasury,
          vaultTokenAccount: vault,
          actorAssetAccounts: [asset],
          instructionData: Uint8List(8),
        );

        // Account index 2 = config; must be writable.
        expect(ix.accounts[2].pubKey, config);
        expect(ix.accounts[2].isWriteable, isTrue);
        expect(ix.accounts[2].isSigner, isFalse);
        // Account index 8 = vault (web buildBatchMintActorNftCoreAccountMetas).
        expect(ix.accounts[8].pubKey, vault);
        expect(ix.accounts[8].isWriteable, isTrue);
        expect(ix.accounts.length, 14); // 13 fixed + 1 asset
      });
    });

    group('serializePartiallySignedMintTransaction', () {
      test('returns error when user not found', () {
        final message = const Message(instructions: []).compileV0(
          recentBlockhash: '11111111111111111111111111111111',
          feePayer: Ed25519HDPublicKey.fromBase58(
            '11111111111111111111111111111111',
          ),
        );

        final result = serializePartiallySignedMintTransaction(
          compiledMessage: message,
          userAddress: '5u8h3V2w3kuCdt2TpCq1UjgQoAYjQp3nVqAQTyg57',
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

        final result = serializePartiallySignedMintTransaction(
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
