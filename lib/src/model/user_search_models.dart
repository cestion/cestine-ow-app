import 'package:equatable/equatable.dart';

import 'follow_models.dart';
import 'json_converters.dart';

/// Item from `GET /api/userWallet/user/search`.
class UserSearchItem extends Equatable {
  final String userId;
  final String? nickname;
  final String? avatarUrl;
  final String? bio;
  final String shortDramaCount;
  final String workCount;
  final String followerCount;
  final String totalLikeCount;
  final FollowRelationStatus relationStatus;
  final bool isSelf;

  const UserSearchItem({
    required this.userId,
    this.nickname,
    this.avatarUrl,
    this.bio,
    this.shortDramaCount = '0',
    this.workCount = '0',
    this.followerCount = '0',
    this.totalLikeCount = '0',
    this.relationStatus = FollowRelationStatus.none,
    this.isSelf = false,
  });

  factory UserSearchItem.fromJson(Map<String, dynamic> json) {
    final rawStatus = (asString(json['followStatus']) ?? '').toUpperCase();
    final isSelf = rawStatus == 'SELF';
    return UserSearchItem(
      userId: asString(json['userId']) ?? '',
      nickname: asString(json['nickname']),
      avatarUrl: asString(json['avatarUrl']),
      bio: asString(json['profile']),
      shortDramaCount: asString(json['shortDramaCount']) ?? '0',
      workCount: asString(json['workCount']) ?? '0',
      followerCount: asString(json['followerCount']) ?? '0',
      totalLikeCount: asString(json['totalLikeCount']) ?? '0',
      relationStatus: isSelf
          ? FollowRelationStatus.none
          : FollowRelationStatus.fromApi(rawStatus),
      isSelf: isSelf,
    );
  }

  UserSearchItem copyWith({FollowRelationStatus? relationStatus}) {
    return UserSearchItem(
      userId: userId,
      nickname: nickname,
      avatarUrl: avatarUrl,
      bio: bio,
      shortDramaCount: shortDramaCount,
      workCount: workCount,
      followerCount: followerCount,
      totalLikeCount: totalLikeCount,
      relationStatus: relationStatus ?? this.relationStatus,
      isSelf: isSelf,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    nickname,
    avatarUrl,
    bio,
    shortDramaCount,
    workCount,
    followerCount,
    totalLikeCount,
    relationStatus,
    isSelf,
  ];
}
