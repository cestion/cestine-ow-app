import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/request_coalescer.dart';
import '../core/request_keys.dart';
import '../core/story_constants.dart';
import '../provider/app_providers.dart';

/// Session-scoped following cache for the current login user.
///
/// Recommend cards carry [RecommendFeedItem.followedByMe], so the player
/// rail seeds this store instead of paging `GET .../followings`. Unknown
/// creators (drama player) still fall back to a single relation GET.
class FollowStatusState extends Equatable {
  final bool loaded;
  final bool failed;
  final Set<String> followingIds;

  /// Creators whose follow flag is known (followed or not). Distinct from
  /// [followingIds] so a `followedByMe: false` seed is not treated as unknown.
  final Set<String> knownIds;

  const FollowStatusState({
    this.loaded = false,
    this.failed = false,
    this.followingIds = const {},
    this.knownIds = const {},
  });

  bool knows(String userId) => loaded || knownIds.contains(userId);

  bool isFollowing(String userId) => followingIds.contains(userId);

  FollowStatusState copyWith({
    bool? loaded,
    bool? failed,
    Set<String>? followingIds,
    Set<String>? knownIds,
  }) {
    return FollowStatusState(
      loaded: loaded ?? this.loaded,
      failed: failed ?? this.failed,
      followingIds: followingIds ?? this.followingIds,
      knownIds: knownIds ?? this.knownIds,
    );
  }

  @override
  List<Object?> get props => [loaded, failed, followingIds, knownIds];
}

class FollowStatusStore extends Notifier<FollowStatusState> {
  late RequestCoalescer _coalescer;

  @override
  FollowStatusState build() {
    _coalescer = ref.read(requestCoalescerProvider);
    ref.listen<String?>(authControllerProvider.select((s) => s.userId), (
      prev,
      next,
    ) {
      if ((prev ?? '') == (next ?? '')) return;
      _coalescer.invalidate(RequestKeys.followingsHydrate);
      state = const FollowStatusState();
    });
    return const FollowStatusState();
  }

  /// Writes [following] only when this creator is not already known, so a
  /// later feed refresh cannot clobber an in-session follow/unfollow.
  void seedIfUnknown(String userId, bool following) {
    final id = userId.trim();
    if (id.isEmpty) return;
    if (state.knows(id)) return;
    setFollowing(id, following);
  }

  Future<void> ensureLoaded() {
    return _coalescer.run(RequestKeys.followingsHydrate, _hydrate);
  }

  Future<void> _hydrate() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn || auth.isLoggingOut) return;
    final userId = auth.userId?.trim();
    if (userId == null || userId.isEmpty) return;

    final repo = ref.read(followRepositoryProvider);
    final ids = <String>{...state.followingIds};
    String? mark;
    var failed = false;

    for (
      var page = 0;
      page < StoryConstants.followingsHydrateMaxPages;
      page++
    ) {
      if (!_isHydrateSessionActive(userId)) return;
      final result = await repo.listFollowings(
        userId: userId,
        mark: mark,
        pageSize: StoryConstants.followingsHydratePageSize,
      );
      if (!_isHydrateSessionActive(userId)) return;
      if (result.isFailure) {
        failed = true;
        break;
      }
      final data = result.dataOrNull;
      final list = data?.list ?? const [];
      for (final item in list) {
        final id = item.userId.trim();
        if (id.isNotEmpty) ids.add(id);
      }
      if (data?.hasMore != true) {
        failed = false;
        break;
      }
      final nextMark = data?.mark?.trim();
      if (nextMark == null || nextMark.isEmpty) break;
      mark = nextMark;
    }

    if (!_isHydrateSessionActive(userId)) return;
    if (failed && !state.loaded) {
      state = state.copyWith(failed: true, loaded: false);
      return;
    }
    state = FollowStatusState(
      loaded: true,
      followingIds: ids,
      knownIds: {...state.knownIds, ...ids},
    );
  }

  /// Drops stale hydrate completions after logout / account switch.
  bool _isHydrateSessionActive(String expectedUserId) {
    if (!ref.mounted) return false;
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn || auth.isLoggingOut) return false;
    return (auth.userId?.trim() ?? '') == expectedUserId;
  }

  void setFollowing(String userId, bool following) {
    final id = userId.trim();
    if (id.isEmpty) return;
    final has = state.followingIds.contains(id);
    final known = state.knownIds.contains(id);
    if (following == has && known) return;
    final next = {...state.followingIds};
    if (following) {
      next.add(id);
    } else {
      next.remove(id);
    }
    state = state.copyWith(
      followingIds: next,
      knownIds: {...state.knownIds, id},
    );
  }
}

final followStatusStoreProvider =
    NotifierProvider<FollowStatusStore, FollowStatusState>(
      FollowStatusStore.new,
    );
