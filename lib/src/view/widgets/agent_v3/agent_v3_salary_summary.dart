import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/game/game_risk_account_badge.dart';
import '../../../l10n/story_l10n.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';

/// 本周片酬摘要，对应 Figma 节点 `2620:133095`。
class AgentV3SalarySummary extends ConsumerWidget {
  final String value;

  const AgentV3SalarySummary({super.key, required this.value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    // 与 V2 保持一致：仅已登录且信任系数低于 1 时展示风险提示。
    final isLoggedIn = ref.watch(
      authControllerProvider.select((state) => state.isLoggedIn),
    );
    final hasRiskTrust = ref.watch(
      profileControllerProvider.select(
        (state) => state.user?.isRiskAccount == true,
      ),
    );
    final showRiskBadge = isLoggedIn && hasRiskTrust;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/game_v3/agent_salary.svg',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StoryColors.warning,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 30 / 24,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.agentV3WeeklySalary,
                  style: TextStyle(
                    color: StoryColors.mutedForegroundOf(brightness),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 18 / 13,
                  ),
                ),
              ],
            ),
          ),
          if (showRiskBadge) ...[
            const SizedBox(width: 8),
            const GameRiskAccountBadge(),
          ],
        ],
      ),
    );
  }
}
