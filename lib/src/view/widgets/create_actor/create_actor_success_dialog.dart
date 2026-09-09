import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';

const _successCheckAsset = 'assets/common/create_actor_success_check.svg';

/// 发行角色 IP 成功弹窗 — Figma 暗色 `841:167680` / 亮色 `1061:116905`。
class CreateActorSuccessDialog extends StatelessWidget {
  final String actorName;
  final String actorId;
  final VoidCallback onClose;
  final VoidCallback onView;

  const CreateActorSuccessDialog({
    super.key,
    required this.actorName,
    required this.actorId,
    required this.onClose,
    required this.onView,
  });

  static Future<void> show(
    BuildContext context, {
    required String actorName,
    required String actorId,
    required VoidCallback onClose,
    required VoidCallback onView,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CreateActorSuccessDialog(
        actorName: actorName,
        actorId: actorId,
        onClose: () {
          Navigator.of(dialogContext).pop();
          onClose();
        },
        onView: () {
          Navigator.of(dialogContext).pop();
          onView();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final fg = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.commentTabInactiveFgOf(brightness);
    final tipColor = brightness == Brightness.dark
        ? const Color(0xFFFFD60A)
        : StoryColors.warning;
    final dialogBg = brightness == Brightness.dark
        ? StoryColors.darkBackground
        : StoryColors.lightCard;
    final cancelBorder = StoryColors.actorSignSheetCancelBorderOf(brightness);
    final confirmBg = StoryColors.actorSignSheetConfirmBgOf(brightness);
    final confirmFg = StoryColors.actorSignSheetConfirmFgOf(brightness);
    final displayName = actorName.trim().isEmpty ? '—' : actorName.trim();
    final displayId = actorId.trim().isEmpty ? '—' : actorId.trim();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
      backgroundColor: dialogBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Center(
                child: SvgPicture.asset(
                  _successCheckAsset,
                  width: 53.33,
                  height: 53.33,
                ),
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            Text(
              l10n.createActorSuccessTitle(displayName),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 26 / 18,
                letterSpacing: -0.04,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(height: StorySpacing.md),
            Text(
              l10n.createActorSuccessDesc(displayId),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
                color: secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.createActorSuccessTip,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
                color: tipColor,
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: BorderSide(color: cancelBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.createActorCloseButton,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: StorySpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onView,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: confirmBg,
                      foregroundColor: confirmFg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.createActorViewButton,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w700,
                        color: confirmFg,
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
