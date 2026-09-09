import 'package:flutter/material.dart';

import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/format_number.dart';
import '../../../utils/mining_power.dart';
import 'agent_v2_salary_detail_dialog.dart';

/// V2 角色每小时片酬；仅 `STORY/h` 后缀打开明细。
class AgentV2HourlySalaryText extends StatelessWidget {
  final MiningActor actor;

  const AgentV2HourlySalaryText({super.key, required this.actor});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          formatNumber(getMiningActorHourlySalary(actor)),
          key: ValueKey('agent-v2-hourly-salary-value-${actor.nftId}'),
          style: TextStyle(
            color: StoryColors.foregroundOf(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 20 / 14,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          key: ValueKey('agent-v2-hourly-salary-link-${actor.nftId}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => showAgentV2SalaryDetailDialog(context, actor),
          child: Text(
            'STORY/h',
            style: TextStyle(
              color: StoryColors.mutedForegroundOf(brightness),
              fontSize: 12,
              height: 16 / 12,
              letterSpacing: 0.04,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
            ),
          ),
        ),
      ],
    );
  }
}
