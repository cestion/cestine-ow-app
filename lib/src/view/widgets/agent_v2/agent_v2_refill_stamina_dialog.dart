import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/story_toast.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../utils/wallet_balance_gate.dart';
import '../../../widgets/error_handler.dart';

/// 经纪人 V2 补充体力确认弹窗；挖矿卡片可按需展示“全部补充”。
Future<bool> showAgentV2RefillStaminaDialog(
  BuildContext context,
  WidgetRef ref,
  MiningActor actor, {
  bool showRefillAll = false,
}) async {
  final shouldShowRefillAll =
      showRefillAll && ref.read(gameControllerProvider).deployedCount > 1;
  final didRefill = await showGeneralDialog<bool>(
    context: context,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) =>
        _AgentV2RefillStaminaRoute(
          actor: actor,
          showRefillAll: shouldShowRefillAll,
        ),
  );

  if (didRefill != true) return false;

  if (context.mounted) {
    StoryToast.success(context, context.l10n.gameRefillSuccess);
    ref.read(incomeControllerProvider.notifier).refresh();
    ref.read(onChainWalletBalanceProvider.notifier).refresh();
  }
  return true;
}

class _AgentV2RefillStaminaRoute extends ConsumerStatefulWidget {
  final MiningActor actor;
  final bool showRefillAll;

  const _AgentV2RefillStaminaRoute({
    required this.actor,
    required this.showRefillAll,
  });

  @override
  ConsumerState<_AgentV2RefillStaminaRoute> createState() =>
      _AgentV2RefillStaminaRouteState();
}

class _AgentV2RefillStaminaRouteState
    extends ConsumerState<_AgentV2RefillStaminaRoute> {
  bool _isLoadingPricing = true;
  bool _isSubmitting = false;
  bool _isSubmittingAll = false;
  bool _isLoadingAllActors = false;
  bool _didFailLoadingAllActors = false;
  double? _actorCost;
  int? _latestStaminaLimit;
  Future<void>? _pricingRefresh;
  List<ActorNeedingStaminaRefill> _actorsNeedingRefill = const [];

  @override
  void initState() {
    super.initState();
    final actorConfig = ref.read(gameControllerProvider).actorNftConfig;
    _actorCost = actorConfig?.supplyFeeForLevel(widget.actor.level);
    _latestStaminaLimit = actorConfig?.staminaLimit;
    _isLoadingPricing = true;

    // The pricing refresh updates Riverpod state. Starting it from initState
    // may synchronously notify listeners while this route is still being
    // built, which Riverpod explicitly rejects. Wait until the first frame has
    // completed before kicking off the initial async work.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pricingRefresh = _refreshLatestPricing();
      if (widget.showRefillAll) {
        unawaited(_loadActorsNeedingRefill());
      }
    });
  }

  Future<void> _loadActorsNeedingRefill() async {
    setState(() {
      _isLoadingAllActors = true;
      _didFailLoadingAllActors = false;
    });

    final result = await ref
        .read(miningRepositoryProvider)
        .listActorsNeedingStaminaRefill();
    if (!mounted) return;

    result.when(
      success: (actors) => setState(() {
        _actorsNeedingRefill = actors;
        _isLoadingAllActors = false;
      }),
      failure: (_) => setState(() {
        _actorsNeedingRefill = const [];
        _isLoadingAllActors = false;
        _didFailLoadingAllActors = true;
      }),
    );
  }

  /// 每次打开弹窗都通过 GameController 回源，避免使用全局配置缓存定价。
  Future<void> _refreshLatestPricing() async {
    final notifier = ref.read(gameControllerProvider.notifier);
    await notifier.refreshAgentV2Config();
    if (!mounted) return;

    final gameState = ref.read(gameControllerProvider);
    final actorConfig = gameState.actorNftConfig;
    final actorCost = actorConfig?.supplyFeeForLevel(widget.actor.level);
    setState(() {
      _actorCost = actorCost;
      _latestStaminaLimit = actorConfig?.staminaLimit;
      _isLoadingPricing = false;
    });
    final error = gameState.agentV2ConfigError;
    if (actorCost == null && error != null) {
      handleApiError(error, ctx: context, rootOverlay: true);
    }
  }

  Future<void> _refillActor() async {
    final actor = widget.actor;
    final initialGameState = ref.read(gameControllerProvider);

    if (_isSubmitting ||
        _isSubmittingAll ||
        initialGameState.isActionLoading ||
        _isLoadingPricing ||
        _actorCost == null ||
        actor.nftId.isEmpty ||
        actor.actorTokenId == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    var didClose = false;

    try {
      // 支付前等待本次网络刷新，确保实际下单使用 Controller 中的最新配置。
      await _pricingRefresh;
      if (!mounted) return;

      final gameState = ref.read(gameControllerProvider);
      final notifier = ref.read(gameControllerProvider.notifier);
      final staminaLimit = _latestStaminaLimit ?? gameState.agentV2StaminaLimit;
      final payAmount = _actorCost;
      if (gameState.isActionLoading ||
          staminaLimit == null ||
          payAmount == null ||
          actor.isStaminaFull(staminaLimit)) {
        return;
      }

      final hasBalance = await ensureUsdcBalanceOrShowDialog(
        ref,
        context,
        payAmount,
      );
      if (!hasBalance || !mounted) return;

      final didRefill = await notifier.replenishStamina(
        actor,
        payAmount: payAmount,
      );
      if (!mounted) return;

      if (didRefill) {
        didClose = true;
        Navigator.of(context).pop(true);
        return;
      }

      ref.read(onChainWalletBalanceProvider.notifier).refresh();
      final error = ref.read(gameControllerProvider).lastError;
      if (error != null) {
        handleApiError(error, ctx: context, rootOverlay: true);
      } else {
        StoryToast.error(context, context.l10n.gameRefillFailed);
      }
    } finally {
      if (mounted && !didClose) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _refillAllActors() async {
    final gameState = ref.read(gameControllerProvider);
    final actors = _actorsNeedingRefill;

    if (_isSubmitting ||
        _isSubmittingAll ||
        gameState.isActionLoading ||
        _isLoadingAllActors ||
        _didFailLoadingAllActors ||
        actors.isEmpty) {
      return;
    }

    final totalCost = actors.fold<double>(
      0,
      (sum, actor) => sum + actor.supplyFee,
    );
    setState(() => _isSubmittingAll = true);
    var didClose = false;

    try {
      final hasBalance = await ensureUsdcBalanceOrShowDialog(
        ref,
        context,
        totalCost,
      );
      if (!hasBalance || !mounted) return;

      final didRefill = await ref
          .read(gameControllerProvider.notifier)
          .replenishStaminaBatch(actors);
      if (!mounted) return;

      if (didRefill) {
        didClose = true;
        Navigator.of(context).pop(true);
        return;
      }

      ref.read(onChainWalletBalanceProvider.notifier).refresh();
      final error = ref.read(gameControllerProvider).lastError;
      if (error != null) {
        handleApiError(error, ctx: context, rootOverlay: true);
      } else {
        StoryToast.error(context, context.l10n.gameRefillFailed);
      }
    } finally {
      if (mounted && !didClose) {
        setState(() => _isSubmittingAll = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final staminaLimit = _latestStaminaLimit ?? gameState.agentV2StaminaLimit;
    final isSubmitting =
        _isSubmitting || _isSubmittingAll || gameState.isActionLoading;
    final allActorCount = _actorsNeedingRefill.length;
    final allActorCost = _actorsNeedingRefill.fold<double>(
      0,
      (sum, actor) => sum + actor.supplyFee,
    );
    final canRefill =
        !_isLoadingPricing &&
        staminaLimit != null &&
        _actorCost != null &&
        !widget.actor.isStaminaFull(staminaLimit) &&
        widget.actor.nftId.isNotEmpty &&
        widget.actor.actorTokenId != null &&
        !isSubmitting;

    return PopScope(
      canPop: !isSubmitting,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isSubmitting ? null : () => Navigator.of(context).pop(false),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: const ColoredBox(color: StoryColors.overlayMid),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(StorySpacing.base),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 343),
                  child: SizedBox(
                    width: double.infinity,
                    child: widget.showRefillAll
                        ? _AgentV2BatchRefillStaminaCard(
                            actor: widget.actor,
                            staminaLimit: staminaLimit,
                            actorCost: _actorCost,
                            allActorCount: allActorCount,
                            allActorCost: allActorCost,
                            isLoadingPricing: _isLoadingPricing,
                            isSubmitting: _isSubmitting,
                            isSubmittingAll: _isSubmittingAll,
                            isLoadingAllActors: _isLoadingAllActors,
                            didFailLoadingAllActors: _didFailLoadingAllActors,
                            onRefillActor: canRefill ? _refillActor : null,
                            onRefillAll:
                                !_isLoadingAllActors &&
                                    !_didFailLoadingAllActors &&
                                    _actorsNeedingRefill.isNotEmpty &&
                                    !isSubmitting
                                ? _refillAllActors
                                : null,
                            onRetryAllActors: _didFailLoadingAllActors
                                ? _loadActorsNeedingRefill
                                : null,
                          )
                        : AgentV2RefillStaminaCard(
                            actor: widget.actor,
                            staminaLimit: staminaLimit,
                            actorCost: _actorCost,
                            isLoadingPricing: _isLoadingPricing,
                            isSubmitting: isSubmitting,
                            onCancel: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(false),
                            onConfirm: canRefill ? _refillActor : null,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单角色体力恢复确认卡片；展示层独立，便于视觉与交互测试。
class AgentV2RefillStaminaCard extends StatelessWidget {
  final MiningActor actor;
  final int? staminaLimit;
  final double? actorCost;
  final bool isLoadingPricing;
  final bool isSubmitting;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  const AgentV2RefillStaminaCard({
    super.key,
    required this.actor,
    required this.staminaLimit,
    required this.actorCost,
    required this.isLoadingPricing,
    required this.isSubmitting,
    this.onCancel,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final confirmBackground = StoryColors.actorSignSheetConfirmBgOf(brightness);
    final confirmForeground = StoryColors.actorSignSheetConfirmFgOf(brightness);
    final disabledForeground = StoryColors.buttonDisabledForegroundOf(
      brightness,
    );
    final actorName = actor.displayName.isEmpty ? '-' : actor.displayName;
    final actorMeta = actor.level == null
        ? actorName
        : '$actorName · Lv${actor.level}';
    final currentStamina = actor.stamina ?? 0;
    final staminaLimitLabel = staminaLimit?.toString() ?? '--';
    final actorCostLabel = actorCost == null
        ? '-'
        : '${actorCost!.toStringAsFixed(1)} ${context.l10n.currency}';

    return Material(
      key: const ValueKey('agent-v2-refill-dialog'),
      color: StoryColors.cardOf(brightness),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.gameRefillTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 26 / 18,
                    letterSpacing: -0.04,
                  ),
                ),
                const SizedBox(height: StorySpacing.xs),
                Text(
                  actorMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                    letterSpacing: 0.04,
                  ),
                ),
              ],
            ),
            const SizedBox(height: StorySpacing.xl),
            DecoratedBox(
              decoration: BoxDecoration(
                color: StoryColors.brandTealRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StorySpacing.base,
                  vertical: StorySpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$currentStamina/$staminaLimitLabel → '
                      '$staminaLimitLabel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 26 / 18,
                        letterSpacing: -0.04,
                      ),
                    ),
                    if (isLoadingPricing)
                      const SizedBox(
                        key: ValueKey('agent-v2-refill-pricing-loading'),
                        height: 26,
                        child: Center(
                          child: SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      Text(
                        '${context.l10n.agentV2RefillCost} $actorCostLabel',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: StoryColors.brandTealRed,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 26 / 18,
                          letterSpacing: -0.04,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      key: const ValueKey('agent-v2-refill-cancel-button'),
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: foreground,
                        disabledForegroundColor: disabledForeground,
                        side: BorderSide(
                          color: StoryColors.actorSignSheetCancelBorderOf(
                            brightness,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.l10n.commonCancel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: StorySpacing.md),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      key: const ValueKey('agent-v2-refill-confirm-button'),
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmBackground,
                        foregroundColor: confirmForeground,
                        disabledBackgroundColor: isSubmitting
                            ? confirmBackground
                            : StoryColors.mutedOf(brightness),
                        disabledForegroundColor: isSubmitting
                            ? confirmForeground
                            : disabledForeground,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? SizedBox.square(
                              key: const ValueKey(
                                'agent-v2-refill-confirm-loading',
                              ),
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: confirmForeground,
                              ),
                            )
                          : Text(
                              context.l10n.commonConfirm,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 20 / 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 挖矿卡片使用的旧版补充体力弹窗，保留单个补充和全部补充两个入口。
class _AgentV2BatchRefillStaminaCard extends StatelessWidget {
  final MiningActor actor;
  final int? staminaLimit;
  final double? actorCost;
  final int allActorCount;
  final double allActorCost;
  final bool isLoadingPricing;
  final bool isSubmitting;
  final bool isSubmittingAll;
  final bool isLoadingAllActors;
  final bool didFailLoadingAllActors;
  final VoidCallback? onRefillActor;
  final VoidCallback? onRefillAll;
  final VoidCallback? onRetryAllActors;

  const _AgentV2BatchRefillStaminaCard({
    required this.actor,
    required this.staminaLimit,
    required this.actorCost,
    required this.allActorCount,
    required this.allActorCost,
    required this.isLoadingPricing,
    required this.isSubmitting,
    required this.isSubmittingAll,
    required this.isLoadingAllActors,
    required this.didFailLoadingAllActors,
    this.onRefillActor,
    this.onRefillAll,
    this.onRetryAllActors,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final mutedBackground = StoryColors.mutedOf(brightness);
    final lineColor = StoryColors.borderOf(brightness);
    final buttonBackground = StoryColors.actorSignSheetConfirmBgOf(brightness);
    final buttonForeground = StoryColors.actorSignSheetConfirmFgOf(brightness);
    final actorName = actor.displayName.isEmpty ? '-' : actor.displayName;
    final actorMeta = actor.level == null
        ? actorName
        : '$actorName · Lv${actor.level}';
    final stamina = actor.stamina?.toString() ?? '-';
    final staminaLimitLabel = staminaLimit?.toString() ?? '--';
    final actorCostLabel = actorCost == null
        ? '-'
        : '${actorCost!.toStringAsFixed(1)} ${context.l10n.currency}';
    final allActorCostLabel =
        '${allActorCost.toStringAsFixed(1)} ${context.l10n.currency}';

    return Material(
      key: const ValueKey('agent-v2-refill-dialog'),
      color: StoryColors.cardOf(brightness),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.agentV2RefillTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 26 / 18,
                letterSpacing: -0.04,
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            _RefillChoice(
              backgroundColor: mutedBackground,
              lineColor: lineColor,
              topLeft: actorMeta,
              topRight: '$stamina/$staminaLimitLabel → $staminaLimitLabel',
              bottomLeft: context.l10n.agentV2RefillCost,
              bottomRight: isLoadingPricing ? null : actorCostLabel,
              bottomRightChild: isLoadingPricing
                  ? const SizedBox.square(
                      key: ValueKey('agent-v2-refill-pricing-loading'),
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            const SizedBox(height: StorySpacing.md),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                key: const ValueKey('agent-v2-refill-actor-button'),
                onPressed: isSubmitting ? null : onRefillActor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBackground,
                  foregroundColor: buttonForeground,
                  disabledBackgroundColor: buttonBackground,
                  disabledForegroundColor: buttonForeground,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? SizedBox.square(
                        key: const ValueKey('agent-v2-refill-actor-loading'),
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: buttonForeground,
                        ),
                      )
                    : Text(
                        context.l10n.agentV2RefillActorButton,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: StorySpacing.base),
            Row(
              children: [
                Expanded(child: Divider(height: 1, color: lineColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StorySpacing.base,
                  ),
                  child: Text(
                    context.l10n.agentV2RefillOr,
                    style: TextStyle(
                      color: StoryColors.mutedForegroundOf(brightness),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                      letterSpacing: 0.04,
                    ),
                  ),
                ),
                Expanded(child: Divider(height: 1, color: lineColor)),
              ],
            ),
            const SizedBox(height: StorySpacing.base),
            _RefillChoice(
              backgroundColor: mutedBackground,
              lineColor: lineColor,
              topLeft: context.l10n.agentV2RefillAllActors,
              bottomLeft: didFailLoadingAllActors
                  ? context.l10n.commonLoadFailed
                  : context.l10n.agentV2RefillActorCount(allActorCount),
              bottomRight: isLoadingAllActors || didFailLoadingAllActors
                  ? null
                  : allActorCostLabel,
              bottomRightChild: isLoadingAllActors
                  ? const SizedBox.square(
                      key: ValueKey('agent-v2-refill-all-loading'),
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : didFailLoadingAllActors
                  ? IconButton(
                      key: const ValueKey('agent-v2-refill-all-retry'),
                      onPressed: onRetryAllActors,
                      tooltip: context.l10n.commonRetry,
                      icon: const Icon(Icons.refresh, size: 20),
                      visualDensity: VisualDensity.compact,
                    )
                  : null,
            ),
            const SizedBox(height: StorySpacing.md),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                key: const ValueKey('agent-v2-refill-all-button'),
                onPressed: isSubmitting || isSubmittingAll ? null : onRefillAll,
                style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(foreground),
                  side: WidgetStatePropertyAll(
                    BorderSide(color: StoryColors.dividerOf(brightness)),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: isSubmittingAll
                    ? SizedBox.square(
                        key: const ValueKey('agent-v2-refill-all-submitting'),
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : Text(
                        context.l10n.agentV2RefillAllButton,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefillChoice extends StatelessWidget {
  final Color backgroundColor;
  final Color lineColor;
  final String topLeft;
  final String? topRight;
  final String bottomLeft;
  final String? bottomRight;
  final Widget? bottomRightChild;

  const _RefillChoice({
    required this.backgroundColor,
    required this.lineColor,
    required this.topLeft,
    this.topRight,
    required this.bottomLeft,
    this.bottomRight,
    this.bottomRightChild,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = StoryColors.foregroundOf(Theme.of(context).brightness);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.base,
          vertical: StorySpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    topLeft,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                    ),
                  ),
                ),
                if (topRight != null) ...[
                  const SizedBox(width: StorySpacing.sm),
                  Text(
                    topRight!,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: StorySpacing.sm),
            Divider(height: 1, thickness: 0.5, color: lineColor),
            const SizedBox(height: StorySpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    bottomLeft,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 24 / 16,
                    ),
                  ),
                ),
                const SizedBox(width: StorySpacing.sm),
                if (bottomRightChild != null)
                  bottomRightChild!
                else if (bottomRight != null)
                  Text(
                    bottomRight!,
                    style: const TextStyle(
                      color: StoryColors.brandTealRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 24 / 16,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
