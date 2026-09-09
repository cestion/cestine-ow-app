import 'package:flutter/material.dart';

import '../../core/story_logger.dart';
import '../../l10n/app_localizations.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';

/// Whether creator-managed content may expose an edit entry for [status].
///
/// Content under review and content that has been delisted are read-only.
bool isCreatorContentEditable(String? status) {
  final normalizedStatus = status?.trim().toUpperCase() ?? '';
  return normalizedStatus != 'PENDING_REVIEW' && normalizedStatus != 'OFFLINE';
}

/// Whether a creator-managed work may open the public player.
enum CreatorContentPlaybackAvailability { playable, deleted, unavailable }

CreatorContentPlaybackAvailability creatorContentPlaybackAvailability(
  String? status,
) {
  return switch (status?.trim().toUpperCase()) {
    'ONLINE' => CreatorContentPlaybackAvailability.playable,
    'DELETED' => CreatorContentPlaybackAvailability.deleted,
    _ => CreatorContentPlaybackAvailability.unavailable,
  };
}

/// Status badge with white/80 bg and status-toned text color.
///
/// Color mapping: ONLINE/PENDING_ONLINE→success, PENDING_REVIEW→info,
/// REVIEW_REJECTED→destructive, OFFLINE→pending.
class CreatorStatusBadge extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;

  const CreatorStatusBadge({
    super.key,
    required this.status,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final (label, textColor) = _statusStyle(status, l10n);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
      decoration: const BoxDecoration(
        color: StoryColors.onOverlayMuted,
        borderRadius: StoryRadius.brPill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          height: 16 / 12,
          letterSpacing: 0.04,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  (String, Color) _statusStyle(String status, AppLocalizations l10n) {
    return switch (status) {
      'ONLINE' || 'PENDING_ONLINE' => (
        status == 'PENDING_ONLINE'
            ? l10n.creatorDramaStatusPendingOnline
            : l10n.creatorDramaStatusOnline,
        StoryColors.success,
      ),
      'PENDING_REVIEW' => (
        l10n.creatorDramaStatusPendingReview,
        StoryColors.info,
      ),
      'REVIEW_REJECTED' => (
        l10n.creatorDramaStatusReviewRejected,
        StoryColors.destructive,
      ),
      'OFFLINE' => (l10n.creatorReviewFilterOffline, StoryColors.pending),
      _ => (status, StoryColors.mutedForegroundOf(Brightness.light)),
    };
  }
}

/// Shows the audit-reason dialog for a rejected/offline item.
///
/// When an offline item omits [reason], displays the localized fallback.
/// Used by [RejectedStatusBadge] and the V2 grid management cards.
void showAuditReasonDialog({
  required BuildContext context,
  required String status,
  required String? reason,
  required AppLocalizations l10n,
}) {
  final trimmed = reason?.trim();
  final hasReason = trimmed != null && trimmed.isNotEmpty;
  if (!hasReason && status != 'OFFLINE') {
    StoryLogger.w(
      'Audit reason dialog skipped because reason is empty status=$status',
      tag: 'DramaMgmt',
    );
    return;
  }
  final displayReason = hasReason
      ? trimmed
      : l10n.creatorOfflineReasonUnavailable;
  StoryLogger.i(
    'Showing audit reason dialog status=$status fallback=${!hasReason}',
    tag: 'DramaMgmt',
  );
  showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        AuditReasonDialog(status: status, reason: displayReason, l10n: l10n),
  );
}

/// Rejected/offline status badge with an audit-reason dialog.
///
/// When tapped, shows the Figma audit dialog. Offline content remains tappable
/// when [auditReason] is empty so it can display the fallback message.
class RejectedStatusBadge extends StatelessWidget {
  final String status;
  final String? auditReason;
  final AppLocalizations l10n;

  const RejectedStatusBadge({
    super.key,
    required this.status,
    this.auditReason,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final (label, textColor) = _statusTextColor(status, l10n);
    final reason = auditReason?.trim();
    final canShowReason = reason?.isNotEmpty == true || status == 'OFFLINE';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canShowReason
          ? () => showAuditReasonDialog(
              context: context,
              status: status,
              reason: reason,
              l10n: l10n,
            )
          : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
        decoration: const BoxDecoration(
          color: StoryColors.onOverlayMuted,
          borderRadius: StoryRadius.brPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0.04,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.help_outline, size: 14, color: textColor),
          ],
        ),
      ),
    );
  }

  (String, Color) _statusTextColor(String status, AppLocalizations l10n) {
    return switch (status) {
      'REVIEW_REJECTED' => (
        l10n.creatorDramaStatusReviewRejected,
        StoryColors.destructive,
      ),
      'OFFLINE' => (l10n.creatorReviewFilterOffline, StoryColors.pending),
      _ => (status, StoryColors.mutedForegroundOf(Brightness.light)),
    };
  }
}

class AuditReasonDialog extends StatelessWidget {
  final String status;
  final String reason;
  final AppLocalizations l10n;

  const AuditReasonDialog({
    super.key,
    required this.status,
    required this.reason,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isRejected = status == 'REVIEW_REJECTED';
    final title = isRejected
        ? l10n.creatorDramaStatusReviewRejected
        : l10n.creatorReviewFilterOffline;

    return Dialog(
      backgroundColor: StoryColors.cardOf(brightness),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.screenHorizontal,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: StoryColors.foregroundOf(brightness),
                fontSize: 18,
                height: 26 / 18,
                letterSpacing: -0.04,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: StorySpacing.base,
                vertical: StorySpacing.md,
              ),
              decoration: BoxDecoration(
                color: StoryColors.sheetSecondaryOf(brightness),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Text(
                reason,
                style: TextStyle(
                  color: StoryColors.foregroundOf(brightness),
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: StoryColors.foregroundOf(brightness),
                  side: BorderSide(color: StoryColors.dividerOf(brightness)),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(l10n.commonClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// NFT minted badge — shown at bottom-left of cover.
class NftMintedBadge extends StatelessWidget {
  final AppLocalizations l10n;

  const NftMintedBadge({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
      decoration: const BoxDecoration(
        color: StoryColors.onOverlayMuted,
        borderRadius: StoryRadius.brPill,
      ),
      child: Text(
        l10n.creatorDramaNftMinted,
        style: const TextStyle(
          fontSize: 12,
          height: 16 / 12,
          letterSpacing: 0.04,
          fontWeight: FontWeight.w500,
          color: StoryColors.successDeep,
        ),
      ),
    );
  }
}
