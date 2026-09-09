import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/page_dto.dart';
import '../model/user_profile_content_model.dart';
import '../provider/auth_providers.dart';
import '../provider/core_providers.dart';
import '../provider/repository_providers.dart';
import '../repositories/user_repository.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';
import 'user_profile_dramas_state.dart';

class UserProfileDramasController extends Notifier<UserProfileDramasState>
    with PaginationMixin<UserProfileContentItem, UserProfileDramasState> {
  final UserProfileDramaParam param;

  late UserRepository _repository;
  String? _userId;
  bool _initialized = false;
  bool _isSilentRevalidating = false;
  bool _pendingMutationRevalidation = false;
  int _refreshRevision = 0;

  UserProfileDramasController(this.param);

  @override
  UserProfileDramasState build() {
    // Keep list state while switching profile tabs (slivers unmount the
    // inactive tab, which would otherwise dispose this autoDispose family).
    ref.keepAlive();

    _repository = ref.read(userRepositoryProvider);
    final userId =
        param.userId ??
        ref.watch(
          authControllerProvider.select((state) => state.userId),
        );

    // Profile card tags are localized by the API through Accept-Language.
    // Re-fetch loaded lists when the app language changes so server-provided
    // tags do not remain in the previous language on kept-alive profile tabs.
    ref.listen<String>(localeCodeProvider, (previous, next) {
      if (previous != null && previous != next) {
        unawaited(refresh());
      }
    });

    final userIdChanged = userId != _userId;
    _userId = userId;

    if (userId == null || userId.isEmpty) {
      _initialized = true;
      return const UserProfileDramasState(
        hasFetched: true,
        pagination: PaginationState(hasMore: false),
      );
    }

    // Preserve list across dependency rebuilds when the owner is unchanged.
    // Returning a fresh empty state would wipe items and re-schedule refresh().
    if (_initialized && !userIdChanged) {
      return state;
    }

    _initialized = true;
    Future.microtask(() {
      if (ref.mounted) unawaited(refresh());
    });
    return const UserProfileDramasState();
  }

  @override
  PaginationState<UserProfileContentItem> get pagination => state.pagination;

  @override
  bool get isLoading => state.isLoading;

  @override
  void setPaginationState(
    PaginationState<UserProfileContentItem> pagination, {
    bool? isLoading,
  }) {
    final endedLoading =
        isLoading == false && !pagination.isPageLoading && state.isLoading;
    state = state.copyWith(
      pagination: pagination,
      isLoading: isLoading,
      hasFetched: endedLoading ? true : null,
      clearLastError: isLoading == true,
    );
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error, hasFetched: true);
  }

  @override
  Future<Result<PageDto<UserProfileContentItem>>> fetchPage({String? mark}) {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return Future.value(
        Result.failure(ApiError.unknown('Missing profile user id')),
      );
    }
    return _repository.getUserProfileDramas(
      userId: userId,
      type: param.type,
      contentType: param.contentType,
      mark: mark,
    );
  }

  @override
  Future<void> refresh() async {
    _refreshRevision++;
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(
        hasFetched: true,
        pagination: state.pagination.copyWith(hasMore: false),
      );
      return;
    }
    await super.refresh();
  }

  /// Re-fetches page one without exposing a loading/error state.
  ///
  /// A fresh page is committed only when its leading drama changes (including
  /// empty ↔ non-empty). This keeps lifecycle/connectivity revalidation from
  /// rebuilding the whole grid when the server still has the same newest item.
  Future<bool> silentRevalidate() async {
    final userId = _userId;
    if (_isSilentRevalidating ||
        state.isLoading ||
        state.isPageLoading ||
        !state.hasFetched ||
        userId == null ||
        userId.isEmpty) {
      return false;
    }

    _isSilentRevalidating = true;
    final requestedRevision = _refreshRevision;
    try {
      final result = await _repository.getUserProfileDramas(
        userId: userId,
        type: param.type,
        contentType: param.contentType,
      );
      if (!ref.mounted ||
          requestedRevision != _refreshRevision ||
          state.isLoading ||
          state.isPageLoading ||
          result.isFailure) {
        return false;
      }

      final page = result.dataOrNull;
      if (page == null) return false;

      final currentItems = state.items;
      final freshItems = page.list ?? const <UserProfileContentItem>[];
      final leadingItemChanged =
          currentItems.isEmpty != freshItems.isEmpty ||
          (currentItems.isNotEmpty &&
              freshItems.isNotEmpty &&
              currentItems.first.contentId != freshItems.first.contentId);
      if (!leadingItemChanged) return false;

      _replaceWithFirstPage(page);
      return true;
    } catch (error, stackTrace) {
      StoryLogger.e(
        'Profile dramas silent revalidation failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'ProfileDramas',
      );
      return false;
    } finally {
      _finishSilentRevalidation();
    }
  }

  /// Silently reloads page one after an explicit successful mutation.
  ///
  /// Unlike lifecycle revalidation, an explicit publish/like/favorite action
  /// may change an existing row without changing the leading id. Compare the
  /// returned first page with the currently displayed prefix and commit only
  /// when that page actually changed.
  Future<bool> silentRevalidateAfterMutation() async {
    if (_isSilentRevalidating) {
      _pendingMutationRevalidation = true;
      return false;
    }

    final userId = _userId;
    if (state.isLoading ||
        state.isPageLoading ||
        !state.hasFetched ||
        userId == null ||
        userId.isEmpty) {
      return false;
    }

    _isSilentRevalidating = true;
    final requestedRevision = _refreshRevision;
    try {
      final result = await _repository.getUserProfileDramas(
        userId: userId,
        type: param.type,
        contentType: param.contentType,
      );
      if (!ref.mounted ||
          requestedRevision != _refreshRevision ||
          state.isLoading ||
          state.isPageLoading ||
          result.isFailure) {
        return false;
      }

      final page = result.dataOrNull;
      if (page == null || _matchesCurrentFirstPage(page)) return false;

      _replaceWithFirstPage(page);
      return true;
    } catch (error, stackTrace) {
      StoryLogger.e(
        'Profile dramas mutation revalidation failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'ProfileDramas',
      );
      return false;
    } finally {
      _finishSilentRevalidation();
    }
  }

  /// Applies a successful delete/unlike/unfavorite directly to a loaded list.
  bool removeDrama(String dramaId) {
    final nextItems = state.items
        .where((item) => !item.matchesContentId(dramaId))
        .toList(growable: false);
    if (nextItems.length == state.items.length) return false;

    _refreshRevision++;
    state = state.copyWith(
      pagination: state.pagination.copyWith(items: nextItems),
    );
    return true;
  }

  /// Replaces one loaded profile row without changing loading/pagination.
  bool replaceContentItem(UserProfileContentItem item) {
    final episodeId = item.episode?.id;
    final dramaId = item.drama?.id;
    final index = state.items.indexWhere(
      (candidate) => episodeId != null
          ? candidate.episode?.id == episodeId
          : dramaId != null && candidate.drama?.id == dramaId,
    );
    if (index < 0 || state.items[index] == item) return false;

    final nextItems = List<UserProfileContentItem>.from(state.items);
    nextItems[index] = item;
    _refreshRevision++;
    state = state.copyWith(
      pagination: state.pagination.copyWith(items: nextItems),
    );
    return true;
  }

  bool _matchesCurrentFirstPage(PageDto<UserProfileContentItem> page) {
    final freshItems = page.list ?? const <UserProfileContentItem>[];
    final currentItems = state.items;
    if (currentItems.length < freshItems.length) return false;
    for (var index = 0; index < freshItems.length; index++) {
      if (currentItems[index] != freshItems[index]) return false;
    }
    // A short final page is the complete list, so an extra current row means
    // the mutation removed data and the page must be replaced.
    return page.hasMore == true || currentItems.length == freshItems.length;
  }

  void _replaceWithFirstPage(PageDto<UserProfileContentItem> page) {
    final nextMark = page.mark?.toString() ?? '';
    _refreshRevision++;
    state = state.copyWith(
      hasFetched: true,
      clearLastError: true,
      pagination: PaginationState<UserProfileContentItem>(
        items: page.list ?? const <UserProfileContentItem>[],
        hasMore: page.hasMore ?? false,
        mark: nextMark,
      ),
    );
  }

  void _finishSilentRevalidation() {
    _isSilentRevalidating = false;
    if (!_pendingMutationRevalidation || !ref.mounted) return;

    _pendingMutationRevalidation = false;
    Future.microtask(() {
      if (ref.mounted) unawaited(silentRevalidateAfterMutation());
    });
  }
}
