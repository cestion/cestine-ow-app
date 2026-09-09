import 'package:equatable/equatable.dart';

import '../model/subordinate_user_model.dart';

export '../model/subordinate_user_model.dart' show SubordinateUser;

class InviteState extends Equatable {
  final bool isLoading;
  final double totalInviteReward;
  final int totalInviteCount;
  final double weeklyPool;
  final String inviteLink;
  final String inviteCode;
  final String? inviterUserId;
  final List<SubordinateUser> subordinates;
  final List<SubordinateUser> invitees;
  final String? inviteeMark;
  final bool inviteeHasMore;
  final bool isLoadingInvitees;

  const InviteState({
    this.isLoading = false,
    this.totalInviteReward = 0.0,
    this.totalInviteCount = 0,
    this.weeklyPool = 0.0,
    this.inviteLink = '',
    this.inviteCode = '',
    this.inviterUserId,
    this.subordinates = const [],
    this.invitees = const [],
    this.inviteeMark,
    this.inviteeHasMore = false,
    this.isLoadingInvitees = false,
  });

  InviteState copyWith({
    bool? isLoading,
    double? totalInviteReward,
    int? totalInviteCount,
    double? weeklyPool,
    String? inviteLink,
    String? inviteCode,
    String? inviterUserId,
    List<SubordinateUser>? subordinates,
    List<SubordinateUser>? invitees,
    String? inviteeMark,
    bool? inviteeHasMore,
    bool? isLoadingInvitees,
    bool clearInviteeMark = false,
  }) {
    return InviteState(
      isLoading: isLoading ?? this.isLoading,
      totalInviteReward: totalInviteReward ?? this.totalInviteReward,
      totalInviteCount: totalInviteCount ?? this.totalInviteCount,
      weeklyPool: weeklyPool ?? this.weeklyPool,
      inviteLink: inviteLink ?? this.inviteLink,
      inviteCode: inviteCode ?? this.inviteCode,
      inviterUserId: inviterUserId ?? this.inviterUserId,
      subordinates: subordinates ?? this.subordinates,
      invitees: invitees ?? this.invitees,
      inviteeMark: clearInviteeMark ? null : (inviteeMark ?? this.inviteeMark),
      inviteeHasMore: inviteeHasMore ?? this.inviteeHasMore,
      isLoadingInvitees: isLoadingInvitees ?? this.isLoadingInvitees,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    totalInviteReward,
    totalInviteCount,
    weeklyPool,
    inviteLink,
    inviteCode,
    inviterUserId,
    subordinates,
    invitees,
    inviteeMark,
    inviteeHasMore,
    isLoadingInvitees,
  ];

  /// The list used for the bottom-sheet display (API data preferred, falls back
  /// to reward-derived subordinates).
  List<SubordinateUser> get displaySubordinates =>
      invitees.isNotEmpty ? invitees : subordinates;

  int get subordinateTotalCount => displaySubordinates.length;
  int get subordinateActiveCount =>
      displaySubordinates.where((s) => s.isActive).length;
  int get subordinatePendingCount =>
      displaySubordinates.where((s) => !s.isActive).length;

  /// `inviteInfo.inviterUserId` 非空表示已绑定他人邀请码。
  bool get hasBoundInviter =>
      inviterUserId != null && inviterUserId!.trim().isNotEmpty;
}
