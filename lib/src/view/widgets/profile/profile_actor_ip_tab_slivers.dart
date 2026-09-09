import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/story_toast.dart';
import '../../../components/content/content_actor_ip_grid_card.dart';
import '../../../controller/user_profile_actor_collections_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/actor_collection_model.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/actor_detail_navigation.dart';
import '../../../routes/route_names.dart';
import '../../../styles/story_spacing.dart';
import '../../../utils/actor_data_sync.dart';
import '../../../widgets/story_empty_card.dart';
import '../../../widgets/story_loading.dart';
import '../../../foundation/navigator.dart';

List<Widget> buildProfileActorIpTabSlivers(
  BuildContext context,
  WidgetRef ref, {
  required UserProfileActorParam param,
  required bool isActive,
}) {
  if (!isActive) {
    return [const SliverToBoxAdapter(child: SizedBox.shrink())];
  }

  final l10n = context.l10n;
  final provider = userProfileActorCollectionsProvider(param);
  final state = ref.watch(provider);
  final isSelf = param.userId == null;

  if (!state.hasFetched || (state.isLoading && state.items.isEmpty)) {
    return [
      const SliverToBoxAdapter(
        child: SizedBox(
          height: 240,
          child: Center(child: StoryLoading.inline()),
        ),
      ),
    ];
  }

  if (state.items.isEmpty) {
    return [
      SliverToBoxAdapter(
        child: SizedBox(
          height: 320,
          child: Center(
            child: StoryEmptyCard(
              label: isSelf ? l10n.nftEmpty : l10n.publicProfileEmpty,
              actionLabel: isSelf ? l10n.followFollowersEmptyCta : null,
              onAction: isSelf
                  ? () => context.storyPush(RouteNames.createActor)
                  : null,
            ),
          ),
        ),
      ),
    ];
  }

  return [
    SliverLayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.crossAxisExtent - StorySpacing.sm * 2;
        final aspect = ContentActorIpGridCard.gridChildAspectRatioFor(
          gridWidth,
        );
        return SliverPadding(
          padding: const EdgeInsets.all(StorySpacing.sm),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ContentActorIpGridCard.gridCrossAxisCount,
              mainAxisSpacing: ContentActorIpGridCard.gridSpacing,
              crossAxisSpacing: ContentActorIpGridCard.gridSpacing,
              childAspectRatio: aspect,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final actor = state.items[index];
              return RepaintBoundary(
                key: ValueKey(actor.id),
                child: ContentActorIpGridCard(
                  actor: actor,
                  onTap: () => _openActor(context, ref, actor),
                  onSign: () =>
                      showActorSignFlowWithFreshDetail(context, ref, actor),
                  onTrade: () =>
                      StoryToast.info(context, l10n.nftTradeUnavailable),
                ),
              );
            }, childCount: state.items.length),
          ),
        );
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
  ];
}

Future<void> loadMoreProfileActorIpTab(
  WidgetRef ref,
  UserProfileActorParam param,
) async {
  await ref
      .read(userProfileActorCollectionsProvider(param).notifier)
      .loadMore();
}

Future<void> _openActor(
  BuildContext context,
  WidgetRef ref,
  ActorCollection actor,
) async {
  final id = actor.id;
  if (id == null || id.isEmpty) return;
  await openActorDetail(context, actorId: id, preview: actor);
}
