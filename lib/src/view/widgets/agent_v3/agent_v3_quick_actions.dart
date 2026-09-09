import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';

/// 经纪人快捷入口，对应 Figma 节点 `2984:266182`。
class AgentV3QuickActions extends StatelessWidget {
  final int todoCount;
  final int upgradeCount;
  final VoidCallback? onTodoPressed;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onWaitingPressed;
  final VoidCallback? onRecyclePressed;

  const AgentV3QuickActions({
    super.key,
    required this.todoCount,
    required this.upgradeCount,
    this.onTodoPressed,
    this.onUpgradePressed,
    this.onWaitingPressed,
    this.onRecyclePressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _QuickActionItem(
            key: const ValueKey('agent-v3-todo-action'),
            asset: 'assets/game_v3/agent_action_todo.svg',
            label: l10n.agentV3Todo,
            badgeCount: todoCount,
            badgeKey: const ValueKey('agent-v3-todo-count-badge'),
            onTap: onTodoPressed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionItem(
            key: const ValueKey('agent-v3-upgrade-action'),
            asset: 'assets/game_v3/agent_action_upgrade.svg',
            label: l10n.agentV3Upgrade,
            badgeCount: upgradeCount,
            badgeKey: const ValueKey('agent-v3-upgrade-count-badge'),
            onTap: onUpgradePressed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionItem(
            key: const ValueKey('agent-v3-waiting-action'),
            asset: 'assets/game_v3/agent_action_candidate.svg',
            label: l10n.agentV3Waiting,
            onTap: onWaitingPressed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionItem(
            key: const ValueKey('agent-v3-recycle-action'),
            asset: 'assets/game_v3/agent_action_recycle.svg',
            label: l10n.agentV3Recycle,
            onTap: onRecyclePressed,
          ),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final String asset;
  final String label;
  final int? badgeCount;
  final Key? badgeKey;
  final VoidCallback? onTap;

  const _QuickActionItem({
    super.key,
    required this.asset,
    required this.label,
    this.badgeCount,
    this.badgeKey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final showBadge = badgeCount != null && badgeCount! > 0;

    return Semantics(
      button: onTap != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: StoryColors.createDramaPanelSurfaceOf(brightness),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(asset, width: 24, height: 24),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                        letterSpacing: 0.04,
                      ),
                    ),
                  ],
                ),
              ),
              if (showBadge)
                Positioned(
                  top: 2,
                  left: 43,
                  child: Container(
                    key: badgeKey,
                    height: 18,
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: StoryColors.foregroundOf(brightness),
                      border: Border.all(
                        color: StoryColors.createDramaPanelSurfaceOf(
                          brightness,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(34),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        color: StoryColors.whiteToDarkOf(brightness),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 16 / 13,
                        letterSpacing: 0.04,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
