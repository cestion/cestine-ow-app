import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../styles/story_colors.dart';
import 'agent_v3_balance_chip.dart';
import 'agent_v3_salary_summary.dart';

/// 经纪人 V3 顶部资产栏与本周片酬摘要。
class AgentV3AppBar extends StatelessWidget {
  final String primaryItemCount;
  final String secondaryItemCount;
  final String weeklySalary;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onPrimaryAddPressed;
  final VoidCallback? onSecondaryAddPressed;
  final VoidCallback? onMorePressed;

  const AgentV3AppBar({
    super.key,
    required this.primaryItemCount,
    required this.secondaryItemCount,
    required this.weeklySalary,
    this.onMenuPressed,
    this.onPrimaryAddPressed,
    this.onSecondaryAddPressed,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onMenuPressed,
                  child: SvgPicture.asset(
                    'assets/game_v3/agent_menu.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  ),
                ),
                const Spacer(),
                AgentV3BalanceChip(
                  asset: 'assets/game_v3/agent_token_story.png',
                  value: primaryItemCount,
                  assetWidth: 22,
                  assetHeight: 18.264,
                  onAdd: onPrimaryAddPressed,
                ),
                const SizedBox(width: 8),
                AgentV3BalanceChip(
                  asset: 'assets/game_v3/agent_token_usdc.png',
                  value: secondaryItemCount,
                  assetWidth: 17.634,
                  assetHeight: 20,
                  onAdd: onSecondaryAddPressed,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  key: const ValueKey('agent-v3-more-button'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onMorePressed,
                  child: SvgPicture.asset(
                    'assets/game_v3/agent_more.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
          ),
        ),
        AgentV3SalarySummary(value: weeklySalary),
      ],
    );
  }
}
