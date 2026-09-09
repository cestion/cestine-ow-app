import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/components.dart';
import '../controller/theater_filter_controller.dart';
import '../core/episode_play_handoff.dart';
import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../foundation/router.dart';
import '../provider/app_providers.dart';
import '../provider/tab_index_provider.dart';
import '../provider/theater_home_tab_provider.dart';
import '../routes/video_feed_playlist_entry_seeds.dart';
import '../routes/video_feed_navigation.dart';
import '../services/playback_entry_warmup.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../widgets/widgets.dart';
import 'widgets/recommend/recommend_feed_body.dart';

class TheaterPage extends ConsumerStatefulWidget {
  const TheaterPage({super.key});

  @override
  ConsumerState<TheaterPage> createState() => _TheaterPageState();
}

class _TheaterPageState extends ConsumerState<TheaterPage> {
  final ScrollController _scrollController = ScrollController();

  /// Solid app-bar fill once the short-drama list has pinned under chrome.
  bool _chromeSolid = false;

  /// Short-drama subtree (banner + list refresh) stays unmounted until the
  /// user opens that home tab. Default landing is Recommend — mounting both
  /// trees on cold start races the feed for network/CPU.
  bool _shortDramaMounted = false;

  /// True from the first short-drama paint until [ensureLoaded] is kicked,
  /// so the body shows a skeleton instead of an empty-state flash.
  bool _shortDramaAwaitingLoad = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncChromeBackground);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncChromeBackground);
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureShortDramaMounted() {
    if (_shortDramaMounted) return;
    setState(() {
      _shortDramaMounted = true;
      _shortDramaAwaitingLoad = true;
    });
    unawaited(() async {
      try {
        await ref.read(theaterControllerProvider.notifier).ensureLoaded();
      } finally {
        if (mounted && _shortDramaAwaitingLoad) {
          setState(() => _shortDramaAwaitingLoad = false);
        }
      }
    }());
  }

  void _syncChromeBackground() {
    if (!mounted || !_scrollController.hasClients) return;
    if (!_shortDramaMounted &&
        ref.read(theaterHomeTabProvider) == TheaterHomeTab.recommend) {
      return;
    }
    final hasBanner = (ref.read(theaterBannerProvider).value ?? []).isNotEmpty;
    var solid = false;
    if (hasBanner) {
      final chromeH = TheaterHomeChrome.heightOf(context);
      final bannerH =
          TheaterHeroBanner.contentHeight +
          MediaQuery.paddingOf(context).top +
          TheaterHeroBanner.bottomGap;
      final pinAfter = (bannerH - chromeH).clamp(0.0, double.infinity);
      solid = _scrollController.offset >= pinAfter;
    }
    if (solid != _chromeSolid) {
      setState(() => _chromeSolid = solid);
    }
  }

  void _scrollShortDramaToTop() {
    if (!_scrollController.hasClients) return;
    unawaited(
      _scrollController.animateTo(
        0,
        duration: StoryDurations.animationFast,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(theaterScrollToTopProvider, (previous, next) {
      if (previous == next) return;
      _scrollShortDramaToTop();
    });
    // Tag / sort change: jump to the top of the short-drama list so page 1
    // is visible while [TheaterController.reloadWithFilter] replaces items.
    ref.listen(theaterFilterControllerProvider, (previous, next) {
      if (previous == null) return;
      if (previous.selectedTagId == next.selectedTagId &&
          previous.sort == next.sort) {
        return;
      }
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
    final homeTab = ref.watch(theaterHomeTabProvider);
    final isRecommend = homeTab == TheaterHomeTab.recommend;
    // Show the short-drama tree as soon as that tab is selected (avoids an
    // empty IndexedStack frame), then persist [_shortDramaMounted] so it
    // stays warm under Recommend afterward.
    final showShortDrama = _shortDramaMounted || !isRecommend;
    if (showShortDrama && !_shortDramaMounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _shortDramaMounted) return;
        _ensureShortDramaMounted();
      });
    }

    // Banner / list providers only subscribe once the short-drama tree mounts.
    final hasBanner = showShortDrama
        ? (ref.watch(theaterBannerProvider).value ?? []).isNotEmpty
        : false;
    if (showShortDrama) {
      ref.listen(theaterBannerProvider, (_, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncChromeBackground();
        });
      });
    }
    final controllerSkeleton = showShortDrama
        ? ref.watch(
            theaterControllerProvider.select(
              (c) => c.isLoading && c.items.isEmpty,
            ),
          )
        : false;
    // Cover the pre-ensureLoaded frame(s) before the controller flips isLoading.
    final showDramaSkeleton =
        controllerSkeleton ||
        (showShortDrama && (!_shortDramaMounted || _shortDramaAwaitingLoad));

    return IndexedStack(
      index: isRecommend ? 1 : 0,
      sizing: StackFit.expand,
      children: [
        showShortDrama
            ? Scaffold(
                backgroundColor: StoryColors.backgroundOf(
                  Theme.of(context).brightness,
                ),
                resizeToAvoidBottomInset: false,
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    _TheaterBody(
                      scrollController: _scrollController,
                      forceInitialSkeleton: showDramaSkeleton,
                    ),
                    TheaterHomeChrome(
                      overlay:
                          (hasBanner || showDramaSkeleton) && !_chromeSolid,
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
        Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: false,
          body: Stack(
            fit: StackFit.expand,
            children: [
              RecommendFeedBody(isActive: isRecommend),
              const TheaterHomeChrome(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Search pill in the theater app bar.
class _TheaterBody extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  /// Parent is still bootstrapping the first short-drama load.
  final bool forceInitialSkeleton;

  const _TheaterBody({
    required this.scrollController,
    this.forceInitialSkeleton = false,
  });

  @override
  ConsumerState<_TheaterBody> createState() => _TheaterBodyState();
}

class _TheaterBodyState extends ConsumerState<_TheaterBody> with RouteAware {
  bool _isRouteVisible = true;
  PageRoute<dynamic>? _subscribedRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is! PageRoute) return;
    if (_subscribedRoute == route) return;
    if (_subscribedRoute != null) {
      StoryRouter.observer.unsubscribe(this);
    }
    _subscribedRoute = route;
    StoryRouter.observer.subscribe(this, route);
  }

  @override
  void dispose() {
    if (_subscribedRoute != null) {
      StoryRouter.observer.unsubscribe(this);
      _subscribedRoute = null;
    }
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didPushNext() {
    if (_isRouteVisible) {
      setState(() => _isRouteVisible = false);
    }
  }

  @override
  void didPopNext() {
    if (!_isRouteVisible) {
      setState(() => _isRouteVisible = true);
    }
  }

  @override
  void didPush() {
    _isRouteVisible = true;
  }

  @override
  void didPop() {
    _isRouteVisible = false;
  }

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  /// Full-page refresh: banner + global config + tags + drama list.
  /// Shared by pull-to-refresh and the empty-state retry button.
  Future<void> _refreshAll() async {
    await ref.read(configRepositoryProvider).invalidateCache();
    await ref.read(tagRepositoryProvider).invalidateCache();
    // theaterBannerProvider depends on globalConfigProvider — invalidating
    // globalConfigProvider is enough; no need to invalidate banner separately.
    ref.invalidate(globalConfigProvider);
    ref.invalidate(dramaTagsProvider);
    await ref.read(theaterControllerProvider.notifier).refresh();
  }

  void _onScroll() {
    final state = ref.read(theaterControllerProvider);
    if (state.isLoading || state.isPageLoading || state.items.isEmpty) return;

    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent -
            StorySpacing.scrollThreshold) {
      ref.read(theaterControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      theaterControllerProvider.select((c) => c.isLoading),
    );
    final items = ref.watch(theaterControllerProvider.select((c) => c.items));
    final hasMore = ref.watch(
      theaterControllerProvider.select((c) => c.hasMore),
    );
    final isTheaterTabActive = ref.watch(
      tabIndexProvider.select((index) => index == 0),
    );
    final isShortDramaHome = ref.watch(
      theaterHomeTabProvider.select((t) => t == TheaterHomeTab.shortDrama),
    );
    final isDrawerOpen = ref.watch(mainShellDrawerOpenProvider);
    final isRouteCovered = ref.watch(mainShellRouteCoveredProvider);
    // ModalRoute.isCurrent / RouteAware can lag one frame; navigator canPop
    // (ShellCoverageObserver) is the authoritative cover signal for Android
    // banner SurfaceView teardown under Login / feed / detail.
    final routeIsCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    // IndexedStack keeps Short Drama mounted under Recommend — pause the
    // banner so its native player does not contend with the recommend feed.
    final isBannerVisible =
        isTheaterTabActive &&
        isShortDramaHome &&
        _isRouteVisible &&
        routeIsCurrent &&
        !isRouteCovered &&
        !isDrawerOpen;
    final displayItems = ref.watch(filteredTheaterItemsProvider);
    final bannerAsync = ref.watch(theaterBannerProvider);
    final bannerItems = bannerAsync.value ?? [];
    final hasBanner = bannerItems.isNotEmpty;
    final l10n = context.l10n;
    final showInitialSkeleton =
        widget.forceInitialSkeleton || (isLoading && items.isEmpty);
    final showEmpty = !showInitialSkeleton && !isLoading && items.isEmpty;
    final chromeHeight = TheaterHomeChrome.heightOf(context);
    final bannerHeight = hasBanner
        ? TheaterHeroBanner.contentHeight +
              MediaQuery.paddingOf(context).top +
              TheaterHeroBanner.bottomGap
        : 0.0;
    final background = StoryColors.backgroundOf(Theme.of(context).brightness);

    return RefreshIndicator(
      color: StoryColors.brandTeal,
      onRefresh: _refreshAll,
      child: CustomScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (showInitialSkeleton)
            const SliverToBoxAdapter(child: StoryTheaterPageSkeleton())
          else ...[
            SliverPersistentHeader(
              pinned: true,
              delegate: _TheaterStickyHeaderDelegate(
                overlayHeight: chromeHeight,
                bannerHeight: bannerHeight,
                filterHeight: _theaterStickyFilterHeight,
                background: background,
                banner: hasBanner
                    ? TheaterHeroBanner(
                        items: bannerItems,
                        dramaItems: items,
                        isPageVisible: isBannerVisible,
                        onBannerTap: (banner, cachedDetail) =>
                            _openBanner(context, banner, cachedDetail),
                      )
                    : null,
                filter: const _TheaterStickyFilterBar(),
              ),
            ),
            if (showEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: StoryStateWidget.empty(
                  message: l10n.dramaEmpty,
                  actionLabel: l10n.dramaRefresh,
                  onAction: _refreshAll,
                ),
              )
            else if (displayItems.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: StorySpacing.xxl),
                    child: Text(
                      l10n.dramaEmpty,
                      style: StoryTextStyles.bodySmall(),
                    ),
                  ),
                ),
              )
            else
              _buildGrid(displayItems, hasMore),
          ],
        ],
      ),
    );
  }

  Future<void> _openBanner(
    BuildContext context,
    BannerItem banner,
    DramaDetail? cachedDetail,
  ) async {
    final dramaId = banner.dramaId;
    if (dramaId == null || dramaId.isEmpty) return;
    final totalEpisodes =
        cachedDetail?.totalEpisodes ?? banner.totalEpisodes ?? 1;
    final episodeNo = resumeEpisodeForDrama(
      ref,
      dramaId,
      totalEpisodes: totalEpisodes,
    );
    ref
        .read(theaterControllerProvider.notifier)
        .prefetchEpisode(dramaId, episodeNo);

    var warmStart = false;
    DramaPlayResponse? cachedPlay;
    try {
      cachedPlay = await ref
          .read(dramaRepositoryProvider)
          .peekPrefetchedEpisode(dramaId, episodeNo);
      if (cachedPlay != null) {
        PlaybackEntryWarmup.primeFrameCacheAround(
          dramaId: dramaId,
          episodeNo: episodeNo,
          episodeIdsByNo: {
            if (cachedPlay.episodeId != null) episodeNo: cachedPlay.episodeId,
          },
        );
        EpisodePlayHandoff.offer(
          dramaId: dramaId,
          episodeNo: episodeNo,
          play: cachedPlay,
          diskWarmed: PlaybackEntryWarmup.isPlayUrlDiskWarmed(
            cachedPlay.effectivePlayUrl,
          ),
        );
        warmStart = true;
      }
    } catch (e) {
      StoryLogger.d(
        'Peek prefetched episode for warm start failed',
        error: e,
        tag: 'Theater',
      );
    }

    final chrome =
        (cachedDetail != null
                ? VideoFeedPlaylistEntrySeeds.fromDramaDetail(
                    cachedDetail,
                    dramaId: dramaId,
                  )
                : VideoFeedPlaylistEntrySeeds.chrome())
            .mergePlay(cachedPlay);

    if (!context.mounted) return;
    await VideoFeedNavigation.open(
      context,
      dramaId: dramaId,
      episodeNo: episodeNo,
      title: cachedDetail?.title ?? banner.title ?? '',
      totalEpisodes: totalEpisodes,
      coverUrl: cachedDetail?.coverUrl ?? banner.thumbUrl ?? banner.bannerUrl,
      description: cachedDetail?.description ?? banner.description,
      warmStart: warmStart,
      chrome: chrome,
    );
  }

  Widget _buildGrid(List<DramaListItem> displayItems, bool hasMore) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: StorySpacing.sm),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          // Cover 3:4 + title/meta ≈ 0.60; lower values leave empty gaps between rows.
          childAspectRatio: 0.60,
          crossAxisSpacing: StorySpacing.sm,
          mainAxisSpacing: StorySpacing.xs,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              _buildDramaItem(context, displayItems, index, hasMore),
          childCount: displayItems.length + (hasMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildDramaItem(
    BuildContext context,
    List<DramaListItem> displayItems,
    int index,
    bool hasMore,
  ) {
    if (index >= displayItems.length) {
      return const Center(child: StoryLoading.inline());
    }
    final drama = displayItems[index];
    return RepaintBoundary(
      child: Align(
        alignment: Alignment.topCenter,
        child: DramaCard(
          key: ValueKey(drama.id),
          vm: DramaCardVmMapper.fromTheaterList(drama, l10n: context.l10n),
          isGrid: true,
          onTap: () => _openPlayerFromList(drama),
        ),
      ),
    );
  }

  /// Open the feed player for a list item (same warm-start path as banner).
  Future<void> _openPlayerFromList(DramaListItem drama) async {
    final dramaId = drama.id;
    if (dramaId.isEmpty) return;

    final totalEpisodes = drama.totalEpisodes ?? 1;
    final episodeNo = resumeEpisodeForDrama(
      ref,
      dramaId,
      totalEpisodes: totalEpisodes,
    );

    ref
        .read(theaterControllerProvider.notifier)
        .prefetchEpisode(dramaId, episodeNo);

    var warmStart = false;
    DramaPlayResponse? cachedPlay;
    try {
      cachedPlay = await ref
          .read(dramaRepositoryProvider)
          .peekPrefetchedEpisode(dramaId, episodeNo);
      if (cachedPlay != null) {
        PlaybackEntryWarmup.primeFrameCacheAround(
          dramaId: dramaId,
          episodeNo: episodeNo,
          episodeIdsByNo: {
            if (cachedPlay.episodeId != null) episodeNo: cachedPlay.episodeId,
          },
        );
        EpisodePlayHandoff.offer(
          dramaId: dramaId,
          episodeNo: episodeNo,
          play: cachedPlay,
          diskWarmed: PlaybackEntryWarmup.isPlayUrlDiskWarmed(
            cachedPlay.effectivePlayUrl,
          ),
        );
        warmStart = true;
      }
    } catch (e) {
      StoryLogger.d(
        'Peek prefetched episode for list warm start failed',
        error: e,
        tag: 'Theater',
      );
    }

    final chrome = VideoFeedPlaylistEntrySeeds.fromDramaListItem(
      drama,
      dramaId: dramaId,
    ).mergePlay(cachedPlay);

    if (!mounted) return;
    await VideoFeedNavigation.open(
      context,
      dramaId: dramaId,
      episodeNo: episodeNo,
      title: drama.dramaTitle ?? '',
      totalEpisodes: totalEpisodes,
      coverUrl: drama.dramaCoverUrl,
      description: drama.dramaDescription,
      warmStart: warmStart,
      chrome: chrome,
    );
  }
}

/// Category (36) + gap to sort (2) + sort line (16) + gap to cards (10).
const double _theaterTagsToSortGap = 2;
const double _theaterSortToCardsGap = 10;
const double _theaterStickyFilterHeight =
    36 + _theaterTagsToSortGap + 16 + _theaterSortToCardsGap;

class _TheaterStickyFilterBar extends ConsumerWidget {
  const _TheaterStickyFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTagId = ref.watch(
      theaterFilterControllerProvider.select((s) => s.selectedTagId),
    );
    final sort = ref.watch(
      theaterFilterControllerProvider.select((s) => s.sort),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StorySpacing.screenHorizontal,
        0,
        StorySpacing.screenHorizontal,
        _theaterSortToCardsGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TheaterCategoryTabs(
            selectedTagId: selectedTagId,
            onSelected: (tagId) {
              final tags = ref.read(dramaTagsProvider).value ?? [];
              final selectedTag = tags.firstWhere(
                (t) => t.id == tagId,
                orElse: () => const DramaTag(),
              );
              ref
                  .read(theaterFilterControllerProvider.notifier)
                  .setTag(tagId: tagId, tagName: selectedTag.name);
            },
          ),
          const SizedBox(height: _theaterTagsToSortGap),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TheaterSortLayoutBar(
                selectedSort: sort,
                onSortChanged: (sort) => ref
                    .read(theaterFilterControllerProvider.notifier)
                    .setSort(sort),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapses the banner under the overlay chrome and pins tags + sort below it.
class _TheaterStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TheaterStickyHeaderDelegate({
    required this.overlayHeight,
    required this.bannerHeight,
    required this.filterHeight,
    required this.background,
    required this.filter,
    this.banner,
  });

  final double overlayHeight;
  final double bannerHeight;
  final double filterHeight;
  final Color background;
  final Widget filter;
  final Widget? banner;

  bool get _hasBanner => banner != null && bannerHeight > 0;

  @override
  double get maxExtent =>
      (_hasBanner ? bannerHeight : overlayHeight) + filterHeight;

  @override
  double get minExtent => overlayHeight + filterHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Bounce / remaining-paint can push shrinkOffset past max-min. Never
    // size children from raw (maxExtent - shrinkOffset) — that went to
    // BoxConstraints(h=-68) and blew up semantics with the banner player.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final height = maxH.isFinite && maxH >= 0
            ? maxH
            : (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
        final filterH = filterHeight.clamp(0.0, height);
        final bannerSlot = (height - filterH).clamp(0.0, height);

        return SizedBox(
          height: height,
          child: Column(
            children: [
              if (bannerSlot > 0)
                SizedBox(
                  height: bannerSlot,
                  child: _hasBanner
                      ? ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: bannerHeight <= 0
                                ? 0
                                : (bannerSlot / bannerHeight).clamp(0.0, 1.0),
                            child: SizedBox(
                              height: bannerHeight,
                              child: banner,
                            ),
                          ),
                        )
                      : const SizedBox.expand(),
                ),
              if (filterH > 0)
                ColoredBox(
                  color: background,
                  child: SizedBox(height: filterH, child: filter),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(covariant _TheaterStickyHeaderDelegate oldDelegate) {
    return overlayHeight != oldDelegate.overlayHeight ||
        bannerHeight != oldDelegate.bannerHeight ||
        filterHeight != oldDelegate.filterHeight ||
        background != oldDelegate.background ||
        _hasBanner != oldDelegate._hasBanner ||
        banner != oldDelegate.banner ||
        filter != oldDelegate.filter;
  }
}
