import '../api/story_api_client.dart';
import '../core/json_helpers.dart';
import '../core/request_coalescer.dart';
import '../core/request_keys.dart';
import '../core/result.dart';
import '../model/follow_models.dart';
import '../model/page_dto.dart';

abstract class FollowRepository {
  Future<Result<PageDto<FollowListItem>>> listFollowings({
    required String userId,
    String? mark,
    int pageSize = 20,
  });

  Future<Result<PageDto<FollowListItem>>> listFollowers({
    required String userId,
    String? mark,
    int pageSize = 20,
  });

  Future<Result<PageDto<FollowListItem>>> listMutuals({
    required String userId,
    String? mark,
    int pageSize = 20,
  });

  Future<Result<FollowStats>> getStats(String userId);

  Future<Result<FollowRelationStatus>> getRelation(String userId);

  Future<Result<BlockRelation>> getBlockRelation(String userId);

  Future<Result<void>> follow(String targetUserId);

  Future<Result<void>> unfollow(String targetUserId);

  Future<Result<void>> block(String targetUserId);

  Future<Result<void>> unblock(String targetUserId);

  /// Remove [followerId] from the current user's fans list.
  /// Web: `DELETE /api/userWallet/follower/{followerId}`.
  Future<Result<void>> removeFollower(String followerId);

  Future<void> dispose();
}

class FollowRepositoryImpl implements FollowRepository {
  static const _userWallet = '/api/userWallet';

  final StoryApiClient _api;
  final RequestCoalescer _coalescer;

  FollowRepositoryImpl(this._api, {RequestCoalescer? coalescer})
    : _coalescer = coalescer ?? MemoryRequestCoalescer();

  /// Align with web `fetchProfileFollowList`: `mark` / `pageSize` as query
  /// strings, first page `mark=0`.
  Map<String, dynamic> _pageQuery({String? mark, int pageSize = 20}) => {
    'mark': (mark == null || mark.isEmpty) ? '0' : mark,
    'pageSize': pageSize,
  };

  @override
  Future<Result<PageDto<FollowListItem>>> listFollowings({
    required String userId,
    String? mark,
    int pageSize = 20,
  }) => _api.safeGet(
    '$_userWallet/users/$userId/followings',
    query: _pageQuery(mark: mark, pageSize: pageSize),
    decoder: (d) => parsePageDto(d, FollowListItem.fromJson),
  );

  /// Web: `GET /api/userWallet/users/{userId}/followers` via
  /// `fetchProfileFollowList({ kind: 'followers' })`.
  @override
  Future<Result<PageDto<FollowListItem>>> listFollowers({
    required String userId,
    String? mark,
    int pageSize = 20,
  }) => _api.safeGet(
    '$_userWallet/users/$userId/followers',
    query: _pageQuery(mark: mark, pageSize: pageSize),
    decoder: (d) => parsePageDto(d, FollowListItem.fromJson),
  );

  @override
  Future<Result<PageDto<FollowListItem>>> listMutuals({
    required String userId,
    String? mark,
    int pageSize = 20,
  }) => _api.safeGet(
    '$_userWallet/users/$userId/mutuals',
    query: _pageQuery(mark: mark, pageSize: pageSize),
    decoder: (d) => parsePageDto(d, FollowListItem.fromJson),
  );

  @override
  Future<Result<FollowStats>> getStats(String userId) => _coalescer.run(
    RequestKeys.followStats(userId),
    () => _api.safeGet(
      '$_userWallet/users/$userId/follow/stats',
      decoder: decodeWith(FollowStats.fromJson),
    ),
  );

  @override
  Future<Result<FollowRelationStatus>> getRelation(String userId) =>
      _api.safeGet(
        '$_userWallet/users/$userId/relation',
        decoder: (d) {
          final map = normalizeJson(d);
          return FollowRelationStatus.fromApi(asStringOrNull(map['status']));
        },
      );

  @override
  Future<Result<BlockRelation>> getBlockRelation(String userId) => _api.safeGet(
    '$_userWallet/users/$userId/blockRelation',
    decoder: (d) => BlockRelation.fromJson(normalizeJson(d)),
  );

  @override
  Future<Result<void>> follow(String targetUserId) => _api.safePost(
    '$_userWallet/follow/$targetUserId',
    body: <String, dynamic>{},
    decoder: (_) {},
    retry: true,
  );

  @override
  Future<Result<void>> unfollow(String targetUserId) =>
      _api.safeDelete('$_userWallet/follow/$targetUserId', decoder: (_) {});

  @override
  Future<Result<void>> block(String targetUserId) => _api.safePost(
    '$_userWallet/block/$targetUserId',
    body: <String, dynamic>{},
    decoder: (_) {},
    retry: true,
  );

  @override
  Future<Result<void>> unblock(String targetUserId) =>
      _api.safeDelete('$_userWallet/block/$targetUserId', decoder: (_) {});

  @override
  Future<Result<void>> removeFollower(String followerId) =>
      _api.safeDelete('$_userWallet/follower/$followerId', decoder: (_) {});

  @override
  Future<void> dispose() async {}
}
