import '../core/result.dart';
import '../data/repository/story_local_repository.dart';
import '../model/work_content_type.dart';
import '../repositories/drama_repository.dart';

/// Drama like/favorite actions — keeps repository access out of widgets.
class DramaEngagementService {
  final DramaRepository _drama;
  final StoryLocalRepository _local;

  const DramaEngagementService(this._drama, this._local);

  /// [episodeNo] is only needed to patch the episode-play cache; when unknown
  /// the patch is skipped (never patch episode 0 by accident).
  Future<Result<void>> toggleEpisodeLike({
    required String dramaId,
    required String episodeId,
    int? episodeNo,
    required bool likedByMe,
    required int likeCount,
    WorkContentType type = WorkContentType.shortDrama,
  }) async {
    final result = await _drama.toggleEpisodeLike(
      dramaId,
      episodeId,
      type: type,
    );
    if (result.isSuccess && episodeNo != null && type.isShortDrama) {
      await _drama.patchCachedEpisodePlay(
        dramaId,
        episodeNo,
        likedByMe: likedByMe,
        likeCount: likeCount,
      );
    }
    return result;
  }

  /// Whole-series favorite (`/{dramaId}/favorite`). Syncs local watchlist.
  ///
  /// Does **not** patch [DramaPlayResponse.favoritedByMe] — that field is
  /// episode/work-scoped (player rail).
  Future<Result<void>> toggleDramaFavorite(String dramaId) async {
    await _local.toggleWatchlist(dramaId);
    return _drama.toggleFavorite(dramaId);
  }

  /// Episode/work favorite (player right rail).
  ///
  /// Short drama → `/dramas/episodes/{episodeId}/favorite`;
  /// short video → `/short-videos/{episodeId}/favorite`.
  Future<Result<void>> toggleWorkFavorite({
    required String dramaId,
    required String episodeId,
    int? episodeNo,
    bool? favoritedByMe,
    WorkContentType type = WorkContentType.shortDrama,
  }) async {
    final result = await _drama.toggleFavorite(
      dramaId,
      type: type,
      episodeId: episodeId,
      target: FavoriteTarget.work,
    );
    if (result.isSuccess &&
        episodeNo != null &&
        favoritedByMe != null &&
        type.isShortDrama) {
      await _drama.patchCachedEpisodePlay(
        dramaId,
        episodeNo,
        favoritedByMe: favoritedByMe,
      );
    }
    return result;
  }

  /// Back-compat wrapper.
  Future<Result<void>> toggleFavorite(
    String dramaId, {
    int? episodeNo,
    bool? favoritedByMe,
    WorkContentType type = WorkContentType.shortDrama,
    String? episodeId,
    FavoriteTarget target = FavoriteTarget.drama,
  }) {
    if (target == FavoriteTarget.work) {
      final workId = episodeId;
      if (workId == null || workId.isEmpty) {
        return Future.value(
          Result.failure(
            ApiError.validation('episodeId required for work favorite'),
          ),
        );
      }
      return toggleWorkFavorite(
        dramaId: dramaId,
        episodeId: workId,
        episodeNo: episodeNo,
        favoritedByMe: favoritedByMe,
        type: type,
      );
    }
    return toggleDramaFavorite(dramaId);
  }

  Future<void> revertWatchlistToggle(String dramaId) {
    return _local.toggleWatchlist(dramaId);
  }

  bool isFavorite(String dramaId) => _local.isFavorite(dramaId);
}
