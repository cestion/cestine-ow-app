import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../styles/story_colors.dart';
import '../../../widgets/story_cached_image.dart';

class DramaSliverBanner extends StatelessWidget {
  final String? bannerUrl;
  final String heroText;
  const DramaSliverBanner({super.key, this.bannerUrl, this.heroText = ''});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: StoryColors.footer,
      iconTheme: const IconThemeData(color: StoryColors.footerForeground),
      flexibleSpace: FlexibleSpaceBar(
        background: bannerUrl?.isNotEmpty == true
            ? _BannerImage(bannerUrl: bannerUrl!)
            : _BannerPlaceholder(),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  final String bannerUrl;
  const _BannerImage({required this.bannerUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: bannerUrl,
          fit: BoxFit.cover,
          memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
            context,
            MediaQuery.sizeOf(context).width,
          ),
          errorWidget: (_, _, _) => _BannerPlaceholder(),
        ),
      ],
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StoryColors.brandTeal.withValues(alpha: 0.8),
            StoryColors.gradientStart.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 48,
          color: StoryColors.footerForeground.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
