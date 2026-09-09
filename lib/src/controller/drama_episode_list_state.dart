import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

class DramaEpisodeListState extends Equatable {
  final List<DramaEpisodeListItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final ApiError? error;

  const DramaEpisodeListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  DramaEpisodeListState copyWith({
    List<DramaEpisodeListItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    ApiError? error,
    bool clearError = false,
  }) {
    return DramaEpisodeListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [items, isLoading, isLoadingMore, hasMore, error];
}
