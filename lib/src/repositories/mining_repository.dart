import 'package:meta/meta.dart';

import '../api/story_api_client.dart';
import '../core/cache_strategy.dart';
import '../core/json_helpers.dart';
import '../core/result.dart';
import '../data/repository/story_local_repository.dart';
import '../model/models.dart';

abstract class MiningRepository {
  Future<Result<List<MiningActor>>> listDeployedActors();
  Future<List<MiningActor>?> readCachedDeployedActors();
  Future<Result<List<MiningActor>>> refreshDeployedActors();
  Future<Result<MiningActorPage>> listAllActors({
    required String sort,
    int pageNum = 1,
    int pageSize = 100,
    bool excludeMaxLevel = false,
  });

  /// Bypasses list caches without mutating them; used to reconcile newly
  /// signed actor NFTs while the upgrade sheet remains open.
  Future<Result<MiningActorPage>> fetchAllActorsFromNetwork({
    required String sort,
    int pageSize = 100,
    bool excludeMaxLevel = false,
  });
  Future<MiningActorPage?> readCachedAllActors({
    required String sort,
    int pageSize = 100,
    bool excludeMaxLevel = false,
  });
  Future<Result<MiningActorPage>> refreshAllActors({
    required String sort,
    int pageSize = 100,
    bool excludeMaxLevel = false,
  });

  /// 获取当前真正满足升级条件的演员数量。
  Future<Result<int>> getUpgradeableActorCount();

  Future<Result<MiningActorPage>> listRestActors({
    int pageNum = 1,
    int pageSize = 100,
  });
  Future<MiningActorPage?> readCachedRestActors({
    int pageNum = 1,
    int pageSize = 100,
  });
  Future<Result<MiningActorPage>> refreshRestActors({
    int pageNum = 1,
    int pageSize = 100,
  });
  Future<Result<void>> deployActor(String actorNftId);

  /// 派遣全部可派遣演员，返回实际安排演出的演员列表。
  ///
  /// 服务端返回空列表表示当前没有体力可用的候场演员。
  Future<Result<List<MiningActor>>> deployAllActors();

  Future<Result<void>> restActor(String actorNftId);
  Future<Result<void>> restAllActors();
  Future<Result<ReplenishResult>> replenishStamina({
    required String actorNftId,
    required double payAmount,
    required String walletAddress,
  });
  Future<Result<List<ActorNeedingStaminaRefill>>>
  listActorsNeedingStaminaRefill();
  Future<Result<ReplenishBatchResult>> replenishStaminaBatch(
    ReplenishStaminaBatchRequest request,
  );

  /// Centrally consumes stamina packs and restores one actor to its limit.
  ///
  /// Kept separate from the legacy V2 chain-order API so the V3 UI can adopt
  /// the new contract without changing the existing V2 flow.
  Future<Result<StaminaRefillResult>> replenishStaminaWithPack({
    required String actorNftId,
  });

  /// Centrally consumes stamina packs and restores the requested actors.
  /// Omitting [StaminaRefillBatchRequest.items], or passing an empty list,
  /// lets the backend select all eligible actors owned by the current user.
  Future<Result<StaminaRefillBatchResult>> replenishStaminaBatchWithPack(
    StaminaRefillBatchRequest request,
  );

  /// 获取演员升级可用耗材列表（同IP同等级待消耗演员），首项含升级需求。
  Future<Result<List<ActorUpgradeMaterial>>> getUpgradeMaterials({
    required String actorNftId,
  });

  /// 只读预估演员 NFT 的回收返还，不创建订单或变更资产。
  Future<Result<ActorNftRecycleEstimateResponse>> getActorNftRecycleEstimate({
    required String nftAddress,
  });

  /// 仅创建演员 NFT 回收签名订单，不销毁 NFT 或直接返还资产。
  Future<Result<ActorNftRecycleOrderResponse>> createActorNftRecycleOrder({
    required String toAddress,
    required String nftAddress,
  });

  /// 创建演员 NFT 升级订单，返回合约调用签名
  Future<Result<ActorUpgradeOrderResponse>> createUpgradeOrder({
    required int actorCollectionId,
    required String walletAddress,
    required int mainNftTokenId,
    required List<int> burnNftTokenIds,
  });

  /// Evict cached game workshop reads (pull-to-refresh / after mutations).
  Future<void> invalidateGameCache();

  /// Clear all game caches (deployed/rest/all actors are per-user).
  /// Cache keys do not include the user id, so these must be dropped on
  /// login/logout.
  Future<void> clearUserScopedCaches();

  Future<void> dispose();
}

class MiningRepositoryImpl implements MiningRepository {
  static const _defaultRestPageSize = 100;
  static const _gameSorts = ['LEVEL', 'HEAT', 'STAMINA', 'COMPUTING_POWER'];

  @visibleForTesting
  static const restActorsCacheTtl = Duration(hours: 1);

  final StoryApiClient _api;
  final StoryLocalRepository? _local;

  late final CacheChain<String, List<MiningActor>> _deployedCache;
  late final CacheChain<String, MiningActorPage> _allActorsCache;
  late final CacheChain<String, MiningActorPage> _restActorsCache;
  late final MemoryCacheLayer<String, List<MiningActor>> _deployedMemory;
  late final MemoryCacheLayer<String, MiningActorPage> _allActorsMemory;
  late final MemoryCacheLayer<String, MiningActorPage> _restActorsMemory;

  MiningRepositoryImpl(this._api, [this._local]) {
    _deployedMemory = MemoryCacheLayer(maxEntries: 2);
    _allActorsMemory = MemoryCacheLayer(maxEntries: 8);
    _restActorsMemory = MemoryCacheLayer(
      maxEntries: 2,
      defaultTtl: restActorsCacheTtl,
    );

    final local = _local;
    final deployedHive = local == null
        ? null
        : HiveCacheLayer<List<MiningActor>>(
            box: local.cacheBox,
            prefix: 'mining_deployed_',
            decoder: _decodeMiningActorList,
            encoder: _encodeMiningActorList,
          );
    final allActorsHive = local == null
        ? null
        : HiveCacheLayer<MiningActorPage>(
            box: local.cacheBox,
            prefix: 'mining_all_',
            decoder: _decodeMiningActorPage,
            encoder: _encodeMiningActorPage,
          );
    _deployedCache = CacheChain(
      fetcher: (_) => _fetchDeployedActors(),
      readLayers: [_deployedMemory, ?deployedHive],
      writeLayers: [_deployedMemory, ?deployedHive],
    );
    _allActorsCache = CacheChain(
      fetcher: _fetchAllActors,
      readLayers: [_allActorsMemory, ?allActorsHive],
      writeLayers: [_allActorsMemory, ?allActorsHive],
    );
    _restActorsCache = CacheChain(
      fetcher: _fetchRestActors,
      // 候场状态变化频繁，只在当前 App 会话内缓存。冷启动离线时允许
      // 加载失败，避免短暂展示上次运行留下的过期候场、体力或演出状态。
      readLayers: [_restActorsMemory],
      writeLayers: [_restActorsMemory],
    );
  }

  static List<MiningActor> _decodeMiningActorList(Object? data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => MiningActor.fromJson(deepStringMap(item)))
        .toList();
  }

  static List<Map<String, dynamic>> _encodeMiningActorList(
    List<MiningActor> actors,
  ) => actors.map((actor) => actor.toJson()).toList();

  static MiningActorPage _decodeMiningActorPage(Object? data) {
    final json = deepStringMap(data);
    final rawRecords = json['records'];
    final records = <MiningActor>[];
    if (rawRecords is List) {
      for (final item in rawRecords) {
        if (item is Map<String, dynamic>) {
          records.add(MiningActor.fromJson(item));
        } else if (item is Map) {
          records.add(MiningActor.fromJson(deepStringMap(item)));
        }
      }
    }
    return MiningActorPage(
      records: records,
      pageNumber: asIntOrNull(json['pageNumber']) ?? 1,
      pageSize: asIntOrNull(json['pageSize']) ?? records.length,
      totalPage: asIntOrNull(json['totalPage']) ?? 0,
      totalRow: asIntOrNull(json['totalRow']) ?? records.length,
    );
  }

  static Map<String, dynamic> _encodeMiningActorPage(MiningActorPage page) =>
      <String, dynamic>{
        'records': page.records.map((actor) => actor.toJson()).toList(),
        'pageNumber': page.pageNumber,
        'pageSize': page.pageSize,
        'totalPage': page.totalPage,
        'totalRow': page.totalRow,
      };

  static MiningActorPage _parseActorPage(dynamic d) {
    final json = normalizeJson(d);
    final rawRecords = json['records'];
    final records = <MiningActor>[];
    if (rawRecords is List) {
      for (final item in rawRecords) {
        if (item is Map<String, dynamic>) {
          records.add(MiningActor.fromJson(item));
        }
      }
    }
    return MiningActorPage(
      records: records,
      pageNumber: asIntOrNull(json['pageNumber']) ?? 1,
      pageSize: asIntOrNull(json['pageSize']) ?? records.length,
      totalPage: asIntOrNull(json['totalPage']) ?? 0,
      totalRow: asIntOrNull(json['totalRow']) ?? records.length,
    );
  }

  static String _deployedKey() => 'deployed';

  static String _allActorsKey(
    String sort,
    int pageSize,
    bool excludeMaxLevel,
  ) => '$sort|1|$pageSize|${excludeMaxLevel ? 1 : 0}';

  /// Key format: `${sort}|1|$pageSize|$excludeFlag`, where the flag is `0` or
  /// `1` (sort may contain `_`, e.g. COMPUTING_POWER). The last segment keeps
  /// filtered and unfiltered pages from sharing a cache entry.
  static ({String sort, int pageSize, bool excludeMaxLevel})?
  _parseAllActorsKey(String key) {
    final parts = key.split('|');
    if (parts.length != 4) return null;
    final sort = parts[0];
    final pageSize = int.tryParse(parts[2]);
    final excludeMaxLevel = switch (parts[3]) {
      '0' => false,
      '1' => true,
      _ => null,
    };
    if (sort.isEmpty || pageSize == null || excludeMaxLevel == null) {
      return null;
    }
    return (sort: sort, pageSize: pageSize, excludeMaxLevel: excludeMaxLevel);
  }

  /// Test-only accessors for cache-key encoding.
  @visibleForTesting
  static String debugAllActorsKey(
    String sort,
    int pageSize, {
    bool excludeMaxLevel = false,
  }) => _allActorsKey(sort, pageSize, excludeMaxLevel);

  @visibleForTesting
  static ({String sort, int pageSize, bool excludeMaxLevel})?
  debugParseAllActorsKey(String key) => _parseAllActorsKey(key);

  static String _restActorsKey(int pageNum, int pageSize) =>
      '${pageNum}_$pageSize';

  Future<Result<List<MiningActor>>> _fetchDeployedActors() => _api.safeGet(
    '/api/mining/listDeployedActors',
    decoder: (d) => parseList<MiningActor>(d, MiningActor.fromJson),
  );

  Future<Result<MiningActorPage>> _fetchAllActors(String key) {
    final parsed = _parseAllActorsKey(key);
    if (parsed == null) {
      return Future.value(
        Result.failure(ApiError.parse('Invalid mining all-actors cache key')),
      );
    }
    return _api.safeGet(
      '/api/mining/listAllActors',
      query: {
        'sort': parsed.sort,
        'pageNum': '1',
        'pageSize': '${parsed.pageSize}',
        'excludeMaxLevel': '${parsed.excludeMaxLevel}',
      },
      decoder: _parseActorPage,
    );
  }

  Future<Result<MiningActorPage>> _fetchRestActors(String key) {
    final parts = key.split('_');
    if (parts.length < 2) {
      return Future.value(
        Result.failure(ApiError.parse('Invalid mining rest-actors cache key')),
      );
    }
    final pageNum = int.tryParse(parts[0]) ?? 1;
    final pageSize = int.tryParse(parts[1]) ?? _defaultRestPageSize;
    return _api.safeGet(
      '/api/mining/listRestActors',
      query: {'pageNum': '$pageNum', 'pageSize': '$pageSize'},
      decoder: _parseActorPage,
    );
  }

  @override
  Future<Result<List<MiningActor>>> listDeployedActors() =>
      _deployedCache.get(_deployedKey());

  @override
  Future<List<MiningActor>?> readCachedDeployedActors() =>
      _deployedCache.getCachedOnly(_deployedKey());

  @override
  Future<Result<List<MiningActor>>> refreshDeployedActors() async {
    final result = await _fetchDeployedActors();
    final actors = result.dataOrNull;
    if (result.isSuccess && actors != null) {
      await _deployedCache.put(_deployedKey(), actors);
    }
    return result;
  }

  @override
  Future<Result<MiningActorPage>> listAllActors({
    required String sort,
    int pageNum = 1,
    int pageSize = 100,
    bool excludeMaxLevel = false,
  }) {
    if (pageNum == 1) {
      return _allActorsCache.get(
        _allActorsKey(sort, pageSize, excludeMaxLevel),
      );
    }
    return _api.safeGet(
      '/api/mining/listAllActors',
      query: {
        'sort': sort,
        'pageNum': '$pageNum',
        'pageSize': '$pageSize',
        'excludeMaxLevel': '$excludeMaxLevel',
      },
      decoder: _parseActorPage,
    );
  }

  @override
  Future<MiningActorPage?> readCachedAllActors({
    required String sort,
    int pageSize = 100,
    bool excludeMaxLevel = false,
  }) => _allActorsCache.getCachedOnly(
    _allActorsKey(sort, pageSize, excludeMaxLevel),
  );

  @override
  Future<Result<MiningActorPage>> refreshAllActors({
    required String sort,
    int pageSize = 100,
    bool excludeMaxLevel = false,
  }) async {
    final key = _allActorsKey(sort, pageSize, excludeMaxLevel);
    final result = await _fetchAllActors(key);
    final page = result.dataOrNull;
    if (result.isSuccess && page != null) {
      await _allActorsCache.put(key, page);
    }
    return result;
  }

  @override
  Future<Result<MiningActorPage>> fetchAllActorsFromNetwork({
    required String sort,
    int pageSize = 100,
    bool excludeMaxLevel = false,
  }) => _fetchAllActors(_allActorsKey(sort, pageSize, excludeMaxLevel));

  @override
  Future<Result<int>> getUpgradeableActorCount() => _api.safeGet(
    '/api/mining/actorLevelUpgrade/upgradableCount',
    decoder: (data) {
      final count = asIntOrNull(normalizeJson(data)['count']);
      if (count == null || count < 0) {
        throw const FormatException(
          'Missing or invalid count in upgradeable actor response',
        );
      }
      return count;
    },
  );

  @override
  Future<Result<MiningActorPage>> listRestActors({
    int pageNum = 1,
    int pageSize = 100,
  }) {
    if (pageNum == 1) {
      return _restActorsCache.get(_restActorsKey(pageNum, pageSize));
    }
    return _api.safeGet(
      '/api/mining/listRestActors',
      query: {'pageNum': '$pageNum', 'pageSize': '$pageSize'},
      decoder: _parseActorPage,
    );
  }

  @override
  Future<MiningActorPage?> readCachedRestActors({
    int pageNum = 1,
    int pageSize = 100,
  }) {
    if (pageNum != 1) return Future.value();
    return _restActorsCache.getCachedOnly(_restActorsKey(pageNum, pageSize));
  }

  @override
  Future<Result<MiningActorPage>> refreshRestActors({
    int pageNum = 1,
    int pageSize = 100,
  }) async {
    final key = _restActorsKey(pageNum, pageSize);
    final result = await _fetchRestActors(key);
    final page = result.dataOrNull;
    if (pageNum == 1 && result.isSuccess && page != null) {
      await _restActorsCache.put(key, page);
    }
    return result;
  }

  @override
  Future<void> invalidateGameCache() async {
    final evictions = <Future<void>>[
      _deployedCache.evict(_deployedKey()),
      _restActorsCache.clear(),
      for (final sort in _gameSorts)
        for (final excludeMaxLevel in [false, true])
          _allActorsCache.evict(_allActorsKey(sort, 20, excludeMaxLevel)),
      // The V2 app bar count uses a one-record page.
      _allActorsCache.evict(_allActorsKey('LEVEL', 1, true)),
    ];
    await Future.wait(evictions);
  }

  Future<void> _invalidateAfterMutation() => invalidateGameCache();

  @override
  Future<void> clearUserScopedCaches() async {
    await Future.wait([
      _deployedCache.clear(),
      _allActorsCache.clear(),
      _restActorsCache.clear(),
    ]);
  }

  @override
  Future<Result<void>> deployActor(String actorNftId) async {
    final result = await _api.safePost(
      '/api/mining/deployActor',
      body: {'actorNftId': actorNftId},
      decoder: (_) {},
    );
    if (result.isSuccess) {
      await _invalidateAfterMutation();
    }
    return result;
  }

  @override
  Future<Result<List<MiningActor>>> deployAllActors() async {
    final result = await _api.safePost(
      '/api/mining/deployAllActor',
      decoder: (d) => parseList(d, MiningActor.fromJson),
    );
    if (result.isSuccess) {
      await _invalidateAfterMutation();
    }
    return result;
  }

  @override
  Future<Result<void>> restActor(String actorNftId) async {
    final result = await _api.safePost(
      '/api/mining/restActor',
      body: {'actorNftId': actorNftId},
      decoder: (_) {},
    );
    if (result.isSuccess) {
      await _invalidateAfterMutation();
    }
    return result;
  }

  @override
  Future<Result<void>> restAllActors() async {
    final result = await _api.safePost(
      '/api/mining/restAllActor',
      decoder: (_) {},
    );
    if (result.isSuccess) {
      await _invalidateAfterMutation();
    }
    return result;
  }

  @override
  Future<Result<ReplenishResult>> replenishStamina({
    required String actorNftId,
    required double payAmount,
    required String walletAddress,
  }) async {
    final result = await _api.safePost(
      '/api/mining/replenishStamina',
      body: {
        'actorNftId': actorNftId,
        'payAmount': payAmount,
        'walletAddress': walletAddress,
      },
      decoder: (d) => ReplenishResult.fromJson(normalizeJson(d)),
    );
    if (result.isSuccess) {
      await _invalidateAfterMutation();
    }
    return result;
  }

  @override
  Future<Result<ReplenishBatchResult>> replenishStaminaBatch(
    ReplenishStaminaBatchRequest request,
  ) async {
    final result = await _api.safePost(
      '/api/mining/replenishStaminaBatch',
      body: request.toJson(),
      decoder: decodeWith(ReplenishBatchResult.fromJson),
    );
    if (result.isSuccess) {
      await _invalidateAfterMutation();
    }
    return result;
  }

  @override
  Future<Result<StaminaRefillResult>> replenishStaminaWithPack({
    required String actorNftId,
  }) async {
    final normalizedActorNftId = actorNftId.trim();
    final result = await _api.safePost(
      '/api/mining/replenishStamina',
      body: {'actorNftId': normalizedActorNftId},
      decoder: (data) {
        final refill = decodeWith(StaminaRefillResult.fromJson)(data);
        if (refill.actorNftId.trim() != normalizedActorNftId) {
          throw const FormatException(
            'Refill response actorNftId does not match request',
          );
        }
        return refill;
      },
    );
    if (result.isSuccess) {
      await _invalidateAfterMutation();
    }
    return result;
  }

  @override
  Future<Result<StaminaRefillBatchResult>> replenishStaminaBatchWithPack(
    StaminaRefillBatchRequest request,
  ) async {
    final result = await _api.safePost(
      '/api/mining/replenishStaminaBatch',
      body: request.toJson(),
      decoder: decodeWith(StaminaRefillBatchResult.fromJson),
    );
    if (result.isSuccess) {
      await _invalidateAfterMutation();
    }
    return result;
  }

  @override
  Future<Result<List<ActorNeedingStaminaRefill>>>
  listActorsNeedingStaminaRefill() => _api.safeGet(
    '/api/mining/listActorsNeedingStaminaRefill',
    decoder: (d) => parseList(d, ActorNeedingStaminaRefill.fromJson),
  );

  @override
  Future<Result<List<ActorUpgradeMaterial>>> getUpgradeMaterials({
    required String actorNftId,
  }) {
    return _api.safeGet(
      '/api/mining/actorLevelUpgrade/materials',
      query: {'actorNftId': actorNftId.trim()},
      decoder: (d) => parseList(d, ActorUpgradeMaterial.fromJson),
    );
  }

  @override
  Future<Result<ActorNftRecycleEstimateResponse>> getActorNftRecycleEstimate({
    required String nftAddress,
  }) => _api.safeGet(
    '/api/userWallet/actorNft/recycleEstimate',
    query: {'nftAddress': nftAddress.trim()},
    decoder: decodeWith(ActorNftRecycleEstimateResponse.fromJson),
  );

  @override
  Future<Result<ActorNftRecycleOrderResponse>> createActorNftRecycleOrder({
    required String toAddress,
    required String nftAddress,
  }) => _api.safePost(
    '/api/userWallet/actorNft/recycleOrder',
    body: {'toAddress': toAddress.trim(), 'nftAddress': nftAddress.trim()},
    decoder: decodeWith(ActorNftRecycleOrderResponse.fromJson),
  );

  @override
  Future<Result<ActorUpgradeOrderResponse>> createUpgradeOrder({
    required int actorCollectionId,
    required String walletAddress,
    required int mainNftTokenId,
    required List<int> burnNftTokenIds,
  }) {
    return _api.safePost(
      '/api/userWallet/actorNft/upgradeOrder',
      body: {
        'actorCollectionId': actorCollectionId,
        'walletAddress': walletAddress.trim(),
        'mainNftTokenId': mainNftTokenId,
        'burnNftTokenIds': burnNftTokenIds,
      },
      decoder: (d) => ActorUpgradeOrderResponse.fromJson(normalizeJson(d)),
    );
  }

  @override
  Future<void> dispose() async {
    await _deployedMemory.clear();
    await _allActorsMemory.clear();
    await _restActorsMemory.clear();
  }
}
