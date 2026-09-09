import 'package:equatable/equatable.dart';

import '../model/page_dto.dart';

/// Immutable pagination slice shared by Notifier-based list controllers.
class PaginationState<T> extends Equatable {
  final List<T> items;
  final bool hasMore;
  final String mark;
  final bool isPageLoading;

  const PaginationState({
    this.items = const [],
    this.hasMore = true,
    this.mark = '',
    this.isPageLoading = false,
  });

  PaginationState<T> copyWith({
    List<T>? items,
    bool? hasMore,
    String? mark,
    bool? isPageLoading,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      mark: mark ?? this.mark,
      isPageLoading: isPageLoading ?? this.isPageLoading,
    );
  }

  PaginationState<T> reset() => PaginationState<T>();

  PaginationState<T> appendPage(PageDto<T> page) {
    final nextMark = page.mark?.toString() ?? '';
    final resolvedMark = nextMark.isNotEmpty ? nextMark : mark;
    // hasMore without a cursor would make loadMore re-hit page 1 forever
    // (scroll listeners near the bottom fire continuously on short viewports).
    final claimedHasMore = page.hasMore ?? false;
    final hasMore = claimedHasMore && resolvedMark.isNotEmpty;
    return copyWith(
      items: [...items, ...?page.list],
      hasMore: hasMore,
      mark: resolvedMark,
      isPageLoading: false,
    );
  }

  @override
  List<Object?> get props => [items, hasMore, mark, isPageLoading];
}
