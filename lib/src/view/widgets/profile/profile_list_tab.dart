import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:story_app/src/routes/route_args.dart';
import 'package:story_app/src/routes/video_feed_navigation.dart';

import '../../../components/common/story_toast.dart';
import '../../../components/theater/drama_card.dart';
import '../../../components/theater/drama_card_vm_mapper.dart';
import '../../../controller/playlist_continuation.dart';
import '../../../controller/playlist_continuation_sync.dart';
import '../../../controller/user_profile_dramas_state.dart';
import '../../../core/result.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/user_profile_content_model.dart';
import '../../../model/work_content_type.dart';
import '../../../provider/app_providers.dart';
import '../../../provider/tab_index_provider.dart';
import '../../../repositories/user_repository.dart';
import '../../../routes/route_names.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../widgets/story_empty_card.dart';
import '../../../widgets/story_paginated_scroll_view.dart';
import '../../../widgets/story_skeleton.dart';
import 'profile_playback_entry_mapper.dart';
import '../../../foundation/navigator.dart';

/// 个人中心作品/点赞/收藏共用的双列内容网格。
///
/// 卡片比例与剧场首页保持一致；TabBar 仍由 `public_profile_page.dart` 管理，
/// 避免列表样式调整影响现有页签行为。
class ProfileListTab extends ConsumerStatefulWidget {
  final UserProfileDramaParam param;
  final String emptyLabel;
  final bool isActive;
  final bool coordinatedWithParentRefresh;
  final ValueChanged<WorkContentType>? onFavoriteTypeChanged;

  const ProfileListTab({
    super.key,
    required this.param,
    required this.emptyLabel,
    required this.isActive,
    this.coordinatedWithParentRefresh = false,
    this.onFavoriteTypeChanged,
  });

  @override
  ConsumerState<ProfileListTab> createState() => _ProfileListTabState();
}

class _ProfileListTabState extends ConsumerState<ProfileListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String get _emptyActionLabel => switch (widget.param.type) {
    ProfileDramaType.published ||
    ProfileDramaType.works => context.l10n.followFollowersEmptyCta,
    ProfileDramaType.likes ||
    ProfileDramaType.favorites => context.l10n.followFollowingEmptyCta,
  };

  void _onEmptyAction() {
    switch (widget.param.type) {
      case ProfileDramaType.published:
        context.storyPush(RouteNames.createDrama);
      case ProfileDramaType.works:
        context.storyPush(RouteNames.publishVideo);
      case ProfileDramaType.likes:
      case ProfileDramaType.favorites:
        ref.read(tabIndexProvider.notifier).setIndex(StoryTab.theater.index);
        Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  VideoFeedPlaylistEntry? _toPlaylistEntry(UserProfileContentItem item) {
    return ProfilePlaybackEntryMapper.fromItem(
      item,
      resolveResumeEpisode: (dramaId, totalEpisodes) =>
          resumeEpisodeForDrama(ref, dramaId, totalEpisodes: totalEpisodes),
    );
  }

  Future<void> _openPlaylist(
    List<UserProfileContentItem> items,
    int tappedIndex,
  ) async {
    final playlist = <VideoFeedPlaylistEntry>[];
    var initialIndex = -1;
    for (var index = 0; index < items.length; index++) {
      final entry = _toPlaylistEntry(items[index]);
      if (entry == null) continue;
      if (index == tappedIndex) initialIndex = playlist.length;
      playlist.add(entry);
    }

    if (initialIndex < 0) {
      StoryToast.error(context, context.l10n.playerDramaUnavailable);
      return;
    }

    final provider = userProfileDramasProvider(widget.param);
    final seenKeys = {for (final e in playlist) e.playbackKey};
    final continuation = CallbackPlaylistContinuation(
      hasMoreCallback: () {
        if (!mounted) return false;
        return ref.read(provider).hasMore;
      },
      loadMoreCallback: () =>
          _loadMoreProfilePlaylistEntries(seenKeys: seenKeys),
    );

    await VideoFeedNavigation.openPlaylist(
      context,
      playlist: playlist,
      initialIndex: initialIndex,
      continuation: continuation,
    );
    if (!mounted) return;
    await _revalidateItemAfterPlayback(items[tappedIndex]);
  }

  Future<Result<PlaylistContinuationPage>> _loadMoreProfilePlaylistEntries({
    required Set<String> seenKeys,
  }) async {
    if (!mounted) {
      return Result.success(
        const PlaylistContinuationPage(entries: [], hasMore: false),
      );
    }
    final provider = userProfileDramasProvider(widget.param);
    final state = ref.read(provider);
    final page = await syncPlaylistContinuation<UserProfileContentItem>(
      items: state.items,
      hasMore: state.hasMore,
      isPageLoading: state.isPageLoading,
      seenKeys: seenKeys,
      toEntry: _toPlaylistEntry,
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

  Future<void> _revalidateItemAfterPlayback(UserProfileContentItem item) async {
    final episode = item.episode;
    if (episode == null || episode.id.isEmpty) return;

    final result = await ref
        .read(dramaRepositoryProvider)
        .getEpisodeDetailByEpisodeId(episode.id);
    if (!mounted || result.isFailure) return;
    final play = result.dataOrNull;
    if (play == null) return;

    final provider = userProfileDramasProvider(widget.param);
    final notifier = ref.read(provider.notifier);
    if (widget.param.type == ProfileDramaType.likes &&
        play.likedByMe == false) {
      notifier.removeDrama(episode.id);
      return;
    }
    if (widget.param.type == ProfileDramaType.favorites &&
        play.favoritedByMe == false) {
      notifier.removeDrama(episode.id);
      return;
    }

    notifier.replaceContentItem(
      UserProfileContentItem(
        userId: item.userId,
        creatorName: item.creatorName,
        creatorAvatarUrl: item.creatorAvatarUrl,
        likedByMe: play.likedByMe ?? item.likedByMe,
        favoritedByMe: play.favoritedByMe ?? item.favoritedByMe,
        followedByMe: item.followedByMe,
        actionTime: item.actionTime,
        type: item.type,
        drama: item.drama,
        episode: UserProfileContentEpisode(
          id: episode.id,
          episodeNo: episode.episodeNo,
          contentType: episode.contentType,
          durationSec: episode.durationSec,
          title: episode.title,
          description: episode.description,
          coverUrl: episode.coverUrl,
          firstFrameUrl: play.firstFrameUrl ?? episode.firstFrameUrl,
          playCount: episode.playCount,
          completeCount: episode.completeCount,
          likeCount: play.likeCount ?? episode.likeCount,
          commentCount: play.commentCount ?? episode.commentCount,
          favoriteCount: play.favoriteCount ?? episode.favoriteCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.isActive) return const SizedBox.shrink();

    final provider = userProfileDramasProvider(widget.param);
    final state = ref.watch(provider);
    final content =
        !state.hasFetched || (state.isLoading && state.items.isEmpty)
        ? const ProfileListSkeleton()
        : _buildList(state);

    if (widget.param.type != ProfileDramaType.favorites) return content;

    return Column(
      children: [
        _ProfileFavoriteTypeFilters(
          selectedType: widget.param.contentType,
          onSelected: widget.onFavoriteTypeChanged,
        ),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildList(UserProfileDramasState state) {
    final provider = userProfileDramasProvider(widget.param);
    final showEmptyAction = widget.param.userId == null;

    return StoryPaginatedScrollView(
      itemCount: state.items.length,
      hasMore: state.hasMore,
      isLoadingMore: state.isPageLoading,
      pullToRefreshEnabled: !widget.coordinatedWithParentRefresh,
      emptyWidget: StoryEmptyCard(
        label: widget.emptyLabel,
        actionLabel: showEmptyAction ? _emptyActionLabel : null,
        onAction: showEmptyAction ? _onEmptyAction : null,
      ),
      onRefresh: widget.coordinatedWithParentRefresh
          ? null
          : () => ref.read(provider.notifier).refresh(),
      onLoadMore: () => ref.read(provider.notifier).loadMore(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: StorySpacing.sm,
            vertical: StorySpacing.md,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: StorySpacing.sm,
              mainAxisSpacing: StorySpacing.base,
              childAspectRatio: 0.60,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildCard(state.items, index),
              childCount: state.items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<UserProfileContentItem> items, int index) {
    final drama = items[index].toDramaListItem();
    final isOwnWorksTab =
        widget.param.userId == null && widget.param.type == ProfileDramaType.works;
    final vm = isOwnWorksTab
        ? DramaCardVmMapper.fromProfileOwnWorks(drama, l10n: context.l10n)
        : DramaCardVmMapper.fromTheaterList(drama, l10n: context.l10n);
    return RepaintBoundary(
      child: GridDramaCard(
        vm: vm,
        showPlayCount: isOwnWorksTab,
        onTap: () => _openPlaylist(items, index),
      ),
    );
  }
}

class _ProfileFavoriteTypeFilters extends StatelessWidget {
  final WorkContentType selectedType;
  final ValueChanged<WorkContentType>? onSelected;

  const _ProfileFavoriteTypeFilters({
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final labels = <WorkContentType, String>{
      WorkContentType.shortDrama: context.l10n.profileTabDramas,
      WorkContentType.shortVideo: context.l10n.profileTabWorks,
    };

    return Padding(
      padding: const EdgeInsets.only(top: StorySpacing.sm),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          itemCount: WorkContentType.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final type = WorkContentType.values[index];
            return _ProfileFavoriteTypeChip(
              key: ValueKey<String>('profile-favorite-filter-${type.name}'),
              label: labels[type]!,
              selected: type == selectedType,
              onTap: () => onSelected?.call(type),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileFavoriteTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileFavoriteTypeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final selectedBackground = brightness == Brightness.light
        ? StoryColors.darkButtonBg
        : StoryColors.foregroundOf(brightness);
    return Material(
      color: selected
          ? selectedBackground
          : StoryColors.actorHeroBadgeBgOf(brightness),
      borderRadius: const BorderRadius.all(Radius.circular(80)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(80)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? StoryColors.backgroundOf(brightness)
                  : StoryColors.foregroundOf(brightness),
              fontSize: 14,
              height: 20 / 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
