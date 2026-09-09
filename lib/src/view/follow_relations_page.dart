import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/follow/follow_relation_empty.dart';
import '../components/follow/follow_user_more_sheet.dart';
import '../components/follow/follow_user_tile.dart';
import '../components/follow/unfollow_confirm_dialog.dart';
import '../components/common/story_toast.dart';
import '../controller/follow_action_controller.dart';
import '../controller/follow_list_controller.dart';
import '../controller/follow_list_state.dart';
import '../core/story_logger.dart';
import '../l10n/app_localizations.dart';
import '../l10n/story_l10n.dart';
import '../model/follow_models.dart';
import '../provider/app_providers.dart';
import '../provider/tab_index_provider.dart';
import '../routes/route_names.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../widgets/widgets.dart';
import '../foundation/navigator.dart';

class FollowRelationsPage extends ConsumerStatefulWidget {
  final String userId;
  final FollowListType initialTab;

  const FollowRelationsPage({
    super.key,
    required this.userId,
    this.initialTab = FollowListType.followers,
  });

  @override
  ConsumerState<FollowRelationsPage> createState() =>
      _FollowRelationsPageState();
}

class _FollowRelationsPageState extends ConsumerState<FollowRelationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<int> _loadedTabs = {};

  static const _tabs = [
    FollowListType.following,
    FollowListType.followers,
    FollowListType.mutuals,
  ];

  int _indexFor(FollowListType type) => _tabs.indexOf(type);

  @override
  void initState() {
    super.initState();
    final initialIndex = _indexFor(widget.initialTab).clamp(0, 2);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
    _loadedTabs.add(initialIndex);
    _tabController.addListener(_onTabControllerTick);
    StoryLogger.d(
      'FollowRelationsPage open userId=${widget.userId} '
      'initialTab=${widget.initialTab.name} index=$initialIndex',
      tag: 'FollowList',
    );
  }

  void _onTabControllerTick() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (_loadedTabs.add(index)) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerTick);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final userId = ref.watch(authControllerProvider.select((s) => s.userId));
    final isLoggedIn = ref.watch(
      authControllerProvider.select((s) => s.isLoggedIn),
    );
    final isSelf =
        userId != null && userId == widget.userId && isLoggedIn;

    // PRD: follow lists are self-only (align web — no guest dialog).
    if (!isSelf) {
      return AppScaffold(
        title: '',
        titleWidget: const SizedBox.shrink(),
        backgroundColor: StoryColors.appBarBackgroundOf(theme.brightness),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(StorySpacing.xl),
            child: Text(
              l10n.followRelationsSelfOnly,
              textAlign: TextAlign.center,
              style: StoryTextStyles.bodyMedium(
                color: StoryColors.mutedForegroundOf(theme.brightness),
              ),
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: '',
      titleWidget: StoryTabBar(
        controller: _tabController,
        isScrollable: true,
        showDivider: false,
        tabs: [
          Tab(text: l10n.publicProfileFollowing),
          Tab(text: l10n.publicProfileFollowers),
          Tab(text: l10n.followTabMutual),
        ],
      ),
      backgroundColor: StoryColors.appBarBackgroundOf(theme.brightness),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            _FollowListTab(
              // Key by type so TabBarView never reuses the wrong list state.
              key: ValueKey(_tabs[i]),
              param: FollowListParam(userId: widget.userId, type: _tabs[i]),
              isActive: _loadedTabs.contains(i),
            ),
        ],
      ),
    );
  }
}

class _FollowListTab extends ConsumerStatefulWidget {
  final FollowListParam param;
  final bool isActive;

  const _FollowListTab({
    super.key,
    required this.param,
    required this.isActive,
  });

  @override
  ConsumerState<_FollowListTab> createState() => _FollowListTabState();
}

class _FollowListTabState extends ConsumerState<_FollowListTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isSelf {
    final currentUserId = ref.read(authControllerProvider).userId;
    return currentUserId != null && currentUserId == widget.param.userId;
  }

  void _onScroll() {
    final state = ref.read(followListControllerProvider(widget.param));
    if (state.isLoading || state.isPageLoading || state.items.isEmpty) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            StorySpacing.scrollThreshold) {
      ref.read(followListControllerProvider(widget.param).notifier).loadMore();
    }
  }

  Future<void> _onRelationTap(FollowListItem item) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn) {
      await context.storyPush(RouteNames.login);
      return;
    }
    if (item.userId.isEmpty || item.userId == auth.userId) return;

    final ownerUserId = widget.param.userId;
    final action = ref.read(followActionControllerProvider.notifier);
    final status = item.relationStatus;

    if (status == FollowRelationStatus.following ||
        status == FollowRelationStatus.mutual) {
      final confirmed = await UnfollowConfirmDialog.show(
        context,
        displayName: item.nickname,
      );
      if (confirmed != true || !mounted) return;

      final previous = status;
      final next = FollowRelationActions.nextAfterUnfollow(status);
      FollowRelationActions.applyUnfollowOptimistic(
        ref,
        ownerUserId: ownerUserId,
        targetUserId: item.userId,
        next: next,
      );
      final result = await action.unfollow(item.userId);
      if (!mounted) return;
      if (result.isFailure) {
        FollowRelationActions.patchAll(
          ref,
          ownerUserId: ownerUserId,
          targetUserId: item.userId,
          status: previous,
        );
        // Mutuals may have been removed optimistically; reload to restore.
        ref.invalidate(
          followListControllerProvider(
            FollowListParam(userId: ownerUserId, type: FollowListType.mutuals),
          ),
        );
        final err = result.errorOrNull;
        if (err != null) {
          StoryToast.error(context, context.l10nError(err));
        }
        return;
      }
      FollowRelationActions.invalidateStats(ref, ownerUserId);
      return;
    }

    final previous = status;
    final next = FollowRelationActions.nextAfterFollow(status);
    FollowRelationActions.patchAll(
      ref,
      ownerUserId: ownerUserId,
      targetUserId: item.userId,
      status: next,
    );
    final result = await action.follow(item.userId);
    if (!mounted) return;
    if (result.isFailure) {
      FollowRelationActions.patchAll(
        ref,
        ownerUserId: ownerUserId,
        targetUserId: item.userId,
        status: previous,
      );
      final err = result.errorOrNull;
      if (err != null) {
        StoryToast.error(context, context.l10nError(err));
      }
      return;
    }
    FollowRelationActions.invalidateStats(ref, ownerUserId);
  }

  Future<void> _onRemoveFollower(FollowListItem item) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn) {
      await context.storyPush(RouteNames.login);
      return;
    }
    if (item.userId.isEmpty || item.userId == auth.userId) return;

    final confirmed = await FollowUserMoreSheet.show(context);
    if (confirmed != true || !mounted) return;

    final ownerUserId = widget.param.userId;
    final action = ref.read(followActionControllerProvider.notifier);
    FollowRelationActions.applyRemoveFollowerOptimistic(
      ref,
      ownerUserId: ownerUserId,
      followerId: item.userId,
    );
    final result = await action.removeFollower(item.userId);
    if (!mounted) return;
    if (result.isFailure) {
      // Restore both lists — optimistic remove also dropped mutuals rows.
      ref.invalidate(
        followListControllerProvider(
          FollowListParam(userId: ownerUserId, type: FollowListType.followers),
        ),
      );
      ref.invalidate(
        followListControllerProvider(
          FollowListParam(userId: ownerUserId, type: FollowListType.mutuals),
        ),
      );
      final err = result.errorOrNull;
      if (err != null) {
        StoryToast.error(context, context.l10nError(err));
      }
      return;
    }
    FollowRelationActions.invalidateStats(ref, ownerUserId);
    StoryToast.success(context, context.l10n.followRemoveFollowerSuccess);
  }

  void _openProfile(String userId) {
    if (userId.isEmpty) return;
    context.storyPush(RouteNames.publicProfile, arguments: {'userId': userId});
  }

  void _onExplore() {
    ref.read(tabIndexProvider.notifier).setIndex(StoryTab.theater.index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onPublish() {
    context.storyPush(RouteNames.createDrama);
  }

  Widget _emptyForType(AppLocalizations l10n) {
    final isSelf = _isSelf;
    return switch (widget.param.type) {
      FollowListType.following => FollowRelationEmpty(
        message: isSelf
            ? l10n.followFollowingEmpty
            : l10n.followFollowingEmptyGuest,
        ctaLabel: isSelf ? l10n.followFollowingEmptyCta : null,
        onCta: isSelf ? _onExplore : null,
      ),
      FollowListType.followers => FollowRelationEmpty(
        message: isSelf
            ? l10n.followFollowersEmpty
            : l10n.followFollowersEmptyGuest,
        ctaLabel: isSelf ? l10n.followFollowersEmptyCta : null,
        onCta: isSelf ? _onPublish : null,
      ),
      FollowListType.mutuals => FollowRelationEmpty(
        message: l10n.followMutualsEmpty,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // TabBarView requires non-zero child extent. Returning [SizedBox.shrink]
    // for inactive tabs breaks initialIndex != 0 (e.g. opening 粉丝) and can
    // leave the viewport on 关注 while the tab bar shows 粉丝.
    if (!widget.isActive) {
      return const SizedBox.expand();
    }

    final l10n = context.l10n;

    final state = ref.watch(followListControllerProvider(widget.param));
    final pending = ref.watch(
      followActionControllerProvider.select((s) => s.pendingUserIds),
    );
    final currentUserId = ref.watch(
      authControllerProvider.select((a) => a.userId),
    );

    final showInitialLoading =
        (!state.hasFetched || state.isLoading) && state.items.isEmpty;
    final showError =
        state.hasFetched &&
        !state.isLoading &&
        state.items.isEmpty &&
        state.lastError != null;
    final showEmpty =
        state.hasFetched &&
        !state.isLoading &&
        state.items.isEmpty &&
        state.lastError == null;

    return RefreshIndicator(
      color: StoryColors.brandTeal,
      onRefresh: () => ref
          .read(followListControllerProvider(widget.param).notifier)
          .refresh(),
      child: showInitialLoading
          ? const StoryLoading.centered()
          : showError
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 280,
                  child: Center(
                    child: StoryStateWidget.error(
                      message: state.errorMessage.isNotEmpty
                          ? state.errorMessage
                          : l10n.commonLoadFailed,
                      actionLabel: l10n.dramaDetailRetry,
                      onAction: () => ref
                          .read(
                            followListControllerProvider(widget.param).notifier,
                          )
                          .refresh(),
                    ),
                  ),
                ),
              ],
            )
          : showEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: _emptyForType(l10n),
                ),
              ],
            )
          : ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                StorySpacing.xl,
                StorySpacing.xl,
                StorySpacing.xl,
                StorySpacing.xxl,
              ),
              itemCount: state.items.length + (state.isPageLoading ? 1 : 0),
              separatorBuilder: (_, _) =>
                  const SizedBox(height: StorySpacing.xl),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: StorySpacing.base),
                    child: Center(child: StoryLoading.inline()),
                  );
                }
                final item = state.items[index];
                final isOwnRow = item.userId == currentUserId;
                // Guest (viewing another user's lists): no relation / more actions.
                // Mutuals (Figma 358:93249 / 358:89948): identity-only rows, no CTA.
                final hideActions = !_isSelf;
                final isMutuals = widget.param.type == FollowListType.mutuals;
                return FollowUserTile(
                  item: item,
                  actionLoading: pending.contains(item.userId),
                  hideRelationButton: hideActions || isOwnRow || isMutuals,
                  showMoreButton:
                      !hideActions &&
                      widget.param.type == FollowListType.followers &&
                      !isOwnRow,
                  onOpenProfile: () => _openProfile(item.userId),
                  onRelationTap: () => _onRelationTap(item),
                  onMoreTap: () => _onRemoveFollower(item),
                );
              },
            ),
    );
  }
}
