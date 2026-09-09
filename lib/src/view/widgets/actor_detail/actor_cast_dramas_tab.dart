import 'package:flutter/material.dart';

import '../../../components/actor_detail/actor_cast_dramas_list.dart';
import '../../../model/models.dart';

class ActorCastDramasTab extends StatelessWidget {
  final ScrollController scrollController;
  final List<DramaListItem> castItems;
  final bool loadingMore;
  final bool hasMore;

  const ActorCastDramasTab({
    super.key,
    required this.scrollController,
    required this.castItems,
    required this.loadingMore,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        ActorCastDramasList(
          castItems: castItems,
          loadingMore: loadingMore,
          hasMore: hasMore,
        ),
      ],
    );
  }
}
