import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_text_styles.dart';
import '../../../utils/format_number.dart';

/// 「近期挖矿释放」单条记录行样式（Figma node 6312:98138 内列表 item）。
///
/// 同时用于 Tab 内最多 5 条的预览列表（见 `RecentMiningReleaseSection`）与
/// 「查看更多」跳转的完整列表页（`StoryReleaseHistoryPage`），两处保持样式一致。
class WeeklyRewardListItem extends StatelessWidget {
  final WeeklyRewardItem item;

  /// 是否绘制底部 0.5px 分隔线（列表最后一项通常为 false）。
  final bool showDivider;

  const WeeklyRewardListItem({
    super.key,
    required this.item,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final mutedColor = StoryColors.mutedForegroundOf(theme.brightness);
    final foregroundColor = StoryColors.foregroundOf(theme.brightness);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            label: l10n.storyReleaseFieldPeriod,
            value: _formatPeriod(item),
            mutedColor: mutedColor,
            foregroundColor: foregroundColor,
          ),
          _Row(
            label: l10n.storyReleaseFieldHardLimit,
            value: formatNumber(item.hardLimit),
            mutedColor: mutedColor,
            foregroundColor: foregroundColor,
          ),
          _Row(
            label: l10n.storyReleaseFieldMiningRewards,
            value: formatNumber(item.miningRewards),
            mutedColor: mutedColor,
            foregroundColor: foregroundColor,
          ),
          _Row(
            label: l10n.storyReleaseFieldInviteRewards,
            value: formatNumber(item.inviteRewards),
            mutedColor: mutedColor,
            foregroundColor: foregroundColor,
          ),
          _Row(
            label: l10n.storyReleaseFieldUsageRate,
            value: _formatUsageRate(item),
            mutedColor: mutedColor,
            foregroundColor: StoryColors.brandTeal,
          ),
        ],
      ),
    );
  }
}

/// 格式化「周期」为 `MM/dd - MM/dd`；解析失败时回退为原始字符串。
String _formatPeriod(WeeklyRewardItem item) {
  final start = _formatPeriodDate(item.rewardPeriodStart);
  final end = _formatPeriodDate(
    item.rewardPeriodEnd,
    rollEndOfDayForward: true,
  );
  if (start.isEmpty && end.isEmpty) return '-';
  return '$start - $end';
}

String _formatPeriodDate(String? raw, {bool rollEndOfDayForward = false}) {
  if (raw == null || raw.trim().isEmpty) return '';
  var parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return raw.trim();
  if (rollEndOfDayForward &&
      parsed.hour == 23 &&
      parsed.minute == 59 &&
      parsed.second == 59) {
    parsed = parsed.add(const Duration(seconds: 1));
  }
  final mm = parsed.month.toString().padLeft(2, '0');
  final dd = parsed.day.toString().padLeft(2, '0');
  return '$mm/$dd';
}

/// 使用率 = (质押挖矿 + 邀请挖矿) / 周硬顶。
String _formatUsageRate(WeeklyRewardItem item) {
  final hardLimit = item.hardLimit;
  if (hardLimit == null || hardLimit == 0) return '-';
  final used = (item.miningRewards ?? 0) + (item.inviteRewards ?? 0);
  final rate = used / hardLimit * 100;
  if (rate > 0 && rate < 0.1) return '<0.1%';
  return '${rate.toStringAsFixed(1)}%';
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color mutedColor;
  final Color foregroundColor;

  const _Row({
    required this.label,
    required this.value,
    required this.mutedColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: StoryTextStyles.bodySmall(color: mutedColor)),
          Text(
            value,
            style: StoryTextStyles.titleMedium(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}
