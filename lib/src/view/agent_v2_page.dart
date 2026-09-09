import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/app_providers.dart';
import '../provider/tab_index_provider.dart';
import '../services/connectivity_service.dart';
import '../styles/story_colors.dart';
import 'widgets/agent_v2/agent_v2_widgets.dart';

/// 经纪人 V2。
class AgentV2Page extends ConsumerStatefulWidget {
  final Duration miningRefreshInterval;
  final Duration weeklySalaryBoundaryDelay;
  final Duration actorSignRefreshDelay;

  const AgentV2Page({
    super.key,
    this.miningRefreshInterval = const Duration(minutes: 10),
    this.weeklySalaryBoundaryDelay = const Duration(seconds: 5),
    this.actorSignRefreshDelay = const Duration(seconds: 2),
  });

  @override
  ConsumerState<AgentV2Page> createState() => _AgentV2PageState();
}

class _AgentV2PageState extends ConsumerState<AgentV2Page>
    with WidgetsBindingObserver {
  late int _handledInventoryRevision;
  Timer? _miningRefreshTimer;
  Timer? _weeklySalaryBoundaryTimer;
  late final ConnectivityService _connectivityService;
  late bool _wasOnline;
  bool _isSilentRefreshInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectivityService = ref.read(connectivityProvider);
    _wasOnline = _connectivityService.value;
    _connectivityService.addListener(_handleConnectivityChanged);
    _handledInventoryRevision = ref.read(actorInventorySyncControllerProvider);
    _startMiningRefreshTimer();
    _scheduleWeeklySalaryBoundaryRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadMiningData());
      unawaited(_loadCandidateActorsInitial());
      unawaited(_loadUpgradeableActorsInitial());
      unawaited(_refreshWeeklySalaryIfStale());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityService.removeListener(_handleConnectivityChanged);
    _miningRefreshTimer?.cancel();
    _weeklySalaryBoundaryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _startMiningRefreshTimer();
      _scheduleWeeklySalaryBoundaryRefresh();
      if (ref.read(tabIndexProvider) == StoryTab.game.index) {
        unawaited(_refreshMiningDataSilently());
      } else {
        // The page is retained by IndexedStack; refresh shared Agent data.
        unawaited(_refreshAgentDataSilently());
      }
      unawaited(_refreshWeeklySalaryIfStale());
    } else {
      _miningRefreshTimer?.cancel();
      _miningRefreshTimer = null;
      _weeklySalaryBoundaryTimer?.cancel();
      _weeklySalaryBoundaryTimer = null;
    }
  }

  /// 对齐整点后稍作延迟，避免结算尚未完成及客户端集中请求。
  void _scheduleWeeklySalaryBoundaryRefresh() {
    _weeklySalaryBoundaryTimer?.cancel();
    final now = DateTime.now();
    final nextBoundary = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour + 1,
    ).add(widget.weeklySalaryBoundaryDelay);
    _weeklySalaryBoundaryTimer = Timer(
      nextBoundary.difference(now),
      _handleWeeklySalaryBoundary,
    );
  }

  void _handleWeeklySalaryBoundary() {
    if (!mounted) return;
    final controller = ref.read(weeklySalaryControllerProvider.notifier);
    if (ref.read(tabIndexProvider) == StoryTab.game.index) {
      unawaited(controller.forceRefresh());
    } else {
      controller.markDirty();
    }
    _scheduleWeeklySalaryBoundaryRefresh();
  }

  Future<void> _refreshWeeklySalaryIfStale() async {
    if (!mounted || ref.read(tabIndexProvider) != StoryTab.game.index) return;
    await ref.read(weeklySalaryControllerProvider.notifier).refreshIfStale();
  }

  void _startMiningRefreshTimer() {
    _miningRefreshTimer?.cancel();
    _miningRefreshTimer = Timer.periodic(widget.miningRefreshInterval, (_) {
      unawaited(_refreshMiningDataSilently());
    });
  }

  Future<void> _refreshMiningDataSilently() async {
    final auth = ref.read(authControllerProvider);
    if (!mounted ||
        _isSilentRefreshInFlight ||
        !auth.isLoggedIn ||
        auth.isLogging ||
        ref.read(tabIndexProvider) != StoryTab.game.index) {
      return;
    }

    _isSilentRefreshInFlight = true;
    try {
      final controller = ref.read(gameControllerProvider.notifier);
      await Future.wait([
        controller.refreshAgentV2Config(),
        controller.refreshDeployedActors(silent: true, bypassCache: true),
        ref.read(agentV2CandidateActorsControllerProvider.notifier).refresh(),
        ref.read(agentV2UpgradeableActorsControllerProvider.notifier).refresh(),
      ]);
    } finally {
      _isSilentRefreshInFlight = false;
    }
  }

  Future<void> _refreshAgentDataSilently() async {
    final auth = ref.read(authControllerProvider);
    if (!mounted || !auth.isLoggedIn || auth.isLogging) return;
    await Future.wait([
      ref.read(gameControllerProvider.notifier).refreshAgentV2Config(),
      ref.read(agentV2CandidateActorsControllerProvider.notifier).refresh(),
      ref.read(agentV2UpgradeableActorsControllerProvider.notifier).refresh(),
    ]);
  }

  void _handleConnectivityChanged() {
    final isOnline = _connectivityService.value;
    final didRecover = !_wasOnline && isOnline;
    _wasOnline = isOnline;
    if (!didRecover || !mounted) return;

    // Recalibrate config and actor data only on the offline -> online edge.
    unawaited(_refreshAgentDataSilently());
  }

  Future<void> _loadCandidateActorsInitial() async {
    final auth = ref.read(authControllerProvider);
    if (!mounted || !auth.isLoggedIn || auth.isLogging) return;
    await ref
        .read(agentV2CandidateActorsControllerProvider.notifier)
        .loadInitial();
  }

  Future<void> _loadUpgradeableActorsInitial() async {
    final auth = ref.read(authControllerProvider);
    if (!mounted || !auth.isLoggedIn || auth.isLogging) return;
    await ref
        .read(agentV2UpgradeableActorsControllerProvider.notifier)
        .loadInitial();
  }

  Future<void> _loadMiningData({bool force = false}) async {
    final auth = ref.read(authControllerProvider);
    if (!mounted || !auth.isLoggedIn || auth.isLogging) return;
    final controller = ref.read(gameControllerProvider.notifier);
    controller.loadCachedAgentV2Config();
    if (force) {
      await Future.wait([
        controller.refreshAgentV2Config(),
        controller.refreshDeployedActors(force: true),
      ]);
    } else {
      await Future.wait([
        controller.refreshAgentV2Config(),
        controller.loadDeployedActorsWithRevalidation(),
      ]);
    }
  }

  bool _refreshSignedActorData(int revision) {
    if (revision <= _handledInventoryRevision) return false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(tabIndexProvider) != StoryTab.game.index) {
        return;
      }
      _handledInventoryRevision = revision;
      unawaited(_forceRefreshSignedActorData());
    });
    return true;
  }

  Future<void> _forceRefreshSignedActorData() async {
    // Give the mining indexer a short window, then refresh each affected actor
    // list exactly once for this inventory revision.
    await Future<void>.delayed(widget.actorSignRefreshDelay);
    if (!mounted) return;
    await Future.wait([
      ref.read(agentV2CandidateActorsControllerProvider.notifier).refresh(),
      ref.read(agentV2UpgradeableActorsControllerProvider.notifier).refresh(),
    ]);
  }

  void _invalidateAccountData() {
    ref.invalidate(gameControllerProvider);
    ref.invalidate(agentV2CandidateActorsControllerProvider);
    ref.invalidate(agentV2UpgradeableActorsControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    ref.listen<({bool isLoggedIn, bool isLogging, String? userId})>(
      authControllerProvider.select(
        (state) => (
          isLoggedIn: state.isLoggedIn,
          isLogging: state.isLogging,
          userId: state.userId,
        ),
      ),
      (previous, current) {
        final loggedOut = previous?.isLoggedIn == true && !current.isLoggedIn;
        final accountChanged =
            previous?.isLoggedIn == true &&
            current.isLoggedIn &&
            previous?.userId != current.userId;
        final loginCompleted =
            current.isLoggedIn &&
            !current.isLogging &&
            (previous?.isLoggedIn != true || previous?.isLogging == true);
        if (loggedOut) {
          _invalidateAccountData();
        } else if (accountChanged || loginCompleted) {
          _invalidateAccountData();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_loadMiningData(force: true));
            unawaited(_loadCandidateActorsInitial());
            unawaited(_loadUpgradeableActorsInitial());
          });
        }
      },
    );

    ref.listen<int>(actorInventorySyncControllerProvider, (_, revision) {
      if (ref.read(tabIndexProvider) == StoryTab.game.index) {
        _refreshSignedActorData(revision);
      }
    });
    ref.listen<bool>(
      tabIndexProvider.select((index) => index == StoryTab.game.index),
      (previous, isGameTab) {
        if (previous == false && isGameTab) {
          final isSignedActorRefreshScheduled = _refreshSignedActorData(
            ref.read(actorInventorySyncControllerProvider),
          );
          if (!isSignedActorRefreshScheduled) {
            unawaited(_refreshMiningDataSilently());
          }
          unawaited(_refreshWeeklySalaryIfStale());
        }
      },
    );

    return ColoredBox(
      color: StoryColors.cardOf(brightness),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AgentV2AppBar(
              onMenuPressed: () => ref
                  .read(mainShellScaffoldKeyProvider)
                  .currentState
                  ?.openDrawer(),
            ),
            const AgentV2WeeklySalary(),
            const SizedBox(height: 16),
            const Expanded(
              child: Column(
                children: [
                  Expanded(child: AgentV2MiningCardList()),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: AgentV2PerformButton(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const AgentV2ActorStrip(),
          ],
        ),
      ),
    );
  }
}
