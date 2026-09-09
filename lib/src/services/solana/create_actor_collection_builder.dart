import 'dart:typed_data';

import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../../core/result.dart';
import 'delegator_signature.dart';
import 'partial_tx_serializer.dart';
import 'solana_compute_budget.dart';
import 'solana_encode_helpers.dart';
import 'solana_program_ids.dart';
import 'story_pda.dart';

export 'solana_compute_budget.dart'
    show
        buildSetComputeUnitLimitInstruction,
        buildStoryNftMintComputeBudgetInstructions;

const _createActorCollectionDiscriminator = <int>[
  51,
  247,
  218,
  151,
  198,
  93,
  167,
  124,
];

Result<Uint8List> encodeCreateActorCollectionData({
  required String assetId,
  required String canonicalPayload,
  required Uint8List delegatorSig,
}) {
  return encodeAssetIdPayloadInstructionData(
    discriminator: _createActorCollectionDiscriminator,
    assetId: assetId,
    canonicalPayload: canonicalPayload,
    delegatorSig: delegatorSig,
  );
}

Instruction buildCreateActorCollectionInstruction({
  required Ed25519HDPublicKey programId,
  required Ed25519HDPublicKey creator,
  required Ed25519HDPublicKey sponsor,
  required Ed25519HDPublicKey config,
  required Ed25519HDPublicKey collection,
  required Ed25519HDPublicKey collectionInfo,
  required Ed25519HDPublicKey payTokenMint,
  required Ed25519HDPublicKey creatorPayAccount,
  required Ed25519HDPublicKey treasuryTokenAccount,
  required Uint8List instructionData,
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: creator, isSigner: true),
      AccountMeta.writeable(pubKey: sponsor, isSigner: true),
      AccountMeta.readonly(pubKey: config, isSigner: false),
      AccountMeta.writeable(pubKey: collection, isSigner: false),
      AccountMeta.writeable(pubKey: collectionInfo, isSigner: false),
      AccountMeta.readonly(pubKey: payTokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: creatorPayAccount, isSigner: false),
      AccountMeta.writeable(pubKey: treasuryTokenAccount, isSigner: false),
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
    ],
    data: ByteArray(instructionData),
  );
}

class CreateActorCollectionBuildResult {
  final CompiledMessage compiledMessage;
  final Uint8List messageBytes;
  final String blockhash;
  final String payTokenMint;

  const CreateActorCollectionBuildResult({
    required this.compiledMessage,
    required this.messageBytes,
    required this.blockhash,
    required this.payTokenMint,
  });
}

Future<Result<CreateActorCollectionBuildResult>>
buildCreateActorCollectionMessage({
  required String rpcHttpUrl,
  required String storyProgramAddress,
  required String delegatorAddress,
  required String treasuryAddress,
  required String spenderAddress,
  required String userAddress,
  required String assetId,
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

  final sigResult = decodeDelegatorSignature(sigBase64);
  if (sigResult.isFailure) {
    return Result.failure(sigResult.errorOrNull!);
  }
  final sig64 = sigResult.dataOrNull!;

  final configFuture = StoryPda.findConfigPda(programId: programId);
  final collectionFuture = StoryPda.findCollectionMintPda(
    programId: programId,
    collectionAssetId: assetId,
  );
  final collectionInfoFuture = StoryPda.findCollectionInfoPda(
    programId: programId,
    collectionAssetId: assetId,
  );
  final creatorPayFuture = findAssociatedTokenAddress(
    owner: user,
    mint: payMint,
  );
  final treasuryAtaFuture = findAssociatedTokenAddress(
    owner: treasury,
    mint: payMint,
  );

  final config = await configFuture;
  final collection = await collectionFuture;
  final collectionInfo = await collectionInfoFuture;
  final creatorPayAccount = await creatorPayFuture;
  final treasuryTokenAccount = await treasuryAtaFuture;

  final instructionDataResult = encodeCreateActorCollectionData(
    assetId: assetId,
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

  final createIx = buildCreateActorCollectionInstruction(
    programId: programId,
    creator: user,
    sponsor: sponsor,
    config: config,
    collection: collection,
    collectionInfo: collectionInfo,
    payTokenMint: payMint,
    creatorPayAccount: creatorPayAccount,
    treasuryTokenAccount: treasuryTokenAccount,
    instructionData: instructionData,
  );

  final rpc = RpcClient(rpcHttpUrl);
  final latestBlockhash = await rpc.getLatestBlockhash(
    commitment: Commitment.confirmed,
  );

  // 指令顺序对齐 web：computeBudget → ed25519 → create（sponsorPrep 已移除）
  final instructions = <Instruction>[
    ...buildStoryNftMintComputeBudgetInstructions(),
    ed25519Ix,
    createIx,
  ];

  final compiledMessage = Message(instructions: instructions).compileV0(
    recentBlockhash: latestBlockhash.value.blockhash,
    feePayer: sponsor,
  );

  return Result.success(
    CreateActorCollectionBuildResult(
      compiledMessage: compiledMessage,
      messageBytes: Uint8List.fromList(compiledMessage.toByteArray().toList()),
      blockhash: latestBlockhash.value.blockhash,
      payTokenMint: payTokenMint,
    ),
  );
}

Result<String> serializePartiallySignedCreateActorCollectionTransaction({
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
