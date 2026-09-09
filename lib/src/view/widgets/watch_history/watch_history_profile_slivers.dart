import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../model/work_content_type.dart';
import '../../../provider/app_providers.dart';
import '../profile/profile_list_tab_slivers.dart';
import 'watch_history_content.dart';
import 'watch_history_drama_card.dart';
import 'watch_history_drama_grid.dart';
import 'watch_history_work_card.dart';
import 'watch_history_work_grid.dart';

List<Widget> buildWatchHistoryProfileTabSlivers(
  BuildContext context,
  WidgetRef ref, {
  required bool isActive,
  required WorkContentType selectedType,
  ValueChanged<WorkContentType>? onTypeChanged,
}) {
  if (!isActive) {
    return [const SliverToBoxAdapter(child: SizedBox.shrink())];
  }

  final filterBar = SliverToBoxAdapter(
    child: ProfileWorkTypeFilterBar(
      selectedType: selectedType,
      onSelected: onTypeChanged,
    ),
  );

  if (selectedType.isShortVideo) {
    return [
      filterBar,
      ..._watchHistoryVideoGridSlivers(context, ref),
    ];
  }

  return [
    filterBar,
    ..._watchHistoryDramaGridSlivers(context, ref),
  ];
}

List<Widget> _watchHistoryDramaGridSlivers(BuildContext context, WidgetRef ref) {
  final state = ref.watch(watchHistoryDramaControllerProvider);
  final viewportWidth = MediaQuery.sizeOf(context).width;
  final cardWidth = (viewportWidth - 32) / 3;
  final cardExtent =
      cardWidth / WatchHistoryDramaCard.coverAspectRatio +
      WatchHistoryDramaCard.infoHeight;

  return watchHistoryDramaGridSlivers(
    context,
    state: state,
    cardExtent: cardExtent,
    onRefresh: () =>
        ref.read(watchHistoryDramaControllerProvider.notifier).refresh(),
    onItemTap: (item) => openWatchHistoryDramaPlaylist(
      context,
      ref,
      state.items,
      item,
    ),
  );
}

List<Widget> _watchHistoryVideoGridSlivers(BuildContext context, WidgetRef ref) {
  final state = ref.watch(watchHistoryVideoControllerProvider);
  final viewportWidth = MediaQuery.sizeOf(context).width;
  final cardWidth = (viewportWidth - 32) / 3;
  final cardExtent = cardWidth / WatchHistoryWorkCard.coverAspectRatio;

  return watchHistoryWorkGridSlivers(
    context,
    state: state,
    cardExtent: cardExtent,
    onRefresh: () =>
        ref.read(watchHistoryVideoControllerProvider.notifier).refresh(),
    onItemTap: (item) => openWatchHistoryVideoPlaylist(
      context,
      ref,
      state.items,
      item,
    ),
  );
}

Future<void> loadMoreWatchHistoryProfileTab(
  WidgetRef ref,
  WorkContentType selectedType,
) async {
  if (selectedType.isShortVideo) {
    await ref.read(watchHistoryVideoControllerProvider.notifier).loadMore();
  } else {
    await ref.read(watchHistoryDramaControllerProvider.notifier).loadMore();
  }
}
