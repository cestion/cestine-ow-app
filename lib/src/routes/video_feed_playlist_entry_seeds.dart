import '../model/models.dart';
import 'route_args.dart';

/// Chrome merge helpers and list-row → [VideoFeedPlaylistEntry] factories.
extension VideoFeedPlaylistEntryChrome on VideoFeedPlaylistEntry {
  /// First non-null chrome field wins (left-hand side preferred).
  VideoFeedPlaylistEntry mergeChrome(VideoFeedPlaylistEntry? other) {
    if (other == null) return this;
    return _copyChrome(
      creatorName: creatorName ?? other.creatorName,
      creatorUserId: creatorUserId ?? other.creatorUserId,
      creatorAvatarUrl: creatorAvatarUrl ?? other.creatorAvatarUrl,
      likedByMe: likedByMe ?? other.likedByMe,
      likeCount: likeCount ?? other.likeCount,
      commentCount: commentCount ?? other.commentCount,
      favoritedByMe: favoritedByMe ?? other.favoritedByMe,
      favoriteCount: favoriteCount ?? other.favoriteCount,
      followedByMe: followedByMe ?? other.followedByMe,
      actors: actors ?? other.actors,
      roles: roles ?? other.roles,
    );
  }

  /// Prefer authoritative [play] engagement over list-row chrome.
  VideoFeedPlaylistEntry mergePlay(DramaPlayResponse? play) {
    if (play == null) return this;
    return _copyChrome(
      creatorUserId: creatorUserId ?? play.userId,
      likedByMe: play.likedByMe ?? likedByMe,
      likeCount: play.likeCount ?? likeCount,
      commentCount: play.commentCount ?? commentCount,
      favoritedByMe: play.favoritedByMe ?? favoritedByMe,
      favoriteCount: play.favoriteCount ?? favoriteCount,
    );
  }

  VideoFeedPlaylistEntry _copyChrome({
    String? creatorName,
    String? creatorUserId,
    String? creatorAvatarUrl,
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
    bool? followedByMe,
    List<RecommendFeedActor>? actors,
    List<RoleCharacter>? roles,
  }) {
    return VideoFeedPlaylistEntry(
      dramaId: dramaId,
      episodeId: episodeId,
      contentType: contentType,
      episodeNo: episodeNo,
      title: title,
      totalEpisodes: totalEpisodes,
      coverUrl: coverUrl,
      description: description,
      expandEpisodes: expandEpisodes,
      creatorName: creatorName ?? this.creatorName,
      creatorUserId: creatorUserId ?? this.creatorUserId,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      likedByMe: likedByMe ?? this.likedByMe,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      favoritedByMe: favoritedByMe ?? this.favoritedByMe,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      followedByMe: followedByMe ?? this.followedByMe,
      actors: actors ?? this.actors,
      roles: roles ?? this.roles,
    );
  }
}

/// Builds [VideoFeedPlaylistEntry] rows with list/detail chrome pre-filled.
abstract final class VideoFeedPlaylistEntrySeeds {
  VideoFeedPlaylistEntrySeeds._();

  static List<RecommendFeedActor>? actorsFromCollections(
    List<DramaActorCollection>? collections,
  ) {
    if (collections == null || collections.isEmpty) return null;
    return [
      for (final collection in collections)
        RecommendFeedActor(
          actorId: collection.id,
          actorName: collection.name,
          avatarUrl: collection.avatarUrl,
          badge: collection.badge,
          trust: collection.trust,
          storyPerHour: collection.storyPerHour,
          unitPrice: collection.unitPrice,
          computingPower: collection.computingPower,
        ),
    ];
  }

  static VideoFeedPlaylistEntry fromDramaDetail(
    DramaDetail detail, {
    String? dramaId,
    int episodeNo = 1,
  }) {
    final id = dramaId ?? detail.id?.trim() ?? '';
    return VideoFeedPlaylistEntry.drama(
      dramaId: id,
      episodeNo: episodeNo,
      creatorName: detail.creatorName,
      creatorUserId: detail.userId,
      creatorAvatarUrl: detail.creatorAvatarUrl,
      favoritedByMe: detail.favoritedByMe,
      favoriteCount: detail.favoriteCount,
      roles: detail.roles,
    );
  }

  static VideoFeedPlaylistEntry fromDramaListItem(
    DramaListItem item, {
    required String dramaId,
    int episodeNo = 1,
  }) {
    return VideoFeedPlaylistEntry.drama(
      dramaId: dramaId,
      episodeNo: episodeNo,
      creatorName: item.creatorName,
      likeCount: item.likeCount,
      favoriteCount: item.favoriteCount,
      actors: actorsFromCollections(item.actorCollections),
    );
  }

  static VideoFeedPlaylistEntry shortVideoFromFeedItem(
    FeedItem item, {
    required String episodeId,
    String title = '',
    String? coverUrl,
    String? description,
  }) {
    return VideoFeedPlaylistEntry.shortVideo(
      episodeId: episodeId,
      title: title,
      coverUrl: coverUrl,
      description: description,
      creatorName: item.creatorName,
      creatorUserId: item.creatorId,
      creatorAvatarUrl: item.creatorAvatar,
      likedByMe: item.likedByMe,
      likeCount: item.likeCount,
      commentCount: item.commentCount,
      favoritedByMe: item.favoritedByMe,
      favoriteCount: item.favoriteCount,
    );
  }

  static VideoFeedPlaylistEntry dramaFromFeedItem(
    FeedItem item, {
    required String dramaId,
    String? episodeId,
    int episodeNo = 1,
    int? totalEpisodes,
    String title = '',
    String? coverUrl,
    String? description,
    bool expandEpisodes = false,
  }) {
    return VideoFeedPlaylistEntry.drama(
      dramaId: dramaId,
      episodeId: episodeId,
      episodeNo: episodeNo,
      totalEpisodes: totalEpisodes,
      title: title,
      coverUrl: coverUrl,
      description: description,
      expandEpisodes: expandEpisodes,
      creatorName: item.creatorName,
      creatorUserId: item.creatorId,
      creatorAvatarUrl: item.creatorAvatar,
      likedByMe: item.likedByMe,
      likeCount: item.likeCount,
      commentCount: item.commentCount,
      favoritedByMe: item.favoritedByMe,
      favoriteCount: item.favoriteCount,
    );
  }

  static VideoFeedPlaylistEntry fromRecommendFeedItem(
    RecommendFeedItem item, {
    DramaDetail? detail,
    String? dramaId,
    int episodeNo = 1,
  }) {
    final id = dramaId ?? item.dramaId.trim();
    if (item.workType.isShortVideo) {
      final episodeId = item.episodeId?.trim() ?? '';
      return VideoFeedPlaylistEntry.shortVideo(
        episodeId: episodeId,
        title: detail?.title ?? item.title ?? '',
        coverUrl: item.posterUrl ?? detail?.coverUrl,
        description: detail?.description ?? item.description,
        creatorName: detail?.creatorName ?? item.creatorName,
        creatorUserId: detail?.userId ?? item.creatorId,
        creatorAvatarUrl: detail?.creatorAvatarUrl ?? item.creatorAvatar,
        likedByMe: item.likedByMe,
        likeCount: item.likeCount,
        commentCount: item.commentCount,
        favoritedByMe: item.favoritedByMe ?? detail?.favoritedByMe,
        favoriteCount: item.favoriteCount ?? detail?.favoriteCount,
        followedByMe: item.followedByMe,
        actors: item.actors,
        roles: detail?.roles ?? item.roles,
      );
    }
    return VideoFeedPlaylistEntry.drama(
      dramaId: id,
      episodeNo: episodeNo,
      episodeId: item.episodeId,
      title: detail?.title ?? item.title ?? '',
      coverUrl: detail?.coverUrl ?? item.coverUrl,
      description: detail?.description ?? item.description,
      creatorName: detail?.creatorName ?? item.creatorName,
      creatorUserId: detail?.userId ?? item.creatorId,
      creatorAvatarUrl: detail?.creatorAvatarUrl ?? item.creatorAvatar,
      likedByMe: item.likedByMe,
      likeCount: item.likeCount,
      commentCount: item.commentCount,
      favoritedByMe: item.favoritedByMe ?? detail?.favoritedByMe,
      favoriteCount: item.favoriteCount ?? detail?.favoriteCount,
      followedByMe: item.followedByMe,
      actors: item.actors,
      roles: detail?.roles ?? item.roles,
    );
  }

  static VideoFeedPlaylistEntry shortVideoFromCreatorVideo(
    CreatorShortVideo video, {
    required String episodeId,
    String? creatorName,
    String? creatorUserId,
    String? creatorAvatarUrl,
    String title = '',
    String? coverUrl,
    String? description,
  }) {
    return VideoFeedPlaylistEntry.shortVideo(
      episodeId: episodeId,
      title: title,
      coverUrl: coverUrl,
      description: description,
      creatorName: creatorName,
      creatorUserId: creatorUserId,
      creatorAvatarUrl: creatorAvatarUrl,
      likeCount: video.likeCount,
      commentCount: video.commentCount,
      favoriteCount: video.favoriteCount,
    );
  }

  static VideoFeedPlaylistEntry shortVideoFromWatchHistory(
    WatchHistoryVideo item, {
    required String episodeId,
    String title = '',
    String? coverUrl,
    String? description,
  }) {
    return VideoFeedPlaylistEntry.shortVideo(
      episodeId: episodeId,
      title: title,
      coverUrl: coverUrl,
      description: description,
      likeCount: item.likeCount,
    );
  }

  static VideoFeedPlaylistEntry chromeFromFeedItem(FeedItem item) {
    return chrome(
      creatorName: item.creatorName,
      creatorUserId: item.creatorId,
      creatorAvatarUrl: item.creatorAvatar,
      likedByMe: item.likedByMe,
      likeCount: item.likeCount,
      commentCount: item.commentCount,
      favoritedByMe: item.favoritedByMe,
      favoriteCount: item.favoriteCount,
    );
  }

  static VideoFeedPlaylistEntry chromeFromDramaListItem(DramaListItem item) {
    return chrome(
      creatorName: item.creatorName,
      likeCount: item.likeCount,
      favoriteCount: item.favoriteCount,
      actors: actorsFromCollections(item.actorCollections),
    );
  }

  /// Caller-provided creator / engagement overlay for [VideoFeedNavigation].
  static VideoFeedPlaylistEntry chrome({
    String? creatorName,
    String? creatorUserId,
    String? creatorAvatarUrl,
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
    bool? followedByMe,
    List<RecommendFeedActor>? actors,
    List<RoleCharacter>? roles,
  }) {
    return VideoFeedPlaylistEntry.drama(
      dramaId: '',
      creatorName: creatorName,
      creatorUserId: creatorUserId,
      creatorAvatarUrl: creatorAvatarUrl,
      likedByMe: likedByMe,
      likeCount: likeCount,
      commentCount: commentCount,
      favoritedByMe: favoritedByMe,
      favoriteCount: favoriteCount,
      followedByMe: followedByMe,
      actors: actors,
      roles: roles,
    );
  }
}

/// Merges explicit navigation params with optional playlist chrome.
VideoFeedPlaylistEntry mergePlaybackChrome({
  String? creatorName,
  String? creatorUserId,
  String? creatorAvatarUrl,
  VideoFeedPlaylistEntry? chrome,
}) {
  return VideoFeedPlaylistEntrySeeds.chrome(
    creatorName: creatorName,
    creatorUserId: creatorUserId,
    creatorAvatarUrl: creatorAvatarUrl,
  ).mergeChrome(chrome);
}
