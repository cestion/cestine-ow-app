import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/drama_repository.dart';
import 'comment_state.dart';
import 'engagement_state.dart';
import 'story_controller_mixin.dart';

class CommentArgs {
  final String dramaId;
  final String? episodeId;

  /// Episode number, used only to patch the episode-play cache after a
  /// successful post. Deliberately excluded from equality so callers with and
  /// without it share the same provider instance.
  final int? episodeNo;

  const CommentArgs({required this.dramaId, this.episodeId, this.episodeNo});

  @override
  bool operator ==(Object other) {
    return other is CommentArgs &&
        other.dramaId == dramaId &&
        other.episodeId == episodeId;
  }

  @override
  int get hashCode => Object.hash(dramaId, episodeId);
}

/// Appends [incoming] to [existing], skipping items whose `commentId` already
/// exists in [existing] so a just-posted comment (temporarily pinned into the
/// list) is not duplicated again when a later page happens to contain it.
List<StoryComment> _mergeDeduped(
  List<StoryComment> existing,
  List<StoryComment>? incoming,
) {
  final existingIds = existing.map((c) => c.commentId).toSet();
  final additions = (incoming ?? const <StoryComment>[])
      .where((c) => c.commentId != null && !existingIds.contains(c.commentId))
      .toList();
  return [...existing, ...additions];
}

/// 把 [justPosted] 回复逐个移动到其被回复对象（[StoryComment.parentId]）
/// 之后，保证刚发布的回复始终紧挨目标，不受服务端排序影响。
///
/// [featuredReplyId] 为根评论的精选评论 id（位于回复组之外）：回复精选的
/// 刚发布回复应插到回复组顶部（精选之后渲染）。目标不存在时回退到末尾。
List<StoryComment> _repositionJustPosted(
  List<StoryComment> list,
  List<StoryComment> justPosted, {
  String? featuredReplyId,
}) {
  final result = List<StoryComment>.from(list);
  for (final reply in justPosted) {
    final replyId = reply.commentId;
    if (replyId == null) continue;
    final currentIndex = result.indexWhere((r) => r.commentId == replyId);
    if (currentIndex != -1) result.removeAt(currentIndex);

    final targetId = reply.parentId;
    if (targetId != null && targetId == featuredReplyId) {
      result.insert(0, reply);
      continue;
    }
    if (targetId == null || targetId.isEmpty) {
      result.add(reply);
      continue;
    }
    final targetIndex = result.indexWhere((r) => r.commentId == targetId);
    if (targetIndex == -1) {
      result.add(reply);
    } else {
      result.insert(targetIndex + 1, reply);
    }
  }
  return result;
}

/// The comment a pending reply will be attached to.
///
/// The UI keeps one active target at a time; when set, the input bar switches
/// to "reply" mode and [CommentController.postReply] is called on send.
class CommentReplyTarget {
  /// The root (first-level) comment id the reply belongs to. Used as the key
  /// for the reply group so the reply stays under the right root comment.
  final String rootId;

  /// The comment actually being replied to: the root comment for a direct
  /// reply, or a second-level comment when replying to one of them. Passed to
  /// the API; defaults to [rootId] when replying directly to the root comment.
  final String? replyToCommentId;

  /// Author of the targeted comment, used for the input hint and `@` prefix.
  final String replyToNickname;

  const CommentReplyTarget({
    required this.rootId,
    this.replyToCommentId,
    required this.replyToNickname,
  });

  /// The comment id the API should attach the reply to.
  String get effectiveReplyToId => replyToCommentId ?? rootId;
}

/// Loads and posts comments for a single (dramaId, episodeId) pair.
class CommentController extends Notifier<CommentState>
    with StoryControllerMixin<CommentState> {
  late final DramaRepository _repo;
  final CommentArgs _args;

  CommentController(this._args);

  String get dramaId => _args.dramaId;
  String? get episodeId => _args.episodeId;
  List<StoryComment> get comments => state.comments;
  bool get isLoading => state.isLoading;
  bool get isPosting => state.isPosting;
  String get errorMessage => state.errorMessage;

  /// 最近一次操作的错误（点赞/删除等），供 UI 层 toast 本地化提示
  /// （如评论被删除后点赞/回复返回 125101「评论不存在」）。
  ApiError? get lastError => state.lastError;

  /// 是否为「评论不存在」业务错误（125101）：回复/删除/点赞的目标评论
  /// 已被删除（如后台审核删除）时服务端返回该码，此时应把本地仍展示的
  /// 该评论一并移除，避免残留无效数据。
  bool _isCommentNotExists(ApiError? error) =>
      error is BusinessError && error.code == ApiResponseCode.commentNotExists;

  /// 根评论的回复数（0 当评论已不在列表中）。
  int _rootReplyCountOf(String rootId) {
    final index = state.comments.indexWhere((c) => c.commentId == rootId);
    return index == -1 ? 0 : (state.comments[index].replyCount ?? 0);
  }

  /// 在已加载的评论数据中定位 [commentId] 的作者 userId，找不到返回 null。
  ///
  /// 覆盖一级评论、精选回复、已加载的二级回复以及刚发布的临时置顶回复。
  String? _commentAuthorIdOf(String commentId) {
    StoryComment? found;
    for (final comment in state.comments) {
      if (comment.commentId == commentId) {
        found = comment;
        break;
      }
      if (comment.featuredReply?.commentId == commentId) {
        found = comment.featuredReply;
        break;
      }
    }
    if (found == null) {
      for (final group in state.replyGroups.values) {
        for (final reply in group.replies) {
          if (reply.commentId == commentId) {
            found = reply;
            break;
          }
        }
        if (found != null) break;
      }
    }
    if (found == null) {
      for (final list in state.justPostedReplies.values) {
        for (final reply in list) {
          if (reply.commentId == commentId) {
            found = reply;
            break;
          }
        }
        if (found != null) break;
      }
    }
    final userId = found?.userId?.trim();
    return (userId == null || userId.isEmpty) ? null : userId;
  }

  /// 黑名单拦截：把 [message]（sentinel）写入组级与 state 级 lastError，
  /// UI 经 `l10nError` 本地化 toast 提示，与 125101 走同一展示路径。
  void _setReplyBlocked(String rootId, String message) {
    final error = ApiError.business(0, message);
    _updateReplyGroup(
      rootId,
      (g) => g.copyWith(isPosting: false, lastError: error),
    );
    state = state.copyWith(lastError: error);
  }

  @override
  CommentState build() {
    _repo = ref.read(dramaRepositoryProvider);
    return const CommentState();
  }

  @override
  CommentState copyWithLoadingState({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return state.copyWith(
      isLoading: isLoading,
      lastError: lastError,
      clearLastError: clearLastError,
    );
  }

  Future<void> loadComments() async {
    if (episodeId == null) {
      StoryLogger.w(
        'Skip loading comments: episodeId is null dramaId=$dramaId',
        tag: 'NotificationNavigation',
      );
      state = state.copyWith(isLoading: false);
      return;
    }
    StoryLogger.d(
      'Loading comments dramaId=$dramaId episodeId=$episodeId',
      tag: 'NotificationNavigation',
    );
    final result = await withLoadingResult<PageDto<StoryComment>>(
      // forceRefresh：每次打开评论区强制拉取最新首页数据（写入并覆盖
      // 缓存），避免 TTL 内命中旧缓存看不到他人新发表的评论。
      () => _repo.getEpisodeComments(episodeId!, forceRefresh: true),
    );
    if (!ref.mounted) return;
    if (result != null) {
      final comments = result.list ?? const <StoryComment>[];
      state = state.copyWith(
        comments: comments,
        nextMark: result.mark ?? '',
        hasMore: result.hasMore ?? false,
        justPostedReplies: const {},
      );
      StoryLogger.i(
        'Loaded comments dramaId=$dramaId episodeId=$episodeId '
        'count=${comments.length}',
        tag: 'NotificationNavigation',
      );
    } else {
      StoryLogger.w(
        'Failed to load comments dramaId=$dramaId episodeId=$episodeId '
        'error=${state.lastError?.userMessage}',
        tag: 'NotificationNavigation',
      );
    }
  }

  /// Loads the next page of comments. Carries the previous page's mark
  /// verbatim into the request, and stops once the API reports
  /// `hasMore == false` with `mark == "-1"`.
  ///
  /// 使用独立的 [CommentState.isLoadingMore]（而非首屏 isLoading）标记
  /// 加载中，避免滚动触底翻页时 UI 把整个列表替换成整页 loading。
  Future<void> loadMoreComments() async {
    if (episodeId == null ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repo.getEpisodeComments(
        episodeId!,
        mark: state.nextMark.isEmpty ? null : state.nextMark,
      );
      if (!ref.mounted) return;
      result.when(
        success: (page) {
          final stop = page.hasMore == false && page.mark == '-1';
          state = state.copyWith(
            comments: _mergeDeduped(state.comments, page.list),
            nextMark: page.mark ?? state.nextMark,
            hasMore: stop ? false : (page.hasMore ?? state.hasMore),
            isLoadingMore: false,
          );
        },
        failure: (error) {
          state = state.copyWith(isLoadingMore: false, lastError: error);
        },
      );
    } catch (e, st) {
      if (!ref.mounted) return;
      StoryLogger.e(
        'loadMoreComments failed: $e',
        error: e,
        stackTrace: st,
        tag: 'Comment',
      );
      state = state.copyWith(
        isLoadingMore: false,
        lastError: ApiError.unknown(e.toString()),
      );
    }
  }

  /// Posts a comment. Returns true on success so callers do not have to
  /// infer success from list-length diffs.
  ///
  /// On success this is the single place that propagates the new comment
  /// count: it bumps [episodeEngagementProvider] (live pages) which in turn
  /// patches the episode-play cache (re-entry staleness).
  Future<bool> postComment(String content) async {
    if (content.isEmpty || episodeId == null) return false;
    // 黑名单预检：发布一级评论前先确认与短剧/作品作者的拉黑关系，命中则
    // 拦截提示（作者信息取自短剧详情，未加载时降级放行交由服务端判定）。
    final currentUserId = ref.read(authControllerProvider).userId;
    final authorId = await _resolveEpisodeAuthorId();
    if (authorId != null && authorId != currentUserId) {
      final relation = await ref
          .read(followRepositoryProvider)
          .getBlockRelation(authorId);
      if (ref.mounted && relation.isSuccess) {
        final block = relation.dataOrNull;
        if (block != null) {
          if (block.blockedByMe) {
            _setCommentBlocked(CommentBlockErrorMessages.blockedByMe);
            return false;
          }
          if (block.blockedByTarget) {
            _setCommentBlocked(CommentBlockErrorMessages.blockedByTarget);
            return false;
          }
        }
      }
    }
    var posted = false;
    state = state.copyWith(isPosting: true, clearLastError: true);
    try {
      final result = await _repo.postEpisodeComment(episodeId!, content);
      if (!ref.mounted) return false;
      result.when(
        success: (comment) {
          posted = true;
          // Enrich with current user profile if API returned null fields.
          final profile = ref.read(authControllerProvider).profile;
          final enriched =
              (comment.nickname == null &&
                  comment.avatarUrl == null &&
                  profile != null)
              ? StoryComment(
                  commentId: comment.commentId,
                  userId: comment.userId ?? profile.userId,
                  nickname: profile.nickname,
                  avatarUrl: profile.avatarUrl,
                  content: comment.content,
                  likeCount: comment.likeCount,
                  likedByMe: comment.likedByMe,
                  createdAt: comment.createdAt,
                )
              : comment;
          state = state.copyWith(
            comments: [enriched, ...state.comments],
            clearLastError: true,
          );
          _bumpCommentCount();
        },
        failure: (error) {
          state = state.copyWith(lastError: error);
        },
      );
    } catch (e, st) {
      if (!ref.mounted) return false;
      StoryLogger.e(
        'postComment failed: $e',
        error: e,
        stackTrace: st,
        tag: 'Comment',
      );
      state = state.copyWith(lastError: ApiError.unknown(e.toString()));
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isPosting: false);
      }
    }
    return posted;
  }

  /// Whether the current user may delete [comment]: only the drama's author
  /// or the comment's own author.
  bool canDeleteComment(StoryComment comment) {
    final commentId = comment.commentId;
    if (commentId == null || commentId.isEmpty) return false;
    final currentUserId = ref.read(authControllerProvider).userId;
    if (currentUserId == null || currentUserId.isEmpty) return false;
    if (comment.userId != null && comment.userId == currentUserId) return true;
    return _isDramaAuthor;
  }

  /// Whether the current user is this drama's (video's) author.
  bool get _isDramaAuthor {
    final currentUserId = ref.read(authControllerProvider).userId;
    if (currentUserId == null || currentUserId.isEmpty) return false;
    final dramaAuthorId = ref
        .read(dramaDetailProvider(dramaId))
        .asData
        ?.value
        .dataOrNull
        ?.userId;
    return dramaAuthorId != null && dramaAuthorId == currentUserId;
  }

  /// 当前短剧/作品作者 userId（取自短剧详情）。详情未加载时等待其解析，
  /// 解析失败或取不到时返回 null，调用方据此降级放行（交由服务端判定）。
  Future<String?> _resolveEpisodeAuthorId() async {
    final current = ref.read(dramaDetailProvider(dramaId));
    final fromCurrent = current.asData?.value.dataOrNull?.userId?.trim();
    if (fromCurrent != null && fromCurrent.isNotEmpty) return fromCurrent;
    try {
      final result = await ref.read(dramaDetailProvider(dramaId).future);
      final userId = result.dataOrNull?.userId?.trim();
      return (userId == null || userId.isEmpty) ? null : userId;
    } catch (_) {
      return null;
    }
  }

  /// 黑名单拦截：把 [message]（sentinel）写入 state 级 lastError，UI 经
  /// `l10nError` 本地化 toast 提示。
  void _setCommentBlocked(String message) {
    state = state.copyWith(
      isPosting: false,
      lastError: ApiError.business(0, message),
    );
  }

  /// 作者点赞/取消点赞后本地同步「作者赞过」标签，使其即时展示。
  ///
  /// 展示层 [CommentTagBadges] 已处理 FIRST 与 AUTHOR_LIKED 并存时的
  /// 优先级（首评优先），此处数据层不做互斥过滤。
  StoryComment _withAuthorLikedTag(
    StoryComment comment, {
    required bool liked,
  }) {
    final tags = comment.tags ?? const <String>[];
    if (liked) {
      if (tags.contains('AUTHOR_LIKED')) return comment;
      return comment.copyWith(tags: [...tags, 'AUTHOR_LIKED']);
    }
    if (!tags.contains('AUTHOR_LIKED')) return comment;
    return comment.copyWith(
      tags: tags.where((t) => t != 'AUTHOR_LIKED').toList(growable: false),
    );
  }

  /// Optimistically removes [commentId] from the list, then deletes it on the
  /// server. On failure the comment is restored and the error is surfaced.
  ///
  /// Returns true when the comment was actually deleted.
  Future<bool> deleteComment(String commentId) async {
    final index = state.comments.indexWhere((c) => c.commentId == commentId);
    if (index == -1) return false;
    final target = state.comments[index];
    if (!canDeleteComment(target)) return false;

    var deleted = false;
    final optimisticList = List<StoryComment>.from(state.comments)
      ..removeAt(index);
    state = state.copyWith(comments: optimisticList, clearLastError: true);

    try {
      final result = await _repo.deleteComment(commentId);
      if (!ref.mounted) return false;
      result.when(
        success: (_) {
          deleted = true;
          // 删除一级评论时其下属二级回复被连锁删除，评论总数按
          // 1 + replyCount 一并扣减。
          _decrementCommentCount(count: 1 + (target.replyCount ?? 0));
          final epId = episodeId;
          if (epId != null) {
            unawaited(_repo.invalidateCommentsCache(epId));
          }
        },
        failure: (error) {
          // 评论已不存在（如被后台审核删除）：保持乐观移除，不恢复，
          // 并按连锁数量扣减评论总数。
          if (_isCommentNotExists(error)) {
            _removeNotFoundComment(commentId, target.replyCount ?? 0);
            // 仍记录错误供 UI toast「评论不存在」。
            state = state.copyWith(lastError: error);
            return;
          }
          _restoreDeletedComment(target, index, error);
        },
      );
    } catch (e, st) {
      if (!ref.mounted) return false;
      StoryLogger.e(
        'deleteComment failed: $e',
        error: e,
        stackTrace: st,
        tag: 'Comment',
      );
      _restoreDeletedComment(target, index, ApiError.unknown(e.toString()));
    }
    return deleted;
  }

  void _restoreDeletedComment(StoryComment target, int index, ApiError error) {
    final restoredList = List<StoryComment>.from(state.comments);
    restoredList.insert(index.clamp(0, restoredList.length), target);
    state = state.copyWith(comments: restoredList, lastError: error);
  }

  /// 服务端判定评论已不存在（125101）时，把该一级评论（连同其二级区块）
  /// 从本地列表移除并同步扣减评论总数。
  void _removeNotFoundComment(String commentId, int replyCount) {
    final index = state.comments.indexWhere((c) => c.commentId == commentId);
    if (index == -1) return;
    final updated = List<StoryComment>.from(state.comments)..removeAt(index);
    // 其回复组与临时置顶回复随根评论一并清理。
    final replyGroups = Map<String, CommentReplyGroup>.from(state.replyGroups)
      ..remove(commentId);
    final justPosted = Map<String, List<StoryComment>>.from(
      state.justPostedReplies,
    )..remove(commentId);
    state = state.copyWith(
      comments: updated,
      replyGroups: replyGroups,
      justPostedReplies: justPosted,
    );
    _decrementCommentCount(count: 1 + replyCount);
    final epId = episodeId;
    if (epId != null) {
      unawaited(_repo.invalidateCommentsCache(epId));
      unawaited(_repo.invalidateRepliesCache(commentId));
    }
  }

  /// 服务端判定二级回复已不存在（125101）时，把它从所在回复组、精选外显
  /// 与临时置顶位置一并移除，并同步扣减计数。
  void _removeNotFoundReply(String rootId, String replyId) {
    final group = state.replyGroups[rootId];
    final inGroup = group?.replies.any((r) => r.commentId == replyId) ?? false;
    if (inGroup) {
      _updateReplyGroup(rootId, (g) {
        final updated = List<StoryComment>.from(g.replies)
          ..removeWhere((r) => r.commentId == replyId);
        return g.copyWith(replies: updated);
      });
    }
    if (_featuredReplyOf(rootId)?.commentId == replyId) {
      _setFeaturedReply(rootId, null);
    }
    _removeJustPostedReply(rootId, replyId);
    if (inGroup) {
      _patchRootReplyCount(rootId, -1);
      _decrementCommentCount();
    }
    unawaited(_repo.invalidateRepliesCache(rootId));
    _invalidateCommentsCache();
  }

  Future<void> toggleCommentLike(String commentId) async {
    final index = state.comments.indexWhere((c) => c.commentId == commentId);
    if (index == -1) return;

    final comment = state.comments[index];
    final oldLiked = comment.likedByMe ?? false;
    final oldLikeCount = comment.likeCount ?? 0;

    final newLiked = !oldLiked;
    final newLikeCount = newLiked ? oldLikeCount + 1 : oldLikeCount - 1;
    var updatedComment = comment.copyWith(
      likeCount: newLikeCount < 0 ? 0 : newLikeCount,
      likedByMe: newLiked,
    );
    // 视频作者点赞后即时展示/移除「作者赞过」标签。
    if (_isDramaAuthor) {
      updatedComment = _withAuthorLikedTag(updatedComment, liked: newLiked);
    }

    final updatedList = List<StoryComment>.from(state.comments);
    updatedList[index] = updatedComment;
    state = state.copyWith(comments: updatedList, clearLastError: true);

    final result = await _repo.toggleCommentLike(commentId, liked: newLiked);

    if (result.isSuccess) {
      // Cached first-page comments still hold the old likedByMe; evict so
      // a re-opened comment sheet re-fetches fresh state within the TTL.
      final epId = episodeId;
      if (epId != null) {
        unawaited(_repo.invalidateCommentsCache(epId));
      }
      return;
    }

    if (result.isFailure) {
      if (!ref.mounted) return;
      // 评论已不存在（如被后台审核删除）：直接移除，不回滚乐观点赞。
      if (_isCommentNotExists(result.errorOrNull)) {
        _removeNotFoundComment(commentId, comment.replyCount ?? 0);
        state = state.copyWith(lastError: result.errorOrNull);
        return;
      }
      final revertList = List<StoryComment>.from(state.comments);
      final revertIndex = revertList.indexWhere(
        (c) => c.commentId == commentId,
      );
      if (revertIndex != -1) {
        revertList[revertIndex] = comment;
      }
      // 无论评论是否还在列表中，都记录错误供 UI 提示
      // （如评论已被删除时服务端返回 125101「评论不存在」）。
      state = state.copyWith(
        comments: revertList,
        lastError: result.errorOrNull,
      );
    }
  }

  CommentReplyGroup? replyGroupOf(String rootId) => state.replyGroupOf(rootId);

  /// Reply just posted to [rootId] (shown even when the section is collapsed).
  StoryComment? justPostedReplyOf(String rootId) =>
      state.justPostedReplyOf(rootId);

  /// Just-posted replies for [rootId] in display order (empty when none).
  List<StoryComment> justPostedRepliesOf(String rootId) =>
      state.justPostedRepliesOf(rootId);

  void _updateReplyGroup(
    String rootId,
    CommentReplyGroup Function(CommentReplyGroup group) update,
  ) {
    state = state.copyWith(
      replyGroups: {
        ...state.replyGroups,
        rootId: update(
          state.replyGroups[rootId] ?? CommentReplyGroup(rootId: rootId),
        ),
      },
    );
  }

  /// Pins a reply in the collapsed just-posted display for [rootId].
  ///
  /// [afterCommentId] non-null inserts right after that just-posted reply
  /// (回复链）；否则插到首位（回复主评论/精选）。
  void _setJustPostedReply(
    String rootId,
    StoryComment reply, {
    String? afterCommentId,
  }) {
    final current = state.justPostedReplies[rootId] ?? const <StoryComment>[];
    final list = List<StoryComment>.from(current);
    if (afterCommentId == null) {
      list.insert(0, reply);
    } else {
      final targetIndex = list.indexWhere((r) => r.commentId == afterCommentId);
      list.insert(targetIndex == -1 ? 0 : targetIndex + 1, reply);
    }
    state = state.copyWith(
      justPostedReplies: {...state.justPostedReplies, rootId: list},
    );
  }

  void _removeJustPostedReply(String rootId, String replyId) {
    final current = state.justPostedReplies[rootId];
    if (current == null) return;
    final updated = current
        .where((r) => r.commentId != replyId)
        .toList(growable: false);
    if (updated.isEmpty) {
      _clearJustPostedReply(rootId);
    } else {
      state = state.copyWith(
        justPostedReplies: {...state.justPostedReplies, rootId: updated},
      );
    }
  }

  /// 折叠态外显的刚发布回复（按 id 查找）。
  StoryComment? _justPostedReplyOf(String rootId, String replyId) {
    final list = state.justPostedReplies[rootId];
    if (list == null) return null;
    for (final r in list) {
      if (r.commentId == replyId) return r;
    }
    return null;
  }

  /// 用 [updated] 替换折叠态外显的刚发布回复（如点赞状态变化），
  /// 保证折叠态 UI 与回复组数据同步。
  void _updateJustPostedReply(
    String rootId,
    String replyId,
    StoryComment updated,
  ) {
    final current = state.justPostedReplies[rootId];
    if (current == null) return;
    final index = current.indexWhere((r) => r.commentId == replyId);
    if (index == -1) return;
    final list = List<StoryComment>.from(current);
    list[index] = updated;
    state = state.copyWith(
      justPostedReplies: {...state.justPostedReplies, rootId: list},
    );
  }

  void _clearJustPostedReply(String rootId) {
    if (!state.justPostedReplies.containsKey(rootId)) return;
    final updated = Map<String, List<StoryComment>>.from(
      state.justPostedReplies,
    )..remove(rootId);
    state = state.copyWith(justPostedReplies: updated);
  }

  void _invalidateCommentsCache() {
    final epId = episodeId;
    if (epId != null) {
      unawaited(_repo.invalidateCommentsCache(epId));
    }
  }

  /// Bumps the live episode comment count (and patches the episode-play cache)
  /// after a comment or reply is successfully posted.
  void _bumpCommentCount() {
    final epId = episodeId;
    if (epId == null) return;
    ref
        .read(
          episodeEngagementProvider(
            EpisodeEngagementKey.forEpisode(
              dramaId: dramaId,
              episodeId: epId,
              episodeNo: _args.episodeNo,
            ),
          ).notifier,
        )
        .onCommentPosted(episodeNo: _args.episodeNo);
  }

  /// Decrements the live episode comment count after a comment/reply delete.
  ///
  /// [count] defaults to 1；删除一级评论时传 `1 + replyCount`（其下二级
  /// 回复被服务端连锁删除，一并计入扣减）。
  void _decrementCommentCount({int count = 1}) {
    final epId = episodeId;
    if (epId == null) return;
    ref
        .read(
          episodeEngagementProvider(
            EpisodeEngagementKey.forEpisode(
              dramaId: dramaId,
              episodeId: epId,
              episodeNo: _args.episodeNo,
            ),
          ).notifier,
        )
        .onCommentDeleted(episodeNo: _args.episodeNo, count: count);
  }

  /// Loads the first page of replies for [rootId]. No-op when replies are
  /// already loaded or a request is in flight.
  Future<void> loadReplies(String rootId) async {
    if (episodeId == null) return;
    final group = state.replyGroups[rootId];
    if (group != null && group.isLoading) return;
    _updateReplyGroup(
      rootId,
      (g) => g.copyWith(isLoading: true, clearLastError: true),
    );
    try {
      // 首次展开首批共 3 条（含外显的精选回复）：有精选时再加载 2 条，
      // 无精选时加载 3 条（精选在渲染时会从回复列表中去重）。
      final featured = _featuredReplyOf(rootId);
      final firstBatchSize = featured != null ? 2 : 3;
      final result = await _repo.getCommentReplies(
        rootId,
        pageSize: firstBatchSize,
      );
      if (!ref.mounted) return;
      result.when(
        success: (page) {
          // 会话内刚发布的回复保留展示：加载/刷新只把服务端新数据并入并按
          // commentId 去重。刚发布的回复仍需紧挨其被回复对象（精选/主评论/
          // 其它刚发布回复），故在合并后按其 parentId 重新定位到目标下方。
          final serverList = page.list ?? const <StoryComment>[];
          final justPostedList = List<StoryComment>.from(
            state.justPostedReplies[rootId] ?? const [],
          );
          _clearJustPostedReply(rootId);
          _updateReplyGroup(
            rootId,
            (g) => g.copyWith(
              replies: _repositionJustPosted(
                _mergeDeduped(serverList, g.replies),
                justPostedList,
                featuredReplyId: _featuredReplyOf(rootId)?.commentId,
              ),
              nextMark: page.mark ?? '',
              hasMore: page.hasMore ?? false,
              isLoading: false,
            ),
          );
        },
        failure: (error) {
          _updateReplyGroup(
            rootId,
            (g) => g.copyWith(isLoading: false, lastError: error),
          );
        },
      );
    } catch (e, st) {
      if (!ref.mounted) return;
      StoryLogger.e(
        'loadReplies failed: $e',
        error: e,
        stackTrace: st,
        tag: 'Comment',
      );
      _updateReplyGroup(
        rootId,
        (g) => g.copyWith(
          isLoading: false,
          lastError: ApiError.unknown(e.toString()),
        ),
      );
    }
  }

  /// Loads the next page of replies for [rootId], carrying the group's cursor
  /// verbatim into the request.
  Future<void> loadMoreReplies(String rootId) async {
    final group = state.replyGroups[rootId];
    if (episodeId == null ||
        group == null ||
        group.isLoading ||
        !group.hasMore) {
      return;
    }
    _updateReplyGroup(rootId, (g) => g.copyWith(isLoading: true));
    try {
      // 增量加载：每次点击「展开更多」追加 10 条。
      final result = await _repo.getCommentReplies(
        rootId,
        mark: group.nextMark.isEmpty ? null : group.nextMark,
        pageSize: 10,
      );
      if (!ref.mounted) return;
      result.when(
        success: (page) {
          final stop = page.hasMore == false && page.mark == '-1';
          _updateReplyGroup(
            rootId,
            (g) => g.copyWith(
              replies: _mergeDeduped(g.replies, page.list),
              nextMark: page.mark ?? g.nextMark,
              hasMore: stop ? false : (page.hasMore ?? g.hasMore),
              isLoading: false,
            ),
          );
        },
        failure: (error) {
          _updateReplyGroup(
            rootId,
            (g) => g.copyWith(isLoading: false, lastError: error),
          );
        },
      );
    } catch (e, st) {
      if (!ref.mounted) return;
      StoryLogger.e(
        'loadMoreReplies failed: $e',
        error: e,
        stackTrace: st,
        tag: 'Comment',
      );
      _updateReplyGroup(
        rootId,
        (g) => g.copyWith(
          isLoading: false,
          lastError: ApiError.unknown(e.toString()),
        ),
      );
    }
  }

  /// Posts a second-level comment under [rootId]. Returns true on success.
  ///
  /// [replyToCommentId] is the comment the reply is attached to server-side:
  /// the root comment for a direct reply, or the targeted second-level comment
  /// when replying to one. It defaults to [rootId]; the reply is still grouped
  /// under [rootId] in the UI.
  ///
  /// On success the reply is pinned locally:
  /// - replying to a main comment: inserted at the top of the reply group and
  ///   shown even when the section is collapsed (until replies reload);
  /// - replying to a second-level comment: inserted right after it.
  /// The root comment's [StoryComment.replyCount] is bumped as well.
  Future<bool> postReply(
    String rootId,
    String content, {
    String? replyToCommentId,
    String? replyToNickname,
  }) async {
    if (content.isEmpty || episodeId == null) return false;
    // 黑名单预检：回复他人评论前先确认与对方的拉黑关系，命中则拦截提示。
    final currentUserId = ref.read(authControllerProvider).userId;
    final targetUserId = _commentAuthorIdOf(replyToCommentId ?? rootId);
    if (targetUserId != null && targetUserId != currentUserId) {
      final relation = await ref
          .read(followRepositoryProvider)
          .getBlockRelation(targetUserId);
      if (ref.mounted && relation.isSuccess) {
        final block = relation.dataOrNull;
        if (block != null) {
          if (block.blockedByMe) {
            _setReplyBlocked(rootId, CommentBlockErrorMessages.blockedByMe);
            return false;
          }
          if (block.blockedByTarget) {
            _setReplyBlocked(rootId, CommentBlockErrorMessages.blockedByTarget);
            return false;
          }
        }
      }
    }
    var posted = false;
    _updateReplyGroup(
      rootId,
      (g) => g.copyWith(isPosting: true, clearLastError: true),
    );
    try {
      final result = await _repo.postCommentReply(
        replyToCommentId ?? rootId,
        content: content,
      );
      if (!ref.mounted) return false;
      result.when(
        success: (reply) {
          posted = true;
          final profile = ref.read(authControllerProvider).profile;
          final enriched =
              (reply.nickname == null &&
                  reply.avatarUrl == null &&
                  profile != null)
              ? reply.copyWith(
                  userId: reply.userId ?? profile.userId,
                  nickname: profile.nickname,
                  avatarUrl: profile.avatarUrl,
                )
              : reply;
          // 记录回复对象 id，供 loadReplies 重排时把刚发布回复紧挨其下方。
          final targetId = replyToCommentId ?? rootId;
          // 服务端可能不回填 replyToNickname：用调用方传入的回复对象昵称
          // 补齐，保证刚发布的回复立即显示「回复 @xxx：」前缀。
          final anchored = enriched.copyWith(
            parentId: enriched.parentId ?? targetId,
            replyToNickname: enriched.replyToNickname ?? replyToNickname,
          );
          final repliesToMain =
              replyToCommentId == null || replyToCommentId == rootId;
          // 精选评论在折叠态常显：回复它时也应置 justPosted，让新回复在
          // 精选下方外显，直到列表重新获取后按服务端顺序排列。
          final featuredId = _featuredReplyOf(rootId)?.commentId;
          final repliesToFeatured =
              !repliesToMain &&
              featuredId != null &&
              replyToCommentId == featuredId;
          // 折叠态外显的 justPosted 回复同样可见：回复它时把新回复插到其
          // 下方一并外显（支持回复链）。
          final justPostedList = state.justPostedReplies[rootId];
          final repliesToJustPosted =
              !repliesToMain &&
              (justPostedList?.any((r) => r.commentId == replyToCommentId) ??
                  false);
          _updateReplyGroup(rootId, (g) {
            final list = List<StoryComment>.from(g.replies);
            if (repliesToMain) {
              list.insert(0, anchored);
            } else {
              final targetIndex = list.indexWhere(
                (r) => r.commentId == replyToCommentId,
              );
              list.insert(targetIndex == -1 ? 0 : targetIndex + 1, anchored);
            }
            return g.copyWith(replies: list, isPosting: false);
          });
          if (repliesToMain || repliesToFeatured) {
            _setJustPostedReply(rootId, anchored);
          } else if (repliesToJustPosted) {
            _setJustPostedReply(
              rootId,
              anchored,
              afterCommentId: replyToCommentId,
            );
          }
          _patchRootReplyCount(rootId, 1);
          // Evict the cached first-page replies so a re-expanded list re-fetches
          // fresh server data that includes the new reply (when posting to a
          // second-level comment the repo only evicts that comment's own cache).
          unawaited(_repo.invalidateRepliesCache(rootId));
          // 根评论的 replyCount 同时缓存在一级评论缓存中，一并失效。
          _invalidateCommentsCache();
          // 回复也计入评论总数，同步递增 live count。
          _bumpCommentCount();
          // 清除 state 级错误（组级已随上处 copyWith 清除）。
          state = state.copyWith(clearLastError: true);
        },
        failure: (error) {
          _updateReplyGroup(
            rootId,
            (g) => g.copyWith(isPosting: false, lastError: error),
          );
          // state 级同步记录：125101 连根移除根评论时回复组会被删除，
          // 组级错误随之丢失，UI 需从 state 级读取 toast。
          state = state.copyWith(lastError: error);
          // 回复目标已不存在（如被后台审核删除）：目标是一级评论时连根
          // 移除；目标是二级回复时仅移除该回复。
          if (_isCommentNotExists(error) && ref.mounted) {
            final targetId = replyToCommentId ?? rootId;
            if (targetId == rootId) {
              _removeNotFoundComment(rootId, _rootReplyCountOf(rootId));
            } else {
              _removeNotFoundReply(rootId, targetId);
            }
          }
        },
      );
    } catch (e, st) {
      if (!ref.mounted) return false;
      StoryLogger.e(
        'postReply failed: $e',
        error: e,
        stackTrace: st,
        tag: 'Comment',
      );
      _updateReplyGroup(
        rootId,
        (g) => g.copyWith(
          isPosting: false,
          lastError: ApiError.unknown(e.toString()),
        ),
      );
    }
    return posted;
  }

  /// Optimistically removes [replyId] from [rootId]'s group, then deletes it on
  /// the server. On failure the reply is restored. Returns true when deleted.
  ///
  /// Handles both the loaded reply list, the root comment's featured reply
  /// (精选评论, which lives outside the reply group), and the just-posted reply
  /// （刚发布临时置顶，折叠态外显）。
  Future<bool> deleteReply(String rootId, String replyId) async {
    final group = state.replyGroups[rootId];
    final index =
        group?.replies.indexWhere((r) => r.commentId == replyId) ?? -1;
    final featured = _featuredReplyOf(rootId);
    final isFeatured = featured?.commentId == replyId;
    final justPostedList = state.justPostedReplies[rootId];
    StoryComment? justPostedTarget;
    if (justPostedList != null) {
      for (final r in justPostedList) {
        if (r.commentId == replyId) {
          justPostedTarget = r;
          break;
        }
      }
    }
    final isJustPosted = justPostedTarget != null;
    if (index == -1 && !isFeatured && !isJustPosted) return false;
    final target = index != -1
        ? group!.replies[index]
        : (isFeatured ? featured! : justPostedTarget!);
    if (!canDeleteComment(target)) return false;

    var deleted = false;
    if (index != -1) {
      final optimisticList = List<StoryComment>.from(group!.replies)
        ..removeAt(index);
      _updateReplyGroup(
        rootId,
        (g) => g.copyWith(replies: optimisticList, clearLastError: true),
      );
    }
    if (isFeatured) {
      _setFeaturedReply(rootId, null);
    }
    if (isJustPosted) {
      _removeJustPostedReply(rootId, replyId);
    }

    try {
      final result = await _repo.deleteComment(replyId);
      if (!ref.mounted) return false;
      result.when(
        success: (_) {
          deleted = true;
          _patchRootReplyCount(rootId, -1);
          _decrementCommentCount();
          unawaited(_repo.invalidateRepliesCache(rootId));
          // 根评论的 featuredReply / replyCount 缓存在一级评论缓存中，
          // 删除二级评论后一并失效，避免重新加载后精选/计数回退。
          _invalidateCommentsCache();
        },
        failure: (error) {
          // 回复已不存在（如被后台审核删除）：保持乐观移除，不恢复。
          if (_isCommentNotExists(error)) {
            _patchRootReplyCount(rootId, -1);
            _decrementCommentCount();
            unawaited(_repo.invalidateRepliesCache(rootId));
            _invalidateCommentsCache();
            // 仍记录错误供 UI toast「评论不存在」。
            _updateReplyGroup(rootId, (g) => g.copyWith(lastError: error));
            state = state.copyWith(lastError: error);
            return;
          }
          _restoreDeletedReply(
            rootId,
            target,
            index,
            error,
            featured: featured,
            justPosted: justPostedTarget,
          );
        },
      );
    } catch (e, st) {
      if (!ref.mounted) return false;
      StoryLogger.e(
        'deleteReply failed: $e',
        error: e,
        stackTrace: st,
        tag: 'Comment',
      );
      _restoreDeletedReply(
        rootId,
        target,
        index,
        ApiError.unknown(e.toString()),
        featured: featured,
        justPosted: justPostedTarget,
      );
    }
    return deleted;
  }

  void _restoreDeletedReply(
    String rootId,
    StoryComment target,
    int index,
    ApiError error, {
    StoryComment? featured,
    StoryComment? justPosted,
  }) {
    if (index != -1) {
      _updateReplyGroup(rootId, (g) {
        final restoredList = List<StoryComment>.from(g.replies);
        restoredList.insert(index.clamp(0, restoredList.length), target);
        return g.copyWith(replies: restoredList, lastError: error);
      });
    }
    if (featured != null) {
      _setFeaturedReply(rootId, featured);
    }
    if (justPosted != null) {
      _setJustPostedReply(rootId, justPosted);
    }
  }

  void _patchRootReplyCount(String rootId, int delta) {
    final index = state.comments.indexWhere((c) => c.commentId == rootId);
    if (index == -1) return;
    final comment = state.comments[index];
    final updated = comment.copyWith(
      replyCount: ((comment.replyCount ?? 0) + delta).clamp(0, 1 << 31),
    );
    final list = List<StoryComment>.from(state.comments);
    list[index] = updated;
    state = state.copyWith(comments: list);
  }

  /// Optimistically toggles the like on a second-level comment and reverts on
  /// failure, mirroring [toggleCommentLike].
  ///
  /// Handles the loaded reply list, the root comment's featured reply
  /// （精选评论，渲染自 [StoryComment.featuredReply]、存于回复组之外）and
  /// the just-posted reply（刚发布回复，折叠态从 justPostedReplies 外显，
  /// 与回复组是两个独立列表，需同步更新两处）。
  Future<void> toggleReplyLike(String rootId, String replyId) async {
    final group = state.replyGroups[rootId];
    final index =
        group?.replies.indexWhere((r) => r.commentId == replyId) ?? -1;
    final featured = _featuredReplyOf(rootId);
    final isFeatured = featured?.commentId == replyId;
    final justPosted = _justPostedReplyOf(rootId, replyId);
    if (index == -1 && !isFeatured && justPosted == null) return;

    final reply = index != -1
        ? group!.replies[index]
        : (isFeatured ? featured! : justPosted!);
    final oldLiked = reply.likedByMe ?? false;
    final oldLikeCount = reply.likeCount ?? 0;
    final newLiked = !oldLiked;
    final newLikeCount = newLiked ? oldLikeCount + 1 : oldLikeCount - 1;
    var updated = reply.copyWith(
      likedByMe: newLiked,
      likeCount: newLikeCount < 0 ? 0 : newLikeCount,
    );
    // 视频作者点赞后即时展示/移除「作者赞过」标签。
    if (_isDramaAuthor) {
      updated = _withAuthorLikedTag(updated, liked: newLiked);
    }

    if (index != -1) {
      _updateReplyGroup(rootId, (g) {
        final list = List<StoryComment>.from(g.replies);
        list[index] = updated;
        return g.copyWith(replies: list);
      });
    }
    if (isFeatured) {
      _setFeaturedReply(rootId, updated);
    }
    if (justPosted != null) {
      _updateJustPostedReply(rootId, replyId, updated);
    }
    state = state.copyWith(clearLastError: true);

    final result = await _repo.toggleCommentLike(replyId, liked: newLiked);
    if (result.isSuccess) {
      unawaited(_repo.invalidateRepliesCache(rootId));
      return;
    }
    if (result.isFailure && ref.mounted) {
      // 回复已不存在（如被后台审核删除）：直接移除，不回滚乐观点赞。
      if (_isCommentNotExists(result.errorOrNull)) {
        _removeNotFoundReply(rootId, replyId);
        state = state.copyWith(lastError: result.errorOrNull);
        return;
      }
      if (index != -1) {
        _updateReplyGroup(rootId, (g) {
          final revertList = List<StoryComment>.from(g.replies);
          final revertIndex = revertList.indexWhere(
            (r) => r.commentId == replyId,
          );
          if (revertIndex != -1) revertList[revertIndex] = reply;
          return g.copyWith(replies: revertList, lastError: result.errorOrNull);
        });
      } else if (group != null) {
        _updateReplyGroup(
          rootId,
          (g) => g.copyWith(lastError: result.errorOrNull),
        );
      }
      if (isFeatured) {
        _setFeaturedReply(rootId, reply);
      }
      if (justPosted != null) {
        _updateJustPostedReply(rootId, replyId, reply);
      }
      // state 级错误统一供 UI toast（评论被删除后点赞返回 125101 等）。
      state = state.copyWith(lastError: result.errorOrNull);
    }
  }

  StoryComment? _featuredReplyOf(String rootId) {
    final index = state.comments.indexWhere((c) => c.commentId == rootId);
    if (index == -1) return null;
    return state.comments[index].featuredReply;
  }

  void _setFeaturedReply(String rootId, StoryComment? reply) {
    final index = state.comments.indexWhere((c) => c.commentId == rootId);
    if (index == -1) return;
    final comment = state.comments[index];
    // Can't use copyWith to clear a nullable field (it treats null as
    // "unchanged"), so rebuild the comment explicitly.
    final updated = StoryComment(
      commentId: comment.commentId,
      workId: comment.workId,
      rootId: comment.rootId,
      parentId: comment.parentId,
      userId: comment.userId,
      nickname: comment.nickname,
      avatarUrl: comment.avatarUrl,
      author: comment.author,
      replyToUserId: comment.replyToUserId,
      replyToNickname: comment.replyToNickname,
      content: comment.content,
      likeCount: comment.likeCount,
      replyCount: comment.replyCount,
      likedByMe: comment.likedByMe,
      deletable: comment.deletable,
      tags: comment.tags,
      createdAt: comment.createdAt,
      featuredReply: reply,
    );
    final list = List<StoryComment>.from(state.comments);
    list[index] = updated;
    state = state.copyWith(comments: list);
  }
}
