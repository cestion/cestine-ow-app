import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

/// A single notification tab's immutable list state.
class NotificationState extends Equatable {
  final List<NotificationItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoaded;
  final bool hasMore;
  final String mark;
  final ApiError? lastError;

  const NotificationState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasLoaded = false,
    this.hasMore = true,
    this.mark = '0',
    this.lastError,
  });

  NotificationState copyWith({
    List<NotificationItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasLoaded,
    bool? hasMore,
    String? mark,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return NotificationState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      hasMore: hasMore ?? this.hasMore,
      mark: mark ?? this.mark,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  List<Object?> get props => [
    items,
    isLoading,
    isLoadingMore,
    hasLoaded,
    hasMore,
    mark,
    lastError,
  ];
}
