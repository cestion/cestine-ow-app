import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solana/solana.dart' show Ed25519HDPublicKey;

import '../core/result.dart';
import '../l10n/app_localizations.dart';
import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../controller/user_profile_actor_collections_state.dart';
import '../services/actor_sign_service.dart';
import '../services/solana/story_pda.dart';
import '../services/sponsor_service.dart';
import '../core/story_constants.dart';
import '../services/wallet_ledger.dart';
import '../utils/create_actor_form_validator.dart';
import '../utils/wallet_spend_amount.dart';
import 'create_actor_state.dart';

class CreateActorController extends Notifier<CreateActorState> {
  @override
  CreateActorState build() {
    // Fetch available materials when the controller is initialized
    Future.microtask(loadMaterials);
    return const CreateActorState();
  }

  Future<void> loadMaterials() async {
    state = state.copyWith(isMaterialsLoading: true, clearMaterialsError: true);
    final repo = ref.read(actorRepositoryProvider);
    final result = await repo.listDreamOsMaterials();

    if (!ref.mounted) return;

    result.when(
      success: (materials) {
        state = state.copyWith(
          availableMaterials: materials,
          isMaterialsLoading: false,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isMaterialsLoading: false,
          materialsError: error,
        );
      },
    );
  }

  void selectMaterial(Actor material) {
    state = state.copyWith(
      selectedMaterial: material,
      name: material.name ?? '',
      bio: material.bio ?? '',
    );
  }

  void clearSelection() {
    state = state.copyWith(clearSelectedMaterial: true, name: '', bio: '');
  }

  CreateActorFormValidationResult _validateFields({
    required AppLocalizations l10n,
    required String totalSupplyText,
    String? name,
    String? bio,
    String? price,
  }) {
    return validateCreateActorForm(
      l10n: l10n,
      name: name ?? state.name,
      bio: bio ?? state.bio,
      totalSupplyText: totalSupplyText,
      priceText: price ?? state.price,
    );
  }

  /// Live-validate the changed field (aligns with Web RHF `reValidateMode: onChange`).
  void updateName({
    required String name,
    required AppLocalizations l10n,
    required String totalSupplyText,
  }) {
    final result = _validateFields(
      l10n: l10n,
      totalSupplyText: totalSupplyText,
      name: name,
    );
    state = state.copyWith(
      name: name,
      fieldErrors: state.fieldErrors.copyWith(
        name: result.errors.name,
        clearName: result.errors.name == null,
      ),
    );
  }

  void updateBio({
    required String bio,
    required AppLocalizations l10n,
    required String totalSupplyText,
  }) {
    final result = _validateFields(
      l10n: l10n,
      totalSupplyText: totalSupplyText,
      bio: bio,
    );
    state = state.copyWith(
      bio: bio,
      fieldErrors: state.fieldErrors.copyWith(
        bio: result.errors.bio,
        clearBio: result.errors.bio == null,
      ),
    );
  }

  void updatePrice({
    required String price,
    required AppLocalizations l10n,
    required String totalSupplyText,
  }) {
    final result = _validateFields(
      l10n: l10n,
      totalSupplyText: totalSupplyText,
      price: price,
    );
    state = state.copyWith(
      price: price,
      fieldErrors: state.fieldErrors.copyWith(
        price: result.errors.price,
        clearPrice: result.errors.price == null,
      ),
    );
  }

  void updatePricingMode(ActorCollectionPricingMode pricingMode) {
    state = state.copyWith(pricingMode: pricingMode);
  }

  void onTotalSupplyInputChanged({
    required String value,
    required AppLocalizations l10n,
  }) {
    final parsed = int.tryParse(value);
    final result = _validateFields(l10n: l10n, totalSupplyText: value);
    state = state.copyWith(
      totalSupply: parsed,
      fieldErrors: state.fieldErrors.copyWith(
        totalSupply: result.errors.totalSupply,
        clearTotalSupply: result.errors.totalSupply == null,
      ),
    );
  }

  /// Full-form validation on submit (mirrors Web `form.handleSubmit` + Zod).
  CreateActorFormValidationResult validateForm({
    required AppLocalizations l10n,
    required String totalSupplyText,
  }) {
    final result = _validateFields(
      l10n: l10n,
      totalSupplyText: totalSupplyText,
    );
    state = state.copyWith(
      showValidationErrors: true,
      fieldErrors: result.errors,
    );
    return result;
  }

  /// Submit actor IP creation: prepare → mint (mirrors web flow).
  Future<void> submit({
    required int totalSupply,
    required double price,
    required AppLocalizations l10n,
  }) async {
    if (state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true, clearSubmitError: true);

    SpendTicket? spendTicket;
    final ledger = ref.read(walletLedgerProvider);

    try {
      final repo = ref.read(actorRepositoryProvider);
      final material = state.selectedMaterial!;

      // Resolve chain context from global config (mirrors ActorSignService.resolveChainContext)
      await ref.read(globalConfigProvider.future);
      final svmChain = ref.read(svmChainProvider);
      final storyProgram = svmChain?.contracts?.story;
      final nftChain = svmChain?.name;
      if (storyProgram == null || nftChain == null) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: ApiError.unknown(l10n.actorSignChainConfigMissing),
        );
        return;
      }

      // Soft pre-check with the UI fallback fee so empty wallets fail fast.
      final preGate = await ledger.ensureAffordable(
        SpendAsset.usdc,
        StoryConstants.defaultMintFeeUsdc,
      );
      if (!ref.mounted) return;
      if (preGate.isFailure) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: ApiError.business(
            -1,
            l10n.creatorMintInsufficientUsdc(l10n.currency, l10n.currency),
          ),
        );
        return;
      }

      final walletResult = await ref
          .read(privyServiceProvider)
          .ensureSolanaWallet();
      if (!ref.mounted) return;
      final userAddress = walletResult.address?.trim() ?? '';
      if (!walletResult.success || userAddress.isEmpty) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: ApiError.business(-1, l10n.creatorMintWalletNotReady),
        );
        return;
      }

      // Step 1: prepareActorCollection — creates the actor collection on backend
      final prepareResult = await repo.prepareActorCollection(
        PrepareActorCollectionRequest.create(
          assetId: material.id ?? '',
          name: state.name.trim(),
          bio: state.bio.trim(),
          totalSupply: totalSupply,
          pricingMode: state.pricingMode,
          initialPriceUsdc: price,
        ),
      );

      if (!ref.mounted) return;

      if (prepareResult.isFailure) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: prepareResult.errorOrNull,
        );
        return;
      }

      final prepareResponse = prepareResult.dataOrNull!;
      final actorCollectionId = prepareResponse.actorCollectionId;
      if (actorCollectionId == null) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: ApiError.unknown(l10n.createActorInvalidOrderId),
        );
        return;
      }

      // Derive nftContractAddress (collection mint PDA) — mirrors web resolveCreateActorCollectionMintAddress
      final programId = await StoryPda.findCollectionMintPda(
        programId: Ed25519HDPublicKey.fromBase58(storyProgram),
        collectionAssetId: actorCollectionId.toString(),
      );
      final nftContractAddress = programId.toBase58();

      // Step 2: mintActorCollection — initiates on-chain minting
      final mintResult = await repo.mintActorCollection(
        actorCollectionId,
        MintActorCollectionRequest(
          actorCollectionId: actorCollectionId,
          nftChain: nftChain,
          nftTokenStandard: 'NFT',
          nftContractAddress: nftContractAddress,
          walletAddress: userAddress,
        ),
      );

      if (!ref.mounted) return;

      if (mintResult.isFailure) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: mintResult.errorOrNull,
        );
        return;
      }

      final mintDigest = mintResult.dataOrNull;
      if (mintDigest == null || !mintDigest.isReadyForChain) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: ApiError.unknown(l10n.creatorMintDigestEmpty),
        );
        return;
      }

      // Authoritative fee from digest; fall back to default mint fee.
      final feeUsdc = resolveMintFeeUsdc(mintDigest.feeAmount);
      final prepared = await ledger.prepareSpend(
        SpendQuote(
          asset: SpendAsset.usdc,
          amount: feeUsdc,
          reason: 'mint_actor_collection',
        ),
      );
      if (!ref.mounted) return;
      if (prepared.isFailure) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: ApiError.business(
            -1,
            l10n.creatorMintInsufficientUsdc(l10n.currency, l10n.currency),
          ),
        );
        return;
      }
      spendTicket = prepared.dataOrNull;

      // Step 3: resolve chain context for sponsor on-chain transaction
      final withdrawCfg = ref.read(withdrawConfigProvider);
      final chainContext = ActorSignService.resolveChainContext(
        svmChain: svmChain,
        sponsorApiUrl: withdrawCfg.sponsorApiUrl,
      );
      if (chainContext == null) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: ApiError.unknown(l10n.actorSignChainConfigMissing),
        );
        return;
      }

      // Submit on-chain transaction via sponsor service
      final sponsorService = ref.read(sponsorServiceProvider);
      final txResult = await sponsorService.submitSponsorCreateActorCollection(
        SponsorCreateActorCollectionParams(
          userSolanaAddress: userAddress,
          assetId: actorCollectionId.toString(),
          canonicalPayload: mintDigest.canonicalPayload!,
          sigBase64: mintDigest.sig!,
          payTokenMint: mintDigest.payToken!,
          rpcHttpUrl: chainContext.rpc,
          storyProgramAddress: chainContext.storyProgram,
          delegatorAddress: chainContext.delegator,
          treasuryAddress: chainContext.treasury,
          spenderAddress: chainContext.spender,
          sponsorApiUrl: chainContext.sponsorUrl,
        ),
      );

      if (!ref.mounted) return;

      if (txResult.isFailure) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: txResult.errorOrNull,
        );
        return;
      }

      // Success — on-chain transaction submitted and confirmed
      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        issuedActorId: actorCollectionId.toString(),
        issuedActorName: state.name,
      );
      ref.invalidate(
        userProfileActorCollectionsProvider(const UserProfileActorParam()),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isSubmitting: false,
        submitError: ApiError.unknown(e.toString()),
      );
    } finally {
      if (spendTicket != null && spendTicket.didDeduct) {
        await ledger.reconcile(spendTicket);
      }
    }
  }

  void resetSuccess() {
    state = state.copyWith(isSuccess: false);
  }
}
