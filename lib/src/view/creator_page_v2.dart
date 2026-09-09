import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/common/publish_content_sheet.dart';
import '../controller/drama_management_state.dart';
import '../core/story_sdk.dart';
import '../foundation/story_launcher.dart';
import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../routes/route_names.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../widgets/widgets.dart';
import 'widgets/creator/creator_drama_tab_v2.dart';
import 'widgets/creator/creator_video_tab_v2.dart';
import '../foundation/navigator.dart';

/// Figma `781:139560` 对应的创作管理 V2 页面。
///
/// 顶部主页签固定在滚动区域上方；短剧与视频页签分别使用独立的服务端筛选与分页。
class CreatorPageV2 extends ConsumerStatefulWidget {
  final bool showBack;
  final int initialTabIndex;

  const CreatorPageV2({
    super.key,
    this.showBack = true,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<CreatorPageV2> createState() => CreatorPageV2State();
}

class CreatorPageV2State extends ConsumerState<CreatorPageV2>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
      vsync: this,
    );
    _tabController.addListener(_handlePrimaryTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authControllerProvider).isLoggedIn) {
        unawaited(_refreshDramas());
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handlePrimaryTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handlePrimaryTabChanged() {
    if (!_tabController.indexIsChanging && mounted) setState(() {});
  }

  Future<void> _refreshDramas() async {
    await Future.wait([
      ref.read(creatorManagementOverviewControllerProvider.notifier).refresh(),
      ref.read(creatorDramaManagementControllerProvider.notifier).refresh(),
    ]);
  }

  /// Publishing changes all three creator-management data sources. Reconcile
  /// each one directly from the network without surfacing a loading state.
  Future<void> _reconcilePublishedContent() async {
    await Future.wait([
      ref
          .read(creatorManagementOverviewControllerProvider.notifier)
          .silentRefresh(),
      ref
          .read(creatorDramaManagementControllerProvider.notifier)
          .silentRefresh(),
      ref
          .read(creatorVideoManagementControllerProvider.notifier)
          .silentRefresh(),
    ]);
  }

  Future<void> openCreateContent() async {
    final action = await PublishContentSheet.show(
      context,
      actions: const [PublishContentAction.drama, PublishContentAction.video],
    );
    if (!mounted || action == null) return;

    final route = switch (action) {
      PublishContentAction.drama => RouteNames.createDrama,
      PublishContentAction.video => RouteNames.publishVideo,
      PublishContentAction.actorIp => RouteNames.createActor,
    };
    final created = await context.storyPushForResult<Object?>(route);
    if (!mounted || created == null) return;
    unawaited(_reconcilePublishedContent());
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final pageBackground = StoryColors.backgroundOf(brightness);
    final headerBackground = StoryColors.cardOf(brightness);
    final contentCounts = ref.watch(
      creatorManagementOverviewControllerProvider.select(
        (state) => (state.dramaCount, state.videoCount),
      ),
    );
    final isLoggedIn = ref.watch(
      authControllerProvider.select(
        (state) => state.isLoggedIn && !state.isLogging,
      ),
    );

    return AppScaffold(
      title: '',
      showBack: widget.showBack,
      toolbarHeight: 44,
      backgroundColor: headerBackground,
      leading: widget.showBack
          ? IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              icon: const SizedBox.square(
                key: ValueKey<String>('creator-v2-back-asset-box'),
                dimension: 24,
                child: Center(child: Icon(Icons.arrow_back_ios_new, size: 16)),
              ),
            )
          : null,
      actions: [
        TextButton(
          onPressed: () => StoryLauncher.openExternal(
            StorySdk.instance.config.env.dreamOsUrl,
          ),
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            backgroundColor: StoryColors.foregroundOf(brightness),
            foregroundColor: StoryColors.backgroundOf(brightness),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          child: Text(
            context.l10n.creatorCreateDrama,
            style: const TextStyle(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox.square(
          key: const ValueKey<String>('creator-v2-add-button'),
          dimension: 32,
          child: IconButton(
            tooltip: _tabController.index == 0
                ? context.l10n.creatorPublishNewDrama
                : context.l10n.publishVideo,
            onPressed: openCreateContent,
            padding: const EdgeInsets.all(8),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFE50815),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
          ),
        ),
        const SizedBox(width: 16),
      ],
      body: isLoggedIn
          ? ColoredBox(
              color: pageBackground,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: headerBackground,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.drawerCreatorManagement,
                            style: TextStyle(
                              color: StoryColors.foregroundOf(brightness),
                              fontSize: 24,
                              height: 30 / 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.creatorV2Subtitle,
                            style: TextStyle(
                              color: StoryColors.mutedForegroundOf(brightness),
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CreatorPrimaryTabsHeader(
                      controller: _tabController,
                      backgroundColor: pageBackground,
                      foregroundColor: StoryColors.foregroundOf(brightness),
                      mutedColor: StoryColors.mutedForegroundOf(brightness),
                      dramaTabLabel: context.l10n.creatorV2DramaTabCount(
                        contentCounts.$1,
                      ),
                      videoTabLabel: context.l10n.creatorV2VideoTabCount(
                        contentCounts.$2,
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    CreatorDramaTabV2(onCreateContent: openCreateContent),
                    CreatorVideoTabV2(onCreateContent: openCreateContent),
                  ],
                ),
              ),
            )
          : ColoredBox(
              color: pageBackground,
              child: ListView(
                padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
                children: [
                  StoryEmptyCard(label: context.l10n.creatorLoginPrompt),
                ],
              ),
            ),
    );
  }
}

class _CreatorPrimaryTabsHeader extends SliverPersistentHeaderDelegate {
  final TabController controller;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color mutedColor;
  final String dramaTabLabel;
  final String videoTabLabel;

  const _CreatorPrimaryTabsHeader({
    required this.controller,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.mutedColor,
    required this.dramaTabLabel,
    required this.videoTabLabel,
  });

  @override
  double get minExtent => 46;

  @override
  double get maxExtent => 46;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: TabBar(
            controller: controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.only(right: 20),
            labelColor: foregroundColor,
            unselectedLabelColor: mutedColor,
            labelStyle: const TextStyle(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w400,
            ),
            dividerHeight: 0,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            indicator: StoryTabIndicator(
              color: foregroundColor,
              width: 16,
              borderRadius: 17,
            ),
            tabs: [
              Tab(height: 36, text: dramaTabLabel),
              Tab(height: 36, text: videoTabLabel),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CreatorPrimaryTabsHeader oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.dramaTabLabel != dramaTabLabel ||
        oldDelegate.videoTabLabel != videoTabLabel ||
        oldDelegate.controller != controller;
  }
}

class CreatorStatusFilters extends StatelessWidget {
  final DramaManagementStatus selectedStatus;
  final ValueChanged<DramaManagementStatus> onSelected;

  const CreatorStatusFilters({
    super.key,
    required this.selectedStatus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = <DramaManagementStatus, String>{
      DramaManagementStatus.all: l10n.creatorReviewFilterAll,
      DramaManagementStatus.online: l10n.creatorReviewFilterApproved,
      DramaManagementStatus.pendingReview: l10n.creatorReviewFilterPending,
      DramaManagementStatus.reviewRejected: l10n.creatorReviewFilterRejected,
      DramaManagementStatus.offline: l10n.creatorReviewFilterOffline,
    };

    return Padding(
      padding: const EdgeInsets.only(top: StorySpacing.sm),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          itemCount: DramaManagementStatus.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final status = DramaManagementStatus.values[index];
            final selected = status == selectedStatus;
            return _CreatorFilterChip(
              key: ValueKey<String>('creator-v2-filter-${status.name}'),
              label: labels[status]!,
              selected: selected,
              onTap: () => onSelected(status),
            );
          },
        ),
      ),
    );
  }
}

class _CreatorFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CreatorFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final selectedBackground = brightness == Brightness.light
        ? StoryColors.darkButtonBg
        : StoryColors.foregroundOf(brightness);
    return Material(
      color: selected
          ? selectedBackground
          : StoryColors.actorHeroBadgeBgOf(brightness),
      borderRadius: const BorderRadius.all(Radius.circular(80)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(80)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? StoryColors.backgroundOf(brightness)
                  : StoryColors.foregroundOf(brightness),
              fontSize: 14,
              height: 20 / 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
