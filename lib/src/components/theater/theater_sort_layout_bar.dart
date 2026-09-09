import 'package:flutter/material.dart';

import '../../controller/theater_filter_state.dart';
import '../../l10n/story_l10n.dart';

/// Sort options bar for the theater home grid.
class TheaterSortLayoutBar extends StatelessWidget {
  final TheaterSort selectedSort;
  final ValueChanged<TheaterSort> onSortChanged;

  const TheaterSortLayoutBar({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final sortLabels = {
      TheaterSort.hottest: l10n.theaterSortHottest,
      TheaterSort.newest: l10n.theaterSortNewest,
      TheaterSort.topRated: l10n.theaterSortTopRated,
      TheaterSort.completedView: l10n.theaterSortCompletedView,
    };
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final sort in TheaterSort.values)
              GestureDetector(
                onTap: () => onSortChanged(sort),
                child: Padding(
                  padding: EdgeInsets.only(
                    right: sort == TheaterSort.values.last ? 0 : 16,
                  ),
                  child: Text(
                    sortLabels[sort] ?? sort.name,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 13,
                      height: 16 / 13,
                      fontWeight: sort == selectedSort
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: sort == selectedSort
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
