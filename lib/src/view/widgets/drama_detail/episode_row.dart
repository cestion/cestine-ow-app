import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/components.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../routes/video_feed_playlist_entry_seeds.dart';
import '../../../routes/video_feed_navigation.dart';
import '../../../styles/story_text_styles.dart';
import '../../../utils/wallet_balance_gate.dart';
import '../../../widgets/widgets.dart';
import 'episode_badge.dart';

String? _episodeCoverForList(
  List<DramaEpisodeListItem> items,
  int episodeNo,
) {
  for (final item in items) {
    if (item.episodeNo == episodeNo) {
      final ep = item.posterUrl?.trim();
      if (ep != null && ep.isNotEmpty) return ep;
      break;
    }
  }
  return null;
}

class EpisodeRow extends ConsumerWidget {
  final DramaDetail d;
  final int episodeNo;
  final ThemeData theme;
  const EpisodeRow({
    super.key,
    required this.d,
    required this.episodeNo,
    required this.theme,
  });

  bool get isFree =>
      d.episodePrice == 0 ||
      d.episodePrice == null ||
      (d.freeEps != null && episodeNo <= d.freeEps!);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (isFree) {
          final dramaId = d.id;
          if (dramaId == null || dramaId.isEmpty) return;
          final episodeCover = _episodeCoverForList(
            ref.read(dramaEpisodeListProvider(dramaId)).items,
            episodeNo,
          );
          VideoFeedNavigation.open(
            context,
            dramaId: dramaId,
            episodeNo: episodeNo,
            title: d.title ?? context.l10n.playerEpisodeLabel(episodeNo),
            totalEpisodes: d.totalEpisodes ?? 1,
            coverUrl: d.coverUrl,
            episodeCoverUrl: episodeCover,
            description: d.description,
            fromDramaDetail: true,
            chrome: VideoFeedPlaylistEntrySeeds.fromDramaDetail(
              d,
              dramaId: dramaId,
            ),
          );
        } else {
          _showUnlock(context, ref);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.md,
          vertical: StorySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: StoryColors.cardOf(theme.brightness),
          borderRadius: StoryRadius.brMd,
          border: Border.all(
            color: StoryColors.borderOf(theme.brightness),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: StoryColors.brandTeal,
              child: Text(
                '$episodeNo',
                style: StoryTextStyles.labelMedium(
                  color: StoryColors.onOverlay,
                ),
              ),
            ),
            const SizedBox(width: StorySpacing.md),
            Expanded(
              child: Text(
                context.l10n.playerEpisodeLabel(episodeNo),
                style: StoryTextStyles.titleMedium(
                  color: StoryColors.foregroundOf(theme.brightness),
                ),
              ),
            ),
            if (isFree)
              EpisodeBadge(
                label: context.l10n.dramaDetailFree,
                color: StoryColors.success,
              )
            else ...[
              Text(
                d.episodePrice != null
                    ? '${d.episodePrice} ${context.l10n.currency}'
                    : context.l10n.dramaDetailPaid,
                style: StoryTextStyles.labelSmall(
                  color: StoryColors.lightMutedForeground,
                ),
              ),
              const SizedBox(width: StorySpacing.xs),
              const Icon(
                Icons.lock_outline,
                size: 14,
                color: StoryColors.lightMutedForeground,
              ),
            ],
            const SizedBox(width: StorySpacing.xs),
            Icon(
              Icons.play_circle_outline,
              size: 22,
              color: StoryColors.mutedForegroundOf(theme.brightness),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlock(BuildContext context, WidgetRef ref) {
    if (!ref.read(authControllerProvider).isLoggedIn) {
      StoryToast.warning(context, context.l10n.dramaUnlockLoginRequired);
      return;
    }
    StoryDialog.confirm(
      context: context,
      title: context.l10n.dramaUnlockTitle,
      message: context.l10n.dramaUnlockMessage(
        episodeNo,
        '${d.episodePrice ?? ''}',
        d.batchUnlockDiscountRate != null
            ? '${(d.batchUnlockDiscountRate! * 100).toStringAsFixed(0)}%'
            : context.l10n.commonNone,
        context.l10n.currency,
      ),
      confirmLabel: context.l10n.dramaUnlockConfirmLabel(
        '${d.episodePrice ?? ''}',
        context.l10n.currency,
      ),
      onConfirm: () async {
        final price = d.episodePrice ?? 0.0;

        if (price > 0) {
          final ticket = await prepareUsdcSpend(
            ref,
            context,
            price,
            reason: 'unlock_episode',
          );
          if (ticket == null) return;
        }

        final unlock = ref.read(dramaUnlockServiceProvider);
        final result = await unlock.unlockEpisode(
          d.id ?? '',
          'pending_signature',
        );

        final ledger = ref.read(walletLedgerProvider);
        if (!context.mounted) {
          await ledger.refresh();
          return;
        }

        if (result.isSuccess) {
          await ledger.refresh();
          if (!context.mounted) return;

          StoryToast.show(
            context,
            message: context.l10n.dramaUnlockSuccessFetching,
            type: StoryToastType.success,
          );
          final mediaResult = await unlock.pollEpisodeMedia(
            dramaId: d.id ?? '',
            episodeNo: episodeNo,
          );
          if (mediaResult.isSuccess && context.mounted) {
            final dramaId = d.id;
            if (dramaId != null && dramaId.isNotEmpty) {
              final episodeCover = _episodeCoverForList(
                ref.read(dramaEpisodeListProvider(dramaId)).items,
                episodeNo,
              );
              VideoFeedNavigation.open(
                context,
                dramaId: dramaId,
                episodeNo: episodeNo,
                title: d.title ?? context.l10n.playerEpisodeLabel(episodeNo),
                totalEpisodes: d.totalEpisodes ?? 1,
                coverUrl: d.coverUrl,
                episodeCoverUrl: episodeCover,
                description: d.description,
                fromDramaDetail: true,
                chrome: VideoFeedPlaylistEntrySeeds.fromDramaDetail(
                  d,
                  dramaId: dramaId,
                ),
              );
            }
            return;
          }
          if (context.mounted) {
            StoryToast.show(
              context,
              message: context.l10n.dramaUnlockFetchTimeout,
              type: StoryToastType.error,
            );
          }
        } else {
          // Restore balance on failure
          await ledger.refresh();
          if (!context.mounted) return;

          StoryToast.show(
            context,
            message:
                result.errorOrNull?.userMessage ??
                context.l10n.dramaUnlockFailedRetry,
            type: StoryToastType.error,
          );
        }
      },
    );
  }
}
