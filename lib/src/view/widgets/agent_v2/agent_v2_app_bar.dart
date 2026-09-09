import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../agent_more_sheet.dart';
import 'agent_v2_todo_sheet.dart';
import 'agent_v2_upgradeable_actors_sheet.dart';

/// 经纪人 V2 顶栏：菜单、待办数、升级数与帮助入口。
class AgentV2AppBar extends ConsumerWidget {
  final VoidCallback? onMenuPressed;

  const AgentV2AppBar({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final upgradeableActorCount = ref.watch(
      agentV2UpgradeableActorsControllerProvider.select(
        (state) => state.upgradeableCount,
      ),
    );
    final todoCount = ref.watch(
      gameControllerProvider.select((state) => state.todoCount),
    );

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: onMenuPressed,
                icon: Icon(Icons.menu, size: 24, color: foreground),
              ),
            ),
            const Spacer(),
            _CountPill(
              key: const ValueKey('agent-v2-todo-count-pill'),
              svgAsset: 'assets/game_v2/agent_todo.svg',
              count: '$todoCount',
              onTap: () => showAgentV2TodoSheet(context, ref),
            ),
            const SizedBox(width: 13),
            _CountPill(
              key: const ValueKey('agent-v2-upgrade-count-pill'),
              svgAsset: 'assets/game_v2/agent_upgrade.svg',
              count: '$upgradeableActorCount',
              onTap: () => showAgentV2UpgradeableActorsSheet(context),
            ),
            const SizedBox(width: 13),
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () => showAgentMoreSheet(context),
                icon: Icon(Icons.help_outline, size: 24, color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String svgAsset;
  final String count;
  final VoidCallback? onTap;

  const _CountPill({
    super.key,
    required this.svgAsset,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);

    return Semantics(
      button: onTap != null,
      child: Material(
        color: brightness == Brightness.dark
            ? StoryColors.darkMuted
            : StoryColors.lightSheetSecondary,
        borderRadius: BorderRadius.circular(59),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 24,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    svgAsset,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    count,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                      letterSpacing: 0.04,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
