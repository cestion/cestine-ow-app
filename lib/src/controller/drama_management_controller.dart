import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../l10n/app_localizations.dart';
import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/drama_repository.dart';
import '../repositories/user_repository.dart';
import '../services/actor_sign_service.dart';
import '../services/sponsor_service.dart';
import '../services/wallet_ledger.dart';
import '../utils/wallet_spend_amount.dart';
import 'drama_management_state.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';
import 'story_controller_mixin.dart';
import 'user_profile_dramas_state.dart';

/// Controller backing the 「短剧管理」tab on the creator page.
///
/// Loads creator dramas filtered by review status with server-side pagination,
/// driven by [DramaManagementStatus] selection. Replaces the previous in-memory
/// `myDramas` + client-side `filteredDramas` filtering on [CreatorController].
class DramaManagementController extends Notifier<DramaManagementState>
    with
        PaginationMixin<CreatorDrama, DramaManagementState>,
        StoryControllerMixin<DramaManagementState> {
  DramaRepository get _drama => ref.read(dramaRepositoryProvider);
  bool _isSilentRefreshing = false;

  @override
  DramaManagementState build() => const DramaManagementState();

  @override
  DramaManagementState copyWithLoadingState({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return state.copyWith(
      isLoading: isLoading,
      lastError: lastError,
      clearLastError: clearLastError,
    );
  }

  @override
  PaginationState<CreatorDrama> get pagination => state.pagination;
  @override
  bool get isLoading => state.isLoading;

  @override
  void setPaginationState(
    PaginationState<CreatorDrama> pagination, {
    bool? isLoading,
  }) {
    state = state.copyWith(pagination: pagination, isLoading: isLoading);
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error);
  }

  @override
  Future<Result<PageDto<CreatorDrama>>> fetchPage({String? mark}) {
    return _drama.listMyCreatorDramas(
      mark: mark,
      status: state.currentStatus.apiValue,
    );
  }

  /// 失效当前 status 的首页缓存后再刷新，确保每次进入 tab / 切换 status
  /// 都能拉到最新数据（绕过永不过期的内存缓存层）。
  @override
  Future<void> refresh() async {
    await _drama.invalidateCreatorDramasCache(
      status: state.currentStatus.apiValue,
    );
    await super.refresh();
  }

  /// Refresh the current filter without clearing the visible list or exposing
  /// a loading state. The response is applied only if the user is still on
  /// the same filter, so a slower background request cannot overwrite a
  /// newer filter selection.
  ///
  /// Returns whether the currently displayed data contains a drama that is
  /// still under review. Callers use this to decide whether polling should
  /// continue.
  Future<bool> silentRefresh() async {
    if (_isSilentRefreshing || state.isLoading) {
      return state.hasPendingReview;
    }

    _isSilentRefreshing = true;
    final requestedStatus = state.currentStatus;
    try {
      await _drama.invalidateCreatorDramasCache(
        status: requestedStatus.apiValue,
      );
      final result = await _drama.listMyCreatorDramas(
        status: requestedStatus.apiValue,
      );
      if (!ref.mounted || state.currentStatus != requestedStatus) {
        return false;
      }

      final page = result.dataOrNull;
      if (result.isSuccess && page != null) {
        final nextMark = page.mark?.toString() ?? '';
        state = state.copyWith(
          pagination: PaginationState<CreatorDrama>(
            items: page.list ?? const [],
            hasMore: page.hasMore ?? false,
            mark: nextMark,
          ),
          clearLastError: true,
        );
      }
      return state.hasPendingReview;
    } catch (error, stackTrace) {
      StoryLogger.e(
        'Silent refresh failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'DramaMgmt',
      );
      return ref.mounted && state.hasPendingReview;
    } finally {
      _isSilentRefreshing = false;
    }
  }

  /// 用编辑后的数据替换列表中同 id 的项。
  /// 编辑后 status 变为 PENDING_REVIEW，只有"全部"或"审核中"才保留，
  /// 其他筛选下从列表移除。
  void updateDrama(CreatorDrama drama) {
    final dramaId = drama.id;
    if (dramaId == null) return;

    final originalIndex = state.items.indexWhere((d) => d.id == dramaId);
    final items = state.items.where((d) => d.id != dramaId).toList();

    final shouldKeep =
        state.currentStatus == DramaManagementStatus.all ||
        state.currentStatus == DramaManagementStatus.pendingReview;

    if (shouldKeep && originalIndex >= 0) {
      final insertIndex = originalIndex > items.length
          ? items.length
          : originalIndex;
      items.insert(insertIndex, drama);
    }

    state = state.copyWith(pagination: state.pagination.copyWith(items: items));
  }

  /// Switch the review-status filter and reload from the first page.
  Future<void> selectStatus(DramaManagementStatus status) async {
    if (status == state.currentStatus && state.items.isNotEmpty) return;
    state = state.copyWith(currentStatus: status);
    state = state.copyWith(pagination: const PaginationState<CreatorDrama>());
    await refresh();
  }

  void requestDeleteDrama(CreatorDrama drama) {
    state = state.copyWith(
      activeDialog: DramaManagementDialog.deleteDramaConfirm,
      dramaToDelete: drama.id,
    );
  }

  void closeDialog() {
    state = state.copyWith(activeDialog: DramaManagementDialog.closed);
  }

  Future<bool> confirmDeleteDrama() async {
    final dramaId = state.dramaToDelete;
    if (dramaId == null) return false;

    state = state.copyWith(isDeleting: true);
    try {
      final result = await _drama.deleteDrama(dramaId);
      if (!ref.mounted) return false;
      if (result.isSuccess) {
        state = state.copyWith(
          pagination: state.pagination.copyWith(
            items: state.items.where((d) => d.id != dramaId).toList(),
          ),
          activeDialog: DramaManagementDialog.closed,
        );
        final publishedProvider = userProfileDramasProvider(
          const UserProfileDramaParam(type: ProfileDramaType.published),
        );
        if (ref.exists(publishedProvider)) {
          ref.read(publishedProvider.notifier).removeDrama(dramaId);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isDeleting: false);
      }
    }
  }

  /// 铸造短剧 NFT（邮箱代付）：
  /// 1) 校验余额 + 乐观扣款 2) 调用 mint 摘要接口 3) 组 sponsor 参数
  /// 4) 代付提交 5) 成功后拉取详情原地更新列表项（失败回退本地乐观标记）
  ///    并刷新钱包余额与收益。
  Future<Result<String>> mintDramaNft(
    CreatorDrama drama, {
    required AppLocalizations l10n,
  }) async {
    final dramaId = drama.id;
    if (dramaId == null || dramaId.isEmpty) {
      return Result.failure(
        ApiError.business(-1, l10n.creatorMintInvalidDramaId),
      );
    }

    if (state.isMinting) {
      return Result.failure(ApiError.business(-1, l10n.creatorMintInProgress));
    }

    state = state.copyWith(
      isMinting: true,
      clearMintError: true,
      clearLastMintTxHash: true,
    );

    SpendTicket? spendTicket;
    final ledger = ref.read(walletLedgerProvider);

    try {
      StoryLogger.d('mintDramaNft.start dramaId=$dramaId', tag: 'DramaMgmt');

      await ref.read(globalConfigProvider.future);
      final svmChain = ref.read(svmChainProvider);
      final withdrawCfg = ref.read(withdrawConfigProvider);
      final chainContext = ActorSignService.resolveChainContext(
        svmChain: svmChain,
        sponsorApiUrl: withdrawCfg.sponsorApiUrl,
      );
      if (chainContext == null) {
        final error = ApiError.business(-1, l10n.actorSignChainConfigMissing);
        state = state.copyWith(mintError: error);
        return Result.failure(error);
      }

      final walletResult = await ref
          .read(privyServiceProvider)
          .ensureSolanaWallet();
      if (!ref.mounted) {
        return Result.failure(ApiError.unknown('disposed'));
      }
      final userAddress = walletResult.address?.trim() ?? '';
      if (!walletResult.success || userAddress.isEmpty) {
        final error = ApiError.business(-1, l10n.creatorMintWalletNotReady);
        state = state.copyWith(mintError: error);
        return Result.failure(error);
      }

      // 校验 USDC 余额是否足够支付链上铸造手续费。
      final usdcBalance = ref.read(onChainWalletBalanceProvider).usdcBalance;
      if (usdcBalance < StoryConstants.defaultMintFeeUsdc) {
        final error = ApiError.business(
          -1,
          l10n.creatorMintInsufficientUsdc(l10n.currency, l10n.currency),
        );
        state = state.copyWith(mintError: error);
        return Result.failure(error);
      }

      StoryLogger.d(
        'mintDramaNft.request dramaId=$dramaId wallet=$userAddress',
        tag: 'DramaMgmt',
      );
      final mintResult = await _drama.mintDramaNft(
        dramaId,
        MintDramaNftRequest(
          nftChain: chainContext.nftChain,
          nftContractAddress: userAddress,
          nftTokenStandard: 'NFT',
          walletAddress: userAddress,
        ),
      );
      if (mintResult.isFailure) {
        final error = mintResult.errorOrNull!;
        state = state.copyWith(mintError: error);
        return Result.failure(error);
      }

      final digest = mintResult.dataOrNull;
      if (digest == null || !digest.isReadyForChain) {
        final error = ApiError.business(-1, l10n.creatorMintDigestEmpty);
        state = state.copyWith(mintError: error);
        return Result.failure(error);
      }

      // Authoritative fee from digest; fall back to default mint fee.
      final feeUsdc = resolveMintFeeUsdc(digest.feeAmount);
      final prepared = await ledger.prepareSpend(
        SpendQuote(
          asset: SpendAsset.usdc,
          amount: feeUsdc,
          reason: 'mint_drama_nft',
        ),
      );
      if (!ref.mounted) {
        return Result.failure(ApiError.unknown('disposed'));
      }
      if (prepared.isFailure) {
        final error = ApiError.business(
          -1,
          l10n.creatorMintInsufficientUsdc(l10n.currency, l10n.currency),
        );
        state = state.copyWith(mintError: error);
        return Result.failure(error);
      }
      spendTicket = prepared.dataOrNull;

      // 钱包一致性校验：mint 钱包必须与当前登录钱包一致（对齐演员签约流程）。
      final mintWallet = digest.mintWalletAddress?.trim();
      if (mintWallet != null &&
          mintWallet.isNotEmpty &&
          mintWallet != userAddress) {
        final error = ApiError.business(-1, l10n.creatorMintWalletMismatch);
        state = state.copyWith(mintError: error);
        return Result.failure(error);
      }

      final sponsorService = ref.read(sponsorServiceProvider);
      final txResult = await sponsorService.submitSponsorMintDrama(
        SponsorMintDramaParams(
          userSolanaAddress: userAddress,
          dramaId: dramaId,
          canonicalPayload: digest.canonicalPayload!,
          sigBase64: digest.sig!,
          payTokenMint: digest.payToken!,
          rpcHttpUrl: chainContext.rpc,
          storyProgramAddress: chainContext.storyProgram,
          delegatorAddress: chainContext.delegator,
          treasuryAddress: chainContext.treasury,
          spenderAddress: chainContext.spender,
          sponsorApiUrl: chainContext.sponsorUrl,
        ),
      );

      if (txResult.isFailure) {
        final error = txResult.errorOrNull!;
        state = state.copyWith(mintError: error);
        return Result.failure(error);
      }

      final txHash = txResult.dataOrNull!;
      state = state.copyWith(lastMintTxHash: txHash, clearMintError: true);

      // 失效「全部」首页缓存：下次回 tab 拉到最新数据。
      await _drama.invalidateCreatorDramasCache();
      // 拉取单条详情并原地替换列表项；失败则本地乐观标记为已铸造，
      // 保证 UI 立即反映铸造状态，下次进 tab 因缓存已失效会自动校正。
      if (ref.mounted) {
        final i = state.items.indexWhere((d) => d.id == dramaId);
        if (i >= 0) {
          updateDrama(
            state.items[i].copyWith(
              nftMinted: true,
              nftTxHash: txHash,
              nftChain: chainContext.nftChain,
              nftContractAddress: userAddress,
            ),
          );
        }
      }
      // 成功后刷新收益页，与演员签约流程保持一致。
      if (ref.mounted) {
        ref.read(incomeControllerProvider.notifier).refresh();
      }

      StoryLogger.d(
        'mintDramaNft.success dramaId=$dramaId txHash=$txHash',
        tag: 'DramaMgmt',
      );

      return Result.success(txHash);
    } finally {
      // 还原乐观扣款：以链上/后端真实余额为准（失败回滚、成功对账）。
      if (spendTicket != null && spendTicket.didDeduct && ref.mounted) {
        await ledger.reconcile(spendTicket);
      }
      if (ref.mounted) {
        state = state.copyWith(isMinting: false);
      }
    }
  }
}
