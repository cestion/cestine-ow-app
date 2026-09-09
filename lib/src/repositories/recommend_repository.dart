import 'dart:async';

import '../api/story_api_client.dart';
import '../core/cache_strategy.dart';
import '../core/json_helpers.dart';
import '../core/result.dart';
import '../core/story_logger.dart';
import '../data/repository/story_local_repository.dart';
import '../foundation/locale_controller.dart';
import '../model/json_converters.dart';
import '../model/page_dto.dart';
import '../model/recommend_feed_model.dart';
import '../model/recommend_search_models.dart';
import '../services/device_id_service.dart';

/// Mini-drama Recommend Feed API (`/api/recommend/*`).
///
/// Served via the same API gateway as other mini-drama routes
/// ([StoryApiClient.baseUrl]). Guests are identified by the `Device-ID`
/// header — do not send `userId=guest`. Logged-in users use Bearer auth.
abstract class RecommendRepository {
  /// Personalized / cold-start recommend page.
  ///
  /// Always hits the network. Successful first pages are written to
  /// Memory→Hive for [peekCachedFirstPage] (stale-while-revalidate).
  /// Pagination cursors are never cached.
  Future<Result<PageDto<RecommendFeedItem>>> fetchFeed({
    String? cursor,
    int size = 10,
    String? subject,
  });

  /// Last first-page snapshot for [subject] without a network round-trip.
  ///
  /// Used by the feed controller for stale-while-revalidate on cold start.
  Future<PageDto<RecommendFeedItem>?> peekCachedFirstPage({
    required String subject,
    int size = 10,
  });

  /// Same as [peekCachedFirstPage] but reads memory/Hive synchronously so the
  /// recommend tab can paint cached covers on the first frame.
  PageDto<RecommendFeedItem>? peekCachedFirstPageSync({
    required String subject,
    int size = 10,
  });

  /// Drop first-page caches (locale / auth subject change).
  Future<void> invalidateFirstPageCache({String? subject});

  /// Fuzzy search (`keyword` length 2–50). [type]: all | drama | short_video.
  Future<Result<RecommendSearchResponse>> search({
    required String keyword,
    String type = 'all',
    int size = 20,
    String? cursor,
  });

  /// Hard-filter a feed unit. [videoId] is [RecommendFeedItem.episodeId].
  Future<Result<void>> dislike(String videoId);
}

class RecommendRepositoryImpl implements RecommendRepository {
  RecommendRepositoryImpl(this._api, this._deviceId, [this._local]) {
    _memory = MemoryCacheLayer<String, PageDto<RecommendFeedItem>>(
      maxEntries: 4,
      defaultTtl: _firstPageTtl,
    );
    final local = _local;
    _hive = local == null
        ? null
        : HiveCacheLayer<PageDto<RecommendFeedItem>>(
            box: local.cacheBox,
            defaultTtl: _firstPageTtl,
            prefix: _cachePrefix,
            decoder: _decodePage,
            encoder: _encodePage,
          );
    // Warm Device-ID so the first feed request does not wait on Secure Storage.
    unawaited(_deviceId.getDeviceId());
  }

  final StoryApiClient _api;
  final DeviceIdService _deviceId;
  final StoryLocalRepository? _local;

  late final MemoryCacheLayer<String, PageDto<RecommendFeedItem>> _memory;
  late final HiveCacheLayer<PageDto<RecommendFeedItem>>? _hive;

  static const _feedPath = '/api/recommend/feed';
  static const _searchPath = '/api/recommend/search';
  static const _dislikePath = '/api/recommend/dislike';
  static const _cachePrefix = 'recommend_feed_first_';
  static const _lastFirstPageKeyMeta = 'recommend_feed_last_first_page_key';
  static const _firstPageTtl = Duration(minutes: 10);

  String _langCode() {
    final locale = StoryLocaleController.instance.current;
    return locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
  }

  String _cacheKey({required String subject, required int size}) {
    final scope = subject.trim().isEmpty ? 'guest' : subject.trim();
    return '${Uri.encodeComponent(scope)}|${_langCode()}|$size';
  }

  /// Logged-in subjects stay as userId. Guests are scoped by installation
  /// Device-ID so two guest sessions do not share a Hive first page.
  Future<String> _resolveCacheSubject(String? subject) async {
    final trimmed = subject?.trim() ?? '';
    if (trimmed.isNotEmpty && trimmed != 'guest') return trimmed;
    final raw = await _deviceId.getRawDeviceId();
    return 'guest:$raw';
  }

  static PageDto<RecommendFeedItem> _decodePage(Object? data) {
    final map = deepStringMap(data);
    final listRaw = map['list'];
    final items = listRaw is List
        ? listRaw
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (e) => RecommendFeedItem.fromJson(Map<String, dynamic>.from(e)),
              )
              .where((item) => item.hasPlayableIdentity)
              .toList()
        : <RecommendFeedItem>[];
    return PageDto<RecommendFeedItem>(
      mark: asStringOrNull(map['mark']),
      hasMore: asBool(map['hasMore']),
      pageSize: asIntOrNull(map['pageSize']),
      list: items,
    );
  }

  /// Persist card fields for SWR covers / chrome. Omit [signedCookies] and
  /// [mediaAccessUrl] — both expire / are signed and would 403 on cold resume.
  static Object _encodePage(PageDto<RecommendFeedItem> value) {
    return <String, dynamic>{
      'mark': value.mark,
      'hasMore': value.hasMore,
      'pageSize': value.pageSize,
      'list': [
        for (final item in value.list ?? const <RecommendFeedItem>[])
          _encodeItem(item),
      ],
    };
  }

  static Map<String, dynamic> _encodeItem(RecommendFeedItem item) {
    return <String, dynamic>{
      'dramaId': item.dramaId,
      if (item.contentType != null) 'contentType': item.contentType,
      if (item.episodeId != null) 'episodeId': item.episodeId,
      if (item.episodeNo != null) 'episodeNo': item.episodeNo,
      if (item.title != null) 'title': item.title,
      if (item.description != null) 'description': item.description,
      if (item.coverUrl != null) 'coverUrl': item.coverUrl,
      if (item.playbackType != null) 'playbackType': item.playbackType,
      if (item.avgRating != null) 'avgRating': item.avgRating,
      if (item.totalEpisodes != null) 'totalEpisodes': item.totalEpisodes,
      if (item.badge != null) 'badge': item.badge,
      if (item.likeCount != null) 'likeCount': item.likeCount,
      if (item.commentCount != null) 'commentCount': item.commentCount,
      if (item.favoriteCount != null) 'favoriteCount': item.favoriteCount,
      if (item.playCount != null) 'playCount': item.playCount,
      if (item.completeCount != null) 'completeCount': item.completeCount,
      if (item.likedByMe != null) 'likedByMe': item.likedByMe,
      if (item.favoritedByMe != null) 'favoritedByMe': item.favoritedByMe,
      if (item.followedByMe != null) 'followedByMe': item.followedByMe,
      if (item.creatorId != null) 'creatorId': item.creatorId,
      if (item.creatorName != null) 'creatorName': item.creatorName,
      if (item.creatorAvatar != null) 'creatorAvatar': item.creatorAvatar,
      if (item.tags != null) 'tags': item.tags,
      if (item.actors != null)
        'actors': [
          for (final a in item.actors!)
            <String, dynamic>{
              if (a.actorId != null) 'actorId': a.actorId,
              if (a.actorName != null) 'actorName': a.actorName,
              if (a.avatarUrl != null) 'avatarUrl': a.avatarUrl,
              if (a.badge != null) 'badge': a.badge,
              if (a.trust != null) 'trust': a.trust,
              if (a.computingPower != null) 'computingPower': a.computingPower,
              if (a.storyPerHour != null) 'storyPerHour': a.storyPerHour,
              if (a.unitPrice != null) 'unitPrice': a.unitPrice,
            },
        ],
      if (item.score != null) 'score': item.score,
      if (item.reason != null) 'reason': item.reason,
    };
  }

  Future<void> _writeFirstPage(
    String key,
    PageDto<RecommendFeedItem> page,
  ) async {
    try {
      await _memory.set(key, page);
      await _hive?.set(key, page);
      _local?.cacheBox.put(_lastFirstPageKeyMeta, key);
    } catch (e) {
      StoryLogger.w(
        'Recommend first-page cache write failed',
        error: e,
        tag: 'RecRepo',
      );
    }
  }

  @override
  PageDto<RecommendFeedItem>? peekCachedFirstPageSync({
    required String subject,
    int size = 10,
  }) {
    final key = _syncCacheKey(subject: subject, size: size.clamp(1, 50));
    if (key == null) return null;
    return _peekByCacheKey(key);
  }

  @override
  Future<PageDto<RecommendFeedItem>?> peekCachedFirstPage({
    required String subject,
    int size = 10,
  }) async {
    final resolved = await _resolveCacheSubject(subject);
    final key = _cacheKey(subject: resolved, size: size.clamp(1, 50));
    return _peekByCacheKey(key);
  }

  PageDto<RecommendFeedItem>? _peekByCacheKey(String key) {
    try {
      final memoryHit = _memory.peek(key);
      if (memoryHit != null && (memoryHit.list?.isNotEmpty ?? false)) {
        return memoryHit;
      }
      final hiveHit = _hive?.peekSync(key);
      if (hiveHit != null && (hiveHit.list?.isNotEmpty ?? false)) {
        unawaited(_memory.set(key, hiveHit));
        return hiveHit;
      }
    } catch (e) {
      StoryLogger.w(
        'Recommend first-page cache read failed',
        error: e,
        tag: 'RecRepo',
      );
    }
    return null;
  }

  String? _syncCacheKey({required String subject, required int size}) {
    final trimmed = subject.trim().isEmpty ? 'guest' : subject.trim();
    if (trimmed != 'guest') {
      return _cacheKey(subject: trimmed, size: size);
    }
    final raw = _deviceId.cachedRawDeviceId;
    if (raw != null && raw.isNotEmpty) {
      return _cacheKey(subject: 'guest:$raw', size: size);
    }
    final lastKey = _local?.cacheBox.get(_lastFirstPageKeyMeta);
    if (lastKey is String && lastKey.isNotEmpty) return lastKey;
    return null;
  }

  void _clearLastFirstPageKeyMeta() {
    _local?.cacheBox.delete(_lastFirstPageKeyMeta);
  }

  @override
  Future<void> invalidateFirstPageCache({String? subject}) async {
    if (subject != null) {
      final resolved = await _resolveCacheSubject(subject);
      for (final size in const [10, 20]) {
        final key = _cacheKey(subject: resolved, size: size);
        await _memory.evict(key);
        await _hive?.evict(key);
      }
      _clearLastFirstPageKeyMeta();
      return;
    }
    await _memory.clear();
    await _hive?.clear();
    _clearLastFirstPageKeyMeta();
  }

  @override
  Future<Result<PageDto<RecommendFeedItem>>> fetchFeed({
    String? cursor,
    int size = 10,
    String? subject,
  }) async {
    final deviceId = await _deviceId.getDeviceId();
    final clamped = size.clamp(1, 50);
    final isFirstPage = cursor == null || cursor.isEmpty;
    final cacheSubject = await _resolveCacheSubject(subject);
    final cacheKey = _cacheKey(subject: cacheSubject, size: clamped);

    final result = await _api.safeGet(
      _feedPath,
      query: {
        'size': clamped,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
      headers: {'Device-ID': deviceId},
      decoder: (d) {
        final page = RecommendFeedPage.fromJson(d as Map<String, dynamic>);
        return PageDto<RecommendFeedItem>(
          mark: page.cursor,
          hasMore: page.hasMore,
          list: page.items,
          pageSize: clamped,
        );
      },
    );

    if (isFirstPage && result.isSuccess) {
      final page = result.dataOrNull;
      if (page != null && (page.list?.isNotEmpty ?? false)) {
        await _writeFirstPage(cacheKey, page);
      }
    }
    return result;
  }

  @override
  Future<Result<RecommendSearchResponse>> search({
    required String keyword,
    String type = 'all',
    int size = 20,
    String? cursor,
  }) async {
    final kw = keyword.trim();
    final clamped = size.clamp(1, 50);
    final deviceId = await _deviceId.getDeviceId();
    return _api.safeGet(
      _searchPath,
      query: {
        'keyword': kw,
        'type': type,
        'size': clamped,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
      headers: {'Device-ID': deviceId},
      decoder: (d) =>
          RecommendSearchResponse.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }

  @override
  Future<Result<void>> dislike(String videoId) => _api.safePost(
    '$_dislikePath/$videoId',
    body: <String, dynamic>{},
    decoder: (_) {},
  );

  Future<void> dispose() async {}
}
