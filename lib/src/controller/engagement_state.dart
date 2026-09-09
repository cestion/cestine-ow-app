import 'package:equatable/equatable.dart';

import '../core/result.dart';

/// Drama-scoped engagement state (favorite is per drama, not per episode).
///
/// Nullable fields mean "not yet known" — UI falls back to whatever value it
/// already has (list item, cached detail, play payload). Once a field is set
/// by [seed]/[applyServer]/a mutation, it is the single source of truth for
/// every live page watching the provider.
class DramaEngagementState extends Equatable {
  final bool? favoritedByMe;
  final int? favoriteCount;

  /// The current user's rating (1..5), null when not rated / unknown.
  final int? myRating;

  /// Server-computed average rating; cannot be derived locally, so it is
  /// only refreshed from authoritative fetches after a rating submit.
  final double? avgRating;
  final bool isMutating;

  const DramaEngagementState({
    this.favoritedByMe,
    this.favoriteCount,
    this.myRating,
    this.avgRating,
    this.isMutating = false,
  });

  bool get ratedByMe => myRating != null;

  DramaEngagementState copyWith({
    bool? favoritedByMe,
    int? favoriteCount,
    int? myRating,
    double? avgRating,
    bool? isMutating,
  }) {
    return DramaEngagementState(
      favoritedByMe: favoritedByMe ?? this.favoritedByMe,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      myRating: myRating ?? this.myRating,
      avgRating: avgRating ?? this.avgRating,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [
    favoritedByMe,
    favoriteCount,
    myRating,
    avgRating,
    isMutating,
  ];
}

/// Episode-scoped engagement state (like, comment, and work favorite).
class EpisodeEngagementState extends Equatable {
  final bool? likedByMe;
  final int? likeCount;
  final int? commentCount;
  final bool? favoritedByMe;
  final int? favoriteCount;
  final bool isMutating;

  /// 最近一次操作失败（如拉黑拦截），供 UI 层 toast 本地化提示。
  final ApiError? lastError;

  const EpisodeEngagementState({
    this.likedByMe,
    this.likeCount,
    this.commentCount,
    this.favoritedByMe,
    this.favoriteCount,
    this.isMutating = false,
    this.lastError,
  });

  EpisodeEngagementState copyWith({
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
    bool? isMutating,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return EpisodeEngagementState(
      likedByMe: likedByMe ?? this.likedByMe,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      favoritedByMe: favoritedByMe ?? this.favoritedByMe,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      isMutating: isMutating ?? this.isMutating,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  List<Object?> get props => [
    likedByMe,
    likeCount,
    commentCount,
    favoritedByMe,
    favoriteCount,
    isMutating,
    lastError,
  ];
}

/// Family key for episode engagement providers.
///
/// The server identifies like/comment targets by [episodeId]; [episodeNo] is
/// carried along for cache patching only and is deliberately excluded from
/// equality so callers with/without it share the same provider instance.
class EpisodeEngagementKey {
  final String dramaId;
  final String episodeId;
  final int? episodeNo;

  const EpisodeEngagementKey({
    required this.dramaId,
    required this.episodeId,
    this.episodeNo,
  });

  /// Canonical key for episode-scoped stores. When [dramaId] is empty (short
  /// video cards) the work id falls back to [episodeId] so toggle paths and
  /// the player rail watch the same provider instance.
  factory EpisodeEngagementKey.forEpisode({
    required String dramaId,
    required String episodeId,
    int? episodeNo,
  }) {
    final drama = dramaId.trim();
    final episode = episodeId.trim();
    assert(episode.isNotEmpty, 'episodeId is required');
    return EpisodeEngagementKey(
      dramaId: drama.isEmpty ? episode : drama,
      episodeId: episode,
      episodeNo: episodeNo,
    );
  }

  static EpisodeEngagementKey? tryForEpisode({
    required String dramaId,
    String? episodeId,
    int? episodeNo,
  }) {
    final episode = episodeId?.trim() ?? '';
    if (episode.isEmpty) return null;
    return EpisodeEngagementKey.forEpisode(
      dramaId: dramaId,
      episodeId: episode,
      episodeNo: episodeNo,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EpisodeEngagementKey &&
        other.dramaId == dramaId &&
        other.episodeId == episodeId;
  }

  @override
  int get hashCode => Object.hash(dramaId, episodeId);
}
