import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../utils/format_number.dart';
import '../../widgets/story_card.dart';
import 'game_weekly_stat_help_dialog.dart';

/// Weekly mining stats panel.
class GameWeeklyStatsPanel extends StatelessWidget {
  final MiningWeeklyStats? stats;
  final VoidCallback? onMiningRules;
  final VoidCallback? onSettlementRecords;

  const GameWeeklyStatsPanel({
    super.key,
    required this.stats,
    this.onMiningRules,
    this.onSettlementRecords,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final l10n = context.l10n;
    final weekPool = stats?.weekPool;
    final nominal = stats?.weeklyNominalOutput;
    final estimated = stats?.weeklyTotalOutput;

    return StoryCard(
      padding: const EdgeInsets.all(StorySpacing.cardPadding),
      borderRadius: StoryRadius.brXl,
      backgroundColor: StoryColors.cardOf(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricRow(
            label: l10n.gameWeekPool,
            value: _formatAmount(weekPool),
            onHelpTap: () => showGameWeeklyStatHelpDialog(
              context,
              GameWeeklyStatHelpType.weekPool,
            ),
          ),
          const SizedBox(height: StorySpacing.sm),
          _MetricRow(
            label: l10n.gameWeekNominalOutput,
            value: _formatAmount(nominal),
            onHelpTap: () => showGameWeeklyStatHelpDialog(
              context,
              GameWeeklyStatHelpType.nominalOutput,
            ),
          ),
          const SizedBox(height: StorySpacing.sm),
          _MetricRow(
            label: l10n.gameWeekEstimatedOutput,
            value: _formatAmount(estimated),
            onHelpTap: () => showGameWeeklyStatHelpDialog(
              context,
              GameWeeklyStatHelpType.actualOutput,
            ),
          ),
          const SizedBox(height: StorySpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onMiningRules,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: StoryColors.borderOf(brightness)),
                    shape: const RoundedRectangleBorder(
                      borderRadius: StoryRadius.brSm,
                    ),
                  ),
                  child: Text(
                    l10n.gameMiningRules,
                    style: StoryTextStyles.caption(
                      color: StoryColors.foregroundOf(brightness),
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: StorySpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSettlementRecords,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: StoryColors.borderOf(brightness)),
                    shape: const RoundedRectangleBorder(
                      borderRadius: StoryRadius.brSm,
                    ),
                  ),
                  child: Text(
                    l10n.gameSettlementRecords,
                    style: StoryTextStyles.caption(
                      color: StoryColors.foregroundOf(brightness),
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double? value) {
    if (value == null) return '-';
    return formatNumber(value);
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onHelpTap;

  const _MetricRow({required this.label, required this.value, this.onHelpTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: StoryTextStyles.bodySmall(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onHelpTap,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.help_outline,
              size: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: StoryTextStyles.bodyMedium(
              color: StoryColors.foregroundOf(theme.brightness),
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
