import 'package:flutter/material.dart';

import '../../../core/story_constants.dart';
import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';

class VideoFeedHeaderOverlay extends StatelessWidget {
  final int episodeNo;
  final int totalEpisodes;
  final String title;
  final VoidCallback? onEpisodeTap;
  final VoidCallback? onBack;

  /// When false (short video), only the back control is shown.
  final bool showEpisodeLabel;

  const VideoFeedHeaderOverlay({
    super.key,
    required this.episodeNo,
    required this.totalEpisodes,
    required this.title,
    this.onEpisodeTap,
    this.onBack,
    this.showEpisodeLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Padding(
        padding: EdgeInsets.only(
          left: StorySpacing.base,
          right: StorySpacing.base,
          top: MediaQuery.paddingOf(context).top,
          bottom: 10,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(right: StorySpacing.sm),
                child: SizedBox(
                  height: StorySizes.touchIcon,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: StorySizes.iconBack,
                    color: StoryColors.onOverlay,
                  ),
                ),
              ),
            ),
            if (showEpisodeLabel)
              Text(
                context.l10n.playerEpisodeLabel(episodeNo),
                style: StoryTextStyles.titleLarge(
                  color: StoryColors.onOverlay,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
