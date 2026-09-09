import 'package:flutter/material.dart';

import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../widgets/widgets.dart';
import 'countdown_text.dart';

enum _CountdownSlot { idle, verifying, success }

/// Step 2 of OTP login: code verification.
///
/// Owns its own code-error [ValueNotifier] so the parent LoginPage does not
/// rebuild when an OTP error is set/cleared. Invokes [onVerify] when the user
/// has entered a 6-digit code. Shows a resend countdown that calls
/// [onResend] when it reaches zero.
///
/// While verifying, the countdown slot shows [verifyingLabel]; on success the
/// parent calls [setSuccess] so the same slot shows the success message.
class OtpInputSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? email;
  final String resendLabel;
  final String verifyingLabel;
  final String Function(int seconds) countdownFormatter;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function() onResend;

  const OtpInputSection({
    super.key,
    required this.title,
    required this.subtitle,
    this.email,
    required this.resendLabel,
    required this.verifyingLabel,
    required this.countdownFormatter,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<OtpInputSection> createState() => OtpInputSectionState();
}

class OtpInputSectionState extends State<OtpInputSection> {
  final ValueNotifier<String?> _error = ValueNotifier<String?>(null);
  final ValueNotifier<_CountdownSlot> _countdownSlot =
      ValueNotifier<_CountdownSlot>(_CountdownSlot.idle);
  final GlobalKey<StoryPinInputState> _pinKey = GlobalKey<StoryPinInputState>();
  String? _successMessage;

  Listenable get _feedbackListenable =>
      Listenable.merge([_error, _countdownSlot]);

  @override
  void dispose() {
    _error.dispose();
    _countdownSlot.dispose();
    super.dispose();
  }

  /// Called by the parent when the verify response fails. Shows the error
  /// message, clears the entered digits, and re-focuses the first cell so the
  /// user can retype immediately.
  void setError(String? message) {
    _successMessage = null;
    _countdownSlot.value = _CountdownSlot.idle;
    _error.value = message;
    // Rebuild with enabled:true first, then clear + focus so typing works.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pinKey.currentState?.reset();
    });
  }

  /// Called by the parent when verification succeeds. Replaces the countdown
  /// slot with the success message.
  void setSuccess(String message) {
    _error.value = null;
    _successMessage = message;
    _countdownSlot.value = _CountdownSlot.success;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Clears the OTP cells, clears any error, and re-focuses the first cell.
  /// Called by the parent after a successful resend.
  void reset() {
    _error.value = null;
    _successMessage = null;
    _countdownSlot.value = _CountdownSlot.idle;
    _pinKey.currentState?.reset();
  }

  Future<void> _handleChanged(String code) async {
    // First keystroke after a failed verify restores the initial border / hint.
    if (_error.value != null && code.isNotEmpty) {
      _error.value = null;
    }
    if (code.length != 6) return;
    if (_countdownSlot.value == _CountdownSlot.verifying ||
        _countdownSlot.value == _CountdownSlot.success) {
      return;
    }
    _successMessage = null;
    _countdownSlot.value = _CountdownSlot.verifying;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await widget.onVerify(code);
    } catch (_) {
      // Never leave the UI stuck on "verifying".
      if (mounted && _countdownSlot.value == _CountdownSlot.verifying) {
        _countdownSlot.value = _CountdownSlot.idle;
      }
      rethrow;
    }
  }

  /// Splits [widget.subtitle] around [widget.email] so the email segment can
  /// be rendered bold. Falls back to a single span when email is absent or not
  /// found in the subtitle.
  List<TextSpan> _buildSubtitleSpans() {
    final subtitle = widget.subtitle;
    final email = widget.email;
    if (email == null || email.isEmpty || !subtitle.contains(email)) {
      return [TextSpan(text: subtitle)];
    }
    final parts = subtitle.split(email);
    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i]));
      }
      if (i < parts.length - 1) {
        spans.add(
          TextSpan(
            text: email,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countdownStyle = StoryTextStyles.bodyMedium(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final resendStyle = StoryTextStyles.bodyMedium(
      color: theme.brightness == Brightness.dark
          ? const Color(0xFFEDEEF0)
          : StoryColors.lightForeground,
    ).copyWith(fontWeight: FontWeight.bold);
    final successStyle = StoryTextStyles.bodyMedium(color: StoryColors.success);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: StoryTextStyles.headingLarge(
            color: StoryColors.foregroundOf(theme.brightness),
          ).copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: StorySpacing.xs),
        Text.rich(
          TextSpan(
            style: StoryTextStyles.bodyMedium(
              color: StoryColors.foregroundOf(theme.brightness),
            ),
            children: _buildSubtitleSpans(),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ListenableBuilder(
          listenable: _feedbackListenable,
          builder: (context, _) {
            final slot = _countdownSlot.value;
            return StoryPinInput(
              key: _pinKey,
              hasError: _error.value != null,
              hasSuccess: slot == _CountdownSlot.success,
              enabled: slot == _CountdownSlot.idle,
              onChanged: _handleChanged,
            );
          },
        ),
        ListenableBuilder(
          listenable: _error,
          builder: (context, _) {
            final error = _error.value;
            if (error == null || error.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error,
                style: StoryTextStyles.bodySmall(
                  color: StoryColors.destructive,
                ),
                textAlign: TextAlign.start,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Center(
          child: ListenableBuilder(
            listenable: _countdownSlot,
            builder: (context, _) {
              final slot = _countdownSlot.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Keep countdown state alive while verifying / success.
                  Opacity(
                    opacity: slot == _CountdownSlot.idle ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: slot != _CountdownSlot.idle,
                      child: CountdownText(
                        formatter: widget.countdownFormatter,
                        resendLabel: widget.resendLabel,
                        countdownStyle: countdownStyle,
                        resendStyle: resendStyle,
                        onResend: widget.onResend,
                      ),
                    ),
                  ),
                  if (slot == _CountdownSlot.verifying)
                    Text(widget.verifyingLabel, style: countdownStyle),
                  if (slot == _CountdownSlot.success)
                    Text(_successMessage ?? '', style: successStyle),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
