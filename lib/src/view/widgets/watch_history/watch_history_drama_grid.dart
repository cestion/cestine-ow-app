import 'dart:async';

import 'package:flutter/material.dart';

import '../../../controller/watch_history_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../widgets/widgets.dart';
import 'watch_history_drama_card.dart';

class WatchHistoryDramaGrid extends StatelessWidget {
  const WatchHistoryDramaGrid({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onItemTap,
    this.pullToRefreshEnabled = true,
  });

  final WatchHistoryListState<WatchHistoryDrama> state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final ValueChanged<WatchHistoryDrama> onItemTap;
  final bool pullToRefreshEnabled;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final background = StoryColors.appBarBackgroundOf(brightness);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (viewportWidth - 32) / 3;
    final cardExtent =
        cardWidth / WatchHistoryDramaCard.coverAspectRatio +
        WatchHistoryDramaCard.infoHeight;

    final scrollable = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < StorySpacing.scrollThreshold) {
          unawaited(onLoadMore());
        }
        return false;
      },
      child: CustomScrollView(
        key: const PageStorageKey<String>('watchHistory.dramas'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: watchHistoryDramaGridSlivers(
          context,
          state: state,
          cardExtent: cardExtent,
          onRefresh: onRefresh,
          onItemTap: onItemTap,
        ),
      ),
    );

    return ColoredBox(
      color: background,
      child: pullToRefreshEnabled
          ? RefreshIndicator(
              color: StoryColors.brandTeal,
              onRefresh: onRefresh,
              child: scrollable,
            )
          : scrollable,
    );
  }
}

List<Widget> watchHistoryDramaGridSlivers(
  BuildContext context, {
  required WatchHistoryListState<WatchHistoryDrama> state,
  required double cardExtent,
  required Future<void> Function() onRefresh,
  required ValueChanged<WatchHistoryDrama> onItemTap,
}) {
  final initialLoading =
      !state.isInitialized || (state.isLoading && state.items.isEmpty);
  if (initialLoading) {
    return [
      _watchHistoryDramaGridSliver(
        cardExtent: cardExtent,
        count: 6,
        builder: (_) => const _DramaCardSkeleton(),
      ),
    ];
  }

  if (state.items.isEmpty) {
    final error = state.lastError;
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: error == null
            ? StoryStateWidget.empty(message: context.l10n.watchHistoryEmpty)
            : StoryStateWidget.error(
                message: context.l10nError(error),
                actionLabel: context.l10n.commonRetry,
                onAction: () => unawaited(onRefresh()),
              ),
      ),
    ];
  }

  return [
    _watchHistoryDramaGridSliver(
      cardExtent: cardExtent,
      count: state.items.length,
      builder: (index) {
        final item = state.items[index];
        return WatchHistoryDramaCard(item: item, onTap: () => onItemTap(item));
      },
    ),
    if (state.isPageLoading)
      const SliverPadding(
        padding: EdgeInsets.symmetric(vertical: StorySpacing.base),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    const SliverToBoxAdapter(child: SizedBox(height: StorySpacing.base)),
  ];
}

SliverPadding _watchHistoryDramaGridSliver({
  required double cardExtent,
  required int count,
  required Widget Function(int index) builder,
}) {
  return SliverPadding(
    padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
    sliver: SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: cardExtent,
      ),
      delegate: SliverChildBuilderDelegate(
        (_, index) => builder(index),
        childCount: count,
      ),
    ),
  );
}

class _DramaCardSkeleton extends StatelessWidget {
  const _DramaCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: WatchHistoryDramaCard.coverAspectRatio,
          child: StorySkeletonBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: StoryRadius.brLg,
          ),
        ),
        SizedBox(height: 8),
        StorySkeletonBox(width: double.infinity, height: 14),
        SizedBox(height: 4),
        StorySkeletonBox(width: 44, height: 12),
      ],
    );
  }
}
