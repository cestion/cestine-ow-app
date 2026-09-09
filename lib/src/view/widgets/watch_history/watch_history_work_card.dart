import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../widgets/story_cached_image.dart';

const _likeAsset = 'assets/drama/card_heart.svg';

class WatchHistoryWorkCard extends StatelessWidget {
  static const double coverAspectRatio = 232 / 310;

  const WatchHistoryWorkCard({super.key, required this.item, this.onTap});

  final WatchHistoryVideo item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final description = item.description?.trim() ?? "";
    final likeLabel = NumberFormat.decimalPattern(
      locale,
    ).format(item.likeCount ?? 0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: StoryRadius.brLg,
        child: AspectRatio(
          aspectRatio: coverAspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _HistoryCover(url: item.posterUrl),
              const Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.transparent, Color(0x99000000)],
                      ),
                    ),
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: double.infinity,
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
              ),
              Positioned(
                left: 8,
                right: 8,
                top: 8,
                child: Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StoryColors.onOverlay,
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Row(
                  children: [
                    SvgPicture.asset(
                      _likeAsset,
                      key: const ValueKey<String>('watchHistory.likeIcon'),
                      width: 12,
                      height: 12,
                      colorFilter: const ColorFilter.mode(
                        StoryColors.onOverlay,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        likeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: StoryColors.onOverlay,
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        Icons.play_circle_outline,
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
