import 'package:solana/solana.dart';

import '../core/result.dart';
import '../core/role_asset_error_messages.dart';
import '../model/models.dart';
import '../repositories/actor_repository.dart';
import '../services/privy_service.dart';
import '../services/solana/solana_transaction_confirm_service.dart';
import '../services/solana/game_actor_nft.dart';
import '../services/solana/story_pda.dart';
import '../services/sponsor_service.dart';
import '../services/wallet_ledger.dart';

// Public ctor keeps readable names; fields stay private.
// ignore_for_file: prefer_initializing_formals

class ActorSignChainContext {
  final String rpc;
  final String sponsorUrl;
  final String spender;
  final String storyProgram;
  final String delegator;
  final String treasury;
  final String nftChain;

  const ActorSignChainContext({
    required this.rpc,
    required this.sponsorUrl,
    required this.spender,
    required this.storyProgram,
    required this.delegator,
    required this.treasury,
    required this.nftChain,
  });
}

class ActorSignService {
  final ActorRepository _actorRepository;
  final SponsorService _sponsorService;
  final PrivyService _privyService;
  final SolanaTransactionConfirmService _confirmService;

  const ActorSignService({
    required ActorRepository actorRepository,
    required SponsorService sponsorService,
    required PrivyService privyService,
    SolanaTransactionConfirmService confirmService =
        const SolanaTransactionConfirmService(),
  }) : _actorRepository = actorRepository,
       _sponsorService = sponsorService,
       _privyService = privyService,
       _confirmService = confirmService;

  static ActorSignChainContext? resolveChainContext({
    required ChainInfo? svmChain,
    required String? sponsorApiUrl,
  }) {
    final contracts = svmChain?.contracts;
    final rpc = svmChain?.rpc?.http;
    final spender = contracts?.spender;
    final storyProgram = contracts?.story;
    final delegator = contracts?.storyDelegator;
    final treasury = contracts?.storyTreasury;
    final nftChain = svmChain?.name;
    if (rpc == null ||
        sponsorApiUrl == null ||
        spender == null ||
        storyProgram == null ||
        delegator == null ||
        treasury == null ||
        nftChain == null) {
      return null;
    }
    return ActorSignChainContext(
      rpc: rpc,
      sponsorUrl: sponsorApiUrl,
      spender: spender,
      storyProgram: storyProgram,
      delegator: delegator,
      treasury: treasury,
      nftChain: nftChain,
    );
  }

  Future<Result<String>> signActor({
    required ActorCollection actor,
    required ActorSignChainContext chainContext,
    required WalletLedger walletLedger,
    double? fallbackPriceUsdc,
  }) async {
    final actorId = actor.id?.trim();
    if (actorId == null || actorId.isEmpty) {
      return Result.failure(
        ApiError.business(-1, RoleAssetErrorMessages.invalidRoleId),
      );
    }

    final walletResult = await _privyService.ensureSolanaWallet();
    if (!walletResult.success || walletResult.address == null) {
      final err = walletResult.error ?? 'Wallet unavailable';
      if (PrivyService.looksLikeUnauthenticated(err)) {
        return Result.failure(
          ApiError.unauthorized(PrivyService.sessionExpiredErrorKey),
        );
      }
      return Result.failure(ApiError.business(-1, err));
    }
    final userAddress = walletResult.address!;

    final programId = Ed25519HDPublicKey.fromBase58(chainContext.storyProgram);
    final collectionMint = await StoryPda.findCollectionMintPda(
      programId: programId,
      collectionAssetId: actorId,
    );

    final mintRequest = MintActorNftRequest(
      nftChain: actor.nftChain ?? chainContext.nftChain,
      nftTokenStandard: actor.nftTokenStandard ?? 'NFT',
      nftContractAddress: collectionMint.toBase58(),
      walletAddress: userAddress,
    );

    final digestResult = await _actorRepository.mintActorNft(
      actorId,
      mintRequest,
    );
    if (digestResult.isFailure) {
      return Result.failure(digestResult.errorOrNull!);
    }

    final digest = digestResult.dataOrNull!;
    final canonicalPayload = digest.canonicalPayload?.trim();
    final sig = digest.sig?.trim();
    final payToken = digest.payToken?.trim();
    if (canonicalPayload == null ||
        canonicalPayload.isEmpty ||
        sig == null ||
        sig.isEmpty ||
        payToken == null ||
        payToken.isEmpty) {
      return Result.failure(
        ApiError.business(-1, 'Mint digest incomplete, please retry'),
      );
    }

    if (digest.walletAddress != null &&
        digest.walletAddress!.trim().isNotEmpty &&
        digest.walletAddress!.trim() != userAddress) {
      return Result.failure(
        ApiError.business(-1, 'Mint wallet must match connected wallet'),
      );
    }

    final mintCount = digest.quantity ?? 1;
    if (mintCount < 1 || mintCount > 10) {
      return Result.failure(
        ApiError.business(-1, 'Invalid mint quantity, please refresh'),
      );
    }

    final collectionAssetIdResult = resolveActorCollectionAssetId(
      digest: digest,
      actor: actor,
      collectionAssetId: actorId,
    );
    if (collectionAssetIdResult.isFailure) {
      return Result.failure(collectionAssetIdResult.errorOrNull!);
    }
    final collectionAssetId = collectionAssetIdResult.dataOrNull!;

    final resolvedCollectionMint = await StoryPda.findCollectionMintPda(
      programId: programId,
      collectionAssetId: collectionAssetId,
    );
    final digestCollectionMint = digest.collectionMintAddress?.trim();
    if (digestCollectionMint != null &&
        digestCollectionMint.isNotEmpty &&
        digestCollectionMint != resolvedCollectionMint.toBase58()) {
      return Result.failure(
        ApiError.business(
          -1,
          'Collection mint mismatch, please refresh and retry',
        ),
      );
    }

    final submitResult = await _sponsorService.submitSponsorMintActorNft(
      SponsorMintActorNftParams(
        userSolanaAddress: userAddress,
        collectionAssetId: collectionAssetId,
        collectionMintAddress: resolvedCollectionMint.toBase58(),
        mintStartIndex: digest.mintStartIndex,
        mintCount: mintCount,
        canonicalPayload: canonicalPayload,
        sigBase64: sig,
        payTokenMint: payToken,
        rpcHttpUrl: chainContext.rpc,
        storyProgramAddress: chainContext.storyProgram,
        delegatorAddress: chainContext.delegator,
        treasuryAddress: chainContext.treasury,
        spenderAddress: chainContext.spender,
        sponsorApiUrl: chainContext.sponsorUrl,
      ),
    );
    if (submitResult.isFailure) {
      return Result.failure(submitResult.errorOrNull!);
    }

    final txHash = submitResult.dataOrNull;
    if (txHash == null || txHash.isEmpty) {
      return Result.failure(
        ApiError.business(-1, 'Sponsor API returned no tx hash'),
      );
    }

    // Align with web: do not treat sponsor ack as success until confirmed.
    return _confirmService.confirm(
      rpcHttpUrl: chainContext.rpc,
      signature: txHash,
      action: 'batch_mint_actor_nft',
    );
  }
}
