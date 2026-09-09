import '../model/models.dart';

/// Deep JSON codec shared by config caches. Generated `toJson()` methods do
/// not recursively encode every nested config model.
Map<String, dynamic> globalConfigToJson(GlobalConfig config) {
  return {
    'chainlinks': config.chainlinks?.map(
      (key, chain) => MapEntry(key, _chainInfoToJson(chain)),
    ),
    'init': config.init == null ? null : _initConfigToJson(config.init!),
    'mini-drama': config.miniDrama == null
        ? null
        : _miniDramaConfigToJson(config.miniDrama!),
    'banner': config.banner == null
        ? null
        : {
            'enabled': config.banner!.enabled,
            'items': config.banner!.items
                ?.map((item) => item.toJson())
                .toList(),
          },
  };
}

Map<String, dynamic> _initConfigToJson(InitConfig config) {
  return {
    'claim': config.claim?.toJson(),
    'assets': config.assets,
    'deposit': config.deposit
        ?.map(
          (item) => {
            'api': item.api,
            'chain': item.chain,
            'chainType': item.chainType,
            'tokens': item.tokens?.map((token) => token.toJson()).toList(),
          },
        )
        .toList(),
    'withdraw': config.withdraw
        ?.map(
          (item) => {
            'chain': item.chain,
            'tokens': item.tokens?.map((token) => token.toJson()).toList(),
          },
        )
        .toList(),
    'actorNft': config.actorNft == null
        ? null
        : {
            'staminaLimit': config.actorNft!.staminaLimit,
            'fixedFullRefillPrice': config.actorNft!.fixedFullRefillPrice,
            'staminaCostPerMinite': config.actorNft!.staminaCostPerMinite,
            'staminaRecoverPerHour': config.actorNft!.staminaRecoverPerHour,
            'partialRefillSupported': config.actorNft!.partialRefillSupported,
            'upgradeInheritMainActorStamina':
                config.actorNft!.upgradeInheritMainActorStamina,
            'levels': config.actorNft!.levels?.map(
              (key, level) => MapEntry(key, {
                'name': level.name,
                'supplyFee': level.supplyFee,
                'miningCoefficient': level.miningCoefficient,
                'staminaPackAmount': level.staminaPackAmount,
                'upgrade': level.upgrade?.toJson(),
              }),
            ),
          },
    'mining': config.mining == null
        ? null
        : {
            'percents': config.mining!.percents?.toJson(),
            'totalSupply': config.mining!.totalSupply,
          },
    'mint': config.mint?.toJson(),
    'miningItems': config.miningItems?.map(
      (key, item) =>
          MapEntry(key, {'name': item.name, 'price': item.price?.toJson()}),
    ),
    'consumableItems': config.consumableItems?.map(
      (key, item) => MapEntry(key, {
        'name': item.name,
        'price': item.price?.toJson(),
        'costsByLevel': item.costsByLevel,
      }),
    ),
  };
}

Map<String, dynamic> _miniDramaConfigToJson(MiniDramaConfig config) {
  return {
    'rebate_tiers': config.rebateTiers
        ?.map(
          (tier) => {
            'start_episode': tier.startEpisode,
            'end_episode': tier.endEpisode,
            'direct_inviter_rate': tier.directInviterRate,
            'indirect_inviter_rate': tier.indirectInviterRate,
          },
        )
        .toList(growable: false),
    'creator_rate_max': config.creatorRateMax,
    'default_creator_rate': config.defaultCreatorRate,
    'self_reward_usdt_rate': config.selfRewardUsdtRate,
    'usdt_to_points_rate': config.usdtToPointsRate,
    'point_cost_per_episode': config.pointCostPerEpisode,
    'bulk_unlock_discount_rate': config.bulkUnlockDiscountRate,
  };
}

Map<String, dynamic> _chainInfoToJson(ChainInfo chain) {
  return {
    'chainId': chain.chainId,
    'name': chain.name,
    'icon': chain.icon,
    'chainType': chain.chainType,
    'contracts': chain.contracts?.toJson(),
    'rpc': chain.rpc?.toJson(),
    'testnet': chain.testnet,
    'tokens': chain.tokens?.map((key, token) => MapEntry(key, token.toJson())),
  };
}
