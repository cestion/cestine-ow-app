import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../components/components.dart';
import '../controller/follow_action_controller.dart';
import '../controller/user_profile_actor_collections_state.dart';
import '../controller/user_profile_dramas_state.dart';
import '../core/logging_request_policy_observer.dart';
import '../core/request_keys.dart';
import '../core/request_throttle.dart';
import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../l10n/app_localizations.dart';
import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../provider/tab_index_provider.dart';
import '../repositories/user_repository.dart';
import '../routes/route_names.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_radius.dart';
import '../styles/story_text_styles.dart';
import '../services/connectivity_service.dart';
import '../utils/auth_navigation.dart';
import '../utils/format_number.dart';
import 'widgets/profile/profile_actor_ip_tab_slivers.dart';
import 'widgets/profile/profile_list_tab_slivers.dart';
import 'widgets/watch_history/watch_history_profile_slivers.dart';
import '../widgets/widgets.dart';
import '../foundation/navigator.dart';

/// Profile content tabs. Each entry carries an [enabled] switch so a tab can
/// be hidden without removing its build/revalidate logic — flipping the switch
/// back to `true` restores the tab end-to-end.
///
/// Individual entries can still be disabled temporarily without removing
/// their build and revalidation logic.
enum _ProfileTabKind { dramas, works, actorIp, likes, favorites, watchHistory }

class _ProfileTabConfig {
  const _ProfileTabConfig({
    required this.kind,
    required this.enabled,
    this.selfOnly = false,
  });

  final _ProfileTabKind kind;
  final bool enabled;
  final bool selfOnly;
}

const _kActorIpTabEnabled = true;

const _allProfileTabs = <_ProfileTabConfig>[
  _ProfileTabConfig(kind: _ProfileTabKind.dramas, enabled: true),
  _ProfileTabConfig(kind: _ProfileTabKind.works, enabled: true),
  _ProfileTabConfig(
    kind: _ProfileTabKind.actorIp,
    enabled: _kActorIpTabEnabled,
  ),
  _ProfileTabConfig(kind: _ProfileTabKind.likes, enabled: true),
  _ProfileTabConfig(kind: _ProfileTabKind.favorites, enabled: true),
  _ProfileTabConfig(
    kind: _ProfileTabKind.watchHistory,
    enabled: true,
    selfOnly: true,
  ),
];

/// Unified profile page — serves both "My Profile" (self) and "User Profile" (other).
///
/// When [userId] is omitted or matches the current user, the page renders in
/// "self" mode with wallet info. When [userId] is provided and differs from the
/// current user, it renders the public view without wallet actions.
class PublicProfilePage extends ConsumerStatefulWidget {
  final String? userId;
  final bool showBack;

  const PublicProfilePage({super.key, this.userId, this.showBack = true});

  @override
  ConsumerState<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends ConsumerState<PublicProfilePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _didRefresh = false;
  TabController? _tabController;
  final Set<int> _loadedTabs = {0};
  late final ConnectivityService _connectivityService;
  late bool _wasOnline;
  bool _wasBackgrounded = false;
  /// Bottom-nav Profile re-entry throttle (list/stats revalidation).
  final RequestThrottle _profileTabThrottle =
      MemoryRequestThrottle(observer: debugRequestPolicyObserver);
  int _selectedListTabIndex = 0;
  WorkContentType _favoriteContentType = WorkContentType.shortDrama;
  WorkContentType _watchHistoryContentType = WorkContentType.shortDrama;
  bool? _blockedByMeOverride;
  BlockRelation _lastBlockRelation = BlockRelation.none;
  bool _contentRestricted = false;

  bool get _isTabControllerReady {
    final tabCount = _visibleTabs.length;
    return tabCount > 0 &&
        _tabController != null &&
        _tabController!.length == tabCount;
  }

  void _syncTabController(int length) {
    if (length <= 0) {
      _disposeTabController();
      return;
    }
    if (_tabController != null && _tabController!.length == length) {
      return;
    }

    final oldIndex = _tabController?.index ?? _selectedListTabIndex;
    _disposeTabController();
    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: oldIndex.clamp(0, length - 1),
    )..addListener(_handleListTabChanged);
    _selectedListTabIndex = _tabController!.index;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectivityService = ref.read(connectivityProvider);
    _wasOnline = _connectivityService.value;
    _connectivityService.addListener(_handleConnectivityChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 未登录查看他人主页 → 跳转登录；登录失败则返回。
      if (!_isSelf && !ref.read(authControllerProvider).isLoggedIn) {
        unawaited(_redirectToLoginIfGuest());
        return;
      }
      if (_didRefresh) return;
      _didRefresh = true;
      if (_isSelf) {
        unawaited(_refreshSelfProfile(force: false));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityService.removeListener(_handleConnectivityChanged);
    _disposeTabController();
    super.dispose();
  }

  bool get _isSelf {
    final currentUserId = ref.read(authControllerProvider).userId;
    return widget.userId == null || widget.userId == currentUserId;
  }

  /// 未登录查看他人主页时跳转登录页；登录失败或取消则返回上一页。
  Future<void> _redirectToLoginIfGuest() async {
    if (!mounted) return;
    final loggedIn = await ensureLoggedInOrRedirect(context, ref);
    if (!loggedIn && mounted) {
      Navigator.of(context).pop();
    }
  }

  List<_ProfileTabConfig> get _visibleTabs => _allProfileTabs
      .where((tab) => tab.enabled && (!tab.selfOnly || _isSelf))
      .toList(growable: false);

  String _tabLabel(AppLocalizations l10n, _ProfileTabKind kind) {
    return switch (kind) {
      _ProfileTabKind.dramas => l10n.profileTabDramas,
      _ProfileTabKind.works => l10n.profileTabWorks,
      _ProfileTabKind.actorIp => l10n.profileTabActorIp,
      _ProfileTabKind.likes => l10n.playerLike,
      _ProfileTabKind.favorites => l10n.playerFavorite,
      _ProfileTabKind.watchHistory => l10n.profileWatchHistory,
    };
  }

  bool get _isProfilePageVisible {
    if (_tabController == null) return false;
    if (_isSelf && !widget.showBack) {
      return ref.read(tabIndexProvider) == StoryTab.profile.index;
    }
    return ModalRoute.of(context)?.isCurrent ?? false;
  }

  void _disposeTabController() {
    _tabController?.removeListener(_handleListTabChanged);
    _tabController?.dispose();
    _tabController = null;
  }

  void _handleListTabChanged() {
    final controller = _tabController;
    if (controller == null || controller.indexIsChanging) return;

    final index = controller.index;
    final didSwitchTab = index != _selectedListTabIndex;
    final alreadyLoaded = _loadedTabs.contains(index);
    _selectedListTabIndex = index;
    if (!mounted) return;
    if (didSwitchTab || !alreadyLoaded) {
      setState(() => _loadedTabs.add(index));
    }
    // First visit loads via the tab provider's own refresh. Only revisit an
    // already-mounted tab through the shared silent + throttle path.
    if (didSwitchTab && alreadyLoaded && _isProfilePageVisible) {
      unawaited(_silentRevalidateActiveTab());
    }
  }

  bool _handleProfileScrollNotification(ScrollNotification notification) {
    // Ignore nested / horizontal bars (e.g. scrollable StoryTabBar) and
    // non-update notifications so tab swipes do not spam loadMore.
    if (notification.depth != 0) return false;
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is! ScrollUpdateNotification &&
        notification is! OverscrollNotification) {
      return false;
    }
    if (notification.metrics.extentAfter >= StorySpacing.scrollThreshold) {
      return false;
    }
    unawaited(_loadMoreActiveTab());
    return false;
  }

  Future<void> _loadMoreActiveTab() async {
    if (!mounted || _contentRestricted) return;
    final index = _tabController?.index ?? _selectedListTabIndex;
    final kind = _visibleTabs.elementAtOrNull(index)?.kind;
    if (kind == null) return;
    final userId = _isSelf ? null : widget.userId;

    switch (kind) {
      case _ProfileTabKind.dramas:
      case _ProfileTabKind.works:
      case _ProfileTabKind.likes:
      case _ProfileTabKind.favorites:
        final type = _dramaTypeForKind(kind)!;
        final param = UserProfileDramaParam(
          userId: userId,
          type: type,
          contentType: type == ProfileDramaType.favorites
              ? _favoriteContentType
              : WorkContentType.shortDrama,
        );
        await loadMoreProfileListTab(ref, param);
      case _ProfileTabKind.actorIp:
        await loadMoreProfileActorIpTab(
          ref,
          UserProfileActorParam(userId: userId),
        );
      case _ProfileTabKind.watchHistory:
        await loadMoreWatchHistoryProfileTab(ref, _watchHistoryContentType);
    }
  }

  void _handleConnectivityChanged() {
    final isOnline = _connectivityService.value;
    final didRecover = !_wasOnline && isOnline;
    _wasOnline = isOnline;
    if (didRecover && mounted && _isProfilePageVisible) {
      unawaited(_silentRevalidateActiveTab());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) {
      _wasBackgrounded =
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.hidden ||
          state == AppLifecycleState.paused;
      return;
    }
    final didReturnFromBackground = _wasBackgrounded;
    _wasBackgrounded = false;
    if (didReturnFromBackground && _isProfilePageVisible) {
      unawaited(_silentRevalidateActiveTab());
    }
  }

  void _markProfileRevalidated([_ProfileTabKind? kind]) {
    final resolved =
        kind ??
        _visibleTabs
            .elementAtOrNull(_tabController?.index ?? _selectedListTabIndex)
            ?.kind;
    if (resolved == null) return;
    _profileTabThrottle.mark(RequestKeys.profileTabRevalidate(resolved.name));
  }

  bool _tryClaimProfileTabRevalidate(_ProfileTabKind kind) =>
      _profileTabThrottle.tryClaim(
        RequestKeys.profileTabRevalidate(kind.name),
        window: StoryConstants.profileTabRevalidateThrottle,
      );

  /// Silent revalidate of the visible list tab (15s per-kind throttle).
  ///
  /// Covers bottom-nav Profile re-entry, App resume, and revisiting an already
  /// loaded in-page list tab. First mounts still load via the provider; pull
  /// / filter / login force paths bypass via [RequestThrottle.resetAll] or
  /// non-silent [refresh].
  Future<bool> _silentRevalidateActiveTab() async {
    if (!mounted || !_isProfilePageVisible || _contentRestricted) {
      return false;
    }
    final index = _tabController?.index ?? _selectedListTabIndex;
    final kind = _visibleTabs.elementAtOrNull(index)?.kind;
    if (kind == null) return false;
    if (!_tryClaimProfileTabRevalidate(kind)) return false;
    await _revalidateTabKind(
      kind,
      userId: _isSelf ? null : widget.userId,
      silent: true,
    );
    return true;
  }

  ProfileDramaType? _dramaTypeForKind(_ProfileTabKind kind) {
    return switch (kind) {
      _ProfileTabKind.dramas => ProfileDramaType.published,
      _ProfileTabKind.works => ProfileDramaType.works,
      _ProfileTabKind.likes => ProfileDramaType.likes,
      _ProfileTabKind.favorites => ProfileDramaType.favorites,
      _ProfileTabKind.actorIp || _ProfileTabKind.watchHistory => null,
    };
  }

  /// Revalidate (silent or refresh) the provider backing [kind].
  Future<void> _revalidateTabKind(
    _ProfileTabKind kind, {
    required String? userId,
    required bool silent,
  }) async {
    switch (kind) {
      case _ProfileTabKind.dramas:
      case _ProfileTabKind.works:
      case _ProfileTabKind.likes:
      case _ProfileTabKind.favorites:
        final type = _dramaTypeForKind(kind)!;
        final param = UserProfileDramaParam(
          userId: userId,
          type: type,
          contentType: type == ProfileDramaType.favorites
              ? _favoriteContentType
              : WorkContentType.shortDrama,
        );
        final notifier = ref.read(userProfileDramasProvider(param).notifier);
        if (silent) {
          await notifier.silentRevalidate();
        } else {
          await notifier.refresh();
        }
      case _ProfileTabKind.actorIp:
        final notifier = ref.read(
          userProfileActorCollectionsProvider(
            UserProfileActorParam(userId: userId),
          ).notifier,
        );
        if (silent) {
          await notifier.silentRevalidate();
        } else {
          await notifier.refresh();
        }
      case _ProfileTabKind.watchHistory:
        if (_watchHistoryContentType.isShortVideo) {
          await ref
              .read(watchHistoryVideoControllerProvider.notifier)
              .revalidate();
        } else {
          await ref
              .read(watchHistoryDramaControllerProvider.notifier)
              .revalidate();
        }
    }
  }

  Future<void> _refreshActiveTabDramas({String? userId}) async {
    final index = _tabController?.index ?? 0;
    final kind = _visibleTabs.elementAtOrNull(index)?.kind;
    if (kind == null) return;
    await _revalidateTabKind(kind, userId: userId, silent: false);
  }

  /// Full self refresh after login / session change (header + visible tab).
  ///
  /// [force] also drops cached profile list providers (account switch). Soft
  /// first-open refresh only revalidates the header + active tab so swiping
  /// other tabs later does not inherit a mass invalidate/refetch storm.
  Future<void> _refreshSelfProfile({required bool force}) async {
    // Align the visibility throttle clock so a near-simultaneous tab listen
    // does not immediately re-hit the same list/stats endpoints.
    _markProfileRevalidated();
    if (force) {
      for (final tab in _visibleTabs) {
        switch (tab.kind) {
          case _ProfileTabKind.dramas:
          case _ProfileTabKind.works:
          case _ProfileTabKind.likes:
            ref.invalidate(
              userProfileDramasProvider(
                UserProfileDramaParam(type: _dramaTypeForKind(tab.kind)!),
              ),
            );
          case _ProfileTabKind.favorites:
            ref.invalidate(
              userProfileDramasProvider(
                const UserProfileDramaParam(type: ProfileDramaType.favorites),
              ),
            );
            ref.invalidate(
              userProfileDramasProvider(
                const UserProfileDramaParam(
                  type: ProfileDramaType.favorites,
                  contentType: WorkContentType.shortVideo,
                ),
              ),
            );
          case _ProfileTabKind.actorIp:
            ref.invalidate(
              userProfileActorCollectionsProvider(const UserProfileActorParam()),
            );
          case _ProfileTabKind.watchHistory:
            ref.invalidate(watchHistoryDramaControllerProvider);
            ref.invalidate(watchHistoryVideoControllerProvider);
        }
      }
    }
    await _refreshProfileHeader(force: force, isSelf: true);
    await _refreshActiveTabDramas();
  }

  /// Pull-to-refresh: header stats + currently selected drama tab only.
  Future<void> _onPullToRefresh({required bool isSelf}) async {
    // User-initiated refresh must bypass every per-kind tab throttle window.
    _profileTabThrottle.resetAll();
    if (isSelf) {
      await Future.wait([
        _refreshProfileHeader(force: true, isSelf: true),
        _refreshActiveTabDramas(),
      ]);
      _markProfileRevalidated();
      return;
    }
    final otherUserId = widget.userId!;
    await Future.wait([
      _refreshProfileHeader(
        force: true,
        isSelf: false,
        otherUserId: otherUserId,
      ),
      _refreshActiveTabDramas(userId: otherUserId),
    ]);
    _markProfileRevalidated();
  }

  Future<void> _refreshProfileHeader({
    required bool force,
    required bool isSelf,
    String? otherUserId,
  }) async {
    if (isSelf) {
      final selfId = ref.read(authControllerProvider).userId;
      final futures = <Future<void>>[
        ref.read(profileControllerProvider.notifier).refresh(force: force),
        ref.read(onChainWalletBalanceProvider.notifier).refresh(),
      ];
      if (selfId != null && selfId.isNotEmpty) {
        ref.invalidate(followStatsProvider(selfId));
        futures.add(ref.read(followStatsProvider(selfId).future));
        ref.invalidate(workStatsProvider(selfId));
        futures.add(ref.read(workStatsProvider(selfId).future));
      }
      await Future.wait(futures);
      return;
    }

    final userId = otherUserId!;
    ref.invalidate(publicProfileProvider(userId));
    ref.invalidate(followStatsProvider(userId));
    final futures = <Future<void>>[
      ref.read(publicProfileProvider(userId).future),
      ref.read(followStatsProvider(userId).future),
    ];

    // Refresh viewer↔target relation when logged in. Skip if a follow/unfollow
    // for this user is in flight to avoid racing a stale getRelation response.
    final loggedIn = ref.read(authControllerProvider).isLoggedIn;
    final relationPending = ref
        .read(followActionControllerProvider)
        .isPending(userId);
    if (loggedIn && !relationPending) {
      ref.invalidate(followRelationProvider(userId));
      futures.add(ref.read(followRelationProvider(userId).future));
      ref.invalidate(blockRelationProvider(userId));
      futures.add(ref.read(blockRelationProvider(userId).future));
    }

    await Future.wait(futures);
  }

  bool _isBlocked(UserProfile? user, BlockRelation relation) {
    final blockedByMe =
        _blockedByMeOverride ??
        (relation.blockedByMe || (user?.blockedByMe ?? false));
    return blockedByMe ||
        relation.blockedByTarget ||
        (user?.blockedByTarget ?? false);
  }

  bool _isBlockedByMe(UserProfile? user, BlockRelation relation) {
    return _blockedByMeOverride ??
        (relation.blockedByMe || (user?.blockedByMe ?? false));
  }

  Future<void> _showOtherProfileActions(
    UserProfile? user,
    BlockRelation relation,
  ) async {
    final userId = widget.userId;
    StoryLogger.d(
      'More actions tapped userId=$userId',
      tag: 'PublicProfileActions',
    );
    final pending = userId == null
        ? false
        : ref.read(followActionControllerProvider).isPending(userId);
    if (userId == null || userId.isEmpty) {
      StoryLogger.w(
        'More actions ignored: target userId is empty',
        tag: 'PublicProfileActions',
      );
      return;
    }
    if (pending) {
      StoryLogger.w(
        'More actions ignored: relation action is pending userId=$userId',
        tag: 'PublicProfileActions',
      );
      return;
    }

    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn) {
      StoryLogger.i(
        'More actions requires login userId=$userId',
        tag: 'PublicProfileActions',
      );
      await context.storyPush(RouteNames.login);
      return;
    }

    final blockedByMe = _isBlockedByMe(user, relation);
    StoryLogger.d(
      'Showing more actions sheet userId=$userId blockedByMe=$blockedByMe',
      tag: 'PublicProfileActions',
    );
    final action = await PublicProfileMoreSheet.show(
      context,
      blockedByMe: blockedByMe,
    );
    if (!mounted) {
      StoryLogger.w(
        'More actions result ignored: page unmounted userId=$userId action=$action',
        tag: 'PublicProfileActions',
      );
      return;
    }
    if (action == null) {
      StoryLogger.d(
        'More actions sheet dismissed userId=$userId',
        tag: 'PublicProfileActions',
      );
      return;
    }
    StoryLogger.i(
      'More action selected userId=$userId action=${action.name}',
      tag: 'PublicProfileActions',
    );
    if (action == PublicProfileMoreAction.report) {
      await context.storyPush(RouteNames.report,
        arguments: <String, dynamic>{
          'scope': UgcReportScope.user,
          'userId': userId,
          'targetDisplayName': user?.nickname,
          'targetAvatarUrl': user?.avatarUrl,
        });
    } else if (action == PublicProfileMoreAction.block) {
      final confirmed = await StoryDialog.confirm(
        context: context,
        title: context.l10n.publicProfileBlockConfirmTitle,
        message: context.l10n.publicProfileBlockConfirmMessage,
        confirmLabel: context.l10n.publicProfileBlock,
        confirmColor: StoryColors.destructive,
      );
      StoryLogger.d(
        'Block confirmation completed userId=$userId confirmed=$confirmed mounted=$mounted',
        tag: 'PublicProfileActions',
      );
      if (confirmed != true || !mounted) return;
      await _setBlockedByMe(true);
    } else {
      await _setBlockedByMe(false);
    }
  }

  Future<void> _setBlockedByMe(bool blocked) async {
    final userId = widget.userId;
    final pending = userId == null
        ? false
        : ref.read(followActionControllerProvider).isPending(userId);
    if (userId == null || userId.isEmpty) {
      StoryLogger.w(
        '${blocked ? 'Block' : 'Unblock'} ignored: target userId is empty',
        tag: 'PublicProfileActions',
      );
      return;
    }
    if (pending) {
      StoryLogger.w(
        '${blocked ? 'Block' : 'Unblock'} ignored: relation action is pending userId=$userId',
        tag: 'PublicProfileActions',
      );
      return;
    }

    StoryLogger.i(
      '${blocked ? 'Blocking' : 'Unblocking'} profile userId=$userId',
      tag: 'PublicProfileActions',
    );
    final action = ref.read(followActionControllerProvider.notifier);
    final result = blocked
        ? await action.block(userId)
        : await action.unblock(userId);
    if (!mounted) {
      StoryLogger.w(
        '${blocked ? 'Block' : 'Unblock'} result ignored: page unmounted userId=$userId',
        tag: 'PublicProfileActions',
      );
      return;
    }

    if (result.isFailure) {
      final error = result.errorOrNull;
      StoryLogger.e(
        '${blocked ? 'Block' : 'Unblock'} profile failed userId=$userId',
        error: error,
        tag: 'PublicProfileActions',
      );
      if (error != null) StoryToast.error(context, context.l10nError(error));
      return;
    }

    setState(() {
      _blockedByMeOverride = blocked;
      _lastBlockRelation = _lastBlockRelation.copyWith(blockedByMe: blocked);
    });
    StoryLogger.i(
      '${blocked ? 'Block' : 'Unblock'} profile succeeded userId=$userId',
      tag: 'PublicProfileActions',
    );

    StoryToast.success(
      context,
      blocked
          ? context.l10n.publicProfileBlockSuccess
          : context.l10n.publicProfileUnblockSuccess,
    );
    ref.invalidate(publicProfileProvider(userId));
    ref.invalidate(followRelationProvider(userId));
    ref.invalidate(blockRelationProvider(userId));
    final viewerId = ref.read(authControllerProvider).userId;
    if (viewerId != null && viewerId.isNotEmpty) {
      FollowRelationActions.invalidateStats(ref, viewerId);
    }
    FollowRelationActions.invalidateStats(ref, userId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (_isSelf) {
      // Main-tab profile State survives logout → login; re-pull after session
      // changes so header / stats / drama tabs cannot keep the prior account.
      ref.listen(authControllerProvider.select((c) => c.isLoggedIn), (
        prev,
        next,
      ) {
        if (prev == true && next == false) {
          _didRefresh = false;
          _disposeTabController();
          _loadedTabs
            ..clear()
            ..add(0);
          // keepAlive list providers survive logout; drop them so the next
          // session cannot paint the previous account's grids.
          ref.invalidate(watchHistoryDramaControllerProvider);
          ref.invalidate(watchHistoryVideoControllerProvider);
          for (final tab in _visibleTabs) {
            switch (tab.kind) {
              case _ProfileTabKind.dramas:
              case _ProfileTabKind.works:
              case _ProfileTabKind.likes:
                ref.invalidate(
                  userProfileDramasProvider(
                    UserProfileDramaParam(type: _dramaTypeForKind(tab.kind)!),
                  ),
                );
              case _ProfileTabKind.favorites:
                ref.invalidate(
                  userProfileDramasProvider(
                    const UserProfileDramaParam(
                      type: ProfileDramaType.favorites,
                    ),
                  ),
                );
                ref.invalidate(
                  userProfileDramasProvider(
                    const UserProfileDramaParam(
                      type: ProfileDramaType.favorites,
                      contentType: WorkContentType.shortVideo,
                    ),
                  ),
                );
              case _ProfileTabKind.actorIp:
                ref.invalidate(
                  userProfileActorCollectionsProvider(
                    const UserProfileActorParam(),
                  ),
                );
              case _ProfileTabKind.watchHistory:
                break;
            }
          }
        } else if (prev == false && next == true) {
          _didRefresh = true;
          _loadedTabs
            ..clear()
            ..add(0);
          _selectedListTabIndex = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(_refreshSelfProfile(force: true));
          });
        }
      });

      // IndexedStack keeps this page alive. Re-entering the bottom-nav Profile
      // tab therefore needs an explicit silent revalidation of the visible list.
      ref.listen<
        bool
      >(tabIndexProvider.select((index) => index == StoryTab.profile.index), (
        previous,
        isProfile,
      ) {
        if (previous == false && isProfile && mounted) {
          // Never invalidate/refetch synchronously inside build/listen.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(() async {
              final ran = await _silentRevalidateActiveTab();
              if (!ran || !mounted) return;
              final selfId = ref.read(authControllerProvider).userId;
              if (selfId != null && selfId.isNotEmpty) {
                ref.invalidate(workStatsProvider(selfId));
              }
            }());
          });
        }
      });

      final isLoggedIn = ref.watch(
        authControllerProvider.select((c) => c.isLoggedIn),
      );
      final user = ref.watch(authControllerProvider.select((c) => c.profile));

      if (!isLoggedIn) {
        return _buildPageScaffold(
          isSelf: true,
          body: ListView(
            children: [
              _buildProfileHeaderSection(
                context: context,
                user: user,
                isSelf: true,
                isLoggedIn: false,
                onLogin: () =>
                    context.storyPush(RouteNames.login),
              ),
              const SizedBox(height: StorySpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StorySpacing.screenHorizontal,
                ),
                child: _buildLoginPrompt(context, l10n),
              ),
            ],
          ),
        );
      }

      return _buildProfileLayout(
        context: context,
        l10n: l10n,
        theme: theme,
        user: user,
        isSelf: true,
      );
    }

    // Other profile mode
    final userId = widget.userId!;
    final async = ref.watch(publicProfileProvider(userId));
    final isLoggedIn = ref.watch(
      authControllerProvider.select((state) => state.isLoggedIn),
    );
    final asyncBlockRelation = isLoggedIn
        ? ref.watch(blockRelationProvider(userId))
        : null;

    Widget buildWithRelation(BlockRelation relation) {
      return async.when(
        loading: () => _buildPageScaffold(
          isSelf: false,
          body: const StoryLoading.centered(),
        ),
        error: (e, _) => _buildOtherProfileError(
          message: e.toString(),
          userId: userId,
          l10n: l10n,
        ),
        data: (result) {
          if (result.isFailure) {
            return _buildOtherProfileError(
              message: result.errorOrNull?.userMessage ?? l10n.commonLoadFailed,
              userId: userId,
              l10n: l10n,
            );
          }
          final user = result.dataOrNull;
          final effectiveRelation = BlockRelation(
            blockedByMe:
                _blockedByMeOverride ??
                (relation.blockedByMe || (user?.blockedByMe ?? false)),
            blockedByTarget:
                relation.blockedByTarget || (user?.blockedByTarget ?? false),
          );
          _lastBlockRelation = effectiveRelation;
          return _buildProfileLayout(
            context: context,
            l10n: l10n,
            theme: theme,
            user: user,
            isSelf: false,
            blockRelation: effectiveRelation,
          );
        },
      );
    }

    if (asyncBlockRelation == null) {
      return buildWithRelation(BlockRelation.none);
    }

    // After a successful local block/unblock action, keep the optimistic
    // relation visible while the GET endpoint revalidates in the background.
    if (_blockedByMeOverride != null) {
      final latest = asyncBlockRelation.asData?.value.dataOrNull;
      return buildWithRelation(latest ?? _lastBlockRelation);
    }

    return asyncBlockRelation.when(
      loading: () => _buildPageScaffold(
        isSelf: false,
        body: const StoryLoading.centered(),
      ),
      // Block relation is supplementary. A failed request must not turn the
      // whole profile into an error page or be interpreted as blocked.
      error: (_, _) => buildWithRelation(_lastBlockRelation),
      data: (result) {
        final relation = result.dataOrNull;
        if (relation == null) {
          return buildWithRelation(_lastBlockRelation);
        }
        return buildWithRelation(relation);
      },
    );
  }

  Widget _buildOtherProfileError({
    required String message,
    required String userId,
    required AppLocalizations l10n,
  }) {
    return _buildPageScaffold(
      isSelf: false,
      body: StoryStateWidget.error(
        message: message,
        actionLabel: l10n.dramaDetailRetry,
        onAction: () {
          ref.invalidate(publicProfileProvider(userId));
          ref.invalidate(blockRelationProvider(userId));
        },
      ),
    );
  }

  // ─── Shared Layout builder ──────────────────────────────────────────────

  Widget _buildProfileLayout({
    required BuildContext context,
    required AppLocalizations l10n,
    required ThemeData theme,
    required UserProfile? user,
    required bool isSelf,
    BlockRelation blockRelation = BlockRelation.none,
  }) {
    final userId = isSelf ? null : widget.userId;
    final walletAddress = isSelf
        ? ref.watch(
            authControllerProvider.select(
              (state) => state.effectiveSolanaAddress,
            ),
          )
        : '';
    final chainIconUrl = isSelf
        ? ref.watch(
            withdrawConfigProvider.select(
              (config) => config.svmChainInfo?.icon,
            ),
          )
        : null;
    final blocked = !isSelf && _isBlocked(user, blockRelation);
    final blockedByMe = !isSelf && _isBlockedByMe(user, blockRelation);
    _contentRestricted = blocked;

    if (blocked) {
      return _buildPageScaffold(
        isSelf: false,
        onMore: () => _showOtherProfileActions(user, blockRelation),
        body: RefreshIndicator(
          color: StoryColors.brandTeal,
          onRefresh: () => _refreshProfileHeader(
            force: true,
            isSelf: false,
            otherUserId: widget.userId!,
          ),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _buildProfileHeaderSection(
                  context: context,
                  user: user,
                  isSelf: false,
                  isLoggedIn: true,
                  blocked: true,
                  blockedByMe: blockedByMe,
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: _BlockedProfileContent(blockedByMe: blockedByMe),
              ),
            ],
          ),
        ),
      );
    }

    final visibleTabs = _visibleTabs;
    _syncTabController(visibleTabs.length);

    return _buildPageScaffold(
      isSelf: isSelf,
      onMore: isSelf
          ? null
          : () => _showOtherProfileActions(user, blockRelation),
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleProfileScrollNotification,
        child: RefreshIndicator(
          color: StoryColors.brandTeal,
          onRefresh: () => _onPullToRefresh(isSelf: isSelf),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeaderSection(
                      context: context,
                      user: user,
                      isSelf: isSelf,
                      isLoggedIn: true,
                      walletAddress: walletAddress,
                      chainIconUrl: chainIconUrl,
                      onEdit: isSelf
                          ? () => ProfileEditSheet.show(context)
                          : null,
                    ),
                    if (isSelf) const ProfileWalletSection(),
                  ],
                ),
              ),
              if (_isTabControllerReady)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StorySliverHeaderDelegate(
                    height: 48,
                    child: Material(
                      color: ProfileColors.listBackground(theme.brightness),
                      child: StoryTabBar(
                        controller: _tabController!,
                        isScrollable: true,
                        tabs: [
                          for (final tab in visibleTabs)
                            Tab(text: _tabLabel(l10n, tab.kind)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(
                  child: SizedBox(height: 48),
                ),
              ..._buildActiveProfileTabSlivers(
                l10n: l10n,
                userId: userId,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActiveProfileTabSlivers({
    required AppLocalizations l10n,
    required String? userId,
  }) {
    final index = _tabController?.index ?? _selectedListTabIndex;
    final kind = _visibleTabs.elementAtOrNull(index)?.kind;
    if (kind == null) return [];

    final isActive = _loadedTabs.contains(index);

    switch (kind) {
      case _ProfileTabKind.dramas:
        return buildProfileListTabSlivers(
          context,
          ref,
          param: UserProfileDramaParam(
            userId: userId,
            type: ProfileDramaType.published,
          ),
          emptyLabel: l10n.creatorNoPublishedDramas,
          isActive: isActive,
        );
      case _ProfileTabKind.works:
        return buildProfileListTabSlivers(
          context,
          ref,
          param: UserProfileDramaParam(
            userId: userId,
            type: ProfileDramaType.works,
          ),
          emptyLabel: l10n.publicProfileEmpty,
          isActive: isActive,
        );
      case _ProfileTabKind.actorIp:
        return buildProfileActorIpTabSlivers(
          context,
          ref,
          param: UserProfileActorParam(userId: userId),
          isActive: isActive,
        );
      case _ProfileTabKind.likes:
        return buildProfileListTabSlivers(
          context,
          ref,
          param: UserProfileDramaParam(
            userId: userId,
            type: ProfileDramaType.likes,
          ),
          emptyLabel: l10n.publicProfileLikedEmpty,
          isActive: isActive,
        );
      case _ProfileTabKind.favorites:
        return [
          if (isActive)
            SliverToBoxAdapter(
              child: ProfileWorkTypeFilterBar(
                selectedType: _favoriteContentType,
                onSelected: (contentType) {
                  if (_favoriteContentType == contentType) return;
                  setState(() => _favoriteContentType = contentType);
                },
              ),
            ),
          ...buildProfileListTabSlivers(
            context,
            ref,
            param: UserProfileDramaParam(
              userId: userId,
              type: ProfileDramaType.favorites,
              contentType: _favoriteContentType,
            ),
            emptyLabel: l10n.publicProfileEmpty,
            isActive: isActive,
          ),
        ];
      case _ProfileTabKind.watchHistory:
        return buildWatchHistoryProfileTabSlivers(
          context,
          ref,
          isActive: isActive,
          selectedType: _watchHistoryContentType,
          onTypeChanged: (contentType) {
            if (_watchHistoryContentType == contentType) return;
            setState(() => _watchHistoryContentType = contentType);
            // Filter bar does not go through TabController; load the newly
            // selected history list explicitly.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              unawaited(
                _revalidateTabKind(
                  _ProfileTabKind.watchHistory,
                  userId: null,
                  silent: false,
                ),
              );
            });
          },
        );
    }
  }

  Widget _buildProfileHeaderSection({
    required BuildContext context,
    required UserProfile? user,
    required bool isSelf,
    required bool isLoggedIn,
    String walletAddress = '',
    String? chainIconUrl,
    VoidCallback? onEdit,
    VoidCallback? onLogin,
    bool blocked = false,
    bool blockedByMe = false,
  }) {
    final targetUserId = isSelf
        ? (user?.userId ??
              user?.id ??
              ref.read(authControllerProvider).userId ??
              '')
        : (widget.userId ?? '');
    final showStats = user != null && (isLoggedIn || !isSelf);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PublicProfileHeader(
          user: user,
          isSelf: isSelf,
          isLoggedIn: isLoggedIn,
          walletAddress: walletAddress,
          chainIconUrl: chainIconUrl,
          onEdit: onEdit,
          onLogin: onLogin,
        ),
        if (showStats)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StorySpacing.screenHorizontal,
              StorySpacing.xxs,
              StorySpacing.screenHorizontal,
              StorySpacing.sm,
            ),
            child: _FollowStatsRow(
              userId: targetUserId,
              embeddedStats: user.followStats,
              enableNavigation: isSelf,
            ),
          ),
        if (user?.bio?.trim().isNotEmpty ?? false)
          ProfileBioSection(bio: user!.bio!),
        if (!isSelf && targetUserId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StorySpacing.screenHorizontal,
              StorySpacing.base,
              StorySpacing.screenHorizontal,
              10,
            ),
            child: blocked
                ? _ProfileBlockButtonWithPending(
                    targetUserId: targetUserId,
                    blockedByMe: blockedByMe,
                    onUnblock: () => _setBlockedByMe(false),
                  )
                : _ProfileFollowButton(
                    targetUserId: targetUserId,
                    seedStatus: user?.relationStatus,
                    displayName: user?.nickname,
                  ),
          ),
      ],
    );
  }

  Widget _buildPageScaffold({
    required bool isSelf,
    required Widget body,
    VoidCallback? onMore,
  }) {
    final foreground = StoryColors.foregroundOf(Theme.of(context).brightness);
    final l10n = context.l10n;
    // Tab "My Profile" uses [showBack]=false. Any pushed profile (including
    // opening your own from the player / feed avatar) must keep a back button.
    final showNavBack = widget.showBack && Navigator.of(context).canPop();
    final showProfileSidebarButton = isSelf && !widget.showBack;

    return AppScaffold(
      title: '',
      titleWidget: const SizedBox.shrink(),
      backgroundColor: ProfileColors.listBackground(
        Theme.of(context).brightness,
      ),
      centerTitle: false,
      showBack: false,
      toolbarHeight: 44,
      leadingWidth: 48,
      leading: showNavBack
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 24, color: foreground),
              onPressed: () => Navigator.of(context).pop(),
            )
          : isSelf
          ? IconButton(
              icon: Icon(Icons.menu, size: 24, color: foreground),
              onPressed: () => ref
                  .read(mainShellScaffoldKeyProvider)
                  .currentState
                  ?.openDrawer(),
            )
          : null,
      actions: [
        if (showProfileSidebarButton)
          IconButton(
            tooltip: l10n.drawerProfile,
            onPressed: () => showProfileSidebar(context),
            icon: Icon(Icons.grid_view_outlined, size: 24, color: foreground),
          )
        else if (!isSelf)
          IconButton(
            onPressed: onMore,
            icon: Icon(Icons.more_horiz, size: 24, color: foreground),
          ),
      ],
      body: body,
    );
  }

  Widget _buildLoginPrompt(BuildContext context, AppLocalizations l10n) {
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
          Text(l10n.creatorLoginPrompt, style: StoryTextStyles.bodyMedium()),
          const SizedBox(height: StorySpacing.md),
          StoryButton(
            label: l10n.profileClickLogin,
            onPressed: () => context.storyPush(RouteNames.login),
          ),
        ],
      ),
    );
  }
}

/// Figma `1061:118095`: blocked profile content replaces the complete tab/list
/// surface, so no work provider is mounted while either side has blocked the
/// other.
class _BlockedProfileContent extends StatelessWidget {
  const _BlockedProfileContent({required this.blockedByMe});

  final bool blockedByMe;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ColoredBox(
      color: ProfileColors.listBackground(brightness),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 120, 40, 40),
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/common/profile_blocked_logo.svg',
                width: 68,
                height: 68,
              ),
              const SizedBox(height: 16),
              Text(
                blockedByMe
                    ? context.l10n.publicProfileBlockedByMeContent
                    : context.l10n.publicProfileBlockedContent,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ProfileColors.secondaryText(brightness),
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Watches follow-action pending state only for the block/unblock control.
class _ProfileBlockButtonWithPending extends ConsumerWidget {
  const _ProfileBlockButtonWithPending({
    required this.targetUserId,
    required this.blockedByMe,
    required this.onUnblock,
  });

  final String targetUserId;
  final bool blockedByMe;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
      followActionControllerProvider.select(
        (state) => state.isPending(targetUserId),
      ),
    );
    return _ProfileBlockButton(
      loading: pending,
      // A target-side block still uses the exact restricted chrome, but only
      // a viewer-side block can be undone.
      onPressed: blockedByMe ? onUnblock : null,
    );
  }
}

/// Figma outlined `解除拉黑` action. It intentionally shares the same 44px
/// geometry as the non-primary follow states.
class _ProfileBlockButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const _ProfileBlockButton({required this.loading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = ProfileColors.followOutlinedFg(brightness);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ProfileColors.followOutlinedBorder(brightness),
              width: ProfileColors.followOutlinedBorderWidth,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: SizedBox(
              height: 24,
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(foreground),
                        ),
                      )
                    : Text(
                        context.l10n.publicProfileUnblock,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileFollowButton extends ConsumerWidget {
  final String targetUserId;
  final FollowRelationStatus? seedStatus;
  final String? displayName;

  const _ProfileFollowButton({
    required this.targetUserId,
    this.seedStatus,
    this.displayName,
  });

  static bool _isPrimary(FollowRelationStatus status) =>
      status == FollowRelationStatus.none;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(
      authControllerProvider.select((a) => a.isLoggedIn),
    );
    final pending = ref.watch(
      followActionControllerProvider.select((s) => s.isPending(targetUserId)),
    );

    // relation API requires login; anonymous viewers see follow CTA → login.
    if (!isLoggedIn) {
      return _ProfileFollowButtonChrome(
        status: FollowRelationStatus.none,
        loading: false,
        onPressed: () => context.storyPush(RouteNames.login),
      );
    }

    final asyncRelation = ref.watch(followRelationProvider(targetUserId));
    // Prefer live relation; keep seed / previous value while a background
    // refresh is in flight so pull-to-refresh does not flash the CTA.
    final status =
        asyncRelation.asData?.value ?? seedStatus ?? FollowRelationStatus.none;
    // Spinner only for first load (no value yet) or an in-flight follow action —
    // not for invalidate/reload during pull-to-refresh.
    final relationFirstLoad =
        asyncRelation.isLoading && !asyncRelation.hasValue;

    return _ProfileFollowButtonChrome(
      status: status,
      loading: pending || relationFirstLoad,
      onPressed: () => _onTap(context, ref, status),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    FollowRelationStatus status,
  ) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn) {
      await context.storyPush(RouteNames.login);
      return;
    }
    if (targetUserId.isEmpty || targetUserId == auth.userId) return;

    final action = ref.read(followActionControllerProvider.notifier);
    final viewerId = auth.userId ?? '';

    if (status == FollowRelationStatus.following ||
        status == FollowRelationStatus.mutual) {
      final confirmed = await UnfollowConfirmDialog.show(
        context,
        displayName: displayName,
      );
      if (confirmed != true || !context.mounted) return;

      final result = await action.unfollow(targetUserId);
      if (!context.mounted) return;
      if (result.isFailure) {
        final err = result.errorOrNull;
        if (err != null) {
          StoryToast.error(context, context.l10nError(err));
        }
        return;
      }
    } else {
      final result = await action.follow(targetUserId);
      if (!context.mounted) return;
      if (result.isFailure) {
        final err = result.errorOrNull;
        if (err != null) {
          StoryToast.error(context, context.l10nError(err));
        }
        return;
      }
    }

    ref.invalidate(followRelationProvider(targetUserId));
    ref.invalidate(publicProfileProvider(targetUserId));
    if (viewerId.isNotEmpty) {
      FollowRelationActions.invalidateStats(ref, viewerId);
    }
    FollowRelationActions.invalidateStats(ref, targetUserId);
  }
}

/// Full-width follow CTA for guest profile — Figma `723:87210` / `872:176514`.
class _ProfileFollowButtonChrome extends StatelessWidget {
  final FollowRelationStatus status;
  final bool loading;
  final VoidCallback? onPressed;

  const _ProfileFollowButtonChrome({
    required this.status,
    required this.loading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final isPrimary = _ProfileFollowButton._isPrimary(status);
    final bg = isPrimary
        ? ProfileColors.followPrimaryBg(brightness)
        : Colors.transparent;
    final fg = isPrimary
        ? ProfileColors.followPrimaryFg(brightness)
        : ProfileColors.followOutlinedFg(brightness);
    final borderColor = isPrimary
        ? null
        : ProfileColors.followOutlinedBorder(brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: borderColor == null
                ? null
                : Border.all(
                    color: borderColor,
                    width: ProfileColors.followOutlinedBorderWidth,
                  ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isPrimary ? 12 : 24,
              vertical: isPrimary ? 8 : 10,
            ),
            child: SizedBox(
              height: isPrimary ? 26 : 24,
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(fg),
                        ),
                      )
                    : Text(
                        FollowRelationButton.labelFor(l10n, status),
                        style: TextStyle(
                          fontSize: isPrimary ? 15 : 14,
                          height: isPrimary ? 22 / 15 : 20 / 14,
                          fontWeight: isPrimary
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: fg,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowStatsRow extends ConsumerWidget {
  final String userId;
  final FollowStats? embeddedStats;
  final bool enableNavigation;

  const _FollowStatsRow({
    required this.userId,
    this.embeddedStats,
    this.enableNavigation = true,
  });

  void _open(BuildContext context, FollowListType tab) {
    if (userId.isEmpty) return;
    context.storyPush(RouteNames.followRelations,
      arguments: <String, dynamic>{
        'userId': userId,
        'tab': switch (tab) {
          FollowListType.following => 'following',
          FollowListType.followers => 'followers',
          FollowListType.mutuals => 'mutuals',
        },
      });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Follow cells share one provider; likes are independent. Give each visual
    // column equal width via flex (N follow cols : 1 likes col).
    final followFlex = enableNavigation ? 3 : 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: followFlex,
            child: _FollowCountsSection(
              userId: userId,
              embeddedStats: embeddedStats,
              enableNavigation: enableNavigation,
              onOpen: _open,
            ),
          ),
          SizedBox(
            height: 13,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: ProfileColors.outlineBorder(
                Theme.of(context).brightness,
              ),
            ),
          ),
          Expanded(
            child: _LikesReceivedSection(userId: userId),
          ),
        ],
      ),
    );
  }
}

class _FollowCountsSection extends ConsumerWidget {
  const _FollowCountsSection({
    required this.userId,
    required this.embeddedStats,
    required this.enableNavigation,
    required this.onOpen,
  });

  final String userId;
  final FollowStats? embeddedStats;
  final bool enableNavigation;
  final void Function(BuildContext context, FollowListType tab) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final asyncStats = userId.isEmpty
        ? null
        : ref.watch(followStatsProvider(userId));
    final stats = asyncStats?.asData?.value ?? embeddedStats;
    final statsLoading = stats == null && (asyncStats?.isLoading ?? false);

    Widget cell({
      String? count,
      required String label,
      bool loading = false,
      VoidCallback? onTap,
    }) {
      return _FollowStatCell(
        count: count,
        label: label,
        loading: loading,
        onTap: onTap,
        theme: theme,
      );
    }

    Widget separator() => SizedBox(
      height: 13,
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: ProfileColors.outlineBorder(theme.brightness),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: cell(
            count: stats == null ? null : formatNumber(stats.followingCount, 0),
            label: l10n.publicProfileFollowing,
            loading: statsLoading,
            onTap: enableNavigation && stats != null
                ? () => onOpen(context, FollowListType.following)
                : null,
          ),
        ),
        separator(),
        Expanded(
          child: cell(
            count: stats == null ? null : formatNumber(stats.followerCount, 0),
            label: l10n.publicProfileFollowers,
            loading: statsLoading,
            onTap: enableNavigation && stats != null
                ? () => onOpen(context, FollowListType.followers)
                : null,
          ),
        ),
        if (enableNavigation) ...[
          separator(),
          Expanded(
            child: cell(
              count: stats == null ? null : formatNumber(stats.mutualCount, 0),
              label: l10n.followTabMutual,
              loading: statsLoading,
              onTap: stats == null
                  ? null
                  : () => onOpen(context, FollowListType.mutuals),
            ),
          ),
        ],
      ],
    );
  }
}

class _LikesReceivedSection extends ConsumerWidget {
  const _LikesReceivedSection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final asyncWorkStats = userId.isEmpty
        ? null
        : ref.watch(workStatsProvider(userId));
    final workStats = asyncWorkStats?.asData?.value;
    final likeCount = workStats?.totalLikeCount;
    final likeLoading =
        likeCount == null && (asyncWorkStats?.isLoading ?? false);

    return _FollowStatCell(
      count: likeCount == null ? '0' : formatNumber(likeCount, 0),
      label: l10n.profileLikesReceived,
      loading: likeLoading,
      theme: theme,
    );
  }
}

class _FollowStatCell extends StatelessWidget {
  const _FollowStatCell({
    required this.count,
    required this.label,
    required this.loading,
    required this.theme,
    this.onTap,
  });

  final String? count;
  final String label;
  final bool loading;
  final ThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const SizedBox(
              height: 24,
              child: Center(
                child: StorySkeletonBox(
                  width: 28,
                  height: 16,
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
              ),
            )
          else
            Text(
              count ?? '—',
              maxLines: 1,
              style: TextStyle(
                color: StoryColors.foregroundOf(theme.brightness),
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: ProfileColors.secondaryText(theme.brightness),
              fontSize: 12,
              height: 16 / 12,
              letterSpacing: 0.04,
            ),
          ),
        ],
      ),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }
}
