// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryComment _$StoryCommentFromJson(Map<String, dynamic> json) => StoryComment(
  commentId: asString(_readCommentId(json, 'commentId')),
  workId: asString(json['workId']),
  rootId: asString(json['rootId']),
  parentId: asString(json['parentId']),
  userId: asString(json['userId']),
  nickname: json['nickname'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  author: asBool(json['author']),
  replyToUserId: asString(json['replyToUserId']),
  replyToNickname: json['replyToNickname'] as String?,
  content: json['content'] as String?,
  likeCount: asInt(json['likeCount']),
  replyCount: asInt(json['replyCount']),
  likedByMe: asBool(_readLiked(json, 'likedByMe')),
  deletable: asBool(json['deletable']),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  createdAt: asInt(json['createdAt']),
  featuredReply: json['featuredReply'] == null
      ? null
      : StoryComment.fromJson(json['featuredReply'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StoryCommentToJson(StoryComment instance) =>
    <String, dynamic>{
      'commentId': instance.commentId,
      'workId': instance.workId,
      'rootId': instance.rootId,
      'parentId': instance.parentId,
      'userId': instance.userId,
      'nickname': instance.nickname,
      'avatarUrl': instance.avatarUrl,
      'author': instance.author,
      'replyToUserId': instance.replyToUserId,
      'replyToNickname': instance.replyToNickname,
      'content': instance.content,
      'likeCount': instance.likeCount,
      'replyCount': instance.replyCount,
      'likedByMe': instance.likedByMe,
      'deletable': instance.deletable,
      'tags': instance.tags,
      'createdAt': instance.createdAt,
      'featuredReply': instance.featuredReply,
    };
