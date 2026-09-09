import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';

/// Figma `637:75116`：一键演出确认弹窗。
Future<bool?> showAgentV2PerformAllConfirmDialog(
  BuildContext context, {
  required int deployCount,
}) {
  return showGeneralDialog<bool>(
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
        _PerformAllConfirmRoute(deployCount: deployCount),
  );
}

class _PerformAllConfirmRoute extends StatelessWidget {
  final int deployCount;

  const _PerformAllConfirmRoute({required this.deployCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(false),
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
                  child: _PerformAllConfirmCard(deployCount: deployCount),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PerformAllConfirmCard extends StatelessWidget {
  final int deployCount;

  const _PerformAllConfirmCard({required this.deployCount});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final confirmBackground = StoryColors.actorSignSheetConfirmBgOf(brightness);
    final confirmForeground = StoryColors.actorSignSheetConfirmFgOf(brightness);

    return Material(
      key: const ValueKey('agent-v2-perform-all-confirm-dialog'),
      color: StoryColors.cardOf(brightness),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.agentV2PerformAllTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 26 / 18,
                    letterSpacing: -0.04,
                  ),
                ),
                const SizedBox(height: StorySpacing.xs),
                Text(
                  context.l10n.agentV2PerformAllDescription,
                  textAlign: TextAlign.center,
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
            const SizedBox(height: StorySpacing.xl),
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
                  context.l10n.agentV2PerformAllCount(deployCount),
                  key: const ValueKey('agent-v2-perform-all-count'),
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
            ),
            const SizedBox(height: StorySpacing.xl),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      key: const ValueKey('agent-v2-perform-all-cancel-button'),
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: foreground,
                        side: BorderSide(
                          color: StoryColors.dividerOf(brightness),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.l10n.commonCancel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: StorySpacing.md),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      key: const ValueKey(
                        'agent-v2-perform-all-confirm-button',
                      ),
                      onPressed: deployCount > 0
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmBackground,
                        foregroundColor: confirmForeground,
                        disabledBackgroundColor: confirmBackground.withValues(
                          alpha: 0.4,
                        ),
                        disabledForegroundColor: confirmForeground.withValues(
                          alpha: 0.6,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.l10n.commonConfirm,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
