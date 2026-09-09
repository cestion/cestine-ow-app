import '../core/cache_strategy.dart';
import '../core/result.dart';
import '../core/json_helpers.dart';
import '../data/repository/story_local_repository.dart';
import '../model/models.dart';
import '../api/story_api_client.dart';

/// Sort options matching backend / web `ListActorCollectionsSort`.
///
/// Plaza UI: Lv.1 片酬 (`computingPower`) · 价格 (`priceAsc`/`priceDesc`).
enum ActorCollectionSort {
  priceAsc('PRICE_ASC'),
  priceDesc('PRICE_DESC'),
  completedView('COMPLETED_VIEW'),
  heat('HEAT'),
  computingPower('computing_power');

  const ActorCollectionSort(this.value);
  final String value;

  bool get isPrice =>
      this == ActorCollectionSort.priceAsc ||
      this == ActorCollectionSort.priceDesc;
}

abstract class ActorRepository {
  Future<Result<PageDto<ActorCollection>>> listActorCollections({
    int? pageSize,
    String? mark,
    ActorCollectionSort? sort,
  });

  /// `GET /api/mini-drama/public/actor-collections/search` (dev: mark + pageSize).
  ///
  /// First page: omit [mark]. Next page: pass the opaque cursor from the
  /// previous response. Do **not** send `"0"` — the API rejects it.
  Future<Result<PageDto<ActorCollection>>> searchActorCollections({
    required String keyword,
    int pageSize = 20,
    String? mark,
  });
  Future<Result<ActorCollection>> getActorCollectionDetail(String id);

  /// Local cache / seed only — never hits the network.
  Future<ActorCollection?> getActorCollectionDetailCachedOnly(String id);

  /// Evicts cache, fetches from server, and writes the fresh value back.
  Future<Result<ActorCollection>> refreshActorCollectionDetail(String id);

  /// 强制走网络拉取演员合集详情（绕过内存/Hive 缓存）。
  ///
  /// 与 web `useActorCompletePlayRequirementSatisfied` 中 `refetchOnMount: true`
  /// 的口径一致，用于升级弹窗实时获取 `completedViewCount`。
  Future<Result<ActorCollection>> getActorCollectionDetailFromNetwork(
    String id,
  );
  Future<void> seedActorCollectionDetail(ActorCollection collection);
  Future<void> invalidateActorCollectionDetailCache(String id);
  Future<Result<List<ActorCollection>>> listOwnedActorCollections();

  /// Profile「角色 IP」tab — 对齐 Web
  /// `GET /api/mini-drama/user/profiles/{userId}/actor-collections`.
  Future<Result<PageDto<ActorCollection>>> listProfileActorCollections({
    required String userId,
    String? mark,
    int pageSize = 20,
  });
  Future<Result<PageDto<Actor>>> listPublic({
    int? mark,
    int pageSize = 20,
    String? name,
  });
  Future<Result<PageDto<Actor>>> listMyActors({int? mark, int pageSize = 20});
  Future<Result<List<Actor>>> listDreamOsMaterials();
  Future<Result<void>> deleteActor(String actorId);
  Future<Result<Actor>> getDetail(String actorId);
  Future<Result<PageDto<DramaListItem>>> getCastDramas(
    String actorId, {
    String? mark,
    int pageSize = 20,
  });
  Future<Result<ActorNftMintDigest>> mintActorNft(
    String actorCollectionId,
    MintActorNftRequest request,
  );
  Future<Result<PrepareActorCollectionResponse>> prepareActorCollection(
    PrepareActorCollectionRequest request,
  );
  Future<Result<ActorCollectionMintDigest>> mintActorCollection(
    int actorCollectionId,
    MintActorCollectionRequest request,
  );
  Future<Result<ActorNftVaultDeposit>> getVaultDeposit(
    String actorCollectionId,
  );
  Future<void> invalidateActorCollectionsCache({ActorCollectionSort? sort});

  /// Clear caches containing user-scoped data ("my actors"). Cache keys do
  /// not include the user id, so these must be dropped on login/logout.
  Future<void> clearUserScopedCaches();
  Future<void> dispose();
}

class ActorRepositoryImpl implements ActorRepository {
  static const _actorCollections = '/api/mini-drama/public/actor-collections';
  static const _creatorActors = '/api/mini-drama/creator/actors';

  final StoryApiClient _api;
  final StoryLocalRepository? _local;
  late final CacheChain<String, PageDto<Actor>> _publicActorsCache;
  late final CacheChain<String, PageDto<Actor>> _myActorsCache;
  late final CacheChain<String, PageDto<ActorCollection>>
  _actorCollectionsCache;
  late final CacheChain<String, ActorCollection> _actorCollectionDetailCache;
  late final MemoryCacheLayer<String, PageDto<Actor>> _publicActorsMemory;
  late final MemoryCacheLayer<String, PageDto<Actor>> _myActorsMemory;
  late final MemoryCacheLayer<String, PageDto<ActorCollection>>
  _actorCollectionsMemory;
  late final MemoryCacheLayer<String, ActorCollection>
  _actorCollectionDetailMemory;

  /// Default TTL for actor caches (5 minutes).
  static const _defaultActorCacheTtl = Duration(minutes: 5);

  ActorRepositoryImpl(this._api, [this._local]) {
    _publicActorsMemory = MemoryCacheLayer<String, PageDto<Actor>>(
      maxEntries: 5,
      defaultTtl: _defaultActorCacheTtl,
    );
    _myActorsMemory = MemoryCacheLayer<String, PageDto<Actor>>(
      maxEntries: 5,
      defaultTtl: _defaultActorCacheTtl,
    );
    _actorCollectionsMemory =
        MemoryCacheLayer<String, PageDto<ActorCollection>>(
          maxEntries: 8,
          defaultTtl: _defaultActorCacheTtl,
        );
    _actorCollectionDetailMemory = MemoryCacheLayer<String, ActorCollection>(
      maxEntries: 32,
      defaultTtl: _defaultActorCacheTtl,
    );

    final local = _local;
    final publicActorsHive = local == null
        ? null
        : HiveCacheLayer<PageDto<Actor>>(
            box: local.cacheBox,
            prefix: 'actor_public_',
            decoder: _decodeActorPage,
            encoder: _encodeActorPage,
          );
    final myActorsHive = local == null
        ? null
        : HiveCacheLayer<PageDto<Actor>>(
            box: local.cacheBox,
            prefix: 'actor_my_',
            decoder: _decodeActorPage,
            encoder: _encodeActorPage,
          );
    final collectionsHive = local == null
        ? null
        : HiveCacheLayer<PageDto<ActorCollection>>(
            box: local.cacheBox,
            prefix: 'actor_collections_',
            decoder: _decodeActorCollectionPage,
            encoder: _encodeActorCollectionPage,
          );
    final collectionDetailHive = local == null
        ? null
        : HiveCacheLayer<ActorCollection>(
            box: local.cacheBox,
            prefix: 'actor_collection_detail_',
            decoder: (data) => ActorCollection.fromJson(deepStringMap(data)),
            encoder: (value) => value.toJson(),
          );

    _publicActorsCache = CacheChain(
      fetcher: _fetchPublicActors,
      readLayers: [_publicActorsMemory, ?publicActorsHive],
      writeLayers: [_publicActorsMemory, ?publicActorsHive],
    );
    _myActorsCache = CacheChain(
      fetcher: _fetchMyActors,
      readLayers: [_myActorsMemory, ?myActorsHive],
      writeLayers: [_myActorsMemory, ?myActorsHive],
    );
    _actorCollectionsCache = CacheChain(
      fetcher: _fetchActorCollections,
      readLayers: [_actorCollectionsMemory, ?collectionsHive],
      writeLayers: [_actorCollectionsMemory, ?collectionsHive],
    );
    _actorCollectionDetailCache = CacheChain(
      fetcher: _fetchActorCollectionDetail,
      readLayers: [_actorCollectionDetailMemory, ?collectionDetailHive],
      writeLayers: [_actorCollectionDetailMemory, ?collectionDetailHive],
    );
  }

  static ActorCollection? _actorCollectionOrNull(ActorCollection collection) {
    final id = collection.id;
    if (id == null || id.isEmpty) return null;
    return collection;
  }

  static String _actorCollectionsCacheKey(ActorCollectionSort? sort) =>
      'first_${sort?.value ?? 'default'}';

  static PageDto<ActorCollection> _decodeActorCollectionPage(Object? data) {
    if (data is Map && data['list'] is List) {
      final map = deepStringMap(data);
      final items = (map['list'] as List)
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => ActorCollection.fromJson(deepStringMap(e)))
          .toList();
      return PageDto(
        list: items,
        mark: map['mark'] as String?,
        hasMore: map['hasMore'] as bool?,
        pageSize: asIntOrNull(map['pageSize']),
      );
    }
    return const PageDto(list: []);
  }

  static Object _encodeActorCollectionPage(PageDto<ActorCollection> value) {
    return {
      'list': (value.list ?? const <ActorCollection>[])
          .map((item) => item.toJson())
          .toList(),
      'mark': value.mark,
      'hasMore': value.hasMore,
      'pageSize': value.pageSize,
    };
  }

  Future<Result<PageDto<ActorCollection>>> _fetchActorCollections(String key) {
    final sortPart = key.startsWith('first_') ? key.substring(6) : 'default';
    ActorCollectionSort? sort;
    for (final candidate in ActorCollectionSort.values) {
      if (candidate.value == sortPart) {
        sort = candidate;
        break;
      }
    }
    return _api.safeGet(
      _actorCollections,
      query: {'pageSize': 20, 'sort': sort?.value},
      decoder: (d) =>
          parsePageDto<ActorCollection>(d, ActorCollection.fromJson),
    );
  }

  @override
  Future<void> invalidateActorCollectionsCache({
    ActorCollectionSort? sort,
  }) async {
    await _actorCollectionsCache.evict(_actorCollectionsCacheKey(sort));
  }

  @override
  Future<void> seedActorCollectionDetail(ActorCollection collection) async {
    final cached = _actorCollectionOrNull(collection);
    if (cached == null) return;
    await _actorCollectionDetailCache.put(cached.id!, cached);
  }

  @override
  Future<void> invalidateActorCollectionDetailCache(String id) async {
    if (id.isEmpty) return;
    await _actorCollectionDetailCache.evict(id);
  }

  @override
  Future<void> clearUserScopedCaches() => _myActorsCache.clear();

  Future<Result<ActorCollection>> _fetchActorCollectionDetail(String id) =>
      _api.safeGet(
        '$_actorCollections/$id',
        decoder: decodeWith(ActorCollection.fromJson),
      );

  static PageDto<Actor> _decodeActorPage(Object? data) {
    if (data is Map && data['list'] is List) {
      final map = deepStringMap(data);
      final items = (map['list'] as List)
          .map((e) => _actorCollectionToActorJson(e as Map<String, dynamic>))
          .map(Actor.fromJson)
          .toList();
      return PageDto(list: items);
    }
    return const PageDto(list: []);
  }

  static Object _encodeActorPage(PageDto<Actor> value) {
    return {
      'list': (value.list ?? const <Actor>[])
          .map((item) => item.toJson())
          .toList(),
    };
  }

  static Map<String, dynamic> _actorCollectionToActorJson(
    Map<String, dynamic> json,
  ) {
    final copy = Map<String, dynamic>.from(json);

    if (json.containsKey('totalSupply')) {
      final rawTotal = json['totalSupply'];
      copy['nftMaxSupply'] = rawTotal is int
          ? rawTotal
          : int.tryParse(rawTotal?.toString() ?? '');
    }
    if (json.containsKey('mintedSupply')) {
      final rawMinted = json['mintedSupply'];
      copy['mintQuantity'] = rawMinted is int
          ? rawMinted
          : int.tryParse(rawMinted?.toString() ?? '');
    }
    if (json.containsKey('initialPriceUsdc')) {
      copy['nftUnitPrice'] = json['initialPriceUsdc'];
    } else if (json.containsKey('currentPriceUsdc')) {
      copy['nftUnitPrice'] = json['currentPriceUsdc'];
    }

    if (json.containsKey('createdAt')) {
      final created = json['createdAt'];
      if (created is String) {
        final dt = DateTime.tryParse(created);
        if (dt != null) {
          copy['createdAt'] = dt.millisecondsSinceEpoch;
        } else {
          copy['createdAt'] = int.tryParse(created);
        }
      }
    }
    if (json.containsKey('updatedAt')) {
      final updated = json['updatedAt'];
      if (updated is String) {
        final dt = DateTime.tryParse(updated);
        if (dt != null) {
          copy['updatedAt'] = dt.millisecondsSinceEpoch;
        } else {
          copy['updatedAt'] = int.tryParse(updated);
        }
      }
    }

    return copy;
  }

  Future<Result<PageDto<Actor>>> _fetchPublicActors(String key) {
    // Parse key: "public_mark_pageSize_name"
    final parts = key.split('_');
    final markPart = parts.length > 1 ? parts[1] : null;
    final mark = markPart == 'first' ? null : markPart;
    final pageSize = parts.length > 2 ? int.tryParse(parts[2]) ?? 20 : 20;
    final name = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null;

    if (name != null && name.isNotEmpty) {
      return _api.safeGet(
        '$_actorCollections/search',
        query: {'keyword': name, 'limit': pageSize},
        decoder: (d) {
          final list = parseList<Map<String, dynamic>>(d, (x) => x);
          final mapped = list
              .map(_actorCollectionToActorJson)
              .map(Actor.fromJson)
              .toList();
          return PageDto<Actor>(list: mapped);
        },
      );
    }

    return _api.safeGet(
      _actorCollections,
      query: {'mark': mark, 'pageSize': pageSize},
      decoder: (d) => parsePageDto<Actor>(
        d,
        (json) => Actor.fromJson(_actorCollectionToActorJson(json)),
      ),
    );
  }

  Future<Result<PageDto<Actor>>> _fetchMyActors(String key) {
    // Parse key: "my_mark_pageSize"
    final parts = key.split('_');
    final mark = parts.length > 1 ? int.tryParse(parts[1]) : null;
    final pageSize = parts.length > 2 ? int.tryParse(parts[2]) ?? 20 : 20;
    return _api.safeGet(
      _creatorActors,
      query: {'mark': mark, 'pageSize': pageSize},
      decoder: (d) => parsePageDto<Actor>(d, Actor.fromJson),
    );
  }

  @override
  Future<Result<PageDto<ActorCollection>>> listActorCollections({
    int? pageSize,
    String? mark,
    ActorCollectionSort? sort,
  }) {
    if (mark == null) {
      return _actorCollectionsCache.get(_actorCollectionsCacheKey(sort));
    }
    return _api.safeGet(
      _actorCollections,
      query: {'pageSize': pageSize ?? 20, 'mark': mark, 'sort': sort?.value},
      decoder: (d) =>
          parsePageDto<ActorCollection>(d, ActorCollection.fromJson),
    );
  }

  @override
  Future<Result<PageDto<ActorCollection>>> searchActorCollections({
    required String keyword,
    int pageSize = 20,
    String? mark,
  }) {
    final cursor = mark?.trim();
    return _api.safeGet(
      '$_actorCollections/search',
      query: {
        'keyword': keyword,
        'pageSize': pageSize.clamp(1, 100),
        // First page: omit mark. Opaque cursor only (never "0").
        if (cursor != null && cursor.isNotEmpty && cursor != '0')
          'mark': cursor,
      },
      decoder: (d) {
        if (d is Map) {
          return parsePageDto<ActorCollection>(d, ActorCollection.fromJson);
        }
        // test env legacy: bare array + limit≤6
        final list = parseList<ActorCollection>(d, ActorCollection.fromJson);
        return PageDto<ActorCollection>(list: list, hasMore: false, mark: '-1');
      },
    );
  }

  @override
  Future<Result<ActorCollection>> getActorCollectionDetail(String id) =>
      _actorCollectionDetailCache.get(id);

  @override
  Future<ActorCollection?> getActorCollectionDetailCachedOnly(String id) {
    if (id.isEmpty) return Future<ActorCollection?>.value();
    return _actorCollectionDetailCache.getCachedOnly(id);
  }

  @override
  Future<Result<ActorCollection>> refreshActorCollectionDetail(
    String id,
  ) async {
    if (id.isEmpty) {
      return Result.failure(ApiError.unknown('actor id is empty'));
    }
    await _actorCollectionDetailCache.evict(id);
    return _actorCollectionDetailCache.get(id);
  }

  @override
  Future<Result<ActorCollection>> getActorCollectionDetailFromNetwork(
    String id,
  ) => _api.safeGet(
    '$_actorCollections/$id',
    decoder: decodeWith(ActorCollection.fromJson),
  );

  @override
  Future<Result<List<ActorCollection>>> listOwnedActorCollections() =>
      _api.safeGet(
        '/api/mini-drama/creator/actor-collections/owned',
        decoder: (d) => parseList<ActorCollection>(d, ActorCollection.fromJson),
      );

  @override
  Future<Result<PageDto<ActorCollection>>> listProfileActorCollections({
    required String userId,
    String? mark,
    int pageSize = 20,
  }) {
    final cursor = mark?.trim();
    return _api.safeGet(
      '/api/mini-drama/user/profiles/$userId/actor-collections',
      query: {
        'pageSize': pageSize.clamp(1, 100),
        if (cursor != null && cursor.isNotEmpty && cursor != '0')
          'mark': cursor,
      },
      decoder: (d) =>
          parsePageDto<ActorCollection>(d, ActorCollection.fromJson),
    );
  }

  @override
  Future<Result<PageDto<Actor>>> listPublic({
    int? mark,
    int pageSize = 20,
    String? name,
  }) {
    final cacheKey = 'public_${mark ?? "first"}_${pageSize}_${name ?? ""}';
    // Only cache first page without search
    if (mark == null && (name == null || name.isEmpty)) {
      return _publicActorsCache.get(cacheKey);
    }
    if (name != null && name.isNotEmpty) {
      return _api.safeGet(
        '$_actorCollections/search',
        query: {'keyword': name, 'limit': pageSize},
        decoder: (d) {
          final list = parseList<Map<String, dynamic>>(d, (x) => x);
          final mapped = list
              .map(_actorCollectionToActorJson)
              .map(Actor.fromJson)
              .toList();
          return PageDto<Actor>(list: mapped);
        },
      );
    }
    return _api.safeGet(
      _actorCollections,
      query: {'mark': mark?.toString(), 'pageSize': pageSize},
      decoder: (d) => parsePageDto<Actor>(
        d,
        (json) => Actor.fromJson(_actorCollectionToActorJson(json)),
      ),
    );
  }

  @override
  Future<Result<PageDto<Actor>>> listMyActors({int? mark, int pageSize = 20}) {
    final cacheKey = 'my_${mark ?? "first"}_$pageSize';
    if (mark == null) {
      return _myActorsCache.get(cacheKey);
    }
    return _api.safeGet(
      _creatorActors,
      query: {'mark': mark, 'pageSize': pageSize},
      decoder: (d) => parsePageDto<Actor>(d, Actor.fromJson),
    );
  }

  @override
  Future<Result<List<Actor>>> listDreamOsMaterials() => _api.safeGet(
    '/api/mini-drama/creator/actor-collections/collection/assets',
    decoder: (d) {
      final list = parseList<Map<String, dynamic>>(d, (x) => x);
      return list.map((json) {
        return Actor(
          id: json['assetId']?.toString(),
          name: json['assetName']?.toString(),
          avatarUrl: json['assetUrl']?.toString(),
          bio: json['assetDescription']?.toString(),
        );
      }).toList();
    },
  );

  @override
  Future<Result<void>> deleteActor(String actorId) async {
    final result = await _api.safeDelete(
      '$_creatorActors/$actorId',
      decoder: (_) {},
    );
    // Clear my actors cache after deletion
    if (result.isSuccess) {
      await _myActorsCache.clear();
    }
    return result;
  }

  @override
  Future<Result<Actor>> getDetail(String id) => _api.safeGet(
    '$_actorCollections/$id',
    decoder: (d) {
      final json = normalizeJson(d);
      return Actor.fromJson(_actorCollectionToActorJson(json));
    },
  );

  @override
  Future<Result<PageDto<DramaListItem>>> getCastDramas(
    String actorId, {
    String? mark,
    int pageSize = 20,
  }) => _api.safeGet(
    '$_actorCollections/$actorId/dramas',
    query: {'mark': mark, 'pageSize': pageSize},
    decoder: (d) => parsePageDto<DramaListItem>(d, DramaListItem.fromJson),
  );

  @override
  Future<Result<ActorNftMintDigest>> mintActorNft(
    String actorCollectionId,
    MintActorNftRequest request,
  ) => _api.safePost(
    '/api/mini-drama/user/actor-collections/$actorCollectionId/nft/mint',
    body: request.toJson(),
    decoder: decodeWith(ActorNftMintDigest.fromJson),
  );

  @override
  Future<Result<PrepareActorCollectionResponse>> prepareActorCollection(
    PrepareActorCollectionRequest request,
  ) => _api.safePost(
    '/api/mini-drama/creator/actor-collections/collection/prepare',
    body: request.toJson(),
    decoder: decodeWith(PrepareActorCollectionResponse.fromJson),
  );

  @override
  Future<Result<ActorCollectionMintDigest>> mintActorCollection(
    int actorCollectionId,
    MintActorCollectionRequest request,
  ) => _api.safePost(
    '/api/mini-drama/creator/actor-collections/$actorCollectionId/mint',
    body: request.toJson(),
    decoder: decodeWith(ActorCollectionMintDigest.fromJson),
  );

  @override
  Future<Result<ActorNftVaultDeposit>> getVaultDeposit(
    String actorCollectionId,
  ) => _api.safeGet(
    '/api/userWallet/actorNft/vaultDeposit',
    query: {'actorCollectionId': actorCollectionId},
    decoder: decodeWith(ActorNftVaultDeposit.fromJson),
  );

  @override
  Future<void> dispose() async {
    await _publicActorsMemory.clear();
    await _myActorsMemory.clear();
    await _actorCollectionsMemory.clear();
    await _actorCollectionDetailMemory.clear();
  }
}
