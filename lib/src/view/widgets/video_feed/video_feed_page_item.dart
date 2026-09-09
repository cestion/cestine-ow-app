import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../core/story_constants.dart';
import '../../../widgets/story_cached_image.dart';
import 'video_feed_episode_bar.dart';

/// Whether the PageView cover should unmount so the native surface shows.
///
/// Current page waits for a painted frame ([currentSurfaceReady]) or a
/// previously latched reveal. Neighbors unmount only after that slot has
/// actually decoded a frame — being mapped after `loadUrl` is not enough.
///
/// [allowLatchedReveal] must be false while the native tree is unmounted
/// (login / detail cover) or [playerSurfaceVisible] is false — otherwise a
/// stale latch exposes an empty scaffold with no poster fallback. User pause
/// should keep [allowLatchedReveal] true so the native surface holds the
/// last decoded frame.
bool shouldUnmountFeedCover({
  required bool isCurrentPage,
  required bool currentSurfaceReady,
  required bool neighborHasDecodedFrame,
  required bool currentRevealLatched,
  bool allowLatchedReveal = true,
}) {
  if (currentSurfaceReady) return true;
  if (isCurrentPage && currentRevealLatched && allowLatchedReveal) {
    return true;
  }
  return !isCurrentPage && neighborHasDecodedFrame;
}

/// Single page in the vertical video feed — cover-first, TikTok-style.
///
/// When [revealPlayer] flips true the poster fades out, then is removed from
/// the tree so the native surface under the [PageView] shows through. Leaving
/// a permanent `Opacity(0)` layer above a Platform View can still occlude
/// video on some devices — fade then unmount.
class VideoFeedPageItem extends StatefulWidget {
  final int episodeNo;
  final int totalEpisodes;
  final String? coverUrl;

  /// Series poster used only when [coverUrl] (episode/item) is missing.
  final String? dramaCoverUrl;

  /// CloudFront Cookie headers when the cover URL requires signed access.
  final Map<String, String>? coverHttpHeaders;
  final Uint8List? firstFrameBytes;
  final bool isCurrentPage;
  final bool revealPlayer;
  final bool showLoading;
  final bool hasError;
  final VoidCallback? onRetry;

  /// Recommend feed: cover fills the slot above the tab bar instead of
  /// insetting by the full-screen drama chrome.
  final bool pinProgressToBottom;

  /// Cover → video fade duration (reveal path).
  final Duration fadeOutDuration;

  const VideoFeedPageItem({
    super.key,
    required this.episodeNo,
    required this.totalEpisodes,
    this.coverUrl,
    this.dramaCoverUrl,
    this.coverHttpHeaders,
    this.firstFrameBytes,
    required this.isCurrentPage,
    required this.revealPlayer,
    this.showLoading = false,
    this.hasError = false,
    this.onRetry,
    this.pinProgressToBottom = false,
    this.fadeOutDuration = StoryDurations.animationFast,
  });

  @override
  State<VideoFeedPageItem> createState() => _VideoFeedPageItemState();
}

class _VideoFeedPageItemState extends State<VideoFeedPageItem> {
  /// Cover stays in the tree until the fade-out finishes, then drops so the
  /// Platform View is not covered by a zero-opacity Flutter layer.
  late bool _coverMounted;

  @override
  void initState() {
    super.initState();
    _coverMounted = !widget.revealPlayer;
  }

  @override
  void didUpdateWidget(covariant VideoFeedPageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealPlayer == oldWidget.revealPlayer) return;
    if (widget.revealPlayer) {
      // Keep the cover mounted so [AnimatedOpacity] can fade it out.
      if (!_coverMounted) {
        setState(() => _coverMounted = true);
      }
    } else {
      // Hide → show: remount immediately (no fade-in required for swipe-back).
      setState(() => _coverMounted = true);
    }
  }

  void _onFadeEnd() {
    if (!mounted || !widget.revealPlayer || !_coverMounted) return;
    setState(() => _coverMounted = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_coverMounted) {
      return const SizedBox.expand();
    }

    final cover = Stack(
      fit: StackFit.expand,
      children: [
        _VideoFeedCover(
          coverUrl: widget.coverUrl,
          dramaCoverUrl: widget.dramaCoverUrl,
          coverHttpHeaders: widget.coverHttpHeaders,
          firstFrameBytes: widget.firstFrameBytes,
          episodeNo: widget.episodeNo,
          totalEpisodes: widget.totalEpisodes,
          pinProgressToBottom: widget.pinProgressToBottom,
        ),
        if (widget.showLoading && widget.isCurrentPage)
          const Center(
            child: SizedBox(
              width: StorySizes.loadingSmall,
              height: StorySizes.loadingSmall,
              child: CircularProgressIndicator(
                strokeWidth: StorySizes.loadingStroke,
                color: StoryColors.onOverlay,
              ),
            ),
          ),
        if (widget.hasError && widget.isCurrentPage)
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onRetry,
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh,
                      size: StorySizes.iconPlayLarge,
                      color: StoryColors.onOverlaySubtle,
                    ),
                    const SizedBox(height: StorySpacing.xs),
                    Text(
                      context.l10n.playerTapRetry,
                      style: StoryTextStyles.bodySmall(
                        color: StoryColors.onOverlaySubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    return AnimatedOpacity(
      opacity: widget.revealPlayer ? 0.0 : 1.0,
      duration: widget.fadeOutDuration,
      curve: Curves.easeOut,
      onEnd: _onFadeEnd,
      child: IgnorePointer(
        // While fading / revealed, let chrome / gestures hit layers below.
        ignoring: widget.revealPlayer,
        child: cover,
      ),
    );
  }
}

class _VideoFeedCover extends StatelessWidget {
  final String? coverUrl;
  final String? dramaCoverUrl;
  final Map<String, String>? coverHttpHeaders;
  final Uint8List? firstFrameBytes;
  final int episodeNo;
  final int totalEpisodes;
  final bool pinProgressToBottom;

  const _VideoFeedCover({
    required this.coverUrl,
    this.dramaCoverUrl,
    this.coverHttpHeaders,
    this.firstFrameBytes,
    required this.episodeNo,
    required this.totalEpisodes,
    this.pinProgressToBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget image = _buildImage(context);

    if (pinProgressToBottom) {
      return ColoredBox(
        color: StoryColors.overlayHeavy,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      StoryColors.overlaySubtle,
                      Colors.transparent,
                      StoryColors.overlayMid,
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screen = MediaQuery.sizeOf(context);
    // Match [VideoFeedPlayerSurface]: cover meets the underside of the
    // progress track (extends through the scrubber row).
    final chromeHeight = VideoFeedEpisodeBar.portraitVideoBottomInsetOf(
      context,
    );
    final contentHeight = math.max(1.0, screen.height - chromeHeight);

    // Portrait fills this band (cover + top); landscape width-fits + centers
    // inside it (same letterbox as [VideoFeedPlayerSurface]).
    return ColoredBox(
      color: StoryColors.overlayHeavy,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: screen.width,
          height: contentHeight,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                image,
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        StoryColors.overlaySubtle,
                        Colors.transparent,
                        StoryColors.overlayMid,
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (firstFrameBytes != null && firstFrameBytes!.isNotEmpty) {
      return _AspectAwareFeedCoverImage(memoryBytes: firstFrameBytes);
    }

    final episodeUrl = coverUrl?.trim();
    final dramaUrl = dramaCoverUrl?.trim();
    final hasEpisode = episodeUrl != null && episodeUrl.isNotEmpty;
    final hasDrama = dramaUrl != null && dramaUrl.isNotEmpty;
    final sameAsDrama = hasEpisode && hasDrama && episodeUrl == dramaUrl;

    // Priority: episode/item cover → series poster → solid.
    // Avoid nesting a second StoryCachedImage for the exact same URL as
    // placeholder/error — that double-resolves CNI and looks like a reload.
    const solidPlaceholder = ColoredBox(color: StoryColors.overlayHeavy);
    final Widget dramaOrSolid = (!sameAsDrama && hasDrama)
        ? _AspectAwareFeedCoverImage(
            imageUrl: dramaUrl,
            httpHeaders: coverHttpHeaders,
            placeholder: solidPlaceholder,
            errorWidget: ColoredBox(
              color: StoryColors.overlayHeavy,
              child: _episodeFallback(context),
            ),
          )
        : ColoredBox(
            color: StoryColors.overlayHeavy,
            child: _episodeFallback(context),
          );

    if (!hasEpisode) return dramaOrSolid;

    return _AspectAwareFeedCoverImage(
      imageUrl: episodeUrl,
      httpHeaders: coverHttpHeaders,
      placeholder: sameAsDrama ? solidPlaceholder : dramaOrSolid,
      errorWidget: dramaOrSolid,
    );
  }

  Widget _episodeFallback(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_circle_outline,
            size: StorySizes.iconPlayLarge,
            color: StoryColors.onOverlaySubtle,
          ),
          const SizedBox(height: StorySpacing.sm),
          Text(
            context.l10n.playerEpisodeLabel(episodeNo),
            style: StoryTextStyles.titleMedium(
              color: StoryColors.onOverlaySubtle,
            ),
          ),
          if (totalEpisodes > 1)
            Padding(
              padding: const EdgeInsets.only(top: StorySpacing.xs),
              child: Text(
                '$episodeNo / $totalEpisodes',
                style: StoryTextStyles.bodySmall(
                  color: StoryColors.onOverlaySubtle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Portrait fills the band ([BoxFit.cover] + top). Landscape width-fits and
/// centers (letterbox) — same split as [VideoFeedPlayerSurface].
class _AspectAwareFeedCoverImage extends StatefulWidget {
  const _AspectAwareFeedCoverImage({
    this.memoryBytes,
    this.imageUrl,
    this.httpHeaders,
    this.placeholder,
    this.errorWidget,
  }) : assert(memoryBytes != null || imageUrl != null);

  final Uint8List? memoryBytes;
  final String? imageUrl;
  final Map<String, String>? httpHeaders;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<_AspectAwareFeedCoverImage> createState() =>
      _AspectAwareFeedCoverImageState();
}

class _AspectAwareFeedCoverImageState extends State<_AspectAwareFeedCoverImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _aspect;

  bool get _isLandscape => (_aspect ?? 0) > 1.0;

  /// Until aspect resolves, assume portrait so the band stays filled.
  BoxFit get _fit => _isLandscape ? BoxFit.fitWidth : BoxFit.cover;

  Alignment get _alignment =>
      _isLandscape ? Alignment.center : Alignment.topCenter;

  @override
  void initState() {
    super.initState();
    _resolveAspect();
  }

  @override
  void didUpdateWidget(covariant _AspectAwareFeedCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bytesChanged = !identical(oldWidget.memoryBytes, widget.memoryBytes);
    final urlChanged = oldWidget.imageUrl != widget.imageUrl;
    if (bytesChanged || urlChanged) {
      _aspect = null;
      _resolveAspect();
    }
  }

  @override
  void dispose() {
    _detachStream();
    super.dispose();
  }

  void _detachStream() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _stream = null;
    _listener = null;
  }

  void _resolveAspect() {
    _detachStream();
    final bytes = widget.memoryBytes;
    if (bytes != null && bytes.isNotEmpty) {
      final provider = MemoryImage(bytes);
      _listen(provider);
      return;
    }
    final url = widget.imageUrl?.trim();
    if (url == null || url.isEmpty) return;
    _listen(
      CachedNetworkImageProvider(url, headers: widget.httpHeaders),
    );
  }

  void _listen(ImageProvider provider) {
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final w = info.image.width;
        final h = info.image.height;
        if (w <= 0 || h <= 0) return;
        final next = w / h;
        if (!mounted) return;
        if (_aspect == next) return;
        setState(() => _aspect = next);
      },
      onError: (_, _) {},
    );
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = widget.memoryBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: _fit,
        alignment: _alignment,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      );
    }

    final url = widget.imageUrl!;
    return StoryCachedImage(
      imageUrl: url,
      httpHeaders: widget.httpHeaders,
      fit: _fit,
      alignment: _alignment,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
        context,
        MediaQuery.sizeOf(context).width,
      ),
      placeholder: widget.placeholder,
      errorWidget: widget.errorWidget,
    );
  }
}
