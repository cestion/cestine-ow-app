import 'dart:async';

import 'package:flutter/material.dart';

import '../../../controller/watch_history_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../widgets/widgets.dart';
import 'watch_history_work_card.dart';

class WatchHistoryWorkGrid extends StatelessWidget {
  const WatchHistoryWorkGrid({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onItemTap,
    this.pullToRefreshEnabled = true,
  });

  final WatchHistoryListState<WatchHistoryVideo> state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final ValueChanged<WatchHistoryVideo> onItemTap;
  final bool pullToRefreshEnabled;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final background = StoryColors.appBarBackgroundOf(brightness);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (viewportWidth - 32) / 3;
    final cardExtent = cardWidth / WatchHistoryWorkCard.coverAspectRatio;

    final scrollable = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < StorySpacing.scrollThreshold) {
          unawaited(onLoadMore());
        }
        return false;
      },
      child: CustomScrollView(
        key: const PageStorageKey<String>('watchHistory.works'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: watchHistoryWorkGridSlivers(
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

List<Widget> watchHistoryWorkGridSlivers(
  BuildContext context, {
  required WatchHistoryListState<WatchHistoryVideo> state,
  required double cardExtent,
  required Future<void> Function() onRefresh,
  required ValueChanged<WatchHistoryVideo> onItemTap,
}) {
  final initialLoading =
      !state.isInitialized || (state.isLoading && state.items.isEmpty);
  if (initialLoading) {
    return [
      _watchHistoryWorkGridSliver(
        cardExtent: cardExtent,
        count: 6,
        builder: (_) => const StorySkeletonBox(
          width: double.infinity,
          height: double.infinity,
          borderRadius: StoryRadius.brLg,
        ),
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
    _watchHistoryWorkGridSliver(
      cardExtent: cardExtent,
      count: state.items.length,
      builder: (index) {
        final item = state.items[index];
        return WatchHistoryWorkCard(item: item, onTap: () => onItemTap(item));
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

SliverPadding _watchHistoryWorkGridSliver({
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
