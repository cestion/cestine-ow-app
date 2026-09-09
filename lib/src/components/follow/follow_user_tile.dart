import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../model/follow_models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../widgets/widgets.dart';
import '../profile/profile_colors.dart';
import 'follow_relation_button.dart';

/// Follow / fans / mutuals row — Figma `358:98084` / `358:88369` (粉丝),
/// mutuals without trailing CTA: `358:93249` (light) / `358:89948` (dark).
class FollowUserTile extends StatelessWidget {
  final FollowListItem item;
  final bool actionLoading;
  final bool hideRelationButton;
  final bool showMoreButton;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onRelationTap;
  final VoidCallback? onMoreTap;

  const FollowUserTile({
    super.key,
    required this.item,
    this.actionLoading = false,
    this.hideRelationButton = false,
    this.showMoreButton = true,
    this.onOpenProfile,
    this.onRelationTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final bio = item.bio?.trim();
    final subtitle = (bio != null && bio.isNotEmpty) ? bio : null;
    final nickname = item.nickname?.trim();
    final displayName = (nickname != null && nickname.isNotEmpty)
        ? nickname
        : l10n.publicProfileUserFallback(item.userId);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpenProfile,
            child: Row(
              children: [
                StoryAvatar(
                  imageUrl: item.avatarUrl,
                  userId: item.userId,
                  fallbackText: item.nickname,
                  size: 48,
                  ringColor: ProfileColors.coverAvatarRing,
                  ringWidth: ProfileColors.coverAvatarRingWidth,
                ),
                const SizedBox(width: StorySpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: StoryTextStyles.bodyMedium(
                          color: StoryColors.foregroundOf(brightness),
                        ).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: StorySpacing.xs),
                        Text(
                          subtitle,
                          style: StoryTextStyles.bodySmall(
                            color: ProfileColors.secondaryText(brightness),
                          ).copyWith(fontSize: 12, height: 16 / 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!hideRelationButton) ...[
          const SizedBox(width: StorySpacing.sm),
          FollowRelationButton(
            status: item.relationStatus,
            loading: actionLoading,
            onPressed: onRelationTap,
          ),
        ],
        if (showMoreButton) ...[
          const SizedBox(width: StorySpacing.sm),
          IconButton(
            onPressed: onMoreTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            icon: Icon(
              Icons.more_horiz,
              size: 24,
              color: ProfileColors.secondaryText(brightness),
            ),
          ),
        ],
      ],
    );
  }
}
