import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

/// 经纪人 V3「角色回收」弹窗的独立分页状态。
class AgentV3RecycleActorsState extends Equatable {
  final List<MiningActor> actors;
  final bool isInitialized;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final String? recyclingActorNftId;
  final ApiError? lastError;

  const AgentV3RecycleActorsState({
    this.actors = const [],
    this.isInitialized = false,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.totalCount = 0,
    this.recyclingActorNftId,
    this.lastError,
  });

  /// Whether the sheet can render meaningful content while revalidating.
  bool get hasUsableSnapshot =>
      isInitialized && (actors.isNotEmpty || lastError == null);

  bool isRecycling(String actorNftId) => recyclingActorNftId == actorNftId;

  AgentV3RecycleActorsState copyWith({
    List<MiningActor>? actors,
    bool? isInitialized,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
    String? recyclingActorNftId,
    bool clearRecyclingActorNftId = false,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return AgentV3RecycleActorsState(
      actors: actors ?? this.actors,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      recyclingActorNftId: clearRecyclingActorNftId
          ? null
          : (recyclingActorNftId ?? this.recyclingActorNftId),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  List<Object?> get props => [
    actors,
    isInitialized,
    isLoading,
    isRefreshing,
    isLoadingMore,
    hasMore,
    currentPage,
    totalCount,
    recyclingActorNftId,
    lastError,
  ];
}
