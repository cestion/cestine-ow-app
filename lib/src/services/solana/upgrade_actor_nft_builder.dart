import 'dart:typed_data';

import 'package:solana/dto.dart' show Encoding;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../../core/result.dart';
import '../../core/role_asset_error_messages.dart';
import 'delegator_signature.dart';
import 'partial_tx_serializer.dart';
import 'solana_ata_helpers.dart';
import 'solana_encode_helpers.dart';
import 'solana_program_ids.dart';
import 'story_pda.dart';

/// 演员 NFT 升级指令 discriminator。
///
/// Anchor 规则：`sha256("global:upgrade_actor_nft")[0..8]`。与同一 StoryProgram
/// 内 `refill_actor_stamina` / `batch_mint_actor_nft` / `create_actor_collection`
/// 的 discriminator 计算方式一致（均已校验匹配）。
const _upgradeDiscriminator = <int>[18, 145, 143, 253, 252, 119, 121, 70];

Result<Uint8List> encodeUpgradeActorNftData({
  required String assetId,
  required String canonicalPayload,
  required Uint8List delegatorSig,
}) {
  return encodeAssetIdPayloadInstructionData(
    discriminator: _upgradeDiscriminator,
    assetId: assetId,
    canonicalPayload: canonicalPayload,
    delegatorSig: delegatorSig,
  );
}

Instruction buildUpgradeActorNftInstruction({
  required Ed25519HDPublicKey programId,
  required Ed25519HDPublicKey user,
  required Ed25519HDPublicKey sponsor,
  required Ed25519HDPublicKey config,
  required Ed25519HDPublicKey collectionInfo,
  required Ed25519HDPublicKey collectionMint,
  required Ed25519HDPublicKey mint,
  required Ed25519HDPublicKey payTokenMint,
  required Ed25519HDPublicKey payerPayAccount,
  required Ed25519HDPublicKey treasury,
  required List<Ed25519HDPublicKey> burnAssetPdas,
  required Uint8List instructionData,
}) {
  // 账户顺序与链上 StoryProgram `upgrade_actor_nft` 指令严格对齐
  // （见 web Codama 生成的 upgradeActorNft.ts）：
  // user, sponor, config, collectionInfo, collectionMint(W), mint(W),
  // payTokenMint, payerPayAccount(W), treasury(W), instructions(sysvar),
  // mplCoreProgram, systemProgram, tokenProgram, ...burnAssetPdas(W)。
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: user, isSigner: true),
      AccountMeta.writeable(pubKey: sponsor, isSigner: true),
      AccountMeta.readonly(pubKey: config, isSigner: false),
      AccountMeta.readonly(pubKey: collectionInfo, isSigner: false),
      AccountMeta.writeable(pubKey: collectionMint, isSigner: false),
      AccountMeta.writeable(pubKey: mint, isSigner: false),
      AccountMeta.readonly(pubKey: payTokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: payerPayAccount, isSigner: false),
      AccountMeta.writeable(pubKey: treasury, isSigner: false),
      AccountMeta.readonly(
        pubKey: SolanaProgramIds.sysvarInstructions,
        isSigner: false,
      ),
      AccountMeta.readonly(
        pubKey: SolanaProgramIds.mplCoreProgram,
        isSigner: false,
      ),
      AccountMeta.readonly(
        pubKey: SolanaProgramIds.systemProgram,
        isSigner: false,
      ),
      AccountMeta.readonly(pubKey: TokenProgram.id, isSigner: false),
      for (final pda in burnAssetPdas)
        AccountMeta.writeable(pubKey: pda, isSigner: false),
    ],
    data: ByteArray(instructionData),
  );
}

class UpgradeActorNftBuildResult {
  final CompiledMessage compiledMessage;
  final Uint8List messageBytes;
  final String collectionAssetId;
  final String normalizedMainAssetId;

  const UpgradeActorNftBuildResult({
    required this.compiledMessage,
    required this.messageBytes,
    required this.collectionAssetId,
    required this.normalizedMainAssetId,
  });
}

/// 组装 sponsor 代付用的 partially-signed 交易消息（用户 signMessage 前）。
Future<Result<UpgradeActorNftBuildResult>> buildUpgradeActorNftMessage({
  required String rpcHttpUrl,
  required String storyProgramAddress,
  required String delegatorAddress,
  required String treasuryAddress,
  required String spenderAddress,
  required String userAddress,
  required int actorCollectionId,
  required int mainNftTokenId,
  required List<int> burnNftTokenIds,
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

  final mainAssetId = '${actorCollectionId}_$mainNftTokenId';
  final normalizedMainAssetId = mainAssetId.trim();

  final collectionAssetId = '$actorCollectionId';
  if (collectionAssetId.isEmpty) {
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

  final burnAssetIds = burnNftTokenIds
      .map((tokenId) => '${actorCollectionId}_$tokenId')
      .toList();

  final pdas = await Future.wait([
    StoryPda.findConfigPda(programId: programId),
    StoryPda.findCollectionInfoPda(
      programId: programId,
      collectionAssetId: collectionAssetId,
    ),
    StoryPda.findCollectionMintPda(
      programId: programId,
      collectionAssetId: collectionAssetId,
    ),
    StoryPda.findActorMintAssetPda(
      programId: programId,
      assetId: normalizedMainAssetId,
    ),
    // Burn asset PDAs
    for (final burnAssetId in burnAssetIds)
      StoryPda.findActorMintAssetPda(
        programId: programId,
        assetId: burnAssetId,
      ),
    // ATA accounts
    findAssociatedTokenAddress(owner: user, mint: payMint),
    findAssociatedTokenAddress(owner: treasury, mint: payMint),
  ]);

  final config = pdas[0];
  final collectionInfo = pdas[1];
  final collectionMint = pdas[2];
  final mainAsset = pdas[3];
  final burnAssetPdas = pdas
      .sublist(4, 4 + burnAssetIds.length)
      .cast<Ed25519HDPublicKey>();
  final payerPayAccount = pdas[4 + burnAssetIds.length];
  final treasuryAta = pdas[5 + burnAssetIds.length];

  final instructionDataResult = encodeUpgradeActorNftData(
    assetId: normalizedMainAssetId,
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

  final upgradeIx = buildUpgradeActorNftInstruction(
    programId: programId,
    user: user,
    sponsor: sponsor,
    config: config,
    collectionInfo: collectionInfo,
    collectionMint: collectionMint,
    mint: mainAsset,
    payTokenMint: payMint,
    payerPayAccount: payerPayAccount,
    treasury: treasuryAta,
    burnAssetPdas: burnAssetPdas,
    instructionData: instructionData,
  );

  final rpc = RpcClient(rpcHttpUrl);
  final latestBlockhash = await rpc.getLatestBlockhash(
    commitment: Commitment.confirmed,
  );

  final instructions = <Instruction>[ed25519Ix, upgradeIx];

  // 检查 payerPayAccount 是否存在，不存在则创建 ATA
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
    UpgradeActorNftBuildResult(
      compiledMessage: compiledMessage,
      messageBytes: Uint8List.fromList(compiledMessage.toByteArray().toList()),
      collectionAssetId: collectionAssetId,
      normalizedMainAssetId: normalizedMainAssetId,
    ),
  );
}

/// 序列化部分签名的交易（用户签名后，提交给 sponsor 前）。
Result<String> serializePartiallySignedUpgradeTransaction({
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
