import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/short_video_repository.dart';
import 'creator_video_management_state.dart';
import 'drama_management_state.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';
import 'story_controller_mixin.dart';

class CreatorVideoManagementController
    extends Notifier<CreatorVideoManagementState>
    with
        PaginationMixin<CreatorShortVideo, CreatorVideoManagementState>,
        StoryControllerMixin<CreatorVideoManagementState> {
  ShortVideoRepository get _videos => ref.read(shortVideoRepositoryProvider);
  bool _isSilentRefreshing = false;

  @override
  CreatorVideoManagementState build() => const CreatorVideoManagementState();

  @override
  CreatorVideoManagementState copyWithLoadingState({
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

  @override
  PaginationState<CreatorShortVideo> get pagination => state.pagination;

  @override
  bool get isLoading => state.isLoading;

  @override
  void setPaginationState(
    PaginationState<CreatorShortVideo> pagination, {
    bool? isLoading,
  }) {
    state = state.copyWith(pagination: pagination, isLoading: isLoading);
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error);
  }

  @override
  Future<Result<PageDto<CreatorShortVideo>>> fetchPage({String? mark}) {
    return _videos.listCreatorShortVideos(
      mark: mark,
      status: state.currentStatus.apiValue,
    );
  }

  /// Reconciles the current filter's first page with the server while keeping
  /// the existing list visible and leaving loading indicators unchanged.
  Future<void> silentRefresh() async {
    if (_isSilentRefreshing || state.isLoading) return;

    _isSilentRefreshing = true;
    final requestedStatus = state.currentStatus;
    try {
      final result = await _videos.listCreatorShortVideos(
        status: requestedStatus.apiValue,
      );
      if (!ref.mounted || state.currentStatus != requestedStatus) return;

      final page = result.dataOrNull;
      if (result.isSuccess && page != null) {
        state = state.copyWith(
          pagination: const PaginationState<CreatorShortVideo>().appendPage(
            page,
          ),
          clearLastError: true,
        );
      }
    } catch (error, stackTrace) {
      StoryLogger.e(
        'Silent video refresh failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'CreatorVideoMgmt',
      );
    } finally {
      _isSilentRefreshing = false;
    }
  }

  Future<void> selectStatus(DramaManagementStatus status) async {
    if (status == state.currentStatus && state.items.isNotEmpty) return;
    state = state.copyWith(
      currentStatus: status,
      pagination: const PaginationState<CreatorShortVideo>(),
      clearLastError: true,
    );
    await refresh();
  }

  Future<bool> deleteVideo(int episodeId) async {
    if (episodeId <= 0 || state.isDeleting) return false;

    state = state.copyWith(isDeleting: true, clearLastError: true);
    try {
      final result = await _videos.delete(episodeId);
      if (!ref.mounted) return false;
      if (result.isFailure) {
        state = state.copyWith(lastError: result.errorOrNull);
        return false;
      }

      state = state.copyWith(
        pagination: state.pagination.copyWith(
          items: state.items
              .where((video) => video.episodeId != episodeId)
              .toList(),
        ),
      );
      return true;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isDeleting: false);
      }
    }
  }
}
