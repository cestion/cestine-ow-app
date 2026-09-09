import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../provider/app_providers.dart';
import '../repositories/reward_repository.dart';
import 'weekly_salary_state.dart';

typedef _WeeklySalaryAuth = ({
  bool isLoggedIn,
  bool isLogging,
  String? userId,
  String? token,
});

/// 管理 Agent V2 本周片酬的单一数据源。
///
/// 首次订阅时先展示可用缓存再静默回源；Tab、前台恢复和整点事件通过
/// [refreshIfStale]、[forceRefresh] 或 [markDirty] 复用同一刷新入口。Controller
/// 同时监听登录账号，退出立即清空，换号后丢弃旧请求并重新获取新账号数据。
class WeeklySalaryController extends Notifier<WeeklySalaryState> {
  static const defaultMaxAge = Duration(minutes: 2);

  RewardRepository get _repository => ref.read(rewardRepositoryProvider);

  Future<void>? _refreshInFlight;
  Future<void> _sessionTransition = Future<void>.value();
  int _requestGeneration = 0;
  int _dirtyRevision = 0;

  @override
  WeeklySalaryState build() {
    ref.listen<_WeeklySalaryAuth>(
      authControllerProvider.select(
        (auth) => (
          isLoggedIn: auth.isLoggedIn,
          isLogging: auth.isLogging,
          userId: auth.userId,
          token: auth.token,
        ),
      ),
      _handleAuthChanged,
    );

    final auth = _readAuth();
    if (_canLoad(auth)) {
      Future.microtask(() {
        if (ref.mounted) unawaited(loadWithRevalidation());
      });
    }
    return WeeklySalaryState(isRefreshing: _canLoad(auth));
  }

  /// 有缓存先展示缓存，然后始终从服务端校准一次。
  Future<void> loadWithRevalidation() async {
    final auth = _readAuth();
    if (!_canLoad(auth)) return;

    final generation = _requestGeneration;
    final sessionKey = _sessionKey(auth);
    final cached = await _repository.getCachedWeeklyStats();
    if (!_isCurrentRequest(generation, sessionKey)) return;
    if (cached != null && state.stats == null) {
      state = state.copyWith(stats: cached, isDirty: true);
    }
    await forceRefresh();
  }

  /// 仅当数据被标脏、尚未加载或超过 [maxAge] 时静默回源。
  Future<void> refreshIfStale({Duration maxAge = defaultMaxAge}) async {
    final updatedAt = state.lastUpdatedAt;
    final isStale =
        updatedAt == null || DateTime.now().difference(updatedAt) >= maxAge;
    if (!state.isDirty && state.stats != null && !isStale) return;
    await forceRefresh();
  }

  /// 绕过 Repository 缓存获取服务端最新片酬。
  Future<void> forceRefresh() => _refresh(forceNetwork: true);

  /// 记录潜在的数据变化，等页面可见或其他刷新时机再回源。
  void markDirty() {
    _dirtyRevision++;
    if (!state.isDirty) state = state.copyWith(isDirty: true);
  }

  /// 业务操作成功后立即静默校准，同时保留当前金额直到新数据返回。
  void refreshAfterMutation() {
    markDirty();
    unawaited(_refreshAfterMutation());
  }

  /// 清除当前账号数据；用于显式退出和账号切换。
  void clear() {
    final previousRequest = _refreshInFlight;
    final repository = _repository;
    _requestGeneration++;
    _dirtyRevision++;
    _refreshInFlight = null;
    state = const WeeklySalaryState();
    _enqueueSessionTransition(() async {
      if (previousRequest != null) await previousRequest;
      await repository.invalidateWeeklyStatsCache();
    });
  }

  Future<void> _refresh({required bool forceNetwork}) {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final auth = _readAuth();
    if (!_canLoad(auth)) return Future<void>.value();

    final generation = _requestGeneration;
    final dirtyRevision = _dirtyRevision;
    final sessionKey = _sessionKey(auth);
    state = state.copyWith(isRefreshing: true, clearLastError: true);

    late final Future<void> operation;
    operation = () async {
      try {
        final result = forceNetwork
            ? await _repository.refreshWeeklyStats()
            : await _repository.getWeeklyStats();
        if (!_isCurrentRequest(generation, sessionKey)) return;

        if (result.isSuccess) {
          final changedWhileRefreshing = dirtyRevision != _dirtyRevision;
          state = state.copyWith(
            stats: result.dataOrNull,
            lastUpdatedAt: DateTime.now(),
            isRefreshing: false,
            isDirty: changedWhileRefreshing,
            clearLastError: true,
          );
        } else {
          state = state.copyWith(
            isRefreshing: false,
            isDirty: true,
            lastError: result.errorOrNull,
          );
        }
      } catch (error) {
        if (!_isCurrentRequest(generation, sessionKey)) return;
        state = state.copyWith(
          isRefreshing: false,
          isDirty: true,
          lastError: ApiError.unknown(error.toString()),
        );
      } finally {
        if (identical(_refreshInFlight, operation)) {
          _refreshInFlight = null;
        }
      }
    }();
    _refreshInFlight = operation;
    return operation;
  }

  Future<void> _refreshAfterMutation() async {
    await refreshIfStale();
    if (state.isDirty && state.lastError == null) {
      await refreshIfStale();
    }
  }

  void _handleAuthChanged(
    _WeeklySalaryAuth? previous,
    _WeeklySalaryAuth current,
  ) {
    if (!current.isLoggedIn) {
      clear();
      return;
    }
    if (current.isLogging) return;

    final loginCompleted =
        previous?.isLoggedIn != true || previous?.isLogging == true;
    final accountChanged =
        previous?.isLoggedIn == true &&
        _sessionKey(previous!) != _sessionKey(current);
    if (!loginCompleted && !accountChanged) return;

    final previousRequest = _refreshInFlight;
    _requestGeneration++;
    _dirtyRevision++;
    _refreshInFlight = null;
    state = const WeeklySalaryState();
    _enqueueSessionTransition(
      () => _reloadAfterAccountChange(current, previousRequest),
    );
  }

  Future<void> _reloadAfterAccountChange(
    _WeeklySalaryAuth expectedAuth,
    Future<void>? previousRequest,
  ) async {
    if (previousRequest != null) await previousRequest;
    await _repository.invalidateWeeklyStatsCache();
    if (!ref.mounted || _sessionKey(_readAuth()) != _sessionKey(expectedAuth)) {
      return;
    }
    await _refresh(forceNetwork: false);
  }

  void _enqueueSessionTransition(Future<void> Function() operation) {
    _sessionTransition = _sessionTransition.then((_) async {
      try {
        await operation();
      } catch (_) {
        // A failed cache cleanup must not block later logout/login transitions.
      }
    });
  }

  _WeeklySalaryAuth _readAuth() {
    final auth = ref.read(authControllerProvider);
    return (
      isLoggedIn: auth.isLoggedIn,
      isLogging: auth.isLogging,
      userId: auth.userId,
      token: auth.token,
    );
  }

  bool _canLoad(_WeeklySalaryAuth auth) => auth.isLoggedIn && !auth.isLogging;

  String _sessionKey(_WeeklySalaryAuth auth) => auth.userId ?? auth.token ?? '';

  bool _isCurrentRequest(int generation, String sessionKey) {
    if (!ref.mounted || generation != _requestGeneration) return false;
    final auth = _readAuth();
    return _canLoad(auth) && _sessionKey(auth) == sessionKey;
  }
}
