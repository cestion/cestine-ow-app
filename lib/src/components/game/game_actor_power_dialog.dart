import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../utils/format_number.dart';
import '../../utils/mining_power.dart';

/// 角色算力详情弹窗 — 对齐 Figma `角色算力详情`（亮/暗）。
class GameActorPowerDialog {
  GameActorPowerDialog._();

  static Future<void> show({
    required BuildContext context,
    required MiningActor actor,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _GameActorPowerDialogBody(actor: actor),
    );
  }
}

class _GameActorPowerDialogBody extends StatelessWidget {
  final MiningActor actor;

  const _GameActorPowerDialogBody({required this.actor});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final breakdown = getMiningActorPowerBreakdown(actor);
    final level = actor.level;
    final name = level == null ? null : _levelName(l10n, level);
    final levelLabel = level == null
        ? null
        : (name == null ? 'Lv$level' : 'Lv$level $name');

    final fg = StoryColors.foregroundOf(brightness);
    final mutedFg = StoryColors.mutedForegroundOf(brightness);
    // Figma `--colors/page&sheet/thirdly` #f6f6f6 / dark muted surface.
    final thirdly = StoryColors.mutedOf(brightness);
    // Figma `--colors/page&sheet/secondary` #f0f0f3.
    final secondary = brightness == Brightness.dark
        ? StoryColors.darkActorHeroBadgeBg
        : StoryColors.lightActorHeroBadgeBg;

    return Dialog(
      backgroundColor: StoryColors.cardOf(brightness),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title + formula banner
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.gameActorPowerDetailTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 26 / 18,
                    letterSpacing: -0.04,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
                const SizedBox(height: StorySpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: StorySpacing.sm,
                    vertical: StorySpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.gameActorPowerFormula,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w400,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: StorySpacing.xl),
            // Breakdown blocks
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // IP power card
                    Container(
                      padding: const EdgeInsets.all(StorySpacing.md),
                      decoration: BoxDecoration(
                        color: thirdly,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DetailRow(
                            label: l10n.actorIpPower,
                            value: breakdown.ipPower.isFinite
                                ? truncatePower(
                                    breakdown.ipPower,
                                    4,
                                  ).toStringAsFixed(4)
                                : '-',
                            labelStyle: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.bold,
                              color: fg,
                            ),
                            valueStyle: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.bold,
                              color: fg,
                            ),
                          ),
                          const SizedBox(height: StorySpacing.sm),
                          _DetailRow(
                            label: l10n.actorPriceCoefficient,
                            value:
                                '× ${formatPowerFactor(breakdown.priceCoefficient)}',
                            labelStyle: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              letterSpacing: 0.04,
                              fontWeight: FontWeight.w400,
                              color: fg,
                            ),
                            valueStyle: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              letterSpacing: 0.04,
                              fontWeight: FontWeight.w500,
                              color: fg,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _DetailRow(
                            label: l10n.actorHeatCoefficient,
                            value:
                                '× ${formatHeatFactor(breakdown.heatCoefficient)}',
                            labelStyle: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              letterSpacing: 0.04,
                              fontWeight: FontWeight.w400,
                              color: fg,
                            ),
                            valueStyle: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              letterSpacing: 0.04,
                              fontWeight: FontWeight.w500,
                              color: fg,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _DetailRow(
                            label: 'Trust1',
                            value: '× ${formatTrustFactor(breakdown.trust1)}',
                            labelStyle: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              letterSpacing: 0.04,
                              fontWeight: FontWeight.w400,
                              color: fg,
                            ),
                            valueStyle: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              letterSpacing: 0.04,
                              fontWeight: FontWeight.w500,
                              color: fg,
                            ),
                          ),
                          const SizedBox(height: StorySpacing.sm),
                          Text(
                            l10n.gameActorPowerIpFormula,
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w400,
                              color: fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: StorySpacing.sm),
                    // Mining coefficient
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StorySpacing.base,
                        vertical: StorySpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: thirdly,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.gameMiningCoef,
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.bold,
                                color: fg,
                              ),
                            ),
                          ),
                          Text(
                            '× ${_oneDecimal(breakdown.miningCoefficient)}',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.bold,
                              color: fg,
                            ),
                          ),
                          if (levelLabel != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '($levelLabel)',
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                letterSpacing: 0.04,
                                fontWeight: FontWeight.w400,
                                color: mutedFg,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: StorySpacing.sm),
                    // CP / Trust2
                    Row(
                      children: [
                        Expanded(
                          child: _FactorTile(
                            label: l10n.gameCpCoefficient,
                            value: '× ${_oneDecimal(breakdown.cpCoefficient)}',
                            background: thirdly,
                            labelColor: mutedFg,
                            valueColor: fg,
                          ),
                        ),
                        const SizedBox(width: StorySpacing.sm),
                        Expanded(
                          child: _FactorTile(
                            label: l10n.gameTrust2,
                            value: '× ${formatTrustFactor(breakdown.trust2)}',
                            background: thirdly,
                            labelColor: mutedFg,
                            valueColor: fg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: StorySpacing.sm),
                    // Hourly output
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StorySpacing.base,
                        vertical: StorySpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: thirdly,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.gameActorPowerHourlyOutput,
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                letterSpacing: 0.04,
                                fontWeight: FontWeight.w400,
                                color: fg,
                              ),
                            ),
                          ),
                          Text(
                            '${formatNumber(breakdown.actorPower)} STORY',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.bold,
                              color: fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: StoryColors.borderOf(brightness)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: fg,
                ),
                child: Text(
                  l10n.commonClose,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _levelName(AppLocalizations l10n, int level) {
    switch (level) {
      case 1:
        return l10n.gameActorLevelName1;
      case 2:
        return l10n.gameActorLevelName2;
      case 3:
        return l10n.gameActorLevelName3;
      case 4:
        return l10n.gameActorLevelName4;
      case 5:
        return l10n.gameActorLevelName5;
      default:
        return null;
    }
  }

  static String _oneDecimal(double value) {
    if (!value.isFinite) return '-';
    return value.toStringAsFixed(1);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _FactorTile extends StatelessWidget {
  final String label;
  final String value;
  final Color background;
  final Color labelColor;
  final Color valueColor;

  const _FactorTile({
    required this.label,
    required this.value,
    required this.background,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.base,
        vertical: StorySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              height: 12 / 10,
              letterSpacing: 0.08,
              fontWeight: FontWeight.w400,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
