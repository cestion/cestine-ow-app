import 'dart:async';
import 'dart:math' as math;

import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/material.dart';

import 'video_feed_episode_bar.dart';

/// Feed native surface — **platform-split** cover for portrait:
///
/// - **Android**: full content box + native top-aligned cover
///   (`TopCropAspectFrameLayout`).
/// - **iOS**: full content box + native top-aligned cover
///   (`PlayerLayerView` cover frame).
///
/// Dart owns the fit: [Positioned] is sized to the video's aspect, so the
/// native cover fills that box exactly. Keep both sides in sync — a native
/// letterbox on top of a Dart-fitted box double-letterboxes.
///
/// **Landscape** (`aspect > 1`): letterbox so wide frames keep top/bottom
/// black bars instead of side-cropping into a phone-tall box.
///
/// **Collapsed sheet band** ([fitCollapsedBand]):
/// - **Landscape**: cover-fill the whole band (top and bottom flush; side
///   crop) so the upper region is fully occupied.
/// - **Portrait**: height-first contain, bottom-aligned to the sheet.
///
/// Layout always uses `ColoredBox → Stack → Positioned → player` so toggling
/// [fitCollapsedBand] only changes [Positioned] geometry (no Platform View
/// remount). Callers must pass it when the sheet collapses the band.
///
/// [NativeVideoPlayer] stays mounted across size updates — never swap it for
/// [SizedBox.shrink], or the platform view is disposed mid-bootstrap.
class VideoFeedPlayerSurface extends StatefulWidget {
  final NativeVideoPlayerController controller;

  /// Keep the platform view across landscape/portrait parent swaps.
  /// Recommend (moving [Positioned] slots) must pass false — [GlobalObjectKey]
  /// + scroll trips `identical(childRenderObject, parentRenderObject)`.
  final bool retainPlayerKey;

  /// Recommend feed: fill the parent (already above [StoryBottomNav]) so the
  /// picture meets the tab. Drama player keeps the chrome inset.
  final bool pinProgressToBottom;

  /// Sheet-open band: landscape cover-fill + portrait bottom-align to sheet.
  final bool fitCollapsedBand;

  const VideoFeedPlayerSurface({
    super.key,
    required this.controller,
    this.retainPlayerKey = true,
    this.pinProgressToBottom = false,
    this.fitCollapsedBand = false,
  });

  /// Rect for the native surface inside a [parentW] × [parentH] slot.
  ///
  /// [boxH] is the portrait full-bleed height (slot minus episode chrome);
  /// [aspect] is the rotation-corrected `width / height` of the stream.
  ///
  /// Platform-agnostic on purpose: the collapsed band must fit the video
  /// above the sheet on every platform, and the native cover relies on this
  /// rect already carrying the video's aspect.
  @visibleForTesting
  static Rect videoRect({
    required double parentW,
    required double parentH,
    required double aspect,
    required double boxH,
    required bool fitCollapsedBand,
    required bool pinProgressToBottom,
  }) {
    final isLandscape = aspect > 1.0;

    if (fitCollapsedBand) {
      if (isLandscape) {
        // Cover the band edge-to-edge (flush with sheet top).
        return Rect.fromLTWH(0, 0, parentW, parentH);
      }
      // Portrait: height-first contain, flush with the sheet.
      final fitted = _fitHeightFirst(parentW, parentH, aspect);
      return Rect.fromLTWH(
        (parentW - fitted.width) / 2,
        parentH - fitted.height,
        fitted.width,
        fitted.height,
      );
    }

    if (isLandscape) {
      final fitted = _fitContain(parentW, parentH, aspect);
      return Rect.fromLTWH(
        (parentW - fitted.width) / 2,
        (parentH - fitted.height) / 2,
        fitted.width,
        fitted.height,
      );
    }

    if (pinProgressToBottom) {
      // Recommend full-bleed: native top-cover fills the parent.
      return Rect.fromLTWH(0, 0, parentW, parentH);
    }

    // Portrait / square: cover-fill from top to episode chrome.
    return Rect.fromLTWH(0, 0, parentW, boxH);
  }

  /// Size that matches [parentH] at [aspect], falling back to width-contain
  /// when that would overflow [parentW] (landscape / very tall band).
  static Size _fitHeightFirst(double parentW, double parentH, double aspect) {
    final byHeight = Size(parentH * aspect, parentH);
    if (byHeight.width <= parentW + 0.5) return byHeight;
    return Size(parentW, parentW / aspect);
  }

  /// Letterbox fit (same as [Center] + [AspectRatio]).
  static Size _fitContain(double parentW, double parentH, double aspect) {
    final byWidth = Size(parentW, parentW / aspect);
    if (byWidth.height <= parentH + 0.5) return byWidth;
    return Size(parentH * aspect, parentH);
  }

  @override
  State<VideoFeedPlayerSurface> createState() => _VideoFeedPlayerSurfaceState();
}

class _VideoFeedPlayerSurfaceState extends State<VideoFeedPlayerSurface> {
  StreamSubscription<NativeVideoPlayerVideoSize>? _sub;

  /// Rotation-aware display aspect (`width/height` after rotationCorrection).
  double _aspect = 9 / 16;

  @override
  void initState() {
    super.initState();
    _applySize(widget.controller.videoSize);
    _sub = widget.controller.videoSizeStream.listen(_applySize);
  }

  @override
  void didUpdateWidget(covariant VideoFeedPlayerSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    _sub?.cancel();
    _aspect = 9 / 16;
    _applySize(widget.controller.videoSize);
    _sub = widget.controller.videoSizeStream.listen(_applySize);
  }

  void _applySize(NativeVideoPlayerVideoSize? size) {
    if (size == null) return;
    if (size.width <= 0 || size.height <= 0) return;
    final next = size.aspectRatio;
    if (next <= 0 || next == _aspect) return;
    if (!mounted) {
      _aspect = next;
      return;
    }
    setState(() => _aspect = next);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentW = math.max(constraints.maxWidth, 1.0);
        final parentH = math.max(constraints.maxHeight, 1.0);

        final screen = MediaQuery.sizeOf(context);
        // Short drama / fullscreen: run the picture down through the scrubber
        // so its bottom edge meets the underside of the progress track.
        final chromeHeight = VideoFeedEpisodeBar.portraitVideoBottomInsetOf(
          context,
        );
        final contentHeight = math.max(1.0, screen.height - chromeHeight);
        final boxH = contentHeight.clamp(1.0, parentH);

        final rect = VideoFeedPlayerSurface.videoRect(
          parentW: parentW,
          parentH: parentH,
          aspect: _aspect,
          boxH: boxH,
          fitCollapsedBand: widget.fitCollapsedBand,
          pinProgressToBottom: widget.pinProgressToBottom,
        );

        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                child: ExcludeSemantics(
                  child: NativeVideoPlayer(
                    // GlobalObjectKey: kept for retainPlayerKey callers.
                    // ObjectKey (recommend) is safe here because the parent
                    // chain above the player never changes on sheet toggle.
                    key: widget.retainPlayerKey
                        ? GlobalObjectKey(widget.controller)
                        : ObjectKey(widget.controller),
                    controller: widget.controller,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
