import 'package:flutter/material.dart';

import '../../../controller/agent_v3_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/format_number.dart';

/// Figma `2708:167956`：经纪人 V3 底部智能主操作。
///
/// 按钮业务优先级由 [AgentV3State.primaryActionKind] 统一解析；本组件只负责
/// 将动作映射为设计稿里的五种文案和两种视觉样式。
class AgentV3PrimaryAction extends StatelessWidget {
  const AgentV3PrimaryAction({
    super.key,
    this.action = AgentV3PrimaryActionKind.performAll,
    this.claimableStory = 0,
    this.loading = false,
    this.onPressed,
  });

  final AgentV3PrimaryActionKind action;
  final double claimableStory;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final filledBackground = StoryColors.actorSignSheetConfirmBgOf(brightness);
    final filledForeground = StoryColors.actorSignSheetConfirmFgOf(brightness);
    final label = _label(context);
    final buttonKey = ValueKey('agent-v3-primary-${action.name}');
    final child = loading
        ? SizedBox.square(
            key: const ValueKey('agent-v3-primary-loading'),
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: action == AgentV3PrimaryActionKind.restAll
                  ? foreground
                  : filledForeground,
            ),
          )
        : Text(label);

    return MediaQuery.withNoTextScaling(
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: action == AgentV3PrimaryActionKind.restAll
            ? OutlinedButton(
                key: buttonKey,
                onPressed: loading ? null : onPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  foregroundColor: foreground,
                  disabledForegroundColor: foreground,
                  side: BorderSide(
                    color: StoryColors.dividerOf(brightness),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: _textStyle,
                ),
                child: child,
              )
            : FilledButton(
                key: action == AgentV3PrimaryActionKind.performAll
                    ? const ValueKey('agent-v3-perform-all')
                    : buttonKey,
                onPressed: loading ? null : onPressed,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 0,
                  backgroundColor: filledBackground,
                  disabledBackgroundColor: filledBackground,
                  foregroundColor: filledForeground,
                  disabledForegroundColor: filledForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: _textStyle,
                ),
                child: child,
              ),
      ),
    );
  }

  String _label(BuildContext context) => switch (action) {
    AgentV3PrimaryActionKind.claim =>
      '${formatNumber(claimableStory)} STORY · ${context.l10n.incomeClaimAction}',
    AgentV3PrimaryActionKind.performAll => context.l10n.agentV3PerformAll,
    AgentV3PrimaryActionKind.restAll => context.l10n.agentV3RestAll,
    AgentV3PrimaryActionKind.refillAll => context.l10n.agentV3RefillAll,
    AgentV3PrimaryActionKind.signActor => context.l10n.agentV3SignActor,
  };

  static const TextStyle _textStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
  );
}
