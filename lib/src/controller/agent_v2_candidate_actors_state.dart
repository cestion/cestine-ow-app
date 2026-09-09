import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

/// 经纪人 V2 底部候场条与候场弹窗共享的分页状态。
class AgentV2CandidateActorsState extends Equatable {
  final List<MiningActor> actors;
  final bool isInitialized;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final ApiError? lastError;
  final String? submittingActorNftId;
  final ApiError? actionError;

  const AgentV2CandidateActorsState({
    this.actors = const [],
    this.isInitialized = false,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.totalCount = 0,
    this.lastError,
    this.submittingActorNftId,
    this.actionError,
  });

  /// Whether the sheet can render meaningful content while revalidating.
  bool get hasUsableSnapshot =>
      isInitialized && (actors.isNotEmpty || lastError == null);

  bool isSubmitting(String actorNftId) => submittingActorNftId == actorNftId;

  AgentV2CandidateActorsState copyWith({
    List<MiningActor>? actors,
    bool? isInitialized,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
    ApiError? lastError,
    bool clearLastError = false,
    String? submittingActorNftId,
    bool clearSubmittingActor = false,
    ApiError? actionError,
    bool clearActionError = false,
  }) {
    return AgentV2CandidateActorsState(
      actors: actors ?? this.actors,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      submittingActorNftId: clearSubmittingActor
          ? null
          : (submittingActorNftId ?? this.submittingActorNftId),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
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
    lastError,
    submittingActorNftId,
    actionError,
  ];
}
