import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../model/work_content_type.dart';
import '../provider/app_providers.dart';
import '../repositories/user_repository.dart';
import 'engagement_state.dart';
import 'user_profile_dramas_state.dart';

/// Keeps an autoDispose engagement store alive for a short retention window
/// after its last listener is gone, so quick page hops (detail → back →
/// detail, feed → detail → feed) reuse the same state instead of rebuilding.
void _retainAfterLastListener(Ref ref) {
  final link = ref.keepAlive();
  Timer? timer;
  ref.onCancel(() {
    timer?.cancel();
    timer = Timer(StoryConstants.engagementStoreRetention, link.close);
  });
  ref.onResume(() => timer?.cancel());
  ref.onDispose(() => timer?.cancel());
}

/// Single source of truth for **series-scoped** favorite / rating across live
/// pages (detail sheet, theater watchlist). Player right-rail episode
/// favorites use [EpisodeEngagementController.toggleWorkFavorite] instead.
///
/// Data-freshness contract:
/// - [seed] fills only missing fields — safe for cached payloads which may be
///   older than an in-flight optimistic mutation.
/// - [applyServer] overwrites — only call with force-refreshed server data.
///   While a mutation is in flight the payload is stashed instead, and used
///   to reconcile if the mutation fails (it is fresher than the pre-mutation
///   snapshot).
class DramaEngagementController extends Notifier<DramaEngagementState> {
  DramaEngagementController(this._dramaId);

  final String _dramaId;

  ({bool? favoritedByMe, int? favoriteCount, int? myRating, double? avgRating})?
  _pendingServer;

  @override
  DramaEngagementState build() {
    _retainAfterLastListener(ref);
    _pendingServer = null;
    // Instant-display hint from the local watchlist; server data overwrites
    // it (both directions) as soon as any page applies a fresh fetch.
    bool? hint;
    try {
      if (ref.read(localRepositoryProvider).isFavorite(_dramaId)) {
        hint = true;
      }
    } catch (_) {}
    return DramaEngagementState(favoritedByMe: hint);
  }

  void seed({
    bool? favoritedByMe,
    int? favoriteCount,
    int? myRating,
    double? avgRating,
  }) {
    state = state.copyWith(
      favoritedByMe: state.favoritedByMe ?? favoritedByMe,
      favoriteCount: state.favoriteCount ?? favoriteCount,
      myRating: state.myRating ?? myRating,
      avgRating: state.avgRating ?? avgRating,
    );
  }

  /// Overwrites known fields from the visible detail payload.
  ///
  /// Unlike [seed], reconciles retained store state from other entry points.
  /// Skipped while [isMutating] so optimistic toggles are not clobbered.
  void applyVisible({
    bool? favoritedByMe,
    int? favoriteCount,
    int? myRating,
    double? avgRating,
  }) {
    if (state.isMutating) return;
    state = state.copyWith(
      favoritedByMe: favoritedByMe ?? state.favoritedByMe,
      favoriteCount: favoriteCount ?? state.favoriteCount,
      myRating: myRating ?? state.myRating,
      avgRating: avgRating ?? state.avgRating,
    );
  }

  void applyServer({
    bool? favoritedByMe,
    int? favoriteCount,
    int? myRating,
    double? avgRating,
  }) {
    if (state.isMutating) {
      // Stash instead of dropping — used to reconcile on mutation failure.
      _pendingServer = (
        favoritedByMe: favoritedByMe,
        favoriteCount: favoriteCount,
        myRating: myRating,
        avgRating: avgRating,
      );
      return;
    }
    state = state.copyWith(
      favoritedByMe: favoritedByMe,
      favoriteCount: favoriteCount,
      myRating: myRating,
      avgRating: avgRating,
    );
    if (favoritedByMe != null) {
      unawaited(_syncWatchlist(favoritedByMe));
    }
  }

  Future<void> _syncWatchlist(bool favoritedByMe) async {
    try {
      final local = ref.read(localRepositoryProvider);
      if (favoritedByMe && !local.isFavorite(_dramaId)) {
        await local.addToWatchlist(_dramaId);
      } else if (!favoritedByMe && local.isFavorite(_dramaId)) {
        await local.removeFromWatchlist(_dramaId);
      }
    } catch (e) {
      StoryLogger.w('watchlist sync failed: $e', tag: 'Engagement');
    }
  }

  /// Optimistically toggles series favorite; rolls back on API failure.
  /// Returns null when a toggle is already in flight (double-tap guard).
  Future<Result<void>?> toggleFavorite({
    int? episodeNo,
    WorkContentType type = WorkContentType.shortDrama,
    String? episodeId,
    String? authorUserId,
    bool? favoritedByMeBaseline,
  }) async {
    if (state.isMutating) return null;
    final baseFavorited = favoritedByMeBaseline ?? state.favoritedByMe ?? false;
    final nextFavorited = !baseFavorited;
    final previous = state;
    _pendingServer = null;
    // 预检期间即占位 isMutating，防止双点重入（预检是异步的）。
    state = state.copyWith(isMutating: true);
    // 黑名单预检：仅在「收藏」时（取消收藏不受影响）拦截。
    if (nextFavorited) {
      final authorId = await _resolveDramaAuthorId(authorUserId);
      if (authorId != null) {
        final currentUserId = ref.read(authControllerProvider).userId;
        if (authorId != currentUserId) {
          final relation = await ref
              .read(followRepositoryProvider)
              .getBlockRelation(authorId);
          if (ref.mounted && relation.isSuccess) {
            final block = relation.dataOrNull;
            if (block != null) {
              if (block.blockedByMe) {
                state = previous.copyWith(isMutating: false);
                return Result.failure(
                  ApiError.business(0, FavoriteBlockErrorMessages.blockedByMe),
                );
              }
              if (block.blockedByTarget) {
                state = previous.copyWith(isMutating: false);
                return Result.failure(
                  ApiError.business(
                    0,
                    FavoriteBlockErrorMessages.blockedByTarget,
                  ),
                );
              }
            }
          }
        }
      }
    }
    // Match [toggleLike]: treat missing count as 0 so the rail never sticks
    // at "0" after a successful favorite when the play payload had no count.
    final baseCount = state.favoriteCount ?? 0;
    final nextCount = (nextFavorited ? baseCount + 1 : baseCount - 1).clamp(
      0,
      StoryConstants.maxFavoriteCountDisplay,
    );
    state = state.copyWith(
      favoritedByMe: nextFavorited,
      favoriteCount: nextCount,
      isMutating: true,
    );

    final engagement = ref.read(dramaEngagementServiceProvider);
    final result = await engagement.toggleDramaFavorite(_dramaId);
    if (!ref.mounted) return result;

    if (result.isFailure) {
      state = previous.copyWith(isMutating: false);
      await engagement.revertWatchlistToggle(_dramaId);
      // A server fetch that arrived mid-mutation is fresher than the
      // pre-mutation snapshot — reconcile to it.
      final pending = _pendingServer;
      _pendingServer = null;
      if (pending != null && ref.mounted) {
        applyServer(
          favoritedByMe: pending.favoritedByMe,
          favoriteCount: pending.favoriteCount,
          myRating: pending.myRating,
          avgRating: pending.avgRating,
        );
      }
      return result;
    }
    // Mutation succeeded: our state is newer than any fetch that raced it.
    _pendingServer = null;
    state = state.copyWith(isMutating: false);
    _syncLoadedProfileList(
      ref,
      type: ProfileDramaType.favorites,
      contentType: type,
      dramaId: _dramaId,
      shouldContain: nextFavorited,
    );
    return result;
  }

  /// Loads the current user's review into the store (no-op for guests —
  /// callers guard on auth).
  Future<void> loadMyRating() async {
    final result = await ref
        .read(dramaRepositoryProvider)
        .getMyReview(dramaId: _dramaId);
    if (!ref.mounted || result.isFailure) return;
    final rating = result.dataOrNull?.rating;
    if (rating != null) {
      applyServer(myRating: rating);
    }
  }

  /// Submits a rating optimistically, then refreshes the authoritative
  /// average (it cannot be computed locally). Rolls back [myRating] on
  /// failure. Returns null when a mutation is already in flight.
  ///
  /// [authorUserId] is the drama author's id; when omitted it is resolved
  /// from the drama detail.
  Future<Result<void>?> submitRating(int rating, {String? authorUserId}) async {
    if (state.isMutating) return null;
    final previous = state;
    _pendingServer = null;
    // 预检期间即占位 isMutating，防止双点重入（预检是异步的）。
    state = state.copyWith(isMutating: true);
    // 黑名单预检：评分前确认与短剧作者的拉黑关系，命中则拦截提示。
    final authorId = await _resolveDramaAuthorId(authorUserId);
    if (authorId != null) {
      final currentUserId = ref.read(authControllerProvider).userId;
      if (authorId != currentUserId) {
        final relation = await ref
            .read(followRepositoryProvider)
            .getBlockRelation(authorId);
        if (ref.mounted && relation.isSuccess) {
          final block = relation.dataOrNull;
          if (block != null) {
            if (block.blockedByMe) {
              state = previous.copyWith(isMutating: false);
              return Result.failure(
                ApiError.business(0, RatingBlockErrorMessages.blockedByMe),
              );
            }
            if (block.blockedByTarget) {
              state = previous.copyWith(isMutating: false);
              return Result.failure(
                ApiError.business(0, RatingBlockErrorMessages.blockedByTarget),
              );
            }
          }
        }
      }
    }
    state = state.copyWith(myRating: rating, isMutating: true);

    final repo = ref.read(dramaRepositoryProvider);
    final result = await repo.submitReview(dramaId: _dramaId, rating: rating);
    if (!ref.mounted) return result;

    if (result.isFailure) {
      state = previous.copyWith(isMutating: false);
      return result;
    }
    state = state.copyWith(isMutating: false);

    // Detail is cached ~10min; evict + refetch so avgRating reflects this
    // review, then push the fresh value to every live page. Best-effort:
    // the submit itself already succeeded.
    final detail = await repo.getDetail(_dramaId, forceRefresh: true);
    if (ref.mounted && detail.isSuccess) {
      applyServer(avgRating: detail.dataOrNull?.avgRating);
    }
    return result;
  }

  /// 解析待收藏短剧的作者 userId：优先用调用方传入的作者 id，否则回退到
  /// 短剧详情。取不到时返回 null（降级放行）。
  Future<String?> _resolveDramaAuthorId(String? provided) async {
    final trimmed = provided?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    final current = ref.read(dramaDetailProvider(_dramaId));
    final fromCurrent = current.asData?.value.dataOrNull?.userId?.trim();
    if (fromCurrent != null && fromCurrent.isNotEmpty) return fromCurrent;
    try {
      final result = await ref.read(dramaDetailProvider(_dramaId).future);
      final userId = result.dataOrNull?.userId?.trim();
      return (userId == null || userId.isEmpty) ? null : userId;
    } catch (_) {
      return null;
    }
  }
}

/// Single source of truth for episode-scoped like / comment / work-favorite.
class EpisodeEngagementController extends Notifier<EpisodeEngagementState> {
  EpisodeEngagementController(this._key);

  final EpisodeEngagementKey _key;

  ({
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
  })?
  _pendingServer;

  @override
  EpisodeEngagementState build() {
    _retainAfterLastListener(ref);
    _pendingServer = null;
    return const EpisodeEngagementState();
  }

  void seed({
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
  }) {
    state = state.copyWith(
      likedByMe: state.likedByMe ?? likedByMe,
      likeCount: state.likeCount ?? likeCount,
      commentCount: state.commentCount ?? commentCount,
      favoritedByMe: state.favoritedByMe ?? favoritedByMe,
      favoriteCount: state.favoriteCount ?? favoriteCount,
    );
  }

  void applyServer({
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
  }) {
    if (state.isMutating) {
      _pendingServer = (
        likedByMe: likedByMe,
        likeCount: likeCount,
        commentCount: commentCount,
        favoritedByMe: favoritedByMe,
        favoriteCount: favoriteCount,
      );
      return;
    }
    state = state.copyWith(
      likedByMe: likedByMe,
      likeCount: likeCount,
      commentCount: commentCount,
      favoritedByMe: favoritedByMe,
      favoriteCount: favoriteCount,
    );
  }

  /// Overwrites known fields from the visible feed card / play payload.
  ///
  /// Unlike [seed], this reconciles retained store state after fast swipes.
  /// Skipped while [isMutating] so optimistic toggles are not clobbered.
  void applyVisible({
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
  }) {
    if (state.isMutating) return;
    state = state.copyWith(
      likedByMe: likedByMe ?? state.likedByMe,
      likeCount: likeCount ?? state.likeCount,
      commentCount: commentCount ?? state.commentCount,
      favoritedByMe: favoritedByMe ?? state.favoritedByMe,
      favoriteCount: favoriteCount ?? state.favoriteCount,
    );
  }

  /// Optimistically toggles like; rolls back on API failure.
  /// Returns null when a toggle is already in flight (double-tap guard).
  ///
  /// [authorUserId] is the work author's id (pass-through from play payload /
  /// feed item); when omitted the author is resolved from the drama detail.
  /// [likedByMeBaseline] overrides [state.likedByMe] when the caller has a
  /// fresher card/play snapshot (e.g. after a fast swipe). When omitted, the
  /// live store value is used.
  Future<Result<void>?> toggleLike({
    int? episodeNo,
    WorkContentType type = WorkContentType.shortDrama,
    String? authorUserId,
    bool? likedByMeBaseline,
  }) async {
    if (state.isMutating) return null;
    final baseLiked = likedByMeBaseline ?? state.likedByMe ?? false;
    final nextLiked = !baseLiked;
    final previous = state;
    _pendingServer = null;
    // 预检期间即占位 isMutating，防止双点重入（预检是异步的）。
    state = state.copyWith(isMutating: true);
    // 黑名单预检：仅在「点赞」时（取消点赞不受影响）拦截。
    if (nextLiked) {
      final authorId = await _resolveWorkAuthorId(authorUserId);
      if (authorId != null) {
        final currentUserId = ref.read(authControllerProvider).userId;
        if (authorId != currentUserId) {
          final relation = await ref
              .read(followRepositoryProvider)
              .getBlockRelation(authorId);
          if (ref.mounted && relation.isSuccess) {
            final block = relation.dataOrNull;
            if (block != null) {
              if (block.blockedByMe) {
                return _rejectBlocked(
                  LikeBlockErrorMessages.blockedByMe,
                  previous,
                );
              }
              if (block.blockedByTarget) {
                return _rejectBlocked(
                  LikeBlockErrorMessages.blockedByTarget,
                  previous,
                );
              }
            }
          }
        }
      }
    }
    final baseCount = state.likeCount ?? 0;
    final nextCount = (nextLiked ? baseCount + 1 : baseCount - 1).clamp(
      0,
      StoryConstants.maxFavoriteCountDisplay,
    );
    state = state.copyWith(
      likedByMe: nextLiked,
      likeCount: nextCount,
      isMutating: true,
      clearLastError: true,
    );

    final engagement = ref.read(dramaEngagementServiceProvider);
    final result = await engagement.toggleEpisodeLike(
      dramaId: _key.dramaId,
      episodeId: _key.episodeId,
      episodeNo: episodeNo ?? _key.episodeNo,
      likedByMe: nextLiked,
      likeCount: nextCount,
      type: type,
    );
    if (!ref.mounted) return result;

    if (result.isFailure) {
      state = previous.copyWith(isMutating: false);
      final pending = _pendingServer;
      _pendingServer = null;
      if (pending != null) {
        applyServer(
          likedByMe: pending.likedByMe,
          likeCount: pending.likeCount,
          commentCount: pending.commentCount,
          favoritedByMe: pending.favoritedByMe,
          favoriteCount: pending.favoriteCount,
        );
      }
      return result;
    }
    _pendingServer = null;
    state = state.copyWith(isMutating: false);
    _syncLoadedProfileList(
      ref,
      type: ProfileDramaType.likes,
      contentType: type,
      dramaId: _key.dramaId,
      shouldContain: nextLiked,
    );
    return result;
  }

  /// Work/episode favorite (player right rail) — not the whole drama series.
  Future<Result<void>?> toggleWorkFavorite({
    int? episodeNo,
    WorkContentType type = WorkContentType.shortDrama,
    String? authorUserId,
    bool? favoritedByMeBaseline,
  }) async {
    if (state.isMutating) return null;
    final baseFavorited = favoritedByMeBaseline ?? state.favoritedByMe ?? false;
    final nextFavorited = !baseFavorited;
    final previous = state;
    _pendingServer = null;
    // 预检期间即占位 isMutating，防止双点重入（预检是异步的）。
    state = state.copyWith(isMutating: true);
    // 黑名单预检：仅在「收藏」时（取消收藏不受影响）拦截。
    if (nextFavorited) {
      final authorId = await _resolveWorkAuthorId(authorUserId);
      if (authorId != null) {
        final currentUserId = ref.read(authControllerProvider).userId;
        if (authorId != currentUserId) {
          final relation = await ref
              .read(followRepositoryProvider)
              .getBlockRelation(authorId);
          if (ref.mounted && relation.isSuccess) {
            final block = relation.dataOrNull;
            if (block != null) {
              if (block.blockedByMe) {
                return _rejectBlocked(
                  FavoriteBlockErrorMessages.blockedByMe,
                  previous,
                );
              }
              if (block.blockedByTarget) {
                return _rejectBlocked(
                  FavoriteBlockErrorMessages.blockedByTarget,
                  previous,
                );
              }
            }
          }
        }
      }
    }
    // Same as like: null count ⇒ 0, so first favorite paints "1" not "0".
    final baseCount = state.favoriteCount ?? 0;
    final nextCount = (nextFavorited ? baseCount + 1 : baseCount - 1).clamp(
      0,
      StoryConstants.maxFavoriteCountDisplay,
    );
    state = state.copyWith(
      favoritedByMe: nextFavorited,
      favoriteCount: nextCount,
      isMutating: true,
      clearLastError: true,
    );

    final engagement = ref.read(dramaEngagementServiceProvider);
    final result = await engagement.toggleWorkFavorite(
      dramaId: _key.dramaId,
      episodeId: _key.episodeId,
      episodeNo: episodeNo ?? _key.episodeNo,
      favoritedByMe: nextFavorited,
      type: type,
    );
    if (!ref.mounted) return result;

    if (result.isFailure) {
      state = previous.copyWith(isMutating: false);
      final pending = _pendingServer;
      _pendingServer = null;
      if (pending != null) {
        applyServer(
          likedByMe: pending.likedByMe,
          likeCount: pending.likeCount,
          commentCount: pending.commentCount,
          favoritedByMe: pending.favoritedByMe,
          favoriteCount: pending.favoriteCount,
        );
      }
      return result;
    }
    _pendingServer = null;
    state = state.copyWith(isMutating: false);
    _syncLoadedProfileList(
      ref,
      type: ProfileDramaType.favorites,
      contentType: type,
      dramaId: type.isShortVideo ? _key.episodeId : _key.dramaId,
      shouldContain: nextFavorited,
    );
    return result;
  }

  /// Called after a comment is successfully posted; bumps the live count and
  /// patches the 24h episode-play cache exactly once.
  void onCommentPosted({int? episodeNo}) =>
      _applyCommentCountDelta(1, episodeNo: episodeNo);

  /// Called after a comment/reply is successfully deleted; decrements the live
  /// count and patches the 24h episode-play cache exactly once.
  ///
  /// [count] defaults to 1 (single reply); deleting a root comment passes
  /// `1 + replyCount` because its replies are cascade-deleted server-side.
  void onCommentDeleted({int? episodeNo, int count = 1}) =>
      _applyCommentCountDelta(-count, episodeNo: episodeNo);

  /// 解析待点赞/收藏作品的作者 userId：优先用调用方传入的作者 id（play
  /// payload / feed item），否则回退到短剧详情。取不到时返回 null（降级放行）。
  Future<String?> _resolveWorkAuthorId(String? provided) async {
    final trimmed = provided?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    final current = ref.read(dramaDetailProvider(_key.dramaId));
    final fromCurrent = current.asData?.value.dataOrNull?.userId?.trim();
    if (fromCurrent != null && fromCurrent.isNotEmpty) return fromCurrent;
    try {
      final result = await ref.read(dramaDetailProvider(_key.dramaId).future);
      final userId = result.dataOrNull?.userId?.trim();
      return (userId == null || userId.isEmpty) ? null : userId;
    } catch (_) {
      return null;
    }
  }

  /// 黑名单拦截：把 [message]（sentinel）写入 state 级 lastError 并返回失败，
  /// UI 经 `l10nError` 本地化 toast 提示。基于预检前的 [previous] 恢复
  /// isMutating，避免双点保护标志残留。
  Result<void>? _rejectBlocked(
    String message,
    EpisodeEngagementState previous,
  ) {
    state = previous.copyWith(
      isMutating: false,
      lastError: ApiError.business(0, message),
    );
    return Result.failure(ApiError.business(0, message));
  }

  void _applyCommentCountDelta(int delta, {int? episodeNo}) {
    state = state.copyWith(
      commentCount: ((state.commentCount ?? 0) + delta).clamp(0, 1 << 31),
    );
    final epNo = episodeNo ?? _key.episodeNo;
    if (epNo != null) {
      unawaited(
        ref
            .read(dramaRepositoryProvider)
            .patchCachedEpisodePlay(
              _key.dramaId,
              epNo,
              commentCountDelta: delta,
            ),
      );
    }
  }
}

void _syncLoadedProfileList(
  Ref ref, {
  required ProfileDramaType type,
  WorkContentType contentType = WorkContentType.shortDrama,
  required String dramaId,
  required bool shouldContain,
}) {
  final provider = userProfileDramasProvider(
    UserProfileDramaParam(type: type, contentType: contentType),
  );
  if (!ref.exists(provider)) return;

  final notifier = ref.read(provider.notifier);
  if (shouldContain) {
    unawaited(notifier.silentRevalidateAfterMutation());
  } else {
    notifier.removeDrama(dramaId);
  }
}
