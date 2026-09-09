import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../styles/story_colors.dart';

/// Full-bleed track: active + inactive share one height (no thumb inset).
///
/// Leaves a [thumbGap] under the knob so a translucent thumb does not sit on
/// top of the active/inactive seam (which looked like a collage).
class FullWidthSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const FullWidthSliderTrackShape({
    this.thumbGap = 2,
    this.alignBottom = false,
  });

  /// Half-width cleared under the thumb (typically thumb radius).
  final double thumbGap;

  /// Pin the track to the bottom of the slider so a taller hit-target can
  /// overlap chrome above without lifting the visible bar.
  final bool alignBottom;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final rect = super.getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    if (!alignBottom) return rect;
    final dy = offset.dy + parentBox.size.height - rect.height;
    return Rect.fromLTWH(rect.left, dy, rect.width, rect.height);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 2;
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final trackRadius = Radius.circular(trackHeight / 2);
    final activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.white;
    final inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.white24;

    final gap = thumbGap;
    final activeRight = (thumbCenter.dx - gap).clamp(
      trackRect.left,
      trackRect.right,
    );
    final inactiveLeft = (thumbCenter.dx + gap).clamp(
      trackRect.left,
      trackRect.right,
    );

    if (activeRight > trackRect.left) {
      final activeRect = Rect.fromLTRB(
        trackRect.left,
        trackRect.top,
        activeRight,
        trackRect.bottom,
      );
      context.canvas.drawRRect(
        RRect.fromRectAndCorners(
          activeRect,
          topLeft: trackRadius,
          bottomLeft: trackRadius,
          topRight: activeRight >= inactiveLeft ? trackRadius : Radius.zero,
          bottomRight: activeRight >= inactiveLeft ? trackRadius : Radius.zero,
        ),
        activePaint,
      );
    }

    if (inactiveLeft < trackRect.right) {
      final inactiveRect = Rect.fromLTRB(
        inactiveLeft,
        trackRect.top,
        trackRect.right,
        trackRect.bottom,
      );
      context.canvas.drawRRect(
        RRect.fromRectAndCorners(
          inactiveRect,
          topRight: trackRadius,
          bottomRight: trackRadius,
          topLeft: inactiveLeft <= activeRight ? trackRadius : Radius.zero,
          bottomLeft: inactiveLeft <= activeRight ? trackRadius : Radius.zero,
        ),
        inactivePaint,
      );
    }
  }
}

class VideoFeedProgressBar extends StatefulWidget {
  final ValueListenable<Duration> positionNotifier;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const VideoFeedProgressBar({
    super.key,
    required this.positionNotifier,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<VideoFeedProgressBar> createState() => _VideoFeedProgressBarState();
}

class _VideoFeedProgressBarState extends State<VideoFeedProgressBar> {
  double? _dragPosition;
  SliderThemeData? _sliderTheme;
  ThemeData? _sliderThemeBase;

  /// Cache the SliderThemeData: positionNotifier fires many times per second
  /// and `copyWith` would otherwise allocate a fresh theme on every tick.
  SliderThemeData _resolveSliderTheme(BuildContext context) {
    final base = Theme.of(context);
    if (_sliderTheme == null || !identical(_sliderThemeBase, base)) {
      _sliderThemeBase = base;
      _sliderTheme = base.sliderTheme.copyWith(
        trackHeight: 2,
        trackShape: const FullWidthSliderTrackShape(),
        // Slider (M3) reserves horizontal padding for the thumb by default;
        // zero it so the track aligns with the parent's edges.
        padding: EdgeInsets.zero,
        activeTrackColor: const Color(0x66FFFFFF), // rgba(255,255,255,0.4)
        inactiveTrackColor: const Color(0x33FFFFFF), // rgba(255,255,255,0.2)
        thumbColor: const Color(0x66FFFFFF), // rgba(255,255,255,0.4)
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 2),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        overlayColor: StoryColors.onOverlaySubtle,
        showValueIndicator: ShowValueIndicator.never,
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
      );
    }
    return _sliderTheme!;
  }

  @override
  Widget build(BuildContext context) {
    final durationMs = widget.duration.inMilliseconds;
    // Duration not resolved yet — pin progress to 0 and disable seeking so the
    // thumb doesn't briefly snap to the end before the real duration arrives.
    final hasDuration = durationMs > 0;
    final maxMs = hasDuration ? durationMs : 1;
    final sliderTheme = _resolveSliderTheme(context);

    return ValueListenableBuilder<Duration>(
      valueListenable: widget.positionNotifier,
      builder: (context, position, _) {
        final positionMs = _dragPosition?.toInt() ?? position.inMilliseconds;
        final progress = hasDuration
            ? positionMs.toDouble() / maxMs.toDouble()
            : 0.0;
        return SliderTheme(
          data: sliderTheme,
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: hasDuration
                ? (value) {
                    setState(() => _dragPosition = value * maxMs.toDouble());
                  }
                : null,
            onChangeEnd: hasDuration
                ? (value) {
                    final pos = (value * maxMs).toInt();
                    widget.onSeek(Duration(milliseconds: pos));
                    setState(() => _dragPosition = null);
                  }
                : null,
          ),
        );
      },
    );
  }
}
