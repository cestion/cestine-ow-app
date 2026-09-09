import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/mining_repository.dart';
import 'agent_v2_upgradeable_actors_state.dart';
import 'game_state.dart';

const int agentV2UpgradeableActorsPageSize = 20;

/// 经纪人 V2 可升级角色的唯一数据源。
///
/// 顶栏消费专用的可升级数量，「升级角色」bottom sheet 消费排除
/// 满级角色后的分页列表。
class AgentV2UpgradeableActorsController
    extends Notifier<AgentV2UpgradeableActorsState> {
  MiningRepository get _repository => ref.read(miningRepositoryProvider);
  bool _isFirstPageLoadInFlight = false;
  bool _isRefreshQueued = false;

  @override
  AgentV2UpgradeableActorsState build() {
    _resetOnAuthSessionChange();
    return const AgentV2UpgradeableActorsState();
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

  Future<void> loadInitial() async {
    if (state.isInitialized || _isFirstPageLoadInFlight) return;

    _isFirstPageLoadInFlight = true;
    state = const AgentV2UpgradeableActorsState(isLoading: true);
    var hasCachedPage = false;
    try {
      final cachedPage = await _repository.readCachedAllActors(
        sort: GameActorSort.computingPower.apiValue,
        pageSize: agentV2UpgradeableActorsPageSize,
        excludeMaxLevel: true,
      );
      if (!ref.mounted) return;

      if (cachedPage != null) {
        hasCachedPage = true;
        _setInitialPage(cachedPage);
      }

      final results = await Future.wait([
        _repository.refreshAllActors(
          sort: GameActorSort.computingPower.apiValue,
          pageSize: agentV2UpgradeableActorsPageSize,
          excludeMaxLevel: true,
        ),
        _repository.getUpgradeableActorCount(),
      ]);
      if (!ref.mounted) return;

      final listResult = results[0] as Result<MiningActorPage>;
      final countResult = results[1] as Result<int>;
      final upgradeableCount = countResult.dataOrNull;

      if (listResult.isFailure) {
        if (!hasCachedPage) {
          state = state.copyWith(
            isInitialized: true,
            isLoading: false,
            hasMore: false,
            upgradeableCount: upgradeableCount,
            lastError: listResult.errorOrNull,
          );
        } else if (upgradeableCount != null) {
          state = state.copyWith(upgradeableCount: upgradeableCount);
        }
        return;
      }

      _setInitialPage(
        listResult.dataOrNull ?? const MiningActorPage(),
        upgradeableCount: upgradeableCount,
      );
    } finally {
      _isFirstPageLoadInFlight = false;
      _runQueuedRefresh();
    }
  }

  /// 保留当前列表并强制回源首页。
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
      final results = await Future.wait([
        _repository.refreshAllActors(
          sort: GameActorSort.computingPower.apiValue,
          pageSize: agentV2UpgradeableActorsPageSize,
          excludeMaxLevel: true,
        ),
        _repository.getUpgradeableActorCount(),
      ]);
      if (!ref.mounted) return;

      final listResult = results[0] as Result<MiningActorPage>;
      final countResult = results[1] as Result<int>;
      final upgradeableCount = countResult.dataOrNull;

      if (listResult.isFailure) {
        state = state.copyWith(
          isInitialized: true,
          isLoading: false,
          isRefreshing: false,
          hasMore: state.isInitialized ? state.hasMore : false,
          upgradeableCount: upgradeableCount,
          lastError: listResult.errorOrNull,
        );
        return;
      }

      _setInitialPage(
        listResult.dataOrNull ?? const MiningActorPage(),
        upgradeableCount: upgradeableCount,
      );
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

  /// 升级成功后丢弃游戏演员缓存并重新回源第一页。
  ///
  /// 升级会改变主演员等级并消耗材料演员，旧分页中的两类数据都不能继续复用。
  Future<void> refreshAfterUpgrade() async {
    await _repository.invalidateGameCache();
    if (!ref.mounted) return;
    await refresh();
  }

  void _setInitialPage(MiningActorPage page, {int? upgradeableCount}) {
    state = state.copyWith(
      actors: page.records,
      isInitialized: true,
      isLoading: false,
      isRefreshing: false,
      currentPage: page.pageNumber,
      totalCount: page.totalRow,
      upgradeableCount: upgradeableCount,
      hasMore: page.hasMore,
      clearLastError: true,
    );
  }

  /// 静默刷新单个升级角色，不触碰分页缓存与列表中的其他项。
  ///
  /// 角色合集详情提供最新完播数；升级材料接口提供当前可用的同 IP、同等级
  /// 角色数。两个请求互不依赖，任一失败时保留对应字段的内存值。
  Future<void> refreshActor(MiningActor actor) async {
    final actorCollectionId = actor.actorCollectionId;
    final actorNftId = actor.nftId;
    if (actorCollectionId == null && actorNftId.isEmpty) return;

    final detailFuture = actorCollectionId == null
        ? Future<Result<ActorCollection>?>.value()
        : ref
              .read(actorRepositoryProvider)
              .getActorCollectionDetailFromNetwork('$actorCollectionId');
    final materialsFuture = actorNftId.isEmpty
        ? Future<Result<List<ActorUpgradeMaterial>>?>.value()
        : _repository.getUpgradeMaterials(actorNftId: actorNftId);

    final results = await Future.wait<Object?>([
      detailFuture,
      materialsFuture,
      _repository.getUpgradeableActorCount(),
    ]);
    final detailResult = results[0] as Result<ActorCollection>?;
    final materialsResult = results[1] as Result<List<ActorUpgradeMaterial>>?;
    final countResult = results[2] as Result<int>;
    if (!ref.mounted) return;

    final completedPlayCount = detailResult?.dataOrNull?.completedViewCountInt;
    final materialCount = materialsResult?.dataOrNull?.length;
    final upgradeableCount = countResult.dataOrNull;
    if (completedPlayCount == null &&
        materialCount == null &&
        upgradeableCount == null) {
      return;
    }

    final index = state.actors.indexWhere(
      (candidate) => _isSameActor(candidate, actor),
    );
    if (index < 0) {
      if (upgradeableCount != null) {
        state = state.copyWith(upgradeableCount: upgradeableCount);
      }
      return;
    }

    final current = state.actors[index];
    final completionThreshold = ref
        .read(globalConfigProvider)
        .whenOrNull(
          data: (result) => result
              .dataOrNull
              ?.init
              ?.actorNft
              ?.levels?['${current.level}']
              ?.upgrade
              ?.heatThreshold,
        );
    final completePlayThresholdMet = completedPlayCount == null
        ? current.completePlayThresholdMet
        : completionThreshold == null
        ? current.completePlayThresholdMet
        : completionThreshold <= 0 || completedPlayCount >= completionThreshold;
    final actors = [...state.actors];
    actors[index] = current.copyWith(
      completedPlayCount: completedPlayCount,
      materialCount: materialCount,
      completePlayThresholdMet: completePlayThresholdMet,
    );
    state = state.copyWith(actors: actors, upgradeableCount: upgradeableCount);
  }

  bool _isSameActor(MiningActor candidate, MiningActor target) {
    if (target.nftId.isNotEmpty) return candidate.nftId == target.nftId;
    return target.actorTokenId != null &&
        candidate.actorTokenId == target.actorTokenId;
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
      pageSize: agentV2UpgradeableActorsPageSize,
      excludeMaxLevel: true,
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
      actors: mergeMiningActors(state.actors, page.records),
      isLoadingMore: false,
      currentPage: page.pageNumber,
      totalCount: page.totalRow,
      hasMore: page.hasMore,
      clearLastError: true,
    );
  }
}
