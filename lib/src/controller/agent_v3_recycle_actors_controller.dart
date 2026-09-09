import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/mining_repository.dart';
import '../services/solana/solana_transaction_confirm_service.dart';
import '../services/sponsor_service.dart';
import 'agent_v3_recycle_actors_state.dart';
import 'game_state.dart';

const int agentV3RecycleActorsPageSize = 20;

/// `GET /api/mining/listAllActors?sort=COMPUTING_POWER` 的回收列表状态源。
class AgentV3RecycleActorsController
    extends Notifier<AgentV3RecycleActorsState> {
  MiningRepository get _repository => ref.read(miningRepositoryProvider);
  bool _isFirstPageLoadInFlight = false;
  bool _isRefreshQueued = false;
  final Set<String> _pendingRecycledActorIds = {};

  @override
  AgentV3RecycleActorsState build() {
    _resetOnAuthSessionChange();
    return const AgentV3RecycleActorsState();
  }

  void _resetOnAuthSessionChange() {
    ref.listen<({bool loggedIn, String? sessionId})>(
      authControllerProvider.select(
        (auth) =>
            (loggedIn: auth.isLoggedIn, sessionId: auth.userId ?? auth.token),
      ),
      (previous, current) {
        if (previous == null) return;
        final loggedOut = previous.loggedIn && !current.loggedIn;
        final loggedIn = !previous.loggedIn && current.loggedIn;
        final accountChanged =
            previous.loggedIn &&
            current.loggedIn &&
            previous.sessionId != current.sessionId;
        if (loggedOut || loggedIn || accountChanged) ref.invalidateSelf();
      },
    );
  }

  /// 每次打开弹窗都回源第一页，避免展示已经被其他端处理的角色。
  Future<void> refresh() async {
    if (_isFirstPageLoadInFlight) {
      _isRefreshQueued = true;
      return;
    }

    _isFirstPageLoadInFlight = true;
    final hasUsableSnapshot = state.hasUsableSnapshot;
    state = state.copyWith(
      isLoading: !hasUsableSnapshot,
      isRefreshing: hasUsableSnapshot,
      clearLastError: true,
    );
    try {
      final result = await _repository.refreshAllActors(
        sort: GameActorSort.computingPower.apiValue,
        pageSize: agentV3RecycleActorsPageSize,
      );
      if (!ref.mounted) return;

      if (result.isFailure) {
        state = state.copyWith(
          isInitialized: true,
          isLoading: false,
          isRefreshing: false,
          hasMore: state.isInitialized ? state.hasMore : false,
          lastError: result.errorOrNull,
        );
        return;
      }

      _setInitialPage(result.dataOrNull ?? const MiningActorPage());
    } finally {
      _isFirstPageLoadInFlight = false;
      _runQueuedRefresh();
    }
  }

  void _runQueuedRefresh() {
    if (!_isRefreshQueued || !ref.mounted) return;
    _isRefreshQueued = false;
    unawaited(refresh());
  }

  void _setInitialPage(MiningActorPage page) {
    state = state.copyWith(
      actors: _withoutPendingRecycles(page.records),
      isInitialized: true,
      isLoading: false,
      isRefreshing: false,
      currentPage: page.pageNumber,
      totalCount: page.totalRow,
      hasMore: page.hasMore,
      clearLastError: true,
    );
  }

  Future<void> loadMore() async {
    if (_isFirstPageLoadInFlight ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearLastError: true);
    final result = await _repository.listAllActors(
      sort: GameActorSort.computingPower.apiValue,
      pageNum: state.currentPage + 1,
      pageSize: agentV3RecycleActorsPageSize,
    );
    if (!ref.mounted) return;

    if (result.isFailure) {
      state = state.copyWith(
        isLoadingMore: false,
        lastError: result.errorOrNull,
      );
      return;
    }

    final page = result.dataOrNull ?? const MiningActorPage();
    state = state.copyWith(
      actors: mergeMiningActors(
        state.actors,
        _withoutPendingRecycles(page.records),
      ),
      isLoadingMore: false,
      currentPage: page.pageNumber,
      totalCount: page.totalRow,
      hasMore: page.hasMore,
      clearLastError: true,
    );
  }

  List<MiningActor> _withoutPendingRecycles(Iterable<MiningActor> actors) =>
      actors
          .where((actor) => !_pendingRecycledActorIds.contains(actor.nftId))
          .toList(growable: false);

  Future<Result<ActorNftRecycleEstimateResponse>> getRecycleEstimate(
    MiningActor actor,
  ) {
    final nftAddress = actor.nftId;
    if (nftAddress.isEmpty) {
      return Future.value(
        Result.failure(ApiError.validation('Actor NFT address is required')),
      );
    }
    return _repository.getActorNftRecycleEstimate(nftAddress: nftAddress);
  }

  /// Creates a server-signed recycle order, submits the sponsored burn
  /// transaction, and removes the actor from this sheet after submission.
  Future<Result<String>> recycleActor({
    required MiningActor actor,
    required ActorNftRecycleEstimateResponse estimate,
  }) async {
    final nftAddress = actor.nftId;
    if (nftAddress.isEmpty) {
      return Result.failure(
        ApiError.validation('Actor NFT address is required'),
      );
    }
    if (state.recyclingActorNftId != null) {
      return Result.failure(
        ApiError.business(-1, 'Another actor recycle is in progress'),
      );
    }

    final auth = ref.read(authControllerProvider);
    final walletAddress = auth.effectiveSolanaAddress.trim();
    if (!auth.isLoggedIn || walletAddress.isEmpty) {
      return Result.failure(ApiError.unauthorized('Wallet login required'));
    }

    state = state.copyWith(
      recyclingActorNftId: nftAddress,
      clearLastError: true,
    );
    Result<String> fail(ApiError error) {
      if (ref.mounted) {
        state = state.copyWith(
          clearRecyclingActorNftId: true,
          lastError: error,
        );
      }
      return Result.failure(error);
    }

    try {
      // Resolve fresh contract addresses before requesting a short-lived
      // order signature, so configuration I/O does not consume its lifetime.
      final configResult = await ref
          .read(configRepositoryProvider)
          .getGlobalConfig(forceRefresh: true);
      if (!ref.mounted) {
        return Result.failure(ApiError.unknown('Recycle controller disposed'));
      }
      if (configResult.isFailure) return fail(configResult.errorOrNull!);
      final chain = _resolveRecycleChain(configResult.dataOrNull);
      if (chain == null) {
        return fail(
          ApiError.notSupported(
            'Actor recycle contract is unavailable in this environment',
          ),
        );
      }

      final orderResult = await _repository.createActorNftRecycleOrder(
        toAddress: walletAddress,
        nftAddress: nftAddress,
      );
      if (!ref.mounted) {
        return Result.failure(ApiError.unknown('Recycle controller disposed'));
      }
      if (orderResult.isFailure) return fail(orderResult.errorOrNull!);

      final order = orderResult.dataOrNull;
      final validation = _validateRecycleOrder(
        order,
        walletAddress: walletAddress,
        estimate: estimate,
      );
      if (validation != null) return fail(validation);

      final sponsorResult = await ref
          .read(sponsorServiceProvider)
          .submitSponsorBurnActorNft(
            SponsorBurnActorNftParams(
              userSolanaAddress: walletAddress,
              collectionAssetId: estimate.actorCollectionId,
              assetId: order!.assetId,
              orderNo: order.orderNo,
              canonicalPayload: order.payload,
              sigBase64: order.sig,
              payTokenMint: chain.usdcMint,
              rpcHttpUrl: chain.rpc,
              storyProgramAddress: chain.storyProgram,
              delegatorAddress: chain.delegator,
              spenderAddress: chain.spender,
              sponsorApiUrl: chain.sponsorUrl,
            ),
          );
      if (!ref.mounted) {
        return Result.failure(ApiError.unknown('Recycle controller disposed'));
      }
      if (sponsorResult.isFailure) return fail(sponsorResult.errorOrNull!);

      final txHash = sponsorResult.dataOrNull!;
      final confirmation = await const SolanaTransactionConfirmService()
          .confirm(
            rpcHttpUrl: chain.rpc,
            signature: txHash,
            action: 'actor recycle',
          );
      if (!ref.mounted) return Result.success(txHash);
      if (confirmation.isFailure && confirmation.errorOrNull is! TimeoutError) {
        return fail(confirmation.errorOrNull!);
      }

      // A submitted order must not be shown as recyclable again while the
      // mining indexer catches up. Confirmation timeouts remain pending, not
      // failures, because resubmitting the signed order risks duplication.
      _pendingRecycledActorIds.add(nftAddress);
      state = state.copyWith(
        actors: state.actors
            .where((candidate) => candidate.nftId != nftAddress)
            .toList(growable: false),
        totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
        clearRecyclingActorNftId: true,
        clearLastError: true,
      );
      ref
          .read(agentV3ControllerProvider.notifier)
          .markActorRecycleSubmitted(
            nftAddress,
            refundedTrainingManual:
                double.tryParse(estimate.refundTrainingManual.trim()) ?? 0,
          );
      return Result.success(txHash);
    } catch (error, stackTrace) {
      StoryLogger.e(
        'Unexpected actor recycle failure',
        error: error,
        stackTrace: stackTrace,
        tag: 'AgentV3Recycle',
      );
      return fail(
        ApiError.unknown(
          error.toString(),
          exception: error is Exception ? error : null,
        ),
      );
    }
  }
}

class _RecycleChainContext {
  final String rpc;
  final String sponsorUrl;
  final String storyProgram;
  final String delegator;
  final String spender;
  final String usdcMint;

  const _RecycleChainContext({
    required this.rpc,
    required this.sponsorUrl,
    required this.storyProgram,
    required this.delegator,
    required this.spender,
    required this.usdcMint,
  });
}

_RecycleChainContext? _resolveRecycleChain(GlobalConfig? config) {
  if (config == null) return null;
  MapEntry<String, ChainInfo>? chainEntry;
  final chainlinks = config.chainlinks;
  if (chainlinks == null) return null;
  for (final entry in chainlinks.entries) {
    if (entry.value.chainType?.toLowerCase() == 'svm') {
      chainEntry = entry;
      break;
    }
  }
  if (chainEntry == null) return null;

  final chain = chainEntry.value;
  final contracts = chain.contracts;
  WalletToken? usdc;
  final tokens = chain.tokens;
  if (tokens != null) {
    for (final entry in tokens.entries) {
      if ((entry.value.symbol ?? entry.key).toUpperCase() == 'USDC') {
        usdc = entry.value;
        break;
      }
    }
  }
  String? sponsorUrl;
  for (final deposit in config.init?.deposit ?? const <InitDepositConfig>[]) {
    final api = deposit.api?.trim();
    if (api != null &&
        api.isNotEmpty &&
        (deposit.chain == chainEntry.key || deposit.chainType == 'svm')) {
      sponsorUrl = api;
      break;
    }
  }
  sponsorUrl ??= '/api/nfp/v1/sponsor/${chainEntry.key}';

  final rpc = chain.rpc?.http?.trim();
  final storyProgram = contracts?.story?.trim();
  final delegator = contracts?.storyDelegator?.trim();
  final spender = contracts?.spender?.trim();
  final usdcMint = usdc?.address?.trim();
  if ([
    rpc,
    storyProgram,
    delegator,
    spender,
    usdcMint,
  ].any((value) => value == null || value.isEmpty)) {
    return null;
  }
  return _RecycleChainContext(
    rpc: rpc!,
    sponsorUrl: sponsorUrl,
    storyProgram: storyProgram!,
    delegator: delegator!,
    spender: spender!,
    usdcMint: usdcMint!,
  );
}

ApiError? _validateRecycleOrder(
  ActorNftRecycleOrderResponse? order, {
  required String walletAddress,
  required ActorNftRecycleEstimateResponse estimate,
}) {
  if (order == null ||
      order.sig.trim().isEmpty ||
      order.payload.trim().isEmpty) {
    return ApiError.validation('Incomplete actor recycle order payload');
  }
  final parts = order.payload.split('|');
  if (parts.length != 6 ||
      parts[0] != 'actor_nft_burn' ||
      parts[1] != order.assetId ||
      parts[1] != estimate.assetId ||
      parts[2] != walletAddress ||
      parts[3] != order.refundAmountMinor ||
      parts[3] != estimate.refundAmountMinor ||
      parts[4] != order.orderNo ||
      parts[5] != order.expiresAt ||
      order.refundUsdcAmount != estimate.refundUsdcAmount ||
      order.refundTrainingManual != estimate.refundTrainingManual) {
    return ApiError.validation('Actor recycle order does not match estimate');
  }
  final expiresAt = int.tryParse(order.expiresAt);
  if (expiresAt == null ||
      expiresAt <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
    return ApiError.validation('Actor recycle signature has expired');
  }
  return null;
}
