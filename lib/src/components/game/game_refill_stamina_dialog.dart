import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/story_l10n.dart';
import '../../widgets/error_handler.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../utils/wallet_balance_gate.dart';
import '../common/story_toast.dart';

Future<bool> showGameRefillStaminaDialog(
  BuildContext context,
  WidgetRef ref,
  MiningActor actor,
) async {
  final didRefill = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: StoryColors.overlayMedium,
    builder: (ctx) => _GameRefillStaminaDialog(actor: actor),
  );

  if (didRefill != true) return false;

  // Wait until the bottom sheet route is fully dismissed before showing the
  // toast and triggering follow-up refreshes. This also prevents a toast
  // failure from skipping the route pop after an on-chain success.
  if (context.mounted) {
    StoryToast.success(context, context.l10n.gameRefillSuccess);
    ref.read(incomeControllerProvider.notifier).refresh();
    ref.read(onChainWalletBalanceProvider.notifier).refresh();
  }
  return true;
}

class _GameRefillStaminaDialog extends ConsumerStatefulWidget {
  final MiningActor actor;

  const _GameRefillStaminaDialog({required this.actor});

  @override
  ConsumerState<_GameRefillStaminaDialog> createState() =>
      _GameRefillStaminaDialogState();
}

class _GameRefillStaminaDialogState
    extends ConsumerState<_GameRefillStaminaDialog> {
  bool _isSubmitting = false;

  Future<void> _handleConfirm() async {
    final l10n = context.l10n;
    final gameState = ref.read(gameControllerProvider);
    final notifier = ref.read(gameControllerProvider.notifier);
    final actor = widget.actor;

    if (_isSubmitting ||
        gameState.isActionLoading ||
        actor.nftId.isEmpty ||
        actor.actorTokenId == null ||
        actor.isStaminaFull(gameState.staminaLimit)) {
      return;
    }

    final payAmount = notifier.supplyFeeForLevel(actor.level);
    if (payAmount == null) return;

    setState(() => _isSubmitting = true);
    var didClose = false;

    try {
      final okBalance = await ensureUsdcBalanceOrShowDialog(
        ref,
        context,
        payAmount,
      );
      if (!okBalance || !mounted) return;

      final ok = await notifier.replenishStamina(actor);
      if (!mounted) return;

      if (ok) {
        // Return the result through the sheet route. The launcher handles the
        // success toast and refreshes only after this route has been dismissed.
        didClose = true;
        Navigator.of(context).pop(true);
        return;
      }

      ref.read(onChainWalletBalanceProvider.notifier).refresh();

      final err = ref.read(gameControllerProvider).lastError;
      if (err != null) {
        handleApiError(err, ctx: context);
      } else {
        StoryToast.error(context, l10n.gameRefillFailed);
      }
    } finally {
      if (mounted && !didClose) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isActionLoading = ref.watch(
      gameControllerProvider.select((s) => s.isActionLoading),
    );
    final staminaLimit = ref.watch(
      gameControllerProvider.select((s) => s.staminaLimit),
    );
    final notifier = ref.read(gameControllerProvider.notifier);
    final actor = widget.actor;
    final stamina = actor.stamina;
    final payAmount = notifier.supplyFeeForLevel(actor.level);
    final isStaminaFull = actor.isStaminaFull(staminaLimit);
    final isPending = _isSubmitting || isActionLoading;

    final actorName = actor.displayName;
    final actorCode = actor.actorCode;
    final staminaLabel = stamina != null ? '$stamina / $staminaLimit' : '-';
    final compactStaminaLabel = stamina != null
        ? '$stamina/$staminaLimit'
        : '-';
    final costLabel = payAmount != null
        ? '${payAmount.toStringAsFixed(1)} ${l10n.currency}'
        : '-';
    final canConfirm =
        !isStaminaFull &&
        payAmount != null &&
        actor.nftId.isNotEmpty &&
        actor.actorTokenId != null &&
        !isPending;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.backgroundOf(theme.brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 24,
            child: Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? StoryColors.darkMuted
                      : const Color(0xFFF0F0F3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: StorySpacing.base),
          Padding(
            padding: EdgeInsets.only(
              left: StorySpacing.base,
              right: StorySpacing.base,
              bottom: StorySpacing.base + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.gameRefillTitle,
                  textAlign: TextAlign.center,
                  style:
                      StoryTextStyles.titleMedium(
                        color: StoryColors.foregroundOf(theme.brightness),
                      ).copyWith(
                        fontSize: 18,
                        height: 26 / 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: StorySpacing.base),
                Container(
                  constraints: const BoxConstraints(minHeight: 78),
                  padding: const EdgeInsets.all(StorySpacing.base),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? StoryColors.darkMuted
                        : const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (actorName.isNotEmpty)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: actorName,
                                style: StoryTextStyles.titleMedium(
                                  color: StoryColors.foregroundOf(
                                    theme.brightness,
                                  ),
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (actorCode != null)
                                TextSpan(
                                  text: ' $actorCode',
                                  style: StoryTextStyles.bodySmall(
                                    color: StoryColors.mutedForegroundOf(
                                      theme.brightness,
                                    ),
                                  ).copyWith(fontWeight: FontWeight.w400),
                                ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 16,
                            color: StoryColors.brandTeal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            compactStaminaLabel,
                            style: StoryTextStyles.bodySmall(
                              color: StoryColors.mutedForegroundOf(
                                theme.brightness,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: StorySpacing.base),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: StorySpacing.base,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: StoryColors.brandTeal.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: StoryColors.brandTeal.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: l10n.gameRefillCurrentStamina,
                        value: staminaLabel,
                      ),
                      Divider(
                        color: StoryColors.brandTeal.withValues(alpha: 0.16),
                        height: 4,
                        thickness: 0.5,
                      ),
                      _DetailRow(label: l10n.gameRefillCost, value: costLabel),
                    ],
                  ),
                ),
                const SizedBox(height: StorySpacing.xl),
                Row(
                  children: [
                    SizedBox(
                      width: 92,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: isPending
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: Color(0xFFD9D9E0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.commonCancel,
                          style: StoryTextStyles.bodyMedium(
                            color: StoryColors.foregroundOf(theme.brightness),
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: canConfirm ? _handleConfirm : null,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: const Color(0xFF212225),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isPending
                                ? const Color(0xFF3C3D41)
                                : null,
                            disabledForegroundColor: isPending
                                ? Colors.white
                                : null,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isPending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.gameRefillConfirm,
                                  style: StoryTextStyles.bodyMedium(
                                    color: Colors.white,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Text(
            label,
            style: StoryTextStyles.bodyMedium(
              color: StoryColors.mutedForegroundOf(
                Theme.of(context).brightness,
              ),
            ).copyWith(fontSize: 13, height: 18 / 13),
          ),
          const Spacer(),
          Text(
            value,
            style: StoryTextStyles.bodyMedium(
              color: const Color(0xFF0F7F81),
            ).copyWith(fontSize: 13, height: 18 / 13),
          ),
        ],
      ),
    );
  }
}
