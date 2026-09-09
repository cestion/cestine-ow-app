// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: asString(json['id']),
  userId: asString(json['userId']),
  nickname: json['nickname'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  bio: json['profile'] as String?,
  email: json['email'] as String?,
  walletAddress: json['walletAddress'] as String?,
  loginType: json['loginType'] as String?,
  inviteCode: json['inviteCode'] as String?,
  inviterUserId: json['inviterUserId'] as String?,
  skipInviteCode: asString(json['skipInviteCode']),
  trust: asDouble(json['trust']),
  createdAt: asInt(json['createdAt']),
  updatedAt: asInt(json['updatedAt']),
  isDeleted: asString(json['isDeleted']),
  followStats: _followStatsFromJson(json['followStats']),
  relationStatus: _relationStatusFromJson(json['relationStatus']),
  blockedByMe: _blockedByMeValue(json, 'blockedByMe') == null
      ? false
      : _boolFromJson(_blockedByMeValue(json, 'blockedByMe')),
  blockedByTarget: _blockedByTargetValue(json, 'blockedByTarget') == null
      ? false
      : _boolFromJson(_blockedByTargetValue(json, 'blockedByTarget')),
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'nickname': instance.nickname,
      'avatarUrl': instance.avatarUrl,
      'profile': instance.bio,
      'email': instance.email,
      'walletAddress': instance.walletAddress,
      'loginType': instance.loginType,
      'inviteCode': instance.inviteCode,
      'inviterUserId': instance.inviterUserId,
      'skipInviteCode': instance.skipInviteCode,
      'trust': instance.trust,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'isDeleted': instance.isDeleted,
    };
