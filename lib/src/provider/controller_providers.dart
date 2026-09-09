import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/controllers.dart';
import '../core/result.dart';
import '../model/models.dart';
import '../routes/route_args.dart';
import '../repositories/drama_repository.dart';
import '../repositories/notification_repository.dart';
import 'app_providers.dart';

// ─── Feature Controllers ───────────────────────────────────────────────────

/// IAP controller — deliberately NOT autoDispose: the `purchaseStream`
/// subscription and anti-loss reconcile must live for the whole app session
/// (design §6.1). Watch it at the app root / purchase entry to establish the
/// early global subscription.
final iapControllerProvider = NotifierProvider<IapController, IapState>(
  IapController.new,
);

final reportControllerProvider =
    NotifierProvider.autoDispose<ReportController, ReportState>(
      ReportController.new,
    );

final theaterControllerProvider =
    NotifierProvider.autoDispose<TheaterController, TheaterState>(
      TheaterController.new,
    );

final nftControllerProvider =
    NotifierProvider.autoDispose<NftController, NftState>(NftController.new);

final notificationControllerProvider = NotifierProvider.family
    .autoDispose<NotificationController, NotificationState, int>(
      NotificationController.new,
    );

/// Unread counters used by the notification page's tab indicators.
final notificationUnreadCountProvider =
    FutureProvider.autoDispose<NotificationUnreadCount>((ref) async {
      final repository = ref.read(notificationRepositoryProvider);
      final result = await repository.getUnreadCount();
      return result.dataOrNull ?? const NotificationUnreadCount();
    });

/// Global realtime coordinator. Instantiated by the root notification
/// listener and shared with all feature modules.
final wsControllerProvider = NotifierProvider<WsController, WsState>(
  WsController.new,
);

/// Notification-specific adapter that shares the global WebSocket connection.
final realtimeNotificationControllerProvider =
    NotifierProvider<RealtimeNotificationController, RealtimeNotificationState>(
      RealtimeNotificationController.new,
    );

final creatorControllerProvider =
    NotifierProvider.autoDispose<CreatorController, CreatorState>(
      CreatorController.new,
    );

final creatorManagementOverviewControllerProvider =
    NotifierProvider.autoDispose<
      CreatorManagementOverviewController,
      CreatorManagementOverviewState
    >(CreatorManagementOverviewController.new);

final dramaManagementControllerProvider =
    NotifierProvider.autoDispose<
      DramaManagementController,
      DramaManagementState
    >(DramaManagementController.new);

/// Creator V2 owns an independent drama list so its filters and pagination do
/// not mutate the legacy creator management tab.
final creatorDramaManagementControllerProvider =
    NotifierProvider.autoDispose<
      DramaManagementController,
      DramaManagementState
    >(DramaManagementController.new);

final creatorVideoManagementControllerProvider =
    NotifierProvider.autoDispose<
      CreatorVideoManagementController,
      CreatorVideoManagementState
    >(CreatorVideoManagementController.new);

final dramaNftControllerProvider =
    NotifierProvider.autoDispose<DramaNftController, DramaNftState>(
      DramaNftController.new,
    );

final profileControllerProvider =
    NotifierProvider.autoDispose<ProfileController, ProfileState>(
      ProfileController.new,
    );

/// Cold-start profile refresh shared by MainShell deletion gate and invite
/// prompt. Concurrent awaits share one Future; repo also coalesces forceRefresh.
final startupProfileRefreshProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return null;

      await ref.read(authControllerProvider.notifier).ready;
      if (!ref.mounted) return null;
      if (ref.read(currentUserIdProvider) != userId) return null;

      await ref.read(profileControllerProvider.notifier).refresh(force: true);
      if (!ref.mounted) return null;
      if (ref.read(currentUserIdProvider) != userId) return null;

      return ref.read(authControllerProvider).profile;
    });

final incomeControllerProvider =
    NotifierProvider.autoDispose<IncomeController, IncomeState>(
      IncomeController.new,
    );

final financeDashboardControllerProvider =
    NotifierProvider.autoDispose<
      FinanceDashboardController,
      FinanceDashboardState
    >(FinanceDashboardController.new);

final usdcIncomeDetailControllerProvider =
    NotifierProvider.autoDispose<
      UsdcIncomeDetailController,
      UsdcIncomeDetailState
    >(UsdcIncomeDetailController.new);

final usdcLedgerHistoryControllerProvider =
    NotifierProvider.autoDispose<
      UsdcLedgerHistoryController,
      UsdcLedgerHistoryState
    >(UsdcLedgerHistoryController.new);

final vaultFundsControllerProvider =
    NotifierProvider.autoDispose<VaultFundsController, VaultFundsState>(
      VaultFundsController.new,
    );

final actorVaultRankingHistoryControllerProvider =
    NotifierProvider.autoDispose<
      ActorVaultRankingHistoryController,
      ActorVaultRankingHistoryState
    >(ActorVaultRankingHistoryController.new);

final storyReleaseOverviewControllerProvider =
    NotifierProvider.autoDispose<
      StoryReleaseOverviewController,
      StoryReleaseOverviewState
    >(StoryReleaseOverviewController.new);

final storyReleaseHistoryControllerProvider =
    NotifierProvider.autoDispose<
      StoryReleaseHistoryController,
      StoryReleaseHistoryState
    >(StoryReleaseHistoryController.new);

final searchControllerProvider =
    NotifierProvider.autoDispose<SearchController, SearchState>(
      SearchController.new,
    );

// searchHistoryControllerProvider is declared next to SearchHistoryController
// in search_controller.dart and re-exported via controllers.dart.

final commentControllerProvider = NotifierProvider.family
    .autoDispose<CommentController, CommentState, CommentArgs>(
      CommentController.new,
    );

/// Drama-scoped favorite state shared by every live page (detail/feed/...).
final dramaEngagementProvider = NotifierProvider.family
    .autoDispose<DramaEngagementController, DramaEngagementState, String>(
      DramaEngagementController.new,
    );

/// Episode-scoped like/comment state shared by every live page.
final episodeEngagementProvider = NotifierProvider.family
    .autoDispose<
      EpisodeEngagementController,
      EpisodeEngagementState,
      EpisodeEngagementKey
    >(EpisodeEngagementController.new);

/// Per-creator follow state shared by the player rail.
final followControllerProvider = NotifierProvider.family
    .autoDispose<FollowController, FollowState, String>(FollowController.new);

/// Paginated public episode list for picker sheet + drama detail.
final dramaEpisodeListProvider =
    NotifierProvider.family<
      DramaEpisodeListController,
      DramaEpisodeListState,
      String
    >(DramaEpisodeListController.new);

/// Two-phase (local seed → server refresh) engagement hydration.
final engagementHydratorProvider = Provider<EngagementHydrator>(
  EngagementHydrator.new,
);

final videoFeedControllerProvider = NotifierProvider.family
    .autoDispose<VideoFeedController, VideoFeedState, VideoFeedArgs>(
      VideoFeedController.new,
    );

/// Tracks the currently selected episode number per drama.
/// Drama detail page watches; video feed page updates on swipe/auto-advance.
///
/// Persisted to Hive: the provider is autoDispose, so without a backing store
/// every write made while nothing watches it (player opened straight from
/// theater/history, or the detail page popped back to a live player) lands on
/// a notifier that is disposed immediately — a later detail page would then
/// reset to episode 1 even though playback advanced.
class CurrentEpisodeNotifier extends Notifier<int> {
  final String dramaId;

  CurrentEpisodeNotifier(this.dramaId);

  String get _cacheKey => 'current_episode_$dramaId';

  @override
  int build() {
    final cached = ref.read(localRepositoryProvider).cacheBox.get(_cacheKey);
    return cached is int && cached >= 1 ? cached : 1;
  }

  void setEpisode(int episode) {
    if (episode < 1 || episode == state) return;
    state = episode;
    ref.read(localRepositoryProvider).cacheBox.put(_cacheKey, episode);
  }
}

final currentDramaEpisodeProvider = NotifierProvider.family
    .autoDispose<CurrentEpisodeNotifier, int, String>(
      CurrentEpisodeNotifier.new,
    );

/// Last-selected episode for [dramaId] (Hive-backed), clamped to [totalEpisodes].
int resumeEpisodeForDrama(
  WidgetRef ref,
  String dramaId, {
  int totalEpisodes = 1,
}) {
  final saved = ref.read(currentDramaEpisodeProvider(dramaId));
  final maxEp = totalEpisodes < 1 ? saved : totalEpisodes;
  return saved.clamp(1, maxEp);
}

final createDramaControllerProvider =
    NotifierProvider.autoDispose<CreateDramaController, CreateDramaState>(
      CreateDramaController.new,
    );

final publishVideoControllerProvider =
    NotifierProvider.autoDispose<PublishVideoController, PublishVideoState>(
      PublishVideoController.new,
    );

final createActorControllerProvider =
    NotifierProvider.autoDispose<CreateActorController, CreateActorState>(
      CreateActorController.new,
    );

final inviteControllerProvider =
    NotifierProvider.autoDispose<InviteController, InviteState>(
      InviteController.new,
    );

final gameControllerProvider =
    NotifierProvider.autoDispose<GameController, GameState>(GameController.new);

/// 经纪人 V3 独立状态树；在正式切换前不与 V2 共享页面状态。
final agentV3ControllerProvider =
    NotifierProvider.autoDispose<AgentV3Controller, AgentV3State>(
      AgentV3Controller.new,
    );

final agentV3RecycleActorsControllerProvider =
    NotifierProvider<AgentV3RecycleActorsController, AgentV3RecycleActorsState>(
      AgentV3RecycleActorsController.new,
    );

/// Cross-tab inventory revision for successfully signed actors.
/// Cross-tab revision and cache reconciliation for successfully signed actors.
final actorInventorySyncControllerProvider =
    NotifierProvider<ActorInventorySyncController, int>(
      ActorInventorySyncController.new,
    );

/// 保持存活以持续监听退出/换号，并及时清除账号相关的内存与 Hive 缓存。
final weeklySalaryControllerProvider =
    NotifierProvider<WeeklySalaryController, WeeklySalaryState>(
      WeeklySalaryController.new,
    );

/// 片酬与奖池页面：一次性拉取 `GET /api/mining/weeklyStats`。
final salaryPoolStatsProvider =
    FutureProvider.autoDispose<Result<MiningWeeklyStats>>((ref) async {
      final repo = ref.read(rewardRepositoryProvider);
      return repo.getWeeklyStats();
    });

final agentV2CandidateActorsControllerProvider =
    NotifierProvider<
      AgentV2CandidateActorsController,
      AgentV2CandidateActorsState
    >(AgentV2CandidateActorsController.new);

final agentV2UpgradeableActorsControllerProvider =
    NotifierProvider<
      AgentV2UpgradeableActorsController,
      AgentV2UpgradeableActorsState
    >(AgentV2UpgradeableActorsController.new);

/// 经纪人 V2 候场演员。
///
/// 直接依赖仓储，避免 GameController 在派遣成功后刷新本 Provider 时形成
/// `Provider -> GameController -> Provider` 循环依赖。
final agentV2RestActorsProvider =
    FutureProvider.autoDispose<Result<List<MiningActor>>>((ref) async {
      final repository = ref.read(miningRepositoryProvider);
      final result = await repository.listRestActors();
      return result.map((page) => page.records);
    });

final videoUploadControllerProvider =
    NotifierProvider.autoDispose<VideoUploadController, VideoUploadState>(
      VideoUploadController.new,
    );

/// Global foreground upload queue. It intentionally outlives publish pages.
final uploadCoordinatorProvider =
    NotifierProvider<UploadCoordinator, Map<String, UploadTask>>(
      UploadCoordinator.new,
    );

// ─── Family Future Providers for one-off data fetching ──────────────────────

final actorCollectionDetailProvider = FutureProvider.autoDispose
    .family<Result<ActorCollection>, String>((ref, id) async {
      final repo = ref.read(actorRepositoryProvider);
      return repo.getActorCollectionDetail(id);
    });

final actorVaultDepositProvider = FutureProvider.autoDispose
    .family<Result<ActorNftVaultDeposit>, String>((ref, actorId) async {
      final repo = ref.read(actorRepositoryProvider);
      return repo.getVaultDeposit(actorId);
    });

final actorCastDramasProvider = FutureProvider.autoDispose
    .family<Result<PageDto<DramaListItem>>, String>((ref, actorId) async {
      final repo = ref.read(actorRepositoryProvider);
      return repo.getCastDramas(actorId);
    });

/// Drama detail with stale-while-revalidate semantics.
///
/// Emits the cached detail immediately (fast page render), then force-fetches
/// from the server in the background and replaces the state — so counters
/// (favoriteCount, avgRating) picked up from a stale cache correct themselves.
/// Fresh counters are also pushed into [dramaEngagementProvider] so pages
/// holding a retained engagement store see them too.
class DramaDetailNotifier extends AsyncNotifier<Result<DramaDetail>> {
  final String dramaId;

  DramaDetailNotifier(this.dramaId);

  @override
  Future<Result<DramaDetail>> build() async {
    final repo = ref.read(dramaRepositoryProvider);
    final cached = await repo.peekDetail(dramaId);
    if (cached != null) {
      unawaited(_revalidate(repo));
      return Result.success(cached);
    }
    // Cache miss — getDetail hits the network and is already fresh.
    final result = await repo.getDetail(dramaId);
    _pushEngagement(result.dataOrNull);
    return result;
  }

  Future<void> _revalidate(DramaRepository repo) async {
    final fresh = await repo.getDetail(dramaId, forceRefresh: true);
    if (!ref.mounted || fresh.isFailure) return;
    state = AsyncData(fresh);
    _pushEngagement(fresh.dataOrNull);
  }

  void _pushEngagement(DramaDetail? detail) {
    if (detail == null || !ref.mounted) return;
    ref
        .read(dramaEngagementProvider(dramaId).notifier)
        .applyServer(
          favoritedByMe: detail.favoritedByMe,
          favoriteCount: detail.favoriteCount,
          avgRating: detail.avgRating,
        );
  }
}

final dramaDetailProvider = AsyncNotifierProvider.family
    .autoDispose<DramaDetailNotifier, Result<DramaDetail>, String>(
      DramaDetailNotifier.new,
    );

final publicProfileProvider = FutureProvider.autoDispose
    .family<Result<UserProfile>, String>((ref, userId) async {
      final repo = ref.read(userRepositoryProvider);
      return repo.getOtherProfile(userId);
    });

/// Work stats for a user (`GET /api/mini-drama/public/users/{id}/stats`).
///
/// Currently consumed by the profile header to surface `totalLikeCount`
/// (likes received). Kept as a separate family so it can be invalidated
/// independently when the bottom-nav Profile tab is revisited (throttled
/// at the profile page visibility listen).
final workStatsProvider = FutureProvider.autoDispose
    .family<UserWorkStats, String>((ref, userId) async {
      final result = await ref
          .read(userRepositoryProvider)
          .getWorkStats(userId);
      return result.dataOrNull ?? const UserWorkStats();
    });

final userProfileDramasProvider = NotifierProvider.family
    .autoDispose<
      UserProfileDramasController,
      UserProfileDramasState,
      UserProfileDramaParam
    >(UserProfileDramasController.new);

final userProfileActorCollectionsProvider = NotifierProvider.family
    .autoDispose<
      UserProfileActorCollectionsController,
      UserProfileActorCollectionsState,
      UserProfileActorParam
    >(UserProfileActorCollectionsController.new);

final watchHistoryDramaControllerProvider =
    NotifierProvider.autoDispose<
      WatchHistoryDramaController,
      WatchHistoryListState<WatchHistoryDrama>
    >(WatchHistoryDramaController.new);

final watchHistoryVideoControllerProvider =
    NotifierProvider.autoDispose<
      WatchHistoryVideoController,
      WatchHistoryListState<WatchHistoryVideo>
    >(WatchHistoryVideoController.new);

/// The three most recent drama-level watch-history records for the drawer.
final drawerWatchHistoryPreviewProvider =
    FutureProvider.autoDispose<List<WatchHistoryDrama>>((ref) async {
      final isLoggedIn = ref.watch(
        authControllerProvider.select((state) => state.isLoggedIn),
      );
      if (!isLoggedIn) return const [];

      // The API localizes history display fields through Accept-Language.
      // Watching the locale makes the drawer preview re-fetch automatically.
      ref.watch(localeCodeProvider);

      final result = await ref
          .read(userRepositoryProvider)
          .getWatchHistoryDramas(pageSize: 3);
      return result.dataOrNull?.list ?? const [];
    });

/// The three newest interaction notifications shown in the V2 drawer.
enum DrawerNotificationPreviewPhase { readingCache, loading, ready }

class DrawerNotificationPreviewState {
  const DrawerNotificationPreviewState({
    this.items = const <NotificationItem>[],
    this.phase = DrawerNotificationPreviewPhase.readingCache,
  });

  const DrawerNotificationPreviewState.loading()
    : items = const <NotificationItem>[],
      phase = DrawerNotificationPreviewPhase.loading;

  const DrawerNotificationPreviewState.ready([
    this.items = const <NotificationItem>[],
  ]) : phase = DrawerNotificationPreviewPhase.ready;

  final List<NotificationItem> items;
  final DrawerNotificationPreviewPhase phase;

  bool get isReadingCache =>
      phase == DrawerNotificationPreviewPhase.readingCache;
  bool get isLoading => phase == DrawerNotificationPreviewPhase.loading;
}

class DrawerNotificationPreviewNotifier
    extends Notifier<DrawerNotificationPreviewState> {
  static const _request = NotificationListRequest(mark: 0, pageSize: 20);
  int _generation = 0;

  @override
  DrawerNotificationPreviewState build() {
    final generation = ++_generation;
    final isLoggedIn = ref.watch(
      authControllerProvider.select((state) => state.isLoggedIn),
    );
    if (!isLoggedIn) return const DrawerNotificationPreviewState.ready();

    final repository = ref.read(notificationRepositoryProvider);
    Future.microtask(() => _bootstrap(repository, generation));
    return const DrawerNotificationPreviewState();
  }

  Future<void> _bootstrap(
    NotificationRepository repository,
    int generation,
  ) async {
    final cached = await repository.getCachedFirstPage(_request);
    if (!ref.mounted || generation != _generation) return;

    if (cached != null) {
      state = DrawerNotificationPreviewState.ready(_preview(cached));
      unawaited(_revalidate(repository, generation));
      return;
    }

    state = const DrawerNotificationPreviewState.loading();
    final result = await repository.listNotifications(_request);
    if (!ref.mounted || generation != _generation) return;
    final page = result.dataOrNull;
    state = DrawerNotificationPreviewState.ready(
      page == null ? const [] : _preview(page),
    );
  }

  Future<void> _revalidate(
    NotificationRepository repository,
    int generation,
  ) async {
    final result = await repository.listNotifications(_request);
    final page = result.dataOrNull;
    if (!ref.mounted || generation != _generation || page == null) return;
    state = DrawerNotificationPreviewState.ready(_preview(page));
  }

  List<NotificationItem> _preview(NotificationPage page) =>
      page.list?.take(3).toList(growable: false) ?? const [];
}

final drawerNotificationPreviewProvider =
    NotifierProvider.autoDispose<
      DrawerNotificationPreviewNotifier,
      DrawerNotificationPreviewState
    >(DrawerNotificationPreviewNotifier.new);
