import '../core/cache_strategy.dart';
import '../core/result.dart';
import '../core/json_helpers.dart';
import '../model/models.dart';
import '../api/story_api_client.dart';
import '../data/repository/story_local_repository.dart';

abstract class RewardRepository {
  Future<Result<WithdrawCreateResponse>> claim({
    required String assetCode,
    required num amount,
    required String toAddress,
  });
  Future<Result<WithdrawDetailResponse>> getWithdrawOrder(String orderNo);
  Future<Result<TotalReward>> getTotalReward();
  Future<Result<UsdcIncomePage>> getUsdcIncome({
    int mark = 0,
    int pageSize = 20,
  });
  Future<Result<RewardDetailPage>> listRewardDetails({
    ListRewardDetailsFilter type = ListRewardDetailsFilter.all,
    int mark = 0,
    int pageSize = 20,
  });
  Future<Result<MiningWeeklyStats>> getWeeklyStats();
  Future<Result<MiningWeeklyStats>> refreshWeeklyStats();
  Future<MiningWeeklyStats?> getCachedWeeklyStats();

  /// 结算中的挖矿 / 邀请奖励（到账前不可领取）。
  Future<Result<SettlingReward>> getSettlingReward();

  /// Evict cached weekly stats (game workshop pull-to-refresh).
  Future<void> invalidateWeeklyStatsCache();

  Future<void> dispose();
}

class RewardRepositoryImpl implements RewardRepository {
  static const _weeklyStatsKey = 'weekly_stats';

  final StoryApiClient _api;
  final StoryLocalRepository? _local;

  late final CacheChain<String, MiningWeeklyStats> _weeklyStatsCache;
  late final MemoryCacheLayer<String, MiningWeeklyStats> _weeklyStatsMemory;

  RewardRepositoryImpl(this._api, [this._local]) {
    _weeklyStatsMemory = MemoryCacheLayer(maxEntries: 2);

    final local = _local;
    final weeklyStatsHive = local == null
        ? null
        : HiveCacheLayer<MiningWeeklyStats>(
            box: local.cacheBox,
            prefix: 'mining_weekly_stats_',
            decoder: (data) => MiningWeeklyStats.fromJson(deepStringMap(data)),
            encoder: (value) => value.toJson(),
          );

    _weeklyStatsCache = CacheChain(
      fetcher: (_) => _fetchWeeklyStats(),
      readLayers: [_weeklyStatsMemory, ?weeklyStatsHive],
      writeLayers: [_weeklyStatsMemory, ?weeklyStatsHive],
    );
  }

  Future<Result<MiningWeeklyStats>> _fetchWeeklyStats() => _api.safeGet(
    '/api/mining/weeklyStats',
    decoder: (d) => MiningWeeklyStats.fromJson(normalizeJson(d)),
  );

  @override
  Future<void> dispose() async {
    await _weeklyStatsMemory.clear();
  }

  @override
  Future<Result<WithdrawCreateResponse>> claim({
    required String assetCode,
    required num amount,
    required String toAddress,
  }) => _api.safePost(
    '/api/userWallet/withdraw',
    body: {'assetCode': assetCode, 'amount': amount, 'toAddress': toAddress},
    decoder: decodeWith(WithdrawCreateResponse.fromJson),
  );

  @override
  Future<Result<WithdrawDetailResponse>> getWithdrawOrder(String orderNo) =>
      _api.safeGet(
        '/api/userWallet/withdraw/$orderNo',
        decoder: decodeWith(WithdrawDetailResponse.fromJson),
      );

  @override
  Future<Result<TotalReward>> getTotalReward() => _api.safeGet(
    '/api/mining/totalReward',
    decoder: (d) => TotalReward.fromJson(normalizeJson(d)),
  );

  @override
  Future<Result<UsdcIncomePage>> getUsdcIncome({
    int mark = 0,
    int pageSize = 20,
  }) => _api.safeGet(
    '/api/userWallet/income/usdc',
    query: {'mark': mark, 'pageSize': pageSize},
    decoder: (d) => UsdcIncomePage.fromJson(normalizeJson(d)),
  );

  @override
  Future<Result<RewardDetailPage>> listRewardDetails({
    ListRewardDetailsFilter type = ListRewardDetailsFilter.all,
    int mark = 0,
    int pageSize = 20,
  }) => _api.safeGet(
    '/api/mining/listRewardDetails',
    query: {'type': type.queryString, 'mark': mark, 'pageSize': pageSize},
    decoder: (d) => RewardDetailPage.fromJson(normalizeJson(d)),
  );

  @override
  Future<Result<MiningWeeklyStats>> getWeeklyStats() =>
      _weeklyStatsCache.get(_weeklyStatsKey);

  @override
  Future<Result<MiningWeeklyStats>> refreshWeeklyStats() async {
    await invalidateWeeklyStatsCache();
    return getWeeklyStats();
  }

  @override
  Future<MiningWeeklyStats?> getCachedWeeklyStats() =>
      _weeklyStatsCache.getCachedOnly(_weeklyStatsKey);

  @override
  Future<Result<SettlingReward>> getSettlingReward() => _api.safeGet(
    '/api/mining/settlingReward',
    decoder: (d) => SettlingReward.fromJson(normalizeJson(d)),
  );

  @override
  Future<void> invalidateWeeklyStatsCache() =>
      _weeklyStatsCache.evict(_weeklyStatsKey);
}
