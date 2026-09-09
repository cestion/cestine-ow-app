import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'comment_model.g.dart';

Object? _readCommentId(Map<dynamic, dynamic> json, String key) {
  return json['id'] ?? json['commentId'];
}

Object? _readLiked(Map<dynamic, dynamic> json, String key) {
  return json['liked'] ?? json['likedByMe'];
}

@JsonSerializable()
class StoryComment extends Equatable {
  @JsonKey(readValue: _readCommentId, fromJson: asString)
  final String? commentId;
  @JsonKey(fromJson: asString)
  final String? workId;
  @JsonKey(fromJson: asString)
  final String? rootId;
  @JsonKey(fromJson: asString)
  final String? parentId;
  @JsonKey(fromJson: asString)
  final String? userId;
  final String? nickname;
  final String? avatarUrl;

  /// Whether the comment was written by the drama's author.
  @JsonKey(fromJson: asBool)
  final bool? author;
  @JsonKey(fromJson: asString)
  final String? replyToUserId;
  final String? replyToNickname;
  final String? content;
  @JsonKey(fromJson: asInt)
  final int? likeCount;
  @JsonKey(fromJson: asInt)
  final int? replyCount;
  @JsonKey(readValue: _readLiked, fromJson: asBool)
  final bool? likedByMe;

  /// Whether the current user is allowed to delete this comment.
  @JsonKey(fromJson: asBool)
  final bool? deletable;
  final List<String>? tags;
  @JsonKey(fromJson: asInt)
  final int? createdAt;

  /// The comment the drama's author featured under this comment.
  final StoryComment? featuredReply;

  const StoryComment({
    this.commentId,
    this.workId,
    this.rootId,
    this.parentId,
    this.userId,
    this.nickname,
    this.avatarUrl,
    this.author,
    this.replyToUserId,
    this.replyToNickname,
    this.content,
    this.likeCount,
    this.replyCount,
    this.likedByMe,
    this.deletable,
    this.tags,
    this.createdAt,
    this.featuredReply,
  });

  factory StoryComment.fromJson(Map<String, dynamic> json) =>
      _$StoryCommentFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$StoryCommentToJson(this);
    // Fix: json_serializable emits `featuredReply` as a raw StoryComment?
    // object instead of calling .toJson(), which causes Hive serialization
    // errors ("unknown type: StoryComment"). Recursively serialize it.
    json['featuredReply'] = featuredReply?.toJson();
    return json;
  }

  StoryComment copyWith({
    String? commentId,
    String? workId,
    String? rootId,
    String? parentId,
    String? userId,
    String? nickname,
    String? avatarUrl,
    bool? author,
    String? replyToUserId,
    String? replyToNickname,
    String? content,
    int? likeCount,
    int? replyCount,
    bool? likedByMe,
    bool? deletable,
    List<String>? tags,
    int? createdAt,
    StoryComment? featuredReply,
  }) {
    return StoryComment(
      commentId: commentId ?? this.commentId,
      workId: workId ?? this.workId,
      rootId: rootId ?? this.rootId,
      parentId: parentId ?? this.parentId,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      author: author ?? this.author,
      replyToUserId: replyToUserId ?? this.replyToUserId,
      replyToNickname: replyToNickname ?? this.replyToNickname,
      content: content ?? this.content,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      likedByMe: likedByMe ?? this.likedByMe,
      deletable: deletable ?? this.deletable,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      featuredReply: featuredReply ?? this.featuredReply,
    );
  }

  @override
  List<Object?> get props => [
    commentId,
    workId,
    rootId,
    parentId,
    userId,
    nickname,
    avatarUrl,
    author,
    replyToUserId,
    replyToNickname,
    content,
    likeCount,
    replyCount,
    likedByMe,
    deletable,
    tags,
    createdAt,
    featuredReply,
  ];
}
