import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../foundation/story_theme.dart';

/// Tags row showing drama status, NFT mint status, chain, and bound actor count.
class DramaDetailTags extends StatelessWidget {
  final DramaDetail drama;

  const DramaDetailTags({super.key, required this.drama});

  @override
  Widget build(BuildContext context) {
    final tags = drama.tags;
    if (tags == null || tags.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final customColors = theme.extension<StoryCustomColors>();

    final bg =
        customColors?.surfaceMuted ??
        StoryColors.fillSecondaryOf(theme.brightness);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Metadata row showing episode count, price, and role count.
class DramaDetailMetadataRow extends StatelessWidget {
  final DramaDetail drama;
  final ThemeData theme;

  const DramaDetailMetadataRow({
    super.key,
    required this.drama,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(StorySpacing.md),
      decoration: BoxDecoration(
        color: StoryColors.cardOf(theme.brightness),
        borderRadius: StoryRadius.brLg,
        border: Border.all(
          color: StoryColors.borderOf(theme.brightness),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          _MetaItem(
            icon: Icons.movie_outlined,
            label: l10n.dramaDetailEpisodeCount(drama.totalEpisodes ?? 0),
            sub: (drama.episodePrice == 0 || drama.episodePrice == null)
                ? l10n.dramaDetailAllFree
                : l10n.dramaDetailFreeEpisodes(drama.freeEps ?? 0),
          ),
          _VerticalDivider(theme: theme),
          _MetaItem(
            icon: Icons.paid_outlined,
            label: (drama.episodePrice != null && drama.episodePrice! > 0)
                ? '${drama.episodePrice} ${l10n.currency}'
                : l10n.dramaDetailFree,
            sub: l10n.dramaDetailEpisodePrice,
          ),
          _VerticalDivider(theme: theme),
          _MetaItem(
            icon: Icons.group_outlined,
            label: '${drama.totalRoles ?? 0}',
            sub: l10n.dramaDetailRoleCount,
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;

  const _MetaItem({required this.icon, required this.label, this.sub});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: StoryColors.brandTeal),
          const SizedBox(height: StorySpacing.xxs),
          Text(label, style: StoryTextStyles.labelMedium()),
          if (sub != null)
            Text(
              sub!,
              style: StoryTextStyles.caption(),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final ThemeData theme;
  const _VerticalDivider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: VerticalDivider(
        width: 1,
        color: StoryColors.borderOf(theme.brightness),
      ),
    );
  }
}

/// Synopsis section with expand/collapse toggle.
class DramaDetailSynopsis extends StatefulWidget {
  final String description;
  final ThemeData theme;

  const DramaDetailSynopsis({
    super.key,
    required this.description,
    required this.theme,
  });

  @override
  State<DramaDetailSynopsis> createState() => _DramaDetailSynopsisState();
}

class _DramaDetailSynopsisState extends State<DramaDetailSynopsis> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.dramaDetailSynopsis,
          style: StoryTextStyles.headingMedium(
            color: StoryColors.foregroundOf(widget.theme.brightness),
          ),
        ),
        const SizedBox(height: StorySpacing.xs),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            widget.description,
            style: StoryTextStyles.bodyMedium(
              color: StoryColors.mutedForegroundOf(widget.theme.brightness),
            ),
            maxLines: _expanded ? 999 : 3,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
        if (widget.description.length > 120)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? loc.dramaDetailCollapse : loc.dramaDetailExpand,
            ),
          ),
      ],
    );
  }
}
