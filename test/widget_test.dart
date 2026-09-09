import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'package:story_app/main.dart';
import 'package:story_app/src/foundation/locale_controller.dart';
import 'package:story_app/src/foundation/router.dart';
import 'package:story_app/src/routes/story_routes.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/story_env.dart';
import 'package:story_app/src/core/story_sdk_config.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/controller/app_version_update_controller.dart';
import 'package:story_app/src/controller/app_version_update_state.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/services/privy_service.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/repositories/actor_repository.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/repositories/recommend_repository.dart';
import 'package:story_app/src/repositories/reward_repository.dart';
import 'package:story_app/src/repositories/user_repository.dart';
import 'package:story_app/src/view/nft_page.dart';

class MockDramaRepo extends Mock implements DramaRepository {}

class MockActorRepo extends Mock implements ActorRepository {}

class MockUserRepo extends Mock implements UserRepository {}

class MockRewardRepo extends Mock implements RewardRepository {}

class MockRecommendRepo extends Mock implements RecommendRepository {}

class MockLocalRepo extends Mock implements StoryLocalRepository {}

class MockBox extends Mock implements Box<dynamic> {}

class MockPrivyService extends Mock implements PrivyService {}

class _NoopAppVersionUpdateController extends AppVersionUpdateController {
  @override
  AppVersionUpdateState build() => const AppVersionUpdateState();

  @override
  Future<void> checkOnLaunch() async {}

  @override
  Future<void> checkOnResume() async {}
}

late ProviderScope _scope;

void main() {
  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(
      const LoginRequest(privyToken: '', deviceType: LoginDeviceType.app),
    );
    registerFallbackValue(const UserProfile());
    registerFallbackValue(const LocaleInfo(languageCode: 'zh'));
  });

  setUp(() {
    final d = MockDramaRepo(),
        a = MockActorRepo(),
        u = MockUserRepo(),
        r = MockRewardRepo(),
        l = MockLocalRepo();
    final box = MockBox();
    when(() => l.cacheBox).thenReturn(box);
    when(() => box.get(any<dynamic>())).thenReturn(null);
    when(
      () => box.put(any<dynamic>(), any<dynamic>()),
    ).thenAnswer((_) async => 0);
    when(() => box.delete(any<dynamic>())).thenAnswer((_) async {});
    when(
      () => d.invalidatePublicListCache(
        tagId: any(named: 'tagId'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => d.listPublic(
        mark: any(named: 'mark'),
        tagId: any(named: 'tagId'),
        sort: any(named: 'sort'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer(
      (_) async => Result<PageDto<DramaListItem>>.success(
        const PageDto(list: [], hasMore: false),
      ),
    );
    when(
      () => a.listPublic(
        mark: any(named: 'mark'),
        pageSize: any(named: 'pageSize'),
        name: any(named: 'name'),
      ),
    ).thenAnswer(
      (_) async => Result<PageDto<Actor>>.success(
        const PageDto(list: [], hasMore: false),
      ),
    );
    when(
      () => a.listActorCollections(
        pageSize: any(named: 'pageSize'),
        mark: any(named: 'mark'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer(
      (_) async => Result<PageDto<ActorCollection>>.success(
        const PageDto(list: [], hasMore: false),
      ),
    );
    when(
      () => u.getProfile(),
    ).thenAnswer((_) async => Result<UserProfile>.success(const UserProfile()));
    when(() => u.login(any())).thenAnswer(
      (_) async => Result<LoginResponse>.success(const LoginResponse()),
    );
    when(() => u.logout()).thenAnswer((_) async => Result<void>.success(null));
    when(() => d.dispose()).thenAnswer((_) async {});
    when(() => a.dispose()).thenAnswer((_) async {});
    when(() => u.dispose()).thenAnswer((_) async {});
    when(() => r.dispose()).thenAnswer((_) async {});
    when(() => r.invalidateWeeklyStatsCache()).thenAnswer((_) async {});
    when(() => l.init()).thenAnswer((_) async {});
    when(() => l.getToken()).thenReturn(null);
    when(() => l.getTokenAsync()).thenAnswer((_) async => null);
    when(() => l.getSolanaWalletAddressAsync()).thenAnswer((_) async => null);
    when(() => l.getEthereumWalletAddressAsync()).thenAnswer((_) async => null);
    when(() => l.getUser()).thenReturn(null);
    when(() => l.getWatchlist()).thenReturn([]);
    when(() => l.isFavorite(any())).thenReturn(false);
    when(() => l.getSearchHistory()).thenReturn([]);
    when(() => l.getLocale()).thenReturn(null);
    when(() => l.getSolanaWalletAddress()).thenReturn(null);
    when(() => l.getEthereumWalletAddress()).thenReturn(null);
    when(() => l.getWatchProgress(any(), any())).thenReturn(0);
    when(() => l.saveToken(any())).thenAnswer((_) async {});
    when(() => l.clearToken()).thenAnswer((_) async {});
    when(() => l.saveUser(any())).thenAnswer((_) async {});
    when(() => l.clearUser()).thenAnswer((_) async {});
    when(() => l.saveSolanaWalletAddress(any())).thenAnswer((_) async {});
    when(() => l.clearSolanaWalletAddress()).thenAnswer((_) async {});
    when(() => l.saveEthereumWalletAddress(any())).thenAnswer((_) async {});
    when(() => l.clearEthereumWalletAddress()).thenAnswer((_) async {});
    when(() => l.addToWatchlist(any())).thenAnswer((_) async {});
    when(() => l.removeFromWatchlist(any())).thenAnswer((_) async {});
    when(() => l.toggleWatchlist(any())).thenAnswer((_) async => false);
    when(() => l.addSearchHistory(any())).thenAnswer((_) async {});
    when(() => l.removeSearchHistory(any())).thenAnswer((_) async {});
    when(() => l.clearSearchHistory()).thenAnswer((_) async {});
    when(() => l.setLocale(any())).thenAnswer((_) async {});
    when(
      () => l.saveWatchProgress(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(() => l.clearWatchProgress(any(), any())).thenAnswer((_) async {});
    when(() => l.vacuumCache()).thenAnswer((_) async {});
    when(() => l.getWatchHistoryDramaIds()).thenReturn([]);
    when(() => l.getLastWatchedEpisode(any())).thenReturn(null);
    when(() => l.dispose()).thenAnswer((_) async {});

    final rec = MockRecommendRepo();
    when(
      () => rec.fetchFeed(
        cursor: any(named: 'cursor'),
        size: any(named: 'size'),
        subject: any(named: 'subject'),
      ),
    ).thenAnswer(
      (_) async => Result<PageDto<RecommendFeedItem>>.success(
        const PageDto(list: [], hasMore: false),
      ),
    );
    when(
      () => rec.peekCachedFirstPage(
        subject: any(named: 'subject'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => rec.invalidateFirstPageCache(subject: any(named: 'subject')),
    ).thenAnswer((_) async {});
    when(
      () => rec.search(
        keyword: any(named: 'keyword'),
        type: any(named: 'type'),
        size: any(named: 'size'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => Result<RecommendSearchResponse>.success(
        const RecommendSearchResponse(),
      ),
    );
    when(
      () => rec.dislike(any()),
    ).thenAnswer((_) async => Result<void>.success(null));

    final privy = MockPrivyService();
    _scope = ProviderScope(
      overrides: [
        // Use development env (no initialToken) so tests stay logged-out by default
        storySdkConfigProvider.overrideWithValue(
          const StorySdkConfig(env: StoryEnv.development),
        ),
        dramaRepositoryProvider.overrideWithValue(d),
        actorRepositoryProvider.overrideWithValue(a),
        userRepositoryProvider.overrideWithValue(u),
        rewardRepositoryProvider.overrideWithValue(r),
        localRepositoryProvider.overrideWithValue(l),
        privyServiceProvider.overrideWithValue(privy),
        recommendRepositoryProvider.overrideWithValue(rec),
        appVersionUpdateControllerProvider.overrideWith(
          _NoopAppVersionUpdateController.new,
        ),
      ],
      child: const StoryApp(),
    );
    StoryRouter.instance.clear();
    StoryRoutes.registerRoutes();
  });

  tearDown(() {
    StoryRouter.instance.clear();
  });

  testWidgets('app renders 4-tab bottom nav', (t) async {
    await t.pumpWidget(_scope);
    await t.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('首页'), findsWidgets);
    expect(find.text('IP市场'), findsOneWidget);
    expect(find.text('经纪人'), findsOneWidget);
    expect(find.text('我'), findsOneWidget);
  });
  testWidgets('NFT tab switches page', (t) async {
    await t.pumpWidget(_scope);
    await t.pumpAndSettle(const Duration(seconds: 2));
    await t.tap(find.text('IP市场'));
    await t.pumpAndSettle();
    expect(find.byType(NftPage), findsOneWidget);
  });
  testWidgets('game tab without login shows login page', (t) async {
    await t.pumpWidget(_scope);
    await t.pumpAndSettle(const Duration(seconds: 2));
    await t.tap(find.text('经纪人'));
    await t.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('邮箱'), findsOneWidget);
  });
  testWidgets('app switches locale and updates text labels', (t) async {
    await t.pumpWidget(_scope);
    await t.pumpAndSettle(const Duration(seconds: 2));
    // Verify initial Chinese labels
    expect(find.text('首页'), findsWidgets);
    expect(find.text('经纪人'), findsOneWidget);

    // Switch to English locale
    await StoryLocaleController.instance.setLocale(const Locale('en'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    // Verify translated English labels
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Manager'), findsOneWidget);

    // Switch back to Chinese locale
    await StoryLocaleController.instance.setLocale(const Locale('zh'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('首页'), findsWidgets);
    expect(find.text('经纪人'), findsOneWidget);
  });
}
