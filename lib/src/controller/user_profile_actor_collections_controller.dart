import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/actor_collection_model.dart';
import '../model/page_dto.dart';
import '../provider/auth_providers.dart';
import '../provider/repository_providers.dart';
import '../repositories/actor_repository.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';
import 'user_profile_actor_collections_state.dart';

class UserProfileActorCollectionsController
    extends Notifier<UserProfileActorCollectionsState>
    with PaginationMixin<ActorCollection, UserProfileActorCollectionsState> {
  final UserProfileActorParam param;

  late ActorRepository _repository;
  String? _userId;
  bool _initialized = false;

  UserProfileActorCollectionsController(this.param);

  @override
  UserProfileActorCollectionsState build() {
    // Keep list state while switching profile tabs (slivers unmount the
    // inactive tab, which would otherwise dispose this autoDispose family).
    ref.keepAlive();

    _repository = ref.read(actorRepositoryProvider);
    final userId =
        param.userId ??
        ref.watch(
          authControllerProvider.select((state) => state.userId),
        );

    final userIdChanged = userId != _userId;
    _userId = userId;

    if (userId == null || userId.isEmpty) {
      _initialized = true;
      return const UserProfileActorCollectionsState(
        hasFetched: true,
        pagination: PaginationState(hasMore: false),
      );
    }

    if (_initialized && !userIdChanged) {
      return state;
    }

    _initialized = true;
    Future.microtask(() {
      if (ref.mounted) unawaited(refresh());
    });
    return const UserProfileActorCollectionsState();
  }

  @override
  PaginationState<ActorCollection> get pagination => state.pagination;

  @override
  bool get isLoading => state.isLoading;

  @override
  void setPaginationState(
    PaginationState<ActorCollection> pagination, {
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
  Future<Result<PageDto<ActorCollection>>> fetchPage({String? mark}) {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return Future.value(
        Result.failure(ApiError.unknown('Missing profile user id')),
      );
    }
    return _repository.listProfileActorCollections(
      userId: userId,
      mark: mark,
    );
  }

  @override
  Future<void> refresh() async {
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

  /// Re-fetches page one without flipping the tab into a loading spinner.
  Future<void> silentRevalidate() async {
    if (state.isLoading || state.isPageLoading || !state.hasFetched) return;
    final result = await fetchPage();
    if (!ref.mounted || result.isFailure) return;
    final page = result.dataOrNull;
    if (page == null) return;
    state = state.copyWith(
      clearLastError: true,
      pagination: const PaginationState<ActorCollection>().appendPage(page),
    );
  }

  void upsertActor(ActorCollection actor) {
    final id = actor.id;
    if (id == null || id.isEmpty) return;
    final items = pagination.items;
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final next = List<ActorCollection>.from(items);
    next[index] = actor;
    setPaginationState(pagination.copyWith(items: next));
  }
}
