import 'package:flutter/material.dart';

import '../../controller/game_state.dart';
import '../../l10n/story_l10n.dart';
import '../nft/nft_sort_filters.dart';

/// Sort filter row for the agency workshop my-actors section.
class GameSortFilters extends StatelessWidget {
  final GameActorSort currentSort;
  final ValueChanged<GameActorSort> onSortChanged;

  const GameSortFilters({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        NftSortButton(
          label: l10n.gameFilterLevel,
          isActive: currentSort == GameActorSort.level,
          onTap: () => onSortChanged(GameActorSort.level),
        ),
        const SizedBox(width: 8),
        NftSortButton(
          label: l10n.gameFilterComputingPower,
          isActive: currentSort == GameActorSort.computingPower,
          onTap: () => onSortChanged(GameActorSort.computingPower),
        ),
        const SizedBox(width: 8),
        NftSortButton(
          label: l10n.gameFilterStamina,
          isActive: currentSort == GameActorSort.stamina,
          onTap: () => onSortChanged(GameActorSort.stamina),
        ),
      ],
    );
  }
}
