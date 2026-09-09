import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/story_toast.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/format_number.dart';
import '../../../widgets/error_handler.dart';
import 'agent_v3_purchase_sheet.dart';

const _staminaPackAsset = 'assets/game_v3/agent_token_story.png';

enum _RefillDialogAction { purchase }

/// Figma `2620:133148` — single-actor stamina-pack refill dialog.
Future<StaminaRefillResult?> showAgentV3RefillStaminaDialog(
  BuildContext context,
  WidgetRef ref,
  MiningActor actor,
) async {
  while (context.mounted) {
    final state = ref.read(agentV3ControllerProvider);
    final packCost = state.actorNftConfig?.staminaPackAmountForLevel(
      actor.level,
    );
    if (packCost == null || packCost <= 0) {
      StoryToast.error(context, context.l10n.agentV3RefillConfigUnavailable);
      return null;
    }

    final dialogResult = await showDialog<Object?>(
      context: context,
      barrierDismissible: false,
      barrierColor: StoryColors.overlayMid,
      builder: (_) =>
          _AgentV3RefillStaminaDialog(actor: actor, packCost: packCost),
    );
    if (!context.mounted) return null;
    if (dialogResult is StaminaRefillResult) {
      StoryToast.success(context, context.l10n.agentV3RefillSuccess);
      return dialogResult;
    }
    if (dialogResult != _RefillDialogAction.purchase) return null;

    final baseline =
        (ref.read(agentV3ControllerProvider).assets ?? UserAssets.empty)
            .staminaPack;
    final shortage = (packCost - baseline).ceil().clamp(1, 999999999);
    final submitted = await showAgentV3PurchaseSheet(
      context,
      ref,
      CardPurchaseType.energyPack,
      initialQuantity: shortage,
    );
    if (!submitted || !context.mounted) return null;

    final credited = await ref
        .read(agentV3ControllerProvider.notifier)
        .waitForPurchaseCredit(
          type: CardPurchaseType.energyPack,
          baseline: baseline,
          quantity: shortage,
        );
    if (!context.mounted) return null;
    if (!credited) {
      StoryToast.warning(context, context.l10n.agentV3PurchaseCreditPending);
      return null;
    }
    // 到账后重新读取配置与余额，再展示补充确认。
  }
  return null;
}

/// Figma `2620:133146` — 批量体力包补充弹窗。
///
/// 消耗角色与单角色费用以 `/api/mining/listActorsNeedingStaminaRefill`
/// 的实时结果为准，避免使用页面中的旧体力快照估算。
Future<StaminaRefillBatchResult?> showAgentV3RefillAllDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  while (context.mounted) {
    final actorsResult = await ref
        .read(miningRepositoryProvider)
        .listActorsNeedingStaminaRefill();
    if (!context.mounted) return null;
    if (actorsResult.isFailure) {
      handleApiError(actorsResult.errorOrNull!, ctx: context);
      return null;
    }

    final actors =
        actorsResult.dataOrNull ?? const <ActorNeedingStaminaRefill>[];
    if (actors.isEmpty) {
      StoryToast.error(context, context.l10n.agentV3RefillNoActors);
      return null;
    }

    final dialogResult = await showDialog<Object?>(
      context: context,
      barrierDismissible: false,
      barrierColor: StoryColors.overlayMid,
      builder: (_) => _AgentV3RefillAllDialog(actors: actors),
    );
    if (!context.mounted) return null;
    if (dialogResult is StaminaRefillBatchResult) {
      final refilledActorIds =
          (dialogResult.items ?? const <StaminaRefillResult>[])
              .map((item) => item.actorNftId)
              .toSet();
      final refilledActors = refilledActorIds.isEmpty
          ? actors
          : actors
                .where((actor) => refilledActorIds.contains(actor.actorNftId))
                .toList(growable: false);
      final packCount = refilledActors.fold<double>(
        0,
        (total, actor) => total + actor.supplyFee,
      );
      StoryToast.success(
        context,
        context.l10n.agentV3RefillAllSuccess(
          refilledActorIds.isEmpty ? actors.length : refilledActorIds.length,
          formatNumber(packCount),
        ),
      );
      return dialogResult;
    }
    if (dialogResult != _RefillDialogAction.purchase) return null;

    final totalCost = actors.fold<double>(
      0,
      (total, actor) => total + actor.supplyFee,
    );
    final baseline =
        (ref.read(agentV3ControllerProvider).assets ?? UserAssets.empty)
            .staminaPack;
    final shortage = (totalCost - baseline).ceil().clamp(1, 999999999);
    final submitted = await showAgentV3PurchaseSheet(
      context,
      ref,
      CardPurchaseType.energyPack,
      initialQuantity: shortage,
    );
    if (!submitted || !context.mounted) return null;

    final credited = await ref
        .read(agentV3ControllerProvider.notifier)
        .waitForPurchaseCredit(
          type: CardPurchaseType.energyPack,
          baseline: baseline,
          quantity: shortage,
        );
    if (!context.mounted) return null;
    if (!credited) {
      StoryToast.warning(context, context.l10n.agentV3PurchaseCreditPending);
      return null;
    }
    // 到账后重新拉取待补充角色，避免沿用购买前的费用快照。
  }
  return null;
}

class _AgentV3RefillAllDialog extends ConsumerStatefulWidget {
  const _AgentV3RefillAllDialog({required this.actors});

  final List<ActorNeedingStaminaRefill> actors;

  @override
  ConsumerState<_AgentV3RefillAllDialog> createState() =>
      _AgentV3RefillAllDialogState();
}

class _AgentV3RefillAllDialogState
    extends ConsumerState<_AgentV3RefillAllDialog> {
  bool _isSubmitting = false;

  double get _totalCost =>
      widget.actors.fold<double>(0, (total, actor) => total + actor.supplyFee);

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final result = await ref
        .read(agentV3ControllerProvider.notifier)
        .refillActorsWithPack(widget.actors);
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop(result.dataOrNull);
      return;
    }

    handleApiError(result.errorOrNull!, ctx: context, rootOverlay: true);
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final available = ref.watch(
      agentV3ControllerProvider.select(
        (state) => (state.assets ?? UserAssets.empty).staminaPack,
      ),
    );
    final hasEnoughPacks = available >= _totalCost;

    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        key: const ValueKey('agent-v3-refill-all-dialog'),
        elevation: 0,
        backgroundColor: StoryColors.whiteToDarkOf(brightness),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          key: const ValueKey('agent-v3-refill-all-dialog-surface'),
          width: 400,
          child: MediaQuery.withNoTextScaling(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.agentV3RefillAll,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 26 / 18,
                          letterSpacing: -0.04,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.agentV3RefillAllDescription,
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
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      Container(
                        key: const ValueKey('agent-v3-refill-all-cost'),
                        height: 57,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: StoryColors.actorSignSheetPriceCardBgOf(
                            brightness,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.l10n.agentV3RefillCost,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                height: 25 / 17,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ClipRect(
                              child: SizedBox(
                                width: 26.5,
                                height: 22,
                                child: Image.asset(
                                  _staminaPackAsset,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatNumber(_totalCost),
                              key: const ValueKey(
                                'agent-v3-refill-all-cost-value',
                              ),
                              style: TextStyle(
                                color: foreground,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                height: 25 / 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 20,
                        child: Text.rich(
                          key: const ValueKey('agent-v3-refill-all-available'),
                          TextSpan(
                            children: [
                              TextSpan(
                                text: context.l10n.agentV3RefillAvailable,
                              ),
                              const TextSpan(text: ' '),
                              TextSpan(
                                text: formatNumber(available),
                                style: hasEnoughPacks
                                    ? null
                                    : TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 20 / 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _RefillDialogButton(
                          key: const ValueKey('agent-v3-refill-all-cancel'),
                          label: context.l10n.commonCancel,
                          foregroundColor: foreground,
                          borderColor: StoryColors.dividerOf(brightness),
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RefillDialogButton(
                          key: ValueKey(
                            hasEnoughPacks
                                ? 'agent-v3-refill-all-use'
                                : 'agent-v3-refill-all-buy',
                          ),
                          label: hasEnoughPacks
                              ? context.l10n.agentV3RefillUse
                              : context.l10n.agentV3PurchaseButton,
                          foregroundColor:
                              StoryColors.actorSignSheetConfirmFgOf(brightness),
                          backgroundColor:
                              StoryColors.actorSignSheetConfirmBgOf(brightness),
                          onPressed: _isSubmitting
                              ? null
                              : hasEnoughPacks
                              ? _submit
                              : () => Navigator.of(
                                  context,
                                ).pop(_RefillDialogAction.purchase),
                          isLoading: _isSubmitting,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgentV3RefillStaminaDialog extends ConsumerStatefulWidget {
  const _AgentV3RefillStaminaDialog({
    required this.actor,
    required this.packCost,
  });

  final MiningActor actor;
  final int packCost;

  @override
  ConsumerState<_AgentV3RefillStaminaDialog> createState() =>
      _AgentV3RefillStaminaDialogState();
}

class _AgentV3RefillStaminaDialogState
    extends ConsumerState<_AgentV3RefillStaminaDialog> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final result = await ref
        .read(agentV3ControllerProvider.notifier)
        .refillStaminaWithPack(widget.actor);
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop(result.dataOrNull);
      return;
    }

    handleApiError(result.errorOrNull!, ctx: context, rootOverlay: true);
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final available = ref.watch(
      agentV3ControllerProvider.select(
        (state) => (state.assets ?? UserAssets.empty).staminaPack,
      ),
    );
    final hasEnoughPacks = available >= widget.packCost;

    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        key: const ValueKey('agent-v3-refill-dialog'),
        elevation: 0,
        backgroundColor: StoryColors.whiteToDarkOf(brightness),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          key: const ValueKey('agent-v3-refill-dialog-surface'),
          width: 400,
          child: MediaQuery.withNoTextScaling(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.agentV3RefillTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: StoryColors.foregroundOf(brightness),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 26 / 18,
                      letterSpacing: -0.04,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    key: const ValueKey('agent-v3-refill-cost'),
                    height: 57,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: StoryColors.actorSignSheetPriceCardBgOf(
                        brightness,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.l10n.agentV3RefillLevelCost(
                            '${widget.actor.level ?? '-'}',
                          ),
                          style: TextStyle(
                            color: StoryColors.foregroundOf(brightness),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 25 / 17,
                          ),
                        ),
                        const SizedBox(width: 6),
                        ClipRect(
                          child: SizedBox(
                            width: 26.5,
                            height: 22,
                            child: Image.asset(
                              _staminaPackAsset,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.packCost}',
                          style: TextStyle(
                            color: StoryColors.foregroundOf(brightness),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 25 / 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 20,
                    child: Text.rich(
                      key: const ValueKey('agent-v3-refill-available'),
                      TextSpan(
                        children: [
                          TextSpan(text: context.l10n.agentV3RefillAvailable),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: formatNumber(available),
                            style: hasEnoughPacks
                                ? null
                                : TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: StoryColors.mutedForegroundOf(brightness),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _RefillDialogButton(
                          key: const ValueKey('agent-v3-refill-cancel'),
                          label: context.l10n.commonCancel,
                          foregroundColor: StoryColors.foregroundOf(brightness),
                          borderColor: StoryColors.dividerOf(brightness),
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RefillDialogButton(
                          key: ValueKey(
                            hasEnoughPacks
                                ? 'agent-v3-refill-use'
                                : 'agent-v3-refill-buy',
                          ),
                          label: hasEnoughPacks
                              ? context.l10n.agentV3RefillUse
                              : context.l10n.agentV3PurchaseButton,
                          foregroundColor:
                              StoryColors.actorSignSheetConfirmFgOf(brightness),
                          backgroundColor:
                              StoryColors.actorSignSheetConfirmBgOf(brightness),
                          onPressed: _isSubmitting
                              ? null
                              : hasEnoughPacks
                              ? _submit
                              : () => Navigator.of(
                                  context,
                                ).pop(_RefillDialogAction.purchase),
                          isLoading: _isSubmitting,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RefillDialogButton extends StatelessWidget {
  const _RefillDialogButton({
    super.key,
    required this.label,
    required this.foregroundColor,
    this.backgroundColor = Colors.transparent,
    this.borderColor,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? borderColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor!, width: 1.5),
    );
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: Material(
        color: backgroundColor,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 44,
            child: Center(
              child: isLoading
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foregroundColor,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
