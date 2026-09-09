import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../styles/story_colors.dart';

class PublishVideoCoverSection extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final String hint;
  final String? localCoverPath;
  final String? remoteCoverUrl;
  final bool isBusy;
  final double uploadProgress;
  final VoidCallback? onPressed;

  const PublishVideoCoverSection({
    super.key,
    required this.title,
    required this.buttonLabel,
    required this.hint,
    required this.localCoverPath,
    this.remoteCoverUrl,
    required this.isBusy,
    required this.uploadProgress,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: StoryColors.foregroundOf(brightness),
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _CoverPreview(
              localCoverPath: localCoverPath,
              remoteCoverUrl: remoteCoverUrl,
              isBusy: isBusy,
              uploadProgress: uploadProgress,
              onTap: onPressed,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IntrinsicWidth(
                    child: _ChangeCoverButton(
                      label: buttonLabel,
                      onPressed: isBusy ? null : onPressed,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hint,
                    style: TextStyle(
                      color: StoryColors.mutedForegroundOf(brightness),
                      fontSize: 14,
                      height: 20 / 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CoverPreview extends StatelessWidget {
  final String? localCoverPath;
  final String? remoteCoverUrl;
  final bool isBusy;
  final double uploadProgress;
  final VoidCallback? onTap;

  const _CoverPreview({
    required this.localCoverPath,
    required this.remoteCoverUrl,
    required this.isBusy,
    required this.uploadProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    Widget content;
    if (localCoverPath != null) {
      content = Image.file(
        File(localCoverPath!),
        width: 88,
        height: 117,
        fit: BoxFit.cover,
      );
    } else if (remoteCoverUrl != null && remoteCoverUrl!.isNotEmpty) {
      content = CachedNetworkImage(
        imageUrl: remoteCoverUrl!,
        width: 88,
        height: 117,
        fit: BoxFit.cover,
        memCacheWidth: (88 * MediaQuery.devicePixelRatioOf(context)).round(),
        memCacheHeight: (117 * MediaQuery.devicePixelRatioOf(context)).round(),
        placeholder: (_, _) => _buildRemoteImageLoading(),
        errorWidget: (_, _, _) => _buildPlaceholder(),
      );
    } else {
      content = _buildPlaceholder();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 88,
          height: 117,
          decoration: BoxDecoration(
            color: StoryColors.mutedOf(brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: brightness == Brightness.light
                  ? StoryColors.lightSheetSecondary
                  : StoryColors.darkBorder,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              fit: StackFit.expand,
              children: [
                content,
                if (isBusy) ...[
                  const ColoredBox(color: StoryColors.overlayMedium),
                  Center(
                    child: Text(
                      '${(uploadProgress * 100).clamp(0, 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() => Center(
    child: SvgPicture.asset(
      'assets/publish_video/image_placeholder.svg',
      width: 40,
      height: 40,
    ),
  );

  Widget _buildRemoteImageLoading() => const ColoredBox(
    key: Key('publishVideoCoverLoadingOverlay'),
    color: StoryColors.overlayMedium,
    child: Center(
      child: SizedBox.square(
        key: Key('publishVideoCoverLoadingIndicator'),
        dimension: 30,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: StoryColors.onOverlay,
        ),
      ),
    ),
  );
}

class _ChangeCoverButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _ChangeCoverButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      height: 45,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: StoryColors.dividerOf(brightness),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: StoryColors.foregroundOf(brightness),
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
