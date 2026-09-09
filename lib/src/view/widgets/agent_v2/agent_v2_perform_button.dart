import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/story_toast.dart';
import '../../../l10n/story_l10n.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import 'agent_v2_perform_all_confirm_dialog.dart';

/// 经纪人 V2 一键演出主操作。
class AgentV2PerformButton extends ConsumerStatefulWidget {
  const AgentV2PerformButton({super.key});

  @override
  ConsumerState<AgentV2PerformButton> createState() =>
      _AgentV2PerformButtonState();
}

class _AgentV2PerformButtonState extends ConsumerState<AgentV2PerformButton> {
  bool _isPreparing = false;

  Future<void> _handlePressed() async {
    if (_isPreparing) return;
    setState(() => _isPreparing = true);

    final restActorsController = ref.read(
      agentV2CandidateActorsControllerProvider.notifier,
    );
    await restActorsController.refresh();
    if (!mounted) return;
    setState(() => _isPreparing = false);

    final restActorsState = ref.read(agentV2CandidateActorsControllerProvider);
    final restActorsError = restActorsState.lastError;
    if (restActorsError != null && restActorsState.actors.isEmpty) {
      StoryToast.error(context, context.l10n.agentV2PerformAllFailed);
      return;
    }

    final restActorCount = restActorsState.totalCount;
    final deployCount = ref
        .read(gameControllerProvider)
        .deployAllActorCount(restActorCount);
    final confirmed = await showAgentV2PerformAllConfirmDialog(
      context,
      deployCount: deployCount,
    );
    if (confirmed != true || !mounted) return;

    await _perform(deployCount);
  }

  Future<void> _perform(int expectedActorCount) async {
    final successCount = await ref
        .read(gameControllerProvider.notifier)
        .deployAllActors();
    if (!mounted) return;

    if (successCount == null) {
      StoryToast.error(context, context.l10n.agentV2PerformAllFailed);
      return;
    }

    if (successCount > 0) {
      ref.read(weeklySalaryControllerProvider.notifier).refreshAfterMutation();
    }

    // expectedActorCount 已取“候场演员数”和“空槽数”的较小值，因此演员
    // 不足造成的空槽不会计入体力耗尽；服务端少安排的数量即为体力耗尽数。
    final depletedCount = (expectedActorCount - successCount).clamp(
      0,
      expectedActorCount,
    );
    if (depletedCount > 0) {
      final message = context.l10n.agentV2PerformAllDepletedResult(
        successCount,
        depletedCount,
      );
      // 保持原有反馈级别：部分成功用成功提示，全员体力耗尽仍用错误提示。
      if (successCount > 0) {
        StoryToast.success(context, message);
      } else {
        StoryToast.error(context, message);
      }
      return;
    }

    StoryToast.success(context, context.l10n.agentV2PerformAllSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isActionLoading = ref.watch(
      gameControllerProvider.select((state) => state.isActionLoading),
    );
    final isPageLoading = ref.watch(
      gameControllerProvider.select((state) => state.isLoading),
    );
    final isSlotsFull = !ref.watch(
      gameControllerProvider.select((state) => state.canDeployMore),
    );
    final restActorsState = ref.watch(agentV2CandidateActorsControllerProvider);
    final isRestActorsEmpty =
        restActorsState.isInitialized && restActorsState.actors.isEmpty;
    final isLoading = _isPreparing || isActionLoading || isPageLoading;
    final isDisabled = isLoading || isSlotsFull || isRestActorsEmpty;
    final buttonBackground = StoryColors.actorSignSheetConfirmBgOf(brightness);
    final buttonForeground = StoryColors.actorSignSheetConfirmFgOf(brightness);
    final disabledBackground = isLoading
        ? buttonBackground
        : StoryColors.mutedOf(brightness);
    final disabledForeground = isLoading
        ? buttonForeground
        : StoryColors.buttonDisabledForegroundOf(brightness);

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton(
        key: const ValueKey('agent-v2-perform-all-button'),
        onPressed: isDisabled ? null : _handlePressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          backgroundColor: buttonBackground,
          disabledBackgroundColor: disabledBackground,
          foregroundColor: buttonForeground,
          disabledForegroundColor: disabledForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 20 / 14,
          ),
        ),
        child: isLoading
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  key: const ValueKey('agent-v2-perform-all-loading'),
                  strokeWidth: 2,
                  color: buttonForeground,
                ),
              )
            : Text(context.l10n.agentV2PerformAllTitle),
      ),
    );
  }
}
