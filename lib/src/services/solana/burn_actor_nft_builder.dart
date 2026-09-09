import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:solana/dto.dart' show Encoding;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../../core/result.dart';
import 'delegator_signature.dart';
import 'generated/story_program.g.dart';
import 'solana_ata_helpers.dart';
import 'solana_program_ids.dart';
import 'story_pda.dart';

class BurnActorNftBuildResult {
  final CompiledMessage compiledMessage;
  final String assetId;
  final String orderNo;

  const BurnActorNftBuildResult({
    required this.compiledMessage,
    required this.assetId,
    required this.orderNo,
  });
}

/// Builds the sponsored `burn_actor_nft` transaction.
///
/// The server signature is verified by the Ed25519 program before the Story
/// instruction. The order number is hashed into the burn-record PDA so a
/// signed order cannot be replayed.
Future<Result<BurnActorNftBuildResult>> buildBurnActorNftMessage({
  required String rpcHttpUrl,
  required String storyProgramAddress,
  required String delegatorAddress,
  required String spenderAddress,
  required String userAddress,
  required String collectionAssetId,
  required String assetId,
  required String orderNo,
  required String canonicalPayload,
  required String sigBase64,
  required String payTokenMint,
}) async {
  final validation = validateBurnActorNftOrder(
    userAddress: userAddress,
    assetId: assetId,
    orderNo: orderNo,
    canonicalPayload: canonicalPayload,
  );
  if (validation != null) return Result.failure(validation);

  try {
    final programId = Ed25519HDPublicKey.fromBase58(storyProgramAddress);
    final user = Ed25519HDPublicKey.fromBase58(userAddress);
    final sponsor = Ed25519HDPublicKey.fromBase58(spenderAddress);
    final delegator = Ed25519HDPublicKey.fromBase58(delegatorAddress);
    final payMint = Ed25519HDPublicKey.fromBase58(payTokenMint);

    final signatureResult = decodeDelegatorSignature(sigBase64);
    if (signatureResult.isFailure) {
      return Result.failure(signatureResult.errorOrNull!);
    }
    final signature = signatureResult.dataOrNull!;
    final orderHash = resolveBurnActorNftOrderHash(orderNo);

    final configFuture = StoryPda.findConfigPda(programId: programId);
    final resolved = await Future.wait<Ed25519HDPublicKey>([
      configFuture,
      StoryPda.findCollectionInfoPda(
        programId: programId,
        collectionAssetId: collectionAssetId,
      ),
      StoryPda.findCollectionMintPda(
        programId: programId,
        collectionAssetId: collectionAssetId,
      ),
      StoryPda.findActorMintAssetPda(programId: programId, assetId: assetId),
      findBurnActorNftBurnRecordPda(programId: programId, orderHash: orderHash),
      configFuture.then(
        (config) => findAssociatedTokenAddress(owner: config, mint: payMint),
      ),
      findAssociatedTokenAddress(owner: user, mint: payMint),
    ]);

    final verifyResult = createDelegatorEd25519Instruction(
      delegator: delegator,
      canonicalPayload: canonicalPayload,
      sig64: signature,
    );
    if (verifyResult.isFailure) {
      return Result.failure(verifyResult.errorOrNull!);
    }

    final burnInstruction = buildBurnActorNftInstruction(
      programId: programId,
      accounts: BurnActorNftAccounts(
        user: user,
        sponor: sponsor,
        config: resolved[0],
        collectionInfo: resolved[1],
        collectionMint: resolved[2],
        asset: resolved[3],
        payTokenMint: payMint,
        vault: resolved[5],
        refundRecipient: resolved[6],
        burnRecord: resolved[4],
        instructions: SolanaProgramIds.sysvarInstructions,
        mplCoreProgram: SolanaProgramIds.mplCoreProgram,
        systemProgram: SolanaProgramIds.systemProgram,
        tokenProgram: TokenProgram.id,
      ),
      assetId: assetId,
      orderHash: orderHash,
      params: StorySignedParams(
        canonicalPayload: canonicalPayload,
        sig: signature,
      ),
    );

    final rpc = RpcClient(rpcHttpUrl);
    final latestBlockhash = await rpc.getLatestBlockhash(
      commitment: Commitment.confirmed,
    );
    final instructions = <Instruction>[
      verifyResult.dataOrNull!,
      burnInstruction,
    ];

    // A fresh wallet might not have a USDC ATA yet. Create it idempotently so
    // the refund destination always exists before the burn instruction runs.
    final refundAccount = await rpc.getAccountInfo(
      resolved[6].toBase58(),
      commitment: Commitment.confirmed,
      encoding: Encoding.base64,
    );
    if (refundAccount.value == null) {
      instructions.insert(
        0,
        createIdempotentAtaInstruction(
          funder: sponsor,
          address: resolved[6],
          owner: user,
          mint: payMint,
        ),
      );
    }

    return Result.success(
      BurnActorNftBuildResult(
        compiledMessage: Message(instructions: instructions).compileV0(
          recentBlockhash: latestBlockhash.value.blockhash,
          feePayer: sponsor,
        ),
        assetId: assetId,
        orderNo: orderNo,
      ),
    );
  } on FormatException catch (error) {
    return Result.failure(
      ApiError.validation('Invalid recycle address: ${error.message}'),
    );
  } catch (error) {
    return Result.failure(
      ApiError.unknown(
        'Failed to build actor recycle transaction: $error',
        exception: error is Exception ? error : null,
      ),
    );
  }
}

Uint8List resolveBurnActorNftOrderHash(String orderNo) =>
    Uint8List.fromList(sha256.convert(utf8.encode(orderNo.trim())).bytes);

ApiError? validateBurnActorNftOrder({
  required String userAddress,
  required String assetId,
  required String orderNo,
  required String canonicalPayload,
  DateTime? now,
}) {
  final normalizedUser = userAddress.trim();
  final normalizedAsset = assetId.trim();
  final normalizedOrder = orderNo.trim();
  if (normalizedUser.isEmpty ||
      normalizedAsset.isEmpty ||
      normalizedOrder.isEmpty) {
    return ApiError.validation('Incomplete actor recycle order');
  }

  final parts = canonicalPayload.split('|');
  if (parts.length != 6 ||
      parts[0] != 'actor_nft_burn' ||
      parts[1] != normalizedAsset ||
      parts[2] != normalizedUser ||
      parts[4] != normalizedOrder ||
      BigInt.tryParse(parts[3]) == null) {
    return ApiError.validation('Actor recycle order does not match request');
  }
  final expiresAt = int.tryParse(parts[5]);
  final nowSeconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  if (expiresAt == null || expiresAt <= nowSeconds) {
    return ApiError.validation('Actor recycle signature has expired');
  }
  return null;
}
