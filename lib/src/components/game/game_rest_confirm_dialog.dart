import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';

Future<bool?> showGameRestConfirmDialog(
  BuildContext context,
  MiningActor actor,
) {
  return showGameRestConfirmDialogWithMeta(context, actor);
}

Future<bool?> showGameRestConfirmDialogWithMeta(
  BuildContext context,
  MiningActor actor, {
  int? staminaLimit,
  String? restoreFeeLabel,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: StoryColors.overlayMid,
    builder: (ctx) => _GameRestConfirmDialog(
      actor: actor,
      staminaLimit: staminaLimit,
      restoreFeeLabel: restoreFeeLabel,
    ),
  );
}

class _GameRestConfirmDialog extends StatelessWidget {
  final MiningActor actor;
  final int? staminaLimit;
  final String? restoreFeeLabel;

  const _GameRestConfirmDialog({
    required this.actor,
    this.staminaLimit,
    this.restoreFeeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final actorName = actor.displayName.isNotEmpty ? actor.displayName : '-';
    final levelLabel = actor.level != null ? 'Lv${actor.level}' : null;
    final levelName = _resolveLevelName(context, actor.level);
    final codeLabel = actor.actorCode?.trim();
    final metaParts = <String>[
      if (levelName != null && levelName.isNotEmpty) levelName,
      if (levelLabel != null && levelLabel.isNotEmpty) levelLabel,
      if (codeLabel != null && codeLabel.isNotEmpty) codeLabel,
    ];
    final metaLabel = metaParts.join(' · ');
    final l10n = context.l10n;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomSpacing = bottomInset > 34 ? bottomInset : 30.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StoryColors.backgroundOf(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
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
                      color: brightness == Brightness.light
                          ? const Color(0xFFF0F0F3)
                          : StoryColors.dividerOf(brightness),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StorySpacing.base,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.gameRecallConfirm,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 26 / 18,
                        letterSpacing: -0.04,
                        color: StoryColors.foregroundOf(brightness),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.gameRestConfirmDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                        letterSpacing: 0.04,
                        color: StoryColors.mutedForegroundOf(brightness),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(minHeight: 78),
                      padding: const EdgeInsets.all(StorySpacing.base),
                      decoration: BoxDecoration(
                        color: brightness == Brightness.light
                            ? const Color(0xFFF6F6F6)
                            : StoryColors.mutedOf(brightness),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            actorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 24 / 16,
                              color: StoryColors.foregroundOf(brightness),
                            ),
                          ),
                          if (metaLabel.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              metaLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 16 / 12,
                                letterSpacing: 0.04,
                                color: StoryColors.mutedForegroundOf(
                                  brightness,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        SizedBox(
                          width: 92,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              side: BorderSide(
                                color: StoryColors.dividerOf(brightness),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n.commonCancel,
                                maxLines: 1,
                                style:
                                    const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      height: 20 / 14,
                                    ).copyWith(
                                      color: StoryColors.foregroundOf(
                                        brightness,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brightness == Brightness.light
                                    ? const Color(0xFF212225)
                                    : StoryColors.foregroundOf(brightness),
                                foregroundColor: StoryColors.backgroundOf(
                                  brightness,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  l10n.gameRestConfirmAction,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 20 / 14,
                                    color: StoryColors.backgroundOf(brightness),
                                  ),
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
              const SizedBox(height: 16),
              SizedBox(height: bottomSpacing),
            ],
          ),
        ),
      ),
    );
  }

  String? _resolveLevelName(BuildContext context, int? level) {
    if (level == null) return null;
    final l10n = context.l10n;
    switch (level) {
      case 1:
        return l10n.gameActorLevelName1;
      case 2:
        return l10n.gameActorLevelName2;
      case 3:
        return l10n.gameActorLevelName3;
      case 4:
        return l10n.gameActorLevelName4;
      case 5:
        return l10n.gameActorLevelName5;
      default:
        return null;
    }
  }
}
