import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../utils/format_number.dart';

/// 「STORY 总量分配」内容区（Figma node 6312:97295）。
///
/// 顶部「总量 {total} STORY」胶囊徽标 + 6 项分配明细行（NFT 挖矿池 / 团队 /
/// 投资人 / Launchpad + 流动性 / 国库 / 市场运营），每行展示「分配对象、比例、
/// 数量、已释放、释放进度」5 个字段。数据来自 [globalConfigProvider] 中的
/// [InitConfig.mining]（`InitMiningPercents` 6 项比例 + `InitMiningConfig.totalSupply`
/// 总量）。
///
/// NFT 挖矿池的「已释放」来自 [financeDashboardControllerProvider]，释放进度按
/// 已释放 / 分配数量计算；其余分配项当前展示「0 / 0%」。
class StoryAllocationSection extends ConsumerWidget {
  const StoryAllocationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final configAsync = ref.watch(globalConfigProvider);
    final dashboardState = ref.watch(financeDashboardControllerProvider);

    final init = configAsync.maybeWhen(
      data: (result) => result.dataOrNull?.init?.mining,
      orElse: () => null,
    );

    if (init == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: StorySpacing.xxl),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: StoryColors.brandTeal,
            ),
          ),
        ),
      );
    }

    final totalSupply = init.totalSupply;
    final totalClean = (totalSupply ?? '').replaceAll(',', '');
    final total = double.tryParse(totalClean);

    final rows = _buildRows(
      percents: init.percents,
      total: total,
      totalReleased:
          dashboardState.isLoading || dashboardState.lastError != null
          ? null
          : dashboardState.totalStoryReleased,
      l10n: l10n,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StorySpacing.base),
      decoration: BoxDecoration(
        color: StoryColors.cardOf(theme.brightness),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TotalSupplyBadge(
            text: l10n.storyReleaseTotalSupplyBadge(
              total == null ? '-' : '${formatNumber(total / 1000000, 1)}M',
            ),
          ),
          const SizedBox(height: StorySpacing.sm),
          for (var i = 0; i < rows.length; i++)
            _AllocationRow(data: rows[i], showDivider: i != rows.length - 1),
        ],
      ),
    );
  }

  List<_AllocationData> _buildRows({
    required InitMiningPercents? percents,
    required double? total,
    required double? totalReleased,
    required AppLocalizations l10n,
  }) {
    final p = percents ?? const InitMiningPercents();

    _AllocationData row({
      required String target,
      required int? percent,
      bool isNftMiningPool = false,
    }) {
      final isReleasedReady = totalReleased != null;
      return _AllocationData(
        target: target,
        percent: percent,
        total: total,
        released: !isReleasedReady
            ? '-'
            : isNftMiningPool
            ? formatNumber(totalReleased)
            : '0',
        progress: !isReleasedReady
            ? '-'
            : isNftMiningPool
            ? _formatReleaseProgress(percent, total, totalReleased)
            : '0%',
      );
    }

    return [
      row(
        target: l10n.storyReleaseCategoryNftMiningPool,
        percent: p.nftMiningPool,
        isNftMiningPool: true,
      ),
      row(target: l10n.storyReleaseCategoryTeam, percent: p.team),
      row(target: l10n.storyReleaseCategoryInvestors, percent: p.investors),
      row(target: l10n.storyReleaseCategoryLiquidity, percent: p.liquidity),
      row(target: l10n.storyReleaseCategoryTreasury, percent: p.treasury),
      row(
        target: l10n.storyReleaseCategoryMarketOps,
        percent: p.marketOperations,
      ),
    ];
  }

  String _formatReleaseProgress(int? percent, double? total, double released) {
    if (percent == null || total == null) return '-';
    final amount = percent / 100.0 * total;
    if (amount <= 0) return '-';
    final progress = released / amount * 100;
    if (progress > 0 && progress < 0.1) return '<0.1%';
    return '${formatNumber(progress)}%';
  }
}

class _AllocationData {
  final String target;
  final int? percent;
  final double? total;
  final String released;
  final String progress;

  const _AllocationData({
    required this.target,
    required this.released,
    required this.progress,
    this.percent,
    this.total,
  });
}

class _TotalSupplyBadge extends StatelessWidget {
  final String text;

  const _TotalSupplyBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: StoryColors.tealSurfaceOf(Theme.of(context).brightness),
        borderRadius: const BorderRadius.all(Radius.circular(88)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: StoryTextStyles.labelMedium(
          color: StoryColors.brandTeal,
        ).copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  final _AllocationData data;
  final bool showDivider;

  const _AllocationRow({required this.data, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final dividerColor = theme.brightness == Brightness.dark
        ? StoryColors.darkMuted
        : StoryColors.lightInputBorder;

    return Container(
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 0.5, color: dividerColor),
              ),
            )
          : null,
      padding: showDivider
          ? const EdgeInsets.only(bottom: 12)
          : EdgeInsets.zero,
      child: Column(
        children: [
          _Item(label: l10n.storyReleaseFieldTarget, value: data.target),
          _Item(
            label: l10n.storyReleaseFieldRatio,
            value: _formatPercent(data.percent),
          ),
          _Item(
            label: l10n.storyReleaseFieldAmount,
            value: _formatAmount(data.percent, data.total),
          ),
          _Item(
            label: l10n.storyReleaseFieldReleased,
            value: data.released,
            valueColor: StoryColors.brandTeal,
          ),
          _Item(label: l10n.storyReleaseFieldProgress, value: data.progress),
        ],
      ),
    );
  }

  String _formatPercent(int? percent) => percent == null ? '-' : '$percent%';

  String _formatAmount(int? percent, double? total) {
    if (percent == null || total == null) return '-';
    final amount = percent / 100.0 * total / 1000000;
    final formatted = formatNumber(amount.toStringAsFixed(1), 1);
    final number = formatted.contains('.') ? formatted : '$formatted.0';
    return '${number}M';
  }
}

class _Item extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Item({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = valueColor ?? StoryColors.foregroundOf(theme.brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: StoryTextStyles.bodySmall(
              color: StoryColors.mutedForegroundOf(theme.brightness),
            ).copyWith(letterSpacing: 0.04),
          ),
          Text(
            value,
            style: StoryTextStyles.bodySmall(
              color: primary,
            ).copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.04),
          ),
        ],
      ),
    );
  }
}
