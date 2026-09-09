import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../provider/repository_providers.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../utils/format_number.dart';

enum GameWeeklyStatHelpType { weekPool, nominalOutput, actualOutput }

Future<void> showGameWeeklyStatHelpDialog(
  BuildContext context,
  GameWeeklyStatHelpType type,
) async {
  final weeklyStats = type == GameWeeklyStatHelpType.weekPool
      ? await ProviderScope.containerOf(
          context,
        ).read(rewardRepositoryProvider).getCachedWeeklyStats()
      : null;
  if (!context.mounted) return;

  return showDialog<void>(
    context: context,
    builder: (ctx) => switch (type) {
      GameWeeklyStatHelpType.weekPool => _WeekPoolHelpDialog(weeklyStats),
      GameWeeklyStatHelpType.nominalOutput => const _NominalOutputHelpDialog(),
      GameWeeklyStatHelpType.actualOutput => const _ActualOutputHelpDialog(),
    },
  );
}

/// Shared inset with「本周奖池」— wider than default StoryInfoDialog.
const _helpDialogInset = EdgeInsets.symmetric(horizontal: StorySpacing.base);

/// 本周奖池说明 — 对齐 Figma「本周奖池」亮/暗。
class _WeekPoolHelpDialog extends StatelessWidget {
  final MiningWeeklyStats? weeklyStats;

  const _WeekPoolHelpDialog(this.weeklyStats);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final mutedFg = StoryColors.mutedForegroundOf(brightness);
    final border = StoryColors.borderOf(brightness);
    // Figma `--colors/page&sheet/secondary` #f0f0f3 / dark badge surface.
    final panelBg = brightness == Brightness.dark
        ? StoryColors.darkActorHeroBadgeBg
        : StoryColors.lightActorHeroBadgeBg;
    final weekPool = weeklyStats?.weekPool;
    final weekInvitePool = weeklyStats?.weekInvitePool;

    return Dialog(
      backgroundColor: StoryColors.cardOf(brightness),
      elevation: 0,
      insetPadding: _helpDialogInset,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.gameStatHelpWeekPoolTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 26 / 18,
                letterSpacing: -0.04,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
            const SizedBox(height: StorySpacing.xs),
            Text(
              l10n.gameStatHelpWeekPoolSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0.04,
                fontWeight: FontWeight.w400,
                color: mutedFg,
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: StorySpacing.base,
                vertical: StorySpacing.md,
              ),
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HelpDetailRow(
                    label: l10n.gameStatHelpWeekTotalPool,
                    value: formatStoryAmount(weekPool) ?? '-',
                    labelColor: mutedFg,
                    valueColor: fg,
                  ),
                  Divider(height: 16, thickness: 1, color: border),
                  _HelpDetailRow(
                    label: l10n.gameStatHelpWeekStakePool,
                    value: weekPool == null || weekInvitePool == null
                        ? '-'
                        : formatStoryAmount(weekPool - weekInvitePool) ?? '-',
                    labelColor: mutedFg,
                    valueColor: fg,
                  ),
                  Divider(height: 16, thickness: 1, color: border),
                  _HelpDetailRow(
                    label: l10n.gameStatHelpWeekInvitePool,
                    value: formatStoryAmount(weekInvitePool) ?? '-',
                    labelColor: mutedFg,
                    valueColor: fg,
                  ),
                  Divider(height: 16, thickness: 1, color: border),
                  _HelpDetailRow(
                    label: l10n.gameStatHelpWeeklyDecay,
                    value: l10n.gameStatHelpWeeklyDecayValue,
                    labelColor: mutedFg,
                    valueColor: fg,
                  ),
                  Divider(height: 16, thickness: 1, color: border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: StorySpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.gameStatHelpWeeklyDistributionFormula,
                          style: TextStyle(
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w500,
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.gameStatHelpUnusedQuotaNote,
                          style: TextStyle(
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w400,
                            color: mutedFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            _HelpCloseButton(border: border, foreground: fg),
          ],
        ),
      ),
    );
  }
}

/// 本周名义产出说明 — 对齐 Figma「本周名义产出」亮/暗。
class _NominalOutputHelpDialog extends StatelessWidget {
  const _NominalOutputHelpDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final mutedFg = StoryColors.mutedForegroundOf(brightness);
    final border = StoryColors.borderOf(brightness);
    // Figma `--colors/page&sheet/secondary` #f0f0f3 / dark badge surface.
    final panelBg = brightness == Brightness.dark
        ? StoryColors.darkActorHeroBadgeBg
        : StoryColors.lightActorHeroBadgeBg;

    return Dialog(
      backgroundColor: StoryColors.cardOf(brightness),
      elevation: 0,
      insetPadding: _helpDialogInset,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.gameStatHelpNominalTitle,
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
                    horizontal: StorySpacing.base,
                    vertical: StorySpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.gameStatHelpNominalSummary,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.bold,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.gameStatHelpNominalSummaryHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          height: 12 / 10,
                          letterSpacing: 0.08,
                          fontWeight: FontWeight.w400,
                          color: mutedFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: StorySpacing.xl),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.gameStatHelpNominalFormula,
                  style: TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w400,
                    color: fg,
                  ),
                ),
                const SizedBox(height: StorySpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: StorySpacing.base,
                    vertical: StorySpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HelpDetailRow(
                        label: l10n.gameStatHelpHourlyWeight,
                        value: l10n.gameStatHelpHourlyWeightValue,
                        labelColor: mutedFg,
                        valueColor: fg,
                        fontSize: 12,
                        lineHeight: 16 / 12,
                      ),
                      Divider(height: 16, thickness: 1, color: border),
                      _HelpDetailRow(
                        label: l10n.gameStatHelpActorPower,
                        value: l10n.gameStatHelpActorPowerValue,
                        labelColor: mutedFg,
                        valueColor: fg,
                        fontSize: 12,
                        lineHeight: 16 / 12,
                      ),
                      Divider(height: 16, thickness: 1, color: border),
                      _HelpDetailRow(
                        label: l10n.gameStatHelpRBase,
                        value: l10n.gameStatHelpRBaseValue,
                        labelColor: mutedFg,
                        valueColor: fg,
                        fontSize: 12,
                        lineHeight: 16 / 12,
                      ),
                      Divider(height: 16, thickness: 1, color: border),
                      _HelpDetailRow(
                        label: l10n.gameStatHelpEffectiveDuration,
                        value: l10n.gameStatHelpEffectiveDurationValue,
                        labelColor: mutedFg,
                        valueColor: fg,
                        fontSize: 12,
                        lineHeight: 16 / 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: StorySpacing.xl),
            _HelpCloseButton(border: border, foreground: fg),
          ],
        ),
      ),
    );
  }
}

class _HelpCloseButton extends StatelessWidget {
  final Color border;
  final Color foreground;

  const _HelpCloseButton({required this.border, required this.foreground});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: foreground,
        ),
        child: Text(
          l10n.commonClose,
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.bold,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _HelpDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final double fontSize;
  final double lineHeight;

  const _HelpDetailRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    this.fontSize = 13,
    this.lineHeight = 18 / 13,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              height: lineHeight,
              letterSpacing: 0.04,
              fontWeight: FontWeight.w400,
              color: labelColor,
            ),
          ),
        ),
        const SizedBox(width: StorySpacing.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: fontSize,
              height: lineHeight,
              letterSpacing: 0.04,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActualOutputHelpDialog extends StatelessWidget {
  const _ActualOutputHelpDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final mutedFg = StoryColors.mutedForegroundOf(brightness);
    final border = StoryColors.borderOf(brightness);
    // Figma `--colors/page&sheet/secondary` #f0f0f3 / dark badge surface.
    final panelBg = brightness == Brightness.dark
        ? StoryColors.darkActorHeroBadgeBg
        : StoryColors.lightActorHeroBadgeBg;

    final mutedStyle = TextStyle(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w400,
      color: mutedFg,
    );
    final formulaStyle = TextStyle(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w500,
      color: fg,
    );

    return Dialog(
      backgroundColor: StoryColors.cardOf(brightness),
      elevation: 0,
      insetPadding: _helpDialogInset,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.gameStatHelpActualTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 26 / 18,
                    letterSpacing: -0.04,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.gameStatHelpActualSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    letterSpacing: 0.04,
                    fontWeight: FontWeight.w400,
                    color: mutedFg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: StorySpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: StorySpacing.base,
                vertical: StorySpacing.md,
              ),
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ActualRuleBlock(
                    showDivider: true,
                    borderColor: border,
                    children: [
                      Text(l10n.gameStatHelpIfNominalLte, style: mutedStyle),
                      const SizedBox(height: 8),
                      Text(
                        l10n.gameStatHelpUserActualEqNominal,
                        style: formulaStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.gameStatHelpUnusedQuotaNote, style: mutedStyle),
                    ],
                  ),
                  _ActualRuleBlock(
                    showDivider: true,
                    borderColor: border,
                    children: [
                      Text(l10n.gameStatHelpIfNominalGt, style: mutedStyle),
                      const SizedBox(height: 8),
                      Text(
                        l10n.gameStatHelpUserActualFormula,
                        style: formulaStyle,
                      ),
                    ],
                  ),
                  _ActualRuleBlock(
                    showDivider: false,
                    borderColor: border,
                    children: [
                      Text(l10n.gameStatHelpAddressCap, style: mutedStyle),
                      const SizedBox(height: 8),
                      Text(
                        l10n.gameStatHelpAddressCapValue,
                        style: formulaStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            _HelpCloseButton(border: border, foreground: fg),
          ],
        ),
      ),
    );
  }
}

class _ActualRuleBlock extends StatelessWidget {
  final List<Widget> children;
  final Color borderColor;
  final bool showDivider;

  const _ActualRuleBlock({
    required this.children,
    required this.borderColor,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: StorySpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 1, color: borderColor),
      ],
    );
  }
}
