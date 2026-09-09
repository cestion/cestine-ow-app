import 'package:flutter/material.dart';

/// Two-finger pinch on the player surface toggles clear-screen chrome.
///
/// Uses a [Listener] rather than [GestureDetector.onScaleStart] so a
/// one-finger pan is not claimed by [ScaleGestureRecognizer] and the
/// vertical [PageView] can still swipe.
class PlayerPinchClearScreen extends StatefulWidget {
  /// Fingers spreading past this scale enters clear-screen.
  static const double pinchOutThreshold = 1.12;

  /// Fingers pinching below this scale exits clear-screen.
  static const double pinchInThreshold = 0.88;

  final bool chromeHidden;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final Widget child;

  const PlayerPinchClearScreen({
    super.key,
    required this.chromeHidden,
    required this.onEnter,
    required this.onExit,
    required this.child,
  });

  @override
  State<PlayerPinchClearScreen> createState() => _PlayerPinchClearScreenState();
}

class _PlayerPinchClearScreenState extends State<PlayerPinchClearScreen> {
  final Map<int, Offset> _pointers = <int, Offset>{};
  double? _startSpan;
  bool _fired = false;

  static const double _minStartSpan = 24;

  double? _span() {
    if (_pointers.length < 2) return null;
    final pts = _pointers.values.toList(growable: false);
    return (pts[0] - pts[1]).distance;
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.position;
    if (_pointers.length == 2) {
      final span = _span();
      _startSpan = span != null && span >= _minStartSpan ? span : null;
      _fired = false;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.position;
    if (_fired || _startSpan == null) return;
    final span = _span();
    if (span == null) return;
    final scale = span / _startSpan!;
    if (!widget.chromeHidden &&
        scale >= PlayerPinchClearScreen.pinchOutThreshold) {
      _fired = true;
      widget.onEnter();
    } else if (widget.chromeHidden &&
        scale <= PlayerPinchClearScreen.pinchInThreshold) {
      _fired = true;
      widget.onExit();
    }
  }

  void _onPointerEnd(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.length < 2) {
      _startSpan = null;
      _fired = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: widget.child,
    );
  }
}
