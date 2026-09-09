import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/follow_models.dart';
import '../model/page_dto.dart';
import '../provider/repository_providers.dart';
import '../repositories/follow_repository.dart';
import 'follow_list_state.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';

class FollowListController extends Notifier<FollowListState>
    with PaginationMixin<FollowListItem, FollowListState> {
  late FollowRepository _repo;
  final FollowListParam param;

  FollowListController(this.param);

  @override
  FollowListState build() {
    _repo = ref.read(followRepositoryProvider);
    // Auto-fetch when this family instance is first watched (active tab).
    // Matches web ProfileFollowRelationsDialog `enabled: open` query.
    Future.microtask(() {
      if (!ref.mounted) return;
      refresh();
    });
    return const FollowListState();
  }

  @override
  PaginationState<FollowListItem> get pagination => state.pagination;

  @override
  bool get isLoading => state.isLoading;

  @override
  void setPaginationState(
    PaginationState<FollowListItem> pagination, {
    bool? isLoading,
  }) {
    // Mark fetched when a loading cycle ends (was loading → not loading).
    final endedLoading =
        isLoading == false && !pagination.isPageLoading && state.isLoading;
    state = state.copyWith(
      pagination: pagination,
      isLoading: isLoading,
      hasFetched: endedLoading ? true : null,
      clearLastError: true,
    );
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error, hasFetched: true);
  }

  @override
  Future<Result<PageDto<FollowListItem>>> fetchPage({String? mark}) {
    final markArg = (mark == null || mark.isEmpty) ? '0' : mark;
    StoryLogger.d(
      'follow list fetch type=${param.type.name} userId=${param.userId} mark=$markArg',
      tag: 'FollowList',
    );
    return switch (param.type) {
      FollowListType.following => _repo.listFollowings(
        userId: param.userId,
        mark: markArg,
      ),
      FollowListType.followers => _repo.listFollowers(
        userId: param.userId,
        mark: markArg,
      ),
      FollowListType.mutuals => _repo.listMutuals(
        userId: param.userId,
        mark: markArg,
      ),
    };
  }

  @override
  Future<void> refresh() async {
    if (param.userId.trim().isEmpty) {
      StoryLogger.w(
        'follow list refresh skipped: empty userId type=${param.type.name}',
        tag: 'FollowList',
      );
      state = state.copyWith(
        isLoading: false,
        hasFetched: true,
        lastError: ApiError.unknown('Missing userId'),
      );
      return;
    }
    await super.refresh();
    if (!ref.mounted) return;
    StoryLogger.d(
      'follow list done type=${param.type.name} userId=${param.userId} '
      'count=${state.items.length} hasFetched=${state.hasFetched} '
      'error=${state.lastError?.userMessage}',
      tag: 'FollowList',
    );
  }

  void patchRelation(String targetUserId, FollowRelationStatus status) {
    final next = [
      for (final item in state.items)
        if (item.userId == targetUserId)
          item.copyWith(relationStatus: status)
        else
          item,
    ];
    state = state.copyWith(
      pagination: state.pagination.copyWith(items: next),
      clearLastError: true,
    );
  }

  void removeUser(String targetUserId) {
    final next = [
      for (final item in state.items)
        if (item.userId != targetUserId) item,
    ];
    state = state.copyWith(
      pagination: state.pagination.copyWith(items: next),
      clearLastError: true,
    );
  }
}

final followListControllerProvider = NotifierProvider.family
    .autoDispose<FollowListController, FollowListState, FollowListParam>(
      FollowListController.new,
    );
