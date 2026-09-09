part of 'video_feed_controller.dart';

/// Engagement mutations for [VideoFeedController].
///
/// Owns like/favorite/comment interactions. All mutations go through the
/// shared engagement store (single write path for every page); the feed
/// then mirrors the settled store state into its own play payloads for
/// playback bookkeeping. Kept as a same-library extension to access
/// private controller fields while isolating engagement logic in one file.
extension FeedEngagementManager on VideoFeedController {
  DramaPlayResponse? _playForEngagement(int episodeNo) =>
      playForEpisode(episodeNo);

  void _patchEpisodePlayEngagement(
    int episodeNo,
    DramaPlayResponse play, {
    bool? likedByMe,
    int? likeCount,
    bool? favoritedByMe,
    int? favoriteCount,
    int? commentCount,
  }) {
    final updated = play.copyWith(
      likedByMe: likedByMe,
      likeCount: likeCount,
      favoritedByMe: favoritedByMe,
      favoriteCount: favoriteCount,
      commentCount: commentCount,
    );
    if (episodeNo == _currentEpisodeNo) {
      setCurrentPlay(updated);
    }
    final epState = _episodeStates[episodeNo];
    if (epState != null) {
      _episodeStates[episodeNo] = FeedEpisodeState(
        play: updated,
        isPrefetching: epState.isPrefetching,
        error: epState.error,
      );
      _episodeStatesDirty = true;
    }
    _notify();
  }

  /// Toggle like for [episodeNo] (defaults to the active episode).
  Future<bool> toggleLike({int? episodeNo}) async {
    final epNo = episodeNo ?? _currentEpisodeNo;
    final play = _playForEngagement(epNo);
    final episodeId = play?.episodeId;
    if (play == null || episodeId == null || episodeId.isEmpty) return false;

    final key = EpisodeEngagementKey.forEpisode(
      dramaId: dramaId,
      episodeId: episodeId,
      episodeNo: play.episodeNo ?? epNo,
    );
    final notifier = _episodeEngagementNotifier(key);
    final store = _episodeEngagement(key);
    final result = await notifier.toggleLike(
      episodeNo: play.episodeNo ?? epNo,
      type: contentType,
      authorUserId: play.userId,
      likedByMeBaseline: store.likedByMe ?? play.likedByMe,
    );
    if (result == null || result.isFailure || !_alive) return false;

    final settled = _episodeEngagement(key);
    _patchEpisodePlayEngagement(
      epNo,
      play,
      likedByMe: settled.likedByMe,
      likeCount: settled.likeCount,
    );
    return true;
  }

  /// Player right-rail favorite — **episode/work** scoped.
  ///
  /// Short drama → `/dramas/episodes/{episodeId}/favorite`;
  /// short video → `/short-videos/{episodeId}/favorite`.
  /// Whole-series favorite lives on the drama detail sheet.
  Future<bool> toggleFavorite({int? episodeNo}) async {
    final epNo = episodeNo ?? _currentEpisodeNo;
    final play = _playForEngagement(epNo);
    final episodeId = play?.episodeId;
    if (play == null || episodeId == null || episodeId.isEmpty) return false;

    final key = EpisodeEngagementKey.forEpisode(
      dramaId: dramaId,
      episodeId: episodeId,
      episodeNo: play.episodeNo ?? epNo,
    );
    final notifier = _episodeEngagementNotifier(key);
    final store = _episodeEngagement(key);
    final result = await notifier.toggleWorkFavorite(
      episodeNo: play.episodeNo ?? epNo,
      type: contentType,
      authorUserId: play.userId,
      favoritedByMeBaseline: store.favoritedByMe ?? play.favoritedByMe,
    );
    if (result == null || result.isFailure || !_alive) return false;

    final settled = _episodeEngagement(key);
    _patchEpisodePlayEngagement(
      epNo,
      play,
      favoritedByMe: settled.favoritedByMe ?? false,
      favoriteCount: settled.favoriteCount,
    );
    return true;
  }

  /// After a successful episode comment, bump counts shown on the feed rail.
  void onCommentPosted() {
    final play = _currentPlay;
    if (play == null) return;
    final nextCount = (play.commentCount ?? 0) + 1;
    final updated = play.copyWith(commentCount: nextCount);
    setCurrentPlay(updated);
    final epNo = _currentEpisodeNo;
    final epState = _episodeStates[epNo];
    if (epState?.play != null) {
      _episodeStates[epNo] = FeedEpisodeState(
        play: epState!.play!.copyWith(commentCount: nextCount),
        isPrefetching: epState.isPrefetching,
        error: epState.error,
      );
      _episodeStatesDirty = true;
    }
    _notify();
  }

  /// Bind [play] as current. Episode/work favorite stays on the payload.
  void setCurrentPlay(DramaPlayResponse? play) {
    _currentPlay = play;
  }

  /// Chrome seeds for the right rail before play payloads finish loading.
  ({
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
  })
  engagementChromeSeedFor(int episodeNo) {
    final play = playForEpisode(episodeNo);
    final fromRoute = episodeNo == initialEpisodeNo;
    return (
      likedByMe: play?.likedByMe ?? (fromRoute ? _args.likedByMe : null),
      likeCount: play?.likeCount ?? (fromRoute ? _args.likeCount : null),
      commentCount:
          play?.commentCount ?? (fromRoute ? _args.commentCount : null),
      favoritedByMe:
          play?.favoritedByMe ?? (fromRoute ? _args.favoritedByMe : null),
      favoriteCount:
          play?.favoriteCount ?? (fromRoute ? _args.favoriteCount : null),
    );
  }

  /// Apply route / list-row engagement onto the shared store for [episodeNo].
  void seedRouteEngagement(int episodeNo) {
    final play = playForEpisode(episodeNo);
    final episodeId = switch (play?.episodeId?.trim()) {
      final value? when value.isNotEmpty => value,
      _ => _args.isShortVideo ? _args.episodeId?.trim() : null,
    };
    if (episodeId == null || episodeId.isEmpty) return;

    final fromRoute = episodeNo == initialEpisodeNo;
    final key = EpisodeEngagementKey.forEpisode(
      dramaId: dramaId,
      episodeId: episodeId,
      episodeNo: play?.episodeNo ?? episodeNo,
    );
    _syncVisibleEpisodeEngagement(
      key,
      VisibleEpisodeEngagement.fromPlayAndCard(
        play: play,
        cardLikedByMe: fromRoute ? _args.likedByMe : null,
        cardLikeCount: fromRoute ? _args.likeCount : null,
        cardCommentCount: fromRoute ? _args.commentCount : null,
        cardFavoritedByMe: fromRoute ? _args.favoritedByMe : null,
        cardFavoriteCount: fromRoute ? _args.favoriteCount : null,
      ),
      authoritativePlay: play,
    );

    if (!fromRoute) return;
    _seedRouteFollowStatus();
  }
}
