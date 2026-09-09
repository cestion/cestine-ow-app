import 'package:flutter/material.dart';

import '../../../controller/agent_v3_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../widgets/story_state_widget.dart';
import 'agent_v3_actor_carousel.dart';
import 'agent_v3_page_skeleton.dart';
import 'agent_v3_page_indicator.dart';
import 'agent_v3_primary_action.dart';
import 'agent_v3_quick_actions.dart';

/// 经纪人 V3 的页面内容入口。
///
/// 设计稿到位后在此目录按区域继续拆分组件，页面本身只负责生命周期和状态装配。
class AgentV3Content extends StatefulWidget {
  final AgentV3State state;
  final String? focusedActorNftId;
  final VoidCallback? onTodoPressed;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onWaitingPressed;
  final VoidCallback? onRecyclePressed;
  final ValueChanged<MiningActor>? onActorPressed;
  final ValueChanged<MiningActor>? onRefillPressed;
  final ValueChanged<MiningActor>? onRestPressed;
  final int waitingActorCount;
  final bool isPrimaryActionLoading;
  final VoidCallback? onPrimaryActionPressed;

  const AgentV3Content({
    super.key,
    required this.state,
    this.focusedActorNftId,
    this.onTodoPressed,
    this.onUpgradePressed,
    this.onWaitingPressed,
    this.onRecyclePressed,
    this.onActorPressed,
    this.onRefillPressed,
    this.onRestPressed,
    this.waitingActorCount = 0,
    this.isPrimaryActionLoading = false,
    this.onPrimaryActionPressed,
  });

  @override
  State<AgentV3Content> createState() => _AgentV3ContentState();
}

class _AgentV3ContentState extends State<AgentV3Content> {
  late int _selectedIndex = _initialPage(
    widget.state,
    widget.focusedActorNftId,
  );

  static int _initialPage(AgentV3State state, String? focusedActorNftId) {
    final focusedIndex = _actorIndex(state, focusedActorNftId);
    if (focusedIndex >= 0) return focusedIndex;
    if (state.deployedActors.length == 1) return 0;
    return 1;
  }

  static int _actorIndex(AgentV3State state, String? actorNftId) {
    if (actorNftId == null || actorNftId.isEmpty) return -1;
    return state.deployedActors.indexWhere(
      (actor) => actor.nftId == actorNftId,
    );
  }

  @override
  void didUpdateWidget(covariant AgentV3Content oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFocusedIndex = _actorIndex(
      oldWidget.state,
      oldWidget.focusedActorNftId,
    );
    final focusedIndex = _actorIndex(widget.state, widget.focusedActorNftId);
    final focusChanged =
        oldWidget.focusedActorNftId != widget.focusedActorNftId;
    if (focusedIndex >= 0 && (focusChanged || oldFocusedIndex < 0)) {
      _selectedIndex = focusedIndex;
    } else if (oldWidget.state.isLoading && !widget.state.isLoading) {
      _selectedIndex = _initialPage(widget.state, widget.focusedActorNftId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.isLoading) {
      return const AgentV3PageSkeleton();
    }

    final error = state.lastError;
    if (error != null && !state.hasUsableSnapshot) {
      return StoryStateWidget.error(message: context.l10nError(error));
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: AgentV3ActorCarousel(
              key: state.deployedActors.isEmpty
                  ? const ValueKey('agent-v3-empty-carousel')
                  : const ValueKey('agent-v3-actor-carousel'),
              actors: state.deployedActors,
              staminaLimit: state.staminaLimit,
              initialPage: _selectedIndex,
              onActorPressed: widget.onActorPressed,
              onRefillPressed: widget.onRefillPressed,
              onRestPressed: widget.onRestPressed,
              onEmptySlotPressed: widget.onWaitingPressed,
              onPageChanged: (index) {
                if (_selectedIndex == index) return;
                setState(() => _selectedIndex = index);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              AgentV3PageIndicator(
                occupiedItemCount: state.deployedActors.length,
                selectedIndex: _selectedIndex,
              ),
              const SizedBox(height: 16),
              AgentV3PrimaryAction(
                action: state.primaryActionKind(
                  waitingActorCount: widget.waitingActorCount,
                ),
                claimableStory: state.claimableStory,
                loading: widget.isPrimaryActionLoading,
                onPressed: widget.onPrimaryActionPressed,
              ),
              const SizedBox(height: 16),
              AgentV3QuickActions(
                todoCount: state.todoCount,
                upgradeCount: state.upgradeableCount,
                onTodoPressed: widget.onTodoPressed,
                onUpgradePressed: widget.onUpgradePressed,
                onWaitingPressed: widget.onWaitingPressed,
                onRecyclePressed: widget.onRecyclePressed,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
