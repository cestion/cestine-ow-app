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
import '../../../widgets/story_paginated_scroll_view.dart';
import '../../../foundation/navigator.dart';

/// 个人主页「角色 IP」双列网格，卡片与搜索 / 广场紧凑卡一致。
class ProfileActorIpTab extends ConsumerStatefulWidget {
  final UserProfileActorParam param;
  final bool isActive;
  final bool coordinatedWithParentRefresh;

  const ProfileActorIpTab({
    super.key,
    required this.param,
    required this.isActive,
    this.coordinatedWithParentRefresh = false,
  });

  @override
  ConsumerState<ProfileActorIpTab> createState() => _ProfileActorIpTabState();
}

class _ProfileActorIpTabState extends ConsumerState<ProfileActorIpTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool get _isSelf => widget.param.userId == null;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.isActive) return const SizedBox.shrink();

    final l10n = context.l10n;
    final provider = userProfileActorCollectionsProvider(widget.param);
    final state = ref.watch(provider);
    if (!state.hasFetched || (state.isLoading && state.items.isEmpty)) {
      return const Center(child: StoryLoading.inline());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth - StorySpacing.sm * 2;
        final aspect = ContentActorIpGridCard.gridChildAspectRatioFor(
          gridWidth,
        );
        return StoryPaginatedScrollView(
          itemCount: state.items.length,
          hasMore: state.hasMore,
          isLoadingMore: state.isPageLoading,
          pullToRefreshEnabled: !widget.coordinatedWithParentRefresh,
          emptyWidget: StoryEmptyCard(
            label: _isSelf ? l10n.nftEmpty : l10n.publicProfileEmpty,
            actionLabel: _isSelf ? l10n.followFollowersEmptyCta : null,
            onAction: _isSelf
                ? () => context.storyPush(RouteNames.createActor)
                : null,
          ),
          onRefresh: widget.coordinatedWithParentRefresh
              ? null
              : () => ref.read(provider.notifier).refresh(),
          onLoadMore: () => ref.read(provider.notifier).loadMore(),
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final actor = state.items[index];
                  return RepaintBoundary(
                    key: ValueKey(actor.id),
                    child: ContentActorIpGridCard(
                      actor: actor,
                      onTap: () => _openActor(actor),
                      onSign: () =>
                          showActorSignFlowWithFreshDetail(context, ref, actor),
                      onTrade: () =>
                          StoryToast.info(context, l10n.nftTradeUnavailable),
                    ),
                  );
                }, childCount: state.items.length),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openActor(ActorCollection actor) async {
    final id = actor.id;
    if (id == null || id.isEmpty) return;
    await openActorDetail(context, actorId: id, preview: actor);
  }
}
