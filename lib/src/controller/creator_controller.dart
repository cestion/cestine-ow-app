import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/actor_repository.dart';
import '../repositories/drama_repository.dart';
import '../repositories/user_repository.dart';
import 'creator_state.dart';
import 'story_controller_mixin.dart';

class CreatorController extends Notifier<CreatorState>
    with StoryControllerMixin<CreatorState> {
  DramaRepository get _drama => ref.read(dramaRepositoryProvider);
  ActorRepository get _actor => ref.read(actorRepositoryProvider);
  UserRepository get _user => ref.read(userRepositoryProvider);

  /// 铸造成功后的 NFT 数量保护下限。
  ///
  /// 链上成功后索引服务可能短暂返回旧数量；保护下限可避免后续刷新把已确认
  /// 的乐观 +1 回滚。Controller 在登出时重置，因此不会跨账号保留。
  int? _optimisticOwnedNftCountFloor;

  @override
  CreatorState build() {
    final authNotifier = ref.read(authControllerProvider.notifier);
    final authSub = authNotifier.authStateChanges.listen((loggedIn) {
      if (!loggedIn) {
        _optimisticOwnedNftCountFloor = null;
        state = state.copyWith(myActors: [], ownedNftCount: 0);
      }
    });
    ref.onDispose(authSub.cancel);
    return const CreatorState();
  }

  @override
  CreatorState copyWithLoadingState({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return state.copyWith(
      isLoading: isLoading,
      lastError: lastError,
      clearLastError: clearLastError,
    );
  }

  List<Actor> get myActors => state.myActors;
  bool get isLoading => state.isLoading;
  String get errorMessage => state.errorMessage;

  Future<void> load() async {
    if (!ref.read(authControllerProvider).isLoggedIn) return;

    final result = await withLoading(() async {
      final results = await Future.wait<Object>([
        _actor.listMyActors(),
        _drama.getOnlineDramaCount(),
        _user.getDramaNftCount(),
      ]);
      final a = results[0] as Result<PageDto<Actor>>;
      final c = results[1] as Result<int>;
      final n = results[2] as Result<int>;
      return {
        'actors': a.isSuccess ? (a.dataOrNull?.list ?? []) : state.myActors,
        'onlineCount': c.isSuccess
            ? (c.dataOrNull ?? 0)
            : state.onlineDramaCount,
        'nftCount': n.isSuccess
            ? _resolveOwnedNftCount(n.dataOrNull ?? state.ownedNftCount)
            : state.ownedNftCount,
      };
    });

    if (result.isSuccess && result.dataOrNull != null) {
      final data = result.dataOrNull!;
      state = state.copyWith(
        myActors: data['actors'] as List<Actor>,
        onlineDramaCount: data['onlineCount'] as int,
        ownedNftCount: data['nftCount'] as int,
      );
    }
  }

  /// Lightweight refresh of [CreatorState.ownedNftCount] only.
  ///
  /// Used after minting a drama NFT so the metric card reflects the new
  /// count without re-fetching actors/online-count or toggling the
  /// page-level [isLoading] spinner.
  ///
  /// When [optimisticIncrement] is true, the count is increased immediately.
  /// Eventually-consistent responses below that confirmed value are ignored.
  Future<void> refreshOwnedNftCount({bool optimisticIncrement = false}) async {
    if (!ref.read(authControllerProvider).isLoggedIn) return;

    if (optimisticIncrement) {
      final optimisticCount = state.ownedNftCount + 1;
      _optimisticOwnedNftCountFloor = optimisticCount;
      state = state.copyWith(ownedNftCount: optimisticCount);
    }

    final result = await _user.getDramaNftCount();
    if (!ref.mounted) return;
    final count = result.dataOrNull;
    if (result.isSuccess && count != null) {
      state = state.copyWith(ownedNftCount: _resolveOwnedNftCount(count));
    }
  }

  int _resolveOwnedNftCount(int serverCount) {
    final floor = _optimisticOwnedNftCountFloor;
    if (floor == null) return serverCount;

    final resolved = serverCount < floor ? floor : serverCount;
    _optimisticOwnedNftCountFloor = resolved;
    return resolved;
  }

  /// Lightweight refresh of [CreatorState.onlineDramaCount] only.
  ///
  /// Used after creating a new drama so the metric card reflects the new
  /// count without re-fetching actors/NFT positions or toggling the
  /// page-level [isLoading] spinner.
  Future<void> refreshOnlineDramaCount() async {
    if (!ref.read(authControllerProvider).isLoggedIn) return;
    final result = await _drama.getOnlineDramaCount();
    if (!ref.mounted) return;
    if (result.isSuccess && result.dataOrNull != null) {
      state = state.copyWith(onlineDramaCount: result.dataOrNull!);
    }
  }

  void requestDeleteActor(Actor actor) {
    state = state.copyWith(
      activeDialog: CreatorDialog.deleteActorConfirm,
      actorToDelete: actor.id,
    );
  }

  void closeDialog() {
    state = state.copyWith(activeDialog: CreatorDialog.closed);
  }

  Future<void> confirmDeleteActor() async {
    final actorId = state.actorToDelete;
    if (actorId == null) return;

    state = state.copyWith(isDeleting: true);
    try {
      final result = await _actor.deleteActor(actorId);
      if (!ref.mounted) return;
      if (result.isSuccess) {
        state = state.copyWith(
          myActors: state.myActors.where((a) => a.id != actorId).toList(),
          activeDialog: CreatorDialog.closed,
        );
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isDeleting: false);
      }
    }
  }
}
