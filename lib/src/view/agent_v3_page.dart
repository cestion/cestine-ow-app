import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/common/story_toast.dart';
import '../controller/agent_v3_state.dart';
import '../core/logging_request_policy_observer.dart';
import '../core/request_keys.dart';
import '../core/request_throttle.dart';
import '../core/story_constants.dart';
import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../provider/tab_index_provider.dart';
import '../model/models.dart';
import '../routes/actor_detail_navigation.dart';
import '../services/connectivity_service.dart';
import '../styles/story_colors.dart';
import '../widgets/error_handler.dart';
import 'widgets/agent_more_sheet.dart';
import 'widgets/agent_v3/agent_v3_widgets.dart';

/// 经纪人 V3。
class AgentV3Page extends ConsumerStatefulWidget {
  const AgentV3Page({
    super.key,
    this.standalone = false,
    this.syncInterval = StoryConstants.agentV3SyncInterval,
    this.syncDebounce = StoryConstants.agentV3SyncDebounce,
  });

  /// Widget/golden tests may render the static page without an initialized SDK.
  final bool standalone;
  final Duration syncInterval;
  final Duration syncDebounce;

  @override
  ConsumerState<AgentV3Page> createState() => _AgentV3PageState();
}

class _AgentV3PageState extends ConsumerState<AgentV3Page>
    with WidgetsBindingObserver {
  bool _isPrimaryActionLoading = false;
  String? _focusedActorNftId;
  Timer? _syncTimer;
  late final ConnectivityService _connectivityService;
  late bool _wasOnline;
  late bool _isForeground;
  final RequestThrottle _syncThrottle =
      MemoryRequestThrottle(observer: debugRequestPolicyObserver);

  Future<void> _openActorDetail(MiningActor actor) {
    final actorId = actor.actorCollectionId?.toString();
    if (actorId == null) return Future.value();
    return openActorDetail(
      context,
      actorId: actorId,
      preview: ActorCollection(
        id: actorId,
        name: actor.actorName,
        avatarUrl: actor.avatarUrl,
        heatValue: actor.heat,
        trust: actor.trust,
        computingPower: actor.computingPower,
      ),
    );
  }

  Future<void> _openCandidateActors() async {
    final actorNftId = await showAgentV3CandidateActorsSheet(context);
    await _focusScheduledActor(actorNftId);
  }

  Future<void> _openTodo() async {
    final actorNftId = await showAgentV3TodoSheet(context, ref);
    await _focusScheduledActor(actorNftId);
  }

  Future<void> _focusScheduledActor(String? actorNftId) async {
    final normalizedId = actorNftId?.trim();
    if (!mounted || normalizedId == null || normalizedId.isEmpty) return;

    setState(() => _focusedActorNftId = normalizedId);
    await _requestSynchronization(
      AgentV3SyncReason.mutation,
      bypassDebounce: true,
    );
  }

  @override
  void initState() {
    super.initState();
    if (!widget.standalone) {
      WidgetsBinding.instance.addObserver(this);
      _isForeground =
          WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      _connectivityService = ref.read(connectivityProvider);
      _wasOnline = _connectivityService.value;
      _connectivityService.addListener(_handleConnectivityChanged);
      _updateSyncTimer();
      Future.microtask(() async {
        final auth = ref.read(authControllerProvider.notifier);
        await auth.ready;
        if (!mounted) return;
        await _requestSynchronization(
          AgentV3SyncReason.initial,
          bypassDebounce: true,
        );
      });
    }
  }

  @override
  void dispose() {
    if (!widget.standalone) {
      WidgetsBinding.instance.removeObserver(this);
      _connectivityService.removeListener(_handleConnectivityChanged);
      _syncTimer?.cancel();
    }
    super.dispose();
  }

  bool get _isAgentTab => ref.read(tabIndexProvider) == StoryTab.game.index;

  bool get _canSynchronize {
    if (widget.standalone || !_isForeground || !_isAgentTab) return false;
    final auth = ref.read(authControllerProvider);
    return auth.isLoggedIn && !auth.isLogging && _connectivityService.value;
  }

  Future<void> _requestSynchronization(
    AgentV3SyncReason reason, {
    bool bypassDebounce = false,
  }) async {
    if (!_canSynchronize) {
      if (!widget.standalone) {
        ref.read(agentV3ControllerProvider.notifier).markDirty();
      }
      return;
    }

    if (bypassDebounce) {
      _syncThrottle.reset(RequestKeys.agentV3Sync);
    }
    if (!_syncThrottle.tryClaim(
      RequestKeys.agentV3Sync,
      window: widget.syncDebounce,
    )) {
      return;
    }
    await ref
        .read(agentV3ControllerProvider.notifier)
        .synchronize(reason: reason);
  }

  void _updateSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
    if (!_canSynchronize || widget.syncInterval <= Duration.zero) return;
    _syncTimer = Timer.periodic(widget.syncInterval, (_) {
      unawaited(_requestSynchronization(AgentV3SyncReason.periodic));
    });
  }

  void _handleConnectivityChanged() {
    final isOnline = _connectivityService.value;
    final recovered = !_wasOnline && isOnline;
    _wasOnline = isOnline;
    _updateSyncTimer();
    if (!recovered || !mounted) return;

    if (_isForeground && _isAgentTab) {
      unawaited(
        _requestSynchronization(
          AgentV3SyncReason.connectivityRecovered,
          bypassDebounce: true,
        ),
      );
    } else {
      ref.read(agentV3ControllerProvider.notifier).markDirty();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        final returnedFromBackground = !_isForeground;
        _isForeground = true;
        _updateSyncTimer();
        if (!returnedFromBackground) return;
        if (_isAgentTab) {
          unawaited(
            _requestSynchronization(
              AgentV3SyncReason.appResumed,
              bypassDebounce: true,
            ),
          );
        } else {
          ref.read(agentV3ControllerProvider.notifier).markDirty();
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _isForeground = false;
        _syncTimer?.cancel();
        _syncTimer = null;
      case AppLifecycleState.inactive:
        // Ignore short interruptions such as notification shade and dialogs.
        break;
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (_isPrimaryActionLoading) return;

    final state = ref.read(agentV3ControllerProvider);
    final candidates = ref.read(agentV2CandidateActorsControllerProvider);
    final waitingActorCount = candidates.isInitialized
        ? candidates.totalCount
        : candidates.actors.length;
    final action = state.primaryActionKind(
      waitingActorCount: waitingActorCount,
    );

    if (action == AgentV3PrimaryActionKind.signActor) {
      ref.read(tabIndexProvider.notifier).setIndex(StoryTab.nft.index);
      return;
    }
    if (action == AgentV3PrimaryActionKind.claim &&
        ref.read(authControllerProvider).solanaAddress.trim().isEmpty) {
      StoryToast.error(context, context.l10n.incomeClaimNoWallet);
      return;
    }

    int? confirmedPerformCount;
    if (action == AgentV3PrimaryActionKind.performAll) {
      confirmedPerformCount = state.vacantDeploySlotCount < waitingActorCount
          ? state.vacantDeploySlotCount
          : waitingActorCount;
      final confirmed = await showAgentV3PerformAllConfirmDialog(
        context,
        deployCount: confirmedPerformCount,
      );
      if (confirmed != true || !mounted) return;
    }
    if (action == AgentV3PrimaryActionKind.restAll) {
      final confirmed = await showAgentV3RestAllConfirmDialog(
        context,
        actorCount: state.deployedActors.length,
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _isPrimaryActionLoading = true);
    try {
      switch (action) {
        case AgentV3PrimaryActionKind.claim:
          final result = await ref
              .read(agentV3ControllerProvider.notifier)
              .claimStory(
                toAddress: ref.read(authControllerProvider).solanaAddress,
              );
          if (!mounted) return;
          if (result.isFailure) {
            handleApiError(result.errorOrNull!, ctx: context);
            unawaited(
              _requestSynchronization(
                AgentV3SyncReason.mutation,
                bypassDebounce: true,
              ),
            );
            return;
          }
          StoryToast.success(
            context,
            context.l10n.incomeClaimWithdrawSubmitted,
          );
          ref.read(onChainWalletBalanceProvider.notifier).refresh();
          break;

        case AgentV3PrimaryActionKind.performAll:
          final expectedCount = confirmedPerformCount!;
          final result = await ref
              .read(agentV3ControllerProvider.notifier)
              .performAllActors();
          if (!mounted) return;
          if (result.isFailure) {
            handleApiError(result.errorOrNull!, ctx: context);
            unawaited(
              _requestSynchronization(
                AgentV3SyncReason.mutation,
                bypassDebounce: true,
              ),
            );
            return;
          }

          final successCount = result.dataOrNull ?? 0;
          final depletedCount = (expectedCount - successCount).clamp(
            0,
            expectedCount,
          );
          if (depletedCount > 0) {
            final message = context.l10n.agentV2PerformAllDepletedResult(
              successCount,
              depletedCount,
            );
            if (successCount > 0) {
              StoryToast.success(context, message);
            } else {
              StoryToast.error(context, message);
            }
          } else {
            StoryToast.success(context, context.l10n.agentV2PerformAllSuccess);
          }
          await ref
              .read(agentV2CandidateActorsControllerProvider.notifier)
              .refresh();
          break;

        case AgentV3PrimaryActionKind.restAll:
          final result = await ref
              .read(agentV3ControllerProvider.notifier)
              .restAllActors();
          if (!mounted) return;
          if (result.isFailure) {
            handleApiError(result.errorOrNull!, ctx: context);
            unawaited(
              _requestSynchronization(
                AgentV3SyncReason.mutation,
                bypassDebounce: true,
              ),
            );
            return;
          }
          StoryToast.success(context, context.l10n.agentV2RestAllSuccess);
          await ref
              .read(agentV2CandidateActorsControllerProvider.notifier)
              .refresh();
          break;

        case AgentV3PrimaryActionKind.refillAll:
          await showAgentV3RefillAllDialog(context, ref);
          break;

        case AgentV3PrimaryActionKind.signActor:
          break;
      }
    } finally {
      if (mounted) setState(() => _isPrimaryActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.standalone) {
      ref.listen<bool>(
        tabIndexProvider.select((index) => index == StoryTab.game.index),
        (previous, isAgentTab) {
          _updateSyncTimer();
          if (previous == false && isAgentTab) {
            unawaited(
              _requestSynchronization(
                AgentV3SyncReason.tabActivated,
                bypassDebounce: true,
              ),
            );
          }
        },
      );
      ref.listen<({bool loggedIn, bool logging, String? sessionId})>(
        authControllerProvider.select(
          (auth) => (
            loggedIn: auth.isLoggedIn,
            logging: auth.isLogging,
            sessionId: auth.userId ?? auth.token,
          ),
        ),
        (previous, current) {
          _updateSyncTimer();
          final loginCompleted =
              current.loggedIn &&
              !current.logging &&
              (previous?.loggedIn != true || previous?.logging == true);
          final accountChanged =
              previous?.loggedIn == true &&
              current.loggedIn &&
              previous?.sessionId != current.sessionId;
          if ((loginCompleted || accountChanged) && _isAgentTab) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              unawaited(
                _requestSynchronization(
                  AgentV3SyncReason.initial,
                  bypassDebounce: true,
                ),
              );
            });
          }
        },
      );
    }
    final state = ref.watch(agentV3ControllerProvider);
    final candidates = ref.watch(agentV2CandidateActorsControllerProvider);
    final waitingActorCount = candidates.isInitialized
        ? candidates.totalCount
        : candidates.actors.length;
    final brightness = Theme.of(context).brightness;
    final pageSurface = StoryColors.whiteToDarkOf(brightness);
    final body = ColoredBox(
      color: pageSurface,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AgentV3AppBar(
              primaryItemCount: state.primaryItemCount,
              secondaryItemCount: state.secondaryItemCount,
              weeklySalary: state.weeklySalary,
              onMenuPressed: () => ref
                  .read(mainShellScaffoldKeyProvider)
                  .currentState
                  ?.openDrawer(),
              onPrimaryAddPressed: () => showAgentV3PurchaseSheet(
                context,
                ref,
                CardPurchaseType.energyPack,
              ),
              onSecondaryAddPressed: () => showAgentV3PurchaseSheet(
                context,
                ref,
                CardPurchaseType.trainingManual,
              ),
              onMorePressed: () => showAgentMoreSheet(context),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _requestSynchronization(
                  AgentV3SyncReason.manual,
                  bypassDebounce: true,
                ),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      child: AgentV3Content(
                        state: state,
                        focusedActorNftId: _focusedActorNftId,
                        onTodoPressed: _openTodo,
                        onUpgradePressed: () =>
                            showAgentV3UpgradeableActorsSheet(context),
                        onWaitingPressed: _openCandidateActors,
                        onRecyclePressed: () =>
                            showAgentV3RecycleActorsSheet(context),
                        onActorPressed: _openActorDetail,
                        onRefillPressed: (actor) =>
                            showAgentV3RefillStaminaDialog(context, ref, actor),
                        onRestPressed: (actor) =>
                            showAgentV3RestConfirmDialog(context, actor),
                        waitingActorCount: waitingActorCount,
                        isPrimaryActionLoading: _isPrimaryActionLoading,
                        onPrimaryActionPressed:
                            candidates.isLoading && !candidates.isInitialized
                            ? null
                            : _handlePrimaryAction,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return body;
  }
}
