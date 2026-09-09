import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

/// 与 web `GameActorSort` / `LEVEL|HEAT|STAMINA|COMPUTING_POWER` 对齐。
enum GameActorSort {
  computingPower('COMPUTING_POWER'),
  level('LEVEL'),
  heat('HEAT'),
  stamina('STAMINA');

  const GameActorSort(this.apiValue);
  final String apiValue;
}

/// 经纪工坊派遣槽位数，与 web `GAME_DEPLOY_SLOT_COUNT` 一致。
const int gameDeploySlotCount = 5;

/// 默认体力上限（init config 未接入时的 fallback，与 API 文档一致）。
const int defaultGameStaminaLimit = 24;

/// 我的演员分页条数（首屏与翻页统一，避免 offset 重叠）。
const int gameMyActorsPageSize = 20;

/// Sponsor 代付链上上下文。
class RefillChainContext {
  final String rpc;
  final String sponsorUrl;
  final String spender;
  final String storyProgram;
  final String delegator;
  final String treasury;

  const RefillChainContext({
    required this.rpc,
    required this.sponsorUrl,
    required this.spender,
    required this.storyProgram,
    required this.delegator,
    required this.treasury,
  });
}

class GameState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshingList;
  final bool isActionLoading;
  final ApiError? lastError;
  final MiningWeeklyStats? weeklyStats;
  final List<MiningActor> deployedActors;
  final List<MiningActor> myActors;
  final int totalActorCount;
  final int nonMaxLevelActorCount;
  final int currentPage;
  final bool hasMore;
  final GameActorSort sort;

  /// Agent V2 owns this scoped config instead of reading global config state.
  final GlobalConfig? agentV2Config;
  final bool isAgentV2ConfigLoading;
  final ApiError? agentV2ConfigError;
  final int staminaLimit;

  const GameState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshingList = false,
    this.isActionLoading = false,
    this.lastError,
    this.weeklyStats,
    this.deployedActors = const [],
    this.myActors = const [],
    this.totalActorCount = 0,
    this.nonMaxLevelActorCount = 0,
    this.currentPage = 0,
    this.hasMore = false,
    this.sort = GameActorSort.computingPower,
    this.agentV2Config,
    this.isAgentV2ConfigLoading = false,
    this.agentV2ConfigError,
    this.staminaLimit = defaultGameStaminaLimit,
  });

  InitActorNftConfig? get actorNftConfig => agentV2Config?.init?.actorNft;

  /// Null means the Agent V2 config has not produced a trustworthy value yet.
  int? get agentV2StaminaLimit {
    final limit = actorNftConfig?.staminaLimit;
    return limit != null && limit > 0 ? limit : null;
  }

  String get errorMessage => lastError?.userMessage ?? '';

  int get deployedCount => deployedActors.length;

  /// 尚未使用的在演位数量；最多同时安排 5 位角色演出。
  int get vacantDeploySlotCount =>
      (gameDeploySlotCount - deployedCount).clamp(0, gameDeploySlotCount);

  /// 已在演但体力恰好耗尽、需要补充体力的角色。
  List<MiningActor> get depletedDeployedActors => deployedActors
      .where((actor) => actor.stamina == 0)
      .take(gameDeploySlotCount)
      .toList(growable: false);

  /// 空位合并为一条待办，体力耗尽的角色各占一条待办。
  int get todoCount =>
      (vacantDeploySlotCount > 0 ? 1 : 0) + depletedDeployedActors.length;

  /// 5 槽派遣位：已派遣 + 空槽占位。
  List<MiningActor?> get deploySlots {
    final slots = <MiningActor?>[...deployedActors.take(gameDeploySlotCount)];
    while (slots.length < gameDeploySlotCount) {
      slots.add(null);
    }
    return slots;
  }

  List<String> get deployedAvatarUrls => deployedActors
      .where((a) => a.avatarUrl?.isNotEmpty ?? false)
      .map((a) => a.avatarUrl!)
      .take(gameDeploySlotCount)
      .toList();

  bool get canDeployMore => deployedCount < gameDeploySlotCount;

  /// 一键演出可派遣数量：空闲角色数与剩余在演位数中的较小值。
  int deployAllActorCount(int restActorCount) {
    if (restActorCount <= 0 || vacantDeploySlotCount <= 0) return 0;
    return restActorCount < vacantDeploySlotCount
        ? restActorCount
        : vacantDeploySlotCount;
  }

  GameState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshingList,
    bool? isActionLoading,
    ApiError? lastError,
    bool clearLastError = false,
    MiningWeeklyStats? weeklyStats,
    List<MiningActor>? deployedActors,
    List<MiningActor>? myActors,
    int? totalActorCount,
    int? nonMaxLevelActorCount,
    int? currentPage,
    bool? hasMore,
    GameActorSort? sort,
    GlobalConfig? agentV2Config,
    bool? isAgentV2ConfigLoading,
    ApiError? agentV2ConfigError,
    bool clearAgentV2ConfigError = false,
    int? staminaLimit,
  }) {
    return GameState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshingList: isRefreshingList ?? this.isRefreshingList,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      weeklyStats: weeklyStats ?? this.weeklyStats,
      deployedActors: deployedActors ?? this.deployedActors,
      myActors: myActors ?? this.myActors,
      totalActorCount: totalActorCount ?? this.totalActorCount,
      nonMaxLevelActorCount:
          nonMaxLevelActorCount ?? this.nonMaxLevelActorCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      sort: sort ?? this.sort,
      agentV2Config: agentV2Config ?? this.agentV2Config,
      isAgentV2ConfigLoading:
          isAgentV2ConfigLoading ?? this.isAgentV2ConfigLoading,
      agentV2ConfigError: clearAgentV2ConfigError
          ? null
          : (agentV2ConfigError ?? this.agentV2ConfigError),
      staminaLimit: staminaLimit ?? this.staminaLimit,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingMore,
    isRefreshingList,
    isActionLoading,
    lastError,
    weeklyStats,
    deployedActors,
    myActors,
    totalActorCount,
    nonMaxLevelActorCount,
    currentPage,
    hasMore,
    sort,
    agentV2Config,
    isAgentV2ConfigLoading,
    agentV2ConfigError,
    staminaLimit,
  ];
}

/// 按 actorNftId 去重合并分页结果，与 web `GameMyActorsSection` 一致。
List<MiningActor> mergeMiningActors(
  List<MiningActor> existing,
  List<MiningActor> incoming,
) {
  final seen = <String>{};
  final merged = <MiningActor>[];
  for (final actor in [...existing, ...incoming]) {
    final id = actor.nftId;
    if (id.isEmpty || seen.contains(id)) continue;
    seen.add(id);
    merged.add(actor);
  }
  return merged;
}
