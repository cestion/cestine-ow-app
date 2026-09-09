import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/nft_state.dart';
import '../controller/recommend_feed_controller.dart';
import '../components/components.dart';
import '../core/logging_request_policy_observer.dart';
import '../core/request_keys.dart';
import '../core/request_throttle.dart';
import '../core/story_constants.dart';
import '../l10n/story_l10n.dart';
import '../model/app_version_update_info.dart';
import '../provider/tab_index_provider.dart';
import '../provider/theater_home_tab_provider.dart';
import '../provider/app_providers.dart';
import '../routes/route_names.dart';
import '../styles/story_colors.dart';
import '../widgets/widgets.dart';
import 'agent_v3_page.dart';
import 'nft_page.dart';
import 'profile_page.dart';
import 'theater_page.dart';
import '../foundation/navigator.dart';

class MainShellPage extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainShellPage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage>
    with WidgetsBindingObserver {
  // 懒加载：初始只有第 0 个 tab，其余在首次选中时创建
  final Map<int, Widget> _pages = {};
  ProviderSubscription<NftState>? _nftPrefetchSub;
  ProviderSubscription<bool>? _nftPrefetchGateSub;
  Timer? _nftPrefetchTimer;
  bool _nftPrefetchStarted = false;
  bool _pendingDeletionGateRunning = false;
  bool _versionDialogVisible = false;
  final RequestThrottle _resumeThrottle =
      MemoryRequestThrottle(observer: debugRequestPolicyObserver);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages[0] = const TheaterPage();
    // Apply initialIndex once on mount through the same auth guard used by
    // bottom-nav taps, so protected tabs cannot be opened via initialIndex.
    // Deletion gate must finish before version check so Force/Remind 不会与
    // DeletingPage 竞态抢弹窗。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapAfterFirstFrame());
    });
  }

  Future<void> _bootstrapAfterFirstFrame() async {
    if (!mounted) return;
    unawaited(_onTabSelected(widget.initialIndex));
    _scheduleNftPrefetch();
    await _ensurePendingDeletionGate();
    if (!mounted) return;
    await ref.read(appVersionUpdateControllerProvider.notifier).checkOnLaunch();
  }

  /// Prefetch NFT after the recommend feed has items (or a fallback delay) so
  /// cold-start bandwidth stays with the home feed.
  void _scheduleNftPrefetch() {
    if (_nftPrefetchStarted) return;
    _nftPrefetchGateSub = ref.listenManual<bool>(
      recommendFeedControllerProvider.select((s) => s.items.isNotEmpty),
      (previous, next) {
        if (next) _startNftPrefetch();
      },
      fireImmediately: true,
    );
    _nftPrefetchTimer?.cancel();
    _nftPrefetchTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _startNftPrefetch();
    });
  }

  void _startNftPrefetch() {
    if (_nftPrefetchStarted || !mounted) return;
    _nftPrefetchStarted = true;
    _nftPrefetchGateSub?.close();
    _nftPrefetchGateSub = null;
    _prefetchNftFeed();
  }

  /// 主壳挂载后预拉演员 IP 首屏，首次进入 Tab 时可直接展示列表。
  void _prefetchNftFeed() {
    _nftPrefetchSub = ref.listenManual(nftControllerProvider, (_, _) {});
    unawaited(ref.read(nftControllerProvider.notifier).ensureLoaded());
  }

  /// Cold start / session restore: if the account is pending deletion, open
  /// [DeletingPage] instead of letting the user stay on the main shell.
  ///
  /// Login success navigates to [DeletingPage] itself; skip when another
  /// route (login / deleting) is already on top to avoid a double push.
  ///
  /// **Important:** do not `await` the push Future until the route pops —
  /// that would block cold-start version check while DeletingPage is open,
  /// so Force updates never appear on top of it.
  Future<void> _ensurePendingDeletionGate() async {
    if (!mounted || _pendingDeletionGateRunning) return;
    final authNotifier = ref.read(authControllerProvider.notifier);
    await authNotifier.ready;
    if (!mounted) return;

    var auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn) return;

    _pendingDeletionGateRunning = true;
    try {
      // Shared with InviteCodePromptController — one userInfo round-trip.
      await ref.read(startupProfileRefreshProvider.future);
      if (!mounted) return;

      auth = ref.read(authControllerProvider);
      if (auth.profile?.isAccountDeleted != true) return;

      // Login flow replaces itself with DeletingPage; don't push again.
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

      unawaited(context.storyPush(RouteNames.deleting));
      // Wait one frame so DeletingPage is on the stack before Force dialog.
      await WidgetsBinding.instance.endOfFrame;
    } finally {
      _pendingDeletionGateRunning = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nftPrefetchTimer?.cancel();
    _nftPrefetchGateSub?.close();
    _nftPrefetchSub?.close();
    // Defensive: ensure the global loading overlay is removed even if an
    // in-flight operation was interrupted by route disposal.
    StoryLoading.dismissAll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    _refreshGlobalConfigOnResume();
    unawaited(
      ref.read(appVersionUpdateControllerProvider.notifier).checkOnResume(),
    );

    if (!ref.read(authControllerProvider).isLoggedIn) return;
    if (!_resumeThrottle.tryClaim(
      RequestKeys.walletOnchainResume,
      window: StoryConstants.walletBalanceResumeThrottle,
    )) {
      return;
    }
    unawaited(ref.read(onChainWalletBalanceProvider.notifier).refresh());
  }

  /// `globalConfigProvider` has no autoDispose, so it only refetches on a
  /// cold start unless explicitly invalidated. Resuming from background
  /// keeps the same isolate/container, so invalidate it here (throttled) to
  /// pick up backend config changes without requiring the theater page pull-to-refresh.
  void _refreshGlobalConfigOnResume() {
    if (!_resumeThrottle.tryClaim(
      RequestKeys.globalConfigResume,
      window: StoryConstants.globalConfigResumeThrottle,
    )) {
      return;
    }
    ref.invalidate(globalConfigProvider);
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const TheaterPage();
      case 1:
        return const NftPage();
      case 2:
        return const AgentV3Page();
      case 3:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  /// 切换 tab，带登录守卫。未登录时跳转登录页。
  Future<void> _onTabSelected(int index) async {
    final targetIndex = index.clamp(0, StoryTab.count - 1);
    if (targetIndex == ref.read(tabIndexProvider)) {
      if (targetIndex == StoryTab.theater.index &&
          ref.read(theaterHomeTabProvider) == TheaterHomeTab.shortDrama) {
        ref.read(theaterScrollToTopProvider.notifier).request();
      }
      return;
    }
    var ok = await ref
        .read(tabIndexProvider.notifier)
        .selectTabWithAuth(targetIndex);
    if (!mounted) return;
    if (!ok) {
      final loggedIn = await Navigator.of(
        context,
      ).pushNamed<bool>(RouteNames.login, arguments: {'returnTo': 'tab'});
      if (!mounted || loggedIn != true) return;
      ok = await ref
          .read(tabIndexProvider.notifier)
          .selectTabWithAuth(targetIndex);
      if (!mounted || !ok) return;
    }

    // Protected pages are created only after authentication succeeds.
    if (_pages[targetIndex] == null) {
      setState(() => _pages[targetIndex] = _buildPage(targetIndex));
    }
  }

  /// 中间发布按钮的登录守卫。它不是一个 tab，不修改 [tabIndexProvider]。
  Future<void> _onCreateSelected() async {
    var auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn && !auth.ready) {
      await ref.read(authControllerProvider.notifier).ready;
      if (!mounted) return;
      auth = ref.read(authControllerProvider);
    }

    if (!auth.isLoggedIn) {
      final loggedIn = await Navigator.of(
        context,
      ).pushNamed<bool>(RouteNames.login, arguments: {'returnTo': 'create'});
      if (!mounted || loggedIn != true) return;
    }

    final action = await PublishContentSheet.show(context);
    if (!mounted || action == null) return;

    final route = switch (action) {
      PublishContentAction.drama => RouteNames.createDrama,
      PublishContentAction.video => RouteNames.publishVideo,
      PublishContentAction.actorIp => RouteNames.createActor,
    };
    await context.storyPush(route);
  }

  Future<void> _showVersionUpdateDialog(AppVersionUpdateInfo info) async {
    if (_versionDialogVisible) return;

    // Force：始终走根 Navigator，即使 MainShell 被 DeletingPage / 登录页盖住也要弹。
    // Remind / Click：仅在主壳为当前路由时弹，避免打断删除/登录流程。
    if (!info.isForce) {
      if (!mounted) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    }

    final dialogContext =
        StoryNavigator.instance.navigatorKey.currentContext ??
        (mounted ? context : null);
    if (dialogContext == null) return;

    _versionDialogVisible = true;
    final notifier = ref.read(appVersionUpdateControllerProvider.notifier);
    try {
      await showAppVersionUpdateDialog(
        dialogContext,
        info: info,
        onLater: () => notifier.markDismissed(info),
      );
    } finally {
      _versionDialogVisible = false;
      notifier.clearDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppVersionUpdateInfo?>(
      appVersionUpdateControllerProvider.select((s) => s.dialogInfo),
      (previous, next) {
        if (next == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_showVersionUpdateDialog(next));
        });
      },
    );
    ref.listen<bool>(
      authControllerProvider.select((state) => state.isLoggedIn),
      (previous, isLoggedIn) {
        if (previous == true && !isLoggedIn) {
          ref.read(tabIndexProvider.notifier).setIndex(0);
        }
      },
    );
    // Auth restore may finish after the first frame; open deleting page then.
    ref.listen<({bool ready, bool loggedIn, bool deleted})>(
      authControllerProvider.select(
        (state) => (
          ready: state.ready,
          loggedIn: state.isLoggedIn,
          deleted: state.profile?.isAccountDeleted == true,
        ),
      ),
      (previous, next) {
        final becameReadyDeleted =
            next.ready &&
            next.loggedIn &&
            next.deleted &&
            (previous == null ||
                !previous.ready ||
                !previous.loggedIn ||
                !previous.deleted);
        if (becameReadyDeleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_ensurePendingDeletionGate());
          });
        }
      },
    );
    final currentIndex = ref.watch(tabIndexProvider);
    final isRecommendHome =
        currentIndex == StoryTab.theater.index &&
        ref.watch(theaterHomeTabProvider) == TheaterHomeTab.recommend;
    // 外部入口（弹窗、抽屉等）可直接切换 tab；同步补建懒加载页面，
    // 避免目标 tab 尚未从底栏点开时显示空白。
    _pages.putIfAbsent(currentIndex, () => _buildPage(currentIndex));
    final theme = Theme.of(context);
    final scaffoldKey = ref.read(mainShellScaffoldKeyProvider);
    final isDrawerOpen = ref.watch(mainShellDrawerOpenProvider);
    return DoubleBackExitScope(
      enabled: !isDrawerOpen,
      onFirstBack: (duration) => StoryToast.show(
        context,
        message: context.l10n.mainPressBackAgainToExit,
        duration: duration,
      ),
      child: Scaffold(
        key: scaffoldKey,
        // 键盘弹出时不压缩 body：推荐流播放器层随键盘上下移动会露黑边/
        // 错位；键盘直接覆盖底栏（评论输入在浮层弹层内，自行避让键盘）。
        resizeToAvoidBottomInset: false,
        backgroundColor: isRecommendHome
            ? Colors.black
            : StoryColors.backgroundOf(theme.brightness),
        drawer: StoryDrawerV2(
          onNotificationsTap: () {
            Navigator.of(context).pop();
            context.storyPush(RouteNames.notifications);
          },
        ),
        drawerScrimColor: StoryColors.overlayMid,
        onDrawerChanged: (isOpened) {
          ref.read(mainShellDrawerOpenProvider.notifier).setOpen(isOpened);
          if (isOpened) {
            final isLoggedIn = ref.read(authControllerProvider).isLoggedIn;
            if (isLoggedIn) {
              ref.read(profileControllerProvider.notifier).refresh();
              ref.read(incomeControllerProvider.notifier).refresh();
              ref.read(onChainWalletBalanceProvider.notifier).refresh();
            }
          }
        },
        // IndexedStack 保留每个 tab 的页面状态（滚动位置、播放状态等）。
        // 页面按需创建（懒加载），创建后保持存活。
        // 控制器通过 Riverpod autoDispose 自动清理，不断开数据层引用。
        body: IndexedStack(
          index: currentIndex,
          children: List<Widget>.generate(
            4,
            (i) => _pages[i] ?? const SizedBox.shrink(),
          ),
        ),

        bottomNavigationBar: StoryBottomNav(
          currentIndex: currentIndex,
          onTap: _onTabSelected,
          onCreateTap: _onCreateSelected,
          forceDark: isRecommendHome,
        ),
      ),
    );
  }
}
