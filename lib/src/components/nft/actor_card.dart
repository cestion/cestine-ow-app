import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../widgets/widgets.dart';

/// Simple actor card for Actor type (used in creator page and search results).
class ActorCard extends StatelessWidget {
  final Actor actor;
  final VoidCallback? onTap;

  const ActorCard({super.key, required this.actor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final mintProgress = actor.mintProgress;
    return StoryCard(
      onTap: onTap,
      padding: const EdgeInsets.all(StorySpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StoryAvatar(
            imageUrl: actor.avatarUrl,
            fallbackText: actor.name,
            size: 72,
            ringColor: StoryColors.brandTeal,
          ),
          const SizedBox(height: StorySpacing.sm),
          Text(
            actor.name ?? context.l10n.commonUntitled,
            style: StoryTextStyles.titleMedium(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (actor.bio != null) ...[
            const SizedBox(height: StorySpacing.xxs),
            Text(
              actor.bio!,
              style: StoryTextStyles.bodySmall(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: StorySpacing.sm),
          if (actor.nftUnitPrice != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('NFT ', style: StoryTextStyles.labelSmall()),
                Text(
                  '${actor.nftUnitPrice} ${context.l10n.currency}',
                  style: StoryTextStyles.labelMedium(
                    color: StoryColors.brandTeal,
                  ),
                ),
              ],
            ),
          if (mintProgress != null) ...[
            const SizedBox(height: StorySpacing.xs),
            ClipRRect(
              borderRadius: StoryRadius.brPill,
              child: LinearProgressIndicator(
                value: mintProgress.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: StoryColors.lightMuted,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  StoryColors.brandTeal,
                ),
              ),
            ),
            const SizedBox(height: StorySpacing.xxs),
            Text(
              context.l10n.actorMintedCount(
                actor.mintQuantity ?? 0,
                actor.nftMaxSupply ?? 0,
              ),
              style: StoryTextStyles.caption(),
            ),
          ],
          if (actor.status != null) ...[
            const SizedBox(height: StorySpacing.xs),
            StoryChip(
              label: _statusLabel(context, actor.status!),
              style: _statusChipStyle(actor.status!),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(BuildContext context, String status) {
    return switch (status.toLowerCase()) {
      'online' || 'active' => context.l10n.actorStatusLabelOnline,
      'pending' => context.l10n.actorStatusLabelPending,
      'rejected' => context.l10n.actorStatusLabelRejected,
      'offline' => context.l10n.actorStatusLabelOffline,
      _ => status,
    };
  }

  StoryChipStyle _statusChipStyle(String status) {
    return switch (status.toLowerCase()) {
      'online' || 'active' => StoryChipStyle.success,
      'pending' => StoryChipStyle.info,
      'rejected' => StoryChipStyle.destructive,
      _ => StoryChipStyle.neutral,
    };
  }
}
