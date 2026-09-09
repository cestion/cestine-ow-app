import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/story_logger.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/user_repository.dart';
import 'invite_state.dart';

/// Income fields consumed by [InviteController]; one `.select` subscription.
typedef InviteIncomeSlice = ({
  bool isLoading,
  double? totalInviteReward,
  List<RewardDetail>? rewardDetails,
  double weeklyPool,
});

/// Reward-detail rows used to derive invitee subordinates in the invite sheet.
typedef InviteRewardDerived = ({
  int inviteeCount,
  List<SubordinateUser> subordinates,
});

InviteRewardDerived deriveInviteRewardData(List<RewardDetail>? rewardDetails) {
  final rows = rewardDetails ?? const <RewardDetail>[];
  final inviteRows = rows.where((r) => r.type == RewardDetailType.invite);

  final inviteeCount = inviteRows
      .map((r) => r.sourceUser ?? r.sourceUserName ?? '')
      .where((s) => s.isNotEmpty)
      .toSet()
      .length;

  final subordinates = inviteRows
      .fold<Map<String, SubordinateUser>>({}, (map, r) {
        final uid = r.sourceUser ?? '';
        if (uid.isNotEmpty) {
          map[uid] = SubordinateUser(
            name: r.sourceUserName ?? uid,
            registerDate: (r.rewardTime != null && r.rewardTime!.length >= 10)
                ? r.rewardTime!.substring(0, 10)
                : '2026-06-06',
            isActive: true,
          );
        }
        return map;
      })
      .values
      .toList(growable: false);

  return (inviteeCount: inviteeCount, subordinates: subordinates);
}

class InviteController extends Notifier<InviteState> {
  late UserRepository _user;

  // API-fetched data lives on the controller instance so they survive
  // build() re-runs triggered by watched provider changes.
  List<SubordinateUser> _cachedInvitees = const [];
  String? _cachedInviteeMark;
  bool _cachedInviteeHasMore = false;
  int? _cachedTotalCount;
  String? _cachedInviterUserId;

  @override
  InviteState build() {
    _user = ref.read(userRepositoryProvider);

    final profile = ref.watch(authControllerProvider.select((s) => s.profile));
    final income = ref.watch(
      incomeControllerProvider.select(
        (s) => (
          isLoading: s.isLoading,
          totalInviteReward: s.totalReward?.totalInviteReward,
          rewardDetails: s.rewardDetailPage?.list,
          weeklyPool: s.weeklyStats?.weekInvitePool ?? 0.0,
        ),
      ),
    );
    final webBaseUrl = ref.watch(
      storySdkConfigProvider.select((c) => c.env.webBaseUrl),
    );

    final inviteLink = _buildInviteLink(profile: profile, webBaseUrl: webBaseUrl);
    final inviteCode = _inviteCodeFromProfile(profile);
    final derived = deriveInviteRewardData(income.rewardDetails);

    return InviteState(
      isLoading: income.isLoading,
      totalInviteReward: income.totalInviteReward ?? 0.0,
      totalInviteCount: _cachedTotalCount ?? derived.inviteeCount,
      weeklyPool: income.weeklyPool,
      inviteCode: inviteCode,
      inviteLink: inviteLink,
      inviterUserId: _cachedInviterUserId,
      subordinates: derived.subordinates,
      invitees: _cachedInvitees,
      inviteeMark: _cachedInviteeMark,
      inviteeHasMore: _cachedInviteeHasMore,
    );
  }

  String _inviteCodeFromProfile(UserProfile? profile) {
    if (profile == null) return '';

    final backendCode = profile.inviteCode;
    if (backendCode != null && backendCode.isNotEmpty) {
      return backendCode;
    }

    final userId = profile.userId ?? profile.id ?? '';
    if (userId.isEmpty) return '';

    return userId.length > 8
        ? userId.substring(userId.length - 8).toUpperCase()
        : userId.toUpperCase();
  }

  String _buildInviteLink({
    required UserProfile? profile,
    required String webBaseUrl,
  }) {
    final code = _inviteCodeFromProfile(profile);
    return code.isEmpty ? '' : '$webBaseUrl?code=$code';
  }

  /// Fetch invite summary from `GET /api/userWallet/inviteInfo`.
  Future<void> fetchInviteInfo() async {
    final result = await _user.getInviteSummary();
    if (!ref.mounted) return;
    result.when(
      success: (summary) {
        _cachedTotalCount = summary.totalInviteCount;
        _cachedInviterUserId = summary.inviterUserId;
        state = state.copyWith(
          totalInviteCount: summary.totalInviteCount,
          inviterUserId: summary.inviterUserId,
        );
      },
      failure: (e) {
        StoryLogger.w('fetchInviteInfo failed', error: e, tag: 'Invite');
      },
    );
  }

  /// Fetch the first page of invitees from the API.
  Future<void> fetchInvitees() async {
    state = state.copyWith(isLoadingInvitees: true);
    final result = await _user.getInviteRecords();
    if (!ref.mounted) return;
    result.when(
      success: (page) {
        _cachedInvitees = page.list ?? [];
        _cachedInviteeMark = page.mark;
        _cachedInviteeHasMore = page.hasMore ?? false;
        state = state.copyWith(
          invitees: _cachedInvitees,
          inviteeMark: _cachedInviteeMark,
          inviteeHasMore: _cachedInviteeHasMore,
          isLoadingInvitees: false,
        );
      },
      failure: (e) {
        StoryLogger.w('fetchInvitees failed', error: e, tag: 'Invite');
        state = state.copyWith(isLoadingInvitees: false);
      },
    );
  }

  /// Append the next page of invitees (triggered by scrolling in the sheet).
  Future<void> loadMoreInvitees() async {
    if (state.isLoadingInvitees || !state.inviteeHasMore) return;
    state = state.copyWith(isLoadingInvitees: true);
    final result = await _user.getInviteRecords(mark: state.inviteeMark);
    if (!ref.mounted) return;
    result.when(
      success: (page) {
        _cachedInvitees = [..._cachedInvitees, ...(page.list ?? [])];
        _cachedInviteeMark = page.mark;
        _cachedInviteeHasMore = page.hasMore ?? false;
        state = state.copyWith(
          invitees: _cachedInvitees,
          inviteeMark: _cachedInviteeMark,
          inviteeHasMore: _cachedInviteeHasMore,
          isLoadingInvitees: false,
        );
      },
      failure: (e) {
        StoryLogger.w('loadMoreInvitees failed', error: e, tag: 'Invite');
        state = state.copyWith(isLoadingInvitees: false);
      },
    );
  }
}
