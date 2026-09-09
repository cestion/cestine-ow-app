import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../widgets/story_cached_image.dart';

class WatchHistoryDramaCard extends StatelessWidget {
  static const double coverAspectRatio = 232 / 310;
  // Figma info block: 8 top + 20 title + 2 gap + 16 progress + 8 bottom.
  static const double infoHeight = 54;

  const WatchHistoryDramaCard({super.key, required this.item, this.onTap});

  final WatchHistoryDrama item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final title = item.dramaTitle?.trim();
    final progress = _progressLabel(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: coverAspectRatio,
            child: ClipRRect(
              borderRadius: StoryRadius.brLg,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _HistoryCover(url: item.dramaCoverUrl),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 40,
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title == null || title.isEmpty
                ? item.dramaId ?? context.l10n.commonUntitled
                : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: StoryColors.foregroundOf(brightness),
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            progress,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: StoryColors.mutedForegroundOf(brightness),
              fontSize: 12,
              height: 16 / 12,
              letterSpacing: 0.04,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _progressLabel(BuildContext context) {
    final episodeNo = item.lastEpisodeNo;
    if (episodeNo != null) {
      final total = item.totalEpisodes;
      return total == null
          ? context.l10n.playerEpisodeLabel(episodeNo)
          : context.l10n.drawerEpisodeProgress(episodeNo, total);
    }

    // The API currently returns localized-looking Chinese text (for example
    // `1/1集`). Only use it when structured episode data is unavailable so
    // changing the app locale can format the normal path correctly.
    return item.watchProgressText?.trim() ?? '';
  }
}

class _HistoryCover extends StatelessWidget {
  const _HistoryCover({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final normalized = url?.trim() ?? '';
    final fallback = ColoredBox(
      color: StoryColors.mutedOf(Theme.of(context).brightness),
      child: Icon(
        Icons.movie_outlined,
        color: StoryColors.mutedForegroundOf(Theme.of(context).brightness),
      ),
    );
    if (normalized.isEmpty) return fallback;
    return LayoutBuilder(
      builder: (context, constraints) => StoryCachedImage(
        imageUrl: normalized,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
          context,
          constraints.maxWidth,
        ),
        placeholder: fallback,
        errorWidget: fallback,
      ),
    );
  }
}
