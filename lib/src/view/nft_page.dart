import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/components.dart';
import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../routes/actor_detail_navigation.dart';
import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../utils/actor_data_sync.dart';
import '../widgets/widgets.dart';

class NftPage extends ConsumerStatefulWidget {
  const NftPage({super.key});

  @override
  ConsumerState<NftPage> createState() => _NftPageState();
}

class _NftPageState extends ConsumerState<NftPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nftControllerProvider.notifier).ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sort = ref.watch(nftControllerProvider.select((s) => s.sort));
    final controller = ref.read(nftControllerProvider.notifier);

    return AppScaffold(
      title: '',
      titleWidget: const SizedBox.shrink(),
      showBack: false,
      toolbarHeight: 44,
      leadingWidth: 56,
      leading: const NftPlazaNavLeading(),
      actions: const [NftPlazaNavActions()],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StorySpacing.screenHorizontal,
              StorySpacing.xs,
              StorySpacing.screenHorizontal,
              StorySpacing.xs,
            ),
            child: NftSortFilters(
              currentSort: sort,
              onSortChanged: controller.setSort,
            ),
          ),
          const Expanded(child: _NftBody()),
        ],
      ),
    );
  }
}

/// Body section with loading/empty/list states.
class _NftBody extends ConsumerStatefulWidget {
  const _NftBody();

  @override
  ConsumerState<_NftBody> createState() => _NftBodyState();
}

class _NftBodyState extends ConsumerState<_NftBody> {
  final ScrollController _scrollController = ScrollController();

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

  void _onScroll() {
    final state = ref.read(nftControllerProvider);
    if (state.pagination.isPageLoading || state.isLoading || !state.hasMore) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            StorySpacing.scrollThreshold) {
      ref.read(nftControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(
      nftControllerProvider.select((s) => s.displayItems),
    );
    final isLoading = ref.watch(
      nftControllerProvider.select((s) => s.isLoading),
    );
    final hasMore = ref.watch(nftControllerProvider.select((s) => s.hasMore));
    final l10n = context.l10n;
    final listBg = StoryColors.actorPlazaListBgOf(Theme.of(context).brightness);
    final showSkeleton = isLoading && items.isEmpty;
    final showEmpty = !isLoading && items.isEmpty;

    Future<void> onRefresh() =>
        ref.read(nftControllerProvider.notifier).refresh(force: true);

    if (showSkeleton) {
      return RefreshIndicator(
        color: StoryColors.brandTeal,
        onRefresh: onRefresh,
        child: ColoredBox(
          color: listBg,
          child: _ActorIpGridView(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: 6,
            itemBuilder: (_, _) => const _ActorIpCardSkeleton(),
          ),
        ),
      );
    }

    if (showEmpty) {
      return RefreshIndicator(
        color: StoryColors.brandTeal,
        onRefresh: onRefresh,
        child: ColoredBox(
          color: listBg,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.5,
                child: StoryStateWidget.empty(
                  message: l10n.nftEmpty,
                  actionLabel: l10n.nftRefresh,
                  onAction: onRefresh,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: StoryColors.brandTeal,
      onRefresh: onRefresh,
      child: ColoredBox(
        color: listBg,
        child: _ActorIpGridView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          footer: hasMore
              ? const Padding(
                  padding: EdgeInsets.all(StorySpacing.base),
                  child: Center(child: StoryLoading.inline()),
                )
              : null,
          itemBuilder: (context, index) {
            final actor = items[index];
            return RepaintBoundary(
              key: ValueKey(actor.id),
              child: ContentActorIpGridCard(
                actor: actor,
                onTap: () => openActorDetail(
                  context,
                  actorId: actor.id ?? '',
                  preview: actor,
                ),
                onSign: () =>
                    showActorSignFlowWithFreshDetail(context, ref, actor),
                onTrade: () =>
                    StoryToast.info(context, l10n.nftTradeUnavailable),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Dual-column actor IP grid — same metrics as search [ContentActorIpGridCard].
class _ActorIpGridView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final Widget? footer;

  const _ActorIpGridView({
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.physics,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth - StorySpacing.sm * 2;
        final aspect = ContentActorIpGridCard.gridChildAspectRatioFor(
          gridWidth,
        );
        return CustomScrollView(
          controller: controller,
          physics: physics,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(StorySpacing.sm),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ContentActorIpGridCard.gridCrossAxisCount,
                  mainAxisSpacing: ContentActorIpGridCard.gridSpacing,
                  crossAxisSpacing: ContentActorIpGridCard.gridSpacing,
                  childAspectRatio: aspect,
                ),
                delegate: SliverChildBuilderDelegate(
                  itemBuilder,
                  childCount: itemCount,
                ),
              ),
            ),
            if (footer != null) SliverToBoxAdapter(child: footer),
          ],
        );
      },
    );
  }
}

class _ActorIpCardSkeleton extends StatelessWidget {
  const _ActorIpCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cardBg = brightness == Brightness.dark
        ? StoryColors.darkCard
        : Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(color: cardBg, borderRadius: StoryRadius.brLg),
      child: ClipRRect(
        borderRadius: StoryRadius.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(
              child: StorySkeletonBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.zero,
              ),
            ),
            SizedBox(
              height: ContentActorIpGridCard.infoHeight,
              child: Padding(
                padding: const EdgeInsets.all(StorySpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StorySkeletonBox(width: double.infinity, height: 16),
                    const SizedBox(height: StorySpacing.sm),
                    const StorySkeletonBox(width: 120, height: 20),
                    const SizedBox(height: StorySpacing.sm),
                    Row(
                      children: [
                        const Expanded(
                          child: StorySkeletonBox(
                            width: double.infinity,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StorySkeletonBox(
                          width: 72,
                          height: 32,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
