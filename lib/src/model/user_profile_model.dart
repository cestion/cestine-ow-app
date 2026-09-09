import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'follow_models.dart';
import 'json_converters.dart';

part 'user_profile_model.g.dart';

FollowStats? _followStatsFromJson(Object? value) {
  if (value is Map<String, dynamic>) return FollowStats.fromJson(value);
  if (value is Map) {
    return FollowStats.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

FollowRelationStatus? _relationStatusFromJson(Object? value) {
  if (value == null) return null;
  return FollowRelationStatus.fromApi(value.toString());
}

String? _relationStatusToJson(FollowRelationStatus? value) => value?.apiValue;

Object? _firstValue(Map<dynamic, dynamic> json, Iterable<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) return json[key];
  }
  return null;
}

Object? _blockedByMeValue(Map<dynamic, dynamic> json, String _) {
  final direct = _firstValue(json, const [
    'blockedByMe',
    'isBlockedByMe',
    'hasBlocked',
    'isBlocked',
    'blocked',
    'isBlock',
    'blacklisted',
    'isBlacklisted',
  ]);
  if (direct != null) return direct;

  final status = _firstValue(json, const [
    'blockStatus',
    'blackStatus',
    'relationStatus',
  ]);
  if (status is num) return status == 1 || status == 3;
  final normalized = status?.toString().trim().toUpperCase();
  return const {
    'BLOCKED',
    'BLOCKING',
    'BLOCKED_BY_ME',
    'I_BLOCKED',
    'BLACKLISTED',
    'MUTUAL_BLOCK',
    'MUTUAL_BLOCKED',
  }.contains(normalized);
}

Object? _blockedByTargetValue(Map<dynamic, dynamic> json, String _) {
  final direct = _firstValue(json, const [
    'blockedMe',
    'hasBlockedMe',
    'blockedByTarget',
    'isBlockedByTarget',
    'blockedByOther',
    'isBlockedByOther',
    'beBlocked',
    'isBeBlocked',
  ]);
  if (direct != null) return direct;

  final status = _firstValue(json, const [
    'blockStatus',
    'blackStatus',
    'relationStatus',
  ]);
  if (status is num) return status == 2 || status == 3;
  final normalized = status?.toString().trim().toUpperCase();
  return const {
    'BLOCKED_BY',
    'BLOCKED_ME',
    'BLOCKED_BY_TARGET',
    'BLOCKED_BY_OTHER',
    'THEY_BLOCKED',
    'MUTUAL_BLOCK',
    'MUTUAL_BLOCKED',
  }.contains(normalized);
}

bool _boolFromJson(Object? value) => asBool(value) ?? false;

@JsonSerializable()
class UserProfile extends Equatable {
  @JsonKey(fromJson: asString)
  final String? id;
  @JsonKey(fromJson: asString)
  final String? userId;
  final String? nickname;
  final String? avatarUrl;

  /// User intro / bio. Serialized as `profile` in userWallet APIs.
  @JsonKey(name: 'profile')
  final String? bio;
  final String? email;
  final String? walletAddress;
  final String? loginType;
  final String? inviteCode;

  /// Inviter user id from `userWallet/userInfo`. Empty when unbound.
  final String? inviterUserId;

  /// Whether the user skipped the invite-code bind prompt (`"0"` / `"1"`).
  @JsonKey(fromJson: asString)
  final String? skipInviteCode;
  @JsonKey(fromJson: asDouble)
  final double? trust;
  @JsonKey(fromJson: asInt)
  final int? createdAt;
  @JsonKey(fromJson: asInt)
  final int? updatedAt;

  /// Soft-delete flag from userWallet APIs: `"0"` not deleted, `"1"` deleted.
  @JsonKey(fromJson: asString)
  final String? isDeleted;

  /// Present on `otherUserInfo` when follow feature is enabled.
  @JsonKey(fromJson: _followStatsFromJson, includeToJson: false)
  final FollowStats? followStats;

  /// Viewer → this user relation from `otherUserInfo`.
  @JsonKey(
    fromJson: _relationStatusFromJson,
    toJson: _relationStatusToJson,
    includeToJson: false,
  )
  final FollowRelationStatus? relationStatus;

  /// Whether the signed-in viewer has blocked this profile.
  ///
  /// `readValue` accepts the field aliases used by current and legacy wallet
  /// services, while keeping the rest of the app on one stable model shape.
  @JsonKey(
    readValue: _blockedByMeValue,
    fromJson: _boolFromJson,
    includeToJson: false,
  )
  final bool blockedByMe;

  /// Whether this profile has blocked the signed-in viewer.
  @JsonKey(
    readValue: _blockedByTargetValue,
    fromJson: _boolFromJson,
    includeToJson: false,
  )
  final bool blockedByTarget;

  const UserProfile({
    this.id,
    this.userId,
    this.nickname,
    this.avatarUrl,
    this.bio,
    this.email,
    this.walletAddress,
    this.loginType,
    this.inviteCode,
    this.inviterUserId,
    this.skipInviteCode,
    this.trust,
    this.createdAt,
    this.updatedAt,
    this.isDeleted,
    this.followStats,
    this.relationStatus,
    this.blockedByMe = false,
    this.blockedByTarget = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? nickname,
    String? avatarUrl,
    String? bio,
    String? isDeleted,
    String? skipInviteCode,
    FollowStats? followStats,
    FollowRelationStatus? relationStatus,
    bool? blockedByMe,
    bool? blockedByTarget,
  }) {
    return UserProfile(
      id: id,
      userId: userId,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      email: email,
      walletAddress: walletAddress,
      loginType: loginType,
      inviteCode: inviteCode,
      inviterUserId: inviterUserId,
      skipInviteCode: skipInviteCode ?? this.skipInviteCode,
      trust: trust,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      followStats: followStats ?? this.followStats,
      relationStatus: relationStatus ?? this.relationStatus,
      blockedByMe: blockedByMe ?? this.blockedByMe,
      blockedByTarget: blockedByTarget ?? this.blockedByTarget,
    );
  }

  /// Aligned with web: a logged-in account is risky when its finite trust
  /// coefficient is below 1. Missing or invalid values are not treated as
  /// risky by the client.
  bool get isRiskAccount => trust != null && trust!.isFinite && trust! < 1;

  /// Whether the account is marked deleted (`isDeleted == "1"`).
  bool get isAccountDeleted => isDeleted == '1';

  /// Whether the current user has bound someone else's invite code.
  bool get hasBoundInviter =>
      inviterUserId != null && inviterUserId!.trim().isNotEmpty;

  /// Whether the user skipped binding an invite code (`skipInviteCode == "1"`).
  bool get hasSkippedInviteCode => skipInviteCode == '1';

  /// Content is private in either direction: I blocked them or they blocked me.
  bool get hasBlockedRelationship => blockedByMe || blockedByTarget;

  @override
  List<Object?> get props => [
    id,
    userId,
    nickname,
    avatarUrl,
    bio,
    email,
    walletAddress,
    loginType,
    inviteCode,
    inviterUserId,
    skipInviteCode,
    trust,
    createdAt,
    updatedAt,
    isDeleted,
    followStats,
    relationStatus,
    blockedByMe,
    blockedByTarget,
  ];
}
