import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';

const _blockUserOffAsset = 'assets/common/user_off_block.svg';
const _blockUserOnAsset = 'assets/common/user_on_block.svg';
const _reportAsset = 'assets/drama/report.svg';

enum PublicProfileMoreAction { block, unblock, report }

/// More-actions sheet for another user's profile.
///
/// Matches Figma `1003:148711`: a 16px-radius secondary sheet, 48x4 handle,
/// and a single 12px-radius card containing the block and report rows.
class PublicProfileMoreSheet {
  PublicProfileMoreSheet._();

  static Future<PublicProfileMoreAction?> show(
    BuildContext context, {
    required bool blockedByMe,
  }) {
    return showModalBottomSheet<PublicProfileMoreAction>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: StoryColors.overlayMid,
      builder: (context) =>
          _PublicProfileMoreSheetBody(blockedByMe: blockedByMe),
    );
  }
}

class _PublicProfileMoreSheetBody extends StatelessWidget {
  const _PublicProfileMoreSheetBody({required this.blockedByMe});

  final bool blockedByMe;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final foreground = StoryColors.foregroundOf(brightness);
    final sheetBackground = isDark
        ? StoryColors.darkElevatedSurface
        : StoryColors.lightSheetSecondary;
    final cardBackground = isDark ? StoryColors.darkCard : Colors.white;
    final dividerColor = isDark
        ? const Color(0x0FFFFFFF)
        : const Color(0x0F000000);
    final handleColor = isDark
        ? const Color(0xFF3A3A3C)
        : const Color(0xFFC3C5CE);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(44, bottomInset + 10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: cardBackground,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileActionRow(
                  label: blockedByMe
                      ? context.l10n.publicProfileUnblock
                      : context.l10n.publicProfileBlock,
                  leading: SvgPicture.asset(
                    blockedByMe ? _blockUserOnAsset : _blockUserOffAsset,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  ),
                  onTap: () => Navigator.of(context).pop(
                    blockedByMe
                        ? PublicProfileMoreAction.unblock
                        : PublicProfileMoreAction.block,
                  ),
                ),
                Divider(
                  height: 0,
                  thickness: 0.5,
                  indent: 52,
                  color: dividerColor,
                ),
                _ProfileActionRow(
                  label: context.l10n.playerReport,
                  leading: SvgPicture.asset(
                    _reportAsset,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(PublicProfileMoreAction.report),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  const _ProfileActionRow({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = StoryColors.foregroundOf(Theme.of(context).brightness);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(width: 24, height: 24, child: leading),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    height: 22 / 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
