import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/story_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/story_l10n.dart';
import '../../widgets/story_cached_image.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import 'creator_status_badges.dart';

/// Action button config for drama management card.
class DramaActionConfig {
  final String? leftLabel;
  final bool leftDisabled;
  final String leftAction;
  final String? rightLabel;
  final String? rightAction;

  const DramaActionConfig({
    this.leftLabel,
    this.leftDisabled = false,
    this.leftAction = '',
    this.rightLabel,
    this.rightAction,
  });
}

/// Drama management card with cover, status badge, bound actors,
/// description, and status-based action buttons.
class DramaManagementCard extends StatelessWidget {
  final CreatorDrama drama;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMint;

  const DramaManagementCard({
    super.key,
    required this.drama,
    this.onEdit,
    this.onDelete,
    this.onMint,
  });

  /// Action config based on drama status and NFT minted state.
  DramaActionConfig _getActions(
    String status,
    bool nftMinted,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case 'PENDING_REVIEW':
        return DramaActionConfig(
          leftLabel: l10n.creatorDramaStatusPendingReview,
          leftAction: 'wait',
          leftDisabled: true,
        );
      case 'ONLINE':
        if (nftMinted) {
          return DramaActionConfig(
            leftLabel: l10n.creatorDramaStatusMinted,
            leftAction: 'minted',
            leftDisabled: true,
            rightLabel: l10n.creatorDramaEdit,
            rightAction: 'edit',
          );
        }
        return DramaActionConfig(
          leftLabel: l10n.creatorMintDramaNft,
          leftAction: 'mint',
          rightLabel: l10n.creatorDramaEdit,
          rightAction: 'edit',
        );
      case 'PENDING_ONLINE':
        return DramaActionConfig(
          leftLabel: l10n.creatorMintDramaNft,
          leftAction: 'mint',
        );
      case 'REVIEW_REJECTED':
        return DramaActionConfig(
          rightLabel: l10n.creatorDramaEdit,
          rightAction: 'edit',
        );
      case 'OFFLINE':
        return DramaActionConfig(
          leftLabel: l10n.creatorDramaStatusOffline,
          leftAction: 'fallback',
          leftDisabled: true,
        );
      default:
        return DramaActionConfig(
          leftLabel: l10n.creatorDramaStatusUnavailable,
          leftAction: 'fallback',
          leftDisabled: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final status = drama.status?.trim() ?? '';
    final isNftMinted = drama.nftMinted == true;
    final actions = _getActions(status, isNftMinted, l10n);
    final episodes = drama.totalEpisodes;
    final boundActors =
        drama.boundActorCollections
            ?.where((a) => a.name != null || a.avatarUrl != null)
            .toList() ??
        [];
    final description = drama.description?.trim();

    return Container(
      decoration: BoxDecoration(
        color: StoryColors.cardOf(theme.brightness),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoverStack(
            context,
            theme,
            l10n,
            status,
            isNftMinted,
            boundActors,
          ),
          _buildInfoSection(
            context,
            theme,
            l10n,
            episodes,
            description,
            boundActors,
            actions,
          ),
        ],
      ),
    );
  }

  Widget _buildCoverStack(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    String status,
    bool isNftMinted,
    List<BoundActor> boundActors,
  ) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 6 / 5,
          child: ColoredBox(
            color: StoryColors.mutedOf(theme.brightness),
            child: drama.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: drama.coverUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
                      context,
                      StoryImageCache.coverManagement,
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.movie_outlined,
                      size: 40,
                      color: StoryColors.mutedForegroundOf(theme.brightness),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: StorySpacing.base,
          left: StorySpacing.base,
          child: status == 'REVIEW_REJECTED' || status == 'OFFLINE'
              ? RejectedStatusBadge(
                  status: status,
                  auditReason: drama.auditReason,
                  l10n: l10n,
                )
              : CreatorStatusBadge(status: status, l10n: l10n),
        ),
        if (isNftMinted)
          Positioned(
            bottom: StorySpacing.base,
            left: StorySpacing.base,
            child: NftMintedBadge(l10n: l10n),
          ),
        if (onDelete != null)
          Positioned(
            top: StorySpacing.base,
            right: StorySpacing.base,
            child: _EllipsisMenu(onDelete: onDelete),
          ),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    int? episodes,
    String? description,
    List<BoundActor> boundActors,
    DramaActionConfig actions,
  ) {
    return Padding(
      padding: const EdgeInsets.all(StorySpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            drama.title?.trim() ?? '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 24 / 16,
              color: StoryColors.foregroundOf(theme.brightness),
            ),
          ),
          const SizedBox(height: StorySpacing.sm),
          if (drama.tags != null && drama.tags!.isNotEmpty) ...[
            _buildTagsRow(theme, drama.tags!),
            const SizedBox(height: StorySpacing.sm),
          ],
          if (episodes != null ||
              (description != null && description.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: StorySpacing.sm),
              child: Text(
                _formatDescription(episodes, description, l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  letterSpacing: -0.1504,
                  color: StoryColors.mutedForegroundOf(theme.brightness),
                ),
              ),
            ),
          if (boundActors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: StorySpacing.sm),
              child: _buildBoundActorsRow(theme, boundActors),
            ),
          const SizedBox(height: StorySpacing.sm),
          _buildActionButtons(context, actions, l10n),
        ],
      ),
    );
  }

  Widget _buildTagsRow(ThemeData theme, List<String> tags) {
    return SizedBox(
      height: 24,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: StoryColors.mutedOf(theme.brightness),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          alignment: Alignment.center,
          child: Text(
            tags[i],
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              letterSpacing: 0.04,
              color: StoryColors.foregroundOf(theme.brightness),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoundActorsRow(ThemeData theme, List<BoundActor> boundActors) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          ...boundActors
              .take(5)
              .map(
                (actor) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: BoundActorAvatar(actor: actor),
                ),
              ),
          if (boundActors.length > 5)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: StoryColors.mutedOf(theme.brightness),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '+${boundActors.length - 5}',
                  style: TextStyle(
                    fontSize: 10,
                    color: StoryColors.mutedForegroundOf(theme.brightness),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDescription(
    int? episodes,
    String? description,
    AppLocalizations l10n,
  ) {
    final epText = episodes != null ? l10n.dramaAllEpisodes(episodes) : '';
    final desc = description?.trim() ?? '';
    if (epText.isEmpty && desc.isEmpty) return '';
    if (epText.isEmpty) return desc;
    if (desc.isEmpty) return epText;
    return '$epText ｜ $desc';
  }

  Widget _buildActionButtons(
    BuildContext context,
    DramaActionConfig actions,
    AppLocalizations l10n,
  ) {
    final hasLeft = actions.leftLabel != null;
    final hasRight = actions.rightLabel != null && actions.rightAction != null;
    final canEdit =
        onEdit != null &&
        actions.rightAction == 'edit' &&
        drama.status?.trim() != 'PENDING_REVIEW';

    if (hasLeft && hasRight) {
      return Row(
        children: [
          Expanded(child: _buildLeftButton(context, actions)),
          const SizedBox(width: StorySpacing.sm),
          _buildRightButton(actions, canEdit),
        ],
      );
    }
    if (hasRight) {
      return SizedBox(
        width: double.infinity,
        child: _buildRightButton(actions, canEdit),
      );
    }
    if (hasLeft) {
      return SizedBox(
        width: double.infinity,
        child: _buildLeftButton(context, actions),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLeftButton(BuildContext context, DramaActionConfig actions) {
    final isFallback = actions.leftAction == 'fallback';

    VoidCallback? onTap;
    if (actions.leftDisabled) {
      onTap = null;
    } else if (actions.leftAction == 'delete') {
      onTap = onDelete;
    } else if (actions.leftAction == 'mint') {
      onTap = onMint;
    }

    return DramaActionButton(
      label: actions.leftLabel!,
      destructive: actions.leftAction == 'delete',
      fallbackStyle: isFallback,
      onTap: onTap,
    );
  }

  Widget _buildRightButton(DramaActionConfig actions, bool canEdit) {
    final rightAction = actions.rightAction;
    if (rightAction == 'edit' && canEdit) {
      return DramaActionButton(label: actions.rightLabel!, onTap: onEdit);
    }
    if (rightAction == 'delete') {
      return DramaActionButton(
        label: actions.rightLabel!,
        destructive: true,
        onTap: onDelete,
      );
    }
    return DramaActionButton(label: actions.rightLabel!);
  }
}

/// Ellipsis popup menu for delete action.
class _EllipsisMenu extends StatelessWidget {
  final VoidCallback? onDelete;

  const _EllipsisMenu({this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      onSelected: (String selected) {
        if (selected == 'delete') onDelete?.call();
      },
      constraints: const BoxConstraints(minWidth: 94, minHeight: 44),
      menuPadding: EdgeInsets.zero,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'delete',
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            child: Text(
              l10n.creatorDramaDelete,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: StoryColors.destructive,
              ),
            ),
          ),
        ),
      ],
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Icon(Icons.more_horiz, size: 16, color: Colors.white),
      ),
    );
  }
}

/// Small circular avatar for a bound actor (24px).
class BoundActorAvatar extends StatelessWidget {
  final BoundActor actor;

  const BoundActorAvatar({super.key, required this.actor});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = actor.avatarUrl?.trim();
    final name = actor.name?.trim();

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
            context,
            StoryImageCache.avatarTiny,
          ),
          errorWidget: (_, _, _) => _fallback(context, name),
        ),
      );
    }
    return _fallback(context, name);
  }

  Widget _fallback(BuildContext context, String? name) {
    final theme = Theme.of(context);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(theme.brightness),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        (name != null && name.isNotEmpty) ? name[0] : '?',
        style: TextStyle(
          fontSize: 10,
          color: StoryColors.mutedForegroundOf(theme.brightness),
        ),
      ),
    );
  }
}

/// Action button with destructive and fallback variants.
class DramaActionButton extends StatelessWidget {
  final String label;
  final bool destructive;
  final bool fallbackStyle;
  final VoidCallback? onTap;

  const DramaActionButton({
    super.key,
    required this.label,
    this.destructive = false,
    this.fallbackStyle = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (fallbackStyle) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: StoryColors.mutedOf(theme.brightness),
          disabledBackgroundColor: StoryColors.mutedOf(theme.brightness),
          disabledForegroundColor: StoryColors.mutedForegroundOf(
            theme.brightness,
          ),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      );
    }

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: destructive
            ? StoryColors.destructive
            : StoryColors.foregroundOf(theme.brightness),
        disabledForegroundColor: StoryColors.buttonDisabledForeground,
        side: BorderSide(
          color: destructive
              ? StoryColors.destructive
              : StoryColors.dividerOf(theme.brightness),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}
