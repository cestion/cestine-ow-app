import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../utils/actor_pricing.dart';
import 'actor_price_curve_chart.dart';

/// 演员 IP 价格走势区块：标题 + 图例 + 公式 + 曲线 + 价格统计。
///
/// 用于演员详情「发行信息」Tab，布局对齐 Figma 移动端稿。
class ActorPriceTrendSection extends StatelessWidget {
  final int signedCount;
  final int maxSupply;
  final double initialPrice;
  final double currentPrice;
  final double chartHeight;

  const ActorPriceTrendSection({
    super.key,
    required this.signedCount,
    required this.maxSupply,
    required this.initialPrice,
    required this.currentPrice,
    this.chartHeight = 180,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final tailPrice = getActorBondingCurveTailPrice(
      initialPrice > 0 ? initialPrice : 0.5,
      maxSupply > 0 ? maxSupply : 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.actorBondingCurve,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
                color: StoryColors.foregroundOf(brightness),
              ),
            ),
            const SizedBox(height: StorySpacing.sm),
            Row(
              children: [
                ActorPriceCurveLegend(
                  color: StoryColors.warning,
                  label: l10n.actorPriceCurve,
                ),
                const SizedBox(width: StorySpacing.base),
                ActorPriceCurveLegend(
                  color: StoryColors.brandTeal,
                  label: l10n.actorCurrentPosition,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: StorySpacing.sm),
        Text(
          l10n.actorSignPriceFormula,
          style: const TextStyle(
            fontSize: 12,
            height: 16 / 12,
            letterSpacing: 0.04,
            color: StoryColors.brandTealDark,
          ),
        ),
        const SizedBox(height: StorySpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(StorySpacing.md),
          decoration: BoxDecoration(
            color: StoryColors.brandTeal.withValues(alpha: 0.05),
            borderRadius: StoryRadius.brMd,
          ),
          child: ActorPriceCurveChart(
            signedCount: signedCount,
            maxSupply: maxSupply,
            initialPrice: initialPrice,
            currentPrice: currentPrice,
            height: chartHeight,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: StorySpacing.md),
        ActorIssueCurvePriceStatsPanel(
          initialPrice: initialPrice,
          currentPrice: currentPrice,
          tailPrice: tailPrice,
          brightness: brightness,
        ),
      ],
    );
  }
}

/// 价格曲线图例（价格曲线 / 当前位置）。
class ActorPriceCurveLegend extends StatelessWidget {
  final Color color;
  final String label;

  const ActorPriceCurveLegend({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            letterSpacing: 0.04,
            color: StoryColors.mutedForegroundOf(brightness),
          ),
        ),
      ],
    );
  }
}

/// 曲线下方初始 / 当前 / 尾价统计，对齐 Figma 边框卡片。
class ActorIssueCurvePriceStatsPanel extends StatelessWidget {
  final double initialPrice;
  final double currentPrice;
  final double tailPrice;
  final Brightness brightness;

  const ActorIssueCurvePriceStatsPanel({
    super.key,
    required this.initialPrice,
    required this.currentPrice,
    required this.tailPrice,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labelColor = StoryColors.mutedForegroundOf(brightness);
    final valueColor = StoryColors.foregroundOf(brightness);
    final borderColor = StoryColors.borderOf(brightness);

    final rows = [
      (
        label: l10n.actorPriceStatInitialPrice,
        value: '${formatActorPriceCeilDisplay(initialPrice)} ${l10n.currency}',
      ),
      (
        label: l10n.actorPriceStatCurrentPrice,
        value: '${formatActorPriceCeilDisplay(currentPrice)} ${l10n.currency}',
      ),
      (
        label: l10n.actorPriceStatTailPrice,
        value: '${formatActorPriceCeilDisplay(tailPrice)} ${l10n.currency}',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.base,
        vertical: StorySpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: StoryRadius.brMd,
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _PriceStatRow(
              label: rows[i].label,
              value: rows[i].value,
              labelColor: labelColor,
              valueColor: valueColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _PriceStatRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              height: 12 / 10,
              letterSpacing: 0.08,
              color: labelColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.04,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
