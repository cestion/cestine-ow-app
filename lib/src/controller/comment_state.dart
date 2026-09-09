import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

/// Reply state for a single root (first-level) comment.
///
/// Each root comment owns its own pageable reply list so second-level comments
/// can be expanded / paginated independently without blocking the top-level
/// comment list.
class CommentReplyGroup extends Equatable {
  final String rootId;
  final List<StoryComment> replies;

  /// Cursor for the next page, carried verbatim into the next request.
  final String nextMark;

  /// Whether more reply pages can be loaded. Set to false once the API reports
  /// `hasMore == false` with `mark == "-1"`.
  final bool hasMore;
  final bool isLoading;
  final bool isPosting;
  final ApiError? lastError;

  const CommentReplyGroup({
    required this.rootId,
    this.replies = const [],
    this.nextMark = '',
    this.hasMore = true,
    this.isLoading = false,
    this.isPosting = false,
    this.lastError,
  });

  String get errorMessage => lastError?.userMessage ?? '';

  CommentReplyGroup copyWith({
    List<StoryComment>? replies,
    String? nextMark,
    bool? hasMore,
    bool? isLoading,
    bool? isPosting,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return CommentReplyGroup(
      rootId: rootId,
      replies: replies ?? this.replies,
      nextMark: nextMark ?? this.nextMark,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isPosting: isPosting ?? this.isPosting,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  List<Object?> get props => [
    rootId,
    replies,
    nextMark,
    hasMore,
    isLoading,
    isPosting,
    lastError,
  ];
}

class CommentState extends Equatable {
  final bool isLoading;

  /// 加载更多一级评论中（区别于首屏 [isLoading]，不触发整页 loading）。
  final bool isLoadingMore;
  final ApiError? lastError;
  final List<StoryComment> comments;
  final bool isPosting;

  /// Cursor for the next page, carried verbatim into the next request.
  final String nextMark;

  /// Whether more pages can be loaded. Set to false once the API reports
  /// `hasMore == false` with `mark == "-1"`.
  final bool hasMore;

  /// Second-level comments keyed by their root comment id.
  final Map<String, CommentReplyGroup> replyGroups;

  /// Replies just posted to a main (root) comment — or to the featured reply /
  /// another just-posted reply visible in the collapsed section — keyed by root
  /// id, kept in display order. They are temporarily pinned below the featured
  /// reply when the section is collapsed; cleared once the replies are
  /// (re)loaded so a fresh page returns to normal ordering.
  final Map<String, List<StoryComment>> justPostedReplies;

  const CommentState({
    this.isLoading = true,
    this.isLoadingMore = false,
    this.lastError,
    this.comments = const [],
    this.isPosting = false,
    this.nextMark = '',
    this.hasMore = true,
    this.replyGroups = const {},
    this.justPostedReplies = const {},
  });

  String get errorMessage => lastError?.userMessage ?? '';

  /// Reply group for [rootId], or null when it has not been loaded yet.
  CommentReplyGroup? replyGroupOf(String rootId) => replyGroups[rootId];

  /// Just-posted replies for [rootId] in display order (empty when none).
  List<StoryComment> justPostedRepliesOf(String rootId) =>
      justPostedReplies[rootId] ?? const [];

  /// The topmost just-posted reply for [rootId], or null.
  StoryComment? justPostedReplyOf(String rootId) {
    final list = justPostedReplies[rootId];
    return (list == null || list.isEmpty) ? null : list.first;
  }

  CommentState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    ApiError? lastError,
    bool clearLastError = false,
    List<StoryComment>? comments,
    bool? isPosting,
    String? nextMark,
    bool? hasMore,
    Map<String, CommentReplyGroup>? replyGroups,
    Map<String, List<StoryComment>>? justPostedReplies,
  }) {
    return CommentState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      comments: comments ?? this.comments,
      isPosting: isPosting ?? this.isPosting,
      nextMark: nextMark ?? this.nextMark,
      hasMore: hasMore ?? this.hasMore,
      replyGroups: replyGroups ?? this.replyGroups,
      justPostedReplies: justPostedReplies ?? this.justPostedReplies,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingMore,
    lastError,
    comments,
    isPosting,
    nextMark,
    hasMore,
    replyGroups,
    justPostedReplies,
  ];
}
