import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/story_toast.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../widgets/error_handler.dart';

/// Figma `637:75118`：经纪人 V2 确认休息弹窗。
Future<bool> showAgentV2RestConfirmDialog(
  BuildContext context,
  MiningActor actor,
) async {
  final submission = await showGeneralDialog<_RestSubmission>(
    context: context,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) =>
        _AgentV2RestConfirmRoute(actor: actor),
  );

  if (submission == null) return false;
  if (context.mounted) {
    StoryToast.success(
      context,
      submission == _RestSubmission.all
          ? context.l10n.agentV2RestAllSuccess
          : context.l10n.gameRestSuccessToast,
    );
  }
  return true;
}

enum _RestSubmission { actor, all }

class _AgentV2RestConfirmRoute extends ConsumerStatefulWidget {
  final MiningActor actor;

  const _AgentV2RestConfirmRoute({required this.actor});

  @override
  ConsumerState<_AgentV2RestConfirmRoute> createState() =>
      _AgentV2RestConfirmRouteState();
}

class _AgentV2RestConfirmRouteState
    extends ConsumerState<_AgentV2RestConfirmRoute> {
  _RestSubmission? _submission;

  Future<void> _submit(_RestSubmission submission) async {
    final gameState = ref.read(gameControllerProvider);
    if (_submission != null || gameState.isActionLoading) return;
    if (submission == _RestSubmission.actor && widget.actor.nftId.isEmpty) {
      return;
    }
    if (submission == _RestSubmission.all && gameState.deployedActors.isEmpty) {
      return;
    }

    setState(() => _submission = submission);
    var didClose = false;
    try {
      final notifier = ref.read(gameControllerProvider.notifier);
      final didRest = submission == _RestSubmission.actor
          ? await notifier.rest(widget.actor.nftId)
          : await notifier.restAllActors();
      if (!mounted) return;

      if (didRest) {
        ref
            .read(weeklySalaryControllerProvider.notifier)
            .refreshAfterMutation();
        didClose = true;
        Navigator.of(context).pop(submission);
        return;
      }

      final error = ref.read(gameControllerProvider).lastError;
      if (error != null) {
        handleApiError(error, ctx: context, rootOverlay: true);
      }
    } finally {
      if (mounted && !didClose) setState(() => _submission = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final isSubmitting = _submission != null || gameState.isActionLoading;

    return PopScope(
      canPop: !isSubmitting,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isSubmitting ? null : () => Navigator.of(context).pop(false),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: const ColoredBox(color: StoryColors.overlayMid),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(StorySpacing.base),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 343),
                  child: SizedBox(
                    width: double.infinity,
                    child: AgentV2RestConfirmCard(
                      actor: widget.actor,
                      deployedActorCount: gameState.deployedCount,
                      isSubmittingActor: _submission == _RestSubmission.actor,
                      isSubmittingAll: _submission == _RestSubmission.all,
                      actionsEnabled: !isSubmitting,
                      onClose: () => Navigator.of(context).pop(false),
                      onRestActor: () => _submit(_RestSubmission.actor),
                      onRestAll: () => _submit(_RestSubmission.all),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AgentV2RestConfirmCard extends StatelessWidget {
  final MiningActor actor;
  final int deployedActorCount;
  final bool isSubmittingActor;
  final bool isSubmittingAll;
  final bool actionsEnabled;
  final VoidCallback onClose;
  final VoidCallback onRestActor;
  final VoidCallback onRestAll;

  const AgentV2RestConfirmCard({
    super.key,
    required this.actor,
    required this.deployedActorCount,
    required this.isSubmittingActor,
    required this.isSubmittingAll,
    required this.actionsEnabled,
    required this.onClose,
    required this.onRestActor,
    required this.onRestAll,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final divider = StoryColors.dividerOf(brightness);
    final actorName = actor.displayName.isEmpty ? '-' : actor.displayName;
    final levelName = _resolveLevelName(context, actor.level);
    final levelLabel = actor.level == null ? null : 'Lv${actor.level}';
    final actorMeta = [actorName, ?levelLabel, ?levelName].join(' · ');
    final canRestActor = actionsEnabled && actor.nftId.isNotEmpty;
    final canRestAll = actionsEnabled && deployedActorCount > 0;

    return Material(
      key: const ValueKey('agent-v2-rest-confirm-dialog'),
      color: StoryColors.cardOf(brightness),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 26,
              child: Row(
                children: [
                  const SizedBox.square(dimension: 24),
                  Expanded(
                    child: Text(
                      context.l10n.gameRestConfirmAction,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 26 / 18,
                        letterSpacing: -0.04,
                      ),
                    ),
                  ),
                  SizedBox.square(
                    dimension: 24,
                    child: IconButton(
                      key: const ValueKey('agent-v2-rest-close-button'),
                      onPressed: actionsEnabled ? onClose : null,
                      tooltip: context.l10n.commonClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 24,
                        height: 24,
                      ),
                      iconSize: 24,
                      color: foreground,
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            Column(
              children: [
                _RestActorSection(
                  actorMeta: actorMeta,
                  isSubmitting: isSubmittingActor,
                  onPressed: canRestActor ? onRestActor : null,
                ),
                const SizedBox(height: StorySpacing.base),
                SizedBox(
                  height: 16,
                  child: Row(
                    children: [
                      Expanded(child: Divider(height: 1, color: divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: StorySpacing.base,
                        ),
                        child: Text(
                          context.l10n.agentV2RefillOr,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 16 / 12,
                            letterSpacing: 0.04,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(height: 1, color: divider)),
                    ],
                  ),
                ),
                const SizedBox(height: StorySpacing.base),
                _RestAllSection(
                  actorCount: deployedActorCount,
                  isSubmitting: isSubmittingAll,
                  onPressed: canRestAll ? onRestAll : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _resolveLevelName(BuildContext context, int? level) {
    final l10n = context.l10n;
    return switch (level) {
      1 => l10n.gameActorLevelName1,
      2 => l10n.gameActorLevelName2,
      3 => l10n.gameActorLevelName3,
      4 => l10n.gameActorLevelName4,
      5 => l10n.gameActorLevelName5,
      _ => null,
    };
  }
}

class _RestActorSection extends StatelessWidget {
  final String actorMeta;
  final bool isSubmitting;
  final VoidCallback? onPressed;

  const _RestActorSection({
    required this.actorMeta,
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: StoryColors.mutedOf(brightness),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.base,
              vertical: StorySpacing.md,
            ),
            child: Text(
              actorMeta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: StoryColors.foregroundOf(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 26 / 18,
                letterSpacing: -0.04,
              ),
            ),
          ),
        ),
        const SizedBox(height: StorySpacing.md),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            key: const ValueKey('agent-v2-rest-actor-button'),
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: StoryColors.brandTealRed,
              foregroundColor: Colors.white,
              disabledBackgroundColor: StoryColors.brandTealRed.withValues(
                alpha: 0.4,
              ),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    context.l10n.agentV2RefillActorButton,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 20 / 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RestAllSection extends StatelessWidget {
  final int actorCount;
  final bool isSubmitting;
  final VoidCallback? onPressed;

  const _RestAllSection({
    required this.actorCount,
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: StoryColors.mutedOf(brightness),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.base,
              vertical: StorySpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.agentV2RestAll,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
                ),
                Text(
                  context.l10n.agentV2RestActorCount(actorCount),
                  key: const ValueKey('agent-v2-rest-all-count'),
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: StorySpacing.md),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            key: const ValueKey('agent-v2-rest-all-button'),
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: foreground,
              disabledForegroundColor: foreground.withValues(alpha: 0.4),
              side: BorderSide(
                color: StoryColors.dividerOf(brightness),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSubmitting
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                : Text(
                    context.l10n.agentV2RestAll,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 20 / 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
