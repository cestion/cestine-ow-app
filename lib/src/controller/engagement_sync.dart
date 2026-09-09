import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/models.dart';
import '../provider/app_providers.dart';
import 'engagement_controller.dart';
import 'engagement_state.dart';

/// Snapshot of episode engagement shown on the visible feed card / play payload.
///
/// [play] fields win over list-row [card] fields — play is usually fresher
/// after resolve, while the card supplies first-frame chrome.
class VisibleEpisodeEngagement {
  const VisibleEpisodeEngagement({
    this.likedByMe,
    this.likeCount,
    this.commentCount,
    this.favoritedByMe,
    this.favoriteCount,
  });

  final bool? likedByMe;
  final int? likeCount;
  final int? commentCount;
  final bool? favoritedByMe;
  final int? favoriteCount;

  factory VisibleEpisodeEngagement.fromPlayAndCard({
    DramaPlayResponse? play,
    bool? cardLikedByMe,
    int? cardLikeCount,
    int? cardCommentCount,
    bool? cardFavoritedByMe,
    int? cardFavoriteCount,
    bool inferFavoriteCountWhenFavorited = false,
  }) {
    final favorited = play?.favoritedByMe ?? cardFavoritedByMe;
    final favoriteCount =
        play?.favoriteCount ??
        cardFavoriteCount ??
        (inferFavoriteCountWhenFavorited && favorited == true ? 1 : null);
    return VisibleEpisodeEngagement(
      likedByMe: play?.likedByMe ?? cardLikedByMe,
      likeCount: play?.likeCount ?? cardLikeCount,
      commentCount: play?.commentCount ?? cardCommentCount,
      favoritedByMe: favorited,
      favoriteCount: favoriteCount,
    );
  }

  factory VisibleEpisodeEngagement.fromPlay(DramaPlayResponse play) {
    return VisibleEpisodeEngagement(
      likedByMe: play.likedByMe,
      likeCount: play.likeCount,
      commentCount: play.commentCount,
      favoritedByMe: play.favoritedByMe,
      favoriteCount: play.favoriteCount,
    );
  }

  factory VisibleEpisodeEngagement.commentCountOnly(int? commentCount) {
    return VisibleEpisodeEngagement(commentCount: commentCount);
  }

  /// Merge [visible] with a live [store] without clobbering recent mutations.
  ///
  /// [authoritativePlay] is the API play payload **before** list-row overlays
  /// on play payloads. When the store and visible disagree on a bool, a stale
  /// list row alone cannot downgrade `true` to `false`; only an explicit
  /// `false` on [authoritativePlay] may reconcile retained `true` away after
  /// fast swipes.
  VisibleEpisodeEngagement reconcileWithStore(
    EpisodeEngagementState store, {
    DramaPlayResponse? authoritativePlay,
  }) {
    return VisibleEpisodeEngagement(
      likedByMe: reconcileEngagementBool(
        store: store.likedByMe,
        visible: likedByMe,
        authoritativePlay: authoritativePlay?.likedByMe,
      ),
      likeCount: likeCount ?? store.likeCount,
      commentCount: commentCount ?? store.commentCount,
      favoritedByMe: reconcileEngagementBool(
        store: store.favoritedByMe,
        visible: favoritedByMe,
        authoritativePlay: authoritativePlay?.favoritedByMe,
      ),
      favoriteCount: favoriteCount ?? store.favoriteCount,
    );
  }

  void applyTo(EpisodeEngagementController notifier) {
    notifier.applyVisible(
      likedByMe: likedByMe,
      likeCount: likeCount,
      commentCount: commentCount,
      favoritedByMe: favoritedByMe,
      favoriteCount: favoriteCount,
    );
  }
}

/// Reconcile a bool engagement field between store, visible card/play, and API.
bool? reconcileEngagementBool({
  required bool? store,
  required bool? visible,
  bool? authoritativePlay,
}) {
  if (visible == null) return store;
  if (store == null) return visible;
  if (store == visible) return store;
  if (store) {
    // Store says liked/favorited; visible (often a stale list row) says not.
    // Downgrade only when the API play payload also says not.
    if (authoritativePlay == false) return false;
    return true;
  }
  // Store false, visible true — accept the fresher visible/play truth.
  return true;
}

void syncVisibleEpisodeEngagement(
  Ref ref, {
  required EpisodeEngagementKey key,
  required VisibleEpisodeEngagement engagement,
  DramaPlayResponse? authoritativePlay,
}) {
  final store = ref.read(episodeEngagementProvider(key));
  engagement
      .reconcileWithStore(store, authoritativePlay: authoritativePlay)
      .applyTo(ref.read(episodeEngagementProvider(key).notifier));
}

EpisodeEngagementController episodeEngagementNotifier(
  Ref ref,
  EpisodeEngagementKey key,
) => ref.read(episodeEngagementProvider(key).notifier);
