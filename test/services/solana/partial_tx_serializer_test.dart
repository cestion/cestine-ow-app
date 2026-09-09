import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/services/solana/mint_actor_nft_builder.dart';
import 'package:story_app/src/services/solana/partial_tx_serializer.dart';

void main() {
  group('serializePartiallySignedTransaction', () {
    test('writes user signature at creator index when sponsor is fee payer', () {
      final user = Ed25519HDPublicKey.fromBase58(
        'Cs8KY3PiWrCMAytMsBRQo8EdGbticVtdvufLnb2UhXh',
      );
      final sponsor = Ed25519HDPublicKey.fromBase58(
        'Dy9c2P6gaNeqg2Q9knTsahBUGZPuoB5rEZM7mAYkTRvo',
      );
      final programId = Ed25519HDPublicKey.fromBase58(
        'CJEnSe9eJ3s8qLQNdWrcHQpp6199s4NohcBBHZ3UeRQL',
      );

      final mintIx = buildBatchMintActorNftInstruction(
        programId: programId,
        creator: user,
        sponsor: sponsor,
        config: Ed25519HDPublicKey.fromBase58(
          'Sysvar1nstructions1111111111111111111111111',
        ),
        collectionInfo: Ed25519HDPublicKey.fromBase58(
          'SysvarC1ock11111111111111111111111111111111',
        ),
        collectionMint: Ed25519HDPublicKey.fromBase58(
          'SysvarRent111111111111111111111111111111111',
        ),
        payTokenMint: Ed25519HDPublicKey.fromBase58(
          'So11111111111111111111111111111111111111112',
        ),
        creatorPayAccount: Ed25519HDPublicKey.fromBase58(
          'Stake11111111111111111111111111111111111111',
        ),
        treasuryTokenAccount: Ed25519HDPublicKey.fromBase58(
          'Vote111111111111111111111111111111111111111',
        ),
        vaultTokenAccount: Ed25519HDPublicKey.fromBase58(
          'Config1111111111111111111111111111111111111',
        ),
        actorAssetAccounts: [
          Ed25519HDPublicKey.fromBase58(
            'MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr',
          ),
        ],
        instructionData: Uint8List(8),
      );

      final message = Message(instructions: [mintIx]).compileV0(
        recentBlockhash: '11111111111111111111111111111111',
        feePayer: sponsor,
      );

      expect(message.requiredSignatureCount, 2);
      expect(
        message.map(
          legacy: (m) => m.accountKeys[0].toBase58(),
          v0: (m) => m.accountKeys[0].toBase58(),
        ),
        sponsor.toBase58(),
      );
      expect(
        message.map(
          legacy: (m) => m.accountKeys[1].toBase58(),
          v0: (m) => m.accountKeys[1].toBase58(),
        ),
        user.toBase58(),
      );

      final userSig = Uint8List.fromList(List.generate(64, (i) => i + 1));
      final result = serializePartiallySignedTransaction(
        compiledMessage: message,
        userAddress: user.toBase58(),
        userSignature: userSig,
      );

      expect(result.isSuccess, isTrue);
      final decoded = SignedTx.decode(result.dataOrNull!);
      expect(decoded.signatures[0].toBase58(), startsWith('1111111'));
      expect(decoded.signatures[1].toBase58(), isNot(startsWith('1111111')));
    });

    test('fails when user is not a required signer', () {
      final sponsor = Ed25519HDPublicKey.fromBase58(
        'Dy9c2P6gaNeqg2Q9knTsahBUGZPuoB5rEZM7mAYkTRvo',
      );
      final message = const Message(instructions: []).compileV0(
        recentBlockhash: '11111111111111111111111111111111',
        feePayer: sponsor,
      );

      final result = serializePartiallySignedTransaction(
        compiledMessage: message,
        userAddress: 'Cs8KY3PiWrCMAytMsBRQo8EdGbticVtdvufLnb2UhXh',
        userSignature: Uint8List(64),
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ApiError>());
    });
  });
}
