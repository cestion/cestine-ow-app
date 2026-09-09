import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';

/// Figma `198:44146`：升级条件不足时展示的居中弹窗。
Future<void> showAgentV2UpgradeRequirementsDialog(
  BuildContext context, {
  required String actorName,
  String? actorCode,
  required int completionRemaining,
  required int materialRemaining,
  VoidCallback? onWatchDramas,
  VoidCallback? onGetActors,
  VoidCallback? onCreateDrama,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, _, _) => AgentV2UpgradeRequirementsDialog(
      actorName: actorName,
      actorCode: actorCode,
      completionRemaining: completionRemaining,
      materialRemaining: materialRemaining,
      onWatchDramas: onWatchDramas,
      onGetActors: onGetActors,
      onCreateDrama: onCreateDrama,
    ),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
        child: child,
      ),
    ),
  );
}

class AgentV2UpgradeRequirementsDialog extends StatelessWidget {
  final String actorName;
  final String? actorCode;
  final int completionRemaining;
  final int materialRemaining;
  final VoidCallback? onWatchDramas;
  final VoidCallback? onGetActors;
  final VoidCallback? onCreateDrama;

  const AgentV2UpgradeRequirementsDialog({
    super.key,
    required this.actorName,
    this.actorCode,
    required this.completionRemaining,
    required this.materialRemaining,
    this.onWatchDramas,
    this.onGetActors,
    this.onCreateDrama,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final displayName = actorName.trim().isEmpty ? '-' : actorName.trim();
    final code = actorCode?.trim();
    final title = [
      l10n.agentV2UpgradeRequirementsTitle(displayName),
      if (code != null && code.isNotEmpty) code,
    ].join(' ');

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: const ColoredBox(color: StoryColors.overlayMid),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
              backgroundColor: StoryColors.cardOf(brightness),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                key: const ValueKey('agent-v2-upgrade-requirements-card'),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        key: const ValueKey(
                          'agent-v2-upgrade-requirements-title',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: StoryColors.foregroundOf(brightness),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 26 / 18,
                          letterSpacing: -0.04,
                        ),
                      ),
                      if (completionRemaining > 0) ...[
                        const SizedBox(height: 24),
                        _RequirementSection(
                          title: l10n.agentV2UpgradeCompletionRemaining(
                            completionRemaining,
                          ),
                          description: l10n.agentV2UpgradeCompletionHint,
                          buttons: [
                            _RequirementButtonData(
                              key: const ValueKey(
                                'agent-v2-upgrade-watch-dramas',
                              ),
                              label: l10n.agentV2UpgradeWatchDramas,
                              onTap: onWatchDramas,
                            ),
                            _RequirementButtonData(
                              key: const ValueKey(
                                'agent-v2-upgrade-create-drama',
                              ),
                              label: l10n.agentV2UpgradeCreateDrama,
                              onTap: onCreateDrama,
                            ),
                          ],
                        ),
                      ],
                      if (materialRemaining > 0) ...[
                        const SizedBox(height: 24),
                        _RequirementSection(
                          title: l10n.agentV2UpgradeMaterialsRemaining(
                            materialRemaining,
                          ),
                          description: l10n.agentV2UpgradeMaterialsHint(
                            displayName,
                          ),
                          buttons: [
                            _RequirementButtonData(
                              key: const ValueKey(
                                'agent-v2-upgrade-get-actors',
                              ),
                              label: l10n.agentV2UpgradeGetActors,
                              onTap: onGetActors,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      _CloseButton(onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RequirementSection extends StatelessWidget {
  final String title;
  final String description;
  final List<_RequirementButtonData> buttons;

  const _RequirementSection({
    required this.title,
    required this.description,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            color: StoryColors.foregroundOf(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 20 / 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            color: StoryColors.mutedForegroundOf(brightness),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 16 / 12,
            letterSpacing: 0.04,
          ),
        ),
        for (final button in buttons) ...[
          const SizedBox(height: 12),
          _RequirementButton(data: button),
        ],
      ],
    );
  }
}

class _RequirementButtonData {
  final Key key;
  final String label;
  final VoidCallback? onTap;

  const _RequirementButtonData({
    required this.key,
    required this.label,
    this.onTap,
  });
}

class _RequirementButton extends StatelessWidget {
  final _RequirementButtonData data;

  const _RequirementButton({required this.data});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: StoryColors.actorSignSheetConfirmBgOf(brightness),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: data.key,
        onTap: data.onTap ?? () {},
        child: SizedBox(
          height: 36,
          child: Center(
            child: Text(
              data.label,
              style: TextStyle(
                color: StoryColors.actorSignSheetConfirmFgOf(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 20 / 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: StoryColors.actorSignSheetCancelBorderOf(brightness),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('agent-v2-upgrade-requirements-close'),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              context.l10n.commonClose,
              style: TextStyle(
                color: StoryColors.foregroundOf(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 20 / 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
