import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../widgets/story_info_dialog.dart';

/// Warning badge shown when the current user's trust coefficient is below 1.
class GameRiskAccountBadge extends StatelessWidget {
  const GameRiskAccountBadge({super.key});

  Future<void> _showDialog(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    return StoryInfoDialog.show(
      context: context,
      title: l10n.gameRiskAccount,
      actionLabel: l10n.commonOk,
      content: Text(
        l10n.gameRiskAccountDescription,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w500,
          color: StoryColors.mutedForegroundOf(brightness),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.gameRiskAccount,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDialog(context),
          borderRadius: BorderRadius.circular(49),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: StoryColors.pending.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(49),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: StoryColors.pending,
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.gameRiskAccount,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    letterSpacing: 0.04,
                    fontWeight: FontWeight.w400,
                    color: StoryColors.pending,
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
