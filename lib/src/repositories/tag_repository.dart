import '../api/story_api_client.dart';
import '../core/cache_strategy.dart';
import '../core/json_helpers.dart';
import '../core/result.dart';
import '../data/repository/story_local_repository.dart';
import '../foundation/locale_controller.dart';
import '../model/models.dart';

abstract class TagRepository {
  Future<Result<List<DramaTag>>> listTags();

  /// Drops cached tags (memory + Hive) so the next [listTags] hits the API.
  Future<void> invalidateCache();

  Future<void> dispose();
}

class TagRepositoryImpl implements TagRepository {
  final StoryApiClient _api;
  final StoryLocalRepository? _local;
  late final CacheChain<String, List<DramaTag>> _tagsCache;
  late final MemoryCacheLayer<String, List<DramaTag>> _tagsMemory;

  TagRepositoryImpl(this._api, [this._local]) {
    // TTL matches the Hive layer; without it the memory layer would keep
    // serving stale tags forever within a single app session.
    _tagsMemory = MemoryCacheLayer<String, List<DramaTag>>(
      maxEntries: 2,
      defaultTtl: const Duration(hours: 1),
    );

    final tagsHive = _local == null
        ? null
        : HiveCacheLayer<List<DramaTag>>(
            box: _local.cacheBox,
            defaultTtl: const Duration(hours: 1),
            prefix: 'drama_tags_',
            decoder: (data) {
              if (data is List) {
                return data.map((item) {
                  final map = item is Map<String, dynamic>
                      ? item
                      : (item is Map
                            ? Map<String, dynamic>.from(item)
                            : <String, dynamic>{});
                  return DramaTag.fromJson(map);
                }).toList();
              }
              return <DramaTag>[];
            },
            encoder: (value) => value.map((e) => e.toJson()).toList(),
          );

    _tagsCache = CacheChain(
      fetcher: _fetchTags,
      readLayers: [_tagsMemory, ?tagsHive],
      writeLayers: [_tagsMemory, ?tagsHive],
    );
  }

  Future<Result<List<DramaTag>>> _fetchTags(String key) => _api.safeGet(
    '/api/mini-drama/public/dramas/tags',
    decoder: (d) => parseList<DramaTag>(d, DramaTag.fromJson),
  );

  @override
  Future<Result<List<DramaTag>>> listTags() => _tagsCache.get(_langCode);

  @override
  Future<void> invalidateCache() => _tagsCache.evict(_langCode);

  String get _langCode {
    final locale = StoryLocaleController.instance.current;
    return locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
  }

  @override
  Future<void> dispose() async {}
}
