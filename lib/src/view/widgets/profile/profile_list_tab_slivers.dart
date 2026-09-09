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
import '../../../widgets/story_skeleton.dart';
import '../../../foundation/navigator.dart';
import 'profile_playback_entry_mapper.dart';

/// Profile list tab content as slivers for the unified profile [CustomScrollView].
List<Widget> buildProfileListTabSlivers(
  BuildContext context,
  WidgetRef ref, {
  required UserProfileDramaParam param,
  required String emptyLabel,
  required bool isActive,
}) {
  if (!isActive) {
    return [const SliverToBoxAdapter(child: SizedBox.shrink())];
  }

  final provider = userProfileDramasProvider(param);
  final state = ref.watch(provider);

  if (!state.hasFetched || (state.isLoading && state.items.isEmpty)) {
    return [
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
            (_, _) => const ShimmerScope(child: GridDramaCardSkeleton()),
            childCount: 6,
          ),
        ),
      ),
    ];
  }

  if (state.items.isEmpty) {
    final showEmptyAction = param.userId == null;
    return [
      SliverToBoxAdapter(
        child: SizedBox(
          height: 320,
          child: Center(
            child: StoryEmptyCard(
              label: emptyLabel,
              actionLabel: showEmptyAction
                  ? _emptyActionLabel(context, param.type)
                  : null,
              onAction: showEmptyAction
                  ? () => _onEmptyAction(context, ref, param.type)
                  : null,
            ),
          ),
        ),
      ),
    ];
  }

  return [
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
          (context, index) => _buildProfileListCard(
            context,
            ref,
            param: param,
            items: state.items,
            index: index,
          ),
          childCount: state.items.length,
        ),
      ),
    ),
    if (state.isPageLoading)
      const SliverPadding(
        padding: EdgeInsets.symmetric(vertical: StorySpacing.base),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
  ];
}

String _emptyActionLabel(BuildContext context, ProfileDramaType type) {
  final l10n = context.l10n;
  return switch (type) {
    ProfileDramaType.published || ProfileDramaType.works =>
      l10n.followFollowersEmptyCta,
    ProfileDramaType.likes || ProfileDramaType.favorites =>
      l10n.followFollowingEmptyCta,
  };
}

void _onEmptyAction(
  BuildContext context,
  WidgetRef ref,
  ProfileDramaType type,
) {
  switch (type) {
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

Widget _buildProfileListCard(
  BuildContext context,
  WidgetRef ref, {
  required UserProfileDramaParam param,
  required List<UserProfileContentItem> items,
  required int index,
}) {
  final drama = items[index].toDramaListItem();
  final isOwnWorksTab =
      param.userId == null && param.type == ProfileDramaType.works;
  final vm = isOwnWorksTab
      ? DramaCardVmMapper.fromProfileOwnWorks(drama, l10n: context.l10n)
      : DramaCardVmMapper.fromTheaterList(drama, l10n: context.l10n);
  return RepaintBoundary(
    child: GridDramaCard(
      vm: vm,
      showPlayCount: isOwnWorksTab,
      onTap: () => openProfileListPlaylist(
        context,
        ref,
        param: param,
        items: items,
        tappedIndex: index,
      ),
    ),
  );
}

Future<void> openProfileListPlaylist(
  BuildContext context,
  WidgetRef ref, {
  required UserProfileDramaParam param,
  required List<UserProfileContentItem> items,
  required int tappedIndex,
}) async {
  final playlist = <VideoFeedPlaylistEntry>[];
  var initialIndex = -1;
  for (var index = 0; index < items.length; index++) {
    final entry = _toPlaylistEntry(ref, items[index]);
    if (entry == null) continue;
    if (index == tappedIndex) initialIndex = playlist.length;
    playlist.add(entry);
  }

  if (initialIndex < 0) {
    StoryToast.error(context, context.l10n.playerDramaUnavailable);
    return;
  }

  final provider = userProfileDramasProvider(param);
  final seenKeys = {for (final e in playlist) e.playbackKey};
  final continuation = CallbackPlaylistContinuation(
    hasMoreCallback: () => ref.read(provider).hasMore,
    loadMoreCallback: () => _loadMoreProfilePlaylistEntries(
      ref,
      param: param,
      seenKeys: seenKeys,
    ),
  );

  await VideoFeedNavigation.openPlaylist(
    context,
    playlist: playlist,
    initialIndex: initialIndex,
    continuation: continuation,
  );
  if (!context.mounted) return;
  await _revalidateProfileListItemAfterPlayback(
    ref,
    param: param,
    item: items[tappedIndex],
  );
}

VideoFeedPlaylistEntry? _toPlaylistEntry(
  WidgetRef ref,
  UserProfileContentItem item,
) {
  return ProfilePlaybackEntryMapper.fromItem(
    item,
    resolveResumeEpisode: (dramaId, totalEpisodes) =>
        resumeEpisodeForDrama(ref, dramaId, totalEpisodes: totalEpisodes),
  );
}

Future<Result<PlaylistContinuationPage>> _loadMoreProfilePlaylistEntries(
  WidgetRef ref, {
  required UserProfileDramaParam param,
  required Set<String> seenKeys,
}) async {
  final provider = userProfileDramasProvider(param);
  final state = ref.read(provider);
  final page = await syncPlaylistContinuation<UserProfileContentItem>(
    items: state.items,
    hasMore: state.hasMore,
    isPageLoading: state.isPageLoading,
    seenKeys: seenKeys,
    toEntry: (item) => _toPlaylistEntry(ref, item),
    loadMore: () => ref.read(provider.notifier).loadMore(),
    readItems: () => ref.read(provider).items,
    readHasMore: () => ref.read(provider).hasMore,
    readIsPageLoading: () => ref.read(provider).isPageLoading,
  );
  return Result.success(page);
}

Future<void> _revalidateProfileListItemAfterPlayback(
  WidgetRef ref, {
  required UserProfileDramaParam param,
  required UserProfileContentItem item,
}) async {
  final episode = item.episode;
  if (episode == null || episode.id.isEmpty) return;

  final result = await ref
      .read(dramaRepositoryProvider)
      .getEpisodeDetailByEpisodeId(episode.id);
  if (result.isFailure) return;
  final play = result.dataOrNull;
  if (play == null) return;

  final provider = userProfileDramasProvider(param);
  final notifier = ref.read(provider.notifier);
  if (param.type == ProfileDramaType.likes && play.likedByMe == false) {
    notifier.removeDrama(episode.id);
    return;
  }
  if (param.type == ProfileDramaType.favorites && play.favoritedByMe == false) {
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

Future<void> loadMoreProfileListTab(
  WidgetRef ref,
  UserProfileDramaParam param,
) async {
  await ref.read(userProfileDramasProvider(param).notifier).loadMore();
}

/// Favorites / watch-history sub-filter chips rendered inside profile scroll.
class ProfileWorkTypeFilterBar extends StatelessWidget {
  final WorkContentType selectedType;
  final ValueChanged<WorkContentType>? onSelected;

  const ProfileWorkTypeFilterBar({
    super.key,
    required this.selectedType,
    this.onSelected,
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
            return _ProfileWorkTypeChip(
              key: ValueKey<String>('profile-work-type-filter-${type.name}'),
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

class _ProfileWorkTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileWorkTypeChip({
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
