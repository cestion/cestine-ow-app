import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_constants.dart';
import '../model/follow_models.dart';
import '../provider/auth_providers.dart';
import '../provider/repository_providers.dart';
import '../repositories/follow_repository.dart';
import 'follow_list_controller.dart';
import 'follow_list_state.dart';
import 'follow_status_store.dart';

class FollowActionState extends Equatable {
  final Set<String> pendingUserIds;
  final ApiError? lastError;

  const FollowActionState({this.pendingUserIds = const {}, this.lastError});

  bool isPending(String userId) => pendingUserIds.contains(userId);

  FollowActionState copyWith({
    Set<String>? pendingUserIds,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return FollowActionState(
      pendingUserIds: pendingUserIds ?? this.pendingUserIds,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  List<Object?> get props => [pendingUserIds, lastError];
}

/// Follow and block mutations with one per-user pending guard. Follow-list
/// optimistic updates live in [FollowRelationActions].
class FollowActionController extends Notifier<FollowActionState> {
  late FollowRepository _repo;

  @override
  FollowActionState build() {
    _repo = ref.read(followRepositoryProvider);
    return const FollowActionState();
  }

  Future<Result<void>> follow(String targetUserId) async {
    if (state.isPending(targetUserId)) {
      return Result.failure(ApiError.unknown('Follow already in progress'));
    }
    // 黑名单预检：与对方存在拉黑关系时禁止关注，命中则拦截提示
    // （覆盖搜索/通知/关注列表等所有关注入口）。
    final relation = await ref
        .read(followRepositoryProvider)
        .getBlockRelation(targetUserId);
    if (ref.mounted && relation.isSuccess) {
      final block = relation.dataOrNull;
      if (block != null) {
        if (block.blockedByMe) {
          return Result.failure(
            ApiError.business(0, FollowBlockErrorMessages.blockedByMe),
          );
        }
        if (block.blockedByTarget) {
          return Result.failure(
            ApiError.business(0, FollowBlockErrorMessages.blockedByTarget),
          );
        }
      }
    }
    _setPending(targetUserId, true);
    final result = await _repo.follow(targetUserId);
    if (!ref.mounted) return result;
    if (result.isSuccess) {
      ref
          .read(followStatusStoreProvider.notifier)
          .setFollowing(targetUserId, true);
    }
    _setPending(targetUserId, false, error: result.errorOrNull);
    return result;
  }

  Future<Result<void>> unfollow(String targetUserId) async {
    if (state.isPending(targetUserId)) {
      return Result.failure(ApiError.unknown('Unfollow already in progress'));
    }
    _setPending(targetUserId, true);
    final result = await _repo.unfollow(targetUserId);
    if (!ref.mounted) return result;
    if (result.isSuccess) {
      ref
          .read(followStatusStoreProvider.notifier)
          .setFollowing(targetUserId, false);
    }
    _setPending(targetUserId, false, error: result.errorOrNull);
    return result;
  }

  Future<Result<void>> block(String targetUserId) async {
    if (state.isPending(targetUserId)) {
      return Result.failure(ApiError.unknown('Block already in progress'));
    }
    _setPending(targetUserId, true);
    final result = await _repo.block(targetUserId);
    if (!ref.mounted) return result;
    if (result.isSuccess) {
      // 双向自动取关：拉黑成功后本地立即清除关注状态、关注列表中的
      // 该用户，并刷新关系与统计，避免界面残留「已关注」。
      _applyAutoUnfollow(targetUserId);
    }
    _setPending(targetUserId, false, error: result.errorOrNull);
    return result;
  }

  /// 双向自动取关的本地副作用：拉黑后清除 [targetUserId] 的关注状态与
  /// 关注/粉丝/互关列表中的该用户，并刷新关系与统计缓存。
  void _applyAutoUnfollow(String targetUserId) {
    ref
        .read(followStatusStoreProvider.notifier)
        .setFollowing(targetUserId, false);
    ref.invalidate(followRelationProvider(targetUserId));
    final viewerId = ref.read(authControllerProvider).userId?.trim();
    if (viewerId == null || viewerId.isEmpty) return;
    for (final type in FollowListType.values) {
      final provider = followListControllerProvider(
        FollowListParam(userId: viewerId, type: type),
      );
      if (ref.exists(provider)) {
        ref.read(provider.notifier).removeUser(targetUserId);
      }
    }
    ref.invalidate(followStatsProvider(viewerId));
  }

  Future<Result<void>> unblock(String targetUserId) async {
    if (state.isPending(targetUserId)) {
      return Result.failure(ApiError.unknown('Unblock already in progress'));
    }
    _setPending(targetUserId, true);
    final result = await _repo.unblock(targetUserId);
    if (!ref.mounted) return result;
    _setPending(targetUserId, false, error: result.errorOrNull);
    return result;
  }

  Future<Result<void>> removeFollower(String followerId) async {
    if (state.isPending(followerId)) {
      return Result.failure(
        ApiError.unknown('Remove follower already in progress'),
      );
    }
    _setPending(followerId, true);
    final result = await _repo.removeFollower(followerId);
    if (!ref.mounted) return result;
    _setPending(followerId, false, error: result.errorOrNull);
    return result;
  }

  void _setPending(String userId, bool pending, {ApiError? error}) {
    final next = {...state.pendingUserIds};
    if (pending) {
      next.add(userId);
    } else {
      next.remove(userId);
    }
    state = state.copyWith(
      pendingUserIds: next,
      lastError: error,
      clearLastError: error == null,
    );
  }

  /// Manually hold the pending flag for [userId] across a multi-step flow
  /// (e.g. follow → refresh relation from `otherUserInfo`). Pairs with
  /// [releasePending]. Use when a single user action triggers several
  /// sequential API calls and the button spinner should cover them all.
  void holdPending(String userId) {
    if (state.isPending(userId)) return;
    final next = {...state.pendingUserIds}..add(userId);
    state = state.copyWith(pendingUserIds: next);
  }

  /// Release a pending flag previously held by [holdPending].
  void releasePending(String userId) {
    if (!state.isPending(userId)) return;
    final next = {...state.pendingUserIds}..remove(userId);
    state = state.copyWith(pendingUserIds: next, clearLastError: true);
  }
}

final followActionControllerProvider =
    NotifierProvider.autoDispose<FollowActionController, FollowActionState>(
      FollowActionController.new,
    );

final followStatsProvider = FutureProvider.autoDispose
    .family<FollowStats, String>((ref, userId) async {
      final result = await ref.read(followRepositoryProvider).getStats(userId);
      return result.dataOrNull ?? const FollowStats();
    });

final followRelationProvider = FutureProvider.autoDispose
    .family<FollowRelationStatus, String>((ref, userId) async {
      final result = await ref
          .read(followRepositoryProvider)
          .getRelation(userId);
      return result.dataOrNull ?? FollowRelationStatus.none;
    });

final blockRelationProvider = FutureProvider.autoDispose
    .family<Result<BlockRelation>, String>((ref, userId) {
      return ref.read(followRepositoryProvider).getBlockRelation(userId);
    });

/// Optimistic list patches + stats invalidation shared by relation UI.
class FollowRelationActions {
  FollowRelationActions._();

  static FollowRelationStatus nextAfterFollow(FollowRelationStatus current) {
    return current == FollowRelationStatus.followBack
        ? FollowRelationStatus.mutual
        : FollowRelationStatus.following;
  }

  static FollowRelationStatus nextAfterUnfollow(FollowRelationStatus current) {
    return current == FollowRelationStatus.mutual
        ? FollowRelationStatus.followBack
        : FollowRelationStatus.none;
  }

  static void patchAll(
    WidgetRef ref, {
    required String ownerUserId,
    required String targetUserId,
    required FollowRelationStatus status,
  }) {
    for (final type in FollowListType.values) {
      final provider = followListControllerProvider(
        FollowListParam(userId: ownerUserId, type: type),
      );
      if (!ref.exists(provider)) continue;
      ref.read(provider.notifier).patchRelation(targetUserId, status);
    }
  }

  /// Optimistic unfollow: keep the row on the Following tab (status only) so
  /// the user can re-follow in the same visit; drop from Mutuals immediately.
  /// Following list rows are pruned on next page enter (autoDispose refresh).
  static void applyUnfollowOptimistic(
    WidgetRef ref, {
    required String ownerUserId,
    required String targetUserId,
    required FollowRelationStatus next,
  }) {
    final following = followListControllerProvider(
      FollowListParam(userId: ownerUserId, type: FollowListType.following),
    );
    final mutuals = followListControllerProvider(
      FollowListParam(userId: ownerUserId, type: FollowListType.mutuals),
    );
    final followers = followListControllerProvider(
      FollowListParam(userId: ownerUserId, type: FollowListType.followers),
    );
    if (ref.exists(following)) {
      ref.read(following.notifier).patchRelation(targetUserId, next);
    }
    if (ref.exists(mutuals)) {
      ref.read(mutuals.notifier).removeUser(targetUserId);
    }
    if (ref.exists(followers)) {
      ref.read(followers.notifier).patchRelation(targetUserId, next);
    }
  }

  /// Drop a fan from the owner's followers / mutuals lists after remove.
  static void applyRemoveFollowerOptimistic(
    WidgetRef ref, {
    required String ownerUserId,
    required String followerId,
  }) {
    final followers = followListControllerProvider(
      FollowListParam(userId: ownerUserId, type: FollowListType.followers),
    );
    final mutuals = followListControllerProvider(
      FollowListParam(userId: ownerUserId, type: FollowListType.mutuals),
    );
    if (ref.exists(followers)) {
      ref.read(followers.notifier).removeUser(followerId);
    }
    if (ref.exists(mutuals)) {
      ref.read(mutuals.notifier).removeUser(followerId);
    }
  }

  static void invalidateStats(WidgetRef ref, String ownerUserId) {
    ref.invalidate(followStatsProvider(ownerUserId));
  }

  /// Drop follow list / stats / relation providers after login or logout so a
  /// new session cannot reuse the previous account's in-memory family state.
  static void clearSessionCaches(ProviderContainer container) {
    container.invalidate(followListControllerProvider);
    container.invalidate(followStatsProvider);
    container.invalidate(followRelationProvider);
    container.invalidate(followActionControllerProvider);
    container.invalidate(followStatusStoreProvider);
  }
}
