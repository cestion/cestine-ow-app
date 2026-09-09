import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';

import '../l10n/story_l10n.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import 'story_empty_card.dart';
import 'story_loading.dart';

/// Scroll container shared by cursor-paginated lists and grids.
///
/// Data fetching and cursor ownership stay in the controller. This widget owns
/// the refresh/load gestures and the shared indicators only.
class StoryPaginatedScrollView extends StatefulWidget {
  final List<Widget> slivers;
  final int itemCount;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function()? onRefresh;
  final Future<void> Function() onLoadMore;
  final ScrollController? controller;
  final double loadMoreThreshold;
  final ScrollPhysics physics;

  /// When false, omits [EasyRefresh] so a parent [NestedScrollView] can own
  /// pull-to-refresh for the whole profile surface.
  final bool pullToRefreshEnabled;
  final Widget? emptyWidget;
  final Widget loadingIndicator;
  final EdgeInsetsGeometry loadingPadding;
  final bool showNoMoreIndicator;
  final Widget? noMoreIndicator;
  final EdgeInsetsGeometry noMorePadding;

  const StoryPaginatedScrollView({
    super.key,
    required this.slivers,
    required this.itemCount,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    this.onRefresh,
    this.controller,
    this.pullToRefreshEnabled = true,
    this.loadMoreThreshold = StorySpacing.scrollThreshold,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.emptyWidget,
    this.loadingIndicator = const StoryLoading.inline(),
    this.loadingPadding = const EdgeInsets.symmetric(
      vertical: StorySpacing.base,
    ),
    this.showNoMoreIndicator = false,
    this.noMoreIndicator,
    this.noMorePadding = const EdgeInsets.symmetric(
      vertical: StorySpacing.base,
    ),
  });

  @override
  State<StoryPaginatedScrollView> createState() =>
      _StoryPaginatedScrollViewState();
}

class _StoryPaginatedScrollViewState extends State<StoryPaginatedScrollView> {
  bool _isRefreshing = false;
  bool _isRequesting = false;

  Future<void> _refresh() async {
    if (_isRefreshing || widget.onRefresh == null) return;
    _isRefreshing = true;
    try {
      await widget.onRefresh!();
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _loadMore() async {
    if (_isRequesting || widget.isLoadingMore || !widget.hasMore) return;
    _isRequesting = true;
    try {
      await widget.onLoadMore();
    } finally {
      _isRequesting = false;
    }
  }

  List<Widget> _buildSlivers(BuildContext context) {
    if (widget.itemCount == 0) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child:
                widget.emptyWidget ??
                StoryEmptyCard(label: context.l10n.searchNoData),
          ),
        ),
      ];
    }

    return [
      ...widget.slivers,
      if (widget.isLoadingMore)
        SliverPadding(
          padding: widget.loadingPadding,
          sliver: SliverToBoxAdapter(
            child: Center(child: widget.loadingIndicator),
          ),
        ),
      if (!widget.hasMore && widget.showNoMoreIndicator)
        SliverPadding(
          padding: widget.noMorePadding,
          sliver: SliverToBoxAdapter(
            child: Center(
              child:
                  widget.noMoreIndicator ??
                  Text(
                    context.l10n.listNoMoreData,
                    style: TextStyle(
                      color: StoryColors.mutedForegroundOf(
                        Theme.of(context).brightness,
                      ),
                      fontSize: 12,
                    ),
                  ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      physics: widget.physics,
      slivers: _buildSlivers(context),
    );

    if (!widget.pullToRefreshEnabled) {
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < widget.loadMoreThreshold) {
            unawaited(_loadMore());
          }
          return false;
        },
        child: scrollView,
      );
    }

    return EasyRefresh.builder(
      header: const MaterialHeader(color: StoryColors.brandTeal),
      footer: BuilderFooter(
        triggerOffset: widget.loadMoreThreshold,
        clamping: false,
        processedDuration: Duration.zero,
        infiniteOffset: widget.loadMoreThreshold,
        position: IndicatorPosition.custom,
        builder: (_, _) => const SizedBox.shrink(),
      ),
      onRefresh: widget.onRefresh == null ? null : _refresh,
      onLoad: widget.itemCount > 0 && widget.hasMore ? _loadMore : null,
      childBuilder: (context, easyRefreshPhysics) => CustomScrollView(
        controller: widget.controller,
        physics: easyRefreshPhysics.applyTo(widget.physics),
        slivers: _buildSlivers(context),
      ),
    );
  }
}
