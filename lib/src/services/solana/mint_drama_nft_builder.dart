import 'dart:convert';
import 'dart:typed_data';

import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../../core/result.dart';
import '../../core/story_logger.dart';
import 'delegator_signature.dart';
import 'solana_compute_budget.dart';
import 'solana_program_ids.dart';
import 'story_pda.dart';

/// Drama NFT mint 指令 discriminator，与链上 StoryProgram `mint_drama_nft`
/// 对齐（通过 Codama 生成）。从 Figma 抓包交易解码：[86,73,192,56,151,242,122,96]。
const _mintDramaNftDiscriminator = <int>[86, 73, 192, 56, 151, 242, 122, 96];

/// 指令前缀固定字符串 "drama"。
const _dramaPrefix = 'drama';

List<int> _u32Le(int value) => [
  value & 0xff,
  (value >> 8) & 0xff,
  (value >> 16) & 0xff,
  (value >> 24) & 0xff,
];

/// u64 最大值（2⁶⁴ − 1）。
final _u64Max = (BigInt.one << 64) - BigInt.one;

/// 将十进制字符串解析为 8 字节 u64 LE。
///
/// 使用 [BigInt] 避免以下问题：
/// - Dart VM 的 `int` 为有符号 64 位，最大正值 0x7FFFFFFFFFFFFFFF，
///   超出此范围的 u64 值（如 0x8000000000000000 ~ 0xFFFFFFFFFFFFFFFF）
///   会导致 `int.parse` 抛异常。
/// - Dart Web 的 `int` 实际为 64 位浮点数，只有 53 位精度，
///   超过 9007199254740992 的值会静默丢失精度。
Result<List<int>> _u64LeFromString(String decimal) {
  final trimmed = decimal.trim();
  final value = BigInt.tryParse(trimmed);
  if (value == null) {
    return Result.failure(
      ApiError.business(-1, 'dramaId must be a numeric string: $decimal'),
    );
  }
  if (value.isNegative || value > _u64Max) {
    return Result.failure(
      ApiError.business(-1, 'dramaId out of u64 range: $trimmed'),
    );
  }
  final bytes = <int>[];
  var v = value;
  for (var i = 0; i < 8; i++) {
    bytes.add((v & BigInt.from(0xff)).toInt());
    v = v >> 8;
  }
  return Result.success(bytes);
}

/// 编码 `mint_drama_nft` 指令数据。
///
/// 布局（与链上 StoryProgram 对齐，从 Figma 抓包交易解码）：
/// ```
/// discriminator      : 8 bytes
/// prefix_len         : u32 LE (5)
/// prefix             : "drama" (5 bytes)
/// drama_id           : u64 LE (8 bytes, 由十进制字符串经 BigInt 解析)
/// payload_len        : u32 LE
/// canonical_payload  : payload_len bytes (UTF-8)
/// delegator_sig      : 64 bytes
/// ```
Result<Uint8List> encodeMintDramaNftData({
  required String dramaId,
  required String canonicalPayload,
  required Uint8List delegatorSig,
}) {
  if (delegatorSig.length != 64) {
    return Result.failure(
      ApiError.business(-1, 'delegator sig must be 64 bytes'),
    );
  }
  final dramaIdBytesResult = _u64LeFromString(dramaId);
  if (dramaIdBytesResult.isFailure) {
    return Result.failure(dramaIdBytesResult.errorOrNull!);
  }
  final dramaIdBytes = dramaIdBytesResult.dataOrNull!;
  final prefixBytes = utf8.encode(_dramaPrefix);
  final payloadBytes = utf8.encode(canonicalPayload);
  return Result.success(
    Uint8List.fromList([
      ..._mintDramaNftDiscriminator,
      ..._u32Le(prefixBytes.length),
      ...prefixBytes,
      ...dramaIdBytes,
      ..._u32Le(payloadBytes.length),
      ...payloadBytes,
      ...delegatorSig,
    ]),
  );
}

/// `mint_drama_nft`（链上 `MintSeriesNft`）指令（13 个账户）。
///
/// 账户顺序与读写标志严格对齐 web Codama `mintSeriesNft`：
///   0 creator(w,s) 1 sponor(w,s) 2 config(r) 3 asset(w) 4 collectionInfo(r)
///   5 collectionMint(w) 6 payTokenMint(r) 7 creatorPayAccount(w) 8 treasury(w)
///   9 instructions(r) 10 mplCore(r) 11 system(r) 12 token(r)
Instruction buildMintDramaNftInstruction({
  required Ed25519HDPublicKey programId,
  required Ed25519HDPublicKey creator,
  required Ed25519HDPublicKey sponsor,
  required Ed25519HDPublicKey config,
  required Ed25519HDPublicKey asset,
  required Ed25519HDPublicKey collectionInfo,
  required Ed25519HDPublicKey collectionMint,
  required Ed25519HDPublicKey payTokenMint,
  required Ed25519HDPublicKey creatorPayAccount,
  required Ed25519HDPublicKey treasury,
  required Uint8List instructionData,
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: creator, isSigner: true),
      AccountMeta.writeable(pubKey: sponsor, isSigner: true),
      AccountMeta.readonly(pubKey: config, isSigner: false),
      AccountMeta.writeable(pubKey: asset, isSigner: false),
      AccountMeta.readonly(pubKey: collectionInfo, isSigner: false),
      AccountMeta.writeable(pubKey: collectionMint, isSigner: false),
      AccountMeta.readonly(pubKey: payTokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: creatorPayAccount, isSigner: false),
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
    ],
    data: ByteArray(instructionData),
  );
}

class MintDramaBuildResult {
  final CompiledMessage compiledMessage;
  final Uint8List messageBytes;
  final String blockhash;
  final String payTokenMint;

  const MintDramaBuildResult({
    required this.compiledMessage,
    required this.messageBytes,
    required this.blockhash,
    required this.payTokenMint,
  });
}

/// 构造未签名的 mint_drama_nft 交易消息（fee payer = sponsor）。
///
/// 流程：
/// 1. 派生 PDA（config / asset / collectionInfo / collectionMint）
/// 2. 派生 ATA（creatorPayAccount / treasuryTokenAccount）
/// 3. 编码 mint_drama_nft 指令数据（dramaId 经 BigInt 转 u64 LE）
/// 4. 创建 Ed25519 验签指令（delegator 对 canonicalPayload 的签名）
/// 5. 组装指令序列：computeBudget → ed25519 → mint（不再附带 sponsorPrep）
/// 6. 获取 latest blockhash，编译 v0 message
Future<Result<MintDramaBuildResult>> buildMintDramaMessage({
  required String rpcHttpUrl,
  required String storyProgramAddress,
  required String delegatorAddress,
  required String treasuryAddress,
  required String spenderAddress,
  required String userAddress,
  required String dramaId,
  required String canonicalPayload,
  required String sigBase64,
  required String payTokenMint,
}) async {
  try {
    final programId = Ed25519HDPublicKey.fromBase58(storyProgramAddress);
    final user = Ed25519HDPublicKey.fromBase58(userAddress);
    final sponsor = Ed25519HDPublicKey.fromBase58(spenderAddress);
    final delegator = Ed25519HDPublicKey.fromBase58(delegatorAddress);
    final treasury = Ed25519HDPublicKey.fromBase58(treasuryAddress);
    final payMint = Ed25519HDPublicKey.fromBase58(payTokenMint);

    // Step 1: decode delegator signature
    final sigResult = decodeDelegatorSignature(sigBase64);
    if (sigResult.isFailure) {
      return Result.failure(sigResult.errorOrNull!);
    }
    final sig64 = sigResult.dataOrNull!;

    // Step 2: derive PDAs — 与 web Codama `mintSeriesNft` 对齐。
    // collectionType 固定为 "drama"（= _dramaPrefix）；collectionInfo /
    // collectionMint 的第二个 seed 是该字符串（不是 dramaId）；asset 的第二个
    // seed 是 dramaId 的 u64 LE 8 字节。
    final dramaIdLeResult = _u64LeFromString(dramaId);
    if (dramaIdLeResult.isFailure) {
      return Result.failure(dramaIdLeResult.errorOrNull!);
    }
    final dramaIdLeBytes = dramaIdLeResult.dataOrNull!;

    final configFuture = StoryPda.findConfigPda(programId: programId);
    final assetFuture = StoryPda.findDramaAssetPda(
      programId: programId,
      dramaIdLeBytes: dramaIdLeBytes,
    );
    final collectionInfoFuture = StoryPda.findCollectionInfoPda(
      programId: programId,
      collectionAssetId: _dramaPrefix,
    );
    final collectionMintFuture = StoryPda.findCollectionMintPda(
      programId: programId,
      collectionAssetId: _dramaPrefix,
    );

    // Step 4: derive payment-token ATAs
    final creatorPayFuture = findAssociatedTokenAddress(
      owner: user,
      mint: payMint,
    );
    final treasuryAtaFuture = findAssociatedTokenAddress(
      owner: treasury,
      mint: payMint,
    );

    final config = await configFuture;
    final asset = await assetFuture;
    final collectionInfo = await collectionInfoFuture;
    final collectionMint = await collectionMintFuture;
    final creatorPayAccount = await creatorPayFuture;
    final treasuryTokenAccount = await treasuryAtaFuture;

    final dramaIdBigInt = BigInt.tryParse(dramaId.trim());
    final dramaIdU64LeHex = dramaIdLeBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(',');
    StoryLogger.d(
      'buildMintDramaMessage: dramaId="$dramaId" (bigInt=$dramaIdBigInt, '
      'u64LE=$dramaIdU64LeHex), '
      'program=${programId.toBase58()}, '
      'user=${user.toBase58()}, '
      'sponsor=${sponsor.toBase58()}, '
      'delegator=${delegator.toBase58()}, '
      'treasury=${treasury.toBase58()}, '
      'payMint=${payMint.toBase58()}',
      tag: 'Builder',
    );
    StoryLogger.d(
      'buildMintDramaMessage PDAs: '
      'config=${config.toBase58()}, '
      'asset=${asset.toBase58()}, '
      'collectionInfo=${collectionInfo.toBase58()}, '
      'collectionMint=${collectionMint.toBase58()}, '
      'creatorPayAccount=${creatorPayAccount.toBase58()}, '
      'treasuryTokenAccount=${treasuryTokenAccount.toBase58()}',
      tag: 'Builder',
    );
    StoryLogger.d(
      'buildMintDramaMessage payload: '
      'canonicalPayload="$canonicalPayload", '
      'sig64=${sig64.sublist(0, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}... '
      '(${sig64.length} bytes)',
      tag: 'Builder',
    );

    // Step 5: encode instruction data
    final instructionDataResult = encodeMintDramaNftData(
      dramaId: dramaId,
      canonicalPayload: canonicalPayload,
      delegatorSig: sig64,
    );
    if (instructionDataResult.isFailure) {
      return Result.failure(instructionDataResult.errorOrNull!);
    }
    final instructionData = instructionDataResult.dataOrNull!;

    // Step 6: ed25519 verify instruction
    final ed25519IxResult = createDelegatorEd25519Instruction(
      delegator: delegator,
      canonicalPayload: canonicalPayload,
      sig64: sig64,
    );
    if (ed25519IxResult.isFailure) {
      return Result.failure(ed25519IxResult.errorOrNull!);
    }
    final ed25519Ix = ed25519IxResult.dataOrNull!;

    // Step 7: main mint instruction
    final mintIx = buildMintDramaNftInstruction(
      programId: programId,
      creator: user,
      sponsor: sponsor,
      config: config,
      asset: asset,
      collectionInfo: collectionInfo,
      collectionMint: collectionMint,
      payTokenMint: payMint,
      creatorPayAccount: creatorPayAccount,
      treasury: treasuryTokenAccount,
      instructionData: instructionData,
    );

    // Step 8: fetch blockhash；指令顺序对齐 web：
    // computeBudget → ed25519 → mint（sponsorPrep 已移除）
    final rpc = RpcClient(rpcHttpUrl);
    final latestBlockhash = await rpc.getLatestBlockhash(
      commitment: Commitment.confirmed,
    );

    final instructions = <Instruction>[
      ...buildStoryNftMintComputeBudgetInstructions(),
      ed25519Ix,
      mintIx,
    ];

    StoryLogger.d(
      'buildMintDramaMessage instructions: count=${instructions.length}, '
      'blockhash=${latestBlockhash.value.blockhash}, '
      'instructionDataLen=${instructionData.length}',
      tag: 'Builder',
    );

    // Step 9: compile v0 message (fee payer = sponsor)
    final compiledMessage = Message(instructions: instructions).compileV0(
      recentBlockhash: latestBlockhash.value.blockhash,
      feePayer: sponsor,
    );

    return Result.success(
      MintDramaBuildResult(
        compiledMessage: compiledMessage,
        messageBytes: Uint8List.fromList(
          compiledMessage.toByteArray().toList(),
        ),
        blockhash: latestBlockhash.value.blockhash,
        payTokenMint: payTokenMint,
      ),
    );
  } on FormatException catch (e) {
    return Result.failure(
      ApiError.business(-1, 'Invalid mint drama parameters: ${e.message}'),
    );
  } catch (e) {
    return Result.failure(
      ApiError.unknown(e.toString(), exception: e is Exception ? e : null),
    );
  }
}
