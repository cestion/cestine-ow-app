import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/story_l10n.dart';
import '../../provider/app_providers.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../widgets/story_skeleton.dart';
import '../../widgets/story_tab_bar.dart';
import 'notification_list_item.dart';

/// The notification page body: a Figma-aligned header TabBar and two lists.
class NotificationTabs extends ConsumerStatefulWidget {
  const NotificationTabs({super.key, this.initialTab = 1})
    : assert(initialTab == 1 || initialTab == 2);

  final int initialTab;

  @override
  ConsumerState<NotificationTabs> createState() => _NotificationTabsState();
}

class _NotificationTabsState extends ConsumerState<NotificationTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  final Set<int> _enteredTabs = <int>{};
  final Set<int> _readTabs = <int>{};

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: 2,
      initialIndex: widget.initialTab - 1,
      vsync: this,
    );
    _controller.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _enterCurrentTab());
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_controller.indexIsChanging) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _enterCurrentTab());
  }

  Future<void> _enterCurrentTab() async {
    if (!mounted) return;
    final tab = _controller.index + 1;
    if (!_enteredTabs.add(tab)) return;

    final success = await ref
        .read(notificationControllerProvider(tab).notifier)
        .enterTab();
    if (!mounted) return;
    if (!success) {
      _enteredTabs.remove(tab);
      return;
    }
    setState(() => _readTabs.add(tab));
    ref.invalidate(notificationUnreadCountProvider);
    if (tab == 2) {
      ref.invalidate(drawerNotificationPreviewProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final unreadCount = ref.watch(notificationUnreadCountProvider).value;
    final incomeHasUnread =
        !_readTabs.contains(1) && _hasUnread(unreadCount?.incomeUnread);
    final interactionHasUnread =
        !_readTabs.contains(2) && _hasUnread(unreadCount?.interactionUnread);
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: StoryColors.dividerOf(brightness),
                width: 0.5,
              ),
            ),
          ),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: StoryTabBar(
                    controller: _controller,
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    showDivider: false,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                    indicator: StoryTabIndicator(
                      color: StoryColors.foregroundOf(brightness),
                      width: 16,
                    ),
                    tabs: [
                      _NotificationTabLabel(
                        label: context.l10n.notificationTabSystem,
                        showUnreadDot: incomeHasUnread,
                        tab: 1,
                      ),
                      _NotificationTabLabel(
                        label: context.l10n.notificationTabInteraction,
                        showUnreadDot: interactionHasUnread,
                        tab: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(
              bottom: StorySpacing.bottomNavHeight,
            ),
            child: TabBarView(
              controller: _controller,
              children: const [
                NotificationList(tab: 1),
                NotificationList(tab: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _hasUnread(String? count) => (int.tryParse(count ?? '') ?? 0) > 0;
}

class _NotificationTabLabel extends StatelessWidget {
  const _NotificationTabLabel({
    required this.label,
    required this.showUnreadDot,
    required this.tab,
  });

  final String label;
  final bool showUnreadDot;
  final int tab;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Text(label),
          if (showUnreadDot)
            Positioned(
              right: -7,
              top: -2,
              child: DecoratedBox(
                key: ValueKey<String>('notificationTab.unreadDot.$tab'),
                decoration: const BoxDecoration(
                  color: StoryColors.destructive,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 6),
              ),
            ),
        ],
      ),
    );
  }
}

/// API-backed notification list for a single backend tab.
class NotificationList extends ConsumerStatefulWidget {
  const NotificationList({super.key, required this.tab});

  final int tab;

  @override
  ConsumerState<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends ConsumerState<NotificationList>
    with AutomaticKeepAliveClientMixin<NotificationList> {
  late final ScrollController _scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter >= 200) {
      return;
    }
    ref.read(notificationControllerProvider(widget.tab).notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(notificationControllerProvider(widget.tab));
    final controller = ref.read(
      notificationControllerProvider(widget.tab).notifier,
    );

    if ((!state.hasLoaded || state.isLoading) && state.items.isEmpty) {
      return const _NotificationListSkeleton();
    }

    if (state.lastError != null && state.items.isEmpty) {
      return _NotificationError(
        message: context.l10nError(state.lastError!),
        onRetry: controller.refresh,
      );
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(StorySpacing.base),
          children: [
            const SizedBox(height: StorySpacing.xl),
            Center(
              child: Text(
                context.l10n.drawerNoNotifications,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: StoryColors.mutedForegroundOf(
                    Theme.of(context).brightness,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final showFooter = state.isLoadingMore;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: StorySpacing.base),
        itemCount: state.items.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: StorySpacing.xl),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: StorySpacing.lg),
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final item = state.items[index];
          return NotificationListItem(
            key: ValueKey(item.id ?? item.eventTime ?? item.hashCode),
            item: item,
            onDelete: () => ref
                .read(notificationControllerProvider(widget.tab).notifier)
                .deleteNotification(item),
          );
        },
      ),
    );
  }
}

class _NotificationListSkeleton extends StatelessWidget {
  const _NotificationListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(StorySpacing.base),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: StorySpacing.xl),
      itemBuilder: (_, _) => const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StorySkeletonBox(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          SizedBox(width: StorySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StorySkeletonBox(width: 96, height: 14),
                SizedBox(height: 8),
                StorySkeletonBox(width: double.infinity, height: 12),
                SizedBox(height: 8),
                StorySkeletonBox(width: 72, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: StorySpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
