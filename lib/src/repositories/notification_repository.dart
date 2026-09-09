import '../api/story_api_client.dart';
import '../core/cache_strategy.dart';
import '../core/json_helpers.dart';
import '../core/result.dart';
import '../core/story_logger.dart';
import '../data/repository/story_local_repository.dart';
import '../model/notification_models.dart';
import 'notification_mock_data.dart';

/// 站内通知相关 API 仓储。
abstract class NotificationRepository {
  /// 获取站内通知列表。
  ///
  /// `GET /api/userWallet/notification/list`
  Future<Result<NotificationPage>> listNotifications(
    NotificationListRequest request,
  );

  /// Reads a cached first page without making a network request.
  Future<NotificationPage?> getCachedFirstPage(NotificationListRequest request);

  /// Clears all locally persisted notification first pages.
  Future<void> clearCachedFirstPages();

  /// 获取站内通知未读计数。
  ///
  /// `GET /api/userWallet/notification/unreadCount`
  Future<Result<NotificationUnreadCount>> getUnreadCount();

  /// 删除指定站内通知。
  ///
  /// `POST /api/userWallet/notification/delete`
  Future<Result<bool>> deleteNotification(NotificationDeleteRequest request);

  /// 将指定通知或整个 Tab 标记为已读。
  ///
  /// `POST /api/userWallet/notification/read`
  Future<Result<bool>> markNotificationsRead(NotificationReadRequest request);

  Future<void> dispose();
}

class NotificationRepositoryImpl implements NotificationRepository {
  static const _notificationListPath = '/api/userWallet/notification/list';
  static const _unreadCountPath = '/api/userWallet/notification/unreadCount';
  static const _deletePath = '/api/userWallet/notification/delete';
  static const _readPath = '/api/userWallet/notification/read';
  static const _cachePrefix = 'notification_first_page_';
  static const _drawerCacheTtl = Duration(days: 7);
  static const _listCacheTtl = Duration(minutes: 5);

  final StoryApiClient _api;
  final StoryLocalRepository? _local;
  late final MemoryCacheLayer<String, NotificationPage> _memoryCache;
  late final HiveCacheLayer<NotificationPage>? _hiveCache;
  final Set<String> _knownCacheKeys = <String>{};

  NotificationRepositoryImpl(this._api, [this._local]) {
    _memoryCache = MemoryCacheLayer<String, NotificationPage>(
      maxEntries: 8,
      defaultTtl: _drawerCacheTtl,
    );
    final local = _local;
    _hiveCache = local == null
        ? null
        : HiveCacheLayer<NotificationPage>(
            box: local.cacheBox,
            defaultTtl: _drawerCacheTtl,
            prefix: _cachePrefix,
            decoder: (data) => NotificationPage.fromJson(deepStringMap(data)),
            encoder: (value) => value.toJson(),
          );
  }

  bool _isFirstPage(NotificationListRequest request) =>
      request.mark == null || request.mark == 0;

  Duration _cacheTtlFor(NotificationListRequest request) =>
      request.tab == null ? _drawerCacheTtl : _listCacheTtl;

  Duration _cacheTtlForKey(String key) =>
      key.contains('|tab=0|') ? _drawerCacheTtl : _listCacheTtl;

  String get _userScope {
    final user = _local?.getUser();
    final userId = user?.userId?.trim().isNotEmpty == true
        ? user!.userId!.trim()
        : user?.id?.trim();
    return Uri.encodeComponent(
      userId?.isNotEmpty == true ? userId! : 'current_session',
    );
  }

  String _cacheKey(NotificationListRequest request) {
    final eventType = request.eventType?.trim().toUpperCase() ?? 'ALL';
    return '$_userScope|tab=${request.tab ?? 0}'
        '|type=${Uri.encodeComponent(eventType)}'
        '|size=${request.pageSize ?? 20}';
  }

  Future<void> _cacheFirstPage(
    NotificationListRequest request,
    NotificationPage page,
  ) async {
    if (!_isFirstPage(request)) return;
    final key = _cacheKey(request);
    final ttl = _cacheTtlFor(request);
    _knownCacheKeys.add(key);
    try {
      await Future.wait([
        _memoryCache.set(key, page, ttl: ttl),
        if (_hiveCache case final hive?) hive.set(key, page, ttl: ttl),
      ]);
    } catch (error, stackTrace) {
      StoryLogger.w(
        'Cache notification first page failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'NotificationRepo',
      );
    }
  }

  @override
  Future<NotificationPage?> getCachedFirstPage(
    NotificationListRequest request,
  ) async {
    if (!_isFirstPage(request)) return null;
    final key = _cacheKey(request);
    _knownCacheKeys.add(key);
    final memory = await _memoryCache.get(key);
    if (memory != null) return memory;
    try {
      final persisted = await _hiveCache?.get(key);
      if (persisted != null) {
        await _memoryCache.set(key, persisted, ttl: _cacheTtlFor(request));
      }
      return persisted;
    } catch (error, stackTrace) {
      StoryLogger.w(
        'Read cached notification first page failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'NotificationRepo',
      );
      return null;
    }
  }

  Iterable<String> _currentUserCacheKeys() sync* {
    final scopePrefix = '$_userScope|';
    yield* _knownCacheKeys.where((key) => key.startsWith(scopePrefix));
    final box = _local?.cacheBox;
    if (box == null) return;
    final persistedPrefix = '$_cachePrefix$scopePrefix';
    for (final storedKey in box.keys) {
      final value = storedKey.toString();
      if (value.startsWith(persistedPrefix)) {
        yield value.substring(_cachePrefix.length);
      }
    }
  }

  Future<void> _updateCurrentUserCache(
    NotificationPage Function(NotificationPage page) update,
  ) async {
    final keys = _currentUserCacheKeys().toSet();
    for (final key in keys) {
      try {
        final page = await _memoryCache.get(key) ?? await _hiveCache?.get(key);
        if (page == null) continue;
        final updated = update(page);
        final ttl = _cacheTtlForKey(key);
        await _memoryCache.set(key, updated, ttl: ttl);
        await _hiveCache?.set(key, updated, ttl: ttl);
      } catch (error, stackTrace) {
        StoryLogger.w(
          'Update cached notification page failed',
          error: error,
          stackTrace: stackTrace,
          tag: 'NotificationRepo',
        );
      }
    }
  }

  @override
  Future<void> clearCachedFirstPages() async {
    _knownCacheKeys.clear();
    try {
      await Future.wait([
        _memoryCache.clear(),
        if (_hiveCache case final hive?) hive.clear(),
      ]);
    } catch (error, stackTrace) {
      StoryLogger.w(
        'Clear cached notification pages failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'NotificationRepo',
      );
    }
  }

  @override
  Future<Result<NotificationPage>> listNotifications(
    NotificationListRequest request,
  ) async {
    if (notificationListMockEnabled) {
      final page = mockNotificationPage(request);
      await _cacheFirstPage(request, page);
      return Result.success(page);
    }

    final result = await _api.safeGet(
      _notificationListPath,
      query: request.toJson(),
      decoder: decodeWith(NotificationPage.fromJson),
    );
    final page = result.dataOrNull;
    if (page != null) await _cacheFirstPage(request, page);
    return result;
  }

  @override
  Future<Result<NotificationUnreadCount>> getUnreadCount() => _api.safeGet(
    _unreadCountPath,
    decoder: decodeWith(NotificationUnreadCount.fromJson),
  );

  @override
  Future<Result<bool>> deleteNotification(
    NotificationDeleteRequest request,
  ) async {
    final result = await _api.safePost(
      _deletePath,
      body: request.toJson(),
      decoder: (data) => asBoolOrNull(data) ?? false,
    );
    if (result.isSuccess) {
      final id = request.id.toString();
      await _updateCurrentUserCache(
        (page) => NotificationPage(
          hasMore: page.hasMore,
          list: page.list
              ?.where((item) => item.id != id)
              .toList(growable: false),
          mark: page.mark,
          pageSize: page.pageSize,
        ),
      );
    }
    return result;
  }

  @override
  Future<Result<bool>> markNotificationsRead(
    NotificationReadRequest request,
  ) async {
    final result = await _api.safePost(
      _readPath,
      body: request.toJson(),
      decoder: (data) => asBoolOrNull(data) ?? false,
    );
    if (result.isSuccess) {
      final ids = request.ids?.map((id) => id.toString()).toSet();
      await _updateCurrentUserCache(
        (page) => NotificationPage(
          hasMore: page.hasMore,
          list: page.list
              ?.map(
                (item) =>
                    (request.tab != null && item.tab == request.tab) ||
                        (ids?.contains(item.id) ?? false)
                    ? item.copyWith(isRead: 1)
                    : item,
              )
              .toList(growable: false),
          mark: page.mark,
          pageSize: page.pageSize,
        ),
      );
    }
    return result;
  }

  @override
  Future<void> dispose() async {
    await _memoryCache.clear();
  }
}
