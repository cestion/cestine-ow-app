import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/game/game_risk_account_badge.dart';
import '../../../l10n/story_l10n.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/format_number.dart';

/// 经纪人 V2 标题与本周片酬摘要。
///
/// 数据由 [weeklySalaryControllerProvider] 统一维护，刷新时保留上一次成功值，
/// 避免静默回源期间金额闪烁。
class AgentV2WeeklySalary extends ConsumerWidget {
  const AgentV2WeeklySalary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final l10n = context.l10n;

    final isLoggedIn = ref.watch(
      authControllerProvider.select((state) => state.isLoggedIn),
    );
    final hasRiskTrust = ref.watch(
      profileControllerProvider.select(
        (state) => state.user?.isRiskAccount == true,
      ),
    );
    final showRiskBadge = isLoggedIn && hasRiskTrust;

    final weekPool = ref.watch(
      weeklySalaryControllerProvider.select(
        (state) => state.stats?.weeklyTotalOutput,
      ),
    );
    final weekPoolText = weekPool == null ? '-' : formatNumber(weekPool);

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    l10n.agentV2WeeklySalaryTitle,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 25 / 17,
                    ),
                  ),
                ),
                if (showRiskBadge) ...[
                  const SizedBox(width: 8),
                  const GameRiskAccountBadge(),
                ],
              ],
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l10n.agentV2WeeklySalaryLabel,
                    style: TextStyle(color: secondary),
                  ),
                  TextSpan(
                    text: weekPoolText,
                    style: const TextStyle(
                      color: Color(0xFFFFBA18),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' STORY',
                    style: TextStyle(color: secondary),
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 18 / 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
