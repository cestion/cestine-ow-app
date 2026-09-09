import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../provider/repository_providers.dart';
import 'report_state.dart';
import 'story_controller_mixin.dart';

class ReportController extends Notifier<ReportState>
    with StoryControllerMixin<ReportState> {
  @override
  ReportState build() => const ReportState();

  @override
  ReportState copyWithLoadingState({
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

  Future<List<ReportTypeItem>> loadReportTypes({
    required List<ReportTypeItem> fallbackReasons,
    String? scope,
  }) async {
    state = state.copyWith(isLoading: true, clearLastError: true);
    final result = await ref
        .read(dramaRepositoryProvider)
        .getReportTypes(scope: scope);
    if (!ref.mounted) return fallbackReasons;

    if (result.isSuccess) {
      final reasons = result.dataOrNull ?? fallbackReasons;
      state = state.copyWith(
        reasons: reasons.isNotEmpty ? reasons : fallbackReasons,
        isLoading: false,
      );
      return state.reasons;
    }

    state = state.copyWith(
      reasons: fallbackReasons,
      isLoading: false,
      lastError: result.errorOrNull,
    );
    return fallbackReasons;
  }

  Future<Result<void>> submitReport({
    required String dramaId,
    required String episodeId,
    required String reportType,
    String? description,
    WorkContentType type = WorkContentType.shortDrama,
  }) async {
    state = state.copyWith(isSubmitting: true, clearLastError: true);
    final result = await ref
        .read(dramaRepositoryProvider)
        .reportEpisode(
          dramaId: dramaId,
          episodeId: episodeId,
          reportType: reportType,
          description: description,
          type: type,
        );
    if (!ref.mounted) return result;

    state = state.copyWith(
      isSubmitting: false,
      lastError: result.isFailure ? result.errorOrNull : null,
      clearLastError: result.isSuccess,
    );
    return result;
  }

  /// 整剧举报（scope=DRAMA）：以 dramaId 为对象，不绑定单集 episodeId。
  Future<Result<void>> submitDramaReport({
    required String dramaId,
    required String reportType,
    String? description,
  }) async {
    state = state.copyWith(isSubmitting: true, clearLastError: true);
    final result = await ref
        .read(dramaRepositoryProvider)
        .reportDrama(
          dramaId: dramaId,
          reportType: reportType,
          description: description,
        );
    if (!ref.mounted) return result;

    state = state.copyWith(
      isSubmitting: false,
      lastError: result.isFailure ? result.errorOrNull : null,
      clearLastError: result.isSuccess,
    );
    return result;
  }

  Future<Result<void>> submitCommentReport({
    required String commentId,
    required String reportType,
    String? description,
  }) async {
    state = state.copyWith(isSubmitting: true, clearLastError: true);
    final result = await ref
        .read(dramaRepositoryProvider)
        .reportComment(
          commentId: commentId,
          reportType: reportType,
          description: description,
        );
    if (!ref.mounted) return result;

    state = state.copyWith(
      isSubmitting: false,
      lastError: result.isFailure ? result.errorOrNull : null,
      clearLastError: result.isSuccess,
    );
    return result;
  }

  Future<Result<void>> submitUserReport({
    required String userId,
    required String reportType,
    String? description,
  }) async {
    state = state.copyWith(isSubmitting: true, clearLastError: true);
    final result = await ref
        .read(dramaRepositoryProvider)
        .reportUser(
          userId: userId,
          reportType: reportType,
          description: description,
        );
    if (!ref.mounted) return result;

    state = state.copyWith(
      isSubmitting: false,
      lastError: result.isFailure ? result.errorOrNull : null,
      clearLastError: result.isSuccess,
    );
    return result;
  }
}
