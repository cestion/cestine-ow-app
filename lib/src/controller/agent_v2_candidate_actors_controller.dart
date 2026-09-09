import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/mining_repository.dart';
import 'agent_v2_candidate_actors_state.dart';
import 'game_state.dart';

const int agentV2CandidateActorsPageSize = 20;

/// 经纪人 V2 候场演员的唯一数据源。
///
/// 底部候场条取前 5 条，候场弹窗消费完整分页列表；派遣和补充
/// 体力的乐观更新也在这里统一应用。
class AgentV2CandidateActorsController
    extends Notifier<AgentV2CandidateActorsState> {
  MiningRepository get _repository => ref.read(miningRepositoryProvider);
  bool _isFirstPageLoadInFlight = false;
  bool _isRefreshQueued = false;
  final Map<String, int> _pendingStaminaRefills = {};
  final Set<String> _optimisticallyRemovedActors = {};

  @override
  AgentV2CandidateActorsState build() {
    _resetOnAuthSessionChange();
    return const AgentV2CandidateActorsState();
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
    state = const AgentV2CandidateActorsState(isLoading: true);

    var hasCachedPage = false;
    try {
      final cachedPage = await _repository.readCachedRestActors(
        pageSize: agentV2CandidateActorsPageSize,
      );
      if (!ref.mounted) return;

      if (cachedPage != null) {
        hasCachedPage = true;
        _setInitialPage(cachedPage);
      }

      final result = await _repository.refreshRestActors(
        pageSize: agentV2CandidateActorsPageSize,
      );
      if (!ref.mounted) return;

      if (result.isFailure) {
        if (!hasCachedPage) {
          state = state.copyWith(
            isInitialized: true,
            isLoading: false,
            hasMore: false,
            lastError: result.errorOrNull,
          );
        }
        return;
      }

      _setInitialPage(result.dataOrNull ?? const MiningActorPage());
    } finally {
      _isFirstPageLoadInFlight = false;
      _runQueuedRefresh();
    }
  }

  /// 保留当前内容并强制回源第一页。
  ///
  /// 候场弹窗打开、App 回到前台及跨端库存变化都走这个入口，
  /// 避免清空底部候场条造成闪烁。
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
      final result = await _repository.refreshRestActors(
        pageSize: agentV2CandidateActorsPageSize,
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

  /// 合并加载期间到达的生命周期/Tab/签约刷新，只追加一次网络校准。
  void _runQueuedRefresh() {
    if (!_isRefreshQueued || !ref.mounted) return;
    _isRefreshQueued = false;
    unawaited(refresh());
  }

  void _setInitialPage(MiningActorPage page) {
    _reconcilePendingStaminaRefills(page.records);
    state = state.copyWith(
      actors: _applyOptimisticChanges(page.records),
      isInitialized: true,
      isLoading: false,
      isRefreshing: false,
      currentPage: page.pageNumber,
      totalCount: page.totalRow,
      hasMore: page.hasMore,
      clearLastError: true,
    );
  }

  List<MiningActor> _applyOptimisticChanges(List<MiningActor> actors) => actors
      .where((actor) => !_optimisticallyRemovedActors.contains(actor.nftId))
      .map((actor) {
        final stamina = _pendingStaminaRefills[actor.nftId];
        return stamina == null ? actor : actor.copyWith(stamina: stamina);
      })
      .toList(growable: false);

  void _reconcilePendingStaminaRefills(List<MiningActor> actors) {
    for (final actor in actors) {
      final pending = _pendingStaminaRefills[actor.nftId];
      if (pending != null && actor.stamina == pending) {
        _pendingStaminaRefills.remove(actor.nftId);
      }
    }
  }

  Future<void> loadMore() async {
    if (_isFirstPageLoadInFlight ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearLastError: true);
    final result = await _repository.listRestActors(
      pageNum: state.currentPage + 1,
      pageSize: agentV2CandidateActorsPageSize,
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
        _applyOptimisticChanges(page.records),
      ),
      isLoadingMore: false,
      currentPage: page.pageNumber,
      totalCount: page.totalRow,
      hasMore: page.hasMore,
      clearLastError: true,
    );
  }

  /// 将补充体力的链上成功结果同步到共享候场列表。
  ///
  /// 补充操作由 [GameController] 执行；这里做乐观同步，避免索引服务尚未
  /// 更新时底部条和弹窗仍显示旧体力。
  void markStaminaRefilled(String actorNftId, int staminaLimit) {
    if (actorNftId.isEmpty || staminaLimit <= 0) return;

    _pendingStaminaRefills[actorNftId] = staminaLimit;
    var didUpdate = false;
    final actors = state.actors
        .map((actor) {
          if (actor.nftId != actorNftId || actor.stamina == staminaLimit) {
            return actor;
          }
          didUpdate = true;
          return actor.copyWith(stamina: staminaLimit);
        })
        .toList(growable: false);

    if (didUpdate) state = state.copyWith(actors: actors);
  }

  /// 安排指定角色演出。
  ///
  /// 候选列表负责本次交互的提交状态和乐观移除；主页面派遣槽位通过聚焦
  /// 刷新同步。弹窗只触发本方法并渲染状态，不直接接触仓储或 API。
  Future<bool> schedulePerformance(String actorNftId) async {
    if (actorNftId.isEmpty || state.submittingActorNftId != null) return false;

    state = state.copyWith(
      submittingActorNftId: actorNftId,
      clearActionError: true,
    );
    final result = await _repository.deployActor(actorNftId);
    if (!ref.mounted) return false;

    if (result.isFailure) {
      final actionError = result.errorOrNull;
      state = state.copyWith(
        clearSubmittingActor: true,
        actionError: actionError,
      );
      return false;
    }

    final remainingActors = state.actors
        .where((actor) => actor.nftId != actorNftId)
        .toList(growable: false);
    _optimisticallyRemovedActors.add(actorNftId);
    state = state.copyWith(
      actors: remainingActors,
      totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
      clearSubmittingActor: true,
      clearActionError: true,
    );

    ref.read(weeklySalaryControllerProvider.notifier).refreshAfterMutation();
    return true;
  }

  /// 角色从演出中回到候场前，解除派遣时的乐观隐藏。
  void allowActorToReturn(String actorNftId) {
    _optimisticallyRemovedActors.remove(actorNftId);
    _pendingStaminaRefills.remove(actorNftId);
  }

  void allowAllActorsToReturn() {
    _optimisticallyRemovedActors.clear();
    _pendingStaminaRefills.clear();
  }
}
