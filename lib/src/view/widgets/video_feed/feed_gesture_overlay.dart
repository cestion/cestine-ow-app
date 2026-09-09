import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'player_pinch_clear_screen.dart';

/// Unified gesture overlay for full-screen video feeds.
/// Combines pinch-to-clear, tap to play/pause, long press menu, and
/// double-tap like with a heart burst aligned to product like-animation spec.
class FeedGestureOverlay extends StatefulWidget {
  final bool chromeHidden;
  final VoidCallback onEnterClearScreen;
  final VoidCallback onExitClearScreen;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Fired after the heart burst is shown. Prefer liking only when not
  /// already liked (double-tap should not unlike).
  final Future<void> Function()? onDoubleTapLike;

  final Widget? child;

  const FeedGestureOverlay({
    super.key,
    required this.chromeHidden,
    required this.onEnterClearScreen,
    required this.onExitClearScreen,
    this.onTap,
    this.onLongPress,
    this.onDoubleTapLike,
    this.child,
  });

  @override
  State<FeedGestureOverlay> createState() => _FeedGestureOverlayState();
}

class _FeedGestureOverlayState extends State<FeedGestureOverlay> {
  static const Duration _burstDuration = Duration(milliseconds: 1220);

  final List<_HeartBurst> _bursts = <_HeartBurst>[];
  final math.Random _random = math.Random();
  int _burstSeq = 0;
  Offset? _lastDoubleTapLocal;

  void _onDoubleTapDown(TapDownDetails details) {
    _lastDoubleTapLocal = details.localPosition;
  }

  void _onDoubleTap() {
    final pos = _lastDoubleTapLocal;
    _lastDoubleTapLocal = null;
    if (pos == null) return;

    unawaited(HapticFeedback.lightImpact());
    final id = _burstSeq++;
    final fontSize = 88 + _random.nextDouble() * 22;
    setState(() {
      _bursts.add(
        _HeartBurst(
          id: id,
          position: pos,
          angleRadians: (_random.nextDouble() * 36 - 18) * math.pi / 180,
          fontSize: fontSize,
        ),
      );
    });

    final like = widget.onDoubleTapLike;
    if (like != null) unawaited(like());
  }

  void _removeBurst(int id) {
    if (!mounted) return;
    setState(() => _bursts.removeWhere((b) => b.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return PlayerPinchClearScreen(
      chromeHidden: widget.chromeHidden,
      onEnter: widget.onEnterClearScreen,
      onExit: widget.onExitClearScreen,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onDoubleTapDown: widget.onDoubleTapLike == null
                ? null
                : _onDoubleTapDown,
            onDoubleTap: widget.onDoubleTapLike == null ? null : _onDoubleTap,
            child: widget.child ?? const SizedBox.expand(),
          ),
          IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                for (final burst in _bursts)
                  _LikeFloatHeart(
                    key: ValueKey<int>(burst.id),
                    position: burst.position,
                    angleRadians: burst.angleRadians,
                    fontSize: burst.fontSize,
                    duration: _burstDuration,
                    onCompleted: () => _removeBurst(burst.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartBurst {
  final int id;
  final Offset position;
  final double angleRadians;
  final double fontSize;

  const _HeartBurst({
    required this.id,
    required this.position,
    required this.angleRadians,
    required this.fontSize,
  });
}

class _LikeKeyframe {
  const _LikeKeyframe(this.t, this.opacity, this.scale, this.shadowOpacity);

  final double t;
  final double opacity;
  final double scale;
  final double shadowOpacity;
}

/// Heart burst keyed to like-animation.css (`like-heart-float`, 1220ms linear).
class _LikeFloatHeart extends StatefulWidget {
  final Offset position;
  final double angleRadians;
  final double fontSize;
  final Duration duration;
  final VoidCallback onCompleted;

  const _LikeFloatHeart({
    super.key,
    required this.position,
    required this.angleRadians,
    required this.fontSize,
    required this.duration,
    required this.onCompleted,
  });

  @override
  State<_LikeFloatHeart> createState() => _LikeFloatHeartState();
}

class _LikeFloatHeartState extends State<_LikeFloatHeart>
    with SingleTickerProviderStateMixin {
  static const _keyframes = <_LikeKeyframe>[
    _LikeKeyframe(0.00, 0.0, 1.45, 0.16),
    _LikeKeyframe(0.06, 1.0, 1.32, 0.16),
    _LikeKeyframe(0.16, 1.0, 0.86, 0.14),
    _LikeKeyframe(0.28, 1.0, 1.08, 0.15),
    _LikeKeyframe(0.38, 1.0, 0.98, 0.12),
    _LikeKeyframe(0.70, 1.0, 0.98, 0.12),
    _LikeKeyframe(0.85, 0.5, 1.52, 0.06),
    _LikeKeyframe(1.00, 0.0, 2.08, 0.0),
  ];

  static const _heartGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFB8BD),
      Color(0xFFFF777F),
      Color(0xFFFF3345),
      Color(0xFFE8001B),
      Color(0xFFE8001B),
    ],
    stops: [0.0, 0.26, 0.46, 0.68, 1.0],
  );

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onCompleted();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _sample(double t, double Function(_LikeKeyframe frame) pick) {
    const frames = _keyframes;
    if (t <= frames.first.t) return pick(frames.first);
    if (t >= frames.last.t) return pick(frames.last);
    for (var i = 0; i < frames.length - 1; i++) {
      final start = frames[i];
      final end = frames[i + 1];
      if (t < start.t || t > end.t) continue;
      final progress = (t - start.t) / (end.t - start.t);
      return lerpDouble(pick(start), pick(end), progress)!;
    }
    return pick(frames.last);
  }

  @override
  Widget build(BuildContext context) {
    final boxSize = widget.fontSize * 104 / 96;
    final anchorY = boxSize * 0.66;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final opacity = _sample(t, (frame) => frame.opacity);
        final scale = _sample(t, (frame) => frame.scale);
        final shadowOpacity = _sample(t, (frame) => frame.shadowOpacity);

        return Positioned(
          left: widget.position.dx - boxSize / 2,
          top: widget.position.dy - anchorY,
          width: boxSize,
          height: boxSize,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: widget.angleRadians,
              alignment: const Alignment(0, 0.32),
              child: Transform.scale(
                scale: scale,
                alignment: const Alignment(0, 0.32),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '♥',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        height: 1,
                        foreground: Paint()
                          ..color = Colors.black.withValues(
                            alpha: shadowOpacity,
                          )
                          ..maskFilter = const MaskFilter.blur(
                            BlurStyle.normal,
                            3.5,
                          ),
                      ),
                    ),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) =>
                          _heartGradient.createShader(bounds),
                      child: Text(
                        '♥',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          height: 1,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(
                                alpha: shadowOpacity,
                              ),
                              blurRadius: 7,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
