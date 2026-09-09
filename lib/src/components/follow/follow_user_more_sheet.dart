import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';

const _userMinusIcon = 'assets/follow/user_minus.svg';

/// Figma remove-follower sheet (`358:96338` dark / `358:98097` light).
///
/// Returns `true` when the user confirms「移除粉丝」.
class FollowUserMoreSheet {
  FollowUserMoreSheet._();

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _RemoveFollowerSheetBody(),
    );
  }
}

class _RemoveFollowerSheetBody extends StatelessWidget {
  const _RemoveFollowerSheetBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final sheetBg = isDark
        ? StoryColors.darkElevatedSurface
        : StoryColors.lightSheetSecondary;
    final rowBg = isDark ? StoryColors.darkCard : Colors.white;
    final fg = StoryColors.foregroundOf(brightness);
    final handleColor = isDark
        ? const Color(0xFF3A3A3C)
        : const Color(0xFFC3C5CE);
    final cancelBorder = StoryColors.dividerOf(brightness);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Paint sheet color to the physical bottom edge, then pad content for the
    // home-indicator inset. Wrapping [SafeArea] outside the colored container
    // leaves a transparent gap under the sheet on notched devices.
    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
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
          Material(
            color: rowBg,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(true),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      _userMinusIcon,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.followRemoveFollower,
                      style: TextStyle(
                        fontSize: 15,
                        height: 22 / 15,
                        fontWeight: FontWeight.w400,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: StorySpacing.base),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cancelBorder),
                foregroundColor: fg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.commonCancel,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
