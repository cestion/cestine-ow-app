import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/models.dart';
import '../provider/app_providers.dart';
import 'theater_filter_state.dart';

/// Riverpod [Notifier] for theater page filter state.
///
/// Replaces the previous page-level `setState` pattern in `_TheaterBodyState`
/// so filter / sort changes do NOT rebuild the whole ListView —
/// only the affected sub-widgets (via `ref.watch` + `.select`).
class TheaterFilterController extends Notifier<TheaterFilterState> {
  @override
  TheaterFilterState build() => const TheaterFilterState();

  void setTag({String? tagId, String? tagName}) {
    if (state.selectedTagId != tagId) {
      state = state.copyWith(
        selectedTagId: tagId,
        selectedTagName: tagName,
        clearTag: tagId == null,
      );
    }
  }

  void setSort(TheaterSort sort) {
    if (state.sort != sort) {
      state = state.copyWith(sort: sort);
    }
  }

  /// Convert TheaterSort to API sort parameter.
  String? get apiSortValue => switch (state.sort) {
    TheaterSort.hottest => 'hot',
    TheaterSort.newest => 'latest',
    TheaterSort.topRated => 'favorite',
    TheaterSort.completedView => 'completed_view',
  };
}

final NotifierProvider<TheaterFilterController, TheaterFilterState>
theaterFilterControllerProvider =
    NotifierProvider<TheaterFilterController, TheaterFilterState>(
      TheaterFilterController.new,
    );

/// Computed provider: returns the theater items after applying the current
/// filter and sort. View layer should watch this instead of doing its own
/// filter/sort in build().
final Provider<List<DramaListItem>> filteredTheaterItemsProvider =
    Provider<List<DramaListItem>>((ref) {
      final items = ref.watch(theaterControllerProvider.select((s) => s.items));
      final sort = ref.watch(
        theaterFilterControllerProvider.select((s) => s.sort),
      );
      return _filterAndSort(items, sort);
    });

List<DramaListItem> _filterAndSort(
  List<DramaListItem> items,
  TheaterSort sort,
) {
  // Server-side filtering handles tag filtering via API.
  // Client-side sort only for topRated (legacy avgRating tie-break on page).
  // hottest / newest / completedView use the API `sort` parameter.
  if (sort == TheaterSort.topRated) {
    final list = List<DramaListItem>.from(items);
    list.sort((a, b) => (b.avgRating ?? 0).compareTo(a.avgRating ?? 0));
    return list;
  }
  return items;
}
