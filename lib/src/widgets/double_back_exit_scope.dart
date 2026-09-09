import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Prevents an accidental app exit by requiring two back presses within
/// [interval].
///
/// The first press invokes [onFirstBack] with the configured [interval], so a
/// prompt can stay visible for exactly the same period. The second press
/// requests a native app exit. Pass [onExitRequested] to override the exit
/// action in tests or in hosts with custom lifecycle handling.
class DoubleBackExitScope extends StatefulWidget {
  const DoubleBackExitScope({
    super.key,
    required this.child,
    required this.onFirstBack,
    this.enabled = true,
    this.interval = const Duration(seconds: 3),
    this.onExitRequested,
  });

  final Widget child;
  final ValueChanged<Duration> onFirstBack;
  final bool enabled;
  final Duration interval;
  final VoidCallback? onExitRequested;

  @override
  State<DoubleBackExitScope> createState() => _DoubleBackExitScopeState();
}

class _DoubleBackExitScopeState extends State<DoubleBackExitScope> {
  Timer? _resetTimer;
  bool _exitArmed = false;

  @override
  void didUpdateWidget(DoubleBackExitScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      _reset();
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _reset() {
    _resetTimer?.cancel();
    _resetTimer = null;
    _exitArmed = false;
  }

  void _handleBack(bool didPop) {
    if (didPop || !widget.enabled) return;

    if (_exitArmed) {
      _reset();
      final onExitRequested = widget.onExitRequested;
      if (onExitRequested != null) {
        onExitRequested();
      } else {
        unawaited(SystemNavigator.pop());
      }
      return;
    }

    _exitArmed = true;
    widget.onFirstBack(widget.interval);
    _resetTimer?.cancel();
    _resetTimer = Timer(widget.interval, _reset);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      // When disabled, let the route handle back normally (for example, to
      // close Scaffold's drawer LocalHistoryEntry).
      canPop: !widget.enabled,
      onPopInvokedWithResult: (didPop, _) => _handleBack(didPop),
      child: widget.child,
    );
  }
}
