import 'dart:async';
import 'dart:convert' hide Encoding;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:privy_flutter/privy_flutter.dart' as privy;
import 'package:solana/dto.dart' show Encoding;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import 'package:meta/meta.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import 'privy_service.dart';
import 'solana/batch_refill_stamina_builder.dart';
import 'solana/burn_actor_nft_builder.dart';
import 'solana/create_actor_collection_builder.dart';
import 'solana/delegator_signature.dart';
import 'solana/mint_actor_nft_builder.dart';
import 'solana/mint_drama_nft_builder.dart';
import 'solana/partial_tx_serializer.dart';
import 'solana/purchase_card_transaction.dart';
import 'solana/refill_stamina_builder.dart';
import 'solana/unsigned_transaction.dart';
import 'solana/upgrade_actor_nft_builder.dart';

class SponsorMintActorNftParams {
  final String userSolanaAddress;
  final String collectionAssetId;
  final String collectionMintAddress;
  final int mintStartIndex;
  final int mintCount;
  final String canonicalPayload;
  final String sigBase64;
  final String payTokenMint;
  final String rpcHttpUrl;
  final String storyProgramAddress;
  final String delegatorAddress;
  final String treasuryAddress;
  final String spenderAddress;
  final String sponsorApiUrl;

  const SponsorMintActorNftParams({
    required this.userSolanaAddress,
    required this.collectionAssetId,
    required this.collectionMintAddress,
    required this.mintStartIndex,
    required this.mintCount,
    required this.canonicalPayload,
    required this.sigBase64,
    required this.payTokenMint,
    required this.rpcHttpUrl,
    required this.storyProgramAddress,
    required this.delegatorAddress,
    required this.treasuryAddress,
    required this.spenderAddress,
    required this.sponsorApiUrl,
  });
}

class SponsorCreateActorCollectionParams {
  final String userSolanaAddress;
  final String assetId;
  final String canonicalPayload;
  final String sigBase64;
  final String payTokenMint;
  final String rpcHttpUrl;
  final String storyProgramAddress;
  final String delegatorAddress;
  final String treasuryAddress;
  final String spenderAddress;
  final String sponsorApiUrl;

  const SponsorCreateActorCollectionParams({
    required this.userSolanaAddress,
    required this.assetId,
    required this.canonicalPayload,
    required this.sigBase64,
    required this.payTokenMint,
    required this.rpcHttpUrl,
    required this.storyProgramAddress,
    required this.delegatorAddress,
    required this.treasuryAddress,
    required this.spenderAddress,
    required this.sponsorApiUrl,
  });
}

/// 短剧 NFT 铸造代付参数。与 [SponsorCreateActorCollectionParams] 类似，
/// 但 dramaId 用 u64 编码（非字符串 assetId），且多一个 dramaNftAccount。
class SponsorMintDramaParams {
  final String userSolanaAddress;
  final String dramaId;
  final String canonicalPayload;
  final String sigBase64;
  final String payTokenMint;
  final String rpcHttpUrl;
  final String storyProgramAddress;
  final String delegatorAddress;
  final String treasuryAddress;
  final String spenderAddress;
  final String sponsorApiUrl;

  const SponsorMintDramaParams({
    required this.userSolanaAddress,
    required this.dramaId,
    required this.canonicalPayload,
    required this.sigBase64,
    required this.payTokenMint,
    required this.rpcHttpUrl,
    required this.storyProgramAddress,
    required this.delegatorAddress,
    required this.treasuryAddress,
    required this.spenderAddress,
    required this.sponsorApiUrl,
  });
}

class SponsorRefillActorStaminaParams {
  final String userSolanaAddress;
  final String actorNftId;
  final int? actorCollectionId;
  final int? actorTokenId;
  final String orderNo;
  final String canonicalPayload;
  final String sigBase64;
  final String payTokenMint;
  final String rpcHttpUrl;
  final String storyProgramAddress;
  final String delegatorAddress;
  final String treasuryAddress;
  final String spenderAddress;
  final String sponsorApiUrl;

  const SponsorRefillActorStaminaParams({
    required this.userSolanaAddress,
    required this.actorNftId,
    required this.actorCollectionId,
    required this.actorTokenId,
    required this.orderNo,
    required this.canonicalPayload,
    required this.sigBase64,
    required this.payTokenMint,
    required this.rpcHttpUrl,
    required this.storyProgramAddress,
    required this.delegatorAddress,
    required this.treasuryAddress,
    required this.spenderAddress,
    required this.sponsorApiUrl,
  });
}

class SponsorBatchRefillActorStaminaParams {
  final String userSolanaAddress;
  final List<String> actorAssetIds;
  final String orderNo;
  final String canonicalPayload;
  final String sigBase64;
  final String payTokenMint;
  final String rpcHttpUrl;
  final String storyProgramAddress;
  final String delegatorAddress;
  final String treasuryAddress;
  final String spenderAddress;
  final String sponsorApiUrl;

  const SponsorBatchRefillActorStaminaParams({
    required this.userSolanaAddress,
    required this.actorAssetIds,
    required this.orderNo,
    required this.canonicalPayload,
    required this.sigBase64,
    required this.payTokenMint,
    required this.rpcHttpUrl,
    required this.storyProgramAddress,
    required this.delegatorAddress,
    required this.treasuryAddress,
    required this.spenderAddress,
    required this.sponsorApiUrl,
  });
}

class SponsorPurchaseCardParams {
  final String userSolanaAddress;
  final String cardType;
  final String payAmountMinor;
  final String orderNo;
  final String canonicalPayload;
  final String sigBase64;
  final String payTokenMint;
  final String rpcHttpUrl;
  final String storyProgramAddress;
  final String delegatorAddress;
  final String treasuryAddress;
  final String spenderAddress;
  final String sponsorApiUrl;

  const SponsorPurchaseCardParams({
    required this.userSolanaAddress,
    required this.cardType,
    required this.payAmountMinor,
    required this.orderNo,
    required this.canonicalPayload,
    required this.sigBase64,
    required this.payTokenMint,
    required this.rpcHttpUrl,
    required this.storyProgramAddress,
    required this.delegatorAddress,
    required this.treasuryAddress,
    required this.spenderAddress,
    required this.sponsorApiUrl,
  });
}

class SponsorWithdrawParams {
  final String userSolanaAddress;
  final String toAddress;
  final String tokenMint;
  final int tokenDecimals;
  final BigInt amount;
  final String rpcHttpUrl;
  final String spenderAddress;
  final String sponsorApiUrl;
  final String? authToken;

  const SponsorWithdrawParams({
    required this.userSolanaAddress,
    required this.toAddress,
    required this.tokenMint,
    required this.tokenDecimals,
    required this.amount,
    required this.rpcHttpUrl,
    required this.spenderAddress,
    required this.sponsorApiUrl,
    this.authToken,
  });
}

class SponsorUpgradeActorNftParams {
  final String userSolanaAddress;
  final int actorCollectionId;
  final int mainNftTokenId;
  final List<int> burnNftTokenIds;
  final String canonicalPayload;
  final String sigBase64;
  final String payTokenMint;
  final String rpcHttpUrl;
  final String storyProgramAddress;
  final String delegatorAddress;
  final String treasuryAddress;
  final String spenderAddress;
  final String sponsorApiUrl;

  const SponsorUpgradeActorNftParams({
    required this.userSolanaAddress,
    required this.actorCollectionId,
    required this.mainNftTokenId,
    required this.burnNftTokenIds,
    required this.canonicalPayload,
    required this.sigBase64,
    required this.payTokenMint,
    required this.rpcHttpUrl,
    required this.storyProgramAddress,
    required this.delegatorAddress,
    required this.treasuryAddress,
    required this.spenderAddress,
    required this.sponsorApiUrl,
  });
}

class SponsorBurnActorNftParams {
  final String userSolanaAddress;
  final String collectionAssetId;
  final String assetId;
  final String orderNo;
  final String canonicalPayload;
  final String sigBase64;
  final String payTokenMint;
  final String rpcHttpUrl;
  final String storyProgramAddress;
  final String delegatorAddress;
  final String spenderAddress;
  final String sponsorApiUrl;

  const SponsorBurnActorNftParams({
    required this.userSolanaAddress,
    required this.collectionAssetId,
    required this.assetId,
    required this.orderNo,
    required this.canonicalPayload,
    required this.sigBase64,
    required this.payTokenMint,
    required this.rpcHttpUrl,
    required this.storyProgramAddress,
    required this.delegatorAddress,
    required this.spenderAddress,
    required this.sponsorApiUrl,
  });
}

class SponsorService {
  final PrivyService _privy;
  final String Function()? tokenProvider;
  final String apiBaseUrl;
  final http.Client _httpClient;

  SponsorService(
    this._privy, {
    this.tokenProvider,
    required this.apiBaseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Uri _resolveSponsorUri(String sponsorApiUrl) {
    final parsed = Uri.parse(sponsorApiUrl);
    if (parsed.hasScheme && parsed.host.isNotEmpty) {
      return parsed;
    }
    return Uri.parse(apiBaseUrl).resolve(sponsorApiUrl);
  }

  Future<Result<privy.EmbeddedSolanaWallet>>
  _requireEmbeddedSolanaWallet() async {
    final privyUser = _privy.privy;
    if (privyUser == null || !_privy.isAvailable) {
      return Result.failure(ApiError.business(-1, 'Privy not initialized'));
    }

    final user = await privyUser.getUser();
    if (user == null) {
      return Result.failure(ApiError.business(-1, 'User not logged in'));
    }
    if (user.embeddedSolanaWallets.isEmpty) {
      return Result.failure(ApiError.business(-1, 'No embedded Solana wallet'));
    }
    return Result.success(user.embeddedSolanaWallets.first);
  }

  Future<Result<String>> _signAndSubmitSponsorTransaction({
    required privy.EmbeddedSolanaWallet solanaWallet,
    required CompiledMessage compiledMessage,
    required String sponsorApiUrl,
    required String action,
    void Function(int wireLength, int sigCount)? logBeforeSign,
    void Function(String signedTx)? logAfterSign,
  }) async {
    final wireBytes = buildUnsignedTransactionWireBytes(compiledMessage);
    logBeforeSign?.call(
      wireBytes.length,
      compiledMessage.requiredSignatureCount,
    );
    final sizeResult = validateSolanaTransactionWireSize(wireBytes);
    if (sizeResult.isFailure) {
      StoryLogger.w(
        'Sponsor $action: transaction too large '
        '(${wireBytes.length} > $solanaTransactionMaxBytes bytes)',
        tag: 'Sponsor',
      );
      return Result.failure(sizeResult.errorOrNull!);
    }
    final signResult = await solanaWallet.provider.signTransaction(wireBytes);
    // ignore: invalid_use_of_visible_for_testing_member
    switch (signResult) {
      case privy.Success(:final value):
        logAfterSign?.call(value);
        return submitSponsorTransaction(value, sponsorApiUrl, action: action);
      case privy.Failure(:final error):
        StoryLogger.w(
          'Privy signTransaction failed: ${error.message}',
          tag: 'Sponsor',
        );
        return Result.failure(ApiError.business(-1, error.message));
    }
  }

  Future<Result<String>> _runSponsorFlow<T>({
    required String action,
    required String sponsorApiUrl,
    required Future<Result<T>> Function() build,
    required CompiledMessage Function(T result) extractMessage,
    void Function(T result)? logBuild,
    void Function(int wireLength, int sigCount)? logBeforeSign,
    void Function(String signedTx)? logAfterSign,
    required String invalidInputMessage,
    required String failureLogMessage,
  }) async {
    try {
      final walletResult = await _requireEmbeddedSolanaWallet();
      if (walletResult.isFailure) {
        return Result.failure(walletResult.errorOrNull!);
      }

      final buildResult = await build();
      if (buildResult.isFailure) {
        return Result.failure(buildResult.errorOrNull!);
      }
      final built = buildResult.dataOrNull;
      if (built == null) {
        return Result.failure(ApiError.unknown('Sponsor build returned null'));
      }
      logBuild?.call(built);

      return _signAndSubmitSponsorTransaction(
        solanaWallet: walletResult.dataOrNull!,
        compiledMessage: extractMessage(built),
        sponsorApiUrl: sponsorApiUrl,
        action: action,
        logBeforeSign: logBeforeSign,
        logAfterSign: logAfterSign,
      );
    } on FormatException catch (e) {
      StoryLogger.w(
        '$failureLogMessage invalid input: ${e.message}',
        tag: 'Sponsor',
      );
      return Result.failure(
        ApiError.business(-1, '$invalidInputMessage: ${e.message}'),
      );
    } catch (e, st) {
      StoryLogger.e(
        failureLogMessage,
        error: e,
        stackTrace: st,
        tag: 'Sponsor',
      );
      return Result.failure(
        ApiError.unknown(e.toString(), exception: e is Exception ? e : null),
      );
    }
  }

  /// 邮箱登录 · 演员签约 mint 代付：与 web `useSponsorMintActorNft` 对齐。
  ///
  /// 1. buildMintActorNftInstructions（同 web buildMintActorNftExecutionContext）
  /// 2. 签名前 getLatestBlockhash('confirmed') + compile
  /// 3. signMessage(base64 message) → partial tx → POST sponsor（对齐 web signMessage）
  Future<Result<String>> submitSponsorMintActorNft(
    SponsorMintActorNftParams params,
  ) async {
    try {
      final walletResult = await _requireEmbeddedSolanaWallet();
      if (walletResult.isFailure) {
        return Result.failure(walletResult.errorOrNull!);
      }
      final solanaWallet = walletResult.dataOrNull!;

      final buildResult = await buildMintActorNftInstructions(
        rpcHttpUrl: params.rpcHttpUrl,
        storyProgramAddress: params.storyProgramAddress,
        delegatorAddress: params.delegatorAddress,
        treasuryAddress: params.treasuryAddress,
        spenderAddress: params.spenderAddress,
        userAddress: params.userSolanaAddress,
        collectionAssetId: params.collectionAssetId,
        collectionMintAddress: params.collectionMintAddress,
        mintStartIndex: params.mintStartIndex,
        mintCount: params.mintCount,
        canonicalPayload: params.canonicalPayload,
        sigBase64: params.sigBase64,
        payTokenMint: params.payTokenMint,
      );
      if (buildResult.isFailure) {
        return Result.failure(buildResult.errorOrNull!);
      }
      final context = buildResult.dataOrNull!;

      StoryLogger.d(
        'Sponsor mint: built instructions collection=${context.collectionAssetId} '
        'mintStartIndex=${context.mintStartIndex} mintCount=${context.mintCount}',
        tag: 'Sponsor',
      );

      final rpc = RpcClient(context.rpcHttpUrl);
      final latestBlockhash = await rpc.getLatestBlockhash(
        commitment: Commitment.confirmed,
      );
      final compiledMessage = compileMintActorNftMessage(
        context: context,
        recentBlockhash: latestBlockhash.value.blockhash,
      );

      final messageBytes = Uint8List.fromList(
        compiledMessage.toByteArray().toList(),
      );
      final wireBytes = buildUnsignedTransactionWireBytes(compiledMessage);
      StoryLogger.d(
        'Sponsor mint: signing message (${wireBytes.length} bytes wire, '
        '${compiledMessage.requiredSignatureCount} sigs) blockhash='
        '${latestBlockhash.value.blockhash}',
        tag: 'Sponsor',
      );

      final sizeResult = validateSolanaTransactionWireSize(wireBytes);
      if (sizeResult.isFailure) {
        return Result.failure(sizeResult.errorOrNull!);
      }

      // 对齐 web useSponsorMintActorNft：signMessage(序列化 message)。
      // Privy Flutter signMessage 要求 base64 字符串；勿传裸 messageBytes 给 signTransaction。
      final signResult = await solanaWallet.provider.signMessage(
        base64Encode(messageBytes),
      );
      // ignore: invalid_use_of_visible_for_testing_member
      switch (signResult) {
        case privy.Success(:final value):
          StoryLogger.d(
            'Sponsor mint: signMessage returned ${value.length} chars',
            tag: 'Sponsor',
          );
          final sigDecode = decodeWalletMessageSignature(value);
          if (sigDecode.isFailure) {
            StoryLogger.w(
              'Sponsor mint: invalid signMessage signature format',
              tag: 'Sponsor',
            );
            return Result.failure(sigDecode.errorOrNull!);
          }
          final partialResult = serializePartiallySignedTransaction(
            compiledMessage: compiledMessage,
            userAddress: solanaWallet.address,
            userSignature: sigDecode.dataOrNull!,
          );
          if (partialResult.isFailure) {
            return Result.failure(partialResult.errorOrNull!);
          }
          final signedTxBase64 = partialResult.dataOrNull!;
          StoryLogger.d(
            'Sponsor mint: partial tx ${signedTxBase64.length} chars',
            tag: 'Sponsor',
          );
          return submitSponsorTransaction(
            signedTxBase64,
            params.sponsorApiUrl,
            action: 'mint',
          );
        case privy.Failure(:final error):
          StoryLogger.w(
            'Privy signMessage failed: ${error.message}',
            tag: 'Sponsor',
          );
          return Result.failure(ApiError.business(-1, error.message));
      }
    } on FormatException catch (e) {
      StoryLogger.w(
        'Sponsor mint failed invalid input: ${e.message}',
        tag: 'Sponsor',
      );
      return Result.failure(
        ApiError.business(-1, 'Invalid mint parameters: ${e.message}'),
      );
    } catch (e, st) {
      StoryLogger.e(
        'Sponsor mint failed',
        error: e,
        stackTrace: st,
        tag: 'Sponsor',
      );
      return Result.failure(
        ApiError.unknown(e.toString(), exception: e is Exception ? e : null),
      );
    }
  }

  /// 邮箱登录 · 演员 IP 发行代付：fee payer = spender，用户 sign message，POST sponsor。
  Future<Result<String>> submitSponsorCreateActorCollection(
    SponsorCreateActorCollectionParams params,
  ) {
    return _runSponsorFlow(
      action: 'create_actor_collection',
      sponsorApiUrl: params.sponsorApiUrl,
      invalidInputMessage: 'Invalid parameters',
      failureLogMessage: 'Sponsor create actor collection failed',
      build: () => buildCreateActorCollectionMessage(
        rpcHttpUrl: params.rpcHttpUrl,
        storyProgramAddress: params.storyProgramAddress,
        delegatorAddress: params.delegatorAddress,
        treasuryAddress: params.treasuryAddress,
        spenderAddress: params.spenderAddress,
        userAddress: params.userSolanaAddress,
        assetId: params.assetId,
        canonicalPayload: params.canonicalPayload,
        sigBase64: params.sigBase64,
        payTokenMint: params.payTokenMint,
      ),
      extractMessage: (result) => result.compiledMessage,
      logBeforeSign: (wireLength, sigCount) {
        StoryLogger.d(
          'Sponsor create actor collection: signing tx ($wireLength bytes, '
          '$sigCount sigs) for ${params.userSolanaAddress}',
          tag: 'Sponsor',
        );
      },
    );
  }

  /// 邮箱登录 · 短剧 NFT 铸造代付：fee payer = spender，用户 signTransaction，
  /// POST sponsor。调用 [buildMintDramaMessage] 构造 drama mint 指令
  /// （u64 dramaId + asset/collectionInfo/collectionMint PDA）。
  Future<Result<String>> submitSponsorMintDrama(SponsorMintDramaParams params) {
    return _runSponsorFlow(
      action: 'mint_drama',
      sponsorApiUrl: params.sponsorApiUrl,
      invalidInputMessage: 'Invalid parameters',
      failureLogMessage: 'Sponsor mint drama failed',
      build: () => buildMintDramaMessage(
        rpcHttpUrl: params.rpcHttpUrl,
        storyProgramAddress: params.storyProgramAddress,
        delegatorAddress: params.delegatorAddress,
        treasuryAddress: params.treasuryAddress,
        spenderAddress: params.spenderAddress,
        userAddress: params.userSolanaAddress,
        dramaId: params.dramaId,
        canonicalPayload: params.canonicalPayload,
        sigBase64: params.sigBase64,
        payTokenMint: params.payTokenMint,
      ),
      extractMessage: (result) => result.compiledMessage,
      logBuild: (result) {
        StoryLogger.d(
          'Sponsor mint drama: built tx '
          '(blockhash=${result.blockhash}, '
          'payTokenMint=${result.payTokenMint}) '
          'for drama ${params.dramaId}',
          tag: 'Sponsor',
        );
      },
      logBeforeSign: (wireLength, sigCount) {
        StoryLogger.d(
          'Sponsor mint drama: signing tx ($wireLength bytes, $sigCount sigs) '
          'for drama ${params.dramaId}',
          tag: 'Sponsor',
        );
      },
    );
  }

  Future<Result<String>> submitSponsorRefillActorStamina(
    SponsorRefillActorStaminaParams params,
  ) {
    return _runSponsorFlow(
      action: 'refill',
      sponsorApiUrl: params.sponsorApiUrl,
      invalidInputMessage: 'Invalid refill parameters',
      failureLogMessage: 'Sponsor refill failed',
      build: () {
        StoryLogger.d(
          'Sponsor refill: building tx for ${params.actorNftId}',
          tag: 'Sponsor',
        );
        return buildRefillStaminaMessage(
          rpcHttpUrl: params.rpcHttpUrl,
          storyProgramAddress: params.storyProgramAddress,
          delegatorAddress: params.delegatorAddress,
          treasuryAddress: params.treasuryAddress,
          spenderAddress: params.spenderAddress,
          userAddress: params.userSolanaAddress,
          actorNftId: params.actorNftId,
          actorCollectionId: params.actorCollectionId,
          actorTokenId: params.actorTokenId,
          orderNo: params.orderNo,
          canonicalPayload: params.canonicalPayload,
          sigBase64: params.sigBase64,
          payTokenMint: params.payTokenMint,
        );
      },
      extractMessage: (result) => result.compiledMessage,
      logBeforeSign: (wireLength, sigCount) {
        StoryLogger.d(
          'Sponsor refill: signing tx ($wireLength bytes, $sigCount sigs) '
          'for ${params.actorNftId}',
          tag: 'Sponsor',
        );
      },
    );
  }

  Future<Result<String>> submitSponsorBatchRefillActorStamina(
    SponsorBatchRefillActorStaminaParams params,
  ) {
    return _runSponsorFlow(
      action: 'batch_refill_actor_stamina',
      sponsorApiUrl: params.sponsorApiUrl,
      invalidInputMessage: 'Invalid batch refill parameters',
      failureLogMessage: 'Sponsor batch refill failed',
      build: () => buildBatchRefillStaminaMessage(
        rpcHttpUrl: params.rpcHttpUrl,
        storyProgramAddress: params.storyProgramAddress,
        delegatorAddress: params.delegatorAddress,
        treasuryAddress: params.treasuryAddress,
        spenderAddress: params.spenderAddress,
        userAddress: params.userSolanaAddress,
        actorAssetIds: params.actorAssetIds,
        orderNo: params.orderNo,
        canonicalPayload: params.canonicalPayload,
        sigBase64: params.sigBase64,
        payTokenMint: params.payTokenMint,
      ),
      extractMessage: (result) => result.compiledMessage,
      logBeforeSign: (wireLength, sigCount) {
        StoryLogger.d(
          'Sponsor batch refill: signing tx '
          '($wireLength bytes, $sigCount sigs) for '
          '${params.actorAssetIds.length} actors',
          tag: 'Sponsor',
        );
      },
    );
  }

  Future<Result<String>> submitSponsorPurchaseCard(
    SponsorPurchaseCardParams params,
  ) {
    return _runSponsorFlow(
      action: 'purchase_card',
      sponsorApiUrl: params.sponsorApiUrl,
      invalidInputMessage: 'Invalid card purchase parameters',
      failureLogMessage: 'Sponsor card purchase failed',
      build: () => buildPurchaseCardTransaction(
        PurchaseCardTransactionRequest(
          rpcHttpUrl: params.rpcHttpUrl,
          storyProgramAddress: params.storyProgramAddress,
          delegatorAddress: params.delegatorAddress,
          treasuryAddress: params.treasuryAddress,
          spenderAddress: params.spenderAddress,
          buyerAddress: params.userSolanaAddress,
          cardType: params.cardType,
          payAmountMinor: params.payAmountMinor,
          orderNo: params.orderNo,
          canonicalPayload: params.canonicalPayload,
          delegatorSignature: params.sigBase64,
          payTokenMint: params.payTokenMint,
        ),
      ),
      extractMessage: (result) => result.compiledMessage,
      logBeforeSign: (wireLength, sigCount) {
        StoryLogger.d(
          'Sponsor card purchase: signing tx '
          '($wireLength bytes, $sigCount sigs) for order ${params.orderNo}',
          tag: 'Sponsor',
        );
      },
    );
  }

  /// 邮箱登录 · 演员 NFT 升级代付：fee payer = spender，用户 signMessage，POST sponsor。
  Future<Result<String>> submitSponsorUpgradeActorNft(
    SponsorUpgradeActorNftParams params,
  ) {
    return _runSponsorFlow(
      action: 'upgrade_actor_nft',
      sponsorApiUrl: params.sponsorApiUrl,
      invalidInputMessage: 'Invalid upgrade parameters',
      failureLogMessage: 'Sponsor upgrade failed',
      build: () {
        StoryLogger.d(
          'Sponsor upgrade: building tx for collection ${params.actorCollectionId}, '
          'main=${params.mainNftTokenId}, burns=${params.burnNftTokenIds}',
          tag: 'Sponsor',
        );
        return buildUpgradeActorNftMessage(
          rpcHttpUrl: params.rpcHttpUrl,
          storyProgramAddress: params.storyProgramAddress,
          delegatorAddress: params.delegatorAddress,
          treasuryAddress: params.treasuryAddress,
          spenderAddress: params.spenderAddress,
          userAddress: params.userSolanaAddress,
          actorCollectionId: params.actorCollectionId,
          mainNftTokenId: params.mainNftTokenId,
          burnNftTokenIds: params.burnNftTokenIds,
          canonicalPayload: params.canonicalPayload,
          sigBase64: params.sigBase64,
          payTokenMint: params.payTokenMint,
        );
      },
      extractMessage: (result) => result.compiledMessage,
      logBeforeSign: (wireLength, sigCount) {
        StoryLogger.d(
          'Sponsor upgrade: signing tx ($wireLength bytes, $sigCount sigs) '
          'for ${params.mainNftTokenId}',
          tag: 'Sponsor',
        );
      },
    );
  }

  /// 邮箱登录 · 演员 NFT 回收代付：创建销毁交易并由用户钱包签名。
  Future<Result<String>> submitSponsorBurnActorNft(
    SponsorBurnActorNftParams params,
  ) {
    return _runSponsorFlow(
      action: 'burn_actor_nft',
      sponsorApiUrl: params.sponsorApiUrl,
      invalidInputMessage: 'Invalid actor recycle parameters',
      failureLogMessage: 'Sponsor actor recycle failed',
      build: () => buildBurnActorNftMessage(
        rpcHttpUrl: params.rpcHttpUrl,
        storyProgramAddress: params.storyProgramAddress,
        delegatorAddress: params.delegatorAddress,
        spenderAddress: params.spenderAddress,
        userAddress: params.userSolanaAddress,
        collectionAssetId: params.collectionAssetId,
        assetId: params.assetId,
        orderNo: params.orderNo,
        canonicalPayload: params.canonicalPayload,
        sigBase64: params.sigBase64,
        payTokenMint: params.payTokenMint,
      ),
      extractMessage: (result) => result.compiledMessage,
      logBeforeSign: (wireLength, sigCount) {
        StoryLogger.d(
          'Sponsor actor recycle: signing tx '
          '($wireLength bytes, $sigCount sigs) for ${params.assetId}',
          tag: 'Sponsor',
        );
      },
    );
  }

  Future<Result<String>> submitSponsorWithdraw(
    SponsorWithdrawParams params,
  ) async {
    try {
      final walletResult = await _requireEmbeddedSolanaWallet();
      if (walletResult.isFailure) {
        return Result.failure(walletResult.errorOrNull!);
      }
      final solanaWallet = walletResult.dataOrNull!;

      final userPub = Ed25519HDPublicKey.fromBase58(params.userSolanaAddress);
      final mintPub = Ed25519HDPublicKey.fromBase58(params.tokenMint);
      final destPub = Ed25519HDPublicKey.fromBase58(params.toAddress);
      final feePayer = Ed25519HDPublicKey.fromBase58(params.spenderAddress);

      final sourceAta = await findAssociatedTokenAddress(
        owner: userPub,
        mint: mintPub,
      );

      final rpc = RpcClient(params.rpcHttpUrl);

      // Check destination address on-chain type and if ATA needs to be created
      Ed25519HDPublicKey destAta;
      bool needCreateAta = false;

      final toAccount = await rpc.getAccountInfo(
        destPub.toBase58(),
        commitment: Commitment.confirmed,
        encoding: Encoding.base64,
      );

      final toAccountOwner = toAccount.value?.owner;
      const tokenProgramId = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
      const token2022ProgramId = 'TokenzQdBNbLqP5ihNs2F88kVCygDLYwK4gnLokR83';

      if (toAccount.value != null &&
          (toAccountOwner == tokenProgramId ||
              toAccountOwner == token2022ProgramId)) {
        // Destination is already a Token Account. Transfer directly to it, no ATA creation.
        destAta = destPub;
        needCreateAta = false;
      } else {
        // Destination is a wallet owner address. We must use its ATA.
        destAta = await findAssociatedTokenAddress(
          owner: destPub,
          mint: mintPub,
        );
        final destAtaAccount = await rpc.getAccountInfo(
          destAta.toBase58(),
          commitment: Commitment.confirmed,
          encoding: Encoding.base64,
        );
        needCreateAta = destAtaAccount.value == null;
      }

      final instructions = [
        if (needCreateAta)
          AssociatedTokenAccountInstruction.createAccount(
            funder: feePayer,
            address: destAta,
            owner: destPub,
            mint: mintPub,
          ),
        TokenInstruction.transferChecked(
          amount: params.amount.toInt(),
          decimals: params.tokenDecimals,
          source: sourceAta,
          mint: mintPub,
          destination: destAta,
          owner: userPub,
        ),
      ];

      final latestBlockhash = await rpc.getLatestBlockhash(
        commitment: Commitment.confirmed,
      );
      final blockhash = latestBlockhash.value.blockhash;

      final compiledMsg = Message(
        instructions: instructions,
      ).compileV0(recentBlockhash: blockhash, feePayer: feePayer);

      final wireBytes = buildUnsignedTransactionWireBytes(compiledMsg);

      StoryLogger.d(
        'Sponsor withdraw: signing tx (${wireBytes.length} bytes, '
        '${compiledMsg.requiredSignatureCount} sigs) for ${params.amount} → ${params.toAddress}',
        tag: 'Sponsor',
      );

      final signResult = await solanaWallet.provider.signTransaction(wireBytes);
      // ignore: invalid_use_of_visible_for_testing_member
      switch (signResult) {
        case privy.Success(:final value):
          return submitSponsorTransaction(
            value,
            params.sponsorApiUrl,
            action: 'withdraw',
          );
        case privy.Failure(:final error):
          StoryLogger.w(
            'Privy signTransaction failed: ${error.message}',
            tag: 'Sponsor',
          );
          return Result.failure(ApiError.business(-1, error.message));
      }
    } on FormatException catch (e) {
      StoryLogger.w('Sponsor invalid input: ${e.message}', tag: 'Sponsor');
      return Result.failure(
        ApiError.business(-1, 'Invalid address or parameters: ${e.message}'),
      );
    } catch (e, st) {
      StoryLogger.e(
        'Sponsor withdraw failed',
        error: e,
        stackTrace: st,
        tag: 'Sponsor',
      );
      return Result.failure(
        ApiError.unknown(e.toString(), exception: e is Exception ? e : null),
      );
    }
  }

  @visibleForTesting
  Future<Result<String>> submitSponsorTransaction(
    String signedTxBase64,
    String sponsorApiUrl, {
    required String action,
  }) async {
    try {
      final uri = _resolveSponsorUri(sponsorApiUrl);
      StoryLogger.d(
        'Sponsor $action: POST $uri, '
        'txLen=${signedTxBase64.length}, '
        'hasPlus=${signedTxBase64.contains('+')}, '
        'hasSlash=${signedTxBase64.contains('/')}, '
        'hasEquals=${signedTxBase64.contains('=')}',
        tag: 'Sponsor',
      );
      final token = tokenProvider?.call();
      final response = await _httpClient
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode(<String, String>{'transaction': signedTxBase64}),
          )
          .timeout(const Duration(seconds: 30));

      final bodyLen = response.body.length;
      StoryLogger.d(
        'Sponsor $action: response ${response.statusCode}, '
        'bodyLen=$bodyLen, '
        'body=${bodyLen > 4000 ? response.body.substring(0, 4000) : response.body}',
        tag: 'Sponsor',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // 错误响应可能包含完整的链上 program logs，不截断输出
        StoryLogger.w(
          'Sponsor $action: FULL error body (${response.statusCode}, '
          '$bodyLen bytes): ${response.body}',
          tag: 'Sponsor',
        );
        return Result.failure(
          ApiError.business(
            response.statusCode,
            'Sponsor API returned ${response.statusCode}',
          ),
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return Result.failure(ApiError.parse('Invalid sponsor response shape'));
      }
      final code = decoded['code'] as int? ?? -1;
      final msg =
          (decoded['msg'] as String?) ?? (decoded['message'] as String?) ?? '';
      final data = decoded['data'];

      if (code != 100000 && code != 200) {
        return Result.failure(
          ApiError.business(
            code,
            msg.isEmpty ? 'Sponsor API rejected transaction' : msg,
          ),
        );
      }

      final txHash = data is String
          ? data
          : (data is Map
                ? ((data['txHash'] as String?) ?? (data['hash'] as String?))
                : null);
      if (txHash == null || txHash.isEmpty) {
        return Result.failure(
          ApiError.business(-1, 'Sponsor API returned no tx hash'),
        );
      }

      StoryLogger.d('Sponsor $action submitted: $txHash', tag: 'Sponsor');
      return Result.success(txHash);
    } on TimeoutException catch (_) {
      return Result.failure(ApiError.timeout('Sponsor API timed out'));
    } catch (e, st) {
      StoryLogger.e(
        'Sponsor submit failed',
        error: e,
        stackTrace: st,
        tag: 'Sponsor',
      );
      return Result.failure(
        ApiError.unknown(e.toString(), exception: e is Exception ? e : null),
      );
    }
  }
}
