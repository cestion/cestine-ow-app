import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../routes/video_feed_playlist_entry_seeds.dart';
import '../../routes/video_feed_navigation.dart';
import '../../styles/story_spacing.dart';
import '../../widgets/story_empty_card.dart';
import '../../widgets/story_loading.dart';
import '../../widgets/story_state_widget.dart';
import '../theater/drama_card.dart';
import '../theater/drama_card_vm_mapper.dart';

/// Cast dramas grid for the actor detail page — Figma「参演」双列剧场卡。
class ActorCastDramasList extends ConsumerWidget {
  final List<DramaListItem> castItems;
  final bool loadingMore;
  final bool hasMore;

  const ActorCastDramasList({
    super.key,
    required this.castItems,
    required this.loadingMore,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (castItems.isEmpty && loadingMore) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(StorySpacing.xl),
          child: StoryStateWidget.loading(
            message: context.l10n.dramaDetailLoading,
          ),
        ),
      );
    }
    if (castItems.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            StorySpacing.screenHorizontal,
            StorySpacing.xl,
            StorySpacing.screenHorizontal,
            StorySpacing.xl,
          ),
          child: StoryEmptyCard(label: context.l10n.searchNoData),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        StorySpacing.sm,
        StorySpacing.base,
        StorySpacing.sm,
        StorySpacing.xl,
      ),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final aspect = DramaCard.gridChildAspectRatioFor(
            constraints.crossAxisExtent,
            crossAxisSpacing: StorySpacing.sm,
          );
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: StorySpacing.sm,
              mainAxisSpacing: StorySpacing.base,
              childAspectRatio: aspect,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final d = castItems[index];
              return RepaintBoundary(
                child: GridDramaCard(
                  vm: DramaCardVmMapper.fromTheaterList(d, l10n: context.l10n),
                  onTap: () {
                    final dramaId = d.id;
                    if (dramaId.isEmpty) return;
                    final totalEpisodes = d.totalEpisodes ?? 1;
                    VideoFeedNavigation.open(
                      context,
                      dramaId: dramaId,
                      episodeNo: resumeEpisodeForDrama(
                        ref,
                        dramaId,
                        totalEpisodes: totalEpisodes,
                      ),
                      title: d.dramaTitle ?? '',
                      totalEpisodes: totalEpisodes,
                      coverUrl: d.dramaCoverUrl,
                      description: d.dramaDescription,
                      chrome:
                          VideoFeedPlaylistEntrySeeds.chromeFromDramaListItem(
                            d,
                          ),
                    );
                  },
                ),
              );
            }, childCount: castItems.length),
          );
        },
      ),
    );
  }
}

/// Optional footer spinner for cast pagination.
class ActorCastDramasLoadMoreFooter extends StatelessWidget {
  final bool loadingMore;
  final bool hasMore;

  const ActorCastDramasLoadMoreFooter({
    super.key,
    required this.loadingMore,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore && !loadingMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: StorySpacing.xl),
      child: Center(
        child: loadingMore
            ? const StoryLoading.inline()
            : const SizedBox(height: 20),
      ),
    );
  }
}
