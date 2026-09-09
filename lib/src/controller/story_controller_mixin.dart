import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_logger.dart';

/// A [Notifier] mixin providing `withLoading` / `withLoadingResult`
/// convenience methods for controllers that manage `isLoading` / `lastError`
/// in their state.
///
/// Controllers using this mixin must implement [copyWithLoadingState] to
/// create a new state instance with updated loading/error fields.
///
/// Example:
/// ```dart
/// class MyController extends Notifier<MyState>
///     with StoryControllerMixin<MyState> {
///   @override
///   MyState copyWithLoadingState({
///     bool? isLoading,
///     ApiError? lastError,
///     bool clearLastError = false,
///   }) {
///     return state.copyWith(
///       isLoading: isLoading,
///       lastError: lastError,
///       clearLastError: clearLastError,
///     );
///   }
///
///   Future<void> loadData() async {
///     final result = await withLoadingResult(() => repo.fetch());
///     if (result != null) state = state.copyWith(data: result);
///   }
/// }
/// ```
mixin StoryControllerMixin<S> on Notifier<S> {
  /// Creates a new state instance with updated loading/error fields.
  ///
  /// [isLoading] is non-null when changing loading state.
  /// [lastError] is the error to set; [clearLastError] signals to clear it.
  S copyWithLoadingState({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  });

  /// Apply loading/error state changes to the immutable state.
  ///
  /// Default implementation calls [copyWithLoadingState] and updates [state].
  /// Override this method only if you need custom loading state logic.
  void updateState({
    required bool? isLoading,
    required ApiError? lastError,
    required bool clearLastError,
  }) {
    state = copyWithLoadingState(
      isLoading: isLoading,
      lastError: lastError,
      clearLastError: clearLastError,
    );
  }

  /// Wraps an async operation with loading/error state management.
  ///
  /// Sets `isLoading = true` and clears errors before execution,
  /// then sets `isLoading = false` after, capturing any exception
  /// into `lastError`.
  ///
  /// Returns [Result.success] with the action's result,
  /// or [Result.failure] if the action throws or returns null.
  Future<Result<T>> withLoading<T>(
    Future<T?> Function() action, {
    String? operation,
  }) async {
    final tag = operation ?? runtimeType.toString();
    updateState(isLoading: true, lastError: null, clearLastError: true);
    try {
      final data = await action();
      if (!ref.mounted) return Result.failure(ApiError.unknown('disposed'));
      if (data == null) {
        final error = ApiError.unknown('Operation returned null');
        updateState(isLoading: false, lastError: error, clearLastError: false);
        return Result.failure(error);
      }
      updateState(isLoading: false, lastError: null, clearLastError: true);
      return Result.success(data);
    } catch (e, st) {
      if (!ref.mounted) {
        return Result.failure(ApiError.unknown('disposed'));
      }
      final error = ApiError.unknown(
        e.toString(),
        exception: e is Exception ? e : null,
      );
      StoryLogger.e(
        'withLoading($tag) failed: $e',
        error: e,
        stackTrace: st,
        tag: tag,
      );
      updateState(isLoading: false, lastError: error, clearLastError: false);
      return Result.failure(error);
    }
  }

  /// Same as [withLoading] but expects the action to return a [Result<T>]
  /// so domain-level failures populate `lastError` while preserving the
  /// typed result. Returns the data on success, `null` on failure.
  Future<T?> withLoadingResult<T>(
    Future<Result<T>> Function() action, {
    String? operation,
  }) async {
    final tag = operation ?? runtimeType.toString();
    updateState(isLoading: true, lastError: null, clearLastError: true);
    try {
      final result = await action();
      if (!ref.mounted) return null;
      if (result.isFailure) {
        final error = result.errorOrNull;
        StoryLogger.w(
          'withLoadingResult($tag) returned failure: ${error?.userMessage}',
          tag: tag,
        );
        updateState(isLoading: false, lastError: error, clearLastError: false);
        return null;
      }
      updateState(isLoading: false, lastError: null, clearLastError: true);
      return result.dataOrNull;
    } catch (e, st) {
      if (!ref.mounted) return null;
      final error = ApiError.unknown(
        e.toString(),
        exception: e is Exception ? e : null,
      );
      StoryLogger.e(
        'withLoadingResult($tag) threw: $e',
        error: e,
        stackTrace: st,
        tag: tag,
      );
      updateState(isLoading: false, lastError: error, clearLastError: false);
      return null;
    }
  }
}
