import '../core/result.dart';
import '../core/json_helpers.dart';
import '../model/json_converters.dart';
import '../model/models.dart';
import '../api/story_api_client.dart';

/// 资金看板相关 API 仓储。
abstract class FinanceDashboardRepository {
  /// 资金看板累计收支统计。
  ///
  /// `GET /api/userWallet/dashboard/incomeStats`
  Future<Result<IncomeStats>> getIncomeStats();

  /// 累计已释放 STORY 总量。
  ///
  /// `GET /api/mining/totalReleased`
  Future<Result<double>> getTotalReleased();

  /// 资金看板流水分页查询。
  ///
  /// `GET /api/userWallet/dashboard/ledger`
  Future<Result<PageDto<LedgerItem>>> getLedger({
    String? mark,
    int pageSize = 20,
  });

  /// 演员金库累计统计。
  ///
  /// `GET /api/userWallet/dashboard/actorVaultStats`
  Future<Result<ActorVaultStats>> getActorVaultStats();

  /// 每日挖矿 / 邀请奖励分页查询。
  ///
  /// `GET /api/mining/listWeeklyRewards`
  Future<Result<PageDto<WeeklyRewardItem>>> listWeeklyRewards({
    String? mark,
    int pageSize = 20,
  });

  /// 演员金库排行榜分页查询。
  ///
  /// `GET /api/userWallet/dashboard/actorVaultRanking`
  Future<Result<PageDto<ActorVaultRankingItem>>> getActorVaultRanking({
    String? mark,
    int pageSize = 20,
  });

  Future<void> dispose();
}

class FinanceDashboardRepositoryImpl implements FinanceDashboardRepository {
  static const _userWallet = '/api/userWallet';
  static const _mining = '/api/mining';

  final StoryApiClient _api;

  FinanceDashboardRepositoryImpl(this._api);

  @override
  Future<Result<IncomeStats>> getIncomeStats() => _api.safeGet(
    '$_userWallet/dashboard/incomeStats',
    decoder: decodeWith(IncomeStats.fromJson),
  );

  @override
  Future<Result<double>> getTotalReleased() =>
      _api.safeGet('$_mining/totalReleased', decoder: (d) => asDouble(d) ?? 0);

  @override
  Future<Result<PageDto<LedgerItem>>> getLedger({
    String? mark,
    int pageSize = 20,
  }) => _api.safeGet(
    '$_userWallet/dashboard/ledger',
    query: {'mark': mark, 'pageSize': pageSize},
    decoder: (d) => parsePageDto<LedgerItem>(d, LedgerItem.fromJson),
  );

  @override
  Future<Result<ActorVaultStats>> getActorVaultStats() => _api.safeGet(
    '$_userWallet/dashboard/actorVaultStats',
    decoder: decodeWith(ActorVaultStats.fromJson),
  );

  @override
  Future<Result<PageDto<WeeklyRewardItem>>> listWeeklyRewards({
    String? mark,
    int pageSize = 20,
  }) => _api.safeGet(
    '$_mining/listWeeklyRewards',
    query: {'mark': mark, 'pageSize': pageSize},
    decoder: (d) =>
        parsePageDto<WeeklyRewardItem>(d, WeeklyRewardItem.fromJson),
  );

  @override
  Future<Result<PageDto<ActorVaultRankingItem>>> getActorVaultRanking({
    String? mark,
    int pageSize = 20,
  }) => _api.safeGet(
    '$_userWallet/dashboard/actorVaultRanking',
    query: {'mark': mark, 'pageSize': pageSize},
    decoder: (d) =>
        parsePageDto<ActorVaultRankingItem>(d, ActorVaultRankingItem.fromJson),
  );

  @override
  Future<void> dispose() async {}
}
