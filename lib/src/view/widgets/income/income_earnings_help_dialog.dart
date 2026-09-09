import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../widgets/story_info_dialog.dart';

/// 对齐 Web `IncomeWalletEarningsHelpType`。
enum IncomeEarningsHelpType {
  totalStory,
  totalUsdc,
  settlingStory,
  claimableStory,
  claimableUsdc,
}

/// 收益摘要说明弹窗 — 对齐 Web `IncomeWalletEarningsHelpDialog`
///（Figma 970:113297 / 113306 / 113314 / 113322 / 113330）。
Future<void> showIncomeEarningsHelpDialog(
  BuildContext context,
  IncomeEarningsHelpType type,
) {
  final l10n = context.l10n;
  final brightness = Theme.of(context).brightness;
  final (title, description) = switch (type) {
    IncomeEarningsHelpType.totalStory => (
      l10n.incomeCumulativeStory,
      l10n.incomeHelpTotalStoryDesc,
    ),
    IncomeEarningsHelpType.totalUsdc => (
      l10n.incomeCumulativeUsdc(l10n.currency),
      l10n.incomeHelpTotalUsdcDesc(l10n.currency),
    ),
    IncomeEarningsHelpType.settlingStory => (
      l10n.incomeSettlingStory,
      l10n.incomeHelpSettlingStoryDesc,
    ),
    IncomeEarningsHelpType.claimableStory => (
      l10n.incomeClaimableStory,
      l10n.incomeHelpClaimableStoryDesc,
    ),
    IncomeEarningsHelpType.claimableUsdc => (
      l10n.incomeClaimableUsdc(l10n.currency),
      l10n.incomeHelpClaimableUsdcDesc(l10n.currency),
    ),
  };

  return StoryInfoDialog.show(
    context: context,
    title: title,
    actionLabel: l10n.gameStaminaMechanismAction,
    insetPadding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
    content: Text(
      description,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: StoryColors.mutedForegroundOf(brightness),
      ),
    ),
  );
}

/// 标签 + 问号，对齐 Web `IncomeWalletEarningsHelpLabel`。
class IncomeEarningsHelpLabel extends StatelessWidget {
  final String label;
  final IncomeEarningsHelpType helpType;
  final TextStyle? labelStyle;

  const IncomeEarningsHelpLabel({
    super.key,
    required this.label,
    required this.helpType,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final iconColor = StoryColors.mutedForegroundOf(brightness);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style:
                labelStyle ??
                TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  color: StoryColors.mutedForegroundOf(brightness),
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => showIncomeEarningsHelpDialog(context, helpType),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(Icons.help_outline, size: 16, color: iconColor),
          ),
        ),
      ],
    );
  }
}
