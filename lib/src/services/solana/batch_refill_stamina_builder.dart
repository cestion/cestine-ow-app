import 'dart:convert' hide Encoding;
import 'dart:typed_data';

import 'package:solana/dto.dart' show Encoding;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../../core/result.dart';
import 'delegator_signature.dart';
import 'game_actor_nft.dart';
import 'partial_tx_serializer.dart';
import 'solana_ata_helpers.dart';
import 'solana_encode_helpers.dart';
import 'solana_program_ids.dart';
import 'story_pda.dart';

const _batchRefillDiscriminator = <int>[67, 159, 179, 127, 253, 208, 205, 128];

Result<Uint8List> encodeBatchRefillActorStaminaData({
  required Uint8List orderHash,
  required String canonicalPayload,
  required Uint8List delegatorSig,
}) {
  final orderCheck = validateOrderHash(orderHash);
  if (orderCheck.isFailure) {
    return Result.failure(orderCheck.errorOrNull!);
  }
  final sigCheck = validateDelegatorSignature(delegatorSig);
  if (sigCheck.isFailure) {
    return Result.failure(sigCheck.errorOrNull!);
  }

  final payloadBytes = utf8.encode(canonicalPayload);
  return Result.success(
    Uint8List.fromList([
      ..._batchRefillDiscriminator,
      ...orderHash,
      ...u32Le(payloadBytes.length),
      ...payloadBytes,
      ...delegatorSig,
    ]),
  );
}

Instruction buildBatchRefillActorStaminaInstruction({
  required Ed25519HDPublicKey programId,
  required Ed25519HDPublicKey user,
  required Ed25519HDPublicKey sponsor,
  required Ed25519HDPublicKey config,
  required Ed25519HDPublicKey payTokenMint,
  required Ed25519HDPublicKey payerPayAccount,
  required Ed25519HDPublicKey treasuryAta,
  required Ed25519HDPublicKey refillRecord,
  required List<Ed25519HDPublicKey> actorAssets,
  required Uint8List instructionData,
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: user, isSigner: true),
      AccountMeta.writeable(pubKey: sponsor, isSigner: true),
      AccountMeta.readonly(pubKey: config, isSigner: false),
      AccountMeta.readonly(pubKey: payTokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: payerPayAccount, isSigner: false),
      AccountMeta.writeable(pubKey: treasuryAta, isSigner: false),
      AccountMeta.writeable(pubKey: refillRecord, isSigner: false),
      AccountMeta.readonly(
        pubKey: SolanaProgramIds.sysvarInstructions,
        isSigner: false,
      ),
      AccountMeta.readonly(
        pubKey: SolanaProgramIds.systemProgram,
        isSigner: false,
      ),
      AccountMeta.readonly(pubKey: TokenProgram.id, isSigner: false),
      for (final actorAsset in actorAssets)
        AccountMeta.readonly(pubKey: actorAsset, isSigner: false),
    ],
    data: ByteArray(instructionData),
  );
}

class BatchRefillStaminaBuildResult {
  final CompiledMessage compiledMessage;
  final Uint8List messageBytes;

  const BatchRefillStaminaBuildResult({
    required this.compiledMessage,
    required this.messageBytes,
  });
}

Future<Result<BatchRefillStaminaBuildResult>> buildBatchRefillStaminaMessage({
  required String rpcHttpUrl,
  required String storyProgramAddress,
  required String delegatorAddress,
  required String treasuryAddress,
  required String spenderAddress,
  required String userAddress,
  required List<String> actorAssetIds,
  required String orderNo,
  required String canonicalPayload,
  required String sigBase64,
  required String payTokenMint,
}) async {
  final normalizedAssetIds = actorAssetIds
      .map((id) => id.trim().replaceFirst(RegExp(r'^#'), ''))
      .where((id) => id.isNotEmpty)
      .toList(growable: false);
  if (normalizedAssetIds.isEmpty || normalizedAssetIds.length > 5) {
    return Result.failure(
      ApiError.validation('Batch refill requires between 1 and 5 actors'),
    );
  }

  final programId = Ed25519HDPublicKey.fromBase58(storyProgramAddress);
  final user = Ed25519HDPublicKey.fromBase58(userAddress);
  final sponsor = Ed25519HDPublicKey.fromBase58(spenderAddress);
  final delegator = Ed25519HDPublicKey.fromBase58(delegatorAddress);
  final treasury = Ed25519HDPublicKey.fromBase58(treasuryAddress);
  final payMint = Ed25519HDPublicKey.fromBase58(payTokenMint);
  final sigResult = decodeDelegatorSignature(sigBase64);
  if (sigResult.isFailure) {
    return Result.failure(sigResult.errorOrNull!);
  }

  final orderHash = resolveRefillOrderHash(orderNo);
  final fixedPdas = await Future.wait([
    StoryPda.findConfigPda(programId: programId),
    StoryPda.findRefillRecordPda(programId: programId, orderHash: orderHash),
    findAssociatedTokenAddress(owner: user, mint: payMint),
    findAssociatedTokenAddress(owner: treasury, mint: payMint),
  ]);
  final actorAssets = await Future.wait(
    normalizedAssetIds.map(
      (assetId) => StoryPda.findActorMintAssetPda(
        programId: programId,
        assetId: assetId,
      ),
    ),
  );

  final config = fixedPdas[0];
  final refillRecord = fixedPdas[1];
  final payerPayAccount = fixedPdas[2];
  final treasuryAta = fixedPdas[3];
  final instructionDataResult = encodeBatchRefillActorStaminaData(
    orderHash: orderHash,
    canonicalPayload: canonicalPayload,
    delegatorSig: sigResult.dataOrNull!,
  );
  if (instructionDataResult.isFailure) {
    return Result.failure(instructionDataResult.errorOrNull!);
  }

  final ed25519IxResult = createDelegatorEd25519Instruction(
    delegator: delegator,
    canonicalPayload: canonicalPayload,
    sig64: sigResult.dataOrNull!,
  );
  if (ed25519IxResult.isFailure) {
    return Result.failure(ed25519IxResult.errorOrNull!);
  }

  final refillIx = buildBatchRefillActorStaminaInstruction(
    programId: programId,
    user: user,
    sponsor: sponsor,
    config: config,
    payTokenMint: payMint,
    payerPayAccount: payerPayAccount,
    treasuryAta: treasuryAta,
    refillRecord: refillRecord,
    actorAssets: actorAssets,
    instructionData: instructionDataResult.dataOrNull!,
  );

  final rpc = RpcClient(rpcHttpUrl);
  final latestBlockhash = await rpc.getLatestBlockhash(
    commitment: Commitment.confirmed,
  );
  final instructions = <Instruction>[ed25519IxResult.dataOrNull!, refillIx];
  final payerAccount = await rpc.getAccountInfo(
    payerPayAccount.toBase58(),
    commitment: Commitment.confirmed,
    encoding: Encoding.base64,
  );
  if (payerAccount.value == null) {
    instructions.insert(
      0,
      createIdempotentAtaInstruction(
        funder: sponsor,
        address: payerPayAccount,
        owner: user,
        mint: payMint,
      ),
    );
  }

  final compiledMessage = Message(instructions: instructions).compileV0(
    recentBlockhash: latestBlockhash.value.blockhash,
    feePayer: sponsor,
  );
  return Result.success(
    BatchRefillStaminaBuildResult(
      compiledMessage: compiledMessage,
      messageBytes: Uint8List.fromList(compiledMessage.toByteArray().toList()),
    ),
  );
}

Result<String> serializePartiallySignedBatchRefillTransaction({
  required CompiledMessage compiledMessage,
  required String userAddress,
  required Uint8List userSignature,
}) {
  return serializePartiallySignedTransaction(
    compiledMessage: compiledMessage,
    userAddress: userAddress,
    userSignature: userSignature,
  );
}
