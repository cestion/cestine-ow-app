import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/story_l10n.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../utils/format_number.dart';

/// 顶部「USDC 总收入 / STORY 总释放」汇总卡片（Figma node 6312:95387）。
///
/// 数据来自 [financeDashboardControllerProvider]，与页面内的 3 个 TabView
/// 各自独立的 Controller 无关。
class FinanceSummaryCards extends ConsumerWidget {
  const FinanceSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(financeDashboardControllerProvider);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: l10n.financeDashboardTotalUsdcIncome(l10n.currency),
            value: formatNumber(state.totalUsdcIncome),
            isLoading: state.isLoading,
          ),
        ),
        const SizedBox(width: StorySpacing.sm),
        Expanded(
          child: _SummaryCard(
            label: l10n.financeDashboardTotalStoryReleased,
            value: formatNumber(state.totalStoryReleased),
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
