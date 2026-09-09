import 'package:flutter/material.dart';

import '../../core/story_constants.dart';
import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';
import '../../widgets/story_cached_image.dart';
import '../../widgets/story_skeleton.dart';
import '../theater/drama_cast_actors_dialog.dart';
import 'creator_status_badges.dart';
import 'drama_management_more_sheet.dart';
import 'drama_management_grid_layout.dart';

/// Creator-management card used by the responsive V2 grid.
class DramaManagementGridCard extends StatelessWidget {
  final CreatorDrama drama;
  final DramaManagementGridLayout layout;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DramaManagementGridCard({
    super.key,
    required this.drama,
    required this.layout,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final status = drama.status?.trim().toUpperCase() ?? '';
    final isPendingReview = status == 'PENDING_REVIEW';
    final isOffline = status == 'OFFLINE';
    final canEdit = isCreatorContentEditable(status);
    final title = drama.title?.trim();
    final tags =
        drama.tags?.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty) ??
        const Iterable<String>.empty();
    final metadata = <String>[
      if (tags.isNotEmpty) tags.first,
      if (drama.totalEpisodes != null)
        l10n.creatorDramaEpisodeCount(drama.totalEpisodes!),
    ];
    final actors = _actorsForDisplay(drama);

    return Material(
      color: StoryColors.cardOf(brightness),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey<String>(
          'drama-management-grid-card-${drama.id ?? 'unknown'}',
        ),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: DramaManagementGridLayout.coverAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _DramaManagementCover(url: drama.coverUrl),
                  if (actors.isNotEmpty)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: DramaCardRolePill(
                        actors: actors,
                        onTap: () =>
                            DramaCastActorsDialog.show(context, actors: actors),
                      ),
                    ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _DramaManagementStatusBadge(
                      key: ValueKey<String>(
                        'drama-management-grid-status-${drama.id ?? 'unknown'}',
                      ),
                      status: status,
                      auditReason: drama.auditReason,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _DramaManagementMoreButton(
                      key: ValueKey<String>(
                        'drama-management-grid-more-${drama.id ?? 'unknown'}',
                      ),
                      showEdit: canEdit,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(
                DramaManagementGridLayout.contentPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: layout.titleHeight,
                    child: Text(
                      title == null || title.isEmpty ? '-' : title,
                      maxLines: DramaManagementGridLayout.titleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: DramaManagementGridLayout.titleStyle.copyWith(
                        color: StoryColors.foregroundOf(brightness),
                      ),
                    ),
                  ),
                  const SizedBox(height: DramaManagementGridLayout.spacing),
                  SizedBox(
                    height: layout.metadataHeight,
                    child: Text(
                      metadata.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DramaManagementGridLayout.metadataStyle.copyWith(
                        color: StoryColors.mutedForegroundOf(brightness),
                      ),
                    ),
                  ),
                  const SizedBox(height: DramaManagementGridLayout.spacing),
                  SizedBox(
                    key: ValueKey<String>(
                      'drama-management-grid-action-${drama.id ?? 'unknown'}',
                    ),
                    width: double.infinity,
                    height: layout.actionHeight,
                    child: OutlinedButton(
                      onPressed: canEdit ? (onEdit ?? () {}) : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: StoryColors.foregroundOf(brightness),
                        disabledForegroundColor: brightness == Brightness.light
                            ? StoryColors.buttonDisabledForeground
                            : StoryColors.darkButtonDisabledForeground,
                        side: BorderSide(
                          width: 1.5,
                          color: StoryColors.dividerOf(brightness),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal:
                              DramaManagementGridLayout.actionHorizontalPadding,
                          vertical: 12,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.standard,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        textStyle: DefaultTextStyle.of(
                          context,
                        ).style.merge(DramaManagementGridLayout.actionStyle),
                      ),
                      child: Text(
                        isPendingReview
                            ? l10n.creatorDramaStatusPendingReview
                            : isOffline
                            ? l10n.creatorDramaStatusOffline
                            : l10n.creatorDramaEdit,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<DramaActorCollection> _actorsForDisplay(CreatorDrama drama) {
    return drama.boundActorCollections
            ?.map(
              (actor) => DramaActorCollection(
                id: actor.actorCollectionId?.toString() ?? actor.assetId,
                name: actor.name,
                avatarUrl: actor.avatarUrl,
                trust: actor.trust,
                computingPower: actor.computingPower,
              ),
            )
            .toList() ??
        const [];
  }
}

class _DramaManagementCover extends StatelessWidget {
  final String? url;

  const _DramaManagementCover({this.url});

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    final placeholder = ColoredBox(
      color: StoryColors.mutedOf(Theme.of(context).brightness),
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 40,
          color: StoryColors.mutedForegroundOf(Theme.of(context).brightness),
        ),
      ),
    );
    if (imageUrl == null || imageUrl.isEmpty) return placeholder;

    return StoryCachedImage(
      imageUrl: imageUrl,
      memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
        context,
        StoryImageCache.coverManagement,
      ),
      placeholder: placeholder,
      errorWidget: placeholder,
    );
  }
}

class _DramaManagementStatusBadge extends StatelessWidget {
  static const _pendingReviewColor = Color(0xCC3E63DD);

  final String status;
  final String? auditReason;

  const _DramaManagementStatusBadge({
    super.key,
    required this.status,
    this.auditReason,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visual = switch (status) {
      'PENDING_REVIEW' => (
        label: l10n.creatorReviewFilterPending,
        color: _pendingReviewColor,
        showHelp: false,
      ),
      'ONLINE' => (
        label: l10n.creatorReviewFilterApproved,
        color: StoryColors.success,
        showHelp: false,
      ),
      'REVIEW_REJECTED' => (
        label: l10n.creatorReviewFilterRejected,
        color: StoryColors.destructive,
        showHelp: true,
      ),
      'OFFLINE' => (
        label: l10n.creatorReviewFilterOffline,
        color: StoryColors.buttonDisabledForeground,
        showHelp: true,
      ),
      _ => null,
    };
    if (visual == null) return const SizedBox.shrink();

    final reason = auditReason?.trim();
    final canShowReason = reason?.isNotEmpty == true || status == 'OFFLINE';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: visual.showHelp && canShowReason
          ? () => showAuditReasonDialog(
              context: context,
              status: status,
              reason: reason,
              l10n: l10n,
            )
          : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
        decoration: BoxDecoration(
          color: visual.color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              visual.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (visual.showHelp) ...[
              const SizedBox(width: 4),
              const Icon(Icons.help_outline, size: 16, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

class _DramaManagementMoreButton extends StatelessWidget {
  final bool showEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _DramaManagementMoreButton({
    super.key,
    required this.showEdit,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final deleteAction = onDelete;
    return SizedBox.square(
      dimension: 32,
      child: Tooltip(
        message: MaterialLocalizations.of(context).showMenuTooltip,
        child: Material(
          color: const Color(0x4D000000),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: deleteAction != null
                ? () => showDramaManagementMoreSheet(
                    context,
                    showEdit: showEdit && onEdit != null,
                    onEdit: onEdit ?? () {},
                    onDelete: deleteAction,
                  )
                : null,
            child: const Center(
              child: Icon(Icons.more_horiz, size: 16, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uses the same row heights as the loaded card to avoid layout jumps.
class DramaManagementGridCardSkeleton extends StatelessWidget {
  final DramaManagementGridLayout layout;

  const DramaManagementGridCardSkeleton({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: ColoredBox(
        color: StoryColors.cardOf(Theme.of(context).brightness),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AspectRatio(
              aspectRatio: DramaManagementGridLayout.coverAspectRatio,
              child: StorySkeletonBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(
                DramaManagementGridLayout.contentPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StorySkeletonBox(
                    width: double.infinity,
                    height: layout.titleHeight,
                  ),
                  const SizedBox(height: DramaManagementGridLayout.spacing),
                  StorySkeletonBox(
                    width: double.infinity,
                    height: layout.metadataHeight,
                  ),
                  const SizedBox(height: DramaManagementGridLayout.spacing),
                  StorySkeletonBox(
                    width: double.infinity,
                    height: layout.actionHeight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
