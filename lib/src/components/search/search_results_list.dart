import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/search_state.dart';
import '../../core/story_constants.dart';
import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../routes/actor_detail_navigation.dart';
import '../../routes/video_feed_playlist_entry_seeds.dart';
import '../../routes/video_feed_navigation.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../widgets/story_cached_image.dart';
import 'search_actor_card.dart';

/// Legacy overlay results listing — kept for [showStorySearch] compatibility.
class SearchResultsList extends ConsumerWidget {
  final List<String> history;
  final ValueChanged<String> onHistoryTap;
  final VoidCallback onClearHistory;

  const SearchResultsList({
    super.key,
    required this.history,
    required this.onHistoryTap,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final searchType = ref.watch(
      searchControllerProvider.select((s) => s.activeTab),
    );
    final searchDramas = ref.watch(
      searchControllerProvider.select((s) => s.dramas),
    );
    final searchActors = ref.watch(
      searchControllerProvider.select((s) => s.actors),
    );

    final dramas = searchType == SearchType.dramas
        ? searchDramas
        : const <FeedItem>[];
    final actors = searchType == SearchType.actors
        ? searchActors
        : const <ActorCollection>[];

    if (dramas.isEmpty && actors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(StorySpacing.xl),
          child: Text(l10n.searchEmpty, style: StoryTextStyles.bodyMedium()),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dramas.isNotEmpty)
            ...dramas.map(
              (d) => RepaintBoundary(
                child: SearchDramaCard(
                  drama: d.toDramaListItem(),
                  onTap: () {
                    if (d.isShortVideo) {
                      final episodeId = d.episodeId?.trim() ?? '';
                      if (episodeId.isEmpty) return;
                      VideoFeedNavigation.openShortVideo(
                        context,
                        episodeId: episodeId,
                        title: d.title ?? '',
                        coverUrl: d.coverUrl,
                        description: d.description,
                        chrome: VideoFeedPlaylistEntrySeeds.chromeFromFeedItem(
                          d,
                        ),
                      );
                      return;
                    }
                    final dramaId = d.dramaId?.trim() ?? '';
                    if (dramaId.isEmpty) return;
                    final totalEpisodes = d.totalEpisodes ?? 1;
                    VideoFeedNavigation.open(
                      context,
                      dramaId: dramaId,
                      episodeNo: resumeEpisodeForDrama(
                        ref,
                        dramaId,
                        totalEpisodes: totalEpisodes < 1 ? 1 : totalEpisodes,
                      ),
                      title: d.title ?? '',
                      totalEpisodes: totalEpisodes < 1 ? 1 : totalEpisodes,
                      coverUrl: d.coverUrl,
                      description: d.description,
                      chrome: VideoFeedPlaylistEntrySeeds.chromeFromFeedItem(d),
                    );
                  },
                ),
              ),
            ),
          if (actors.isNotEmpty)
            ...actors.map(
              (a) => RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: StorySpacing.base),
                  child: SearchActorCard(
                    actor: a,
                    onTap: () {
                      final id = a.id;
                      if (id == null || id.isEmpty) return;
                      openActorDetail(context, actorId: id, preview: a);
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Spaced list item card for search results, matching Figma "剧场卡片v2".
class SearchDramaCard extends StatelessWidget {
  final DramaListItem drama;
  final VoidCallback? onTap;

  const SearchDramaCard({super.key, required this.drama, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final actorsStr =
        drama.actorCollections?.map((a) => a.name).join('，') ?? '';
    final episodeCount = drama.totalEpisodes ?? 0;
    final subtitleText = actorsStr.isNotEmpty
        ? l10n.searchDramaEpisodesWithCast(episodeCount, actorsStr)
        : l10n.dramaAllEpisodesFull(episodeCount);
    final tagsStr = drama.tags?.join(' · ') ?? '';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 64,
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 76.8,
                height: 64,
                child:
                    drama.dramaCoverUrl != null &&
                        drama.dramaCoverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: drama.dramaCoverUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
                          context,
                          StoryImageCache.searchThumbnail,
                        ),
                        placeholder: (context, _) =>
                            Container(color: Colors.grey.shade900),
                        errorWidget: (context, _, _) =>
                            Container(color: Colors.grey.shade900),
                      )
                    : Container(color: Colors.grey.shade900),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    drama.dramaTitle ?? '',
                    style: StoryTextStyles.bodyMedium(
                      color: StoryColors.foregroundOf(theme.brightness),
                    ).copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitleText,
                    style: StoryTextStyles.caption(
                      color: StoryColors.mutedForegroundOf(theme.brightness),
                    ).copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    tagsStr,
                    style: StoryTextStyles.caption(
                      color: StoryColors.mutedForegroundOf(theme.brightness),
                    ).copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
