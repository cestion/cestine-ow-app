import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/story_l10n.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../utils/format_number.dart';

/// 金库资金沉淀 Tab 顶部「总资金 / 覆盖演员 IP」汇总卡片
/// （Figma node 6385:54500）。
///
/// 数据来自 [vaultFundsControllerProvider]。
class VaultFundsSummaryCard extends ConsumerWidget {
  const VaultFundsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(vaultFundsControllerProvider);
    final stats = state.stats;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: l10n.financeDashboardTotalVaultFunds,
            value: '${formatNumber(stats?.totalVault)} ${l10n.currency}',
            isLoading: state.isLoading,
          ),
        ),
        const SizedBox(width: StorySpacing.sm),
        Expanded(
          child: _SummaryCard(
            label: l10n.financeDashboardCoveredActorIp,
            value: '${stats?.actorCount ?? 0}',
            isLoading: state.isLoading,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(StorySpacing.base),
      decoration: BoxDecoration(
        color: StoryColors.cardOf(theme.brightness),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              height: 18 / 13,
              color: StoryColors.mutedForegroundOf(theme.brightness),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isLoading ? '-' : value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 24 / 16,
              color: StoryColors.foregroundOf(theme.brightness),
            ),
          ),
        ],
      ),
    );
  }
}
