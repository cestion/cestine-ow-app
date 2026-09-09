import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'init_config_model.g.dart';

@JsonSerializable()
class InitClaimConfig extends Equatable {
  final String? fee;
  final String? chain;
  final String? symbol;

  const InitClaimConfig({this.fee, this.chain, this.symbol});

  factory InitClaimConfig.fromJson(Map<String, dynamic> json) =>
      _$InitClaimConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitClaimConfigToJson(this);

  @override
  List<Object?> get props => [fee, chain, symbol];
}

@JsonSerializable()
class InitDepositTokenConfig extends Equatable {
  final String? symbol;
  @JsonKey(fromJson: asString)
  final String? min;
  @JsonKey(fromJson: _parseScale)
  final int? scale;

  /// Credited amount = sendAmount × [exchangeRate] when rate is non-zero.
  /// Missing or `0` is treated as `1` (full credit).
  @JsonKey(name: 'exchange_rate', fromJson: asDouble)
  final double? exchangeRate;

  const InitDepositTokenConfig({
    this.symbol,
    this.min,
    this.scale,
    this.exchangeRate,
  });

  /// API may return `scale` as either int (2) or String ("2").
  /// Handles both to avoid decode failures.
  static int? _parseScale(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory InitDepositTokenConfig.fromJson(Map<String, dynamic> json) =>
      _$InitDepositTokenConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitDepositTokenConfigToJson(this);

  @override
  List<Object?> get props => [symbol, min, scale, exchangeRate];
}

@JsonSerializable()
class InitDepositConfig extends Equatable {
  final String? api;
  final String? chain;
  final String? chainType;
  final List<InitDepositTokenConfig>? tokens;

  const InitDepositConfig({this.api, this.chain, this.chainType, this.tokens});

  factory InitDepositConfig.fromJson(Map<String, dynamic> json) =>
      _$InitDepositConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitDepositConfigToJson(this);

  @override
  List<Object?> get props => [api, chain, chainType, tokens];
}

@JsonSerializable()
class InitWithdrawTokenConfig extends Equatable {
  @JsonKey(fromJson: asString)
  final String? fee;

  /// API may return number or string (test gateway uses ints).
  @JsonKey(fromJson: asString)
  final String? min;
  @JsonKey(fromJson: asString)
  final String? max;
  final int? type;
  final String? symbol;

  /// Available-balance display precision. Missing → app default (2).
  @JsonKey(fromJson: asInt)
  final int? scale;

  /// Amount-field / Max-fill precision. Missing → token default (USDC 5, STORY 2).
  @JsonKey(fromJson: asInt)
  final int? inputScale;

  const InitWithdrawTokenConfig({
    this.fee,
    this.min,
    this.max,
    this.type,
    this.symbol,
    this.scale,
    this.inputScale,
  });

  factory InitWithdrawTokenConfig.fromJson(Map<String, dynamic> json) =>
      _$InitWithdrawTokenConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitWithdrawTokenConfigToJson(this);

  @override
  List<Object?> get props => [fee, min, max, type, symbol, scale, inputScale];
}

@JsonSerializable()
class InitWithdrawConfig extends Equatable {
  final String? chain;
  final List<InitWithdrawTokenConfig>? tokens;

  const InitWithdrawConfig({this.chain, this.tokens});

  factory InitWithdrawConfig.fromJson(Map<String, dynamic> json) =>
      _$InitWithdrawConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitWithdrawConfigToJson(this);

  @override
  List<Object?> get props => [chain, tokens];
}

@JsonSerializable()
class InitActorNftUpgradeConfig extends Equatable {
  /// 目标等级
  @JsonKey(fromJson: asInt)
  final int? toLevel;

  /// 所需材料数量
  @JsonKey(fromJson: asInt)
  final int? requiredMaterialCount;

  /// 热度阈值（参演短剧累计完播）
  @JsonKey(fromJson: asInt)
  final int? heatThreshold;

  /// 升级所需训练手册数量。
  ///
  /// 这是独立于 [heatThreshold] 的消耗项，两者不能互相回退。
  @JsonKey(fromJson: asInt)
  final int? trainingManualAmount;

  /// 升级费用 (USDC)
  @JsonKey(fromJson: asDouble)
  final double? fee;

  const InitActorNftUpgradeConfig({
    this.toLevel,
    this.requiredMaterialCount,
    this.heatThreshold,
    this.trainingManualAmount,
    this.fee,
  });

  factory InitActorNftUpgradeConfig.fromJson(Map<String, dynamic> json) =>
      _$InitActorNftUpgradeConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitActorNftUpgradeConfigToJson(this);

  @override
  List<Object?> get props => [
    toLevel,
    requiredMaterialCount,
    heatThreshold,
    trainingManualAmount,
    fee,
  ];
}

@JsonSerializable()
class InitActorNftLevelConfig extends Equatable {
  final String? name;
  @JsonKey(fromJson: asDouble)
  final double? supplyFee;
  @JsonKey(fromJson: asDouble)
  final double? miningCoefficient;

  /// 升级到/处于该等级时配置的体力补给包数量。
  @JsonKey(fromJson: asInt)
  final int? staminaPackAmount;

  /// 下一级升级规则（与 web `InitActorNftUpgradeConfig` 对齐）
  final InitActorNftUpgradeConfig? upgrade;

  const InitActorNftLevelConfig({
    this.name,
    this.supplyFee,
    this.miningCoefficient,
    this.staminaPackAmount,
    this.upgrade,
  });

  factory InitActorNftLevelConfig.fromJson(Map<String, dynamic> json) =>
      _$InitActorNftLevelConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitActorNftLevelConfigToJson(this);

  @override
  List<Object?> get props => [
    name,
    supplyFee,
    miningCoefficient,
    staminaPackAmount,
    upgrade,
  ];
}

@JsonSerializable()
class InitActorNftConfig extends Equatable {
  @JsonKey(fromJson: asInt)
  final int? staminaLimit;

  @JsonKey(fromJson: asBool)
  final bool? fixedFullRefillPrice;

  /// 服务端字段沿用 `Minite` 拼写，不能改名，否则无法反序列化。
  @JsonKey(fromJson: asInt)
  final int? staminaCostPerMinite;

  @JsonKey(fromJson: asInt)
  final int? staminaRecoverPerHour;

  @JsonKey(fromJson: asBool)
  final bool? partialRefillSupported;

  @JsonKey(fromJson: asBool)
  final bool? upgradeInheritMainActorStamina;

  final Map<String, InitActorNftLevelConfig>? levels;

  const InitActorNftConfig({
    this.staminaLimit,
    this.fixedFullRefillPrice,
    this.staminaCostPerMinite,
    this.staminaRecoverPerHour,
    this.partialRefillSupported,
    this.upgradeInheritMainActorStamina,
    this.levels,
  });

  factory InitActorNftConfig.fromJson(Map<String, dynamic> json) =>
      _$InitActorNftConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitActorNftConfigToJson(this);

  double? supplyFeeForLevel(int? level) {
    return levelConfig(level)?.supplyFee;
  }

  /// 返回指定等级配置，供 UI/Controller 统一读取动态规则。
  InitActorNftLevelConfig? levelConfig(int? level) {
    if (level == null) return null;
    return levels?['$level'];
  }

  String? levelNameForLevel(int? level) => levelConfig(level)?.name;

  double? miningCoefficientForLevel(int? level) {
    return levelConfig(level)?.miningCoefficient;
  }

  /// 当前配置声明的最高演员等级。
  int? get maxConfiguredLevel {
    final keys = levels?.keys;
    if (keys == null || keys.isEmpty) return null;
    int? maxLevel;
    for (final key in keys) {
      final level = int.tryParse(key);
      if (level != null && (maxLevel == null || level > maxLevel)) {
        maxLevel = level;
      }
    }
    return maxLevel;
  }

  bool isMaxConfiguredLevel(int? level) {
    final maxLevel = maxConfiguredLevel;
    return level != null && maxLevel != null && level >= maxLevel;
  }

  /// 返回从指定等级开始升级时使用的规则。
  InitActorNftUpgradeConfig? upgradeConfigForLevel(int? level) {
    return levelConfig(level)?.upgrade;
  }

  /// 返回指定等级升级所需训练手册数量。
  ///
  /// `heatThreshold` 是累计完播门槛，语义不同，不能作为缺省值。
  int? trainingManualAmountForLevel(int? level) {
    return upgradeConfigForLevel(level)?.trainingManualAmount;
  }

  /// 返回指定等级升级所需同 IP、同等级角色数量。
  int? requiredMaterialCountForLevel(int? level) {
    return upgradeConfigForLevel(level)?.requiredMaterialCount;
  }

  /// 返回指定等级配置的体力补给包数量。
  int? staminaPackAmountForLevel(int? level) {
    return levelConfig(level)?.staminaPackAmount;
  }

  @override
  List<Object?> get props => [
    staminaLimit,
    fixedFullRefillPrice,
    staminaCostPerMinite,
    staminaRecoverPerHour,
    partialRefillSupported,
    upgradeInheritMainActorStamina,
    levels,
  ];
}

@JsonSerializable()
class InitMintConfig extends Equatable {
  final String? fee;

  const InitMintConfig({this.fee});

  factory InitMintConfig.fromJson(Map<String, dynamic> json) =>
      _$InitMintConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitMintConfigToJson(this);

  @override
  List<Object?> get props => [fee];
}

@JsonSerializable()
class InitMiningPercents extends Equatable {
  @JsonKey(fromJson: asInt)
  final int? team;
  @JsonKey(fromJson: asInt)
  final int? treasury;
  @JsonKey(fromJson: asInt)
  final int? investors;
  @JsonKey(fromJson: asInt)
  final int? liquidity;
  @JsonKey(fromJson: asInt)
  final int? nftMiningPool;
  @JsonKey(fromJson: asInt)
  final int? marketOperations;

  const InitMiningPercents({
    this.team,
    this.treasury,
    this.investors,
    this.liquidity,
    this.nftMiningPool,
    this.marketOperations,
  });

  factory InitMiningPercents.fromJson(Map<String, dynamic> json) =>
      _$InitMiningPercentsFromJson(json);

  Map<String, dynamic> toJson() => _$InitMiningPercentsToJson(this);

  @override
  List<Object?> get props => [
    team,
    treasury,
    investors,
    liquidity,
    nftMiningPool,
    marketOperations,
  ];
}

@JsonSerializable()
class InitMiningConfig extends Equatable {
  final InitMiningPercents? percents;
  final String? totalSupply;

  const InitMiningConfig({this.percents, this.totalSupply});

  factory InitMiningConfig.fromJson(Map<String, dynamic> json) =>
      _$InitMiningConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitMiningConfigToJson(this);

  @override
  List<Object?> get props => [percents, totalSupply];
}

@JsonSerializable()
class InitConsumableItemPrice extends Equatable {
  @JsonKey(fromJson: asString)
  final String? amount;
  final String? currency;

  const InitConsumableItemPrice({this.amount, this.currency});

  factory InitConsumableItemPrice.fromJson(Map<String, dynamic> json) =>
      _$InitConsumableItemPriceFromJson(json);

  Map<String, dynamic> toJson() => _$InitConsumableItemPriceToJson(this);

  @override
  List<Object?> get props => [amount, currency];
}

@JsonSerializable()
class InitConsumableItemConfig extends Equatable {
  final String? name;
  final InitConsumableItemPrice? price;
  final Map<String, int>? costsByLevel;

  const InitConsumableItemConfig({this.name, this.price, this.costsByLevel});

  factory InitConsumableItemConfig.fromJson(Map<String, dynamic> json) =>
      _$InitConsumableItemConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitConsumableItemConfigToJson(this);

  @override
  List<Object?> get props => [name, price, costsByLevel];
}

/// 当前后台 `miningItems.*.price` 结构。
@JsonSerializable()
class InitMiningItemPrice extends Equatable {
  @JsonKey(fromJson: asString)
  final String? usdc;

  const InitMiningItemPrice({this.usdc});

  factory InitMiningItemPrice.fromJson(Map<String, dynamic> json) =>
      _$InitMiningItemPriceFromJson(json);

  Map<String, dynamic> toJson() => _$InitMiningItemPriceToJson(this);

  @override
  List<Object?> get props => [usdc];
}

@JsonSerializable()
class InitMiningItemConfig extends Equatable {
  final String? name;
  final InitMiningItemPrice? price;

  const InitMiningItemConfig({this.name, this.price});

  factory InitMiningItemConfig.fromJson(Map<String, dynamic> json) =>
      _$InitMiningItemConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitMiningItemConfigToJson(this);

  @override
  List<Object?> get props => [name, price];
}

@JsonSerializable()
class InitConfig extends Equatable {
  final InitClaimConfig? claim;
  final List<String>? assets;
  final List<InitDepositConfig>? deposit;
  final List<InitWithdrawConfig>? withdraw;
  final InitActorNftConfig? actorNft;
  final InitMiningConfig? mining;
  final InitMintConfig? mint;
  final Map<String, InitMiningItemConfig>? miningItems;
  final Map<String, InitConsumableItemConfig>? consumableItems;

  const InitConfig({
    this.claim,
    this.assets,
    this.deposit,
    this.withdraw,
    this.actorNft,
    this.mining,
    this.mint,
    this.miningItems,
    this.consumableItems,
  });

  factory InitConfig.fromJson(Map<String, dynamic> json) =>
      _$InitConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InitConfigToJson(this);

  @override
  List<Object?> get props => [
    claim,
    assets,
    deposit,
    withdraw,
    actorNft,
    mining,
    mint,
    miningItems,
    consumableItems,
  ];
}
