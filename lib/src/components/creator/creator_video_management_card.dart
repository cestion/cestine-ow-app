import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/story_constants.dart';
import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_format.dart';
import '../../widgets/story_cached_image.dart';
import 'creator_status_badges.dart';
import 'delete_video_confirm_dialog.dart';
import 'drama_management_more_sheet.dart';

const _videoLikeIcon = 'assets/drama/detail_like.svg';

/// Fixed height of the information/action area below the video cover.
///
/// Kept in sync with the creator drama card so both management grids use the
/// same bottom action layout.
const creatorVideoManagementCardInfoHeight = 124.0;

/// Figma `557:98810` 的创作者短视频双列卡片。
class CreatorVideoManagementCard extends StatelessWidget {
  final CreatorShortVideo video;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final Future<bool> Function()? onDelete;

  const CreatorVideoManagementCard({
    super.key,
    required this.video,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Future<void> _showDeleteDialog(BuildContext context) async {
    final deleteAction = onDelete;
    if (deleteAction == null) return;
    final description = video.description.trim();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => DeleteVideoConfirmDialog(
            videoName: description,
            isDeleting: isDeleting,
            onCancel: () => Navigator.of(dialogContext).pop(),
            onConfirm: () async {
              if (isDeleting) return;
              setDialogState(() => isDeleting = true);
              final deleted = await deleteAction();
              if (!dialogContext.mounted) return;
              if (deleted) {
                Navigator.of(dialogContext).pop();
              } else {
                setDialogState(() => isDeleting = false);
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final id = video.episodeId;
    final status = video.status.trim().toUpperCase();
    final isPendingReview = status == 'PENDING_REVIEW';
    final isOffline = status == 'OFFLINE';
    final canEdit = isCreatorContentEditable(status);

    return Material(
      color: StoryColors.cardOf(brightness),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey<String>('creator-video-card-$id'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              key: ValueKey<String>('creator-video-cover-$id'),
              aspectRatio: 232 / 310,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CreatorVideoCover(url: video.posterUrl ?? video.coverUrl),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x99000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _CreatorVideoMetrics(video: video),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: _CreatorVideoStatusBadge(
                      badgeKey: ValueKey<String>('creator-video-status-$id'),
                      status: video.status,
                      auditReason: video.auditReason,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _CreatorVideoMoreButton(
                      buttonKey: ValueKey<String>('creator-video-more-$id'),
                      showEdit: canEdit,
                      onEdit: onEdit,
                      onDelete: onDelete == null
                          ? null
                          : () => unawaited(_showDeleteDialog(context)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: creatorVideoManagementCardInfoHeight,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 48,
                      child: Text(
                        video.description.trim(),
                        key: ValueKey<String>('creator-video-title-$id'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: StoryColors.foregroundOf(brightness),
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      key: ValueKey<String>('creator-video-action-$id'),
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: canEdit ? (onEdit ?? () {}) : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: StoryColors.foregroundOf(brightness),
                          disabledForegroundColor:
                              brightness == Brightness.light
                              ? StoryColors.buttonDisabledForeground
                              : StoryColors.darkButtonDisabledForeground,
                          side: BorderSide(
                            width: 1.5,
                            color: StoryColors.dividerOf(brightness),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(
                          isPendingReview
                              ? l10n.creatorDramaStatusPendingReview
                              : isOffline
                              ? l10n.creatorDramaStatusOffline
                              : l10n.creatorDramaEdit,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorVideoCover extends StatelessWidget {
  final String url;

  const _CreatorVideoCover({required this.url});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final placeholder = ColoredBox(
      color: StoryColors.mutedOf(brightness),
      child: Center(
        child: Icon(
          Icons.video_library_outlined,
          size: 40,
          color: StoryColors.mutedForegroundOf(brightness),
        ),
      ),
    );
    final imageUrl = url.trim();
    if (imageUrl.isEmpty) return placeholder;

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

class _CreatorVideoMetrics extends StatelessWidget {
  final CreatorShortVideo video;

  const _CreatorVideoMetrics({required this.video});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _CreatorVideoMetric(
                asset: 'assets/drama/card_player_play.svg',
                label: StoryFormat.formatCount(video.playCount),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: _CreatorVideoMetric(
                  asset: _videoLikeIcon,
                  label: StoryFormat.formatCount(video.likeCount),
                ),
              ),
            ],
          ),
        ),
        Text(
          StoryFormat.formatDuration(video.durationSec * 1000),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _CreatorVideoMetric extends StatelessWidget {
  final String asset;
  final String label;

  const _CreatorVideoMetric({required this.asset, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          asset,
          width: 12,
          height: 12,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _CreatorVideoStatusBadge extends StatelessWidget {
  static const _pendingColor = Color(0xCC3E63DD);
  static const _offlineColor = Color(0xFFC3C5CE);

  final Key? badgeKey;
  final String status;
  final String? auditReason;

  const _CreatorVideoStatusBadge({
    this.badgeKey,
    required this.status,
    this.auditReason,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visual = switch (status.trim().toUpperCase()) {
      'PENDING_REVIEW' => (
        label: l10n.creatorReviewFilterPending,
        color: _pendingColor,
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
        color: _offlineColor,
        showHelp: true,
      ),
      _ => null,
    };
    if (visual == null) return const SizedBox.shrink();

    final reason = auditReason?.trim();
    final normalizedStatus = status.trim().toUpperCase();
    final canShowReason =
        reason?.isNotEmpty == true || normalizedStatus == 'OFFLINE';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: visual.showHelp && canShowReason
          ? () => showAuditReasonDialog(
              context: context,
              status: normalizedStatus,
              reason: reason,
              l10n: l10n,
            )
          : null,
      child: Container(
        key: badgeKey,
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

class _CreatorVideoMoreButton extends StatelessWidget {
  final Key? buttonKey;
  final bool showEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CreatorVideoMoreButton({
    this.buttonKey,
    required this.showEdit,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final deleteAction = onDelete;
    return SizedBox.square(
      key: buttonKey,
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
