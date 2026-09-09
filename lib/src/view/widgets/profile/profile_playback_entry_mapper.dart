import '../../../core/video_url_helpers.dart';
import '../../../model/user_profile_content_model.dart';
import '../../../model/work_content_type.dart';
import '../../../routes/route_args.dart';

typedef ProfileResumeEpisodeResolver =
    int Function(String dramaId, int totalEpisodes);

/// Maps one profile-list row to its playback target.
///
/// 整剧条目从第 1 集展开全部剧集；具体剧集保留 episodeId 且只占一页，
/// 不使用本地续播集数替换服务端明确指定的目标。
class ProfilePlaybackEntryMapper {
  ProfilePlaybackEntryMapper._();

  /// List → player poster seed: [firstFrameUrl] then episode/drama cover.
  static String? posterCoverFor(UserProfileContentItem item) {
    final drama = item.drama;
    return VideoUrlHelpers.preferPosterUrl(
      firstFrameUrl: item.episode?.firstFrameUrl,
      coverUrl: item.episode?.coverUrl ?? drama?.coverUrl,
    );
  }

  static VideoFeedPlaylistEntry? fromItem(
    UserProfileContentItem item, {
    required ProfileResumeEpisodeResolver resolveResumeEpisode,
  }) {
    final drama = item.toDramaListItem();
    final contentType = WorkContentType.fromApi(drama.type);
    final workId = contentType.isShortVideo
        ? (drama.episodeId ?? drama.id)
        : drama.id;
    if (workId.trim().isEmpty) return null;
    final posterCover = posterCoverFor(item);

    if (contentType.isShortVideo) {
      return VideoFeedPlaylistEntry.shortVideo(
        episodeId: workId,
        title: drama.dramaTitle ?? '',
        coverUrl: posterCover,
        description: drama.dramaDescription,
        creatorName: item.creatorName,
        creatorUserId: item.userId,
        creatorAvatarUrl: item.creatorAvatarUrl,
        likedByMe: item.likedByMe,
        likeCount: item.episode?.likeCount,
        commentCount: item.episode?.commentCount,
        favoritedByMe: item.favoritedByMe,
        favoriteCount: item.episode?.favoriteCount ?? drama.favoriteCount,
        followedByMe: item.followedByMe,
      );
    }

    final explicitEpisodeNo = switch (drama.episodeNo) {
      final value? when value > 0 => value,
      _ => null,
    };
    final expandEpisodes = item.episode == null;
    final listedTotalEpisodes = switch (drama.totalEpisodes) {
      final value? when value > 0 => value,
      _ => null,
    };
    final episodeNo = expandEpisodes ? 1 : (explicitEpisodeNo ?? 1);
    final totalEpisodes = listedTotalEpisodes == null
        ? (expandEpisodes ? null : episodeNo)
        : (episodeNo > listedTotalEpisodes ? episodeNo : listedTotalEpisodes);

    return VideoFeedPlaylistEntry.drama(
      dramaId: workId,
      episodeId: expandEpisodes ? null : drama.episodeId,
      episodeNo: episodeNo,
      totalEpisodes: totalEpisodes,
      title: drama.dramaTitle ?? '',
      coverUrl: posterCover,
      description: drama.dramaDescription,
      expandEpisodes: expandEpisodes,
      creatorName: item.creatorName,
      creatorUserId: item.userId,
      creatorAvatarUrl: item.creatorAvatarUrl,
      likedByMe: expandEpisodes ? null : item.likedByMe,
      likeCount: expandEpisodes ? null : item.episode?.likeCount,
      commentCount: expandEpisodes ? null : item.episode?.commentCount,
      favoritedByMe: expandEpisodes ? null : item.favoritedByMe,
      favoriteCount: expandEpisodes ? null : item.episode?.favoriteCount,
      followedByMe: item.followedByMe,
    );
  }
}
