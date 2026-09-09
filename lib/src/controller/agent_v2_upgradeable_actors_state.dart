import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

/// 经纪人 V2 顶栏升级数与「升级角色」bottom sheet 的共享状态。
class AgentV2UpgradeableActorsState extends Equatable {
  final List<MiningActor> actors;
  final bool isInitialized;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final int upgradeableCount;
  final ApiError? lastError;

  const AgentV2UpgradeableActorsState({
    this.actors = const [],
    this.isInitialized = false,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.totalCount = 0,
    this.upgradeableCount = 0,
    this.lastError,
  });

  /// Whether the sheet can render meaningful content while revalidating.
  bool get hasUsableSnapshot =>
      isInitialized && (actors.isNotEmpty || lastError == null);

  AgentV2UpgradeableActorsState copyWith({
    List<MiningActor>? actors,
    bool? isInitialized,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
    int? upgradeableCount,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return AgentV2UpgradeableActorsState(
      actors: actors ?? this.actors,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      upgradeableCount: upgradeableCount ?? this.upgradeableCount,
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
    upgradeableCount,
    lastError,
  ];
}
