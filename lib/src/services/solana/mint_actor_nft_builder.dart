import 'dart:convert';
import 'dart:typed_data';

import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../../core/result.dart';
import 'delegator_signature.dart';
import 'game_actor_nft.dart';
import 'partial_tx_serializer.dart';
import 'solana_compute_budget.dart';
import 'solana_encode_helpers.dart';
import 'solana_program_ids.dart';
import 'story_pda.dart';

export 'game_actor_nft.dart'
    show buildActorAssetId, resolveActorCollectionAssetId;
export 'solana_compute_budget.dart'
    show
        buildSetComputeUnitLimitInstruction,
        buildStoryNftMintComputeBudgetInstructions;

const _batchMintActorNftDiscriminator = <int>[
  88,
  201,
  32,
  83,
  171,
  30,
  229,
  71,
];

Result<Uint8List> encodeBatchMintActorNftData({
  required int mintCount,
  required String canonicalPayload,
  required Uint8List delegatorSig,
}) {
  final sigCheck = validateDelegatorSignature(delegatorSig);
  if (sigCheck.isFailure) {
    return Result.failure(sigCheck.errorOrNull!);
  }
  final payloadBytes = utf8.encode(canonicalPayload);
  final paramsBytes = [
    ...u32Le(payloadBytes.length),
    ...payloadBytes,
    ...delegatorSig,
  ];

  return Result.success(
    Uint8List.fromList([
      ..._batchMintActorNftDiscriminator,
      mintCount,
      ...paramsBytes,
    ]),
  );
}

/// 账户顺序对齐 web `buildBatchMintActorNftCoreAccountMetas` / 合约 `BatchMintActorNft`：
/// creator(w,s), sponor(w,s), config(w), collection_info(w), collection_mint(w),
/// pay_token_mint(r), creator_pay_account(w), treasury(w), vault(w),
/// instructions(r), mpl_core(r), system(r), token(r), + remaining Core assets(w)。
///
/// `config` 必须 writable：链上会更新 `GlobalConfig.latest_order_no`（payload 内 orderNo 防重放）。
Instruction buildBatchMintActorNftInstruction({
  required Ed25519HDPublicKey programId,
  required Ed25519HDPublicKey creator,
  required Ed25519HDPublicKey sponsor,
  required Ed25519HDPublicKey config,
  required Ed25519HDPublicKey collectionInfo,
  required Ed25519HDPublicKey collectionMint,
  required Ed25519HDPublicKey payTokenMint,
  required Ed25519HDPublicKey creatorPayAccount,
  required Ed25519HDPublicKey treasuryTokenAccount,
  required Ed25519HDPublicKey vaultTokenAccount,
  required List<Ed25519HDPublicKey> actorAssetAccounts,
  required Uint8List instructionData,
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: creator, isSigner: true),
      AccountMeta.writeable(pubKey: sponsor, isSigner: true),
      AccountMeta.writeable(pubKey: config, isSigner: false),
      AccountMeta.writeable(pubKey: collectionInfo, isSigner: false),
      AccountMeta.writeable(pubKey: collectionMint, isSigner: false),
      AccountMeta.readonly(pubKey: payTokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: creatorPayAccount, isSigner: false),
      AccountMeta.writeable(pubKey: treasuryTokenAccount, isSigner: false),
      AccountMeta.writeable(pubKey: vaultTokenAccount, isSigner: false),
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
      for (final asset in actorAssetAccounts)
        AccountMeta.writeable(pubKey: asset, isSigner: false),
    ],
    data: ByteArray(instructionData),
  );
}

/// 与 web `buildMintActorNftExecutionContext` 输出等价：仅组装指令，不含 blockhash compile。
class MintActorNftBuildContext {
  final List<Instruction> instructions;
  final Ed25519HDPublicKey feePayer;
  final String userAddress;
  final String rpcHttpUrl;
  final String collectionAssetId;
  final int mintStartIndex;
  final int mintCount;

  const MintActorNftBuildContext({
    required this.instructions,
    required this.feePayer,
    required this.userAddress,
    required this.rpcHttpUrl,
    required this.collectionAssetId,
    required this.mintStartIndex,
    required this.mintCount,
  });
}

class MintActorNftBuildResult {
  final CompiledMessage compiledMessage;
  final Uint8List messageBytes;
  final String blockhash;

  const MintActorNftBuildResult({
    required this.compiledMessage,
    required this.messageBytes,
    required this.blockhash,
  });
}

CompiledMessage compileMintActorNftMessage({
  required MintActorNftBuildContext context,
  required String recentBlockhash,
}) {
  return Message(
    instructions: context.instructions,
  ).compileV0(recentBlockhash: recentBlockhash, feePayer: context.feePayer);
}

Future<Result<MintActorNftBuildContext>> buildMintActorNftInstructions({
  required String rpcHttpUrl,
  required String storyProgramAddress,
  required String delegatorAddress,
  required String treasuryAddress,
  required String spenderAddress,
  required String userAddress,
  required String collectionAssetId,
  required String collectionMintAddress,
  required int mintStartIndex,
  required int mintCount,
  required String canonicalPayload,
  required String sigBase64,
  required String payTokenMint,
}) async {
  if (mintCount < 1 || mintCount > 10) {
    return Result.failure(
      ApiError.business(-1, 'Mint count must be between 1 and 10'),
    );
  }

  final programId = Ed25519HDPublicKey.fromBase58(storyProgramAddress);
  final user = Ed25519HDPublicKey.fromBase58(userAddress);
  final sponsor = Ed25519HDPublicKey.fromBase58(spenderAddress);
  final delegator = Ed25519HDPublicKey.fromBase58(delegatorAddress);
  final treasury = Ed25519HDPublicKey.fromBase58(treasuryAddress);
  final payMint = Ed25519HDPublicKey.fromBase58(payTokenMint);
  final collectionMint = Ed25519HDPublicKey.fromBase58(collectionMintAddress);

  final sigResult = decodeDelegatorSignature(sigBase64);
  if (sigResult.isFailure) {
    return Result.failure(sigResult.errorOrNull!);
  }
  final sig64 = sigResult.dataOrNull!;

  final configFuture = StoryPda.findConfigPda(programId: programId);
  final collectionInfoFuture = StoryPda.findCollectionInfoPda(
    programId: programId,
    collectionAssetId: collectionAssetId,
  );
  final creatorPayFuture = findAssociatedTokenAddress(
    owner: user,
    mint: payMint,
  );
  final treasuryAtaFuture = findAssociatedTokenAddress(
    owner: treasury,
    mint: payMint,
  );
  final vaultAtaFuture = configFuture.then(
    (config) => findAssociatedTokenAddress(owner: config, mint: payMint),
  );
  final assetFutures = <Future<Ed25519HDPublicKey>>[
    for (var i = 0; i < mintCount; i++)
      StoryPda.findActorMintAssetPda(
        programId: programId,
        assetId: buildActorAssetId(collectionAssetId, mintStartIndex + i),
      ),
  ];

  final resolved = await Future.wait([
    configFuture,
    collectionInfoFuture,
    creatorPayFuture,
    treasuryAtaFuture,
    vaultAtaFuture,
    ...assetFutures,
  ]);

  final config = resolved[0];
  final collectionInfo = resolved[1];
  final creatorPayAccount = resolved[2];
  final treasuryTokenAccount = resolved[3];
  final vaultTokenAccount = resolved[4];
  final actorAssets = resolved.sublist(5).cast<Ed25519HDPublicKey>();

  final instructionDataResult = encodeBatchMintActorNftData(
    mintCount: mintCount,
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

  final mintIx = buildBatchMintActorNftInstruction(
    programId: programId,
    creator: user,
    sponsor: sponsor,
    config: config,
    collectionInfo: collectionInfo,
    collectionMint: collectionMint,
    payTokenMint: payMint,
    creatorPayAccount: creatorPayAccount,
    treasuryTokenAccount: treasuryTokenAccount,
    vaultTokenAccount: vaultTokenAccount,
    actorAssetAccounts: actorAssets,
    instructionData: instructionData,
  );

  // 指令顺序对齐 web：computeBudget → ed25519 → mint
  final instructions = <Instruction>[
    ...buildStoryNftMintComputeBudgetInstructions(mintCount: mintCount),
    ed25519Ix,
    mintIx,
  ];

  return Result.success(
    MintActorNftBuildContext(
      instructions: instructions,
      feePayer: sponsor,
      userAddress: userAddress,
      rpcHttpUrl: rpcHttpUrl,
      collectionAssetId: collectionAssetId,
      mintStartIndex: mintStartIndex,
      mintCount: mintCount,
    ),
  );
}

Future<Result<MintActorNftBuildResult>> buildMintActorNftMessage({
  required String rpcHttpUrl,
  required String storyProgramAddress,
  required String delegatorAddress,
  required String treasuryAddress,
  required String spenderAddress,
  required String userAddress,
  required String collectionAssetId,
  required String collectionMintAddress,
  required int mintStartIndex,
  required int mintCount,
  required String canonicalPayload,
  required String sigBase64,
  required String payTokenMint,
}) async {
  final contextResult = await buildMintActorNftInstructions(
    rpcHttpUrl: rpcHttpUrl,
    storyProgramAddress: storyProgramAddress,
    delegatorAddress: delegatorAddress,
    treasuryAddress: treasuryAddress,
    spenderAddress: spenderAddress,
    userAddress: userAddress,
    collectionAssetId: collectionAssetId,
    collectionMintAddress: collectionMintAddress,
    mintStartIndex: mintStartIndex,
    mintCount: mintCount,
    canonicalPayload: canonicalPayload,
    sigBase64: sigBase64,
    payTokenMint: payTokenMint,
  );
  if (contextResult.isFailure) {
    return Result.failure(contextResult.errorOrNull!);
  }
  final context = contextResult.dataOrNull!;

  final rpc = RpcClient(context.rpcHttpUrl);
  final latestBlockhash = await rpc.getLatestBlockhash(
    commitment: Commitment.confirmed,
  );
  final compiledMessage = compileMintActorNftMessage(
    context: context,
    recentBlockhash: latestBlockhash.value.blockhash,
  );

  return Result.success(
    MintActorNftBuildResult(
      compiledMessage: compiledMessage,
      messageBytes: Uint8List.fromList(compiledMessage.toByteArray().toList()),
      blockhash: latestBlockhash.value.blockhash,
    ),
  );
}

Result<String> serializePartiallySignedMintTransaction({
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
