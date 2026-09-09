import 'package:equatable/equatable.dart';

import 'json_converters.dart';

/// Viewer → target relation from wallet User Follow APIs.
enum FollowRelationStatus {
  none,
  following,
  mutual,
  followBack;

  static FollowRelationStatus fromApi(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'FOLLOWING':
        return FollowRelationStatus.following;
      case 'MUTUAL':
        return FollowRelationStatus.mutual;
      case 'FOLLOW_BACK':
        return FollowRelationStatus.followBack;
      case 'NONE':
      default:
        return FollowRelationStatus.none;
    }
  }

  String get apiValue => switch (this) {
    FollowRelationStatus.none => 'NONE',
    FollowRelationStatus.following => 'FOLLOWING',
    FollowRelationStatus.mutual => 'MUTUAL',
    FollowRelationStatus.followBack => 'FOLLOW_BACK',
  };

  /// I currently follow the target (`FOLLOWING` or `MUTUAL`).
  bool get isFollowing =>
      this == FollowRelationStatus.following ||
      this == FollowRelationStatus.mutual;
}

enum FollowListType { following, followers, mutuals }

/// Viewer ↔ target block relationship returned by
/// `GET /api/userWallet/users/{userId}/blockRelation`.
class BlockRelation extends Equatable {
  final bool blockedByMe;
  final bool blockedByTarget;

  const BlockRelation({this.blockedByMe = false, this.blockedByTarget = false});

  static const none = BlockRelation();

  factory BlockRelation.fromJson(Map<String, dynamic> json) {
    final rawStatus =
        json['status'] ??
        json['blockStatus'] ??
        json['blockRelation'] ??
        json['relationStatus'] ??
        json['relation'];
    final numericStatus = asInt(rawStatus);
    final status = rawStatus?.toString().trim().toUpperCase();

    final blockedByMe =
        asBool(
          json['blockedByMe'] ??
              json['isBlockedByMe'] ??
              json['hasBlocked'] ??
              json['isBlocked'] ??
              json['blocked'],
        ) ??
        (numericStatus == 1 ||
            numericStatus == 3 ||
            const {
              'BLOCKED',
              'BLOCKING',
              'BLOCKED_BY_ME',
              'I_BLOCKED',
              'MUTUAL_BLOCK',
              'MUTUAL_BLOCKED',
            }.contains(status));
    final blockedByTarget =
        asBool(
          json['blockedByTarget'] ??
              json['isBlockedByTarget'] ??
              json['blockedByOther'] ??
              json['isBlockedByOther'] ??
              json['blockedMe'] ??
              json['hasBlockedMe'] ??
              json['beBlocked'] ??
              json['isBeBlocked'],
        ) ??
        (numericStatus == 2 ||
            numericStatus == 3 ||
            const {
              'BLOCKED_BY',
              'BLOCKED_ME',
              'BLOCKED_BY_TARGET',
              'BLOCKED_BY_OTHER',
              'THEY_BLOCKED',
              'BE_BLOCKED',
              'MUTUAL_BLOCK',
              'MUTUAL_BLOCKED',
            }.contains(status));

    return BlockRelation(
      blockedByMe: blockedByMe,
      blockedByTarget: blockedByTarget,
    );
  }

  bool get isBlocked => blockedByMe || blockedByTarget;

  BlockRelation copyWith({bool? blockedByMe, bool? blockedByTarget}) {
    return BlockRelation(
      blockedByMe: blockedByMe ?? this.blockedByMe,
      blockedByTarget: blockedByTarget ?? this.blockedByTarget,
    );
  }

  @override
  List<Object?> get props => [blockedByMe, blockedByTarget];
}

class FollowStats extends Equatable {
  final String followingCount;
  final String followerCount;
  final String mutualCount;

  const FollowStats({
    this.followingCount = '0',
    this.followerCount = '0',
    this.mutualCount = '0',
  });

  factory FollowStats.fromJson(Map<String, dynamic> json) {
    return FollowStats(
      followingCount: asString(json['followingCount']) ?? '0',
      followerCount: asString(json['followerCount']) ?? '0',
      mutualCount: asString(json['mutualCount']) ?? '0',
    );
  }

  @override
  List<Object?> get props => [followingCount, followerCount, mutualCount];
}

class FollowListItem extends Equatable {
  final String userId;
  final String? nickname;
  final String? avatarUrl;

  /// User intro; API field `profile`.
  final String? bio;
  final String? status;
  final FollowRelationStatus relationStatus;

  const FollowListItem({
    required this.userId,
    this.nickname,
    this.avatarUrl,
    this.bio,
    this.status,
    this.relationStatus = FollowRelationStatus.none,
  });

  factory FollowListItem.fromJson(Map<String, dynamic> json) {
    return FollowListItem(
      userId: asString(json['userId']) ?? '',
      nickname: asString(json['nickname']),
      avatarUrl: asString(json['avatarUrl']),
      bio: asString(json['profile']),
      status: asString(json['status']),
      relationStatus: FollowRelationStatus.fromApi(
        asString(json['relationStatus']),
      ),
    );
  }

  FollowListItem copyWith({FollowRelationStatus? relationStatus}) {
    return FollowListItem(
      userId: userId,
      nickname: nickname,
      avatarUrl: avatarUrl,
      bio: bio,
      status: status,
      relationStatus: relationStatus ?? this.relationStatus,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    nickname,
    avatarUrl,
    bio,
    status,
    relationStatus,
  ];
}
