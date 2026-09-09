import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../components/components.dart';
import '../components/creator/creator_metric_card.dart';
import '../core/story_sdk.dart';
import '../foundation/story_launcher.dart';
import '../foundation/story_theme.dart';
import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../provider/tab_index_provider.dart';
import '../routes/route_names.dart';
import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../widgets/widgets.dart';
import 'widgets/creator/creator_tabs.dart';
import '../foundation/navigator.dart';

class CreatorPage extends ConsumerStatefulWidget {
  final bool showBack;

  const CreatorPage({super.key, this.showBack = false});

  @override
  ConsumerState<CreatorPage> createState() => _CreatorPageState();
}

/// Creator main tab. Hosts a 2-child [TabBarView] (Drama management / Drama NFT).
///
/// **自动刷新策略**：无 WS 通道下的 HTTP 兜底。本页统一处理 app 切回前台
/// 与底部 tab 切回 Creator 两个生命周期事件，按当前显示的子 tab 刷新
/// 对应 controller，弥补两个子 tab 通过 [AutomaticKeepAliveClientMixin]
/// 常驻后不会再触发 `initState` 的缺口。
class _CreatorPageState extends ConsumerState<CreatorPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _lastSubTabIndex = 0;
  Timer? _pendingReviewRefreshTimer;
  int _dramaRefreshGeneration = 0;

  /// Creator workspace uses the third content slot when embedded in the main shell.
  static const int _kCreatorTabIndex = 3;
  static const Duration _pendingReviewRefreshInterval = Duration(seconds: 10);

  /// 上次 app 生命周期状态，用于判定 `resumed` 是从后台切回。
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleSubTabChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(creatorControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _stopPendingReviewRefresh();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_handleSubTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// 子 tab 切换完成后，仅刷新当前 tab 对应的顶部指标。
  ///
  /// [TabController] 在点击切换动画期间会多次通知，因此通过
  /// [TabController.indexIsChanging] 和上次处理的 index 保证每次切换只刷新一次。
  void _handleSubTabChanged() {
    if (_tabController.indexIsChanging) return;

    final index = _tabController.index;
    if (index == _lastSubTabIndex) return;
    _lastSubTabIndex = index;

    if (!mounted || !ref.read(authControllerProvider).isLoggedIn) return;
    final notifier = ref.read(creatorControllerProvider.notifier);
    if (index == 0) {
      _startDramaManagementSilentRefresh();
      unawaited(notifier.refreshOnlineDramaCount());
    } else {
      _stopPendingReviewRefresh();
      unawaited(ref.read(dramaNftControllerProvider.notifier).refresh());
      unawaited(notifier.refreshOwnedNftCount());
    }
  }

  /// Entering the management tab refreshes its first page without clearing
  /// the existing cards. While any returned drama remains under review,
  /// repeat the same silent refresh so status changes appear automatically.
  void _startDramaManagementSilentRefresh() {
    _pendingReviewRefreshTimer?.cancel();
    final generation = ++_dramaRefreshGeneration;
    unawaited(_silentRefreshDramaManagement(generation));
  }

  Future<void> _silentRefreshDramaManagement(int generation) async {
    if (!_canPollDramaManagement(generation)) return;

    final hasPendingReview = await ref
        .read(dramaManagementControllerProvider.notifier)
        .silentRefresh();
    if (!hasPendingReview || !_canPollDramaManagement(generation)) return;

    _pendingReviewRefreshTimer = Timer(_pendingReviewRefreshInterval, () {
      _pendingReviewRefreshTimer = null;
      unawaited(_silentRefreshDramaManagement(generation));
    });
  }

  bool _canPollDramaManagement(int generation) {
    final appIsActive =
        _lastLifecycleState == null ||
        _lastLifecycleState == AppLifecycleState.resumed;
    return mounted &&
        generation == _dramaRefreshGeneration &&
        appIsActive &&
        _tabController.index == 0 &&
        ref.read(tabIndexProvider) == _kCreatorTabIndex &&
        ref.read(authControllerProvider).isLoggedIn;
  }

  void _stopPendingReviewRefresh() {
    _dramaRefreshGeneration++;
    _pendingReviewRefreshTimer?.cancel();
    _pendingReviewRefreshTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final prev = _lastLifecycleState;
    _lastLifecycleState = state;
    if (state != AppLifecycleState.resumed) {
      _stopPendingReviewRefresh();
    }
    final wasBackground =
        prev == null ||
        prev == AppLifecycleState.paused ||
        prev == AppLifecycleState.inactive ||
        prev == AppLifecycleState.hidden;
    if (state == AppLifecycleState.resumed &&
        wasBackground &&
        mounted &&
        ref.read(tabIndexProvider) == _kCreatorTabIndex) {
      _refreshCurrentSubTab();
    }
  }

  /// 按当前显示的子 tab 刷新对应 controller；延迟到下一帧以避免在
  /// build/lifecycle 回调中直接写 state。
  void _refreshCurrentSubTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 子 tab 0：短剧管理；子 tab 1：短剧 NFT。
      if (_tabController.index == 0) {
        _startDramaManagementSilentRefresh();
        ref.read(creatorControllerProvider.notifier).refreshOnlineDramaCount();
        ref.read(creatorControllerProvider.notifier).refreshOwnedNftCount();
      } else {
        ref.read(dramaNftControllerProvider.notifier).refresh();
      }
    });
  }

  /// Creator 页面会被 MainShell 的 IndexedStack 长期保留，因此登出时必须
  /// 主动丢弃三个用户态 controller，避免旧账号数据残留或异步请求回填。
  ///
  /// 登录流程完整结束后主指标由这里重新加载；两个子 tab 会随登录态重建，
  /// 并在各自 initState 中重新加载列表。
  void _handleAuthChanged(bool isLoggedIn) {
    if (!isLoggedIn) {
      _stopPendingReviewRefresh();
      ref.invalidate(creatorControllerProvider);
      ref.invalidate(dramaManagementControllerProvider);
      ref.invalidate(dramaNftControllerProvider);
      _tabController.index = 0;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !ref.read(authControllerProvider).isLoggedIn) {
        return;
      }
      unawaited(ref.read(creatorControllerProvider.notifier).load());
      if (_tabController.index == 0 &&
          ref.read(tabIndexProvider) == _kCreatorTabIndex) {
        _startDramaManagementSilentRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Select only the fields this page reads so unrelated auth/creator state
    // changes don't rebuild the whole tab shell.
    final authStatus = ref.watch(
      authControllerProvider.select(
        (state) => (isLoggedIn: state.isLoggedIn, isLogging: state.isLogging),
      ),
    );
    final loggedIn = authStatus.isLoggedIn && !authStatus.isLogging;
    final l10n = context.l10n;
    final surface = StoryColors.storyBgOf(Theme.of(context).brightness);

    ref.listen<({bool isLoggedIn, bool isLogging})>(
      authControllerProvider.select(
        (state) => (isLoggedIn: state.isLoggedIn, isLogging: state.isLogging),
      ),
      (previous, current) {
        final loggedOut = previous?.isLoggedIn == true && !current.isLoggedIn;
        final loginCompleted =
            current.isLoggedIn &&
            !current.isLogging &&
            (previous?.isLoggedIn != true || previous?.isLogging == true);
        if (loggedOut) {
          _handleAuthChanged(false);
        } else if (loginCompleted) {
          _handleAuthChanged(true);
        }
      },
    );

    // 监听底部 tab 切回 Creator：从其它 tab 返回时刷新，弥补子 tab
    // `AutomaticKeepAliveClientMixin` 下不会重新触发 initState 的缺口。
    ref.listen<bool>(
      tabIndexProvider.select((index) => index == _kCreatorTabIndex),
      (previous, isCreator) {
        if (previous == false && isCreator && mounted) {
          _refreshCurrentSubTab();
        } else if (!isCreator) {
          _stopPendingReviewRefresh();
        }
      },
    );

    return AppScaffold(
      title: l10n.navCreate,
      centerTitle: false,
      showBack: widget.showBack,
      backgroundColor: context.storyColors.appBarBackground,
      leading: widget.showBack ? null : const StoryLeadingAvatar(),
      titleWidget: Row(
        children: [
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: context.l10n.creatorCreateDrama,
            onPressed: () => StoryLauncher.openExternal(
              StorySdk.instance.config.env.dreamOsUrl,
            ),
            icon: SvgPicture.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/game/game_nav_create_d.svg'
                  : 'assets/game/game_nav_create.svg',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(width: StorySpacing.sm),
          ElevatedButton(
            onPressed: () async {
              final created = await context.storyPushForResult<Object?>(RouteNames.createDrama);
              // 仅在发布成功（返回新建的短剧）时刷新列表与计数；
              // 用户取消或提交失败时不刷新页面。
              if (mounted && created != null) {
                ref.read(dramaManagementControllerProvider.notifier).refresh();
                ref
                    .read(creatorControllerProvider.notifier)
                    .refreshOnlineDramaCount();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: StoryColors.foregroundOf(
                Theme.of(context).brightness,
              ),
              foregroundColor: StoryColors.backgroundOf(
                Theme.of(context).brightness,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(71)),
              ),
            ),
            child: Text(
              context.l10n.creatorPublishNewDrama,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: StorySpacing.base),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(color: surface),
        child: loggedIn
            ? NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          StorySpacing.screenHorizontal,
                          StorySpacing.screenHorizontal,
                          StorySpacing.screenHorizontal,
                          0,
                        ),
                        child: _buildMetricCards(context),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ColoredBox(
                        color: surface,
                        child: StoryTabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicator: StoryTabIndicator(
                            color: StoryColors.foregroundOf(
                              Theme.of(context).brightness,
                            ),
                            width: 32,
                            height: 2,
                            borderRadius: 0,
                          ),
                          tabs: [
                            Tab(text: l10n.creatorDramaManagementTab),
                            Tab(text: l10n.creatorDramaNftTab),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    DramaManagementTab(l10n: l10n),
                    DramaNftTab(l10n: l10n),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
                children: [_buildLoginPrompt(context)],
              ),
      ),
    );
  }

  Widget _buildMetricCards(BuildContext context) {
    // Isolated Consumer with selects: metric changes rebuild only this row,
    // and unrelated CreatorState changes (dialogs, actor list) skip it.
    return Consumer(
      builder: (context, ref, _) {
        final isLoading = ref.watch(
          creatorControllerProvider.select((s) => s.isLoading),
        );
        final onlineDramaCount = ref.watch(
          creatorControllerProvider.select((s) => s.onlineDramaCount),
        );
        final ownedNftCount = ref.watch(
          creatorControllerProvider.select((s) => s.ownedNftCount),
        );
        return Row(
          children: [
            Expanded(
              child: CreatorMetricCard(
                title: context.l10n.creatorPublishedDramas,
                value: '$onlineDramaCount',
                isLoading: isLoading,
              ),
            ),
            const SizedBox(width: StorySpacing.md),
            Expanded(
              child: CreatorMetricCard(
                title: context.l10n.creatorOwnedNftCount,
                value: '$ownedNftCount',
                isLoading: isLoading,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(StorySpacing.lg),
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(theme.brightness),
        borderRadius: const BorderRadius.all(
          Radius.circular(StoryRadius.lgValue),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 32,
            color: StoryColors.mutedForegroundOf(theme.brightness),
          ),
          const SizedBox(height: StorySpacing.sm),
          Text(
            context.l10n.creatorLoginPrompt,
            style: StoryTextStyles.bodyMedium(),
          ),
        ],
      ),
    );
  }
}
