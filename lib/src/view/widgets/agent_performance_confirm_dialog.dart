import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/common/story_toast.dart';
import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../utils/mining_power.dart';
import '../../widgets/error_handler.dart';

/// Figma `970:121111` / `970:121130`：安排演出确认弹窗（含片酬为 0 警示）。
Future<bool?> showAgentPerformanceConfirmDialog(
  BuildContext context,
  WidgetRef ref,
  MiningActor actor, {
  required bool hasVacantSlot,
  VoidCallback? onScheduled,
}) {
  if (!hasVacantSlot) {
    StoryToast.error(context, context.l10n.agentV2PerformanceSlotsFull);
    return Future.value();
  }

  return showGeneralDialog<bool>(
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
        _PerformanceConfirmRoute(actor: actor, onScheduled: onScheduled),
  );
}

class _PerformanceConfirmRoute extends ConsumerWidget {
  final MiningActor actor;
  final VoidCallback? onScheduled;

  const _PerformanceConfirmRoute({required this.actor, this.onScheduled});

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    if ((actor.stamina ?? 0) <= 0) {
      StoryToast.error(context, context.l10n.gameDeployStaminaDepleted);
      return;
    }

    final success = await ref
        .read(agentV2CandidateActorsControllerProvider.notifier)
        .schedulePerformance(actor.nftId);
    if (!context.mounted) return;

    if (success) {
      onScheduled?.call();
      StoryToast.success(
        context,
        context.l10n.agentV2PerformanceScheduledSuccess,
      );
      Navigator.of(context).pop(true);
      return;
    }

    final error = ref
        .read(agentV2CandidateActorsControllerProvider)
        .actionError;
    if (error != null) {
      handleApiError(error, ctx: context, rootOverlay: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      agentV2CandidateActorsControllerProvider.select(
        (state) => state.isSubmitting(actor.nftId),
      ),
    );

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
                    child: _PerformanceConfirmCard(
                      actor: actor,
                      isSubmitting: isSubmitting,
                      onCancel: () => Navigator.of(context).pop(false),
                      onConfirm: () => _confirm(context, ref),
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

class _PerformanceConfirmCard extends StatelessWidget {
  final MiningActor actor;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _PerformanceConfirmCard({
    required this.actor,
    required this.isSubmitting,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final cardBackground = brightness == Brightness.dark
        ? StoryColors.darkMuted
        : StoryColors.lightMuted;
    final confirmBackground = StoryColors.actorSignSheetConfirmBgOf(brightness);
    final confirmForeground = StoryColors.actorSignSheetConfirmFgOf(brightness);
    final actorName = actor.displayName.isEmpty ? '-' : actor.displayName;
    final actorCode = actor.actorCode;
    final levelLabel = _buildLevelLabel(context, actor.level);
    // 对齐 Web：每小时片酬真实为 0 时走红色警示文案（Figma 970:121111）
    final isZeroFee = getMiningActorHourlySalary(actor) == 0;

    return Material(
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
              l10n.agentV2PerformanceConfirmTitle,
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
            DecoratedBox(
              decoration: BoxDecoration(
                color: cardBackground,
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
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: actorName,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 26 / 18,
                              letterSpacing: -0.04,
                            ),
                          ),
                          if (actorCode != null)
                            TextSpan(
                              text: ' $actorCode',
                              style: TextStyle(
                                color: foreground,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                height: 26 / 18,
                                letterSpacing: -0.04,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (levelLabel.isNotEmpty) ...[
                      const SizedBox(height: StorySpacing.xs),
                      Text(
                        levelLabel,
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
                    const SizedBox(height: StorySpacing.base),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: StoryColors.dividerOf(brightness),
                    ),
                    const SizedBox(height: StorySpacing.base),
                    if (isZeroFee)
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: secondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 18 / 13,
                          ),
                          children: [
                            TextSpan(
                              text: l10n.agentV2PerformanceZeroFeePrefix,
                            ),
                            TextSpan(
                              text: l10n.agentV2PerformanceZeroFeeHighlight,
                              style: const TextStyle(
                                color: StoryColors.brandTealRed,
                              ),
                            ),
                            TextSpan(
                              text: l10n.agentV2PerformanceZeroFeeSuffix,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      Text(
                        l10n.agentV2PerformanceConfirmDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 18 / 13,
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
                      onPressed: isSubmitting ? null : onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: foreground,
                        disabledForegroundColor: foreground.withValues(
                          alpha: 0.4,
                        ),
                        side: BorderSide(
                          color: StoryColors.dividerOf(brightness),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.commonCancel,
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
                      key: const ValueKey(
                        'agent-v2-performance-confirm-button',
                      ),
                      onPressed: isSubmitting ? null : onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmBackground,
                        foregroundColor: confirmForeground,
                        disabledBackgroundColor: confirmBackground,
                        disabledForegroundColor: confirmForeground,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                key: const ValueKey(
                                  'agent-v2-performance-confirm-loading',
                                ),
                                strokeWidth: 2,
                                color: confirmForeground,
                              ),
                            )
                          : Text(
                              l10n.commonConfirm,
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

String _buildLevelLabel(BuildContext context, int? level) {
  if (level == null) return '';
  final levelName = switch (level) {
    1 => context.l10n.gameActorLevelName1,
    2 => context.l10n.gameActorLevelName2,
    3 => context.l10n.gameActorLevelName3,
    4 => context.l10n.gameActorLevelName4,
    5 => context.l10n.gameActorLevelName5,
    _ => null,
  };
  return levelName == null || levelName.isEmpty
      ? 'Lv$level'
      : '$levelName · Lv$level';
}
