import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/story_toast.dart';
import '../../../components/creator/creator_status_badges.dart';
import '../../../components/creator/creator_video_management_card.dart';
import '../../../controller/drama_management_state.dart';
import '../../../controller/playlist_continuation.dart';
import '../../../controller/playlist_continuation_sync.dart';
import '../../../core/result.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/route_args.dart';
import '../../../routes/route_names.dart';
import '../../../routes/video_feed_navigation.dart';
import '../../../styles/story_spacing.dart';
import '../../../widgets/widgets.dart';
import '../../creator_page_v2.dart';
import '../../../foundation/navigator.dart';

/// Builds the status filter displayed above the video list.
typedef CreatorVideoStatusFiltersBuilder =
    Widget Function(
      DramaManagementStatus selectedStatus,
      ValueChanged<DramaManagementStatus> onSelected,
    );

/// Creator video management tab with status filtering and cursor pagination.
class CreatorVideoTabV2 extends ConsumerStatefulWidget {
  final VoidCallback onCreateContent;

  const CreatorVideoTabV2({super.key, required this.onCreateContent});

  @override
  ConsumerState<CreatorVideoTabV2> createState() => _CreatorVideoTabV2State();
}

class _CreatorVideoTabV2State extends ConsumerState<CreatorVideoTabV2>
    with AutomaticKeepAliveClientMixin {
  VideoFeedPlaylistEntry? _entryFor(
    CreatorShortVideo item, {
    required String? creatorName,
    required String creatorUserId,
    required String? creatorAvatarUrl,
  }) {
    if (creatorContentPlaybackAvailability(item.status) !=
        CreatorContentPlaybackAvailability.playable) {
      return null;
    }
    return VideoFeedPlaylistEntry.shortVideo(
      episodeId: item.episodeId.toString(),
      title: item.title,
      coverUrl: item.posterUrl,
      description: item.description,
      creatorName: creatorName,
      creatorUserId: creatorUserId,
      creatorAvatarUrl: creatorAvatarUrl,
      likeCount: item.likeCount,
      commentCount: item.commentCount,
      favoriteCount: item.favoriteCount,
    );
  }

  Future<void> _openVideo(
    CreatorShortVideo video,
    List<CreatorShortVideo> loadedVideos,
  ) async {
    switch (creatorContentPlaybackAvailability(video.status)) {
      case CreatorContentPlaybackAvailability.deleted:
        StoryToast.error(context, context.l10n.creatorWorkNotFound);
        return;
      case CreatorContentPlaybackAvailability.unavailable:
        StoryToast.error(context, context.l10n.creatorWorkNotPublished);
        return;
      case CreatorContentPlaybackAvailability.playable:
        break;
    }

    final profile = ref.read(authControllerProvider).profile;
    final creatorName = profile?.nickname?.trim();
    final profileUserId = (profile?.userId ?? profile?.id)?.trim();
    final creatorUserId = profileUserId != null && profileUserId.isNotEmpty
        ? profileUserId
        : video.userId.toString();
    final creatorAvatarUrl = profile?.avatarUrl?.trim();

    // Only public, playable videos belong in the vertical playback queue.
    final playlist = <VideoFeedPlaylistEntry>[];
    var playlistIndex = -1;
    for (final item in loadedVideos) {
      final entry = _entryFor(
        item,
        creatorName: creatorName,
        creatorUserId: creatorUserId,
        creatorAvatarUrl: creatorAvatarUrl,
      );
      if (entry == null) continue;
      if (item.episodeId == video.episodeId) {
        playlistIndex = playlist.length;
      }
      playlist.add(entry);
    }

    if (playlistIndex < 0 || playlist.isEmpty) {
      StoryToast.error(context, context.l10n.creatorWorkNotPublished);
      return;
    }

    final seenKeys = {for (final e in playlist) e.playbackKey};
    final continuation = CallbackPlaylistContinuation(
      hasMoreCallback: () {
        if (!mounted) return false;
        return ref.read(creatorVideoManagementControllerProvider).hasMore;
      },
      loadMoreCallback: () => _loadMoreCreatorVideoEntries(
        creatorName: creatorName,
        creatorUserId: creatorUserId,
        creatorAvatarUrl: creatorAvatarUrl,
        seenKeys: seenKeys,
      ),
    );

    await VideoFeedNavigation.openPlaylist(
      context,
      playlist: playlist,
      initialIndex: playlistIndex,
      continuation: continuation,
    );
  }

  Future<Result<PlaylistContinuationPage>> _loadMoreCreatorVideoEntries({
    required String? creatorName,
    required String creatorUserId,
    required String? creatorAvatarUrl,
    required Set<String> seenKeys,
  }) async {
    if (!mounted) {
      return Result.success(
        const PlaylistContinuationPage(entries: [], hasMore: false),
      );
    }
    final provider = creatorVideoManagementControllerProvider;
    final state = ref.read(provider);
    final page = await syncPlaylistContinuation<CreatorShortVideo>(
      items: state.items,
      hasMore: state.hasMore,
      isPageLoading: state.isPageLoading,
      seenKeys: seenKeys,
      toEntry: (item) => _entryFor(
        item,
        creatorName: creatorName,
        creatorUserId: creatorUserId,
        creatorAvatarUrl: creatorAvatarUrl,
      ),
      loadMore: () => ref.read(provider.notifier).loadMore(),
      readItems: () => ref.read(provider).items,
      readHasMore: () => ref.read(provider).hasMore,
      readIsPageLoading: () => ref.read(provider).isPageLoading,
    );
    if (!mounted) {
      return Result.success(
        const PlaylistContinuationPage(entries: [], hasMore: false),
      );
    }
    return Result.success(page);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final state = ref.read(creatorVideoManagementControllerProvider);
      if (state.items.isEmpty && !state.isLoading) {
        unawaited(
          ref.read(creatorVideoManagementControllerProvider.notifier).refresh(),
        );
      }
    });
  }

  Future<bool> _deleteVideo(CreatorShortVideo video) async {
    final notifier = ref.read(
      creatorVideoManagementControllerProvider.notifier,
    );
    final deleted = await notifier.deleteVideo(video.episodeId);
    if (!mounted) return false;

    if (!deleted) {
      final error = ref
          .read(creatorVideoManagementControllerProvider)
          .lastError;
      if (error != null) {
        StoryToast.error(context, context.l10nError(error));
      }
      return false;
    }

    // Keep the count shown in the parent tab header in sync with the list.
    unawaited(
      ref.read(creatorManagementOverviewControllerProvider.notifier).refresh(),
    );
    return true;
  }

  Future<void> _openEditor(CreatorShortVideo video) async {
    final result = await context.storyPushForResult<Object?>(RouteNames.publishVideo,
      arguments: {'episodeId': video.episodeId});
    if (!mounted || result is! ShortVideo) return;

    await ref.read(creatorVideoManagementControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(creatorVideoManagementControllerProvider);
    final notifier = ref.read(
      creatorVideoManagementControllerProvider.notifier,
    );

    // Match the aspect ratio used by the SliverLayoutBuilder below so the
    // skeleton cards share the same height as the real cards.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth - 24) / 2;
    final skeletonAspectRatio =
        cardWidth /
        (cardWidth * 310 / 232 + creatorVideoManagementCardInfoHeight);

    return Stack(
      children: [
        Column(
          children: [
            CreatorStatusFilters(
              selectedStatus: state.currentStatus,
              onSelected: notifier.selectStatus,
            ),
            Expanded(
              child: state.isLoading && state.items.isEmpty
                  ? CreatorManagementGridSkeleton(
                      childAspectRatio: skeletonAspectRatio,
                    )
                  : StoryPaginatedScrollView(
                      key: const PageStorageKey<String>('creator-v2-videos'),
                      itemCount: state.items.length,
                      hasMore: state.hasMore,
                      // The pagination state distinguishes the first-page load
                      // from an appended-page load for a stable footer.
                      isLoadingMore: state.isPageLoading,
                      onLoadMore: notifier.loadMore,
                      emptyWidget: Padding(
                        padding: const EdgeInsets.all(
                          StorySpacing.screenHorizontal,
                        ),
                        child: StoryEmptyCard(
                          label: context.l10n.creatorV2NoVideos,
                          actionLabel:
                              state.currentStatus.showsEmptyPublishAction
                              ? context.l10n.followFollowersEmptyCta
                              : null,
                          onAction: state.currentStatus.showsEmptyPublishAction
                              ? widget.onCreateContent
                              : null,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                          sliver: SliverLayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = 8.0;
                              final cardWidth =
                                  (constraints.crossAxisExtent - spacing) / 2;
                              final cardHeight =
                                  cardWidth * 310 / 232 +
                                  creatorVideoManagementCardInfoHeight;
                              return SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: spacing,
                                      mainAxisSpacing: spacing,
                                      childAspectRatio: cardWidth / cardHeight,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final video = state.items[index];
                                  return CreatorVideoManagementCard(
                                    video: video,
                                    onTap: () => unawaited(
                                      _openVideo(video, state.items),
                                    ),
                                    onEdit: () => unawaited(_openEditor(video)),
                                    onDelete: () => _deleteVideo(video),
                                  );
                                }, childCount: state.items.length),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
