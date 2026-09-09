import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/agent_v2_config_repository.dart';
import '../repositories/mining_repository.dart';
import '../repositories/reward_repository.dart';
import '../services/sponsor_service.dart';
import '../services/wallet_ledger.dart';
import 'game_state.dart';
import 'story_controller_mixin.dart';

/// 链上索引器同步检查 —— 与 web `ACTOR_STAMINA_SYNC_POLL_MAX_ATTEMPTS` 对齐
const _upgradePollMaxAttempts = 20;

/// 链上索引器同步检查 —— 与 web `ACTOR_STAMINA_SYNC_POLL_INTERVAL_MS` 对齐
const _upgradePollInterval = Duration(milliseconds: 2000);

MapEntry<String, ChainInfo>? _resolveSvmChainEntry(GlobalConfig? config) {
  final chainlinks = config?.chainlinks;
  if (chainlinks == null) return null;
  for (final entry in chainlinks.entries) {
    if (entry.value.chainType?.toLowerCase() == 'svm') return entry;
  }
  for (final entry in chainlinks.entries) {
    final name = '${entry.key} ${entry.value.name ?? ''}'.toLowerCase();
    if (name.contains('solana') || name.contains('svm')) return entry;
  }
  return null;
}

String? _resolveSponsorApiUrl(GlobalConfig? config, String? svmChainKey) {
  final deposits = config?.init?.deposit;
  if (deposits != null) {
    for (final deposit in deposits) {
      final api = deposit.api?.trim();
      if (api == null || api.isEmpty) continue;
      if (deposit.chain == svmChainKey || deposit.chainType == 'svm') {
        return api;
      }
    }
    for (final deposit in deposits) {
      final api = deposit.api?.trim();
      if (api != null && api.isNotEmpty) return api;
    }
  }
  return svmChainKey == null || svmChainKey.isEmpty
      ? null
      : '/api/nfp/v1/sponsor/$svmChainKey';
}

class GameController extends Notifier<GameState>
    with StoryControllerMixin<GameState> {
  /// Refill transactions are confirmed on-chain before the mining indexer
  /// reflects the new stamina. Keep the confirmed optimistic value while that
  /// eventually-consistent read model catches up.
  final Map<String, int> _pendingStaminaRefills = {};

  MiningRepository get _mining => ref.read(miningRepositoryProvider);
  RewardRepository get _reward => ref.read(rewardRepositoryProvider);
  AgentV2ConfigRepository get _config =>
      ref.read(agentV2ConfigRepositoryProvider);

  InitActorNftConfig? get _actorNftConfig => state.actorNftConfig;

  int _resolveStaminaLimit() => state.agentV2StaminaLimit ?? state.staminaLimit;

  double? supplyFeeForLevel(int? level) =>
      _actorNftConfig?.supplyFeeForLevel(level);

  /// 静默回源更新 V2 候场演员，并通知候场列表读取最新缓存。
  Future<void> refreshRestActorsSilently() async {
    await ref.read(agentV2CandidateActorsControllerProvider.notifier).refresh();
  }

  /// 演员升级是否已同步 —— 与 web `isActorUpgradeSynced` 对齐。
  bool _isActorUpgradeSynced(int? level, {int? toLevel}) {
    if (level == null || toLevel == null) return false;
    return level >= toLevel;
  }

  /// 升级提交后轮询链上索引器，直到演员等级提升或超时。
  /// 与 web `pollActorUpgradeSynced` 对齐（2s 间隔，最多 20 次）。
  Future<bool> _pollUpgradeSynced({
    required String actorNftId,
    int? toLevel,
  }) async {
    for (int attempt = 0; attempt < _upgradePollMaxAttempts; attempt++) {
      final result = await _mining.fetchAllActorsFromNetwork(
        sort: state.sort.apiValue,
        pageSize: gameMyActorsPageSize,
      );
      if (!ref.mounted) return false;

      if (result.isSuccess) {
        final actor = result.dataOrNull?.records
            .cast<MiningActor?>()
            .firstWhere((a) => a?.nftId == actorNftId, orElse: () => null);
        if (actor != null &&
            _isActorUpgradeSynced(actor.level, toLevel: toLevel)) {
          return true;
        }
      }

      if (attempt < _upgradePollMaxAttempts - 1) {
        await Future<void>.delayed(_upgradePollInterval);
        if (!ref.mounted) return false;
      }
    }
    return false;
  }

  RefillChainContext? _resolveRefillChainContext() {
    final config = state.agentV2Config;
    final chainEntry = _resolveSvmChainEntry(config);
    final chain = chainEntry?.value;
    final contracts = chain?.contracts;
    final rpc = chain?.rpc?.http;
    final sponsorUrl = _resolveSponsorApiUrl(config, chainEntry?.key);
    final spender = contracts?.spender;
    final storyProgram = contracts?.story;
    final delegator = contracts?.storyDelegator;
    final treasury = contracts?.storyTreasury;
    if ([
      rpc,
      sponsorUrl,
      spender,
      storyProgram,
      delegator,
      treasury,
    ].any((s) => s == null || s.isEmpty)) {
      return null;
    }
    return RefillChainContext(
      rpc: rpc!,
      sponsorUrl: sponsorUrl!,
      spender: spender!,
      storyProgram: storyProgram!,
      delegator: delegator!,
      treasury: treasury!,
    );
  }

  /// 升级订单不返回支付币种，使用经纪人配置中的 SVM USDC mint。
  String? _resolveUsdcMint() {
    final tokensMap = _resolveSvmChainEntry(state.agentV2Config)?.value.tokens;
    if (tokensMap == null) return null;
    for (final entry in tokensMap.entries) {
      if (entry.value.symbol?.toUpperCase() == 'USDC') {
        final addr = entry.value.address?.trim();
        if (addr != null && addr.isNotEmpty) return addr;
      }
    }
    return null;
  }

  @override
  GameState build() {
    return const GameState();
  }

  DateTime? _lastAgentV2ConfigNetworkAt;

  /// Loads the dedicated last-known-good cache before background calibration.
  void loadCachedAgentV2Config() {
    final cached = _config.readCachedConfig();
    if (cached != null) _applyAgentV2Config(cached);
  }

  /// Calibrates the scoped config from network; overlapping calls share one
  /// request via [requestCoalescerProvider] inside the repository.
  Future<void> refreshAgentV2Config() => _refreshAgentV2Config();

  Future<void> _refreshAgentV2Config() async {
    state = state.copyWith(
      isAgentV2ConfigLoading: true,
      clearAgentV2ConfigError: true,
    );

    final result = await _config.fetchLatestConfig();
    if (!ref.mounted) return;

    final config = result.dataOrNull;
    final actorConfig = config?.init?.actorNft;
    final staminaLimit = actorConfig?.staminaLimit;
    if (result.isSuccess &&
        config != null &&
        actorConfig != null &&
        staminaLimit != null &&
        staminaLimit > 0) {
      _lastAgentV2ConfigNetworkAt = DateTime.now();
      _applyAgentV2Config(config);
      return;
    }

    state = state.copyWith(
      isAgentV2ConfigLoading: false,
      agentV2ConfigError:
          result.errorOrNull ??
          ApiError.business(-1, 'Actor NFT config incomplete'),
    );
  }

  void _applyAgentV2Config(GlobalConfig config) {
    final staminaLimit = config.init?.actorNft?.staminaLimit;
    if (staminaLimit == null || staminaLimit <= 0) return;
    state = state.copyWith(
      agentV2Config: config,
      staminaLimit: staminaLimit,
      isAgentV2ConfigLoading: false,
      clearAgentV2ConfigError: true,
    );
  }

  /// Paid actions require a recent network calibration, not cache alone.
  Future<bool> _ensureRecentAgentV2Config() async {
    final last = _lastAgentV2ConfigNetworkAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 1)) {
      return state.agentV2Config != null;
    }
    await refreshAgentV2Config();
    return state.agentV2Config != null && _lastAgentV2ConfigNetworkAt != null;
  }

  @override
  GameState copyWithLoadingState({
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

  Future<void> refresh({bool force = false}) async {
    updateState(isLoading: true, lastError: null, clearLastError: true);
    if (!ref.mounted) return;

    try {
      if (force) {
        await Future.wait([
          _mining.invalidateGameCache(),
          _reward.invalidateWeeklyStatsCache(),
        ]);
      }

      final results = await Future.wait([
        _mining.listDeployedActors(),
        _mining.listAllActors(
          sort: state.sort.apiValue,
          pageSize: gameMyActorsPageSize,
        ),
        _reward.getWeeklyStats(),
      ]);

      final deployedResult = results[0] as Result<List<MiningActor>>;
      final actorsResult = results[1] as Result<MiningActorPage>;
      final weeklyResult = results[2] as Result<MiningWeeklyStats>;

      _applyRefreshResults(
        deployedResult: deployedResult,
        actorsResult: actorsResult,
        weeklyResult: weeklyResult,
        replaceMyActors: true,
      );
    } catch (e, st) {
      StoryLogger.e(
        'GameController.refresh failed: $e',
        error: e,
        stackTrace: st,
        tag: 'GameController.refresh',
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        lastError: ApiError.unknown(e.toString()),
      );
      return;
    }

    if (!ref.mounted) return;
    // Preserve any error set by _applyRefreshResults while clearing on success.
    state = state.copyWith(
      isLoading: false,
      clearLastError: state.lastError == null,
    );
  }

  /// 刷新 V2 挖矿槽位。
  ///
  /// V2 入口不依赖“我的演员”分页和周统计，使用聚焦刷新可避免无关请求失败
  /// 覆盖正在挖矿列表的加载状态。
  Future<void> refreshDeployedActors({
    bool force = false,
    bool silent = false,
    bool bypassCache = false,
  }) async {
    if (!ref.mounted) return;
    final mining = _mining;
    if (!silent) {
      updateState(isLoading: true, lastError: null, clearLastError: true);
    }

    try {
      if (force) {
        await mining.invalidateGameCache();
        if (!ref.mounted) return;
      }
      final deployedResult = bypassCache
          ? await mining.refreshDeployedActors()
          : await mining.listDeployedActors();
      if (!ref.mounted) return;

      if (deployedResult.isFailure) {
        if (!silent) {
          state = state.copyWith(
            isLoading: false,
            lastError: deployedResult.errorOrNull,
          );
        }
        return;
      }

      state = state.copyWith(
        isLoading: false,
        deployedActors: _applyPendingStamina(
          deployedResult.dataOrNull ?? const [],
        ),
        staminaLimit: _resolveStaminaLimit(),
        clearLastError: true,
      );
    } catch (e, st) {
      if (!ref.mounted) return;
      StoryLogger.e(
        'GameController.refreshDeployedActors failed: $e',
        error: e,
        stackTrace: st,
        tag: 'GameController.refreshDeployedActors',
      );
      if (!silent) {
        state = state.copyWith(
          isLoading: false,
          lastError: ApiError.unknown(e.toString()),
        );
      }
    }
  }

  /// 优先展示缓存，再静默回源更新 V2 挖矿数据。
  Future<void> loadDeployedActorsWithRevalidation() async {
    updateState(isLoading: true, lastError: null, clearLastError: true);
    final cached = await _mining.readCachedDeployedActors();
    if (!ref.mounted) return;
    if (cached == null) {
      await refreshDeployedActors();
      return;
    }

    state = state.copyWith(
      isLoading: false,
      deployedActors: _applyPendingStamina(cached),
      staminaLimit: _resolveStaminaLimit(),
      clearLastError: true,
    );
    await refreshDeployedActors(silent: true, bypassCache: true);
  }

  /// Fetches idle actors available for deployment.
  Future<Result<List<MiningActor>>> fetchRestActors() async {
    final result = await _mining.listRestActors();
    if (result.isFailure) {
      return Result.failure(result.errorOrNull!);
    }
    return Result.success(result.dataOrNull?.records ?? const []);
  }

  Future<void> setSort(GameActorSort sort) async {
    if (state.sort == sort) return;
    state = state.copyWith(
      sort: sort,
      myActors: const [],
      currentPage: 0,
      hasMore: false,
      isRefreshingList: true,
    );

    final result = await _mining.listAllActors(
      sort: state.sort.apiValue,
      pageSize: gameMyActorsPageSize,
    );

    if (!ref.mounted) return;

    if (result.isFailure) {
      state = state.copyWith(
        isRefreshingList: false,
        lastError: result.errorOrNull,
      );
      return;
    }

    final page = result.dataOrNull ?? const MiningActorPage();
    state = state.copyWith(
      isRefreshingList: false,
      myActors: page.records,
      totalActorCount: page.totalRow,
      currentPage: page.pageNumber,
      hasMore: page.hasMore,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true, clearLastError: true);
    final nextPage = state.currentPage + 1;

    final result = await _mining.listAllActors(
      sort: state.sort.apiValue,
      pageNum: nextPage,
      pageSize: gameMyActorsPageSize,
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
      isLoadingMore: false,
      myActors: mergeMiningActors(state.myActors, page.records),
      currentPage: page.pageNumber,
      hasMore: page.hasMore,
      totalActorCount: page.totalRow,
    );
  }

  Future<bool> deploy(String actorNftId) async {
    if (!state.canDeployMore) return false;

    state = state.copyWith(isActionLoading: true, clearLastError: true);
    final result = await _mining.deployActor(actorNftId);
    if (!ref.mounted) return false;

    if (result.isFailure) {
      state = state.copyWith(
        isActionLoading: false,
        lastError: result.errorOrNull,
      );
      return false;
    }

    state = state.copyWith(isActionLoading: false);
    await refresh(force: true);
    return true;
  }

  /// 一键派遣全部可派遣演员，并返回本次成功演出的演员数。
  ///
  /// `null` 表示请求失败；`0` 表示请求成功，但候场演员均因体力耗尽未演出。
  Future<int?> deployAllActors() async {
    if (state.isActionLoading) return null;

    state = state.copyWith(isActionLoading: true, clearLastError: true);
    final result = await _mining.deployAllActors();
    if (!ref.mounted) return null;

    final actionError = result.errorOrNull;
    if (result.isSuccess) {
      await refreshRestActorsSilently();
    }
    await refreshDeployedActors(
      silent: result.isFailure,
      bypassCache: result.isFailure,
    );
    if (!ref.mounted) return null;

    if (actionError != null) {
      state = state.copyWith(isActionLoading: false, lastError: actionError);
      return null;
    }

    state = state.copyWith(isActionLoading: false);
    return result.dataOrNull?.length ?? 0;
  }

  Future<bool> rest(String actorNftId) async {
    state = state.copyWith(isActionLoading: true, clearLastError: true);
    final result = await _mining.restActor(actorNftId);
    if (!ref.mounted) return false;

    if (result.isFailure) {
      state = state.copyWith(
        isActionLoading: false,
        lastError: result.errorOrNull,
      );
      return false;
    }

    state = state.copyWith(isActionLoading: false);
    await refresh(force: true);
    ref
        .read(agentV2CandidateActorsControllerProvider.notifier)
        .allowActorToReturn(actorNftId);
    await refreshRestActorsSilently();
    return true;
  }

  Future<bool> restAllActors() async {
    if (state.isActionLoading || state.deployedActors.isEmpty) return false;

    state = state.copyWith(isActionLoading: true, clearLastError: true);
    final result = await _mining.restAllActors();
    if (!ref.mounted) return false;

    if (result.isFailure) {
      state = state.copyWith(
        isActionLoading: false,
        lastError: result.errorOrNull,
      );
      return false;
    }

    await refreshDeployedActors(force: true);
    if (!ref.mounted) return false;

    state = state.copyWith(isActionLoading: false);
    ref
        .read(agentV2CandidateActorsControllerProvider.notifier)
        .allowAllActorsToReturn();
    await refreshRestActorsSilently();
    return true;
  }

  void _applyRefreshResults({
    required Result<List<MiningActor>> deployedResult,
    required Result<MiningActorPage> actorsResult,
    required Result<MiningWeeklyStats> weeklyResult,
    required bool replaceMyActors,
  }) {
    final deployed = deployedResult.isSuccess
        ? (deployedResult.dataOrNull ?? [])
        : state.deployedActors;

    MiningActorPage? page;
    if (actorsResult.isSuccess) {
      page = actorsResult.dataOrNull;
    }

    final myActors = page != null
        ? (replaceMyActors
              ? page.records
              : mergeMiningActors(state.myActors, page.records))
        : state.myActors;

    final weeklyStats = weeklyResult.isSuccess
        ? weeklyResult.dataOrNull
        : state.weeklyStats;

    ApiError? error;
    if (deployedResult.isFailure &&
        actorsResult.isFailure &&
        weeklyResult.isFailure) {
      error =
          deployedResult.errorOrNull ??
          actorsResult.errorOrNull ??
          weeklyResult.errorOrNull;
    } else if (deployedResult.isFailure && actorsResult.isFailure) {
      error = deployedResult.errorOrNull ?? actorsResult.errorOrNull;
    } else if (deployedResult.isFailure) {
      error = deployedResult.errorOrNull;
    } else if (actorsResult.isFailure) {
      error = actorsResult.errorOrNull;
    } else if (weeklyResult.isFailure) {
      error = weeklyResult.errorOrNull;
    }

    if (!ref.mounted) return;
    state = state.copyWith(
      deployedActors: _applyPendingStamina(deployed),
      myActors: _applyPendingStamina(myActors),
      totalActorCount: page?.totalRow ?? myActors.length,
      currentPage: page?.pageNumber ?? state.currentPage,
      hasMore: page?.hasMore ?? false,
      weeklyStats: weeklyStats,
      staminaLimit: _resolveStaminaLimit(),
      lastError: error,
      clearLastError: error == null,
    );
  }

  List<MiningActor> _applyPendingStamina(List<MiningActor> actors) {
    if (_pendingStaminaRefills.isEmpty) return actors;
    return actors.map((actor) {
      final pendingStamina = _pendingStaminaRefills[actor.nftId];
      if (pendingStamina == null || (actor.stamina ?? 0) >= pendingStamina) {
        return actor;
      }
      return actor.copyWith(stamina: pendingStamina);
    }).toList();
  }

  MiningActor? _findActor(Iterable<MiningActor> actors, String actorNftId) {
    for (final actor in actors) {
      if (actor.nftId == actorNftId) return actor;
    }
    return null;
  }

  void _markStaminaRefilled(Set<String> actorNftIds, int staminaLimit) {
    for (final actorNftId in actorNftIds) {
      _pendingStaminaRefills[actorNftId] = staminaLimit;
    }

    List<MiningActor> updateActors(List<MiningActor> actors) => actors
        .map(
          (actor) => actorNftIds.contains(actor.nftId)
              ? actor.copyWith(stamina: staminaLimit)
              : actor,
        )
        .toList();

    state = state.copyWith(
      myActors: updateActors(state.myActors),
      deployedActors: updateActors(state.deployedActors),
      isActionLoading: false,
    );
  }

  /// Polls without blocking the success UI. Stale indexer responses are never
  /// allowed to replace the on-chain-confirmed optimistic stamina, and are
  /// evicted again so an auto-disposed/recreated controller cannot read them.
  Future<void> _pollRefilledStaminaSynced({
    required String actorNftId,
    required int staminaLimit,
  }) async {
    try {
      for (var attempt = 0; attempt < _upgradePollMaxAttempts; attempt++) {
        await Future<void>.delayed(_upgradePollInterval);
        if (!ref.mounted) return;

        await _mining.invalidateGameCache();
        final results = await Future.wait([
          _mining.listDeployedActors(),
          _mining.listAllActors(
            sort: state.sort.apiValue,
            pageSize: gameMyActorsPageSize,
          ),
        ]);
        if (!ref.mounted) return;

        final deployedResult = results[0] as Result<List<MiningActor>>;
        final actorsResult = results[1] as Result<MiningActorPage>;
        final fetchedDeployed = deployedResult.dataOrNull;
        final fetchedPage = actorsResult.dataOrNull;
        final deployedActor = fetchedDeployed == null
            ? null
            : _findActor(fetchedDeployed, actorNftId);
        final listedActor = fetchedPage == null
            ? null
            : _findActor(fetchedPage.records, actorNftId);

        final deployedSynced =
            deployedResult.isSuccess &&
            deployedActor != null &&
            (deployedActor.stamina ?? 0) >= staminaLimit;
        final listedSynced =
            actorsResult.isSuccess &&
            (listedActor == null || (listedActor.stamina ?? 0) >= staminaLimit);
        final isSynced = deployedSynced && listedSynced;

        if (isSynced) {
          _pendingStaminaRefills.remove(actorNftId);
        }

        state = state.copyWith(
          deployedActors: fetchedDeployed == null
              ? state.deployedActors
              : _applyPendingStamina(fetchedDeployed),
          myActors: fetchedPage == null
              ? state.myActors
              : _applyPendingStamina(fetchedPage.records),
          totalActorCount: fetchedPage?.totalRow ?? state.totalActorCount,
          currentPage: fetchedPage?.pageNumber ?? state.currentPage,
          hasMore: fetchedPage?.hasMore ?? state.hasMore,
        );

        if (isSynced) return;

        // Both cache layers have just received a stale indexer response.
        await _mining.invalidateGameCache();
        if (!ref.mounted) return;
      }
    } catch (error, stackTrace) {
      StoryLogger.w(
        'Refill stamina sync polling failed for $actorNftId: $error',
        tag: 'GameController.replenishStamina',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> replenishStamina(MiningActor actor, {double? payAmount}) async {
    final walletAddress = ref.read(authControllerProvider).solanaAddress;
    if (walletAddress.isEmpty || actor.nftId.isEmpty) return false;

    if (!await _ensureRecentAgentV2Config()) {
      state = state.copyWith(
        lastError:
            state.agentV2ConfigError ??
            ApiError.business(-1, 'Actor config unavailable'),
      );
      return false;
    }
    final resolvedPayAmount = payAmount ?? supplyFeeForLevel(actor.level);
    if (resolvedPayAmount == null) return false;

    final chainContext = _resolveRefillChainContext();
    if (chainContext == null) {
      state = state.copyWith(
        lastError: ApiError.business(-1, 'Chain config incomplete'),
      );
      return false;
    }

    state = state.copyWith(isActionLoading: true, clearLastError: true);

    final orderResult = await _mining.replenishStamina(
      actorNftId: actor.nftId,
      payAmount: resolvedPayAmount,
      walletAddress: walletAddress,
    );
    if (!ref.mounted) return false;

    if (orderResult.isFailure) {
      state = state.copyWith(
        isActionLoading: false,
        lastError: orderResult.errorOrNull,
      );
      return false;
    }

    final order = orderResult.dataOrNull;
    if (order == null || !order.hasChainPayload) {
      state = state.copyWith(
        isActionLoading: false,
        lastError: ApiError.business(-1, 'Incomplete replenish payload'),
      );
      return false;
    }

    // Prefer order.cost when present so local deduct matches chain charge.
    final charge = order.cost ?? resolvedPayAmount;
    final ledger = ref.read(walletLedgerProvider);
    final prepared = await ledger.prepareSpend(
      SpendQuote(
        asset: SpendAsset.usdc,
        amount: charge,
        reason: 'refill_stamina',
      ),
    );
    if (!ref.mounted) return false;
    if (prepared.isFailure) {
      state = state.copyWith(
        isActionLoading: false,
        lastError: prepared.errorOrNull,
      );
      return false;
    }
    final spendTicket = prepared.dataOrNull!;

    final sponsor = ref.read(sponsorServiceProvider);
    final sponsorResult = await sponsor.submitSponsorRefillActorStamina(
      SponsorRefillActorStaminaParams(
        userSolanaAddress: walletAddress,
        actorNftId: actor.nftId,
        actorCollectionId: actor.actorCollectionId,
        actorTokenId: actor.actorTokenId,
        orderNo: order.orderNo!,
        canonicalPayload: order.canonicalPayload!,
        sigBase64: order.sig!,
        payTokenMint: order.payToken!,
        rpcHttpUrl: chainContext.rpc,
        storyProgramAddress: chainContext.storyProgram,
        delegatorAddress: chainContext.delegator,
        treasuryAddress: chainContext.treasury,
        spenderAddress: chainContext.spender,
        sponsorApiUrl: chainContext.sponsorUrl,
      ),
    );
    if (!ref.mounted) {
      if (spendTicket.didDeduct) {
        await ledger.reconcile(spendTicket);
      }
      return false;
    }

    if (sponsorResult.isFailure) {
      if (spendTicket.didDeduct) {
        await ledger.reconcile(spendTicket);
      }
      state = state.copyWith(
        isActionLoading: false,
        lastError: sponsorResult.errorOrNull,
      );
      return false;
    }

    // The sponsor transaction has succeeded on-chain. Protect this optimistic
    // value until the eventually-consistent mining indexer reports the same
    // stamina, otherwise an immediate refresh would visibly revert it.
    final limit = state.staminaLimit;
    _markStaminaRefilled({actor.nftId}, limit);

    unawaited(
      _pollRefilledStaminaSynced(actorNftId: actor.nftId, staminaLimit: limit),
    );
    return true;
  }

  Future<bool> replenishStaminaBatch(
    List<ActorNeedingStaminaRefill> actors,
  ) async {
    final walletAddress = ref.read(authControllerProvider).solanaAddress;
    final requestedActors = <String, ActorNeedingStaminaRefill>{
      for (final actor in actors)
        if (actor.actorNftId.isNotEmpty) actor.actorNftId: actor,
    };
    if (walletAddress.isEmpty ||
        requestedActors.isEmpty ||
        requestedActors.length > gameDeploySlotCount) {
      state = state.copyWith(
        lastError: ApiError.validation('Invalid batch refill actors'),
      );
      return false;
    }

    if (!await _ensureRecentAgentV2Config()) {
      state = state.copyWith(
        lastError:
            state.agentV2ConfigError ??
            ApiError.business(-1, 'Actor config unavailable'),
      );
      return false;
    }

    final chainContext = _resolveRefillChainContext();
    if (chainContext == null) {
      state = state.copyWith(
        lastError: ApiError.business(-1, 'Chain config incomplete'),
      );
      return false;
    }

    state = state.copyWith(isActionLoading: true, clearLastError: true);

    final orderResult = await _mining.replenishStaminaBatch(
      ReplenishStaminaBatchRequest(
        walletAddress: walletAddress,
        items: requestedActors.values
            .map(
              (actor) => ReplenishStaminaBatchItem(
                actorNftId: actor.actorNftId,
                payAmount: actor.supplyFee,
              ),
            )
            .toList(growable: false),
      ),
    );
    if (!ref.mounted) return false;

    if (orderResult.isFailure) {
      state = state.copyWith(
        isActionLoading: false,
        lastError: orderResult.errorOrNull,
      );
      return false;
    }

    final batch = orderResult.dataOrNull;
    final orders = batch?.items ?? const <ReplenishResult>[];
    final actorAssetIds = orders
        .map((order) => order.actorNftId?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final hasCompleteBatch =
        batch != null &&
        batch.hasChainPayload &&
        orders.length == requestedActors.length &&
        actorAssetIds.length == requestedActors.length &&
        actorAssetIds.toSet().length == requestedActors.length;
    if (!hasCompleteBatch) {
      state = state.copyWith(
        isActionLoading: false,
        lastError: ApiError.business(-1, 'Incomplete batch replenish payload'),
      );
      return false;
    }

    final charge =
        batch.totalCost ??
        requestedActors.values.fold<double>(
          0,
          (sum, actor) => sum + actor.supplyFee,
        );
    final ledger = ref.read(walletLedgerProvider);
    final prepared = await ledger.prepareSpend(
      SpendQuote(
        asset: SpendAsset.usdc,
        amount: charge,
        reason: 'refill_stamina_batch',
      ),
    );
    if (!ref.mounted) return false;
    if (prepared.isFailure) {
      state = state.copyWith(
        isActionLoading: false,
        lastError: prepared.errorOrNull,
      );
      return false;
    }
    final spendTicket = prepared.dataOrNull!;
    final sponsor = ref.read(sponsorServiceProvider);
    final sponsorResult = await sponsor.submitSponsorBatchRefillActorStamina(
      SponsorBatchRefillActorStaminaParams(
        userSolanaAddress: walletAddress,
        actorAssetIds: actorAssetIds,
        orderNo: batch.orderNo!,
        canonicalPayload: batch.canonicalPayload!,
        sigBase64: batch.sig!,
        payTokenMint: batch.payToken!,
        rpcHttpUrl: chainContext.rpc,
        storyProgramAddress: chainContext.storyProgram,
        delegatorAddress: chainContext.delegator,
        treasuryAddress: chainContext.treasury,
        spenderAddress: chainContext.spender,
        sponsorApiUrl: chainContext.sponsorUrl,
      ),
    );
    if (!ref.mounted) {
      if (spendTicket.didDeduct) await ledger.reconcile(spendTicket);
      return false;
    }
    if (sponsorResult.isFailure) {
      if (spendTicket.didDeduct) await ledger.reconcile(spendTicket);
      state = state.copyWith(
        isActionLoading: false,
        lastError: sponsorResult.errorOrNull,
      );
      return false;
    }

    final limit = state.staminaLimit;
    _markStaminaRefilled(requestedActors.keys.toSet(), limit);
    for (final actorNftId in requestedActors.keys) {
      unawaited(
        _pollRefilledStaminaSynced(actorNftId: actorNftId, staminaLimit: limit),
      );
    }
    return true;
  }

  /// 获取演员升级可用耗材列表（同IP同等级待消耗演员）。
  Future<List<ActorUpgradeMaterial>> getUpgradeMaterials(
    String actorNftId,
  ) async {
    StoryLogger.d(
      'getUpgradeMaterials start: actorNftId=$actorNftId',
      tag: 'GameController.getUpgradeMaterials',
    );
    final result = await _mining.getUpgradeMaterials(actorNftId: actorNftId);
    if (result.isFailure) {
      StoryLogger.w(
        'getUpgradeMaterials failed: actorNftId=$actorNftId, '
        'error=${result.errorOrNull}',
        tag: 'GameController.getUpgradeMaterials',
        error: result.errorOrNull,
      );
      if (!ref.mounted) return [];
      state = state.copyWith(lastError: result.errorOrNull);
      return [];
    }
    final materials = result.dataOrNull ?? [];
    final itemsDetail = materials.isEmpty
        ? ''
        : materials
              .map(
                (m) =>
                    '{actorId=${m.actorId}, level=${m.level}, name=${m.actorName}}',
              )
              .join('; ');
    StoryLogger.d(
      'getUpgradeMaterials success: actorNftId=$actorNftId, '
      'count=${materials.length}, items=[$itemsDetail]',
      tag: 'GameController.getUpgradeMaterials',
    );
    return materials;
  }

  /// 升级演员 NFT
  Future<bool> upgradeActor({
    required int actorCollectionId,
    required int mainNftTokenId,
    required List<int> burnNftTokenIds,
    required String actorNftId,
    int? toLevel,
  }) async {
    final walletAddress = ref.read(authControllerProvider).solanaAddress;
    if (walletAddress.isEmpty) return false;

    if (!await _ensureRecentAgentV2Config()) {
      state = state.copyWith(
        lastError:
            state.agentV2ConfigError ??
            ApiError.business(-1, 'Actor config unavailable'),
      );
      return false;
    }

    final chainContext = _resolveRefillChainContext();
    if (chainContext == null) {
      StoryLogger.w(
        'upgradeActor abort: chain config incomplete',
        tag: 'GameController.upgradeActor',
      );
      state = state.copyWith(
        lastError: ApiError.business(-1, 'Chain config incomplete'),
      );
      return false;
    }

    state = state.copyWith(isActionLoading: true, clearLastError: true);

    final orderResult = await _mining.createUpgradeOrder(
      actorCollectionId: actorCollectionId,
      walletAddress: walletAddress,
      mainNftTokenId: mainNftTokenId,
      burnNftTokenIds: burnNftTokenIds,
    );
    if (!ref.mounted) return false;

    if (orderResult.isFailure) {
      StoryLogger.w(
        'upgradeActor abort: createUpgradeOrder failed -> '
        '${orderResult.errorOrNull}',
        tag: 'GameController.upgradeActor',
      );
      state = state.copyWith(
        isActionLoading: false,
        lastError: orderResult.errorOrNull,
      );
      return false;
    }

    final order = orderResult.dataOrNull;
    final hasSig = order?.sig?.trim().isNotEmpty ?? false;
    final hasPayload = order?.payload?.trim().isNotEmpty ?? false;
    if (order == null || !hasSig || !hasPayload) {
      StoryLogger.w(
        'upgradeActor abort: incomplete upgrade order payload '
        '(sig=$hasSig, payload=$hasPayload)',
        tag: 'GameController.upgradeActor',
      );
      state = state.copyWith(
        isActionLoading: false,
        lastError: ApiError.business(-1, 'Incomplete upgrade order payload'),
      );
      return false;
    }

    // 升级订单接口不返回 payToken，从链上配置解析 USDC mint 作为支付代币。
    final payTokenMint = order.payToken?.trim().isNotEmpty == true
        ? order.payToken!.trim()
        : _resolveUsdcMint();
    if (payTokenMint == null || payTokenMint.isEmpty) {
      StoryLogger.w(
        'upgradeActor abort: cannot resolve pay token mint '
        '(order.payToken=${order.payToken}, config USDC missing)',
        tag: 'GameController.upgradeActor',
      );
      state = state.copyWith(
        isActionLoading: false,
        lastError: ApiError.business(-1, 'Pay token mint unavailable'),
      );
      return false;
    }

    final sponsor = ref.read(sponsorServiceProvider);
    final sponsorResult = await sponsor.submitSponsorUpgradeActorNft(
      SponsorUpgradeActorNftParams(
        userSolanaAddress: walletAddress,
        actorCollectionId: actorCollectionId,
        mainNftTokenId: mainNftTokenId,
        burnNftTokenIds: burnNftTokenIds,
        canonicalPayload: order.payload!,
        sigBase64: order.sig!,
        payTokenMint: payTokenMint,
        rpcHttpUrl: chainContext.rpc,
        storyProgramAddress: chainContext.storyProgram,
        delegatorAddress: chainContext.delegator,
        treasuryAddress: chainContext.treasury,
        spenderAddress: chainContext.spender,
        sponsorApiUrl: chainContext.sponsorUrl,
      ),
    );
    if (!ref.mounted) return false;

    if (sponsorResult.isFailure) {
      StoryLogger.w(
        'upgradeActor abort: sponsor tx failed -> ${sponsorResult.errorOrNull}',
        tag: 'GameController.upgradeActor',
      );
      state = state.copyWith(
        isActionLoading: false,
        lastError: sponsorResult.errorOrNull,
      );
      return false;
    }

    // 轮询链上索引器直到等级变更，与 web `pollActorUpgradeSynced` 对齐
    await _pollUpgradeSynced(actorNftId: actorNftId, toLevel: toLevel);

    state = state.copyWith(isActionLoading: false);

    if (!ref.mounted) return false;

    await refresh(force: true);
    await refreshRestActorsSilently();

    // 超时不影响 status——订单已提交成功
    return true;
  }
}
