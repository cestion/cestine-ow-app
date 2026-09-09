import '../foundation/router.dart';
import '../model/report_models.dart';
import '../model/work_content_type.dart';
import 'route_args.dart';
import 'route_names.dart';

// ─── Eager imports (frequently visited pages) ───────────────────────────────
import '../view/main_shell_page.dart';
import '../view/login_page.dart';
import '../view/drama_detail_page.dart';
import '../view/actor_detail_page.dart';
import '../view/video_feed_page.dart';
import '../view/playlist_feed_page.dart';
import '../view/search_page.dart';

// ─── Deferred imports (infrequently visited pages) ──────────────────────────
import '../view/income_page.dart' deferred as income_;
import '../view/agent_v3_page.dart' deferred as agent_v3_;
import '../view/salary_pool_page.dart' deferred as salary_pool_;
import '../view/about_page.dart' deferred as about_;
import '../view/create_actor_page.dart' deferred as create_actor_;
import '../view/create_drama_page.dart' deferred as create_drama_;
import '../view/publish_video_page.dart' deferred as publish_video_;
import '../view/creators_page.dart' deferred as creators_;
import '../view/creator_page_v2.dart' deferred as creator_management_;
import '../view/edit_page.dart' deferred as edit_;
import '../view/public_profile_page.dart' deferred as public_profile_;
import '../view/follow_relations_page.dart' deferred as follow_relations_;
import '../view/settings_page.dart' deferred as settings_;
import '../view/theme_page.dart' deferred as theme_page_;
import '../view/language_page.dart' deferred as language_;
import '../view/deposit_page.dart' deferred as deposit_;
import '../view/withdraw_page.dart' deferred as withdraw_;
import '../view/invite_page.dart' deferred as invite_;
import '../view/finance_dashboard_page.dart' deferred as finance_dashboard_;
import '../view/usdc_ledger_history_page.dart' deferred as usdc_ledger_history_;
import '../view/actor_vault_ranking_history_page.dart'
    deferred as actor_vault_ranking_history_;
import '../view/story_release_history_page.dart'
    deferred as story_release_history_;
import '../view/mining_rules_page.dart' deferred as mining_rules_;
import '../view/report_page.dart' deferred as report_;
import '../view/watch_history_page.dart' deferred as watch_history_;
import '../view/notification_page.dart' deferred as notification_;
import '../view/deleting_page.dart' deferred as deleting_;
import '../view/web_view_page.dart' deferred as web_view_;

/// 路由注册（仅此文件导入 view 层）
///
/// 频繁访问的页面使用 Eager 导入，不常用的页面使用 Deferred 导入，
/// 在首次导航时才会加载编译产物，减少启动时的编译开销。
class StoryRoutes {
  StoryRoutes._();

  // 向后兼容：保持 StoryRoutes.xxx 常量可用
  static const String main = RouteNames.main;
  static const String login = RouteNames.login;
  static const String dramaDetail = RouteNames.dramaDetail;
  static const String actorDetail = RouteNames.actorDetail;
  static const String player = RouteNames.player;
  static const String search = RouteNames.search;
  static const String income = RouteNames.income;
  static const String about = RouteNames.about;
  static const String createDrama = RouteNames.createDrama;
  static const String createActor = RouteNames.createActor;
  static const String publishVideo = RouteNames.publishVideo;
  static const String edit = RouteNames.edit;
  static const String creators = RouteNames.creators;
  static const String creatorManagement = RouteNames.creatorManagement;
  static const String watchHistory = RouteNames.watchHistory;
  static const String notifications = RouteNames.notifications;
  static const String publicProfile = RouteNames.publicProfile;
  static const String game = RouteNames.game;
  static const String miningRules = RouteNames.miningRules;
  static const String salaryPool = RouteNames.salaryPool;

  static void registerRoutes() {
    final router = StoryRouter.instance;

    // ── Eager routes (loaded at startup) ──
    router.register(RouteNames.main, (args) => const MainShellPage());
    router.register(RouteNames.login, (args) {
      final routeArgs = LoginArgs.fromMap(
        args is Map<String, dynamic> ? args : null,
      );
      return LoginPage(returnTo: routeArgs.returnTo);
    });
    router.register(RouteNames.dramaDetail, (args) {
      final routeArgs = DramaDetailArgs.fromMap(
        args is Map<String, dynamic> ? args : null,
      );
      return DramaDetailPage(
        dramaId: routeArgs.dramaId,
        coverUrl: routeArgs.coverUrl,
        autoPlayFirstEpisode: routeArgs.autoPlayFirstEpisode,
        searchPlaylist: routeArgs.searchPlaylist,
        searchPlaylistIndex: routeArgs.searchPlaylistIndex,
      );
    });
    router.register(RouteNames.actorDetail, (args) {
      final routeArgs = ActorDetailArgs.fromMap(
        args is Map<String, dynamic> ? args : null,
      );
      return ActorDetailPage(
        actorId: routeArgs.actorId,
        preview: routeArgs.preview,
        initialTabIndex: routeArgs.initialTabIndex,
      );
    });
    router.register(RouteNames.player, (args) {
      final routeArgs = VideoFeedArgs.fromMap(
        args is Map<String, dynamic> ? args : null,
      );
      if (routeArgs.searchPlaylist.isNotEmpty) {
        return PlaylistFeedPage(feedArgs: routeArgs);
      }
      return VideoFeedPage(feedArgs: routeArgs);
    });
    router.register(RouteNames.search, (args) {
      final routeArgs = SearchArgs.fromMap(
        args is Map<String, dynamic> ? args : null,
      );
      return SearchPage(
        searchType: routeArgs.searchType,
        hintText: routeArgs.hintText,
      );
    });

    // ── Lazy routes (loaded on first navigation) ──
    router.register(
      RouteNames.income,
      LazyPageRoute(
        loadLibrary: income_.loadLibrary,
        buildPage: (_) => income_.IncomePage(),
      ).call,
    );
    router.register(
      RouteNames.game,
      LazyPageRoute(
        loadLibrary: agent_v3_.loadLibrary,
        buildPage: (_) => agent_v3_.AgentV3Page(),
      ).call,
    );
    router.register(
      RouteNames.agentV3,
      LazyPageRoute(
        loadLibrary: agent_v3_.loadLibrary,
        buildPage: (_) => agent_v3_.AgentV3Page(),
      ).call,
    );
    router.register(
      RouteNames.salaryPool,
      LazyPageRoute(
        loadLibrary: salary_pool_.loadLibrary,
        buildPage: (_) => salary_pool_.SalaryPoolPage(),
      ).call,
    );
    router.register(
      RouteNames.about,
      LazyPageRoute(
        loadLibrary: about_.loadLibrary,
        buildPage: (_) => about_.AboutPage(),
      ).call,
    );

    router.register(
      RouteNames.createActor,
      LazyPageRoute(
        loadLibrary: create_actor_.loadLibrary,
        buildPage: (_) => create_actor_.CreateActorPage(),
      ).call,
    );

    router.register(
      RouteNames.createDrama,
      LazyPageRoute(
        loadLibrary: create_drama_.loadLibrary,
        buildPage: (args) {
          final routeArgs = CreateDramaArgs.fromMap(
            args is Map<String, dynamic> ? args : null,
          );
          return create_drama_.CreateDramaPage(dramaId: routeArgs.dramaId);
        },
      ).call,
    );

    router.register(
      RouteNames.publishVideo,
      LazyPageRoute(
        loadLibrary: publish_video_.loadLibrary,
        buildPage: (args) {
          final routeArgs = PublishVideoArgs.fromMap(
            args is Map<String, dynamic> ? args : null,
          );
          return publish_video_.PublishVideoPage(
            episodeId: routeArgs.episodeId,
          );
        },
      ).call,
    );

    router.register(
      RouteNames.edit,
      LazyPageRoute(
        loadLibrary: edit_.loadLibrary,
        buildPage: (args) {
          final routeArgs = EditArgs.fromMap(
            args is Map<String, dynamic> ? args : null,
          );
          return edit_.EditPage(type: routeArgs.type, id: routeArgs.id);
        },
      ).call,
    );

    router.register(
      RouteNames.creators,
      LazyPageRoute(
        loadLibrary: creators_.loadLibrary,
        buildPage: (_) => creators_.CreatorsPage(),
      ).call,
    );

    router.register(
      RouteNames.creatorManagement,
      LazyPageRoute(
        loadLibrary: creator_management_.loadLibrary,
        buildPage: (args) {
          final routeArgs = CreatorManagementArgs.fromMap(
            args is Map<String, dynamic> ? args : null,
          );
          return creator_management_.CreatorPageV2(
            initialTabIndex: routeArgs.initialTabIndex,
          );
        },
      ).call,
    );

    router.register(
      RouteNames.watchHistory,
      LazyPageRoute(
        loadLibrary: watch_history_.loadLibrary,
        buildPage: (_) => watch_history_.WatchHistoryPage(),
      ).call,
    );

    router.register(
      RouteNames.notifications,
      LazyPageRoute(
        loadLibrary: notification_.loadLibrary,
        buildPage: (args) {
          final routeArgs = NotificationArgs.fromMap(
            args is Map<String, dynamic> ? args : null,
          );
          return notification_.NotificationsPage(
            initialTab: routeArgs.initialTab,
          );
        },
      ).call,
    );

    router.register(
      RouteNames.publicProfile,
      LazyPageRoute(
        loadLibrary: public_profile_.loadLibrary,
        buildPage: (args) {
          final routeArgs = PublicProfileArgs.fromMap(
            args is Map<String, dynamic> ? args : null,
          );
          return public_profile_.PublicProfilePage(userId: routeArgs.userId);
        },
      ).call,
    );

    router.register(
      RouteNames.followRelations,
      LazyPageRoute(
        loadLibrary: follow_relations_.loadLibrary,
        buildPage: (args) {
          final routeArgs = FollowRelationsArgs.fromMap(
            args is Map ? Map<String, dynamic>.from(args) : null,
          );
          return follow_relations_.FollowRelationsPage(
            userId: routeArgs.userId,
            initialTab: routeArgs.initialTab,
          );
        },
      ).call,
    );

    router.register(
      RouteNames.settings,
      LazyPageRoute(
        loadLibrary: settings_.loadLibrary,
        buildPage: (_) => settings_.SettingsPage(),
      ).call,
    );

    router.register(
      RouteNames.theme,
      LazyPageRoute(
        loadLibrary: theme_page_.loadLibrary,
        buildPage: (_) => theme_page_.ThemePage(),
      ).call,
    );

    router.register(
      RouteNames.language,
      LazyPageRoute(
        loadLibrary: language_.loadLibrary,
        buildPage: (_) => language_.LanguagePage(),
      ).call,
    );

    router.register(
      RouteNames.deposit,
      LazyPageRoute(
        loadLibrary: deposit_.loadLibrary,
        buildPage: (args) => deposit_.DepositPage(
          initialToken: args is Map<String, dynamic>
              ? args['token'] as String?
              : null,
        ),
      ).call,
    );

    router.register(
      RouteNames.withdraw,
      LazyPageRoute(
        loadLibrary: withdraw_.loadLibrary,
        buildPage: (args) => withdraw_.WithdrawPage(
          initialToken: args is Map<String, dynamic>
              ? args['token'] as String?
              : null,
        ),
      ).call,
    );

    router.register(
      RouteNames.invite,
      LazyPageRoute(
        loadLibrary: invite_.loadLibrary,
        buildPage: (_) => invite_.InvitePage(),
      ).call,
    );

    router.register(
      RouteNames.miningRules,
      LazyPageRoute(
        loadLibrary: mining_rules_.loadLibrary,
        buildPage: (_) => mining_rules_.MiningRulesPage(),
      ).call,
    );

    router.register(
      RouteNames.financeDashboard,
      LazyPageRoute(
        loadLibrary: finance_dashboard_.loadLibrary,
        buildPage: (_) => finance_dashboard_.FinanceDashboardPage(),
      ).call,
    );

    router.register(
      RouteNames.usdcLedgerHistory,
      LazyPageRoute(
        loadLibrary: usdc_ledger_history_.loadLibrary,
        buildPage: (_) => usdc_ledger_history_.UsdcLedgerHistoryPage(),
      ).call,
    );

    router.register(
      RouteNames.actorVaultRankingHistory,
      LazyPageRoute(
        loadLibrary: actor_vault_ranking_history_.loadLibrary,
        buildPage: (_) =>
            actor_vault_ranking_history_.ActorVaultRankingHistoryPage(),
      ).call,
    );

    router.register(
      RouteNames.storyReleaseHistory,
      LazyPageRoute(
        loadLibrary: story_release_history_.loadLibrary,
        buildPage: (_) => story_release_history_.StoryReleaseHistoryPage(),
      ).call,
    );

    router.register(
      RouteNames.report,
      LazyPageRoute(
        loadLibrary: report_.loadLibrary,
        buildPage: (args) {
          final routeArgs = args is Map<String, dynamic>
              ? args
              : <String, dynamic>{};
          return report_.ReportPage(
            dramaId: routeArgs['dramaId'] as String?,
            episodeNo: routeArgs['episodeNo'] as int?,
            episodeId: routeArgs['episodeId'] as String?,
            contentType: WorkContentType.fromApi(
              routeArgs['contentType'] as String?,
            ),
            scope: (routeArgs['scope'] as String?) ?? UgcReportScope.work,
            commentId: routeArgs['commentId'] as String?,
            userId: routeArgs['userId'] as String?,
            targetDisplayName: routeArgs['targetDisplayName'] as String?,
            targetAvatarUrl: routeArgs['targetAvatarUrl'] as String?,
            contentTitle: routeArgs['contentTitle'] as String?,
            contentCoverUrl: routeArgs['contentCoverUrl'] as String?,
          );
        },
      ).call,
    );

    router.register(
      RouteNames.deleting,
      LazyPageRoute(
        loadLibrary: deleting_.loadLibrary,
        buildPage: (_) => deleting_.DeletingPage(),
      ).call,
    );

    router.register(
      RouteNames.webView,
      LazyPageRoute(
        loadLibrary: web_view_.loadLibrary,
        buildPage: (args) {
          final routeArgs = WebViewArgs.fromMap(
            args is Map<String, dynamic> ? args : null,
          );
          return web_view_.WebViewPage(
            title: routeArgs.title,
            url: routeArgs.url,
          );
        },
      ).call,
    );
  }
}
