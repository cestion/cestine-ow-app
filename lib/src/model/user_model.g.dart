// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryUser _$StoryUserFromJson(Map<String, dynamic> json) => StoryUser(
  userId: asString(json['userId']),
  account: json['account'] as String?,
  nickname: json['nickname'] as String?,
  avatar: json['avatar'] as String?,
  realName: json['realName'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  token: json['token'] as String?,
  walletAddress: json['walletAddress'] as String?,
  createdAt: asInt(json['createdAt']),
);

Map<String, dynamic> _$StoryUserToJson(StoryUser instance) => <String, dynamic>{
  'userId': instance.userId,
  'account': instance.account,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
  'realName': instance.realName,
  'email': instance.email,
  'phone': instance.phone,
  'token': instance.token,
  'walletAddress': instance.walletAddress,
  'createdAt': instance.createdAt,
};
