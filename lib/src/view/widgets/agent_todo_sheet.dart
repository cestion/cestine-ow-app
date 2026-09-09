import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';

enum AgentTodoActionType { perform, refill }

class AgentTodoAction {
  final AgentTodoActionType type;
  final MiningActor? actor;

  const AgentTodoAction.perform()
    : type = AgentTodoActionType.perform,
      actor = null;

  const AgentTodoAction.refill(this.actor) : type = AgentTodoActionType.refill;
}

/// V2/V3 共用的待办 Sheet 展示层，不读取任何版本状态或执行具体业务。
class AgentTodoSheet extends StatelessWidget {
  final int vacantCount;
  final List<MiningActor> depletedActors;
  final String keyPrefix;

  const AgentTodoSheet({
    super.key,
    required this.vacantCount,
    required this.depletedActors,
    required this.keyPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final hasTodos = vacantCount > 0 || depletedActors.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: StoryColors.cardOf(brightness),
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 24,
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: brightness == Brightness.dark
                            ? StoryColors.darkMuted
                            : StoryColors.lightSheetSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.agentV2TodoTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: StoryColors.foregroundOf(brightness),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 26 / 18,
                    letterSpacing: -0.04,
                  ),
                ),
                const SizedBox(height: 16),
                if (hasTodos)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (vacantCount > 0)
                        _TodoRow(
                          key: ValueKey('$keyPrefix-vacancy'),
                          color: StoryColors.success,
                          label: context.l10n.agentV2TodoVacancies(vacantCount),
                          actionLabel: context.l10n.agentV2TodoPerform,
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(const AgentTodoAction.perform()),
                        ),
                      for (final (index, actor) in depletedActors.indexed) ...[
                        if (vacantCount > 0 || index > 0)
                          const SizedBox(height: 8),
                        _TodoRow(
                          key: ValueKey('$keyPrefix-stamina-${actor.nftId}'),
                          color: StoryColors.destructive,
                          label: context.l10n.agentV2TodoStaminaDepleted(
                            _actorNameWithCode(actor),
                          ),
                          actionLabel: context.l10n.agentV2TodoRefill,
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(AgentTodoAction.refill(actor)),
                        ),
                      ],
                    ],
                  )
                else
                  _HealthyRow(
                    key: ValueKey('$keyPrefix-healthy'),
                    label: context.l10n.agentV2TodoHealthy,
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    key: ValueKey('$keyPrefix-close'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 10,
                      ),
                      foregroundColor: StoryColors.foregroundOf(brightness),
                      side: BorderSide(
                        color: StoryColors.dividerOf(brightness),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                      ),
                    ),
                    child: Text(context.l10n.commonClose),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _actorNameWithCode(MiningActor actor) {
  final actorCode = actor.actorCode;
  return actorCode == null
      ? actor.displayName
      : '${actor.displayName} $actorCode';
}

class _TodoRow extends StatelessWidget {
  final Color color;
  final String label;
  final String actionLabel;
  final VoidCallback onPressed;

  const _TodoRow({
    super.key,
    required this.color,
    required this.label,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? StoryColors.darkMuted
            : StoryColors.lightSheetSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: StoryColors.foregroundOf(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: brightness == Brightness.dark
                    ? Colors.white
                    : StoryColors.darkButtonBg,
                foregroundColor: brightness == Brightness.dark
                    ? StoryColors.lightForeground
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 18 / 13,
                ),
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthyRow extends StatelessWidget {
  final String label;

  const _HealthyRow({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? StoryColors.darkMuted
            : StoryColors.lightSheetSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: StoryColors.actorSignSheetSlippageNoteOf(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
