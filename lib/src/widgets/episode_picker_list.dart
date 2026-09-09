import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../styles/story_colors.dart';
import '../styles/story_format.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import 'story_cached_image.dart';
import 'story_loading.dart';
import 'story_state_widget.dart';

/// Cover + title + synopsis + like count, shared by the player sheet and
/// the drama-detail episodes tab.
class EpisodePickerListRow extends StatelessWidget {
  static const double coverWidth = 72;
  static const double coverHeight = 96;

  final DramaEpisodeListItem item;
  final bool isCurrent;
  final String title;
  final String? fallbackCoverUrl;
  final VoidCallback onTap;

  const EpisodePickerListRow({
    super.key,
    required this.item,
    required this.isCurrent,
    required this.title,
    this.fallbackCoverUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Episode list always prefers the drama cover; episode stills are only a
    // fallback when the drama cover is missing.
    final dramaCover = fallbackCoverUrl?.trim();
    final episodeCover = item.posterUrl?.trim();
    final coverUrl = (dramaCover != null && dramaCover.isNotEmpty)
        ? dramaCover
        : (episodeCover != null && episodeCover.isNotEmpty
              ? episodeCover
              : null);
    final description = item.description?.trim() ?? '';
    final likeCount = item.likeCount ?? 0;
    final titleColor = isCurrent
        ? StoryColors.brandTeal
        : StoryColors.foregroundOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: StoryRadius.brMd,
          border: isCurrent
              ? Border.all(
                  color: StoryColors.dramaOverlayStatBorderOf(brightness),
                  width: 0.5,
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: StoryRadius.brMd,
              child: SizedBox(
                width: coverWidth,
                height: coverHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverUrl != null && coverUrl.isNotEmpty
                        ? StoryCachedImage(
                            imageUrl: coverUrl,
                            width: coverWidth,
                            height: coverHeight,
                            memCacheWidth:
                                StoryCachedImage.memCacheForLogicalWidth(
                                  context,
                                  coverWidth,
                                ),
                            placeholder: ColoredBox(
                              color: StoryColors.mutedOf(brightness),
                            ),
                            errorWidget: ColoredBox(
                              color: StoryColors.mutedOf(brightness),
                            ),
                          )
                        : ColoredBox(color: StoryColors.mutedOf(brightness)),
                    if (isCurrent)
                      Center(
                        child: SvgPicture.asset(
                          'assets/drama/player_play.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: StorySpacing.md),
            Expanded(
              child: SizedBox(
                height: coverHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StoryTextStyles.headingMedium(
                          color: titleColor,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: StorySpacing.xs),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StoryTextStyles.bodySmall(color: muted),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            item.likedByMe == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 14,
                            color: item.likedByMe == true
                                ? StoryColors.likeActive
                                : muted,
                          ),
                          const SizedBox(width: StorySpacing.xs),
                          Text(
                            StoryFormat.formatCount(likeCount),
                            style: StoryTextStyles.bodySmall(color: muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paginated episode list sliver backed by [dramaEpisodeListProvider].
class EpisodePickerListSliver extends ConsumerWidget {
  final String dramaId;
  final int currentEpisode;
  final ValueChanged<int> onSelect;
  final String? fallbackCoverUrl;
  final EdgeInsetsGeometry padding;

  const EpisodePickerListSliver({
    super.key,
    required this.dramaId,
    required this.currentEpisode,
    required this.onSelect,
    this.fallbackCoverUrl,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(dramaEpisodeListProvider(dramaId));

    if (list.isLoading && list.items.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: StoryLoading.centered(),
      );
    }

    if (list.error != null && list.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: StoryStateWidget.error(
          message: context.l10nError(list.error!),
          actionLabel: l10n.commonRetry,
          onAction: () {
            unawaited(
              ref.read(dramaEpisodeListProvider(dramaId).notifier).load(),
            );
          },
        ),
      );
    }

    if (list.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: StoryStateWidget.empty(message: l10n.dramaEmpty),
      );
    }

    final items = list.items;
    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: StorySpacing.md),
              child: StoryLoading.centered(),
            );
          }
          if (index >= items.length - 3 &&
              list.hasMore &&
              !list.isLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(
                ref
                    .read(dramaEpisodeListProvider(dramaId).notifier)
                    .load(more: true),
              );
            });
          }
          final item = items[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == items.length - 1 ? 0 : StorySpacing.base,
            ),
            child: EpisodePickerListRow(
              item: item,
              isCurrent:
                  item.episodeNo != null && item.episodeNo == currentEpisode,
              title: l10n.playerEpisodeLabel(item.episodeNo ?? index + 1),
              fallbackCoverUrl: fallbackCoverUrl,
              onTap: () {
                final epNo = item.episodeNo;
                if (epNo == null || epNo < 1) return;
                onSelect(epNo);
              },
            ),
          );
        }, childCount: items.length + (list.isLoadingMore ? 1 : 0)),
      ),
    );
  }
}
