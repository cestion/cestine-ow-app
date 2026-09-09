import 'dart:convert' hide Encoding;
import 'dart:typed_data';

import 'package:solana/dto.dart' show Encoding;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../../core/result.dart';
import '../../core/role_asset_error_messages.dart';
import 'delegator_signature.dart';
import 'game_actor_nft.dart';
import 'partial_tx_serializer.dart';
import 'solana_ata_helpers.dart';
import 'solana_encode_helpers.dart';
import 'solana_program_ids.dart';
import 'story_pda.dart';

const _refillDiscriminator = <int>[48, 197, 12, 133, 10, 207, 227, 120];

Result<Uint8List> encodeRefillActorStaminaData({
  required String assetId,
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

  final assetIdBytes = utf8.encode(assetId);
  final payloadBytes = utf8.encode(canonicalPayload);
  final paramsBytes = [
    ...u32Le(payloadBytes.length),
    ...payloadBytes,
    ...delegatorSig,
  ];

  return Result.success(
    Uint8List.fromList([
      ..._refillDiscriminator,
      ...u32Le(assetIdBytes.length),
      ...assetIdBytes,
      ...orderHash,
      ...paramsBytes,
    ]),
  );
}

Instruction buildRefillActorStaminaInstruction({
  required Ed25519HDPublicKey programId,
  required Ed25519HDPublicKey user,
  required Ed25519HDPublicKey sponsor,
  required Ed25519HDPublicKey config,
  required Ed25519HDPublicKey collectionInfo,
  required Ed25519HDPublicKey asset,
  required Ed25519HDPublicKey payTokenMint,
  required Ed25519HDPublicKey payerPayAccount,
  required Ed25519HDPublicKey treasuryAta,
  required Ed25519HDPublicKey refillRecord,
  required Uint8List instructionData,
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: user, isSigner: true),
      AccountMeta.writeable(pubKey: sponsor, isSigner: true),
      AccountMeta.readonly(pubKey: config, isSigner: false),
      AccountMeta.readonly(pubKey: collectionInfo, isSigner: false),
      AccountMeta.readonly(pubKey: asset, isSigner: false),
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
      AccountMeta.readonly(
        pubKey: SolanaProgramIds.associatedTokenProgram,
        isSigner: false,
      ),
    ],
    data: ByteArray(instructionData),
  );
}

class RefillStaminaBuildResult {
  final CompiledMessage compiledMessage;
  final Uint8List messageBytes;

  const RefillStaminaBuildResult({
    required this.compiledMessage,
    required this.messageBytes,
  });
}

/// 组装 sponsor 代付用的 partially-signed 交易消息（用户 signMessage 前）。
Future<Result<RefillStaminaBuildResult>> buildRefillStaminaMessage({
  required String rpcHttpUrl,
  required String storyProgramAddress,
  required String delegatorAddress,
  required String treasuryAddress,
  required String spenderAddress,
  required String userAddress,
  required String actorNftId,
  required int? actorCollectionId,
  required int? actorTokenId,
  required String orderNo,
  required String canonicalPayload,
  required String sigBase64,
  required String payTokenMint,
}) async {
  final programId = Ed25519HDPublicKey.fromBase58(storyProgramAddress);
  final user = Ed25519HDPublicKey.fromBase58(userAddress);
  final sponsor = Ed25519HDPublicKey.fromBase58(spenderAddress);
  final delegator = Ed25519HDPublicKey.fromBase58(delegatorAddress);
  final treasury = Ed25519HDPublicKey.fromBase58(treasuryAddress);
  final payMint = Ed25519HDPublicKey.fromBase58(payTokenMint);

  final assetId = resolveMainActorAssetId(
    actorNftId: actorNftId,
    actorCollectionId: actorCollectionId,
    actorTokenId: actorTokenId,
  );
  if (assetId == null) {
    return Result.failure(
      ApiError.business(-1, RoleAssetErrorMessages.invalidRoleNftAssetId),
    );
  }

  final collectionAssetId = resolveCollectionAssetIdFromActorNftId(
    actorNftId,
    actorCollectionId,
  );
  if (collectionAssetId == null) {
    return Result.failure(
      ApiError.business(
        -1,
        RoleAssetErrorMessages.invalidRoleCollectionAssetId,
      ),
    );
  }

  final sigResult = decodeDelegatorSignature(sigBase64);
  if (sigResult.isFailure) {
    return Result.failure(sigResult.errorOrNull!);
  }
  final sig64 = sigResult.dataOrNull!;
  final orderHash = resolveRefillOrderHash(orderNo);

  final pdas = await Future.wait([
    StoryPda.findConfigPda(programId: programId),
    StoryPda.findCollectionInfoPda(
      programId: programId,
      collectionAssetId: collectionAssetId,
    ),
    StoryPda.findActorMintAssetPda(programId: programId, assetId: assetId),
    StoryPda.findRefillRecordPda(programId: programId, orderHash: orderHash),
    findAssociatedTokenAddress(owner: user, mint: payMint),
    findAssociatedTokenAddress(owner: treasury, mint: payMint),
  ]);

  final config = pdas[0];
  final collectionInfo = pdas[1];
  final asset = pdas[2];
  final refillRecord = pdas[3];
  final payerPayAccount = pdas[4];
  final treasuryAta = pdas[5];

  final instructionDataResult = encodeRefillActorStaminaData(
    assetId: assetId,
    orderHash: orderHash,
    canonicalPayload: canonicalPayload,
    delegatorSig: sig64,
  );
  if (instructionDataResult.isFailure) {
    return Result.failure(instructionDataResult.errorOrNull!);
  }
  final instructionData = instructionDataResult.dataOrNull!;

  final ed25519IxResult = createDelegatorEd25519Instruction(
    delegator: delegator,
    canonicalPayload: canonicalPayload,
    sig64: sig64,
  );
  if (ed25519IxResult.isFailure) {
    return Result.failure(ed25519IxResult.errorOrNull!);
  }
  final ed25519Ix = ed25519IxResult.dataOrNull!;

  final refillIx = buildRefillActorStaminaInstruction(
    programId: programId,
    user: user,
    sponsor: sponsor,
    config: config,
    collectionInfo: collectionInfo,
    asset: asset,
    payTokenMint: payMint,
    payerPayAccount: payerPayAccount,
    treasuryAta: treasuryAta,
    refillRecord: refillRecord,
    instructionData: instructionData,
  );

  final rpc = RpcClient(rpcHttpUrl);
  final latestBlockhash = await rpc.getLatestBlockhash(
    commitment: Commitment.confirmed,
  );

  final instructions = <Instruction>[ed25519Ix, refillIx];

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
    RefillStaminaBuildResult(
      compiledMessage: compiledMessage,
      messageBytes: Uint8List.fromList(compiledMessage.toByteArray().toList()),
    ),
  );
}

Result<String> serializePartiallySignedRefillTransaction({
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
