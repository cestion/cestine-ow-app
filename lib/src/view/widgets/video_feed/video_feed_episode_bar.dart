import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import 'video_feed_progress_bar.dart' show FullWidthSliderTrackShape;

class VideoFeedEpisodeBar extends StatelessWidget {
  /// Slider touch-target height. With `SliderThemeData.padding` set the
  /// framework collapses the slider to the thumb height (~10px), which is too
  /// small to scrub; this fixes a usable height and a stable bar layout.
  static const double sliderHeight = 20;

  /// Drama / fullscreen scrub hit-target. Laid out as [sliderHeight] so
  /// chrome spacing does not grow; extra height overlaps the video above.
  static const double sliderHitHeight = 36;

  /// Gap between the drama progress track and the episode CTA.
  static const double sliderEpisodeGap = 8;

  /// Progress track height at rest.
  static const double trackHeightIdle = 2;

  /// Thumb diameter (logical px); radius is half of this.
  static const double thumbSize = 4;

  /// Recommend feed: layout strip reserved under the CTA, sized so the track
  /// (plus its anti-clip lift) fills it exactly and sits flush under the CTA.
  static const double pinnedSliderHeight =
      pinnedSliderBottomOffset + trackHeightIdle;

  /// Scrub hit-target for the pinned row. Laid out as [pinnedSliderHeight] and
  /// allowed to overflow upward over the CTA; kept small so most of the CTA
  /// stays tappable. The drag halo is painted in the root overlay.
  static const double pinnedSliderHitHeight = 12;

  /// Lift the pinned track off the tab edge by the amount the thumb extends
  /// below the track. [StoryBottomNav] is a Scaffold sibling painted after the
  /// body, so anything drawn past the body bottom is covered regardless of the
  /// feed's own z-order.
  static const double pinnedSliderBottomOffset =
      thumbSize / 2 - trackHeightIdle / 2;

  /// Horizontal inset on the recommend scrubber so the thumb is not clipped
  /// at 0% / 100%.
  static const double pinnedThumbInset = 2;

  /// Episode / "watch full drama" CTA strip height (drama + recommend).
  static const double episodeCtaHeight = 38;

  /// Design distance from the episode-bar content to the screen bottom.
  /// Grows with the system safe-area when it exceeds this value.
  static const double bottomPadding = 34;

  /// Total bar height including [bottomPaddingOf]. Overlays positioned above
  /// the bar (e.g. VideoFeedBottomInfo) should offset by
  /// `contentHeightOf(context) + gap` so spacing stays constant across devices.
  ///
  /// Time labels are ephemeral (shown only while scrubbing) and are not
  /// included in this height.
  ///
  /// When [pinProgressToBottom] is true (recommend feed), the progress row
  /// sits edge-to-edge under the episode CTA / above the tab bar. Track
  /// colors match the drama player (brand red).
  static double bottomPaddingOf(
    BuildContext context, {
    bool pinProgressToBottom = false,
  }) {
    if (pinProgressToBottom) {
      // Body already sits above [StoryBottomNav]; extra inset would open a
      // black gap between the track and the tab bar.
      return 0;
    }
    return math.max(bottomPadding, MediaQuery.paddingOf(context).bottom);
  }

  /// Height kept clear under the portrait video crop on the drama player.
  ///
  /// The picture runs down through the scrubber so its bottom edge sits flush
  /// with the underside of the progress track; only the episode CTA + safe
  /// bottom remain below.
  static double portraitVideoBottomInsetOf(BuildContext context) {
    return bottomPaddingOf(context) + episodeCtaHeight;
  }

  /// Gap between bottom-info text and the top of the progress track.
  static const double sliderTopGap = 2;

  /// Recommend cards without the "watch full drama" CTA: keep the track at
  /// the tab edge, but lift title / synopsis / rails off the scrubber.
  static const double pinnedNoCtaGap = StorySpacing.md;

  static double contentHeightOf(
    BuildContext context, {
    bool pinProgressToBottom = false,
    bool showEpisodeCta = true,
  }) {
    if (pinProgressToBottom) {
      return (showEpisodeCta ? episodeCtaHeight : pinnedNoCtaGap) +
          pinnedSliderHeight;
    }
    return sliderTopGap +
        sliderHeight +
        sliderEpisodeGap +
        (showEpisodeCta ? episodeCtaHeight : 0) +
        bottomPaddingOf(context);
  }

  /// Fixed height when safe-area equals the design inset (34). Prefer
  /// [contentHeightOf] when laying out against the live safe-area.
  static const double contentHeight =
      sliderTopGap +
      sliderHeight +
      sliderEpisodeGap +
      episodeCtaHeight +
      bottomPadding;

  final int totalEpisodes;
  final ValueNotifier<Duration> positionNotifier;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onEpisodeSelector;
  final VoidCallback? onFullscreen;
  final bool isFullscreen;

  /// When set, replaces the default "选集 · 全N集" CTA label.
  final String? selectorLabel;

  /// When false, hides the fullscreen toggle (recommend home feed).
  final bool showFullscreen;

  /// Recommend layout: episode CTA above, progress flush to the bottom edge.
  final bool pinProgressToBottom;

  /// When false, hides the episode / "watch full drama" strip (e.g. single-ep
  /// recommend items) while keeping the progress row.
  final bool showEpisodeCta;

  const VideoFeedEpisodeBar({
    super.key,
    required this.totalEpisodes,
    required this.positionNotifier,
    required this.duration,
    required this.onSeek,
    this.onEpisodeSelector,
    this.onFullscreen,
    this.isFullscreen = false,
    this.selectorLabel,
    this.showFullscreen = true,
    this.pinProgressToBottom = false,
    this.showEpisodeCta = true,
  });

  @override
  Widget build(BuildContext context) {
    final ctaLabel =
        selectorLabel ??
        '${context.l10n.playerEpisodeSelect} · ${context.l10n.dramaAllEpisodesFull(totalEpisodes)}';

    final progress = _ProgressBar(
      positionNotifier: positionNotifier,
      duration: duration,
      onSeek: onSeek,
      edgeToEdge: pinProgressToBottom,
    );

    // Drama player ("选集"): center the CTA. Recommend ("观看完整短剧"): keep
    // left-aligned with trailing chevron.
    final episodeContent = pinProgressToBottom
        ? Row(
            children: [
              SvgPicture.asset(
                'assets/common/play_icon_min.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  StoryColors.onOverlay,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: StorySpacing.sm),
              Expanded(
                child: Text(
                  ctaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StoryTextStyles.labelMedium(
                    color: StoryColors.onOverlay,
                  ),
                ),
              ),
              if (!showFullscreen) ...[
                const SizedBox(width: StorySpacing.xs),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: StoryColors.onOverlay,
                ),
              ],
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/drama/play_series.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  StoryColors.onOverlay,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: StorySpacing.sm),
              Flexible(
                child: Text(
                  ctaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: StoryTextStyles.labelMedium(
                    color: StoryColors.onOverlay,
                  ),
                ),
              ),
            ],
          );

    final Widget episodeRow;
    if (pinProgressToBottom) {
      // Recommend: full-bleed `--color-20` strip, no blur (blur darkens the tint).
      episodeRow = GestureDetector(
        onTap: onEpisodeSelector,
        child: Container(
          width: double.infinity,
          height: episodeCtaHeight,
          padding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
          color: StoryColors.feedChromeScrim,
          child: episodeContent,
        ),
      );
    } else {
      episodeRow = Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onEpisodeSelector,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    height: episodeCtaHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: StorySpacing.base,
                    ),
                    decoration: BoxDecoration(
                      color: StoryColors.playerControlsScrim,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: episodeContent,
                  ),
                ),
              ),
            ),
          ),
          if (showFullscreen) ...[
            const SizedBox(width: StorySpacing.md),
            GestureDetector(
              onTap: onFullscreen,
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: SvgPicture.asset(
                    isFullscreen
                        ? 'assets/drama/play_fullscreen_in.svg'
                        : 'assets/drama/play_fullscreen.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      StoryColors.onOverlay,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (!showEpisodeCta) {
      if (pinProgressToBottom) {
        return Positioned(
          left: 0,
          right: 0,
          bottom: pinnedSliderBottomOffset,
          height: pinnedSliderHitHeight,
          child: progress,
        );
      }
      return Positioned(
        left: 0,
        right: 0,
        bottom: MediaQuery.paddingOf(context).bottom,
        height: sliderHitHeight,
        child: progress,
      );
    }

    if (pinProgressToBottom) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                episodeRow,
                const SizedBox(height: pinnedSliderHeight),
              ],
            ),
            // Overflows upward over the CTA; the track itself is bottom-aligned
            // inside this box so it stays flush in the reserved strip.
            Positioned(
              left: 0,
              right: 0,
              bottom: pinnedSliderBottomOffset,
              height: pinnedSliderHitHeight,
              child: progress,
            ),
          ],
        ),
      );
    }

    final footerBottom = bottomPaddingOf(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: sliderTopGap + sliderHeight + sliderEpisodeGap,
              ),
              ColoredBox(
                color: StoryColors.footer,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    StorySpacing.base,
                    0,
                    StorySpacing.base,
                    footerBottom,
                  ),
                  child: episodeRow,
                ),
              ),
            ],
          ),
          Positioned(
            left: StorySpacing.base,
            right: StorySpacing.base,
            bottom: episodeCtaHeight + footerBottom + sliderEpisodeGap,
            height: sliderHitHeight,
            child: progress,
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  final ValueListenable<Duration> positionNotifier;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  /// Recommend feed: flush to CTA / tab / screen edges (no inset).
  final bool edgeToEdge;

  const _ProgressBar({
    required this.positionNotifier,
    required this.duration,
    required this.onSeek,
    this.edgeToEdge = false,
  });

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double? _dragPosition;
  bool _showTimeLabels = false;
  Timer? _hideTimeLabelsTimer;
  final OverlayPortalController _haloController = OverlayPortalController();
  final GlobalKey _sliderKey = GlobalKey();

  ThemeData? _sliderThemeBase;
  bool? _sliderThemeEdgeToEdge;
  SliderThemeData? _sliderThemeIdle;
  SliderThemeData? _sliderThemeScrubbing;

  static const _timeLabelsHideDelay = Duration(milliseconds: 800);
  static const double _trackHeightIdle = VideoFeedEpisodeBar.trackHeightIdle;
  static const double _trackHeightActive = 4;

  /// Thumb diameter (logical px); radius is half of this.
  static const double _thumbSize = VideoFeedEpisodeBar.thumbSize;

  static String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Cache themes: [positionNotifier] fires many times per second and
  /// `copyWith` would otherwise allocate on every tick.
  SliderThemeData _resolveSliderTheme(
    BuildContext context, {
    required bool scrubbing,
  }) {
    final base = Theme.of(context);
    if (!identical(_sliderThemeBase, base) ||
        _sliderThemeEdgeToEdge != widget.edgeToEdge) {
      _sliderThemeBase = base;
      _sliderThemeEdgeToEdge = widget.edgeToEdge;
      _sliderThemeIdle = null;
      _sliderThemeScrubbing = null;
    }
    if (scrubbing) {
      return _sliderThemeScrubbing ??= _buildSliderTheme(base, scrubbing: true);
    }
    return _sliderThemeIdle ??= _buildSliderTheme(base, scrubbing: false);
  }

  SliderThemeData _buildSliderTheme(ThemeData base, {required bool scrubbing}) {
    final trackHeight = scrubbing ? _trackHeightActive : _trackHeightIdle;
    // Idle: soft white track. Scrubbing (drag / tap): previous brand-red style.
    final activeColor = scrubbing
        ? StoryColors.brandTealRed
        : const Color(0x66FFFFFF); // rgba(255,255,255,0.4)
    final thumbColor = scrubbing
        ? StoryColors.brandTealRed
        : const Color(0x66FFFFFF); // rgba(255,255,255,0.4)
    return base.sliderTheme.copyWith(
      trackHeight: trackHeight,
      trackShape: FullWidthSliderTrackShape(
        thumbGap: scrubbing ? 0 : _thumbSize / 2,
        alignBottom: true,
      ),
      padding: EdgeInsets.zero,
      activeTrackColor: activeColor,
      inactiveTrackColor: const Color(0x33FFFFFF), // rgba(255,255,255,0.2)
      thumbColor: thumbColor,
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: _thumbSize / 2,
      ),
      overlayShape: SliderComponentShape.noOverlay,
      overlayColor: StoryColors.onOverlaySubtle,
      showValueIndicator: ShowValueIndicator.never,
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
    );
  }

  void _revealTimeLabels() {
    _hideTimeLabelsTimer?.cancel();
    if (!_showTimeLabels) {
      setState(() => _showTimeLabels = true);
    }
    if (!_haloController.isShowing) {
      _haloController.show();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _haloController.isShowing) setState(() {});
      });
    }
  }

  void _hideScrubHalo() {
    if (_haloController.isShowing) {
      _haloController.hide();
    }
  }

  void _scheduleHideTimeLabels() {
    _hideTimeLabelsTimer?.cancel();
    _hideTimeLabelsTimer = Timer(_timeLabelsHideDelay, () {
      if (!mounted) return;
      setState(() => _showTimeLabels = false);
    });
  }

  @override
  void dispose() {
    _hideTimeLabelsTimer?.cancel();
    _hideScrubHalo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final durationMs = widget.duration.inMilliseconds;
    // Duration not resolved yet — pin progress to 0 so the thumb doesn't
    // briefly snap to the end when position is still from the previous episode
    // (position / maxMs=1 → clamp 1.0).
    final hasDuration = durationMs > 0;
    final maxMs = hasDuration ? durationMs : 1;
    final scrubbing = _showTimeLabels;
    final barHeight = widget.edgeToEdge
        ? VideoFeedEpisodeBar.pinnedSliderHitHeight
        : VideoFeedEpisodeBar.sliderHitHeight;
    final sliderTheme = _resolveSliderTheme(context, scrubbing: scrubbing);
    final overlayProgress = hasDuration
        ? ((_dragPosition?.toInt() ??
                          widget.positionNotifier.value.inMilliseconds)
                      .toDouble() /
                  maxMs.toDouble())
              .clamp(0.0, 1.0)
        : 0.0;

    return OverlayPortal(
      overlayLocation: OverlayChildLocation.rootOverlay,
      controller: _haloController,
      overlayChildBuilder: (context) {
        return _PinnedScrubHalo(
          sliderKey: _sliderKey,
          progress: overlayProgress,
          alignBottom: true,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          SliderTheme(
            data: sliderTheme,
            child: Container(
              height: barHeight,
              margin: widget.edgeToEdge
                  ? const EdgeInsets.symmetric(
                      horizontal: VideoFeedEpisodeBar.pinnedThumbInset,
                    )
                  : const EdgeInsets.symmetric(horizontal: 2),
              // Pin the track to the bottom of the hit target so the taller
              // touch area overlaps the chrome above without lifting the bar.
              alignment: Alignment.bottomCenter,
              child: ValueListenableBuilder<Duration>(
                valueListenable: widget.positionNotifier,
                builder: (context, position, _) {
                  final positionMs =
                      _dragPosition?.toInt() ?? position.inMilliseconds;
                  final progress = hasDuration
                      ? positionMs.toDouble() / maxMs.toDouble()
                      : 0.0;
                  final Widget slider = Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChangeStart: hasDuration
                        ? (_) => _revealTimeLabels()
                        : null,
                    onChanged: hasDuration
                        ? (value) {
                            _revealTimeLabels();
                            setState(
                              () => _dragPosition = value * maxMs.toDouble(),
                            );
                          }
                        : null,
                    onChangeEnd: hasDuration
                        ? (value) {
                            final pos = (value * maxMs).toInt();
                            widget.onSeek(Duration(milliseconds: pos));
                            setState(() => _dragPosition = null);
                            _hideScrubHalo();
                            _scheduleHideTimeLabels();
                          }
                        : null,
                  );
                  return KeyedSubtree(key: _sliderKey, child: slider);
                },
              ),
            ),
          ),
          if (_showTimeLabels)
            Positioned(
              left: 0,
              right: 0,
              // Float above the scrubber over the video — no footer chrome behind.
              bottom: barHeight + 38,
              child: IgnorePointer(
                child: ValueListenableBuilder<Duration>(
                  valueListenable: widget.positionNotifier,
                  builder: (context, position, _) {
                    final currentPos = hasDuration
                        ? (_dragPosition?.toInt() ?? position.inMilliseconds)
                        : 0;
                    final current = _formatDuration(
                      Duration(milliseconds: currentPos),
                    );
                    final total = _formatDuration(widget.duration);
                    return Center(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Color(0x4D000000), // black @ 0.3
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: current,
                                  style: const TextStyle(
                                    color: StoryColors.onOverlay,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' / ',
                                  style: TextStyle(
                                    color: StoryColors.onOverlaySubtle,
                                  ),
                                ),
                                TextSpan(
                                  text: total,
                                  style: const TextStyle(
                                    color: StoryColors.onOverlaySubtle,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Scrub halo in the root overlay so it paints above tab / episode chrome.
class _PinnedScrubHalo extends StatelessWidget {
  const _PinnedScrubHalo({
    required this.sliderKey,
    required this.progress,
    this.alignBottom = false,
  });

  final GlobalKey sliderKey;
  final double progress;
  final bool alignBottom;

  static const double _radius = 12;
  static const double _trackHeightActive = 4;

  @override
  Widget build(BuildContext context) {
    final sliderContext = sliderKey.currentContext;
    if (sliderContext == null) return const SizedBox.shrink();
    final sliderBox = sliderContext.findRenderObject() as RenderBox?;
    if (sliderBox == null || !sliderBox.hasSize || !sliderBox.attached) {
      return const SizedBox.shrink();
    }
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) {
      return const SizedBox.shrink();
    }

    final dy = alignBottom
        ? sliderBox.size.height - _trackHeightActive / 2
        : sliderBox.size.height / 2;
    // Must match the Slider's own thumb mapping: with `SliderThemeData.padding`
    // zeroed the track spans the full box, so the thumb centre is
    // `progress * width` with no thumb-radius inset.
    final local = Offset(progress.clamp(0.0, 1.0) * sliderBox.size.width, dy);
    final global = sliderBox.localToGlobal(local, ancestor: overlayBox);
    return Positioned(
      left: global.dx - _radius,
      top: global.dy - _radius,
      width: _radius * 2,
      height: _radius * 2,
      child: const IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: StoryColors.onOverlaySubtle,
          ),
        ),
      ),
    );
  }
}
