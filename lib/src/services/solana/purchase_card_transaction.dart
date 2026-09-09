import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:solana/solana.dart';

import '../../core/result.dart';
import 'delegator_signature.dart';
import 'generated/story_program.g.dart';
import 'solana_program_ids.dart';
import 'story_transaction_composer.dart';

class PurchaseCardTransactionRequest {
  final String rpcHttpUrl;
  final String storyProgramAddress;
  final String delegatorAddress;
  final String treasuryAddress;
  final String spenderAddress;
  final String buyerAddress;
  final String cardType;
  final String payAmountMinor;
  final String orderNo;
  final String canonicalPayload;
  final String delegatorSignature;
  final String payTokenMint;

  const PurchaseCardTransactionRequest({
    required this.rpcHttpUrl,
    required this.storyProgramAddress,
    required this.delegatorAddress,
    required this.treasuryAddress,
    required this.spenderAddress,
    required this.buyerAddress,
    required this.cardType,
    required this.payAmountMinor,
    required this.orderNo,
    required this.canonicalPayload,
    required this.delegatorSignature,
    required this.payTokenMint,
  });
}

/// 使用服务端签名原文构建 `purchase_card` 交易；只校验，不重新拼接原文。
Future<Result<StoryTransactionBuildResult>> buildPurchaseCardTransaction(
  PurchaseCardTransactionRequest request, {
  StoryTransactionComposer composer = const StoryTransactionComposer(),
}) async {
  final validation = validatePurchaseCardTransactionRequest(request);
  if (validation != null) return Result.failure(validation);

  try {
    final programId = Ed25519HDPublicKey.fromBase58(
      request.storyProgramAddress,
    );
    final delegator = Ed25519HDPublicKey.fromBase58(request.delegatorAddress);
    final treasuryOwner = Ed25519HDPublicKey.fromBase58(
      request.treasuryAddress,
    );
    final sponsor = Ed25519HDPublicKey.fromBase58(request.spenderAddress);
    final buyer = Ed25519HDPublicKey.fromBase58(request.buyerAddress);
    final payMint = Ed25519HDPublicKey.fromBase58(request.payTokenMint);
    final signatureResult = decodeDelegatorSignature(
      request.delegatorSignature,
    );
    if (signatureResult.isFailure) {
      return Result.failure(signatureResult.errorOrNull!);
    }

    final orderHash = resolveCardPurchaseOrderHash(request.orderNo);
    final resolvedAccounts = await Future.wait([
      findPurchaseCardConfigPda(programId: programId),
      findPurchaseCardPurchaseRecordPda(
        programId: programId,
        orderHash: orderHash,
      ),
      findAssociatedTokenAddress(owner: buyer, mint: payMint),
      findAssociatedTokenAddress(owner: treasuryOwner, mint: payMint),
    ]);

    final signature = signatureResult.dataOrNull!;
    final verifyInstructionResult = createDelegatorEd25519Instruction(
      delegator: delegator,
      canonicalPayload: request.canonicalPayload,
      sig64: signature,
    );
    if (verifyInstructionResult.isFailure) {
      return Result.failure(verifyInstructionResult.errorOrNull!);
    }

    final purchaseInstruction = buildPurchaseCardInstruction(
      programId: programId,
      accounts: PurchaseCardAccounts(
        buyer: buyer,
        sponor: sponsor,
        config: resolvedAccounts[0],
        payTokenMint: payMint,
        buyerPayAccount: resolvedAccounts[2],
        treasury: resolvedAccounts[3],
        purchaseRecord: resolvedAccounts[1],
        instructions: SolanaProgramIds.sysvarInstructions,
        systemProgram: SolanaProgramIds.systemProgram,
        tokenProgram: TokenProgram.id,
      ),
      orderHash: orderHash,
      params: StorySignedParams(
        canonicalPayload: request.canonicalPayload,
        sig: signature,
      ),
    );

    // Ed25519 验签必须先于购买指令，合约会从指令 sysvar 读取校验结果。
    return composer.composeSponsorV0(
      rpcHttpUrl: request.rpcHttpUrl,
      sponsor: sponsor,
      instructions: [verifyInstructionResult.dataOrNull!, purchaseInstruction],
    );
  } on FormatException catch (error) {
    return Result.failure(
      ApiError.validation('Invalid purchase card address: ${error.message}'),
    );
  } catch (error) {
    return Result.failure(
      ApiError.unknown(
        'Failed to build purchase card transaction: $error',
        exception: error is Exception ? error : null,
      ),
    );
  }
}

/// 订单号哈希用于生成链上幂等购买记录 PDA。
Uint8List resolveCardPurchaseOrderHash(String orderNo) =>
    Uint8List.fromList(sha256.convert(utf8.encode(orderNo.trim())).bytes);

ApiError? validatePurchaseCardTransactionRequest(
  PurchaseCardTransactionRequest request,
) {
  if (!StoryContractMetadata.isAllowedProgramId(request.storyProgramAddress)) {
    return ApiError.validation(
      'Story program ID is not present in the locked deployment manifest',
    );
  }
  final orderNo = request.orderNo.trim();
  if (orderNo.isEmpty) {
    return ApiError.validation('Card purchase order number is required');
  }

  final parts = request.canonicalPayload.split('|');
  if (parts.length != 7 || parts.first != 'card_purchase') {
    return ApiError.validation('Invalid card purchase canonical payload');
  }
  if (parts[1] != request.buyerAddress) {
    return ApiError.validation(
      'Card purchase buyer does not match the signed payload',
    );
  }
  if (parts[2] != request.cardType) {
    return ApiError.validation(
      'Card purchase type does not match the requested item',
    );
  }
  if (parts[3].toUpperCase() != 'USDC') {
    return ApiError.validation('Card purchase payment token must be USDC');
  }
  if (parts[5] != orderNo) {
    return ApiError.validation(
      'Card purchase order number does not match the signed payload',
    );
  }
  final amount = BigInt.tryParse(parts[4]);
  final expiresAt = int.tryParse(parts[6]);
  if (amount == null ||
      amount <= BigInt.zero ||
      amount.toString() != request.payAmountMinor ||
      expiresAt == null) {
    return ApiError.validation('Invalid card purchase amount or expiry');
  }
  if (expiresAt <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
    return ApiError.validation('Card purchase signature has expired');
  }
  return null;
}
