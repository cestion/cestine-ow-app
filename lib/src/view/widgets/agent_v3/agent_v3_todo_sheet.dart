import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controller/agent_v3_state.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../agent_todo_sheet.dart';
import 'agent_v3_candidate_actors_sheet.dart';
import 'agent_v3_refill_stamina_dialog.dart';

/// V3 待办入口；安排演出成功时返回对应演员 NFT ID。
Future<String?> showAgentV3TodoSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final action = await showModalBottomSheet<AgentTodoAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: StoryColors.overlayMid,
    showDragHandle: false,
    builder: (_) => const AgentV3TodoSheet(),
  );

  if (action == null || !context.mounted) return null;

  switch (action.type) {
    case AgentTodoActionType.perform:
      return showAgentV3CandidateActorsSheet(context);
    case AgentTodoActionType.refill:
      final actor = action.actor;
      if (actor != null && context.mounted) {
        await showAgentV3RefillStaminaDialog(context, ref, actor);
      }
      return null;
  }
}

/// V3 状态适配层；待办内容直接跟随 [agentV3ControllerProvider] 更新。
class AgentV3TodoSheet extends ConsumerWidget {
  const AgentV3TodoSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentV3ControllerProvider);
    final actors = state.deployedActors
        .take(agentV3DeploySlotCount)
        .toList(growable: false);
    final depletedActors = actors
        .where((actor) => actor.stamina == 0)
        .toList(growable: false);
    final vacantCount = (agentV3DeploySlotCount - actors.length).clamp(
      0,
      agentV3DeploySlotCount,
    );

    return AgentTodoSheet(
      vacantCount: vacantCount,
      depletedActors: depletedActors,
      keyPrefix: 'agent-v3-todo',
    );
  }
}
