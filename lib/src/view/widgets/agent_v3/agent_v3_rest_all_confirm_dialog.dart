import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';

/// 展示一键休息确认弹窗，确认后由页面统一提交批量召回请求。
Future<bool?> showAgentV3RestAllConfirmDialog(
  BuildContext context, {
  required int actorCount,
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
    pageBuilder: (context, animation, secondaryAnimation) => Stack(
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
              padding: const EdgeInsets.all(16),
              child: AgentV3RestAllConfirmCard(
                actorCount: actorCount,
                onCancel: () => Navigator.of(context).pop(false),
                onConfirm: actorCount > 0
                    ? () => Navigator.of(context).pop(true)
                    : null,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// 独立展示层，严格对齐参考图中的 343 × 220 弹窗。
class AgentV3RestAllConfirmCard extends StatelessWidget {
  const AgentV3RestAllConfirmCard({
    super.key,
    required this.actorCount,
    required this.onCancel,
    this.onConfirm,
  });

  final int actorCount;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final primaryBackground = StoryColors.actorSignSheetConfirmBgOf(brightness);
    final primaryForeground = StoryColors.actorSignSheetConfirmFgOf(brightness);

    return Material(
      key: const ValueKey('agent-v3-rest-all-confirm-dialog'),
      color: StoryColors.cardOf(brightness),
      elevation: 8,
      shadowColor: const Color(0x40000000),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 343,
        height: 220,
        child: MediaQuery.withNoTextScaling(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.agentV3RestAll,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 26 / 18,
                    letterSpacing: -0.04,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.agentV3RestAllDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                    letterSpacing: 0.04,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  key: const ValueKey('agent-v3-rest-all-count'),
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StoryColors.mutedOf(brightness),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.l10n.agentV2PerformAllCount(actorCount),
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
                const SizedBox(height: 24),
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey(
                            'agent-v3-rest-all-cancel-button',
                          ),
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: foreground,
                            side: BorderSide(
                              color: StoryColors.dividerOf(brightness),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: _buttonTextStyle,
                          ),
                          child: Text(context.l10n.commonCancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey(
                            'agent-v3-rest-all-confirm-button',
                          ),
                          onPressed: onConfirm,
                          style: FilledButton.styleFrom(
                            elevation: 0,
                            backgroundColor: primaryBackground,
                            disabledBackgroundColor: primaryBackground
                                .withValues(alpha: 0.4),
                            foregroundColor: primaryForeground,
                            disabledForegroundColor: primaryForeground
                                .withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: _buttonTextStyle,
                          ),
                          child: Text(context.l10n.agentV3RestAll),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const TextStyle _buttonTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
  );
}
