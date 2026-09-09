import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_env.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/item_repository.dart';
import '../services/solana/generated/story_program.g.dart';
import '../services/solana/solana_transaction_confirm_service.dart';
import '../services/sponsor_service.dart';
import '../services/wallet_ledger.dart';
import 'agent_v3_state.dart';

const _creditPollInterval = Duration(seconds: 2);
const _creditPollAttempts = 20;
const _recycleReconcileInterval = Duration(seconds: 2);
const _recycleReconcileAttempts = 5;

/// `purchase_card` 开放 Development/Test；Production 保持关闭。
bool isCardPurchaseContractEnabled({
  required StoryEnv env,
  required GlobalConfig? config,
}) {
  if (env.isProduction || config == null) return false;
  final chains = config.chainlinks;
  if (chains == null) return false;
  for (final chain in chains.values) {
    if (chain.chainType?.toLowerCase() != 'svm') continue;
    final program = chain.contracts?.story?.trim();
    return program != null && StoryContractMetadata.isAllowedProgramId(program);
  }
  return false;
}

class _CardPurchaseChainContext {
  final String rpc;
  final String sponsorUrl;
  final String storyProgram;
  final String delegator;
  final String treasury;
  final String spender;
  final String usdcMint;
  final int usdcDecimals;

  const _CardPurchaseChainContext({
    required this.rpc,
    required this.sponsorUrl,
    required this.storyProgram,
    required this.delegator,
    required this.treasury,
    required this.spender,
    required this.usdcMint,
    required this.usdcDecimals,
  });
}

/// 经纪人 V3 数据与非生产环境道具购买编排。
class AgentV3Controller extends Notifier<AgentV3State> {
  ItemRepository get _items => ref.read(itemRepositoryProvider);
  final Set<String> _pendingRecycledActorIds = {};
  final Map<CardPurchaseType, Future<bool>> _pendingCreditPolls = {};
  Future<bool>? _recycleCreditPoll;
  double? _recycleTrainingManualTarget;
  int _recycleCreditRevision = 0;
  bool _isReconcilingRecycledActors = false;
  bool _isRestMutationInFlight = false;
  Future<void>? _syncInFlight;
  bool _syncQueued = false;
  AgentV3SyncReason _queuedSyncReason = AgentV3SyncReason.periodic;
  int _sessionGeneration = 0;

  @override
  AgentV3State build() {
    ref.listen<({bool loggedIn, String? sessionId})>(
      authControllerProvider.select(
        (auth) =>
            (loggedIn: auth.isLoggedIn, sessionId: auth.userId ?? auth.token),
      ),
      (previous, current) {
        final loggedOut = previous?.loggedIn == true && !current.loggedIn;
        final accountChanged =
            previous?.loggedIn == true &&
            current.loggedIn &&
            previous?.sessionId != current.sessionId;
        if (loggedOut || accountChanged) _resetSessionState();
      },
    );
    return const AgentV3State();
  }

  /// Backwards-compatible manual refresh entry point.
  Future<void> refresh() => synchronize(reason: AgentV3SyncReason.manual);

  /// Coalesces lifecycle, tab, connectivity and timer triggers into one
  /// authoritative multi-endpoint calibration. Triggers received while a
  /// request is running add at most one trailing calibration.
  Future<void> synchronize({required AgentV3SyncReason reason}) {
    final running = _syncInFlight;
    if (running != null) {
      _syncQueued = true;
      _queuedSyncReason = reason;
      return running;
    }

    late final Future<void> operation;
    operation = _drainSynchronizations(reason).whenComplete(() {
      if (identical(_syncInFlight, operation)) _syncInFlight = null;
    });
    _syncInFlight = operation;
    return operation;
  }

  /// Records that an external event may have invalidated the retained page.
  /// The page consumes this marker when it next becomes visible.
  void markDirty() {
    if (!state.isDirty) state = state.copyWith(isDirty: true);
  }

  Future<void> _drainSynchronizations(AgentV3SyncReason initialReason) async {
    var reason = initialReason;
    do {
      _syncQueued = false;
      try {
        await _performSynchronization(reason);
      } catch (error, stackTrace) {
        StoryLogger.w(
          'Unexpected Agent V3 synchronization failure',
          error: error,
          stackTrace: stackTrace,
          tag: 'AgentV3Sync',
        );
        if (ref.mounted) {
          state = state.copyWith(
            isLoading: false,
            isRefreshing: false,
            isDirty: true,
            lastError: ApiError.unknown(error.toString()),
          );
        }
      }
      reason = _queuedSyncReason;
    } while (_syncQueued && ref.mounted);
  }

  Future<void> _performSynchronization(AgentV3SyncReason reason) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn || auth.isLogging) {
      _resetSessionState();
      return;
    }

    final generation = _sessionGeneration;
    final sessionKey = _sessionKey();
    final isInitialLoad = state.lastSyncReason == null;

    state = state.copyWith(
      isLoading: isInitialLoad,
      isRefreshing: !isInitialLoad,
      lastSyncReason: reason,
      clearLastError: true,
    );
    final configFuture = ref.read(globalConfigProvider.future);
    final assetsFuture = ref
        .read(userRepositoryProvider)
        .getAssets(forceRefresh: true);
    final weeklyStatsFuture = ref
        .read(rewardRepositoryProvider)
        .refreshWeeklyStats();
    final miningRepository = ref.read(miningRepositoryProvider);
    final deployedActorsFuture = miningRepository.refreshDeployedActors();
    final upgradeableCountFuture = miningRepository.getUpgradeableActorCount();
    final candidateActorsFuture = ref
        .read(agentV2CandidateActorsControllerProvider.notifier)
        .refresh();
    final configResult = await configFuture;
    final assetsResult = await assetsFuture;
    final weeklyStatsResult = await weeklyStatsFuture;
    final deployedActorsResult = await deployedActorsFuture;
    final upgradeableCountResult = await upgradeableCountFuture;
    await candidateActorsFuture;
    if (!ref.mounted ||
        generation != _sessionGeneration ||
        sessionKey != _sessionKey()) {
      return;
    }

    final config = configResult.dataOrNull;
    final candidateActorsError = ref
        .read(agentV2CandidateActorsControllerProvider)
        .lastError;
    final pageError =
        configResult.errorOrNull ??
        assetsResult.errorOrNull ??
        weeklyStatsResult.errorOrNull ??
        deployedActorsResult.errorOrNull ??
        upgradeableCountResult.errorOrNull;
    final hasAnyError = pageError != null || candidateActorsError != null;
    state = state.copyWith(
      isLoading: false,
      isRefreshing: false,
      isDirty: hasAnyError,
      purchaseEnabled: _isPurchaseEnabled(config),
      assets: assetsResult.dataOrNull,
      energyPackUnitPrice: resolveCardPurchaseUnitPrice(
        config,
        CardPurchaseType.energyPack,
      ),
      trainingManualUnitPrice: resolveCardPurchaseUnitPrice(
        config,
        CardPurchaseType.trainingManual,
      ),
      weeklyStats: weeklyStatsResult.dataOrNull,
      deployedActors: switch (deployedActorsResult.dataOrNull) {
        final actors? => _withoutPendingRecycles(actors),
        null => null,
      },
      upgradeableCount: upgradeableCountResult.dataOrNull,
      // Global config and Agent V2's scoped config contain the same `init`
      // payload. Reuse this request rather than fetching the config twice.
      staminaLimit: config?.init?.actorNft?.staminaLimit,
      actorNftConfig: config?.init?.actorNft,
      lastSuccessfulSyncAt: hasAnyError ? null : DateTime.now(),
      lastError: pageError,
    );
  }

  String? _sessionKey() {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn) return null;
    return auth.userId ?? auth.token;
  }

  void _resetSessionState() {
    _sessionGeneration++;
    _syncQueued = false;
    _syncInFlight = null;
    _pendingRecycledActorIds.clear();
    _pendingCreditPolls.clear();
    _recycleCreditPoll = null;
    _recycleTrainingManualTarget = null;
    _recycleCreditRevision++;
    state = const AgentV3State();
  }

  /// Immediately removes a submitted recycle from the V3 performing carousel,
  /// then reconciles the list while the mining indexer catches up.
  ///
  /// Pending ids are also filtered from ordinary [refresh] results, so a stale
  /// response cannot make a recycled actor flash back into the carousel.
  void markActorRecycleSubmitted(
    String actorNftId, {
    double refundedTrainingManual = 0,
    int maxAttempts = _recycleReconcileAttempts,
    Duration retryDelay = _recycleReconcileInterval,
    int creditPollAttempts = _creditPollAttempts,
    Duration creditRetryDelay = _creditPollInterval,
  }) {
    final normalizedId = actorNftId.trim();
    if (normalizedId.isEmpty) return;

    _pendingRecycledActorIds.add(normalizedId);
    _registerOptimisticRecycleCredit(
      refundedTrainingManual,
      maxAttempts: creditPollAttempts,
      retryDelay: creditRetryDelay,
    );
    state = state.copyWith(
      deployedActors: _withoutPendingRecycles(state.deployedActors),
    );

    if (_isReconcilingRecycledActors || maxAttempts <= 0) return;
    unawaited(
      _reconcileRecycledActors(
        maxAttempts: maxAttempts,
        retryDelay: retryDelay,
      ),
    );
  }

  void _registerOptimisticRecycleCredit(
    double amount, {
    required int maxAttempts,
    required Duration retryDelay,
  }) {
    if (!amount.isFinite || amount <= 0) return;

    final actual = (state.assets ?? UserAssets.empty).trainingManual;
    final currentFloor = state.optimisticTrainingManualFloor;
    final baseline = currentFloor != null && currentFloor > actual
        ? currentFloor
        : actual;
    final target = baseline + amount;
    _recycleTrainingManualTarget = target;
    _recycleCreditRevision++;
    state = state.copyWith(optimisticTrainingManualFloor: target);

    if (_recycleCreditPoll != null || maxAttempts <= 0) return;
    late final Future<bool> poll;
    poll = _pollRecycleTrainingManualCredit(
      maxAttempts: maxAttempts,
      retryDelay: retryDelay,
    );
    _recycleCreditPoll = poll;
    unawaited(
      poll.whenComplete(() {
        if (identical(_recycleCreditPoll, poll)) {
          _recycleCreditPoll = null;
        }
      }),
    );
  }

  Future<bool> _pollRecycleTrainingManualCredit({
    required int maxAttempts,
    required Duration retryDelay,
  }) async {
    final generation = _sessionGeneration;
    final credited = await _pollAssetCredit(
      asset: AssetCode.trainingManual,
      target: () => _recycleTrainingManualTarget ?? double.infinity,
      revision: () => _recycleCreditRevision,
      maxAttempts: maxAttempts,
      retryDelay: retryDelay,
    );
    if (!ref.mounted || generation != _sessionGeneration) return credited;

    final target = _recycleTrainingManualTarget;
    _recycleTrainingManualTarget = null;
    state = state.copyWith(clearOptimisticTrainingManualFloor: true);
    if (credited) {
      StoryLogger.i(
        'credited asset=${AssetCode.trainingManual.code} target=$target',
        tag: 'AgentV3Recycle',
      );
    } else {
      StoryLogger.w(
        'credit pending asset=${AssetCode.trainingManual.code} target=$target '
        'after=$maxAttempts attempts',
        tag: 'AgentV3Recycle',
      );
    }
    return credited;
  }

  Future<void> _reconcileRecycledActors({
    required int maxAttempts,
    required Duration retryDelay,
  }) async {
    _isReconcilingRecycledActors = true;
    final repository = ref.read(miningRepositoryProvider);
    try {
      await repository.invalidateGameCache();
      if (!ref.mounted) return;

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        if (attempt > 0) {
          await Future<void>.delayed(retryDelay);
          if (!ref.mounted) return;
        }

        final result = await repository.refreshDeployedActors();
        if (!ref.mounted) return;
        final actors = result.dataOrNull;
        if (actors == null) {
          StoryLogger.w(
            'Failed to reconcile recycled actors, attempt=${attempt + 1}',
            tag: 'AgentV3Recycle',
          );
          continue;
        }

        final serverActorIds = actors.map((actor) => actor.nftId).toSet();
        _pendingRecycledActorIds.removeWhere(
          (actorId) => !serverActorIds.contains(actorId),
        );
        state = state.copyWith(deployedActors: _withoutPendingRecycles(actors));
        if (_pendingRecycledActorIds.isEmpty) return;
      }
    } catch (error, stackTrace) {
      StoryLogger.w(
        'Unexpected recycled actor reconciliation failure',
        error: error,
        stackTrace: stackTrace,
        tag: 'AgentV3Recycle',
      );
    } finally {
      _isReconcilingRecycledActors = false;
    }
  }

  List<MiningActor> _withoutPendingRecycles(Iterable<MiningActor> actors) =>
      actors
          .where((actor) => !_pendingRecycledActorIds.contains(actor.nftId))
          .toList(growable: false);

  /// Centrally consumes stamina packs and refills one actor to the backend
  /// configured stamina limit.
  Future<Result<StaminaRefillResult>> refillStaminaWithPack(
    MiningActor actor,
  ) async {
    final actorNftId = actor.nftId;
    if (actorNftId.isEmpty) {
      return Result.failure(ApiError.validation('Actor NFT id is required'));
    }

    final result = await ref
        .read(miningRepositoryProvider)
        .replenishStaminaWithPack(actorNftId: actorNftId);
    if (!ref.mounted || result.isFailure) return result;

    final refill = result.dataOrNull!;
    state = state.copyWith(
      deployedActors: state.deployedActors
          .map(
            (deployed) => deployed.nftId == refill.actorNftId
                ? deployed.copyWith(stamina: refill.afterStamina)
                : deployed,
          )
          .toList(growable: false),
    );

    // Stamina-pack inventory is centralized. Refresh it after the mutation so
    // the V3 app bar and any subsequent dialog use the authoritative balance.
    final assetsResult = await ref
        .read(userRepositoryProvider)
        .getAssets(forceRefresh: true);
    final assets = assetsResult.dataOrNull;
    if (ref.mounted && assets != null) {
      state = state.copyWith(assets: assets);
    }
    return result;
  }

  /// 一键安排当前所有可用候场角色，并把成功结果立即合并到 V3 轮播。
  Future<Result<int>> performAllActors() async {
    if (state.vacantDeploySlotCount <= 0) {
      return Result.failure(ApiError.validation('No vacant performance slot'));
    }

    final result = await ref.read(miningRepositoryProvider).deployAllActors();
    if (!ref.mounted) {
      return Result.failure(ApiError.unknown('Agent V3 controller disposed'));
    }
    if (result.isFailure) {
      state = state.copyWith(lastError: result.errorOrNull);
      return Result.failure(result.errorOrNull!);
    }

    final performedActors = result.dataOrNull ?? const <MiningActor>[];
    final actorsById = <String, MiningActor>{
      for (final actor in state.deployedActors) actor.nftId: actor,
      for (final actor in performedActors) actor.nftId: actor,
    };
    state = state.copyWith(
      deployedActors: actorsById.values
          .take(agentV3DeploySlotCount)
          .toList(growable: false),
      clearLastError: true,
    );
    ref.read(weeklySalaryControllerProvider.notifier).refreshAfterMutation();
    return Result.success(performedActors.length);
  }

  /// 在经纪人页直接领取全部已结算 STORY，并刷新可领取余额。
  Future<Result<WithdrawCreateResponse>> claimStory({
    required String toAddress,
  }) async {
    final normalizedAddress = toAddress.trim();
    final amount = state.claimableStory;
    if (normalizedAddress.isEmpty) {
      return Result.failure(ApiError.validation('Wallet address is required'));
    }
    if (amount <= 0) {
      return Result.failure(ApiError.validation('No STORY to claim'));
    }

    final result = await ref
        .read(rewardRepositoryProvider)
        .claim(
          assetCode: AssetCode.story.code,
          amount: amount,
          toAddress: normalizedAddress,
        );
    if (!ref.mounted) return result;
    if (result.isFailure) {
      state = state.copyWith(lastError: result.errorOrNull);
      return result;
    }

    // 提现成功后先清空本地可领取余额，避免资产接口短暂延迟时重复提交。
    final currentAssets = state.assets ?? UserAssets.empty;
    state = state.copyWith(
      assets: UserAssets(
        currentAssets.balances.map((balance) {
          if (!AssetCode.story.matches(balance.assetCode)) return balance;
          return WalletBalance(
            assetCode: balance.assetCode,
            availableBalance: 0,
            frozenBalance: balance.frozenBalance,
            decimals: balance.decimals,
          );
        }),
      ),
      clearLastError: true,
    );

    final assetsResult = await ref
        .read(userRepositoryProvider)
        .getAssets(forceRefresh: true);
    final refreshedAssets = assetsResult.dataOrNull;
    if (ref.mounted &&
        refreshedAssets != null &&
        refreshedAssets.story < amount) {
      state = state.copyWith(assets: refreshedAssets);
    }
    return result;
  }

  /// 使用体力包补满所有已在演且体力耗尽的角色。
  Future<Result<StaminaRefillBatchResult>>
  refillAllDepletedActorsWithPack() async {
    final depletedActors = state.deployedActors
        .take(agentV3DeploySlotCount)
        .where((actor) => actor.stamina == 0 && actor.nftId.isNotEmpty)
        .toList(growable: false);
    if (depletedActors.isEmpty) {
      return Result.failure(ApiError.validation('No depleted actor to refill'));
    }

    return refillActorsWithPack(
      depletedActors.map(
        (actor) =>
            ActorNeedingStaminaRefill(actorNftId: actor.nftId, supplyFee: 0),
      ),
    );
  }

  /// 使用接口返回的待补充角色快照批量消耗体力包。
  Future<Result<StaminaRefillBatchResult>> refillActorsWithPack(
    Iterable<ActorNeedingStaminaRefill> actors,
  ) async {
    final actorIds = actors
        .map((actor) => actor.actorNftId.trim())
        .where((actorNftId) => actorNftId.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (actorIds.isEmpty) {
      return Result.failure(ApiError.validation('No actor to refill'));
    }

    final result = await ref
        .read(miningRepositoryProvider)
        .replenishStaminaBatchWithPack(
          StaminaRefillBatchRequest(
            items: actorIds
                .map(
                  (actorNftId) =>
                      StaminaRefillBatchItem(actorNftId: actorNftId),
                )
                .toList(growable: false),
          ),
        );
    if (!ref.mounted || result.isFailure) {
      if (ref.mounted && result.isFailure) {
        state = state.copyWith(lastError: result.errorOrNull);
      }
      return result;
    }

    final refillsById = <String, StaminaRefillResult>{
      for (final refill
          in result.dataOrNull?.items ?? const <StaminaRefillResult>[])
        refill.actorNftId: refill,
    };
    state = state.copyWith(
      deployedActors: state.deployedActors
          .map((actor) {
            final refill = refillsById[actor.nftId];
            return refill == null
                ? actor
                : actor.copyWith(stamina: refill.afterStamina);
          })
          .toList(growable: false),
      clearLastError: true,
    );

    final assetsResult = await ref
        .read(userRepositoryProvider)
        .getAssets(forceRefresh: true);
    final assets = assetsResult.dataOrNull;
    if (ref.mounted && assets != null) {
      state = state.copyWith(assets: assets);
    }
    return result;
  }

  /// Uses the same centralized rest endpoint as V2 and immediately removes
  /// the actor from the V3 performing carousel after a successful response.
  Future<Result<void>> restActor(MiningActor actor) async {
    final actorNftId = actor.nftId;
    if (actorNftId.isEmpty) {
      return Result.failure(ApiError.validation('Actor NFT id is required'));
    }
    if (_isRestMutationInFlight) {
      return Result.failure(
        ApiError.business(-1, 'Another rest request is in progress'),
      );
    }

    _isRestMutationInFlight = true;
    try {
      final result = await ref
          .read(miningRepositoryProvider)
          .restActor(actorNftId);
      if (!ref.mounted) return result;
      if (result.isFailure) {
        state = state.copyWith(lastError: result.errorOrNull);
        return result;
      }

      state = state.copyWith(
        deployedActors: state.deployedActors
            .where((deployed) => deployed.nftId != actorNftId)
            .toList(growable: false),
        clearLastError: true,
      );
      ref
          .read(agentV2CandidateActorsControllerProvider.notifier)
          .allowActorToReturn(actorNftId);
      _refreshWeeklyStatsAfterRest();
      return result;
    } finally {
      _isRestMutationInFlight = false;
    }
  }

  /// Uses V2's existing batch-rest endpoint for the shared confirmation card.
  Future<Result<void>> restAllActors() async {
    if (state.deployedActors.isEmpty) {
      return Result.failure(ApiError.validation('No deployed actors to rest'));
    }
    if (_isRestMutationInFlight) {
      return Result.failure(
        ApiError.business(-1, 'Another rest request is in progress'),
      );
    }

    _isRestMutationInFlight = true;
    try {
      final result = await ref.read(miningRepositoryProvider).restAllActors();
      if (!ref.mounted) return result;
      if (result.isFailure) {
        state = state.copyWith(lastError: result.errorOrNull);
        return result;
      }

      state = state.copyWith(deployedActors: const [], clearLastError: true);
      ref
          .read(agentV2CandidateActorsControllerProvider.notifier)
          .allowAllActorsToReturn();
      _refreshWeeklyStatsAfterRest();
      return result;
    } finally {
      _isRestMutationInFlight = false;
    }
  }

  void _refreshWeeklyStatsAfterRest() {
    unawaited(() async {
      try {
        final result = await ref
            .read(rewardRepositoryProvider)
            .refreshWeeklyStats();
        final weeklyStats = result.dataOrNull;
        if (ref.mounted && weeklyStats != null) {
          state = state.copyWith(weeklyStats: weeklyStats);
        }
      } catch (error, stackTrace) {
        StoryLogger.w(
          'Failed to refresh V3 weekly stats after resting actors',
          error: error,
          stackTrace: stackTrace,
          tag: 'AgentV3Rest',
        );
      }
    }());
  }

  /// 创建签名订单、提交 sponsor 交易并等待链上确认。
  ///
  /// 返回交易签名只代表链上购买已提交；中心化道具由 CARD_PURCHASE 扫链异步入账。
  Future<Result<String>> purchase({
    required CardPurchaseType type,
    required int quantity,
  }) async {
    if (quantity < 1) {
      return Result.failure(
        ApiError.validation('Purchase quantity must be at least 1'),
      );
    }
    if (state.isPurchasing) {
      return Result.failure(ApiError.business(-1, 'Purchase is in progress'));
    }

    final auth = ref.read(authControllerProvider);
    final walletAddress = auth.solanaAddress.trim();
    if (!auth.isLoggedIn || walletAddress.isEmpty) {
      return Result.failure(ApiError.unauthorized('Wallet login required'));
    }

    state = state.copyWith(isPurchasing: true, clearLastError: true);
    var stage = 'start';
    Result<String> fail(ApiError error) =>
        _fail(error, stage: stage, type: type, quantity: quantity);
    StoryLogger.i(
      'start type=${type.apiValue} qty=$quantity '
      'wallet=${_shortValue(walletAddress)}',
      tag: 'CardPurchase',
    );
    SpendTicket? spendTicket;
    try {
      stage = 'config';
      // 强制刷新配置，避免使用五分钟缓存中的旧单价或旧合约地址。
      final configResult = await ref
          .read(configRepositoryProvider)
          .getGlobalConfig(forceRefresh: true);
      if (!ref.mounted) {
        return Result.failure(ApiError.unknown('Purchase controller disposed'));
      }
      final config = configResult.dataOrNull;
      if (configResult.isFailure || config == null) {
        return fail(configResult.errorOrNull!);
      }
      final chain = _resolveChainContext(config);
      if (chain == null || !_isPurchaseEnabled(config)) {
        return fail(
          ApiError.notSupported(
            'Card purchase contract is not available in this environment',
          ),
        );
      }

      stage = 'price';
      final unitPrice = resolveCardPurchaseUnitPrice(config, type);
      final expectedMinor = _majorAmountToMinor(
        unitPrice,
        decimals: chain.usdcDecimals,
        quantity: quantity,
      );
      if (expectedMinor == null || expectedMinor <= BigInt.zero) {
        return fail(ApiError.validation('Invalid consumable item price'));
      }
      StoryLogger.d(
        'price type=${type.apiValue} asset=${type.creditedAsset.code} '
        'unit=$unitPrice qty=$quantity payMinor=$expectedMinor',
        tag: 'CardPurchase',
      );

      stage = 'assets';
      // 记录购买前余额，供后续判断扫链入账是否完成。
      final beforeAssets = await ref
          .read(userRepositoryProvider)
          .getAssets(forceRefresh: true);
      if (!ref.mounted) {
        return Result.failure(ApiError.unknown('Purchase controller disposed'));
      }
      if (beforeAssets.isFailure) return fail(beforeAssets.errorOrNull!);
      final baseline = beforeAssets.dataOrNull!.available(type.creditedAsset);
      StoryLogger.d(
        'assets type=${type.creditedAsset.code} baseline=$baseline',
        tag: 'CardPurchase',
      );

      stage = 'order';
      final orderResult = await _items.createPurchaseOrder(
        CardPurchaseOrderRequest.forType(
          walletAddress: walletAddress,
          type: type,
          quantity: quantity,
        ),
      );
      if (!ref.mounted) {
        return Result.failure(ApiError.unknown('Purchase controller disposed'));
      }
      if (orderResult.isFailure) return fail(orderResult.errorOrNull!);

      final order = orderResult.dataOrNull;
      stage = 'order_validation';
      // 逐字段校验签名明文，防止钱包、金额或订单号被替换。
      final validation = _validateOrder(
        order,
        walletAddress: walletAddress,
        type: type,
        expectedPayAmountMinor: expectedMinor,
      );
      if (validation != null) return fail(validation);

      final payAmountMinor = order!.payAmountMinor!;
      StoryLogger.i(
        'order ready type=${type.apiValue} '
        'order=${_shortValue(order.orderNo!)} payMinor=$payAmountMinor',
        tag: 'CardPurchase',
      );
      final charge =
          expectedMinor.toDouble() /
          math.pow(10, chain.usdcDecimals).toDouble();
      stage = 'balance';
      // 链上提交前校验 USDC 余额，并做本地预扣。
      final ledger = ref.read(walletLedgerProvider);
      final prepared = await ledger.prepareSpend(
        SpendQuote(
          asset: SpendAsset.usdc,
          amount: charge,
          reason: 'purchase_${type.apiValue.toLowerCase()}',
        ),
      );
      if (!ref.mounted) {
        if (prepared.dataOrNull?.didDeduct == true) {
          await ledger.reconcile(prepared.dataOrNull);
        }
        return Result.failure(ApiError.unknown('Purchase controller disposed'));
      }
      if (prepared.isFailure) return fail(prepared.errorOrNull!);
      spendTicket = prepared.dataOrNull!;
      StoryLogger.d(
        'balance verified order=${_shortValue(order.orderNo!)} '
        'required=$charge USDC',
        tag: 'CardPurchase',
      );

      stage = 'sponsor';
      // sponsor 代付手续费并提交 purchase_card 交易。
      final sponsorResult = await ref
          .read(sponsorServiceProvider)
          .submitSponsorPurchaseCard(
            SponsorPurchaseCardParams(
              userSolanaAddress: walletAddress,
              cardType: type.apiValue,
              payAmountMinor: payAmountMinor,
              orderNo: order.orderNo!,
              canonicalPayload: order.payload!,
              sigBase64: order.sig!,
              payTokenMint: chain.usdcMint,
              rpcHttpUrl: chain.rpc,
              storyProgramAddress: chain.storyProgram,
              delegatorAddress: chain.delegator,
              treasuryAddress: chain.treasury,
              spenderAddress: chain.spender,
              sponsorApiUrl: chain.sponsorUrl,
            ),
          );
      if (!ref.mounted) {
        if (spendTicket.didDeduct) await ledger.reconcile(spendTicket);
        return Result.failure(ApiError.unknown('Purchase controller disposed'));
      }
      if (sponsorResult.isFailure) {
        if (spendTicket.didDeduct) await ledger.reconcile(spendTicket);
        return fail(sponsorResult.errorOrNull!);
      }

      final txHash = sponsorResult.dataOrNull!;
      StoryLogger.i(
        'submitted order=${_shortValue(order.orderNo!)} '
        'tx=${_shortValue(txHash)}',
        tag: 'CardPurchase',
      );
      stage = 'confirmation';
      final confirmation = await const SolanaTransactionConfirmService()
          .confirm(
            rpcHttpUrl: chain.rpc,
            signature: txHash,
            action: 'card purchase',
          );
      if (!ref.mounted) {
        await ledger.reconcile(spendTicket);
        return Result.success(txHash);
      }
      if (confirmation.isFailure && confirmation.errorOrNull is! TimeoutError) {
        await ledger.reconcile(spendTicket);
        return fail(confirmation.errorOrNull!);
      }

      // 确认超时不等于失败，禁止重复提交同一订单。
      await ledger.commitSpend(spendTicket);
      StoryLogger.i(
        '${confirmation.isSuccess ? 'confirmed' : 'confirmation pending'} '
        'order=${_shortValue(order.orderNo!)}',
        tag: 'CardPurchase',
      );
      state = state.copyWith(
        isPurchasing: false,
        pendingCreditType: type,
        assets: beforeAssets.dataOrNull,
      );
      final creditPoll = _pollCredited(
        type: type,
        baseline: baseline,
        quantity: quantity,
      );
      _pendingCreditPolls[type] = creditPoll;
      unawaited(
        creditPoll.whenComplete(() {
          if (identical(_pendingCreditPolls[type], creditPoll)) {
            _pendingCreditPolls.remove(type);
          }
        }),
      );
      return Result.success(txHash);
    } catch (error, stackTrace) {
      StoryLogger.e(
        'unexpected failure stage=$stage type=${type.apiValue}',
        error: error,
        stackTrace: stackTrace,
        tag: 'CardPurchase',
      );
      if (spendTicket?.didDeduct == true) {
        await ref.read(walletLedgerProvider).reconcile(spendTicket);
      }
      return fail(
        ApiError.unknown(
          error.toString(),
          exception: error is Exception ? error : null,
        ),
      );
    }
  }

  Result<String> _fail(
    ApiError error, {
    required String stage,
    required CardPurchaseType type,
    required int quantity,
  }) {
    StoryLogger.w(
      'failed stage=$stage type=${type.apiValue} qty=$quantity '
      '${_errorSummary(error)}',
      tag: 'CardPurchase',
    );
    if (ref.mounted) {
      state = state.copyWith(isPurchasing: false, lastError: error);
    }
    return Result.failure(error);
  }

  /// 等待购买流程已有的扫链轮询完成，避免 UI 重复请求资产接口。
  Future<bool> waitForPurchaseCredit({
    required CardPurchaseType type,
    required double baseline,
    required int quantity,
  }) async {
    final target = baseline + quantity;
    final current = (state.assets ?? UserAssets.empty).available(
      type.creditedAsset,
    );
    if (current >= target) return true;
    final pendingPoll = _pendingCreditPolls[type];
    if (pendingPoll == null) return false;
    return pendingPoll;
  }

  Future<bool> _pollCredited({
    required CardPurchaseType type,
    required double baseline,
    required int quantity,
  }) async {
    final generation = _sessionGeneration;
    StoryLogger.d(
      'credit polling type=${type.creditedAsset.code} baseline=$baseline '
      'target=${baseline + quantity}',
      tag: 'CardPurchase',
    );
    final credited = await _pollAssetCredit(
      asset: type.creditedAsset,
      target: () => baseline + quantity,
      maxAttempts: _creditPollAttempts,
      retryDelay: _creditPollInterval,
    );
    if (ref.mounted && generation == _sessionGeneration) {
      state = state.copyWith(clearPendingCredit: true);
      if (credited) {
        StoryLogger.i(
          'credited type=${type.creditedAsset.code} '
          'balance=${state.assets?.available(type.creditedAsset)}',
          tag: 'CardPurchase',
        );
      } else {
        StoryLogger.w(
          'credit pending type=${type.creditedAsset.code} '
          'after=$_creditPollAttempts attempts',
          tag: 'CardPurchase',
        );
      }
    }
    return credited;
  }

  /// Polls the authoritative asset endpoint and keeps the shared V3 asset
  /// snapshot current. A revision source lets a coalesced caller extend its
  /// target (for example, when several actor recycles complete in sequence).
  Future<bool> _pollAssetCredit({
    required AssetCode asset,
    required double Function() target,
    required int maxAttempts,
    required Duration retryDelay,
    int Function()? revision,
  }) async {
    final repository = ref.read(userRepositoryProvider);
    final generation = _sessionGeneration;
    var observedRevision = revision?.call();
    var attempt = 0;
    while (attempt < maxAttempts) {
      if (attempt > 0) await Future<void>.delayed(retryDelay);
      if (!ref.mounted || generation != _sessionGeneration) return false;

      final currentRevision = revision?.call();
      if (currentRevision != observedRevision) {
        observedRevision = currentRevision;
        attempt = 0;
      }

      final result = await repository.getAssets(forceRefresh: true);
      if (!ref.mounted || generation != _sessionGeneration) return false;
      final assets = result.dataOrNull;
      if (assets != null) {
        state = state.copyWith(assets: assets);
        if (assets.available(asset) >= target()) return true;
      }
      attempt++;
    }
    return false;
  }

  bool _isPurchaseEnabled(GlobalConfig? config) {
    return isCardPurchaseContractEnabled(
      env: ref.read(storySdkConfigProvider).env,
      config: config,
    );
  }

  _CardPurchaseChainContext? _resolveChainContext(GlobalConfig config) {
    final chain = _findSvmChain(config);
    final contracts = chain?.contracts;
    final tokens = chain?.tokens;
    WalletToken? usdc;
    if (tokens != null) {
      for (final entry in tokens.entries) {
        final token = entry.value;
        if (token.symbol?.toUpperCase() == 'USDC' ||
            entry.key.toUpperCase() == 'USDC') {
          usdc = token;
          break;
        }
      }
    }
    final rpc = chain?.rpc?.http?.trim();
    final sponsorUrl = resolveSponsorApiUrl(config)?.trim();
    final storyProgram = contracts?.story?.trim();
    final delegator = contracts?.storyDelegator?.trim();
    final treasury = contracts?.storyTreasury?.trim();
    final spender = contracts?.spender?.trim();
    final usdcMint = usdc?.address?.trim();
    if ([
      rpc,
      sponsorUrl,
      storyProgram,
      delegator,
      treasury,
      spender,
      usdcMint,
    ].any((value) => value == null || value.isEmpty)) {
      return null;
    }
    return _CardPurchaseChainContext(
      rpc: rpc!,
      sponsorUrl: sponsorUrl!,
      storyProgram: storyProgram!,
      delegator: delegator!,
      treasury: treasury!,
      spender: spender!,
      usdcMint: usdcMint!,
      usdcDecimals: usdc?.decimals ?? 6,
    );
  }

  static ChainInfo? _findSvmChain(GlobalConfig config) {
    final chains = config.chainlinks;
    if (chains == null) return null;
    for (final chain in chains.values) {
      if (chain.chainType?.toLowerCase() == 'svm') return chain;
    }
    return null;
  }

  static BigInt? _majorAmountToMinor(
    String? amount, {
    required int decimals,
    required int quantity,
  }) {
    if (amount == null || decimals < 0 || quantity < 1) return null;
    final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(amount.trim());
    if (match == null) return null;
    final whole = BigInt.tryParse(match.group(1)!);
    final fraction = match.group(2) ?? '';
    if (whole == null || fraction.length > decimals) return null;
    final scale = BigInt.from(10).pow(decimals);
    final paddedFraction = fraction.padRight(decimals, '0');
    final fractionMinor = paddedFraction.isEmpty
        ? BigInt.zero
        : BigInt.parse(paddedFraction);
    return (whole * scale + fractionMinor) * BigInt.from(quantity);
  }

  static ApiError? _validateOrder(
    CardPurchaseOrderResponse? order, {
    required String walletAddress,
    required CardPurchaseType type,
    required BigInt expectedPayAmountMinor,
  }) {
    if (order == null || !order.hasChainPayload) {
      return ApiError.validation('Incomplete card purchase order payload');
    }
    final parts = order.payload!.split('|');
    if (parts.length != 7 ||
        parts[0] != 'card_purchase' ||
        parts[1] != walletAddress ||
        parts[2] != type.apiValue ||
        parts[3].toUpperCase() != 'USDC' ||
        parts[4] != expectedPayAmountMinor.toString() ||
        parts[5] != order.orderNo ||
        parts[6] != order.expiresAt) {
      return ApiError.validation('Card purchase order does not match request');
    }
    final expiresAt = int.tryParse(parts[6]);
    if (expiresAt == null ||
        expiresAt <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
      return ApiError.validation('Card purchase signature has expired');
    }
    return null;
  }
}

/// 优先读取当前 `miningItems`，兼容旧版 `consumableItems`。
String? resolveCardPurchaseUnitPrice(
  GlobalConfig? config,
  CardPurchaseType type,
) {
  final miningItemKey = switch (type) {
    CardPurchaseType.energyPack => 'STAMINA_PACK',
    CardPurchaseType.trainingManual => 'TRAINING_MANUAL',
  };
  final currentAmount = config?.init?.miningItems?[miningItemKey]?.price?.usdc
      ?.trim();
  if (currentAmount != null && currentAmount.isNotEmpty) return currentAmount;

  final legacyItemKeys = switch (type) {
    // Older configs named this item ENERGY_PACK even though the purchase API
    // and signed payload use STAMINA_PACK.
    CardPurchaseType.energyPack => const ['STAMINA_PACK', 'ENERGY_PACK'],
    CardPurchaseType.trainingManual => const ['TRAINING_MANUAL'],
  };
  for (final itemKey in legacyItemKeys) {
    final legacyItem = config?.init?.consumableItems?[itemKey];
    final currency = legacyItem?.price?.currency?.trim().toUpperCase();
    final amount = legacyItem?.price?.amount?.trim();
    if (currency == 'USDC' && amount?.isNotEmpty == true) return amount;
  }
  return null;
}

String _shortValue(String value) {
  if (value.length <= 16) return value;
  return '${value.substring(0, 6)}...${value.substring(value.length - 6)}';
}

String _errorSummary(ApiError error) => switch (error) {
  BusinessError(:final code, :final message) => 'code=$code message=$message',
  ValidationError(:final message) => 'message=$message',
  _ => 'error=${error.runtimeType} message=${error.userMessage}',
};
