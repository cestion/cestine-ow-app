import 'dart:async';

import 'package:flutter/material.dart';

/// 60s OTP resend countdown widget.
///
/// Uses [ValueNotifier<int>] internally so only this small widget rebuilds
/// every second — not the parent LoginPage. The parent passes [active] to
/// start/stop the timer; when [active] is false, shows the resend button.
class CountdownText extends StatefulWidget {
  /// Notifies the parent when countdown reaches zero (so caller can show
  /// the resend button and reset its own state if needed).
  final VoidCallback? onExpired;
  final VoidCallback? onResend;
  final String Function(int seconds) formatter;
  final String resendLabel;
  final TextStyle? countdownStyle;
  final TextStyle? resendStyle;

  const CountdownText({
    super.key,
    required this.formatter,
    required this.resendLabel,
    this.onExpired,
    this.onResend,
    this.countdownStyle,
    this.resendStyle,
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  static const int _initialSeconds = 24;
  final ValueNotifier<int> _remaining = ValueNotifier<int>(_initialSeconds);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _remaining.value = _initialSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining.value > 0) {
        _remaining.value = _remaining.value - 1;
      } else {
        t.cancel();
        widget.onExpired?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remaining.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _remaining,
      builder: (context, remaining, _) {
        if (remaining > 0) {
          return Text(
            widget.formatter(remaining),
            style: widget.countdownStyle,
          );
        }
        return TextButton(
          onPressed: () {
            _start();
            widget.onResend?.call();
          },
          style: TextButton.styleFrom(
            foregroundColor: widget.resendStyle?.color,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(widget.resendLabel, style: widget.resendStyle),
        );
      },
    );
  }
}
