import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../agent_todo_sheet.dart';
import 'agent_v2_candidate_actors_sheet.dart';
import 'agent_v2_refill_stamina_dialog.dart';

/// 打开 Figma `198:44136` 待办弹层，并把操作衔接到 V2 业务弹层。
Future<void> showAgentV2TodoSheet(BuildContext context, WidgetRef ref) async {
  final action = await showModalBottomSheet<AgentTodoAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: StoryColors.overlayMid,
    showDragHandle: false,
    builder: (_) => const AgentV2TodoSheet(),
  );

  if (action == null || !context.mounted) return;

  switch (action.type) {
    case AgentTodoActionType.perform:
      await showAgentV2CandidateActorsSheet(context);
      return;
    case AgentTodoActionType.refill:
      final actor = action.actor;
      if (actor != null && context.mounted) {
        await showAgentV2RefillStaminaDialog(context, ref, actor);
      }
      return;
  }
}

/// V2 状态适配层；具体 Sheet UI 与 V3 共用。
class AgentV2TodoSheet extends ConsumerWidget {
  const AgentV2TodoSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    return AgentTodoSheet(
      vacantCount: state.vacantDeploySlotCount,
      depletedActors: state.depletedDeployedActors,
      keyPrefix: 'agent-v2-todo',
    );
  }
}
