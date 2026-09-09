import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../story_cached_image.dart';
import '../story_skeleton.dart';
import '../../foundation/navigator.dart';

const _cardKey = ValueKey<String>('storyDrawerV2.watchHistoryCard');
const _emptyKey = ValueKey<String>('storyDrawerV2.watchHistoryEmpty');

// Figma: 257px inner width minus two 12px column gaps.
const _tileWidth = 233 / 3;
const _contentMinHeight = 148.0;

/// Drawer watch-history preview matching Figma node `841:158236`.
class StoryDrawerWatchHistoryCard extends StatelessWidget {
  const StoryDrawerWatchHistoryCard({
    super.key,
    required this.history,
    this.height,
    this.headerFontSize = 14,
    this.emptyLabel,
    this.onHeaderTap,
  });

  final AsyncValue<List<WatchHistoryDrama>> history;
  final double? height;
  final double headerFontSize;
  final String? emptyLabel;
  final VoidCallback? onHeaderTap;

  @override
  Widget build(BuildContext context) {
    final entries = history.asData?.value ?? const <WatchHistoryDrama>[];

    final content = history.isLoading && !history.hasValue
        ? const _GridSkeleton()
        : entries.isEmpty
        ? _EmptyState(key: _emptyKey, label: emptyLabel)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _withHorizontalSpacing(
              entries.take(3).map((entry) => _HistoryTile(entry: entry)),
              StorySpacing.md,
            ),
          );

    return ConstrainedBox(
      key: _cardKey,
      constraints: const BoxConstraints(minHeight: 216),
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: StoryColors.cardOf(Theme.of(context).brightness),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.md,
              vertical: StorySpacing.base,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(fontSize: headerFontSize, onTap: onHeaderTap),
                const SizedBox(height: StorySpacing.base),
                if (height == null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: _contentMinHeight,
                    ),
                    child: content,
                  )
                else
                  Expanded(child: content),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.fontSize, this.onTap});

  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          onTap ??
          () {
            final navigator = Navigator.of(context);
            navigator.pop();
            context.storyPush(RouteNames.watchHistory);
          },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 20),
        child: Row(
          children: [
            Text(
              context.l10n.profileWatchHistory,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: fontSize,
                height: (fontSize == 16 ? 24 : 20) / fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 10,
              height: 20,
              child: Center(
                child: SvgPicture.asset(
                  'assets/drawer/arrow_right.svg',
                  width: 6,
                  height: 12,
                  colorFilter: ColorFilter.mode(
                    Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final WatchHistoryDrama entry;

  String? get _dramaId => entry.dramaId;

  String? get _title => entry.dramaTitle;

  String? get _coverUrl => entry.dramaCoverUrl;

  int? get _episodeNo => entry.lastEpisodeNo;

  @override
  Widget build(BuildContext context) {
    final episodeNo = _episodeNo;
    final progressText = episodeNo == null
        ? _firstNonEmpty([entry.watchProgressText]) ?? ''
        : entry.totalEpisodes == null
        ? context.l10n.playerEpisodeLabel(episodeNo)
        : context.l10n.drawerEpisodeProgress(episodeNo, entry.totalEpisodes!);

    return SizedBox(
      width: _tileWidth,
      child: InkWell(
        borderRadius: StoryRadius.brMd,
        onTap: _dramaId == null || episodeNo == null
            ? null
            : () => _openPlayer(context, episodeNo),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 232 / 310,
              child: ClipRRect(
                borderRadius: StoryRadius.brSm,
                child: _HistoryCover(url: _coverUrl),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _title ?? _dramaId ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 14, height: 20 / 14),
            ),
            const SizedBox(height: StorySpacing.xxs),
            Text(
              progressText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0.04,
                color: StoryColors.mutedForegroundOf(
                  Theme.of(context).brightness,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlayer(BuildContext context, int episodeNo) {
    final navigator = Navigator.of(context);
    navigator.pop();
    context.storyPush(RouteNames.player,
      arguments: <String, dynamic>{
        'dramaId': _dramaId,
        'episodeId': entry.lastEpisodeId,
        'episodeNo': episodeNo,
        'contentType': WorkContentType.shortDrama.apiValue,
        'title': _title,
        'totalEpisodes': entry.totalEpisodes,
        'coverUrl': _coverUrl,
      });
  }
}

class _HistoryCover extends StatelessWidget {
  const _HistoryCover({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.movie_outlined,
        size: 24,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return StoryCachedImage(
      imageUrl: url!,
      width: _tileWidth,
      height: _tileWidth * 310 / 232,
      memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
        context,
        _tileWidth,
      ),
      placeholder: placeholder,
      errorWidget: placeholder,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            brightness == Brightness.dark
                ? 'assets/common/empty_d.svg'
                : 'assets/common/empty.svg',
            width: 88,
            height: 88,
          ),
          const SizedBox(height: StorySpacing.sm),
          Text(
            label ?? context.l10n.watchHistoryEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              height: 20 / 14,
              color: StoryColors.mutedForegroundOf(brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _withHorizontalSpacing(
        List<Widget>.generate(
          3,
          (_) => const SizedBox(
            width: _tileWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 232 / 310,
                  child: StorySkeletonBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: StoryRadius.brSm,
                  ),
                ),
                SizedBox(height: 6),
                StorySkeletonBox(width: 60, height: 14),
                SizedBox(height: StorySpacing.xxs),
                StorySkeletonBox(width: 40, height: 12),
              ],
            ),
          ),
        ),
        StorySpacing.md,
      ),
    );
  }
}

List<Widget> _withHorizontalSpacing(Iterable<Widget> children, double spacing) {
  final widgets = children.toList();
  return [
    for (var index = 0; index < widgets.length; index++) ...[
      if (index > 0) SizedBox(width: spacing),
      widgets[index],
    ],
  ];
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}
