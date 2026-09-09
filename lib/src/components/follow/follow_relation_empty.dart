import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../styles/story_spacing.dart';
import '../profile/profile_colors.dart';

const _avatarLight = 'assets/common/avatar.svg';
const _avatarDark = 'assets/common/avatar_d.svg';

/// Shared Figma empty state for follow-relation tabs
/// (following `358:92329`, followers `358:93063`, mutuals `358:93299`).
class FollowRelationEmpty extends StatelessWidget {
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const FollowRelationEmpty({
    super.key,
    required this.message,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final buttonBg = ProfileColors.followPrimaryBg(brightness);
    final buttonFg = ProfileColors.followPrimaryFg(brightness);
    final showCta = ctaLabel != null && ctaLabel!.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                SvgPicture.asset(
                  isDark ? _avatarDark : _avatarLight,
                  width: 56,
                  height: 56,
                ),
                const SizedBox(height: StorySpacing.md),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                    color: ProfileColors.secondaryText(brightness),
                  ),
                ),
              ],
            ),
            if (showCta) ...[
              const SizedBox(height: StorySpacing.xl),
              IntrinsicWidth(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCta,
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      height: 44,
                      decoration: BoxDecoration(
                        color: buttonBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: StorySpacing.base,
                          vertical: 10,
                        ),
                        child: Center(
                          child: Text(
                            ctaLabel!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w400,
                              color: buttonFg,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
