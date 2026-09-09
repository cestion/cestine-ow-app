import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/story_l10n.dart';
import '../../model/init_config_model.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../utils/actor_pay_upgrade.dart';
import '../../utils/actor_pricing.dart';
import '../../utils/format_number.dart';
import '../../utils/mining_power.dart';
import '../../widgets/widgets.dart';
import 'actor_price_curve_chart.dart';

/// Info dialog explaining "完播" (completion count).
class CompletionInfoDialog {
  CompletionInfoDialog._();

  static Future<void> show(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return StoryInfoDialog.show(
      context: context,
      title: l10n.actorStatCompletionTitle,
      actionLabel: l10n.commonOk,
      content: Text(
        l10n.actorStatCompletionDesc,
        textAlign: TextAlign.center,
        style: StoryTextStyles.bodyMedium(
          color: StoryColors.mutedForegroundOf(theme.brightness),
        ),
      ),
    );
  }
}

/// Info dialog explaining "热度系数" (heat value).
class HeatInfoDialog {
  HeatInfoDialog._();

  static Future<void> show(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return StoryInfoDialog.show(
      context: context,
      title: l10n.actorStatHeatTitle,
      actionLabel: l10n.commonOk,
      content: Text(
        l10n.actorStatHeatDesc,
        textAlign: TextAlign.center,
        style: StoryTextStyles.bodyMedium(
          color: StoryColors.mutedForegroundOf(theme.brightness),
        ),
      ),
    );
  }
}

/// Price coefficient rules dialog (create-actor / sign sheet).
class PriceCoefficientInfoDialog {
  PriceCoefficientInfoDialog._();

  static Future<void> show(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    return StoryInfoDialog.show(
      context: context,
      title: l10n.actorPriceCoefficient,
      subtitle: l10n.actorIpPowerFormula,
      actionLabel: l10n.commonOk,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PowerFactorCard(
            brightness: brightness,
            label: l10n.actorPriceCoefficientDialogTitleLe100(l10n.currency),
            value: l10n.actorPriceCoefficientDialogFormulaLe100,
            description: l10n.actorPriceCoefficientDialogDescLe100,
            valueIsFormula: true,
          ),
          const SizedBox(height: StorySpacing.sm),
          _PowerFactorCard(
            brightness: brightness,
            label: l10n.actorPriceCoefficientDialogTitleGt100(l10n.currency),
            value: l10n.actorPriceCoefficientDialogFormulaGt100,
            description: l10n.actorPriceCoefficientDialogDescGt100,
            valueIsFormula: true,
          ),
        ],
      ),
    );
  }
}

/// 「最高」片酬升级规则弹窗（Figma 655:149477 / 655:149441）。
class PayUpgradeRulesDialog {
  PayUpgradeRulesDialog._();

  static Future<void> show({
    required BuildContext context,
    required int completedViewCount,
    InitActorNftConfig? actorNft,
  }) {
    final l10n = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (ctx) => _IpPayInfoDialog(
        title: l10n.actorPayUpgradeTitle,
        actionLabel: l10n.gameStaminaMechanismAction,
        content: _PayUpgradeRulesBody(
          l10n: l10n,
          locale: Localizations.localeOf(ctx).toLanguageTag(),
          completedViewCount: completedViewCount,
          actorNft: actorNft,
        ),
      ),
    );
  }
}

/// Lv.1 片酬拆解弹窗（Figma 655:148843 / 655:148871）。
class IpPowerInfoDialog {
  IpPowerInfoDialog._();

  static Future<void> show({
    required BuildContext context,
    required String actorName,
    required ActorIpPowerBreakdown breakdown,
  }) {
    final l10n = context.l10n;
    final name = actorName.trim().isEmpty
        ? l10n.commonUntitled
        : actorName.trim();
    return showDialog<void>(
      context: context,
      builder: (ctx) => _IpPayInfoDialog(
        title: l10n.actorPayTitle(name),
        actionLabel: l10n.commonClose,
        content: _IpPayDialogBody(l10n: l10n, breakdown: breakdown),
      ),
    );
  }
}

class _IpPayInfoDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String actionLabel;

  const _IpPayInfoDialog({
    required this.title,
    required this.content,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);

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
            Text(
              title,
              textAlign: TextAlign.center,
              style:
                  StoryTextStyles.headingMedium(
                    color: fg,
                    brightness: brightness,
                  ).copyWith(
                    fontSize: 18,
                    height: 26 / 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.04,
                  ),
            ),
            const SizedBox(height: StorySpacing.xl),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.8,
              ),
              child: SingleChildScrollView(child: content),
            ),
            const SizedBox(height: StorySpacing.xl),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: BorderSide(color: StoryColors.dividerOf(brightness)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: fg,
              ),
              child: Text(
                actionLabel,
                style: StoryTextStyles.bodyMedium(
                  color: fg,
                  brightness: brightness,
                ).copyWith(fontWeight: FontWeight.w700, height: 20 / 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayUpgradeRulesBody extends StatelessWidget {
  final AppLocalizations l10n;
  final String locale;
  final int completedViewCount;
  final InitActorNftConfig? actorNft;

  const _PayUpgradeRulesBody({
    required this.l10n,
    required this.locale,
    required this.completedViewCount,
    this.actorNft,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final mutedFg = StoryColors.mutedForegroundOf(brightness);
    final tiers = listPayUpgradeTiers(actorNft);
    final reachable = reachablePayLevel(completedViewCount, tiers: tiers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(StorySpacing.md),
          decoration: BoxDecoration(
            color: StoryColors.mutedOf(brightness),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                l10n.actorPayUpgradeReachHint,
                textAlign: TextAlign.center,
                style: StoryTextStyles.bodySmall(
                  color: mutedFg,
                  brightness: brightness,
                ).copyWith(height: 16 / 12, letterSpacing: 0.04),
              ),
              const SizedBox(height: 6),
              Text(
                'Lv.$reachable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 25 / 17,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: StorySpacing.xl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(StorySpacing.md),
          decoration: BoxDecoration(
            color: StoryColors.mutedOf(brightness),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (var i = 0; i < tiers.length; i++) ...[
                if (i > 0) const SizedBox(height: StorySpacing.sm),
                _PayUpgradeTierRow(
                  tier: tiers[i],
                  highlighted: tiers[i].level == reachable,
                  locale: locale,
                  l10n: l10n,
                  brightness: brightness,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PayUpgradeTierRow extends StatelessWidget {
  final ActorPayUpgradeTier tier;
  final bool highlighted;
  final String locale;
  final AppLocalizations l10n;
  final Brightness brightness;

  const _PayUpgradeTierRow({
    required this.tier,
    required this.highlighted,
    required this.locale,
    required this.l10n,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final fg = StoryColors.foregroundOf(brightness);
    final mutedFg = StoryColors.mutedForegroundOf(brightness);
    final count = formatPayUpgradeCompletionCount(
      tier.completionThreshold,
      locale: locale,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? StoryColors.sheetSecondaryOf(brightness) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Lv.${tier.level}',
                style:
                    StoryTextStyles.bodySmall(
                      color: fg,
                      brightness: brightness,
                    ).copyWith(
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                      letterSpacing: 0.04,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                l10n.actorPayUpgradeCompletions(count),
                textAlign: TextAlign.center,
                style: StoryTextStyles.bodySmall(
                  color: mutedFg,
                  brightness: brightness,
                ).copyWith(height: 16 / 12, letterSpacing: 0.04),
              ),
            ),
            Expanded(
              child: Text(
                l10n.actorPayUpgradeMultiplier(
                  formatPayUpgradeMultiplier(tier.multiplier),
                ),
                textAlign: TextAlign.right,
                style:
                    StoryTextStyles.bodySmall(
                      color: fg,
                      brightness: brightness,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      height: 16 / 12,
                      letterSpacing: 0.04,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lv.1 片酬拆解（Figma 655:148843 / 655:148871；对齐 Web ActorLv1RateDialog）。
/// Trust1 仍参与 `ipPower` 计算，但不单独展示因子卡。
class _IpPayDialogBody extends StatelessWidget {
  final AppLocalizations l10n;
  final ActorIpPowerBreakdown breakdown;

  const _IpPayDialogBody({required this.l10n, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PaySummaryCard(l10n: l10n, brightness: brightness),
        const SizedBox(height: StorySpacing.xl),
        _PayFactorCard(
          brightness: brightness,
          label: l10n.actorPriceCoefficient,
          value: '× ${formatPowerFactor(breakdown.priceCoefficient)}',
          description: l10n.actorPriceCoefficientFactorDesc(
            l10n.currency,
            l10n.currency,
          ),
        ),
        const SizedBox(height: StorySpacing.sm),
        _PayFactorCard(
          brightness: brightness,
          label: l10n.actorHeatCoefficient,
          value: '× ${formatHeatFactor(breakdown.heatCoefficient)}',
          description: l10n.actorHeatCoefficientFactorDesc,
        ),
      ],
    );
  }
}

class _PaySummaryCard extends StatelessWidget {
  final AppLocalizations l10n;
  final Brightness brightness;

  const _PaySummaryCard({required this.l10n, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StorySpacing.md),
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            l10n.actorLv1PayHint,
            textAlign: TextAlign.center,
            style: StoryTextStyles.bodySmall(
              color: StoryColors.mutedForegroundOf(brightness),
              brightness: brightness,
            ).copyWith(height: 16 / 12, letterSpacing: 0.04),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.actorLv1PayFormula,
            textAlign: TextAlign.center,
            style:
                StoryTextStyles.bodySmall(
                  color: StoryColors.foregroundOf(brightness),
                  brightness: brightness,
                ).copyWith(
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                  letterSpacing: 0.04,
                ),
          ),
        ],
      ),
    );
  }
}

class _PayFactorCard extends StatelessWidget {
  final Brightness brightness;
  final String label;
  final String value;
  final String description;

  const _PayFactorCard({
    required this.brightness,
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final fg = StoryColors.foregroundOf(brightness);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StorySpacing.md),
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: StoryTextStyles.bodyMedium(
                    color: fg,
                    brightness: brightness,
                  ).copyWith(fontWeight: FontWeight.w700, height: 20 / 14),
                ),
              ),
              Text(
                value,
                style: StoryTextStyles.bodyMedium(
                  color: StoryColors.brandTealRed,
                  brightness: brightness,
                ).copyWith(fontWeight: FontWeight.w700, height: 20 / 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style:
                StoryTextStyles.caption(
                  color: StoryColors.mutedForegroundOf(brightness),
                  brightness: brightness,
                ).copyWith(
                  fontSize: 10,
                  height: 12 / 10,
                  letterSpacing: 0.08,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ],
      ),
    );
  }
}

class _PowerFactorCard extends StatelessWidget {
  final Brightness brightness;
  final String label;
  final String value;
  final String description;
  final bool valueIsFormula;

  const _PowerFactorCard({
    required this.brightness,
    required this.label,
    required this.value,
    required this.description,
    this.valueIsFormula = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StorySpacing.md),
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (valueIsFormula) ...[
            Text(
              label,
              style: StoryTextStyles.bodyMedium(
                color: StoryColors.foregroundOf(brightness),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: StoryTextStyles.bodyMedium(
                color: StoryColors.foregroundOf(brightness),
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: StoryTextStyles.bodyMedium(
                      color: StoryColors.foregroundOf(brightness),
                    ),
                  ),
                ),
                Text(
                  value,
                  style: StoryTextStyles.bodyMedium(
                    color: StoryColors.foregroundOf(brightness),
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          const SizedBox(height: StorySpacing.xs),
          Text(
            description,
            style: StoryTextStyles.bodySmall(
              color: StoryColors.mutedForegroundOf(brightness),
            ),
          ),
        ],
      ),
    );
  }
}

/// Info dialog showing price details for fixed or bonding-curve pricing.
class PriceInfoDialog {
  PriceInfoDialog._();

  static Future<void> show({
    required BuildContext context,
    required String? pricingMode,
    required int signedCount,
    required int maxSupply,
    required double initialPrice,
    required double currentPrice,
  }) {
    final l10n = context.l10n;
    final isFixed = isFixedActorPricingMode(pricingMode);
    final chartInitialPrice = initialPrice > 0 ? initialPrice : 0.5;
    final chartMaxSupply = maxSupply > 0 ? maxSupply : 5000;
    final chartCurrentPrice = currentPrice > 0
        ? currentPrice
        : getActorBondingCurvePrice(
            chartInitialPrice,
            signedCount,
            chartMaxSupply,
          );
    final tailPrice = getActorBondingCurveTailPrice(
      chartInitialPrice,
      chartMaxSupply,
    );
    final remainingCount = (chartMaxSupply - signedCount).clamp(
      0,
      chartMaxSupply,
    );

    return showDialog<void>(
      context: context,
      builder: (ctx) => _ActorPriceInfoDialog(
        title: isFixed ? l10n.actorPricingFixed : l10n.actorSignPriceLabel,
        subtitle: isFixed
            ? l10n.actorFixedPriceDialogDesc
            : l10n.actorSignPriceDescription,
        actionLabel: l10n.commonOk,
        content: isFixed
            ? _FixedPriceDialogBody(l10n: l10n)
            : _CurvePriceDialogBody(
                l10n: l10n,
                signedCount: signedCount,
                chartMaxSupply: chartMaxSupply,
                chartInitialPrice: chartInitialPrice,
                chartCurrentPrice: chartCurrentPrice,
                tailPrice: tailPrice,
                remainingCount: remainingCount,
              ),
      ),
    );
  }
}

class _ActorPriceInfoDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget content;
  final String actionLabel;

  const _ActorPriceInfoDialog({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);

    return Dialog(
      backgroundColor: StoryColors.cardOf(brightness),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: StorySpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style:
                  StoryTextStyles.headingMedium(
                    color: fg,
                    brightness: brightness,
                  ).copyWith(
                    fontSize: 18,
                    height: 26 / 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.04,
                  ),
            ),
            const SizedBox(height: StorySpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: StoryTextStyles.bodySmall(
                color: secondary,
                brightness: brightness,
              ).copyWith(height: 16 / 12, letterSpacing: 0.04),
            ),
            const SizedBox(height: StorySpacing.xxl),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.8,
              ),
              child: SingleChildScrollView(child: content),
            ),
            const SizedBox(height: StorySpacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: BorderSide(color: StoryColors.dividerOf(brightness)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: fg,
              ),
              child: Text(
                actionLabel,
                style: StoryTextStyles.bodyMedium(
                  color: fg,
                  brightness: brightness,
                ).copyWith(fontWeight: FontWeight.w700, height: 20 / 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvePriceDialogBody extends StatelessWidget {
  final AppLocalizations l10n;
  final int signedCount;
  final int chartMaxSupply;
  final double chartInitialPrice;
  final double chartCurrentPrice;
  final double tailPrice;
  final int remainingCount;

  const _CurvePriceDialogBody({
    required this.l10n,
    required this.signedCount,
    required this.chartMaxSupply,
    required this.chartInitialPrice,
    required this.chartCurrentPrice,
    required this.tailPrice,
    required this.remainingCount,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);

    final stats = [
      (
        label: l10n.actorPriceStatInitialPrice,
        value: '${formatNumber(chartInitialPrice)} ${l10n.currency}',
      ),
      (
        label: l10n.actorPriceStatCurrentPrice,
        value:
            '${formatActorPriceCeilDisplay(chartCurrentPrice)} ${l10n.currency}',
      ),
      (
        label: l10n.actorPriceStatTailPrice,
        value: '${formatActorPriceCeilDisplay(tailPrice)} ${l10n.currency}',
      ),
      (
        label: l10n.actorPriceStatTotalSupply,
        value: formatNumber(chartMaxSupply, 0),
      ),
      (label: l10n.actorPriceStatSigned, value: formatNumber(signedCount, 0)),
      (
        label: l10n.actorPriceStatRemaining,
        value: formatNumber(remainingCount, 0),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: StoryColors.actorHeroBadgeBgOf(brightness),
            borderRadius: StoryRadius.brMd,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.sm,
              vertical: StorySpacing.xs,
            ),
            child: Text(
              l10n.actorPriceCurveDisclaimer,
              style: StoryTextStyles.bodySmall(
                color: fg,
                brightness: brightness,
              ).copyWith(height: 16 / 12, letterSpacing: 0.04),
            ),
          ),
        ),
        const SizedBox(height: StorySpacing.base),
        Text(
          l10n.actorSignPriceFormula,
          style: StoryTextStyles.bodyMedium(
            color: StoryColors.brandTealDark,
            brightness: brightness,
          ).copyWith(height: 20 / 14),
        ),
        const SizedBox(height: StorySpacing.base),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActorPriceCurveChart(
              signedCount: signedCount,
              maxSupply: chartMaxSupply,
              initialPrice: chartInitialPrice,
              currentPrice: chartCurrentPrice,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: StorySpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(
                  color: StoryColors.warning,
                  label: l10n.actorPriceCurve,
                  textColor: secondary,
                ),
                const SizedBox(width: 44),
                _LegendDot(
                  color: StoryColors.brandTeal,
                  label: l10n.actorCurrentPosition,
                  textColor: secondary,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: StorySpacing.base),
        _PriceStatGrid(stats: stats, brightness: brightness),
      ],
    );
  }
}

class _FixedPriceDialogBody extends StatelessWidget {
  final AppLocalizations l10n;

  const _FixedPriceDialogBody({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);

    return Container(
      padding: const EdgeInsets.all(StorySpacing.base),
      decoration: BoxDecoration(
        color: StoryColors.actorSignSheetPriceCardBgOf(brightness),
        borderRadius: StoryRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '· ${l10n.actorFixedPriceNote1}',
            style: StoryTextStyles.bodyMedium(
              color: fg,
              brightness: brightness,
            ),
          ),
          const SizedBox(height: StorySpacing.xs),
          Text(
            '· ${l10n.actorFixedPriceNote2}',
            style: StoryTextStyles.bodyMedium(
              color: fg,
              brightness: brightness,
            ),
          ),
          const SizedBox(height: StorySpacing.xs),
          Text(
            '· ${l10n.actorFixedPriceNote3}',
            style: StoryTextStyles.bodyMedium(
              color: fg,
              brightness: brightness,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceStatGrid extends StatelessWidget {
  final List<({String label, String value})> stats;
  final Brightness brightness;

  const _PriceStatGrid({required this.stats, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - StorySpacing.sm) / 2;
        return Wrap(
          spacing: StorySpacing.sm,
          runSpacing: StorySpacing.sm,
          children: [
            for (final item in stats)
              SizedBox(
                width: itemWidth,
                child: _PriceStatCard(
                  label: item.label,
                  value: item.value,
                  brightness: brightness,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PriceStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Brightness brightness;

  const _PriceStatCard({
    required this.label,
    required this.value,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final fg = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.base,
          vertical: StorySpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style:
                  StoryTextStyles.caption(
                    color: secondary,
                    brightness: brightness,
                  ).copyWith(
                    fontSize: 10,
                    height: 12 / 10,
                    letterSpacing: 0.08,
                    fontWeight: FontWeight.w400,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              style: StoryTextStyles.bodyMedium(
                color: fg,
                brightness: brightness,
              ).copyWith(fontWeight: FontWeight.w500, height: 20 / 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: StorySpacing.xs),
        Text(
          label,
          style: StoryTextStyles.bodyMedium(
            color: textColor,
          ).copyWith(height: 20 / 14),
        ),
      ],
    );
  }
}
