import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/story_toast.dart';
import '../../../components/creator/delete_video_confirm_dialog.dart';
import '../../../components/creator/drama_management_grid_card.dart';
import '../../../components/creator/drama_management_grid_layout.dart';
import '../../../components/creator/creator_status_badges.dart';
import '../../../controller/drama_management_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/content_playback_navigation.dart';
import '../../../routes/route_names.dart';
import '../../../styles/story_spacing.dart';
import '../../../widgets/widgets.dart';
import '../../creator_page_v2.dart';
import '../../../foundation/navigator.dart';

/// Builds the status filter displayed above the drama list.
///
/// The creator page owns the shared filter appearance, while this tab owns the
/// selected status and passes status changes to its controller.
typedef CreatorDramaStatusFiltersBuilder =
    Widget Function(
      DramaManagementStatus selectedStatus,
      ValueChanged<DramaManagementStatus> onSelected,
    );

/// Creator drama management tab with status filtering and cursor pagination.
class CreatorDramaTabV2 extends ConsumerStatefulWidget {
  final VoidCallback onCreateContent;

  const CreatorDramaTabV2({super.key, required this.onCreateContent});

  @override
  ConsumerState<CreatorDramaTabV2> createState() => _CreatorDramaTabV2State();
}

class _CreatorDramaTabV2State extends ConsumerState<CreatorDramaTabV2>
    with AutomaticKeepAliveClientMixin {
  Future<void> _openDrama(CreatorDrama drama) async {
    switch (creatorContentPlaybackAvailability(drama.status)) {
      case CreatorContentPlaybackAvailability.deleted:
        StoryToast.error(context, context.l10n.creatorWorkNotFound);
        return;
      case CreatorContentPlaybackAvailability.unavailable:
        StoryToast.error(context, context.l10n.creatorWorkNotPublished);
        return;
      case CreatorContentPlaybackAvailability.playable:
        break;
    }

    final dramaId = drama.id?.trim() ?? '';
    if (dramaId.isEmpty) {
      StoryToast.error(context, context.l10n.creatorWorkNotFound);
      return;
    }

    await ContentPlaybackNavigation.openDrama(
      context: context,
      ref: ref,
      dramaId: dramaId,
      title: drama.title,
      coverUrl: drama.coverUrl,
      description: drama.description,
      creatorName: ref.read(authControllerProvider).profile?.nickname,
      creatorUserId: ref.read(authControllerProvider).userId,
      creatorAvatarUrl: ref.read(authControllerProvider).profile?.avatarUrl,
      unavailableMessage: context.l10n.creatorWorkNotPublished,
      notFoundMessage: context.l10n.creatorWorkNotFound,
    );
  }

  Future<void> _openEditor(CreatorDrama drama) async {
    final dramaId = drama.id?.trim();
    if (dramaId == null || dramaId.isEmpty) return;

    final result = await context.storyPushForResult<Object?>(
      RouteNames.createDrama,
      arguments: {'dramaId': dramaId},
    );
    if (!mounted || result is! CreatorDrama) return;

    ref
        .read(creatorDramaManagementControllerProvider.notifier)
        .updateDrama(result);
  }

  Future<void> _showDeleteDialog(CreatorDrama drama) async {
    final notifier = ref.read(
      creatorDramaManagementControllerProvider.notifier,
    );
    notifier.requestDeleteDrama(drama);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (dialogContext, dialogRef, _) {
          final isDeleting = dialogRef.watch(
            creatorDramaManagementControllerProvider.select(
              (state) => state.isDeleting,
            ),
          );
          return DeleteVideoConfirmDialog(
            videoName: drama.title ?? '-',
            isDeleting: isDeleting,
            onCancel: () => Navigator.of(dialogContext).pop(),
            onConfirm: () async {
              final deleted = await notifier.confirmDeleteDrama();
              if (!dialogContext.mounted) return;

              Navigator.of(dialogContext).pop();
              if (deleted) {
                // The overview count is a separate data source, so refresh it
                // after a successful deletion.
                unawaited(
                  dialogRef
                      .read(
                        creatorManagementOverviewControllerProvider.notifier,
                      )
                      .refresh(),
                );
              }
            },
          );
        },
      ),
    );

    if (mounted) notifier.closeDialog();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(creatorDramaManagementControllerProvider);
    final notifier = ref.read(
      creatorDramaManagementControllerProvider.notifier,
    );

    return Column(
      children: [
        CreatorStatusFilters(
          selectedStatus: state.currentStatus,
          onSelected: notifier.selectStatus,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = DramaManagementGridLayout.of(
                context,
                constraints.maxWidth,
              );
              return state.isLoading && state.items.isEmpty
                  ? CreatorManagementGridSkeleton(
                      gridDelegate: layout.gridDelegate,
                      itemBuilder: (_, _) =>
                          DramaManagementGridCardSkeleton(layout: layout),
                    )
                  : StoryPaginatedScrollView(
                      key: const PageStorageKey<String>('creator-v2-dramas'),
                      itemCount: state.items.length,
                      hasMore: state.hasMore,
                      // Only show the footer while a page request is in flight.
                      isLoadingMore: state.isPageLoading,
                      onLoadMore: notifier.loadMore,
                      emptyWidget: Padding(
                        padding: const EdgeInsets.all(
                          StorySpacing.screenHorizontal,
                        ),
                        child: StoryEmptyCard(
                          label: context.l10n.creatorNoDramas,
                          actionLabel:
                              state.currentStatus.showsEmptyPublishAction
                              ? context.l10n.followFollowersEmptyCta
                              : null,
                          onAction: state.currentStatus.showsEmptyPublishAction
                              ? widget.onCreateContent
                              : null,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: DramaManagementGridLayout.gridPadding,
                          sliver: SliverGrid(
                            gridDelegate: layout.gridDelegate,
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final drama = state.items[index];
                              return DramaManagementGridCard(
                                drama: drama,
                                layout: layout,
                                onTap: () => unawaited(_openDrama(drama)),
                                onEdit: () => _openEditor(drama),
                                onDelete: () => _showDeleteDialog(drama),
                              );
                            }, childCount: state.items.length),
                          ),
                        ),
                      ],
                    );
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
