import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/format_number.dart';
import '../../../utils/mining_power.dart';

/// Figma `637:69263` / `637:75115`：角色片酬明细弹窗。
///
/// UI 隐藏 CP 系数与 Trust2；[getMiningActorPowerBreakdown] / 卡片小时片酬仍含二者。
Future<void> showAgentV2SalaryDetailDialog(
  BuildContext context,
  MiningActor actor,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, _, _) => AgentV2SalaryDetailDialog(actor: actor),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
        child: child,
      ),
    ),
  );
}

class AgentV2SalaryDetailDialog extends StatelessWidget {
  final MiningActor actor;

  const AgentV2SalaryDetailDialog({super.key, required this.actor});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // 仍走完整拆解（含 CP / Trust2），仅展示子集。
    final breakdown = getMiningActorPowerBreakdown(actor);

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: const ColoredBox(color: StoryColors.overlayMid),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
              backgroundColor: StoryColors.cardOf(brightness),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                key: const ValueKey('agent-v2-salary-detail-dialog'),
                constraints: const BoxConstraints(maxWidth: 343),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.agentV2SalaryDetailTitle,
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
                      _FormulaBanner(level: actor.level),
                      const SizedBox(height: 24),
                      _SalaryBreakdown(
                        breakdown: breakdown,
                        level: actor.level,
                      ),
                      const SizedBox(height: 24),
                      _CloseButton(onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormulaBanner extends StatelessWidget {
  final int? level;

  const _FormulaBanner({required this.level});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final formula = (level != null && level! > 1)
        ? l10n.agentV2SalaryFormulaLevel(level!)
        : l10n.agentV2SalaryFormulaLv1;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x26E50815), width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          formula,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: StoryColors.foregroundOf(brightness),
            fontSize: 12,
            height: 16 / 12,
            letterSpacing: 0.04,
          ),
        ),
      ),
    );
  }
}

class _SalaryBreakdown extends StatelessWidget {
  final ActorMiningPowerBreakdown breakdown;
  final int? level;

  const _SalaryBreakdown({required this.breakdown, required this.level});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final fg = StoryColors.foregroundOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);
    final roleName = _levelRoleName(l10n, level);
    final coefficientLabel = level == null
        ? l10n.agentV2SalaryCoefficient
        : l10n.agentV2SalaryCoefficientWithLevel(level!, roleName ?? '');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _DetailRow(
              label: l10n.agentV2SalaryLv1Pay,
              value: _formatLv1Pay(breakdown.ipPower),
              color: fg,
              valueWeight: FontWeight.w500,
            ),
            const SizedBox(height: 6),
            _DetailRow(
              label: l10n.actorPriceCoefficient,
              value: '× ${formatPowerFactor(breakdown.priceCoefficient)}',
              color: muted,
              indent: 8,
            ),
            const SizedBox(height: 6),
            _DetailRow(
              label: l10n.actorHeatCoefficient,
              value: '× ${formatHeatFactor(breakdown.heatCoefficient)}',
              color: muted,
              indent: 8,
            ),
            const SizedBox(height: 6),
            _DetailRow(
              label: coefficientLabel,
              value: '× ${_formatCoefficient(breakdown.miningCoefficient, 0)}',
              color: fg,
              valueWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final FontWeight? valueWeight;
  final double indent;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
    this.valueWeight,
    this.indent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0.04,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: valueWeight,
              height: 16 / 12,
              letterSpacing: 0.04,
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: StoryColors.dividerOf(brightness)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('agent-v2-salary-detail-close'),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              context.l10n.commonClose,
              style: TextStyle(
                color: StoryColors.foregroundOf(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 20 / 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatLv1Pay(double value) {
  if (!value.isFinite) return '-';
  if (value > 0 && value < 0.01) return '<0.01';
  return formatNumber(value);
}

String _formatCoefficient(double value, int decimals) {
  if (!value.isFinite) return '-';
  return value.toStringAsFixed(decimals);
}

String? _levelRoleName(AppLocalizations l10n, int? level) {
  return switch (level) {
    1 => l10n.gameActorLevelName1,
    2 => l10n.gameActorLevelName2,
    3 => l10n.gameActorLevelName3,
    4 => l10n.gameActorLevelName4,
    5 => l10n.gameActorLevelName5,
    _ => null,
  };
}
