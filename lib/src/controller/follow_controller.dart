import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/request_coalescer.dart';
import '../core/request_keys.dart';
import '../core/result.dart';
import '../core/story_constants.dart';
import '../provider/app_providers.dart';
import 'follow_state.dart';
import 'follow_status_store.dart';

/// Per-creator follow store. Recommend seeds this from `followedByMe`;
/// drama player falls back to a single relation GET when the flag is unknown.
class FollowController extends Notifier<FollowState> {
  FollowController(this._userId);

  final String _userId;
  late RequestCoalescer _coalescer;

  @override
  FollowState build() {
    _coalescer = ref.read(requestCoalescerProvider);
    final link = ref.keepAlive();
    Timer? timer;
    ref.onCancel(() {
      timer?.cancel();
      timer = Timer(StoryConstants.engagementStoreRetention, link.close);
    });
    ref.onResume(() => timer?.cancel());
    ref.onDispose(() {
      timer?.cancel();
    });

    final loggedIn = ref.watch(
      authControllerProvider.select((s) => s.isLoggedIn),
    );
    ref.listen(followStatusStoreProvider, (prev, next) {
      if (!ref.mounted || state.isMutating) return;
      if (next.knows(_userId)) {
        final following = next.isFollowing(_userId);
        if (state.isFollowing != following) {
          state = state.copyWith(isFollowing: following);
        }
        return;
      }
      if (next.failed && state.isFollowing == null) {
        unawaited(refresh());
      }
    });

    if (loggedIn && _userId.isNotEmpty) {
      Future<void>.microtask(() {
        if (!ref.mounted) return;
        unawaited(ensureLoaded());
      });
    }

    if (loggedIn) {
      final store = ref.read(followStatusStoreProvider);
      if (store.knows(_userId)) {
        return FollowState(isFollowing: store.isFollowing(_userId));
      }
    }
    return const FollowState();
  }

  /// Loads relation if still unknown. Safe to await from a tap handler.
  Future<void> ensureLoaded() async {
    if (state.isFollowing != null) return;
    if (!ref.read(authControllerProvider).isLoggedIn) return;
    final snapshot = ref.read(followStatusStoreProvider);
    if (snapshot.knows(_userId)) {
      state = state.copyWith(isFollowing: snapshot.isFollowing(_userId));
      return;
    }
    await refresh();
  }

  Future<void> refresh() {
    return _coalescer.run(
      RequestKeys.followRelation(_userId),
      _refresh,
    );
  }

  Future<void> _refresh() async {
    if (_userId.isEmpty) return;
    final result = await ref
        .read(userRepositoryProvider)
        .getFollowRelation(_userId);
    if (!ref.mounted) return;
    if (state.isMutating) return;
    state = state.copyWith(
      isFollowing: result.isSuccess
          ? result.dataOrNull!.isFollowing
          : (state.isFollowing ?? false),
    );
  }

  /// Optimistically follows or unfollows. Returns null when a toggle is
  /// already in flight.
  Future<Result<void>?> toggle() async {
    if (state.isMutating || _userId.isEmpty) return null;
    final previous = state;
    final next = !(state.isFollowing ?? false);
    state = state.copyWith(isFollowing: next, isMutating: true);
    ref.read(followStatusStoreProvider.notifier).setFollowing(_userId, next);

    final repo = ref.read(userRepositoryProvider);
    final result = next
        ? await repo.followUser(_userId)
        : await repo.unfollowUser(_userId);
    if (!ref.mounted) return result;

    if (result.isFailure) {
      ref
          .read(followStatusStoreProvider.notifier)
          .setFollowing(_userId, previous.isFollowing ?? false);
      state = previous.copyWith(isMutating: false);
      return result;
    }
    state = state.copyWith(isFollowing: next, isMutating: false);
    return result;
  }
}
