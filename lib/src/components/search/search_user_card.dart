import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/story_l10n.dart';
import '../../model/follow_models.dart';
import '../../model/user_search_models.dart';
import '../../provider/app_providers.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../widgets/widgets.dart';
import '../follow/follow_relation_button.dart';

/// 搜索「用户」结果卡 — Figma `655:126282` / `655:132941`。
///
/// 字段：头像、昵称、关注、粉丝、获赞、简介（1 行）。
class SearchUserCard extends ConsumerWidget {
  final UserSearchItem item;
  final bool actionLoading;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onRelationTap;

  const SearchUserCard({
    super.key,
    required this.item,
    this.actionLoading = false,
    this.onOpenProfile,
    this.onRelationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final fg = StoryColors.foregroundOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);
    final cardBg = brightness == Brightness.dark
        ? StoryColors.darkMuted
        : Colors.white;
    final isLoggedIn = ref.watch(
      authControllerProvider.select((a) => a.isLoggedIn),
    );
    final showFollow = !isLoggedIn || !item.isSelf;
    final relationStatus = isLoggedIn
        ? item.relationStatus
        : FollowRelationStatus.none;
    final name = item.nickname?.trim().isNotEmpty == true
        ? item.nickname!.trim()
        : item.userId;

    return GestureDetector(
      onTap: onOpenProfile,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(StorySpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        StoryAvatar(
                          imageUrl: item.avatarUrl,
                          userId: item.userId,
                          fallbackText: item.nickname,
                          size: 44,
                        ),
                        const SizedBox(width: StorySpacing.md),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              height: 22 / 15,
                              fontWeight: FontWeight.w700,
                              color: fg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showFollow) ...[
                    const SizedBox(width: StorySpacing.md),
                    FollowRelationButton(
                      status: relationStatus,
                      loading: actionLoading,
                      onPressed: onRelationTap,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: StorySpacing.sm),
              Row(
                children: [
                  _Stat(
                    count: item.followerCount,
                    label: l10n.publicProfileFollowers,
                    fg: fg,
                    muted: muted,
                  ),
                  const SizedBox(width: StorySpacing.base),
                  _Stat(
                    count: item.totalLikeCount,
                    label: l10n.profileLikesReceived,
                    fg: fg,
                    muted: muted,
                  ),
                ],
              ),
              if ((item.bio ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: StorySpacing.sm),
                Text(
                  item.bio!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    letterSpacing: 0.04,
                    color: muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String count;
  final String label;
  final Color fg;
  final Color muted;

  const _Stat({
    required this.count,
    required this.label,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: count,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          TextSpan(
            text: ' $label',
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              letterSpacing: 0.04,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}
