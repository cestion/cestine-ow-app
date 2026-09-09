import 'package:flutter/material.dart';

import '../../../core/app_channel.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../utils/format_number.dart';

/// 「签约费/二级版税/购买道具/手续费」2x2 费用网格（Figma node 6312:95418）。
///
/// 数据来自 [IncomeStats]：`mintFee`（签约费）/ `royalty`（二级版税）/
/// `staminaFee + upgradeFee`（购买道具）/ `txFee`（手续费）。
class IncomeFeeGrid extends StatelessWidget {
  final IncomeStats? stats;
  final bool isLoading;

  const IncomeFeeGrid({super.key, this.stats, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeeCard(
                label: l10n.financeDashboardFeeMint,
                value: stats?.mintFee,
                isLoading: isLoading,
              ),
            ),
            const SizedBox(width: StorySpacing.sm),
            Expanded(
              child: _FeeCard(
                label: l10n.financeDashboardFeeRoyalty,
                value: stats?.royalty,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
        const SizedBox(height: StorySpacing.sm),
        Row(
          children: [
            Expanded(
              child: _FeeCard(
                label: l10n.financeDashboardFeeItemPurchase,
                value: (stats?.staminaFee ?? 0) + (stats?.upgradeFee ?? 0),
                isLoading: isLoading,
              ),
            ),
            const SizedBox(width: StorySpacing.sm),
            Expanded(
              child: _FeeCard(
                label: l10n.financeDashboardFeeTx,
                value: stats?.txFee,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeeCard extends StatelessWidget {
  final String label;
  final double? value;
  final bool isLoading;

  const _FeeCard({required this.label, this.value, required this.isLoading});

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
        mainAxisSize: MainAxisSize.min,
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
            isLoading
                ? '-'
                : AppChannel.isStore
                ? formatNumber(value ?? 0)
                : '\$${formatNumber(value ?? 0)}',
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

/// 「手续费」全宽卡片（Figma node 6385:54193），对应 [IncomeStats.txFee]。
class TransactionFeeCard extends StatelessWidget {
  final double? value;
  final bool isLoading;

  const TransactionFeeCard({super.key, this.value, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StorySpacing.base),
      decoration: BoxDecoration(
        color: StoryColors.cardOf(theme.brightness),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.financeDashboardFeeTx,
              style: TextStyle(
                fontSize: 13,
                height: 18 / 13,
                color: StoryColors.mutedForegroundOf(theme.brightness),
              ),
            ),
          ),
          Expanded(
            child: Text(
              isLoading
                  ? '-'
                  : AppChannel.isStore
                  ? formatNumber(value ?? 0)
                  : '\$${formatNumber(value ?? 0)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 24 / 16,
                color: StoryColors.foregroundOf(theme.brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
