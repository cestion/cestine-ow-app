import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_format.dart';
import '../../../styles/story_text_styles.dart';
import '../../../utils/format_number.dart';

/// 「近期 USDC 收入流水」单条记录行样式（Figma node 6312:95533 等）。
///
/// 同时用于 Tab 内最多 5 条的预览列表（见 [RecentUsdcLedgerSection]）与
/// 「查看更多」跳转的完整流水页（`UsdcLedgerHistoryPage`），两处保持样式一致。
class UsdcLedgerListItem extends StatelessWidget {
  final LedgerItem item;

  /// 是否绘制底部 0.5px 分隔线（列表最后一项通常为 false）。
  final bool showDivider;

  const UsdcLedgerListItem({
    super.key,
    required this.item,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(item.amount ?? '') ?? 0;

    return Container(
      height: 60,
      alignment: Alignment.centerLeft,
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: StoryColors.dividerOf(theme.brightness),
                  width: 0.5,
                ),
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                usdcLedgerBizTypeLabel(l10n, item.bizType),
                style: StoryTextStyles.titleMedium(
                  color: StoryColors.foregroundOf(theme.brightness),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                StoryFormat.formatDateTime(item.time),
                style: StoryTextStyles.labelSmall(
                  color: StoryColors.mutedForegroundOf(theme.brightness),
                ),
              ),
            ],
          ),
          Text(
            '${formatNumber(amount, 4)} ${context.l10n.currency}',
            style: StoryTextStyles.titleMedium(color: StoryColors.brandTeal),
          ),
        ],
      ),
    );
  }
}

/// 流水业务类型编码（[LedgerItem.bizType]，如 "2108"）到本地化文案的映射。
///
/// 编码与 dashboard OpenAPI 的 `UsdcIncomeLedgerItemBizType` 枚举一致。
/// 空值显示 `-`，未知编码保留原值，方便识别后端新增的业务类型。
String usdcLedgerBizTypeLabel(AppLocalizations l10n, String? bizType) {
  final code = bizType?.trim();
  if (code == null || code.isEmpty) return '-';

  return switch (code) {
    '2101' => l10n.financeDashboardLedgerBizSigningFee,
    '2103' => l10n.financeDashboardLedgerBizManualCredit,
    '2104' => l10n.financeDashboardLedgerBizManualDebit,
    '2106' => l10n.financeDashboardLedgerBizStaminaPurchase,
    '2107' => l10n.financeDashboardLedgerBizSynthesisUpgrade,
    '2108' => l10n.financeDashboardLedgerBizTransactionFee,
    _ => code,
  };
}
