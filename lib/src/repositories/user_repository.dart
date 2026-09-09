import '../core/cache_strategy.dart';
import '../core/request_coalescer.dart';
import '../core/request_keys.dart';
import '../core/result.dart';
import '../core/json_helpers.dart';
import '../data/repository/story_local_repository.dart';
import '../model/models.dart';
import '../api/story_api_client.dart';

/// The type of drama list on a user's profile page.
enum ProfileDramaType { published, works, likes, favorites }

/// Server-side watch-history clearing scope.
enum WatchHistoryClearScope {
  all('ALL'),
  drama('DRAMA'),
  video('VIDEO');

  const WatchHistoryClearScope(this.apiValue);

  final String apiValue;
}

abstract class UserRepository {
  Future<Result<LoginResponse>> login(LoginRequest req);
  Future<Result<void>> logout();

  /// Gets the short-lived token and authenticated user id used to connect to
  /// the user's Centrifugo channels.
  Future<Result<CentrifugoConnectionInfo>> getCentrifugoConnectionInfo();

  Future<Result<UserProfile>> getProfile({bool forceRefresh = false});
  Future<Result<UserProfile>> getOtherProfile(String userId);
  Future<Result<UserWorkStats>> getWorkStats(String userId);

  /// 获取服务端账户资产；强制刷新时跳过 30 秒缓存。
  /// 与链上钱包余额分开，收益页暂时保留使用 [getBalances]。
  Future<Result<UserAssets>> getAssets({bool forceRefresh = false});

  Future<Result<List<WalletBalance>>> getBalances();
  void invalidateBalances();

  /// Returns the current user's most recently watched items (up to 10).
  Future<Result<List<WatchHistoryItem>>> getRecentWatchHistory({int limit = 3});

  /// Returns episode/short-video watch history, newest first.
  ///
  /// [mark] is the opaque `lastWatchedAt_id` cursor returned by the previous
  /// page. Omit it for the first page.
  Future<Result<PageDto<WatchHistoryVideo>>> getWatchHistoryVideos({
    String? mark,
    int pageSize = 20,
  });

  /// Returns drama-level watch history, newest first (one row per drama).
  ///
  /// Each row includes the last watched episode and a server-formatted
  /// progress label. Use `pageSize: 3` for the drawer preview.
  Future<Result<PageDto<WatchHistoryDrama>>> getWatchHistoryDramas({
    String? mark,
    int pageSize = 20,
  });

  /// Reports one or more episode watch timestamps for the current user.
  Future<Result<void>> reportWatchHistory(WatchHistoryReportRequest request);

  /// Clears server-side watch history for [scope].
  Future<Result<void>> clearWatchHistory({
    WatchHistoryClearScope scope = WatchHistoryClearScope.all,
  });

  Future<Result<PageDto<UserProfileContentItem>>> getUserProfileDramas({
    required String userId,
    required ProfileDramaType type,
    WorkContentType contentType = WorkContentType.shortDrama,
    String? mark,
    int pageSize = 20,
  });
  Future<Result<PageDto<NftPosition>>> getDramaNftPositions({
    String? mark,
    int pageSize = 20,
  });
  Future<Result<int>> getDramaNftCount();

  /// Paginated invitee list — `GET /api/userWallet/inviteRecords`.
  Future<Result<PageDto<SubordinateUser>>> getInviteRecords({
    String? mark,
    int pageSize = 20,
  });

  /// Invite summary — `GET /api/userWallet/inviteInfo`.
  Future<Result<InviteInfoSummary>> getInviteSummary();

  /// `POST /api/userWallet/bindInviteCode` — only users without an inviter.
  Future<Result<void>> bindInviteCode(String inviteCode);

  /// `POST /api/userWallet/skipInviteCode` — mark invite bind prompt as skipped.
  Future<Result<void>> skipInviteCode();

  /// Updates nickname and optional intro (`profile` in API body).
  Future<Result<void>> updateNickname({
    required String nickname,
    String? profile,
  });
  Future<Result<void>> updateAvatar(String avatarUrl);

  /// Marks the current user as deleted (`isDeleted`: 0 or 1).
  ///
  /// `POST /api/userWallet/updateDeleted` — soft flag only on the server.
  Future<Result<void>> updateDeleted({required int isDeleted});

  /// Drops memory + Hive profile cache for the current user.
  ///
  /// Call on login/logout so a new session cannot read the previous account's
  /// `user_profile_current_user` entry via [getProfile].
  Future<void> clearProfileCache();

  /// Writes [profile] into the current-user cache without a network fetch.
  Future<void> seedCurrentProfile(UserProfile profile);

  /// Follow [userId]. Idempotent (`POST /api/userWallet/follow/{id}`).
  Future<Result<void>> followUser(String userId);

  /// Unfollow [userId]. Idempotent (`DELETE /api/userWallet/follow/{id}`).
  Future<Result<void>> unfollowUser(String userId);

  /// Current login user's relation to [userId]
  /// (`GET /api/userWallet/users/{id}/relation`). Requires auth.
  Future<Result<FollowRelationStatus>> getFollowRelation(String userId);

  /// User search (`GET /api/userWallet/user/search`).
  ///
  /// Cursor page: first request `mark=0`, then pass the previous
  /// [PageDto.mark]. Stop when `hasMore` is false or `mark` is `-1`.
  Future<Result<PageDto<UserSearchItem>>> searchUsers({
    required String keyword,
    int pageSize = 20,
    String? mark,
  });

  Future<void> dispose();
}

class UserRepositoryImpl implements UserRepository {
  static const _userWallet = '/api/userWallet';

  static String _profileDramaPathSegment(ProfileDramaType type) =>
      switch (type) {
        ProfileDramaType.published => 'dramas',
        ProfileDramaType.works => 'works',
        ProfileDramaType.likes => 'likes',
        ProfileDramaType.favorites => 'favorites',
      };

  final StoryApiClient _api;
  final StoryLocalRepository? _local;
  final RequestCoalescer _coalescer;
  late final CacheChain<String, UserProfile> _profileCache;
  late final MemoryCacheLayer<String, UserProfile> _profileMemory;
  late final MemoryCacheLayer<String, FollowRelationStatus> _relationMemory;

  /// Bumped on logout / [clearProfileCache] so in-flight force profile fetches
  /// do not put a stale user into the cleared cache.
  int _profileWriteEpoch = 0;

  // ── In-memory TTL cache for wallet balances ──────────────────────────
  /// Short TTL since balances change frequently.
  static const Duration _balanceTtl = Duration(seconds: 30);
  List<WalletBalance>? _cachedBalances;
  DateTime? _cachedAt;

  UserRepositoryImpl(
    this._api, [
    this._local,
    RequestCoalescer? coalescer,
  ]) : _coalescer = coalescer ?? MemoryRequestCoalescer() {
    _profileMemory = MemoryCacheLayer<String, UserProfile>(maxEntries: 5);
    _relationMemory = MemoryCacheLayer<String, FollowRelationStatus>(
      defaultTtl: const Duration(seconds: 60),
    );

    final local = _local;
    final profileHive = local == null
        ? null
        : HiveCacheLayer<UserProfile>(
            box: local.cacheBox,
            prefix: 'user_profile_',
            decoder: (data) => UserProfile.fromJson(_asStringKeyedMap(data)),
            encoder: (value) => value.toJson(),
          );

    _profileCache = CacheChain(
      fetcher: (_) => _fetchProfile(),
      readLayers: [_profileMemory, ?profileHive],
      writeLayers: [_profileMemory, ?profileHive],
    );
  }

  static Map<String, dynamic> _asStringKeyedMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Cached value is not a JSON map');
  }

  Future<Result<UserProfile>> _fetchProfile() => _api.safeGet(
    '$_userWallet/userInfo',
    decoder: decodeWith(UserProfile.fromJson),
  );

  @override
  Future<Result<LoginResponse>> login(LoginRequest req) => _api.safePost(
    '$_userWallet/login',
    body: req.toJson(),
    decoder: decodeWith(LoginResponse.fromJson),
    retry: true,
  );

  @override
  Future<Result<void>> logout() async {
    final result = await _api.safePost(
      '$_userWallet/logout',
      body: <String, dynamic>{},
      decoder: (_) {},
      retry: true,
    );
    // Clear profile and relation caches on logout
    _profileWriteEpoch++;
    await _profileCache.clear();
    await _relationMemory.clear();
    invalidateBalances();
    return result;
  }

  @override
  Future<Result<CentrifugoConnectionInfo>> getCentrifugoConnectionInfo() =>
      _api.safeGet(
        '$_userWallet/centrifugo/token',
        decoder: decodeWith(CentrifugoConnectionInfo.fromJson),
      );

  @override
  Future<Result<UserProfile>> getProfile({bool forceRefresh = false}) async {
    const cacheKey = 'current_user';
    if (!forceRefresh) {
      return _profileCache.get(cacheKey);
    }

    // Coalesce concurrent forceRefresh callers (startup gate + invite prompt).
    final epoch = _profileWriteEpoch;
    return _coalescer.run(RequestKeys.userProfileForce, () async {
      final result = await _fetchProfile();
      if (epoch != _profileWriteEpoch) return result;
      final profile = result.dataOrNull;
      if (profile != null) {
        await _profileCache.put(cacheKey, profile);
      }
      return result;
    });
  }

  @override
  Future<Result<UserProfile>> getOtherProfile(String userId) => _api.safeGet(
    '$_userWallet/otherUserInfo',
    query: {'userId': userId},
    decoder: decodeWith(UserProfile.fromJson),
  );

  @override
  Future<Result<UserWorkStats>> getWorkStats(String userId) => _coalescer.run(
    RequestKeys.userWorkStats(userId),
    () => _api.safeGet(
      '/api/mini-drama/public/users/$userId/stats',
      decoder: decodeWith(UserWorkStats.fromJson),
    ),
  );

  /// Discard cached balances so next call re-fetches from API.
  @override
  void invalidateBalances() {
    _cachedBalances = null;
    _cachedAt = null;
  }

  @override
  Future<Result<UserAssets>> getAssets({bool forceRefresh = false}) async {
    if (forceRefresh) invalidateBalances();
    final result = await getBalances();
    return result.map(UserAssets.new);
  }

  @override
  Future<Result<List<WalletBalance>>> getBalances() async {
    // Return cached value if within TTL
    if (_cachedBalances != null && _cachedAt != null) {
      final age = DateTime.now().difference(_cachedAt!);
      if (age < _balanceTtl) {
        return Result.success(_cachedBalances!);
      }
    }

    final result = await _api.safeGet(
      '$_userWallet/assets',
      decoder: (d) {
        if (d is List) {
          return parseList<WalletBalance>(d, WalletBalance.fromJson);
        }
        if (d is Map<String, dynamic> && d['balances'] is List) {
          return parseList<WalletBalance>(
            d['balances'],
            WalletBalance.fromJson,
          );
        }
        return <WalletBalance>[];
      },
    );

    if (result.isSuccess) {
      _cachedBalances = result.dataOrNull;
      _cachedAt = DateTime.now();
    }

    return result;
  }

  @override
  Future<Result<List<WatchHistoryItem>>> getRecentWatchHistory({
    int limit = 3,
  }) => _api.safeGet(
    '/api/mini-drama/user/watch-history/recent',
    query: {'limit': limit.clamp(1, 10)},
    decoder: (data) =>
        parseList<WatchHistoryItem>(data, WatchHistoryItem.fromJson),
  );

  @override
  Future<Result<PageDto<WatchHistoryVideo>>> getWatchHistoryVideos({
    String? mark,
    int pageSize = 20,
  }) => _api.safeGet(
    '/api/mini-drama/user/watch-history/videos',
    query: {
      if (mark != null && mark.isNotEmpty) 'mark': mark,
      'pageSize': pageSize.clamp(1, 100),
    },
    decoder: (data) =>
        parsePageDto<WatchHistoryVideo>(data, WatchHistoryVideo.fromJson),
  );

  @override
  Future<Result<PageDto<WatchHistoryDrama>>> getWatchHistoryDramas({
    String? mark,
    int pageSize = 20,
  }) => _api.safeGet(
    '/api/mini-drama/user/watch-history/dramas',
    query: {
      if (mark != null && mark.isNotEmpty) 'mark': mark,
      'pageSize': pageSize.clamp(1, 100),
    },
    decoder: (data) =>
        parsePageDto<WatchHistoryDrama>(data, WatchHistoryDrama.fromJson),
  );

  @override
  Future<Result<void>> reportWatchHistory(WatchHistoryReportRequest request) =>
      _api.safePost(
        '/api/mini-drama/user/watch-history/report',
        body: request.toJson(),
        decoder: (_) {},
        retry: true,
      );

  @override
  Future<Result<void>> clearWatchHistory({
    WatchHistoryClearScope scope = WatchHistoryClearScope.all,
  }) => _api.safeDelete(
    '/api/mini-drama/user/watch-history',
    query: {'scope': scope.apiValue},
    decoder: (_) {},
  );

  @override
  Future<Result<PageDto<UserProfileContentItem>>> getUserProfileDramas({
    required String userId,
    required ProfileDramaType type,
    WorkContentType contentType = WorkContentType.shortDrama,
    String? mark,
    int pageSize = 20,
  }) {
    final key = RequestKeys.userProfileDramas(
      userId: userId,
      typeName: type.name,
      contentTypeName: contentType.name,
      mark: mark,
      pageSize: pageSize,
    );
    return _coalescer.run(
      key,
      () => _api.safeGet(
        '/api/mini-drama/user/profiles/$userId/${_profileDramaPathSegment(type)}',
        query: {
          'mark': mark,
          'pageSize': pageSize.toString(),
          if (type == ProfileDramaType.favorites) 'type': contentType.apiValue,
        },
        decoder: (d) => parsePageDto(d, UserProfileContentItem.fromJson),
      ),
    );
  }

  @override
  Future<Result<PageDto<NftPosition>>> getDramaNftPositions({
    String? mark,
    int pageSize = 20,
  }) => _api.safeGet(
    '/api/userWallet/dramaNft/positions',
    query: {'mark': mark, 'pageSize': pageSize},
    decoder: (d) => parsePageDto<NftPosition>(d, NftPosition.fromJson),
  );

  /// Fetches only the total used by the creator-page metric card.
  ///
  /// This intentionally does not deserialize [NftPosition] items. The backend
  /// may add or change item fields independently of the pagination envelope;
  /// one malformed item must not prevent the valid `total` from updating.
  @override
  Future<Result<int>> getDramaNftCount() => _api.safeGet(
    '/api/userWallet/dramaNft/positions',
    query: const {'pageSize': 1},
    decoder: (d) {
      final total = PageDto.parseTotal(normalizeJson(d)['total']);
      if (total == null) {
        throw const FormatException(
          'Missing or invalid total in drama NFT positions response',
        );
      }
      return total;
    },
  );

  @override
  Future<Result<PageDto<SubordinateUser>>> getInviteRecords({
    String? mark,
    int pageSize = 20,
  }) => _api.safeGet(
    '$_userWallet/inviteRecords',
    query: {'mark': mark, 'pageSize': pageSize},
    decoder: (d) => parsePageDto<SubordinateUser>(d, SubordinateUser.fromJson),
  );

  @override
  Future<Result<InviteInfoSummary>> getInviteSummary() => _api.safeGet(
    '$_userWallet/inviteInfo',
    decoder: (d) => InviteInfoSummary.fromJson(normalizeJson(d)),
  );

  @override
  Future<Result<void>> bindInviteCode(String inviteCode) => _api.safePost(
    '$_userWallet/bindInviteCode',
    body: {'inviteCode': inviteCode.trim()},
    decoder: (_) {},
  );

  @override
  Future<Result<void>> skipInviteCode() async {
    final result = await _api.safePost(
      '$_userWallet/skipInviteCode',
      decoder: (_) {},
    );
    if (result.isSuccess) {
      await _profileCache.clear();
    }
    return result;
  }

  @override
  Future<Result<void>> updateNickname({
    required String nickname,
    String? profile,
  }) async {
    final result = await _api.safePost(
      '$_userWallet/nickname',
      body: {'nickname': nickname, 'profile': ?profile},
      decoder: (_) {},
    );
    // Invalidate profile cache so the next getProfile() reflects the new name.
    if (result.isSuccess) {
      await _profileCache.clear();
    }
    return result;
  }

  @override
  Future<Result<void>> updateAvatar(String avatarUrl) async {
    final result = await _api.safePost(
      '$_userWallet/avatar',
      body: {'avatarUrl': avatarUrl},
      decoder: (_) {},
    );
    // Invalidate profile cache so the next getProfile() reflects the new avatar.
    if (result.isSuccess) {
      await _profileCache.clear();
    }
    return result;
  }

  @override
  Future<Result<void>> updateDeleted({required int isDeleted}) async {
    final result = await _api.safePost(
      '$_userWallet/updateDeleted',
      body: {'isDeleted': isDeleted},
      decoder: (_) {},
    );
    if (result.isSuccess) {
      await _profileCache.clear();
    }
    return result;
  }

  @override
  Future<void> clearProfileCache() async {
    _profileWriteEpoch++;
    await _profileCache.clear();
  }

  @override
  Future<void> seedCurrentProfile(UserProfile profile) =>
      _profileCache.put('current_user', profile);

  @override
  Future<Result<PageDto<UserSearchItem>>> searchUsers({
    required String keyword,
    int pageSize = 20,
    String? mark,
  }) {
    final cursor = mark?.trim();
    return _api.safeGet(
      '$_userWallet/user/search',
      query: {
        'keyword': keyword,
        'pageSize': pageSize.clamp(1, 100),
        'mark': (cursor == null || cursor.isEmpty) ? '0' : cursor,
      },
      decoder: (d) => parsePageDto<UserSearchItem>(d, UserSearchItem.fromJson),
    );
  }

  @override
  Future<Result<void>> followUser(String userId) async {
    final result = await _api.safePost(
      '$_userWallet/follow/$userId',
      body: <String, dynamic>{},
      decoder: (_) {},
      retry: true,
    );
    if (result.isSuccess) await _relationMemory.evict(userId);
    return result;
  }

  @override
  Future<Result<void>> unfollowUser(String userId) async {
    final result = await _api.safeDelete(
      '$_userWallet/follow/$userId',
      decoder: (_) {},
    );
    if (result.isSuccess) await _relationMemory.evict(userId);
    return result;
  }

  @override
  Future<Result<FollowRelationStatus>> getFollowRelation(String userId) async {
    final cached = await _relationMemory.get(userId);
    if (cached != null) return Result.success(cached);

    final result = await _api.safeGet(
      '$_userWallet/users/$userId/relation',
      decoder: (d) =>
          FollowRelationStatus.fromApi(normalizeJson(d)['status']?.toString()),
    );
    final data = result.dataOrNull;
    if (data != null) {
      await _relationMemory.set(userId, data);
    }
    return result;
  }

  @override
  Future<void> dispose() async {}
}
