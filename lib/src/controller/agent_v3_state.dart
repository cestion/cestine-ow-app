import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../utils/format_number.dart';

const int agentV3DeploySlotCount = 5;

/// 经纪人 V3 底部智能 CTA 的五种业务状态。
enum AgentV3PrimaryActionKind {
  claim,
  performAll,
  restAll,
  refillAll,
  signActor,
}

/// Triggers that can request an authoritative Agent V3 data calibration.
enum AgentV3SyncReason {
  initial,
  tabActivated,
  appResumed,
  connectivityRecovered,
  periodic,
  manual,
  mutation,
}

/// 经纪人 V3 页面级状态。
class AgentV3State extends Equatable {
  final bool isLoading;
  final bool isRefreshing;
  final bool isDirty;
  final bool isPurchasing;
  final bool purchaseEnabled;
  final ApiError? lastError;
  final UserAssets? assets;
  final double? optimisticTrainingManualFloor;
  final String? energyPackUnitPrice;
  final String? trainingManualUnitPrice;
  final CardPurchaseType? pendingCreditType;
  final MiningWeeklyStats? weeklyStats;
  final List<MiningActor> deployedActors;
  final int upgradeableCount;
  final int? staminaLimit;
  final InitActorNftConfig? actorNftConfig;
  final DateTime? lastSuccessfulSyncAt;
  final AgentV3SyncReason? lastSyncReason;

  const AgentV3State({
    this.isLoading = false,
    this.isRefreshing = false,
    this.isDirty = true,
    this.isPurchasing = false,
    this.purchaseEnabled = false,
    this.lastError,
    this.assets,
    this.optimisticTrainingManualFloor,
    this.energyPackUnitPrice,
    this.trainingManualUnitPrice,
    this.pendingCreditType,
    this.weeklyStats,
    this.deployedActors = const [],
    this.upgradeableCount = 0,
    this.staminaLimit,
    this.actorNftConfig,
    this.lastSuccessfulSyncAt,
    this.lastSyncReason,
  });

  String get primaryItemCount =>
      _formatCount((assets ?? UserAssets.empty).staminaPack);
  String get secondaryItemCount {
    final actual = (assets ?? UserAssets.empty).trainingManual;
    final optimisticFloor = optimisticTrainingManualFloor;
    return _formatCount(
      optimisticFloor != null && optimisticFloor > actual
          ? optimisticFloor
          : actual,
    );
  }

  /// 本周片酬取周统计接口的奖池字段。
  String get weeklySalary => formatNumber(weeklyStats?.weekPool);

  /// 已结算、可领取到个人钱包的 STORY。
  double get claimableStory => (assets ?? UserAssets.empty).story;

  /// Whether a partial synchronization left enough authoritative content to
  /// keep rendering the retained page instead of replacing it with an error.
  bool get hasUsableSnapshot =>
      assets != null ||
      weeklyStats != null ||
      deployedActors.isNotEmpty ||
      staminaLimit != null ||
      actorNftConfig != null;

  int get vacantDeploySlotCount =>
      (agentV3DeploySlotCount - deployedActors.length).clamp(
        0,
        agentV3DeploySlotCount,
      );

  int get depletedDeployedActorCount => deployedActors
      .take(agentV3DeploySlotCount)
      .where((actor) => actor.stamina == 0)
      .length;

  /// 按产品规则解析唯一的主操作；越靠前优先级越高。
  AgentV3PrimaryActionKind primaryActionKind({required int waitingActorCount}) {
    if (claimableStory > 0) return AgentV3PrimaryActionKind.claim;
    if (vacantDeploySlotCount > 0) {
      return waitingActorCount > 0
          ? AgentV3PrimaryActionKind.performAll
          : AgentV3PrimaryActionKind.signActor;
    }
    return depletedDeployedActorCount > 0
        ? AgentV3PrimaryActionKind.refillAll
        : AgentV3PrimaryActionKind.restAll;
  }

  /// 与 Agent V2 一致：空演出位聚合为一条，体力耗尽角色各占一条。
  int get todoCount {
    final hasVacancy = deployedActors.length < agentV3DeploySlotCount;
    final depletedCount = deployedActors
        .take(agentV3DeploySlotCount)
        .where((actor) => actor.stamina == 0)
        .length;
    return (hasVacancy ? 1 : 0) + depletedCount;
  }

  String? unitPriceFor(CardPurchaseType type) => switch (type) {
    CardPurchaseType.energyPack => energyPackUnitPrice,
    CardPurchaseType.trainingManual => trainingManualUnitPrice,
  };

  AgentV3State copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isDirty,
    bool? isPurchasing,
    bool? purchaseEnabled,
    ApiError? lastError,
    bool clearLastError = false,
    UserAssets? assets,
    double? optimisticTrainingManualFloor,
    bool clearOptimisticTrainingManualFloor = false,
    String? energyPackUnitPrice,
    String? trainingManualUnitPrice,
    CardPurchaseType? pendingCreditType,
    bool clearPendingCredit = false,
    MiningWeeklyStats? weeklyStats,
    List<MiningActor>? deployedActors,
    int? upgradeableCount,
    int? staminaLimit,
    InitActorNftConfig? actorNftConfig,
    DateTime? lastSuccessfulSyncAt,
    AgentV3SyncReason? lastSyncReason,
  }) {
    return AgentV3State(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isDirty: isDirty ?? this.isDirty,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      purchaseEnabled: purchaseEnabled ?? this.purchaseEnabled,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      assets: assets ?? this.assets,
      optimisticTrainingManualFloor: clearOptimisticTrainingManualFloor
          ? null
          : (optimisticTrainingManualFloor ??
                this.optimisticTrainingManualFloor),
      energyPackUnitPrice: energyPackUnitPrice ?? this.energyPackUnitPrice,
      trainingManualUnitPrice:
          trainingManualUnitPrice ?? this.trainingManualUnitPrice,
      pendingCreditType: clearPendingCredit
          ? null
          : (pendingCreditType ?? this.pendingCreditType),
      weeklyStats: weeklyStats ?? this.weeklyStats,
      deployedActors: deployedActors ?? this.deployedActors,
      upgradeableCount: upgradeableCount ?? this.upgradeableCount,
      staminaLimit: staminaLimit ?? this.staminaLimit,
      actorNftConfig: actorNftConfig ?? this.actorNftConfig,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      lastSyncReason: lastSyncReason ?? this.lastSyncReason,
    );
  }

  static String _formatCount(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  List<Object?> get props => [
    isLoading,
    isRefreshing,
    isDirty,
    isPurchasing,
    purchaseEnabled,
    lastError,
    assets,
    optimisticTrainingManualFloor,
    energyPackUnitPrice,
    trainingManualUnitPrice,
    pendingCreditType,
    weeklyStats,
    deployedActors,
    upgradeableCount,
    staminaLimit,
    actorNftConfig,
    lastSuccessfulSyncAt,
    lastSyncReason,
  ];
}
