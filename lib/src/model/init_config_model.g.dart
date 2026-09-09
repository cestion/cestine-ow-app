// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'init_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitClaimConfig _$InitClaimConfigFromJson(Map<String, dynamic> json) =>
    InitClaimConfig(
      fee: json['fee'] as String?,
      chain: json['chain'] as String?,
      symbol: json['symbol'] as String?,
    );

Map<String, dynamic> _$InitClaimConfigToJson(InitClaimConfig instance) =>
    <String, dynamic>{
      'fee': instance.fee,
      'chain': instance.chain,
      'symbol': instance.symbol,
    };

InitDepositTokenConfig _$InitDepositTokenConfigFromJson(
  Map<String, dynamic> json,
) => InitDepositTokenConfig(
  symbol: json['symbol'] as String?,
  min: asString(json['min']),
  scale: InitDepositTokenConfig._parseScale(json['scale']),
  exchangeRate: asDouble(json['exchange_rate']),
);

Map<String, dynamic> _$InitDepositTokenConfigToJson(
  InitDepositTokenConfig instance,
) => <String, dynamic>{
  'symbol': instance.symbol,
  'min': instance.min,
  'scale': instance.scale,
  'exchange_rate': instance.exchangeRate,
};

InitDepositConfig _$InitDepositConfigFromJson(Map<String, dynamic> json) =>
    InitDepositConfig(
      api: json['api'] as String?,
      chain: json['chain'] as String?,
      chainType: json['chainType'] as String?,
      tokens: (json['tokens'] as List<dynamic>?)
          ?.map(
            (e) => InitDepositTokenConfig.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$InitDepositConfigToJson(InitDepositConfig instance) =>
    <String, dynamic>{
      'api': instance.api,
      'chain': instance.chain,
      'chainType': instance.chainType,
      'tokens': instance.tokens,
    };

InitWithdrawTokenConfig _$InitWithdrawTokenConfigFromJson(
  Map<String, dynamic> json,
) => InitWithdrawTokenConfig(
  fee: asString(json['fee']),
  min: asString(json['min']),
  max: asString(json['max']),
  type: (json['type'] as num?)?.toInt(),
  symbol: json['symbol'] as String?,
  scale: asInt(json['scale']),
  inputScale: asInt(json['inputScale']),
);

Map<String, dynamic> _$InitWithdrawTokenConfigToJson(
  InitWithdrawTokenConfig instance,
) => <String, dynamic>{
  'fee': instance.fee,
  'min': instance.min,
  'max': instance.max,
  'type': instance.type,
  'symbol': instance.symbol,
  'scale': instance.scale,
  'inputScale': instance.inputScale,
};

InitWithdrawConfig _$InitWithdrawConfigFromJson(Map<String, dynamic> json) =>
    InitWithdrawConfig(
      chain: json['chain'] as String?,
      tokens: (json['tokens'] as List<dynamic>?)
          ?.map(
            (e) => InitWithdrawTokenConfig.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$InitWithdrawConfigToJson(InitWithdrawConfig instance) =>
    <String, dynamic>{'chain': instance.chain, 'tokens': instance.tokens};

InitActorNftUpgradeConfig _$InitActorNftUpgradeConfigFromJson(
  Map<String, dynamic> json,
) => InitActorNftUpgradeConfig(
  toLevel: asInt(json['toLevel']),
  requiredMaterialCount: asInt(json['requiredMaterialCount']),
  heatThreshold: asInt(json['heatThreshold']),
  trainingManualAmount: asInt(json['trainingManualAmount']),
  fee: asDouble(json['fee']),
);

Map<String, dynamic> _$InitActorNftUpgradeConfigToJson(
  InitActorNftUpgradeConfig instance,
) => <String, dynamic>{
  'toLevel': instance.toLevel,
  'requiredMaterialCount': instance.requiredMaterialCount,
  'heatThreshold': instance.heatThreshold,
  'trainingManualAmount': instance.trainingManualAmount,
  'fee': instance.fee,
};

InitActorNftLevelConfig _$InitActorNftLevelConfigFromJson(
  Map<String, dynamic> json,
) => InitActorNftLevelConfig(
  name: json['name'] as String?,
  supplyFee: asDouble(json['supplyFee']),
  miningCoefficient: asDouble(json['miningCoefficient']),
  staminaPackAmount: asInt(json['staminaPackAmount']),
  upgrade: json['upgrade'] == null
      ? null
      : InitActorNftUpgradeConfig.fromJson(
          json['upgrade'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$InitActorNftLevelConfigToJson(
  InitActorNftLevelConfig instance,
) => <String, dynamic>{
  'name': instance.name,
  'supplyFee': instance.supplyFee,
  'miningCoefficient': instance.miningCoefficient,
  'staminaPackAmount': instance.staminaPackAmount,
  'upgrade': instance.upgrade,
};

InitActorNftConfig _$InitActorNftConfigFromJson(Map<String, dynamic> json) =>
    InitActorNftConfig(
      staminaLimit: asInt(json['staminaLimit']),
      fixedFullRefillPrice: asBool(json['fixedFullRefillPrice']),
      staminaCostPerMinite: asInt(json['staminaCostPerMinite']),
      staminaRecoverPerHour: asInt(json['staminaRecoverPerHour']),
      partialRefillSupported: asBool(json['partialRefillSupported']),
      upgradeInheritMainActorStamina: asBool(
        json['upgradeInheritMainActorStamina'],
      ),
      levels: (json['levels'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          InitActorNftLevelConfig.fromJson(e as Map<String, dynamic>),
        ),
      ),
    );

Map<String, dynamic> _$InitActorNftConfigToJson(InitActorNftConfig instance) =>
    <String, dynamic>{
      'staminaLimit': instance.staminaLimit,
      'fixedFullRefillPrice': instance.fixedFullRefillPrice,
      'staminaCostPerMinite': instance.staminaCostPerMinite,
      'staminaRecoverPerHour': instance.staminaRecoverPerHour,
      'partialRefillSupported': instance.partialRefillSupported,
      'upgradeInheritMainActorStamina': instance.upgradeInheritMainActorStamina,
      'levels': instance.levels,
    };

InitMintConfig _$InitMintConfigFromJson(Map<String, dynamic> json) =>
    InitMintConfig(fee: json['fee'] as String?);

Map<String, dynamic> _$InitMintConfigToJson(InitMintConfig instance) =>
    <String, dynamic>{'fee': instance.fee};

InitMiningPercents _$InitMiningPercentsFromJson(Map<String, dynamic> json) =>
    InitMiningPercents(
      team: asInt(json['team']),
      treasury: asInt(json['treasury']),
      investors: asInt(json['investors']),
      liquidity: asInt(json['liquidity']),
      nftMiningPool: asInt(json['nftMiningPool']),
      marketOperations: asInt(json['marketOperations']),
    );

Map<String, dynamic> _$InitMiningPercentsToJson(InitMiningPercents instance) =>
    <String, dynamic>{
      'team': instance.team,
      'treasury': instance.treasury,
      'investors': instance.investors,
      'liquidity': instance.liquidity,
      'nftMiningPool': instance.nftMiningPool,
      'marketOperations': instance.marketOperations,
    };

InitMiningConfig _$InitMiningConfigFromJson(Map<String, dynamic> json) =>
    InitMiningConfig(
      percents: json['percents'] == null
          ? null
          : InitMiningPercents.fromJson(
              json['percents'] as Map<String, dynamic>,
            ),
      totalSupply: json['totalSupply'] as String?,
    );

Map<String, dynamic> _$InitMiningConfigToJson(InitMiningConfig instance) =>
    <String, dynamic>{
      'percents': instance.percents,
      'totalSupply': instance.totalSupply,
    };

InitConsumableItemPrice _$InitConsumableItemPriceFromJson(
  Map<String, dynamic> json,
) => InitConsumableItemPrice(
  amount: asString(json['amount']),
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$InitConsumableItemPriceToJson(
  InitConsumableItemPrice instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'currency': instance.currency,
};

InitConsumableItemConfig _$InitConsumableItemConfigFromJson(
  Map<String, dynamic> json,
) => InitConsumableItemConfig(
  name: json['name'] as String?,
  price: json['price'] == null
      ? null
      : InitConsumableItemPrice.fromJson(json['price'] as Map<String, dynamic>),
  costsByLevel: (json['costsByLevel'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toInt()),
  ),
);

Map<String, dynamic> _$InitConsumableItemConfigToJson(
  InitConsumableItemConfig instance,
) => <String, dynamic>{
  'name': instance.name,
  'price': instance.price,
  'costsByLevel': instance.costsByLevel,
};

InitMiningItemPrice _$InitMiningItemPriceFromJson(Map<String, dynamic> json) =>
    InitMiningItemPrice(usdc: asString(json['usdc']));

Map<String, dynamic> _$InitMiningItemPriceToJson(
  InitMiningItemPrice instance,
) => <String, dynamic>{'usdc': instance.usdc};

InitMiningItemConfig _$InitMiningItemConfigFromJson(
  Map<String, dynamic> json,
) => InitMiningItemConfig(
  name: json['name'] as String?,
  price: json['price'] == null
      ? null
      : InitMiningItemPrice.fromJson(json['price'] as Map<String, dynamic>),
);

Map<String, dynamic> _$InitMiningItemConfigToJson(
  InitMiningItemConfig instance,
) => <String, dynamic>{'name': instance.name, 'price': instance.price};

InitConfig _$InitConfigFromJson(Map<String, dynamic> json) => InitConfig(
  claim: json['claim'] == null
      ? null
      : InitClaimConfig.fromJson(json['claim'] as Map<String, dynamic>),
  assets: (json['assets'] as List<dynamic>?)?.map((e) => e as String).toList(),
  deposit: (json['deposit'] as List<dynamic>?)
      ?.map((e) => InitDepositConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
  withdraw: (json['withdraw'] as List<dynamic>?)
      ?.map((e) => InitWithdrawConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
  actorNft: json['actorNft'] == null
      ? null
      : InitActorNftConfig.fromJson(json['actorNft'] as Map<String, dynamic>),
  mining: json['mining'] == null
      ? null
      : InitMiningConfig.fromJson(json['mining'] as Map<String, dynamic>),
  mint: json['mint'] == null
      ? null
      : InitMintConfig.fromJson(json['mint'] as Map<String, dynamic>),
  miningItems: (json['miningItems'] as Map<String, dynamic>?)?.map(
    (k, e) =>
        MapEntry(k, InitMiningItemConfig.fromJson(e as Map<String, dynamic>)),
  ),
  consumableItems: (json['consumableItems'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(
      k,
      InitConsumableItemConfig.fromJson(e as Map<String, dynamic>),
    ),
  ),
);

Map<String, dynamic> _$InitConfigToJson(InitConfig instance) =>
    <String, dynamic>{
      'claim': instance.claim,
      'assets': instance.assets,
      'deposit': instance.deposit,
      'withdraw': instance.withdraw,
      'actorNft': instance.actorNft,
      'mining': instance.mining,
      'mint': instance.mint,
      'miningItems': instance.miningItems,
      'consumableItems': instance.consumableItems,
    };
