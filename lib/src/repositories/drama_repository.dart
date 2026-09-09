import 'dart:async';

import '../core/request_coalescer.dart';
import '../core/request_keys.dart';
import '../core/cache_strategy.dart';
import '../core/result.dart';
import '../core/json_helpers.dart';
import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../data/repository/story_local_repository.dart';
import '../foundation/locale_controller.dart';
import 'package:equatable/equatable.dart';
import '../model/models.dart';
import '../api/story_api_client.dart';

/// The type of episode tracking event.
enum EpisodeTrackEvent { play, complete }

/// Event path suffix for [EpisodeTrackEvent].
String episodeTrackEventPath(EpisodeTrackEvent event) => switch (event) {
  EpisodeTrackEvent.play => 'play-episode',
  EpisodeTrackEvent.complete => 'complete-episode',
};

class DramaReviewsData extends Equatable {
  final PageDto<DramaReview> reviews;
  final DramaReview? myReview;

  const DramaReviewsData({required this.reviews, this.myReview});

  @override
  List<Object?> get props => [reviews, myReview];
}

abstract class DramaRepository {
  Future<Result<PageDto<DramaReview>>> getReviews({
    required String dramaId,
    String? mark,
    int pageSize = 20,
  });

  Future<Result<DramaReview?>> getMyReview({required String dramaId});

  Future<Result<DramaReview>> submitReview({
    required String dramaId,
    required int rating,
    String? reviewText,
  });

  Future<Result<DramaReviewsData>> getReviewsWithMyReview({
    required String dramaId,
    String? mark,
    int pageSize = 20,
  });

  Future<Result<PageDto<DramaListItem>>> listPublic({
    String? mark,
    int pageSize = 20,
    String? name,
    String? tagId,
    String? sort,
  });

  /// Evict cached first-page results for pull-to-refresh / filter reload.
  Future<void> invalidatePublicListCache({String? tagId, String? sort});
  Future<Result<PageDto<DramaListItem>>> searchPublic({
    required String keyword,
    int limit = 20,
  });
  Future<Result<PageDto<DramaListItem>>> listMyDramas({
    String? mark,
    int pageSize = 20,
    String? status,
  });
  Future<Result<PageDto<CreatorDrama>>> listMyCreatorDramas({
    String? mark,
    int pageSize = 20,
    String? status,
  });

  /// Evict cached creator dramas first-page for re-entry / refresh.
  Future<void> invalidateCreatorDramasCache({
    String? status,
    int pageSize = 20,
  });
  Future<Result<int>> getOnlineDramaCount();
  Future<Result<CreatorDrama>> createDrama(CreateDramaRequest request);
  Future<Result<CreatorDrama>> getCreatorDrama(String dramaId);
  Future<Result<CreatorDrama>> updateDramaEditRevision(
    String dramaId,
    DramaEditRequest request,
  );
  Future<Result<DramaEditSession>> getEditSession(String dramaId);
  Future<Result<DramaDetail>> getDetail(
    String dramaId, {
    bool forceRefresh = false,
  });

  /// Local-only [DramaDetail] lookup (memory → Hive); never hits the network.
  /// Used for stale-while-revalidate: render this immediately, then replace
  /// with a force-refreshed fetch.
  Future<DramaDetail?> peekDetail(String dramaId);

  /// Evict the cached [DramaDetail] so the next [getDetail] hits the network.
  ///
  /// Detail is cached ~10min; counters on it (e.g. favoriteCount) go stale
  /// after the user toggles favorite, so callers invalidate on success.
  Future<void> invalidateDetailCache(String dramaId);
  Future<Result<DramaPlayResponse>> getEpisodeDetailByEpisodeId(
    String episodeId,
  );
  Future<Result<DramaPlayResponse>> getEpisodeDetail(
    String dramaId,
    int episodeNo, {
    bool forceRefresh = false,
  });
  Future<DramaPlayResponse?> prefetchEpisode(String dramaId, int episodeNo);
  Future<DramaPlayResponse?> peekPrefetchedEpisode(
    String dramaId,
    int episodeNo,
  );
  void clearPrefetchCache(String dramaId, int episodeNo);

  /// Public episode list (`GET /api/mini-drama/public/dramas/{id}/episodes`).
  Future<Result<PageDto<DramaEpisodeListItem>>> listEpisodes(
    String dramaId, {
    String? mark,
    int pageSize = 50,
    bool forceRefresh = false,
  });

  /// Patch interaction fields on a cached episode play (like/favorite/comment).
  ///
  /// Episode play is cached up to 24h for media URLs; without this, UI that
  /// reads [getEpisodeDetail] keeps showing stale [DramaPlayResponse.likedByMe]
  /// / [DramaPlayResponse.favoritedByMe] after the user toggles.
  ///
  /// [commentCountDelta] is applied on top of the cached commentCount so
  /// callers do not need to know the server total (e.g. +1 after posting).
  Future<void> patchCachedEpisodePlay(
    String dramaId,
    int episodeNo, {
    bool? likedByMe,
    int? likeCount,
    bool? favoritedByMe,
    int? commentCountDelta,
  });

  Future<Result<void>> deleteDrama(String dramaId);

  /// Toggle favorite.
  ///
  /// [FavoriteTarget.drama]: `POST /user/dramas/{dramaId}/favorite`.
  ///
  /// [FavoriteTarget.work]:
  /// - short drama → `POST /user/dramas/episodes/{episodeId}/favorite`
  /// - short video → `POST /user/short-videos/{episodeId}/favorite`
  Future<Result<void>> toggleFavorite(
    String dramaId, {
    WorkContentType type = WorkContentType.shortDrama,
    String? episodeId,
    FavoriteTarget target = FavoriteTarget.drama,
  });
  Future<Result<void>> toggleEpisodeLike(
    String dramaId,
    String episodeId, {
    WorkContentType type = WorkContentType.shortDrama,
  });
  Future<Result<void>> unlockEpisode(String dramaId, String signature);
  Future<Result<void>> unlockEpisodeBatch(String dramaId, String signature);

  /// Fetches a page of comments for an episode (work id) from
  /// `/api/mini-drama/public/works/{episodeId}/comments`.
  ///
  /// Pagination is cursor-based: the caller must pass the previous page's
  /// [PageDto.mark] verbatim into the next request's `mark`, and stop when
  /// the response reports `hasMore == false` with `mark == "-1"`. An illegal
  /// (terminal) cursor yields an empty page instead of an error.
  Future<Result<PageDto<StoryComment>>> getEpisodeComments(
    String episodeId, {
    String? mark,
    int pageSize = 20,

    /// Skip the first-page cache and force a network fetch (used when the
    /// comment sheet is (re)opened so freshly posted comments show up).
    bool forceRefresh = false,
  });
  Future<Result<StoryComment>> getComment(String commentId);

  /// Fetches a page of replies (second-level comments) for a root comment
  /// from `/api/mini-drama/public/comments/{rootId}/replies`.
  ///
  /// Shares the same envelope and cursor semantics as [getEpisodeComments]:
  /// carry the previous page's [PageDto.mark] verbatim into the next request,
  /// stop when `hasMore == false` with `mark == "-1"`, and treat an illegal
  /// (terminal) cursor as an empty page rather than an error.
  Future<Result<PageDto<StoryComment>>> getCommentReplies(
    String rootId, {
    String? mark,
    int pageSize = 20,
  });
  Future<Result<StoryComment>> postEpisodeComment(
    String episodeId,
    String content,
  );

  /// Posts a second-level comment (reply) under a root comment from
  /// `/api/mini-drama/user/comments/{commentId}/replies`.
  ///
  /// [commentId] is the root comment being replied to and [content] the reply
  /// text; the request body carries only the content.
  Future<Result<StoryComment>> postCommentReply(
    String commentId, {
    required String content,
  });
  Future<Result<void>> deleteComment(String commentId);

  /// Likes (POST) or unlikes (DELETE) a comment from
  /// `/api/mini-drama/user/comments/{commentId}/like`. When [liked] is true the
  /// comment is liked via POST with body `{'commentId': commentId}`; when false
  /// it is unliked via DELETE.
  Future<Result<void>> toggleCommentLike(
    String commentId, {
    required bool liked,
  });

  /// Evict the cached first-page replies for a root comment (called after a
  /// reply is posted / deleted / liked so re-expanded replies re-fetch fresh
  /// state within the TTL).
  Future<void> invalidateRepliesCache(String rootId);

  /// Evict the cached first-page comments for an episode so the next read
  /// re-fetches fresh `likedByMe` state (called after a comment-like toggle).
  Future<void> invalidateCommentsCache(String episodeId);

  /// Clear caches containing user-scoped data (`likedByMe`/`favoritedByMe`
  /// on episode plays, comment like state, creator dramas).
  ///
  /// Cache keys do not include the user id, so these must be dropped on
  /// login/logout to avoid leaking the previous session's interaction state.
  Future<void> clearUserScopedCaches();

  Future<Result<DramaNftMintDigest>> mintDramaNft(
    String dramaId,
    MintDramaNftRequest request,
  );

  Future<Result<List<ReportTypeItem>>> getReportTypes({String? scope});
  Future<Result<void>> reportEpisode({
    required String dramaId,
    required String episodeId,
    required String reportType,
    String? description,
    WorkContentType type = WorkContentType.shortDrama,
  });

  /// Reports a whole drama (not a single episode) from
  /// `/api/mini-drama/user/ugc/dramas/{dramaId}/report`. Used by the
  /// drama-scope report entry (举报整个短剧) in the player drama tab.
  Future<Result<void>> reportDrama({
    required String dramaId,
    required String reportType,
    String? description,
  });

  /// Reports a comment from
  /// `/api/mini-drama/user/ugc/comments/{commentId}/report`. Shares the UGC
  /// report envelope ([SubmitReportRequest]) with work/drama reports.
  Future<Result<void>> reportComment({
    required String commentId,
    required String reportType,
    String? description,
  });

  /// Reports a user from
  /// `/api/mini-drama/user/ugc/users/{userId}/report`.
  Future<Result<void>> reportUser({
    required String userId,
    required String reportType,
    String? description,
  });

  /// Track an episode event (play / complete).
  /// Called at most once per drama/episode per session per event type.
  Future<Result<void>> trackEpisode(
    String dramaId,
    String episodeId,
    EpisodeTrackEvent event, {
    required String deviceId,
    WorkContentType type = WorkContentType.shortDrama,
  });

  Future<void> dispose();
}

class DramaRepositoryImpl implements DramaRepository {
  static const _publicDramas = '/api/mini-drama/public/dramas';
  static const _publicComments = '/api/mini-drama/public/comments';
  static const _publicWorks = '/api/mini-drama/public/works';
  static const _userComments = '/api/mini-drama/user/comments';
  static const _creatorDramas = '/api/mini-drama/creator/dramas';
  static const _userDramas = '/api/mini-drama/user/dramas';
  static const _userWorks = '/api/mini-drama/user/works';
  static const _userShortVideos = '/api/mini-drama/user/short-videos';
  static const _ugcWorks = '/api/mini-drama/user/ugc/works';
  static const _ugcDramas = '/api/mini-drama/user/ugc/dramas';
  static const _ugcComments = '/api/mini-drama/user/ugc/comments';
  static const _ugcUsers = '/api/mini-drama/user/ugc/users';
  static const _ugcReportTypesPath = '/api/mini-drama/public/ugc/report-types';

  /// Terminal comment cursor returned by the API once all pages are loaded.
  /// Requesting a page with this (or any illegal) cursor must yield an empty
  /// page rather than an error so pagination stops cleanly.
  static const _commentsEndMark = '-1';

  final StoryApiClient _api;
  final StoryLocalRepository? _local;
  late final CacheChain<String, PageDto<DramaListItem>> _dramaListCache;
  late final CacheChain<String, DramaDetail> _dramaDetailCache;
  late final CacheChain<String, DramaPlayResponse> _episodePlayCache;
  late final CacheChain<String, PageDto<CreatorDrama>> _creatorDramasCache;
  late final CacheChain<String, PageDto<DramaEpisodeListItem>>
  _episodeListCache;
  late final MemoryCacheLayer<String, PageDto<StoryComment>> _commentsMemory;
  late final CacheChain<String, PageDto<StoryComment>> _commentsCache;
  late final MemoryCacheLayer<String, PageDto<StoryComment>> _repliesMemory;
  late final CacheChain<String, PageDto<StoryComment>> _repliesCache;
  late final MemoryCacheLayer<String, PageDto<DramaListItem>> _dramaListMemory;
  late final MemoryCacheLayer<String, DramaDetail> _dramaDetailMemory;
  late final MemoryCacheLayer<String, DramaPlayResponse> _episodePlayMemory;
  late final MemoryCacheLayer<String, PageDto<CreatorDrama>>
  _creatorDramasMemory;
  late final MemoryCacheLayer<String, PageDto<DramaEpisodeListItem>>
  _episodeListMemory;

  final RequestCoalescer _coalescer;

  /// Play payloads that cannot succeed until transcode finishes. Avoids
  /// hammering `/episodes/{n}/detail` from feed warmers (code 121019).
  final Map<String, (ApiError error, int expiresAtMs)> _episodePlayNegative =
      {};

  /// Episode-play keys whose latest network payload had no CloudFront
  /// cookies. Hive can keep that unsigned body for 24h; without this set
  /// every [getEpisodeDetail] would evict and refetch. Cleared on login
  /// so a later authenticated detail can pick up cookies.
  final Set<String> _unsignedProtectedConfirmed = {};

  static const Duration _transcodeFailedTtl = Duration(minutes: 10);
  static const int _maxNegativePlayEntries = 64;

  static const Duration _dramaDetailTtl = Duration(minutes: 10);

  /// Episode play response cache TTL.
  ///
  /// Kept aligned with the shortest typical CloudFront signed-cookie
  /// lifetime (24h). Caching longer than the signed cookies results in
  /// Hive hits whose `signedCookies` are already expired, which forces a
  /// 403 roundtrip on loadUrl before the cache can be refreshed. If the
  /// backend ever extends cookie lifetime, raise this value accordingly.
  static const Duration _episodePlayTtl = Duration(hours: 24);

  DramaRepositoryImpl(
    this._api, [
    this._local,
    RequestCoalescer? coalescer,
  ]) : _coalescer = coalescer ?? MemoryRequestCoalescer() {
    _dramaListMemory = MemoryCacheLayer<String, PageDto<DramaListItem>>();
    // TTL aligned with the Hive layer — without it the memory layer (which is
    // read first) can serve a stale favoriteCount for the whole app session.
    _dramaDetailMemory = MemoryCacheLayer<String, DramaDetail>(
      defaultTtl: _dramaDetailTtl,
    );
    // TTL aligned with the Hive layer so the in-memory copy cannot outlive
    // the persisted one (stale likedByMe/signedCookies after 24h).
    _episodePlayMemory = MemoryCacheLayer<String, DramaPlayResponse>(
      defaultTtl: _episodePlayTtl,
    );
    _creatorDramasMemory = MemoryCacheLayer<String, PageDto<CreatorDrama>>(
      maxEntries: 5,
    );
    _episodeListMemory =
        MemoryCacheLayer<String, PageDto<DramaEpisodeListItem>>(
          maxEntries: 20,
          defaultTtl: const Duration(minutes: 5),
        );
    _commentsMemory = MemoryCacheLayer<String, PageDto<StoryComment>>(
      maxEntries: 10,
      defaultTtl: const Duration(minutes: 5),
    );
    _repliesMemory = MemoryCacheLayer<String, PageDto<StoryComment>>(
      maxEntries: 10,
      defaultTtl: const Duration(minutes: 5),
    );

    final local = _local;
    final dramaListHive = local == null
        ? null
        : HiveCacheLayer<PageDto<DramaListItem>>(
            box: local.cacheBox,
            prefix: 'drama_list_',
            decoder: _decodeDramaListPage,
            encoder: _encodeDramaListPage,
          );
    final dramaDetailHive = local == null
        ? null
        : HiveCacheLayer<DramaDetail>(
            box: local.cacheBox,
            defaultTtl: _dramaDetailTtl,
            prefix: 'drama_detail_',
            decoder: (data) => DramaDetail.fromJson(deepStringMap(data)),
            encoder: (value) => value.toJson(),
          );
    final episodePlayHive = local == null
        ? null
        : HiveCacheLayer<DramaPlayResponse>(
            box: local.cacheBox,
            defaultTtl: _episodePlayTtl,
            prefix: 'episode_play_',
            decoder: (data) => DramaPlayResponse.fromJson(deepStringMap(data)),
            encoder: (value) => value.toJson(),
          );
    final creatorDramasHive = local == null
        ? null
        : HiveCacheLayer<PageDto<CreatorDrama>>(
            box: local.cacheBox,
            prefix: 'creator_dramas_',
            decoder: _decodeCreatorDramasPage,
            encoder: _encodeCreatorDramasPage,
          );
    final commentsHive = local == null
        ? null
        : HiveCacheLayer<PageDto<StoryComment>>(
            box: local.cacheBox,
            // v2: comment pages moved from a bare list (v1) to a page
            // envelope. A distinct prefix makes old v1 entries unreachable
            // instead of parsing them with the wrong shape.
            prefix: 'comments_v2_',
            decoder: (data) => parsePageDto<StoryComment>(
              deepStringMap(data),
              StoryComment.fromJson,
            ),
            encoder: (value) => <String, dynamic>{
              'list': (value.list ?? const <StoryComment>[])
                  .map((e) => e.toJson())
                  .toList(),
              'mark': value.mark,
              'hasMore': value.hasMore,
              'pageSize': value.pageSize,
            },
          );
    final repliesHive = local == null
        ? null
        : HiveCacheLayer<PageDto<StoryComment>>(
            box: local.cacheBox,
            prefix: 'comment_replies_',
            decoder: (data) => parsePageDto<StoryComment>(
              deepStringMap(data),
              StoryComment.fromJson,
            ),
            encoder: (value) => <String, dynamic>{
              'list': (value.list ?? const <StoryComment>[])
                  .map((e) => e.toJson())
                  .toList(),
              'mark': value.mark,
              'hasMore': value.hasMore,
              'pageSize': value.pageSize,
            },
          );
    final episodeListHive = local == null
        ? null
        : HiveCacheLayer<PageDto<DramaEpisodeListItem>>(
            box: local.cacheBox,
            prefix: 'drama_episodes_',
            decoder: _decodeEpisodeListPage,
            encoder: _encodeEpisodeListPage,
          );

    _dramaListCache = CacheChain(
      fetcher: _fetchPublicDramaList,
      readLayers: [_dramaListMemory, ?dramaListHive],
      writeLayers: [_dramaListMemory, ?dramaListHive],
    );
    _dramaDetailCache = CacheChain(
      fetcher: _fetchDramaDetail,
      readLayers: [_dramaDetailMemory, ?dramaDetailHive],
      writeLayers: [_dramaDetailMemory, ?dramaDetailHive],
    );
    _episodePlayCache = CacheChain(
      fetcher: _fetchEpisodePlay,
      readLayers: [_episodePlayMemory, ?episodePlayHive],
      writeLayers: [_episodePlayMemory, ?episodePlayHive],
    );
    _creatorDramasCache = CacheChain(
      fetcher: _fetchCreatorDramas,
      readLayers: [_creatorDramasMemory, ?creatorDramasHive],
      writeLayers: [_creatorDramasMemory, ?creatorDramasHive],
    );
    _episodeListCache = CacheChain(
      fetcher: _fetchEpisodeList,
      readLayers: [_episodeListMemory, ?episodeListHive],
      writeLayers: [_episodeListMemory, ?episodeListHive],
    );
    _commentsCache = CacheChain(
      fetcher: _fetchComments,
      readLayers: [_commentsMemory, ?commentsHive],
      writeLayers: [_commentsMemory, ?commentsHive],
    );
    _repliesCache = CacheChain(
      fetcher: _fetchCommentReplies,
      readLayers: [_repliesMemory, ?repliesHive],
      writeLayers: [_repliesMemory, ?repliesHive],
    );
  }

  static List<Map<String, dynamic>> _asJsonMapList(Object? data) {
    if (data is! List) {
      throw const FormatException('Cached value is not a list');
    }
    return data.map((item) => deepStringMap(item)).toList();
  }

  static PageDto<DramaListItem> _decodeDramaListPage(Object? data) {
    if (data is List) {
      final items = _asJsonMapList(data).map(DramaListItem.fromJson).toList();
      return PageDto(list: items);
    }
    if (data is Map && data['list'] is List) {
      final map = deepStringMap(data);
      final items = _asJsonMapList(
        map['list'],
      ).map(DramaListItem.fromJson).toList();
      return PageDto(list: items);
    }
    return const PageDto(list: []);
  }

  static Object _encodeDramaListPage(PageDto<DramaListItem> value) {
    return (value.list ?? const <DramaListItem>[])
        .map((item) => item.toJson())
        .toList();
  }

  static PageDto<CreatorDrama> _decodeCreatorDramasPage(Object? data) {
    if (data is Map && data['list'] is List) {
      final map = deepStringMap(data);
      final items = _asJsonMapList(
        map['list'],
      ).map(CreatorDrama.fromJson).toList();
      return PageDto(list: items);
    }
    return const PageDto(list: []);
  }

  static Object _encodeCreatorDramasPage(PageDto<CreatorDrama> value) {
    return {
      'list': (value.list ?? const <CreatorDrama>[])
          .map((item) => item.toJson())
          .toList(),
    };
  }

  static PageDto<DramaEpisodeListItem> _decodeEpisodeListPage(Object? data) {
    if (data is Map && data['list'] is List) {
      final map = deepStringMap(data);
      final items = _asJsonMapList(
        map['list'],
      ).map(DramaEpisodeListItem.fromJson).toList();
      return PageDto(
        pageSize: asIntOrNull(map['pageSize']),
        mark: asStringOrNull(map['mark']),
        list: items,
        hasMore: asBoolOrNull(map['hasMore']),
        total: PageDto.parseTotal(map['total']),
      );
    }
    if (data is List) {
      final items = _asJsonMapList(
        data,
      ).map(DramaEpisodeListItem.fromJson).toList();
      return PageDto(list: items);
    }
    return const PageDto(list: []);
  }

  static Object _encodeEpisodeListPage(PageDto<DramaEpisodeListItem> value) {
    return {
      'pageSize': value.pageSize,
      'mark': value.mark,
      'list': (value.list ?? const <DramaEpisodeListItem>[])
          .map((item) => item.toJson())
          .toList(),
      'hasMore': value.hasMore,
      'total': value.total,
    };
  }

  Future<Result<PageDto<CreatorDrama>>> _fetchCreatorDramas(String key) {
    // Parse key: "creator|mark|pageSize|status"
    final parts = key.split('|');
    // "first" is the cache placeholder for the first page (mark == null);
    // treat it as null so we don't send mark=first to the API.
    final rawMark = parts.length > 1 ? parts[1] : null;
    final mark = rawMark == 'first' ? null : rawMark;
    final pageSize = parts.length > 2 ? int.tryParse(parts[2]) ?? 20 : 20;
    final status = parts.length > 3 ? parts[3] : null;
    final statusValue = (status != null && status.isNotEmpty) ? status : null;
    return _api.safeGet(
      _creatorDramas,
      query: {'mark': mark, 'pageSize': pageSize, 'status': statusValue},
      decoder: (d) => parsePageDto<CreatorDrama>(d, CreatorDrama.fromJson),
    );
  }

  Future<Result<PageDto<DramaListItem>>> _fetchPublicDramaList(String key) {
    // Parse cache key format: "public_first|{langCode}|{tagId}|{sort}"
    // Pipe-separated so sort values like "completed_view" stay intact.
    final parts = key.split('|');
    final tagId = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
    final sort = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null;
    return _api.safeGet(
      _publicDramas,
      query: {
        'mark': null,
        'pageSize': 20,
        'name': null,
        'tagId': tagId,
        'sort': sort,
      },
      decoder: (d) => parsePageDto<DramaListItem>(d, DramaListItem.fromJson),
    );
  }

  Future<Result<DramaDetail>> _fetchDramaDetail(String key) {
    final separator = key.lastIndexOf('_');
    final dramaId = separator > 0 ? key.substring(0, separator) : key;
    return _api.safeGet(
      '$_publicDramas/$dramaId/detail',
      decoder: DramaDetail.fromNestedJson,
    );
  }

  Future<Result<DramaPlayResponse>> _fetchEpisodePlay(String key) {
    // Parse key format: "${dramaId}_${episodeNo}_$langCode"
    final lastUnderscore = key.lastIndexOf('_');
    if (lastUnderscore <= 0) {
      return Future.value(
        Result.failure(ApiError.parse('Invalid episode cache key: $key')),
      );
    }
    final temp = key.substring(0, lastUnderscore); // "${dramaId}_${episodeNo}"
    final secondLastUnderscore = temp.lastIndexOf('_');
    if (secondLastUnderscore <= 0) {
      return Future.value(
        Result.failure(ApiError.parse('Invalid episode cache key: $key')),
      );
    }
    final episodeNoStr = temp.substring(secondLastUnderscore + 1);
    final episodeNo = int.tryParse(episodeNoStr);
    if (episodeNo == null) {
      return Future.value(
        Result.failure(ApiError.parse('Invalid episode number: $key')),
      );
    }
    final dramaId = temp.substring(0, secondLastUnderscore);
    return _api.safeGet(
      '$_publicDramas/$dramaId/episodes/$episodeNo/detail',
      decoder: decodeWith(DramaPlayResponse.fromNestedJson),
    );
  }

  Future<Result<PageDto<StoryComment>>> _fetchComments(String key) {
    // Key is the episode (work) id.
    if (key.isEmpty) {
      return Future.value(
        Result.failure(ApiError.parse('Invalid comment cache key: $key')),
      );
    }
    return _api.safeGet(
      '$_publicWorks/$key/comments',
      decoder: (d) {
        return parsePageDto<StoryComment>(d, StoryComment.fromJson);
      },
    );
  }

  Future<Result<PageDto<StoryComment>>> _fetchCommentReplies(String key) {
    // Key is the root comment id.
    if (key.isEmpty) {
      return Future.value(
        Result.failure(ApiError.parse('Invalid reply cache key: $key')),
      );
    }
    return _api.safeGet(
      '$_publicComments/$key/replies',
      decoder: (d) {
        return parsePageDto<StoryComment>(d, StoryComment.fromJson);
      },
    );
  }

  /// Key format: `${dramaId}|first|${pageSize}|${langCode}`.
  Future<Result<PageDto<DramaEpisodeListItem>>> _fetchEpisodeList(String key) {
    final parts = key.split('|');
    final dramaId = parts.isNotEmpty ? parts[0] : '';
    if (dramaId.isEmpty) {
      return Future.value(
        Result.failure(ApiError.parse('Invalid episode list cache key: $key')),
      );
    }
    final pageSize = parts.length > 2 ? int.tryParse(parts[2]) ?? 50 : 50;
    return _api.safeGet(
      '$_publicDramas/$dramaId/episodes',
      query: {'mark': null, 'pageSize': pageSize},
      decoder: (d) => parsePageDto(d, DramaEpisodeListItem.fromJson),
    );
  }

  String _episodeListCacheKey(String dramaId, {int pageSize = 50}) {
    final locale = StoryLocaleController.instance.current;
    final langCode = locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
    return '$dramaId|first|$pageSize|$langCode';
  }

  /// Pre-fetch an episode's play data via CacheChain (memory → Hive → network).
  /// Returns the cached play response when prefetch succeeds.
  @override
  Future<DramaPlayResponse?> prefetchEpisode(
    String dramaId,
    int episodeNo,
  ) async {
    final existing = await peekPrefetchedEpisode(dramaId, episodeNo);
    if (existing != null) return existing;

    final locale = StoryLocaleController.instance.current;
    final langCode = locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
    final cacheKey = '${dramaId}_${episodeNo}_$langCode';

    return _coalescer.run(
      RequestKeys.dramaEpisodePrefetch(cacheKey),
      () => _prefetchEpisodeImpl(cacheKey),
    );
  }

  Future<DramaPlayResponse?> _prefetchEpisodeImpl(String cacheKey) async {
    final negative = _negativeEpisodePlay(cacheKey);
    if (negative != null) return null;
    await _evictStaleProtectedPlay(cacheKey);
    final result = await _episodePlayCache.get(cacheKey);
    if (result.isFailure) {
      _rememberNegativeEpisodePlay(cacheKey, result.errorOrNull);
      return null;
    }
    _rememberUnsignedProtected(cacheKey, result.dataOrNull);
    if (result.isSuccess && result.dataOrNull != null) {
      StoryLogger.d('Prefetched via CacheChain: $cacheKey', tag: 'DramaRepo');
      return result.dataOrNull;
    }
    return null;
  }

  @override
  Future<DramaPlayResponse?> peekPrefetchedEpisode(
    String dramaId,
    int episodeNo,
  ) async {
    // Local-only: never hits the network (use [prefetchEpisode] to fetch).
    final locale = StoryLocaleController.instance.current;
    final langCode = locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
    final cacheKey = '${dramaId}_${episodeNo}_$langCode';
    final play = await _episodePlayCache.getCachedOnly(cacheKey);
    if (play == null) return null;
    // If the cached play has expired CloudFront cookies, evict and miss.
    if (play.signedCookies != null && !play.signedCookies!.isValid) {
      StoryLogger.d(
        'peekPrefetchedEpisode evicting expired cookies: $cacheKey',
        tag: 'DramaRepo',
      );
      await _episodePlayCache.evict(cacheKey);
      return null;
    }
    // Unsigned CloudFront plays in Hive are stale (guest fetch, or a
    // backend omit). Miss so the next getEpisodeDetail can refetch —
    // unless this process already confirmed the network has no cookies.
    if (play.isUnsignedProtectedPlay &&
        !_unsignedProtectedConfirmed.contains(cacheKey)) {
      StoryLogger.d(
        'peekPrefetchedEpisode evicting unsigned CloudFront play: $cacheKey',
        tag: 'DramaRepo',
      );
      await _episodePlayCache.evict(cacheKey);
      return null;
    }
    return play;
  }

  @override
  void clearPrefetchCache(String dramaId, int episodeNo) {
    final locale = StoryLocaleController.instance.current;
    final langCode = locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
    final cacheKey = '${dramaId}_${episodeNo}_$langCode';
    _episodePlayNegative.remove(cacheKey);
    _episodePlayCache.evict(cacheKey);
    _episodePlayMemory.evict(cacheKey);
  }

  String _episodePlayCacheKey(String dramaId, int episodeNo) {
    final locale = StoryLocaleController.instance.current;
    final langCode = locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
    return '${dramaId}_${episodeNo}_$langCode';
  }

  Result<DramaPlayResponse>? _negativeEpisodePlay(String cacheKey) {
    final entry = _episodePlayNegative[cacheKey];
    if (entry == null) return null;
    if (DateTime.now().millisecondsSinceEpoch >= entry.$2) {
      _episodePlayNegative.remove(cacheKey);
      return null;
    }
    return Result.failure(entry.$1);
  }

  void _rememberNegativeEpisodePlay(String cacheKey, ApiError? error) {
    if (error is! BusinessError ||
        error.code != StoryConstants.episodeTranscodeFailedCode) {
      return;
    }
    if (_episodePlayNegative.length >= _maxNegativePlayEntries) {
      _episodePlayNegative.remove(_episodePlayNegative.keys.first);
    }
    _episodePlayNegative[cacheKey] = (
      error,
      DateTime.now().add(_transcodeFailedTtl).millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> patchCachedEpisodePlay(
    String dramaId,
    int episodeNo, {
    bool? likedByMe,
    int? likeCount,
    bool? favoritedByMe,
    int? commentCountDelta,
  }) async {
    final cacheKey = _episodePlayCacheKey(dramaId, episodeNo);
    final cached = await _episodePlayCache.getCachedOnly(cacheKey);
    if (cached == null) return;
    final nextCommentCount = commentCountDelta == null
        ? null
        : ((cached.commentCount ?? 0) + commentCountDelta).clamp(0, 1 << 31);
    await _episodePlayCache.put(
      cacheKey,
      cached.copyWith(
        likedByMe: likedByMe,
        likeCount: likeCount,
        favoritedByMe: favoritedByMe,
        commentCount: nextCommentCount,
      ),
    );
  }

  @override
  Future<Result<PageDto<DramaListItem>>> listPublic({
    String? mark,
    int pageSize = 20,
    String? name,
    String? tagId,
    String? sort,
  }) async {
    final cacheKey = _publicListCacheKey(tagId: tagId, sort: sort);
    final normalizedName = name?.trim();
    final hasNameFilter = normalizedName?.isNotEmpty == true;
    // Name lookup must hit the API: the first-page cache key intentionally
    // contains only the normal list filters and cannot satisfy a title query.
    if (mark == null && !hasNameFilter) {
      return _dramaListCache.get(cacheKey);
    }
    return _api.safeGet(
      _publicDramas,
      query: {
        'mark': mark,
        'pageSize': pageSize,
        'name': hasNameFilter ? normalizedName : null,
        'tagId': tagId,
        'sort': sort,
      },
      decoder: (d) => parsePageDto<DramaListItem>(d, DramaListItem.fromJson),
    );
  }

  @override
  Future<void> invalidatePublicListCache({String? tagId, String? sort}) async {
    await _dramaListCache.evict(_publicListCacheKey(tagId: tagId, sort: sort));
  }

  String _publicListCacheKey({String? tagId, String? sort}) {
    final locale = StoryLocaleController.instance.current;
    final langCode = locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
    return 'public_first|$langCode|${tagId ?? ''}|${sort ?? ''}';
  }

  @override
  Future<Result<PageDto<DramaListItem>>> searchPublic({
    required String keyword,
    int limit = 20,
  }) async {
    return _api.safeGet(
      '$_publicDramas/search',
      query: {'keyword': keyword, 'limit': limit},
      decoder: (d) {
        try {
          final list = parseList<Map<String, dynamic>>(d, (x) => x);
          final mapped = list.map(DramaListItem.fromJson).toList();
          return PageDto<DramaListItem>(list: mapped);
        } catch (_) {
          return parsePageDto<DramaListItem>(d, DramaListItem.fromJson);
        }
      },
    );
  }

  @override
  Future<Result<PageDto<DramaListItem>>> listMyDramas({
    String? mark,
    int pageSize = 20,
    String? status,
  }) => _api.safeGet(
    _creatorDramas,
    query: {'mark': mark, 'pageSize': pageSize, 'status': status},
    decoder: (d) => parsePageDto<DramaListItem>(d, DramaListItem.fromJson),
  );

  @override
  Future<Result<void>> deleteDrama(String dramaId) =>
      _api.safeDelete('$_creatorDramas/$dramaId', decoder: (_) {});

  @override
  Future<Result<int>> getOnlineDramaCount() => _api.safeGet(
    '/api/mini-drama/creator/dramas/online/count',
    decoder: (d) => int.tryParse(d?.toString() ?? '') ?? 0,
  );

  @override
  Future<Result<CreatorDrama>> createDrama(CreateDramaRequest request) =>
      _api.safePost(
        _creatorDramas,
        body: request.toJson(),
        decoder: decodeWith(CreatorDrama.fromJson),
      );

  @override
  Future<Result<CreatorDrama>> getCreatorDrama(String dramaId) => _api.safeGet(
    '$_creatorDramas/$dramaId',
    decoder: decodeWith(CreatorDrama.fromJson),
  );

  @override
  Future<Result<CreatorDrama>> updateDramaEditRevision(
    String dramaId,
    DramaEditRequest request,
  ) => _api.safePut(
    '$_creatorDramas/$dramaId',
    body: request.toJson(),
    decoder: decodeWith(CreatorDrama.fromJson),
  );

  @override
  Future<Result<DramaEditSession>> getEditSession(String dramaId) =>
      _api.safeGet(
        '$_creatorDramas/$dramaId/edit-sessions',
        decoder: decodeWith(DramaEditSession.fromJson),
      );

  @override
  Future<Result<PageDto<CreatorDrama>>> listMyCreatorDramas({
    String? mark,
    int pageSize = 20,
    String? status,
  }) {
    // Only cache first page of "全部" (status == null); other filters bypass cache.
    if (mark == null && status == null) {
      return _creatorDramasCache.get('creator|first|$pageSize|');
    }
    return _api.safeGet(
      _creatorDramas,
      query: {'mark': mark, 'pageSize': pageSize, 'status': status},
      decoder: (d) => parsePageDto<CreatorDrama>(d, CreatorDrama.fromJson),
    );
  }

  @override
  Future<void> invalidateCreatorDramasCache({
    String? status,
    int pageSize = 20,
  }) async {
    if (status == null) {
      await _creatorDramasCache.evict('creator|first|$pageSize|');
    }
  }

  @override
  Future<Result<DramaDetail>> getDetail(
    String dramaId, {
    bool forceRefresh = false,
  }) async {
    final locale = StoryLocaleController.instance.current;
    final langCode = locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
    final cacheKey = '${dramaId}_$langCode';
    if (forceRefresh) {
      await _dramaDetailCache.evict(cacheKey);
    }
    final result = await _dramaDetailCache.get(cacheKey);
    // Older cache entries may have serialized boundActorCollection with only
    // `name` (pre–boundActorAvatar). Evict and refetch so actor IP avatars
    // can render on the drama detail cast row.
    if (result.isSuccess &&
        _rolesMissingBoundActorAvatar(result.dataOrNull?.roles)) {
      StoryLogger.d(
        'getDetail evicting stale roles without actor avatar: $cacheKey',
        tag: 'DramaRepo',
      );
      await _dramaDetailCache.evict(cacheKey);
      return _dramaDetailCache.get(cacheKey);
    }
    return result;
  }

  @override
  Future<DramaDetail?> peekDetail(String dramaId) async {
    final locale = StoryLocaleController.instance.current;
    final langCode = locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
    final cached = await _dramaDetailCache.getCachedOnly(
      '${dramaId}_$langCode',
    );
    // Pre–boundActorAvatar entries are unusable for cast rendering — treat
    // as a miss so callers fall through to a network fetch.
    if (cached != null && _rolesMissingBoundActorAvatar(cached.roles)) {
      return null;
    }
    return cached;
  }

  /// Language codes used in detail/episode cache keys. Counters
  /// (favoriteCount etc.) are language-independent, so invalidation must
  /// cover every language partition, not just the active one.
  static const List<String> _cacheLangCodes = ['zh', 'en'];

  @override
  Future<void> invalidateDetailCache(String dramaId) async {
    final locale = StoryLocaleController.instance.current;
    final langCode = locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
    for (final lang in {langCode, ..._cacheLangCodes}) {
      await _dramaDetailCache.evict('${dramaId}_$lang');
    }
  }

  static bool _rolesMissingBoundActorAvatar(List<RoleCharacter>? roles) {
    if (roles == null || roles.isEmpty) return false;
    for (final role in roles) {
      if (!role.isBound) continue;
      final avatar = role.boundActorAvatar?.trim();
      if (avatar == null || avatar.isEmpty) return true;
    }
    return false;
  }

  static bool _episodeListNeedsRefetch(List<DramaEpisodeListItem> list) {
    if (list.isEmpty) return false;
    return list.any((item) => item.episodeNo == null || item.episodeId.isEmpty);
  }

  @override
  Future<Result<PageDto<DramaEpisodeListItem>>> listEpisodes(
    String dramaId, {
    String? mark,
    int pageSize = 50,
    bool forceRefresh = false,
  }) async {
    // Cache only the first page; subsequent pages always hit the network.
    if (mark == null) {
      final cacheKey = _episodeListCacheKey(dramaId, pageSize: pageSize);
      if (forceRefresh) {
        await _episodeListCache.evict(cacheKey);
      }
      final cached = await _episodeListCache.getCachedOnly(cacheKey);
      if (cached != null && _episodeListNeedsRefetch(cached.list ?? const [])) {
        StoryLogger.d(
          'listEpisodes evicting stale nested-parse cache: $cacheKey',
          tag: 'DramaRepo',
        );
        await _episodeListCache.evict(cacheKey);
      }
      return _episodeListCache.get(cacheKey);
    }
    return _api.safeGet(
      '$_publicDramas/$dramaId/episodes',
      query: {'mark': mark, 'pageSize': pageSize},
      decoder: (d) => parsePageDto(d, DramaEpisodeListItem.fromJson),
    );
  }

  @override
  Future<Result<DramaPlayResponse>> getEpisodeDetailByEpisodeId(
    String episodeId,
  ) {
    return _api.safeGet(
      '$_publicDramas/episodes/$episodeId/detail',
      decoder: decodeWith(DramaPlayResponse.fromNestedJson),
    );
  }

  @override
  Future<Result<DramaPlayResponse>> getEpisodeDetail(
    String dramaId,
    int episodeNo, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = _episodePlayCacheKey(dramaId, episodeNo);
    if (forceRefresh) {
      _episodePlayNegative.remove(cacheKey);
      _unsignedProtectedConfirmed.remove(cacheKey);
      await _episodePlayCache.evict(cacheKey);
    }
    final negative = _negativeEpisodePlay(cacheKey);
    if (negative != null) return negative;
    await _evictStaleProtectedPlay(cacheKey);
    final result = await _episodePlayCache.get(cacheKey);
    if (result.isFailure) {
      _rememberNegativeEpisodePlay(cacheKey, result.errorOrNull);
      return result;
    }
    _rememberUnsignedProtected(cacheKey, result.dataOrNull);
    return result;
  }

  @override
  Future<Result<void>> toggleFavorite(
    String id, {
    WorkContentType type = WorkContentType.shortDrama,
    String? episodeId,
    FavoriteTarget target = FavoriteTarget.drama,
  }) async {
    if (target == FavoriteTarget.work) {
      final workId = (episodeId != null && episodeId.isNotEmpty)
          ? episodeId
          : (type.isShortVideo ? id : null);
      if (workId == null || workId.isEmpty) {
        return Result.failure(
          ApiError.validation('episodeId required for work favorite'),
        );
      }
      if (type.isShortVideo) {
        return _api.safePost(
          '$_userShortVideos/$workId/favorite',
          body: <String, dynamic>{},
          decoder: (_) {},
        );
      }
      // 单集短剧: /user/dramas/episodes/{episodeId}/favorite
      return _api.safePost(
        '$_userDramas/episodes/$workId/favorite',
        body: <String, dynamic>{},
        decoder: (_) {},
      );
    }

    // 整剧: /user/dramas/{dramaId}/favorite
    final result = await _api.safePost<void>(
      '$_userDramas/$id/favorite',
      body: <String, dynamic>{},
      decoder: (_) {},
    );
    if (result.isSuccess) {
      try {
        await invalidateDetailCache(id);
      } catch (e) {
        StoryLogger.w(
          'detail cache invalidation failed after favorite toggle: $e',
          tag: 'DramaRepo',
        );
      }
    }
    return result;
  }

  @override
  Future<Result<void>> toggleEpisodeLike(
    String dramaId,
    String episodeId, {
    WorkContentType type = WorkContentType.shortDrama,
  }) {
    if (type.isShortVideo) {
      return _api.safePost(
        '$_userShortVideos/$episodeId/like',
        body: <String, dynamic>{},
        decoder: (_) {},
      );
    }
    return _api.safePost(
      '$_userDramas/$dramaId/episodes/$episodeId/like',
      body: <String, dynamic>{},
      decoder: (_) {},
    );
  }

  @override
  Future<Result<void>> unlockEpisode(String dramaId, String sig) =>
      _api.safePost(
        '$_userDramas/$dramaId/unlock/signature',
        body: {'signature': sig},
        decoder: (_) {},
      );

  @override
  Future<Result<void>> unlockEpisodeBatch(String dramaId, String sig) =>
      _api.safePost(
        '$_userDramas/$dramaId/unlock/batch-signature',
        body: {'signature': sig},
        decoder: (_) {},
      );

  @override
  Future<Result<PageDto<StoryComment>>> getEpisodeComments(
    String episodeId, {
    String? mark,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    // Only the first page (no cursor) is served from the comment cache; paged
    // requests always hit the network so cursors never go stale. Reopening
    // the comment sheet forces a refresh so new comments are visible.
    if (mark != null) {
      return _fetchCommentsPage(episodeId, mark, pageSize);
    }
    if (forceRefresh) {
      await _commentsCache.evict(episodeId);
    }
    return _commentsCache.get(episodeId);
  }

  @override
  Future<Result<PageDto<StoryComment>>> getCommentReplies(
    String rootId, {
    String? mark,
    int pageSize = 20,
  }) {
    // Only the default-size first page (no cursor) is served from the reply
    // cache; custom batch sizes (first-expand 3 / incremental 10) and paged
    // requests always hit the network so cursors never go stale.
    if (mark != null || pageSize != 20) {
      return _fetchRepliesPage(rootId, mark, pageSize);
    }
    return _repliesCache.get(rootId);
  }

  /// Fetches one page of comments. The terminal cursor `-1` — and any other
  /// illegal cursor — yields an empty page (not an error) so the caller's
  /// pagination loop stops cleanly.
  Future<Result<PageDto<StoryComment>>> _fetchCommentsPage(
    String episodeId,
    String mark,
    int pageSize,
  ) {
    if (mark == _commentsEndMark) {
      return _emptyCommentsPage();
    }
    return _api.safeGet(
      '$_publicWorks/$episodeId/comments',
      query: {'mark': mark, 'pageSize': pageSize},
      decoder: (d) => parsePageDto<StoryComment>(d, StoryComment.fromJson),
    );
  }

  /// Fetches one page of replies (second-level comments). Shares the cursor
  /// and empty-page semantics of [_fetchCommentsPage].
  Future<Result<PageDto<StoryComment>>> _fetchRepliesPage(
    String rootId,
    String? mark,
    int pageSize,
  ) {
    if (mark == _commentsEndMark) {
      return _emptyCommentsPage();
    }
    return _api.safeGet(
      '$_publicComments/$rootId/replies',
      query: {'mark': mark, 'pageSize': pageSize},
      decoder: (d) => parsePageDto<StoryComment>(d, StoryComment.fromJson),
    );
  }

  /// Terminal page: no more replies, and requesting again must not error.
  static Future<Result<PageDto<StoryComment>>> _emptyCommentsPage() {
    return Future.value(
      Result<PageDto<StoryComment>>.success(
        const PageDto<StoryComment>(mark: '-1', hasMore: false, list: []),
      ),
    );
  }

  @override
  Future<Result<StoryComment>> getComment(String commentId) => _api.safeGet(
    '$_publicComments/$commentId',
    decoder: decodeWith(StoryComment.fromJson),
  );

  @override
  Future<Result<StoryComment>> postEpisodeComment(
    String episodeId,
    String content,
  ) async {
    final result = await _api.safePost(
      '$_userWorks/$episodeId/comments',
      body: {'content': content},
      decoder: decodeWith(StoryComment.fromJson),
    );
    if (result.isSuccess) {
      unawaited(_commentsCache.evict(episodeId));
    }
    return result;
  }

  @override
  Future<Result<StoryComment>> postCommentReply(
    String commentId, {
    required String content,
  }) async {
    final result = await _api.safePost(
      '$_userComments/$commentId/replies',
      body: <String, dynamic>{'content': content},
      decoder: decodeWith(StoryComment.fromJson),
    );
    if (result.isSuccess) {
      unawaited(_repliesCache.evict(commentId));
    }
    return result;
  }

  @override
  Future<void> invalidateRepliesCache(String rootId) =>
      _repliesCache.evict(rootId);

  @override
  Future<Result<void>> deleteComment(String commentId) => _api.safeDelete(
    '/api/mini-drama/user/comments/$commentId',
    decoder: (_) {},
  );

  @override
  Future<Result<void>> toggleCommentLike(
    String commentId, {
    required bool liked,
  }) {
    final path = '$_userComments/$commentId/like';
    if (liked) {
      return _api.safePost(
        path,
        body: <String, dynamic>{'commentId': commentId},
        decoder: (_) {},
      );
    }
    return _api.safeDelete(path, decoder: (_) {});
  }

  @override
  Future<void> invalidateCommentsCache(String episodeId) =>
      _commentsCache.evict(episodeId);

  @override
  Future<void> clearUserScopedCaches() async {
    _unsignedProtectedConfirmed.clear();
    await Future.wait([
      _episodePlayCache.clear(),
      _commentsCache.clear(),
      _repliesCache.clear(),
      _creatorDramasCache.clear(),
      _episodeListCache.clear(),
    ]);
  }

  /// Expired cookies always refetch. Unsigned CloudFront cache hits refetch
  /// once per process so a guest/Hive poison does not 403 for 24h; a network
  /// payload that is still unsigned is remembered and not hammered.
  Future<void> _evictStaleProtectedPlay(String cacheKey) async {
    final cached = await _episodePlayCache.getCachedOnly(cacheKey);
    if (cached == null) return;
    final url = cached.effectivePlayUrl;
    if (url == null || url.isEmpty) {
      StoryLogger.d(
        'getEpisodeDetail evicting play with empty url: $cacheKey',
        tag: 'DramaRepo',
      );
      await _episodePlayCache.evict(cacheKey);
      return;
    }
    final cookies = cached.signedCookies;
    final expired = cookies != null && !cookies.isValid;
    if (expired) {
      StoryLogger.d(
        'getEpisodeDetail evicting expired cookies: $cacheKey',
        tag: 'DramaRepo',
      );
      await _episodePlayCache.evict(cacheKey);
      return;
    }
    if (cached.isUnsignedProtectedPlay &&
        !_unsignedProtectedConfirmed.contains(cacheKey)) {
      StoryLogger.d(
        'getEpisodeDetail evicting unsigned CloudFront play: $cacheKey',
        tag: 'DramaRepo',
      );
      await _episodePlayCache.evict(cacheKey);
    }
  }

  void _rememberUnsignedProtected(String cacheKey, DramaPlayResponse? play) {
    if (play != null &&
        play.isUnsignedProtectedPlay &&
        play.signedCookies == null) {
      _unsignedProtectedConfirmed.add(cacheKey);
      return;
    }
    if (play != null && play.hasUsableSignedCookies) {
      _unsignedProtectedConfirmed.remove(cacheKey);
    }
  }

  @override
  Future<Result<DramaNftMintDigest>> mintDramaNft(
    String dramaId,
    MintDramaNftRequest request,
  ) => _api.safePost(
    '$_creatorDramas/$dramaId/nft/mint',
    body: request.toJson(),
    decoder: decodeWith(DramaNftMintDigest.fromJson),
  );

  @override
  Future<Result<PageDto<DramaReview>>> getReviews({
    required String dramaId,
    String? mark,
    int pageSize = 20,
  }) => _api.safeGet(
    '$_publicDramas/$dramaId/reviews',
    query: {'mark': mark, 'pageSize': pageSize},
    decoder: (d) => parsePageDto<DramaReview>(d, DramaReview.fromJson),
  );

  @override
  Future<Result<DramaReview?>> getMyReview({required String dramaId}) =>
      _api.safeGet(
        '$_userDramas/$dramaId/my-review',
        decoder: (d) {
          if (d == null) return null;
          final map = d as Map<String, dynamic>;
          if (map['id'] == null) return null;
          return DramaReview.fromJson(map);
        },
      );

  @override
  Future<Result<void>> trackEpisode(
    String dramaId,
    String episodeId,
    EpisodeTrackEvent event, {
    required String deviceId,
    WorkContentType type = WorkContentType.shortDrama,
  }) {
    if (type.isShortVideo) {
      final action = switch (event) {
        EpisodeTrackEvent.play => 'play',
        EpisodeTrackEvent.complete => 'complete',
      };
      StoryLogger.d(
        'POST short-videos/$action episodeId=$episodeId dramaId=$dramaId',
        tag: 'play-report-api',
      );
      return _api.safePost(
        '$_userShortVideos/$episodeId/$action',
        headers: {'Device-ID': deviceId},
        body: <String, dynamic>{},
        decoder: (_) {},
      );
    }
    final path = episodeTrackEventPath(event);
    StoryLogger.d(
      'POST $path dramaId=$dramaId episodeId=$episodeId',
      tag: 'play-report-api',
    );
    return _api.safePost(
      '$_userDramas/$dramaId/$path',
      query: {'episodeId': episodeId},
      headers: {'Device-ID': deviceId},
      body: <String, dynamic>{},
      decoder: (_) {},
    );
  }

  @override
  Future<Result<DramaReview>> submitReview({
    required String dramaId,
    required int rating,
    String? reviewText,
  }) {
    final body = <String, dynamic>{'rating': rating};
    if (reviewText != null) {
      body['reviewText'] = reviewText;
    }
    return _api.safePost(
      '$_userDramas/$dramaId/reviews',
      body: body,
      decoder: decodeWith(DramaReview.fromJson),
    );
  }

  @override
  Future<Result<DramaReviewsData>> getReviewsWithMyReview({
    required String dramaId,
    String? mark,
    int pageSize = 20,
  }) async {
    final futures = await Future.wait([
      getReviews(dramaId: dramaId, mark: mark, pageSize: pageSize),
      getMyReview(dramaId: dramaId),
    ]);

    final reviewsRes = futures[0] as Result<PageDto<DramaReview>>;
    final myReviewRes = futures[1] as Result<DramaReview?>;

    if (reviewsRes.isFailure) {
      return Result.failure(reviewsRes.errorOrNull!);
    }

    final reviewsData = reviewsRes.dataOrNull!;
    final myReviewData = myReviewRes.isSuccess ? myReviewRes.dataOrNull : null;

    return Result.success(
      DramaReviewsData(reviews: reviewsData, myReview: myReviewData),
    );
  }

  @override
  Future<Result<List<ReportTypeItem>>> getReportTypes({String? scope}) =>
      _api.safeGet(
        _ugcReportTypesPath,
        query: {if (scope != null && scope.isNotEmpty) 'scope': scope},
        decoder: (d) => parseList<ReportTypeItem>(d, ReportTypeItem.fromJson),
      );

  @override
  Future<Result<void>> reportEpisode({
    required String dramaId,
    required String episodeId,
    required String reportType,
    String? description,
    WorkContentType type = WorkContentType.shortDrama,
  }) {
    // Short videos and drama episodes share the UGC work report.
    final body = SubmitReportRequest(
      reportType: reportType,
      description: description,
    ).toJson();
    return _api.safePost(
      '$_ugcWorks/$episodeId/report',
      body: body,
      decoder: (_) {},
    );
  }

  @override
  Future<Result<void>> reportDrama({
    required String dramaId,
    required String reportType,
    String? description,
  }) {
    final body = SubmitReportRequest(
      reportType: reportType,
      description: description,
    ).toJson();
    return _api.safePost(
      '$_ugcDramas/$dramaId/report',
      body: body,
      decoder: (_) {},
    );
  }

  @override
  Future<Result<void>> reportComment({
    required String commentId,
    required String reportType,
    String? description,
  }) {
    final body = SubmitReportRequest(
      reportType: reportType,
      description: description,
    ).toJson();
    return _api.safePost(
      '$_ugcComments/$commentId/report',
      body: body,
      decoder: (_) {},
    );
  }

  @override
  Future<Result<void>> reportUser({
    required String userId,
    required String reportType,
    String? description,
  }) {
    final body = SubmitReportRequest(
      reportType: reportType,
      description: description,
    ).toJson();
    return _api.safePost(
      '$_ugcUsers/$userId/report',
      body: body,
      decoder: (_) {},
    );
  }

  @override
  Future<void> dispose() async {
    await _dramaListMemory.clear();
    await _dramaDetailMemory.clear();
    await _episodePlayMemory.clear();
    await _creatorDramasMemory.clear();
    await _episodeListMemory.clear();
  }
}
