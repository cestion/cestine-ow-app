import 'package:equatable/equatable.dart';

/// `GET /api/userWallet/inviteInfo` response.
class InviteInfoSummary extends Equatable {
  final String? userId;
  final String? inviteCode;
  final String? inviterUserId;
  final String? bindAt;
  final int totalInviteCount;
  final int validUserCount;

  const InviteInfoSummary({
    this.userId,
    this.inviteCode,
    this.inviterUserId,
    this.bindAt,
    this.totalInviteCount = 0,
    this.validUserCount = 0,
  });

  /// Whether the current user has bound someone else's invite code.
  bool get hasBoundInviter =>
      inviterUserId != null && inviterUserId!.trim().isNotEmpty;

  factory InviteInfoSummary.fromJson(Map<String, dynamic> json) {
    return InviteInfoSummary(
      userId: json['userId']?.toString(),
      inviteCode: json['inviteCode']?.toString(),
      inviterUserId: json['inviterUserId']?.toString(),
      bindAt: json['bindAt']?.toString(),
      totalInviteCount:
          int.tryParse(json['totalInviteCount']?.toString() ?? '') ?? 0,
      validUserCount:
          int.tryParse(json['validUserCount']?.toString() ?? '') ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    inviteCode,
    inviterUserId,
    bindAt,
    totalInviteCount,
    validUserCount,
  ];
}
