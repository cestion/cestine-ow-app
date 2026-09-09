import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';
import 'pagination_state.dart';

class RecommendFeedState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final PaginationState<RecommendFeedItem> pagination;
  final int currentIndex;
  final DramaDetail? currentDetail;
  final DramaPlayResponse? currentPlay;
  final bool isPlayLoading;
  final bool isUserPaused;

  const RecommendFeedState({
    this.isLoading = false,
    this.lastError,
    this.pagination = const PaginationState<RecommendFeedItem>(),
    this.currentIndex = 0,
    this.currentDetail,
    this.currentPlay,
    this.isPlayLoading = false,
    this.isUserPaused = false,
  });

  List<RecommendFeedItem> get items => pagination.items;
  bool get hasMore => pagination.hasMore;
  String get mark => pagination.mark;
  bool get isPageLoading => pagination.isPageLoading;

  RecommendFeedItem? get currentItem {
    if (items.isEmpty || currentIndex < 0 || currentIndex >= items.length) {
      return null;
    }
    return items[currentIndex];
  }

  RecommendFeedState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    PaginationState<RecommendFeedItem>? pagination,
    int? currentIndex,
    DramaDetail? currentDetail,
    bool clearCurrentDetail = false,
    DramaPlayResponse? currentPlay,
    bool clearCurrentPlay = false,
    bool? isPlayLoading,
    bool? isUserPaused,
  }) {
    return RecommendFeedState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      pagination: pagination ?? this.pagination,
      currentIndex: currentIndex ?? this.currentIndex,
      currentDetail: clearCurrentDetail
          ? null
          : (currentDetail ?? this.currentDetail),
      currentPlay: clearCurrentPlay ? null : (currentPlay ?? this.currentPlay),
      isPlayLoading: isPlayLoading ?? this.isPlayLoading,
      isUserPaused: isUserPaused ?? this.isUserPaused,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    lastError,
    pagination,
    currentIndex,
    currentDetail,
    currentPlay,
    isPlayLoading,
    isUserPaused,
  ];
}
