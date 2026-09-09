import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'user_model.g.dart';

@JsonSerializable()
class StoryUser extends Equatable {
  @JsonKey(fromJson: asString)
  final String? userId;
  final String? account;
  final String? nickname;
  final String? avatar;
  final String? realName;
  final String? email;
  final String? phone;
  final String? token;
  final String? walletAddress;
  @JsonKey(fromJson: asInt)
  final int? createdAt;

  const StoryUser({
    this.userId,
    this.account,
    this.nickname,
    this.avatar,
    this.realName,
    this.email,
    this.phone,
    this.token,
    this.walletAddress,
    this.createdAt,
  });

  factory StoryUser.fromJson(Map<String, dynamic> json) =>
      _$StoryUserFromJson(json);

  Map<String, dynamic> toJson() => _$StoryUserToJson(this);

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  StoryUser copyWith({
    String? userId,
    String? account,
    String? nickname,
    String? avatar,
    String? realName,
    String? email,
    String? phone,
    String? token,
    String? walletAddress,
    int? createdAt,
  }) => StoryUser(
    userId: userId ?? this.userId,
    account: account ?? this.account,
    nickname: nickname ?? this.nickname,
    avatar: avatar ?? this.avatar,
    realName: realName ?? this.realName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    token: token ?? this.token,
    walletAddress: walletAddress ?? this.walletAddress,
    createdAt: createdAt ?? this.createdAt,
  );

  static const StoryUser anonymous = StoryUser();

  @override
  List<Object?> get props => [
    userId,
    account,
    nickname,
    avatar,
    realName,
    email,
    phone,
    token,
    walletAddress,
    createdAt,
  ];
}
