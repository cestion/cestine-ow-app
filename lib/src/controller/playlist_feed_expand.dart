import '../core/result.dart';
import '../model/models.dart';
import '../routes/route_args.dart';

/// Merge feed-card actor briefs with drama-detail roles for the player rail.
List<RecommendFeedActor>? railActorsFromSeed({
  List<RecommendFeedActor>? actors,
  List<RoleCharacter>? roles,
}) {
  final merged = RecommendFeedActor.forRail(feedActors: actors, roles: roles);
  return merged.isEmpty ? null : merged;
}

/// Shared expand / flatten helpers for mixed playlists (search, profile, …).
class PlaylistFeedExpand {
  PlaylistFeedExpand._();

  static const int maxExpandedEpisodes = 10000;

  /// Flatten a resolved source playlist into swipe pages.
  static ({List<RecommendFeedItem> items, int initialIndex}) seedFromArgs(
    VideoFeedArgs args, {
    List<VideoFeedPlaylistEntry>? resolvedPlaylist,
  }) {
    final playlist = resolvedPlaylist ?? args.searchPlaylist;
    if (playlist.isEmpty) return (items: const [], initialIndex: 0);
    final selectedWorkIndex = args.searchPlaylistIndex.clamp(
      0,
      playlist.length - 1,
    );
    final items = <RecommendFeedItem>[];
    var initialIndex = 0;

    for (var workIndex = 0; workIndex < playlist.length; workIndex++) {
      final entry = playlist[workIndex];
      final activeArgs = workIndex == selectedWorkIndex ? args : null;
      final contentType = activeArgs?.contentType ?? entry.contentType;
      final expand = entry.expandEpisodes && !contentType.isShortVideo;
      if (!expand) {
        if (workIndex == selectedWorkIndex) initialIndex = items.length;
        items.add(itemFromEntry(entry, activeArgs: activeArgs));
        continue;
      }

      final totalEpisodes = entry.totalEpisodes;
      if (totalEpisodes == null || totalEpisodes < 1) {
        throw StateError('Whole-drama playlist entry was not resolved');
      }
      final selectedEpisode = (activeArgs?.episodeNo ?? 1).clamp(
        1,
        totalEpisodes,
      );
      if (workIndex == selectedWorkIndex) {
        initialIndex = items.length + selectedEpisode - 1;
      }
      for (var episodeNo = 1; episodeNo <= totalEpisodes; episodeNo++) {
        items.add(
          itemFromEntry(
            entry,
            activeArgs: activeArgs,
            expandedEpisodeNo: episodeNo,
          ),
        );
      }
    }

    return (items: items, initialIndex: initialIndex);
  }

  /// Flatten already-resolved entries without an active [VideoFeedArgs] seed.
  static List<RecommendFeedItem> flattenEntries(
    List<VideoFeedPlaylistEntry> entries,
  ) {
    if (entries.isEmpty) return const [];
    return seedFromArgs(
      VideoFeedArgs(
        dramaId: entries.first.dramaId,
        episodeId: entries.first.episodeId,
        contentType: entries.first.contentType,
        episodeNo: entries.first.episodeNo,
        title: entries.first.title,
        totalEpisodes: entries.first.totalEpisodes ?? 1,
        searchPlaylist: entries,
      ),
      resolvedPlaylist: entries,
    ).items;
  }

  /// Resolve unknown whole-drama episode counts via [loadEpisodeCount].
  static Future<Result<List<VideoFeedPlaylistEntry>>> resolveEpisodeCounts(
    List<VideoFeedPlaylistEntry> entries, {
    required Future<Result<int>> Function(String dramaId) loadEpisodeCount,
  }) async {
    final missingDramaIds = <String>{};
    for (final entry in entries) {
      if (!entry.expandEpisodes || entry.isShortVideo) continue;
      final known = entry.totalEpisodes;
      if (known != null && known > maxExpandedEpisodes) {
        return Result.failure(
          ApiError.validation('Invalid total episode count'),
        );
      }
      if (known == null || known < 1) {
        missingDramaIds.add(entry.dramaId.trim());
      }
    }

    final resolvedCounts = <String, int>{};
    final results = await Future.wait(
      missingDramaIds.map((dramaId) async {
        return (dramaId: dramaId, result: await loadEpisodeCount(dramaId));
      }),
    );
    for (final entry in results) {
      final error = entry.result.errorOrNull;
      if (error != null) return Result.failure(error);
      final count = entry.result.dataOrNull ?? 0;
      if (count < 1 || count > maxExpandedEpisodes) {
        return Result.failure(
          ApiError.validation('Invalid total episode count'),
        );
      }
      resolvedCounts[entry.dramaId] = count;
    }

    return Result.success([
      for (final entry in entries)
        if (resolvedCounts.containsKey(entry.dramaId.trim()))
          entry.copyWith(totalEpisodes: resolvedCounts[entry.dramaId.trim()])
        else
          entry,
    ]);
  }

  static RecommendFeedItem itemFromEntry(
    VideoFeedPlaylistEntry entry, {
    VideoFeedArgs? activeArgs,
    int? expandedEpisodeNo,
  }) {
    final isActive = activeArgs != null;
    final contentType = isActive ? activeArgs.contentType : entry.contentType;
    final isShortVideo = contentType.isShortVideo;
    final isExpandedEpisode = expandedEpisodeNo != null;
    final episodeNo = isExpandedEpisode
        ? expandedEpisodeNo
        : isShortVideo
        ? 1
        : (isActive ? activeArgs.episodeNo : entry.episodeNo);
    final entryEpisodeId = entry.episodeId?.trim();
    final episodeId = isExpandedEpisode
        ? null
        : isShortVideo
        ? (isActive ? activeArgs.episodeId : entryEpisodeId)
        : (isActive && activeArgs.episodeNo != entry.episodeNo
              ? null
              : entryEpisodeId);
    final seedEngagement = !isExpandedEpisode;
    final seedActors = isActive
        ? railActorsFromSeed(
            actors: activeArgs.actors ?? entry.actors,
            roles: activeArgs.roles ?? entry.roles,
          )
        : railActorsFromSeed(actors: entry.actors, roles: entry.roles);
    final seedRoles = isActive
        ? (activeArgs.roles ?? entry.roles)
        : entry.roles;

    return RecommendFeedItem(
      contentType: contentType.apiValue,
      dramaId: isShortVideo
          ? ''
          : (isActive ? activeArgs.dramaId.trim() : entry.dramaId.trim()),
      episodeId: episodeId,
      episodeNo: episodeNo,
      title: isActive && activeArgs.title.isNotEmpty
          ? activeArgs.title
          : entry.title,
      description: isActive
          ? (activeArgs.description ?? entry.description)
          : entry.description,
      coverUrl: isActive
          ? (activeArgs.coverUrl ?? entry.coverUrl)
          : entry.coverUrl,
      totalEpisodes: isShortVideo
          ? 1
          : (entry.totalEpisodes ?? (isActive ? activeArgs.totalEpisodes : 1)),
      creatorId: isActive
          ? (activeArgs.creatorUserId ?? entry.creatorUserId)
          : entry.creatorUserId,
      creatorName: isActive
          ? (activeArgs.creatorName ?? entry.creatorName)
          : entry.creatorName,
      creatorAvatar: isActive
          ? (activeArgs.creatorAvatarUrl ?? entry.creatorAvatarUrl)
          : entry.creatorAvatarUrl,
      likedByMe: seedEngagement
          ? (isActive
                ? (activeArgs.likedByMe ?? entry.likedByMe)
                : entry.likedByMe)
          : null,
      likeCount: seedEngagement
          ? (isActive
                ? (activeArgs.likeCount ?? entry.likeCount)
                : entry.likeCount)
          : null,
      commentCount: seedEngagement
          ? (isActive
                ? (activeArgs.commentCount ?? entry.commentCount)
                : entry.commentCount)
          : null,
      favoritedByMe: seedEngagement
          ? (isActive
                ? (activeArgs.favoritedByMe ?? entry.favoritedByMe)
                : entry.favoritedByMe)
          : null,
      favoriteCount: seedEngagement
          ? (isActive
                ? (activeArgs.favoriteCount ?? entry.favoriteCount)
                : entry.favoriteCount)
          : null,
      followedByMe: isActive
          ? (activeArgs.followedByMe ?? entry.followedByMe)
          : entry.followedByMe,
      actors: seedActors,
      roles: seedRoles,
    );
  }
}
