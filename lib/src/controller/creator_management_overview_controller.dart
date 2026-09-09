import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/story_logger.dart';
import '../provider/app_providers.dart';
import 'creator_management_overview_state.dart';

/// Loads totals shown by the primary creator-management tabs.
///
/// These totals are intentionally independent from each tab's status filter.
class CreatorManagementOverviewController
    extends Notifier<CreatorManagementOverviewState> {
  bool _isSilentRefreshing = false;

  @override
  CreatorManagementOverviewState build() =>
      const CreatorManagementOverviewState();

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearLastError: true);

    final userId = ref.read(authControllerProvider).userId;
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final result = await ref.read(userRepositoryProvider).getWorkStats(userId);
    if (!ref.mounted) return;

    result.when(
      success: (stats) {
        state = state.copyWith(
          isLoading: false,
          dramaCount: stats.dramaCount,
          videoCount: stats.shortVideoCount,
          clearLastError: true,
        );
      },
      failure: (error) {
        state = state.copyWith(isLoading: false, lastError: error);
      },
    );
  }

  /// Reconciles the displayed totals with the server without exposing a
  /// loading state or replacing the current values when the request fails.
  Future<void> silentRefresh() async {
    if (_isSilentRefreshing) return;

    final userId = ref.read(authControllerProvider).userId;
    if (userId == null || userId.isEmpty) return;

    _isSilentRefreshing = true;
    try {
      final result = await ref
          .read(userRepositoryProvider)
          .getWorkStats(userId);
      if (!ref.mounted) return;

      final stats = result.dataOrNull;
      if (result.isSuccess && stats != null) {
        state = state.copyWith(
          dramaCount: stats.dramaCount,
          videoCount: stats.shortVideoCount,
          clearLastError: true,
        );
      }
    } catch (error, stackTrace) {
      StoryLogger.e(
        'Silent overview refresh failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'CreatorOverview',
      );
    } finally {
      _isSilentRefreshing = false;
    }
  }
}
