import 'package:flutter/material.dart';

import '../../../styles/story_colors.dart';
import '../../../utils/validators.dart';
import '../../../widgets/widgets.dart';

/// Step 1 of OTP login: email entry.
///
/// Owns its own email-validity + error [ValueNotifier]s so the parent
/// LoginPage does not rebuild when the user types or when an email error
/// is set/cleared. Calls [onSubmit] when the "send code" button is tapped.
class EmailInputSection extends StatefulWidget {
  final String label;
  final String hintText;
  final String sendLabel;
  final String sendingLabel;
  final bool isSending;
  final Future<void> Function(String email) onSubmit;

  const EmailInputSection({
    super.key,
    required this.label,
    required this.hintText,
    required this.sendLabel,
    required this.sendingLabel,
    required this.isSending,
    required this.onSubmit,
  });

  @override
  State<EmailInputSection> createState() => EmailInputSectionState();
}

class EmailInputSectionState extends State<EmailInputSection> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ValueNotifier<bool> _isValid = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _error = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onChanged);
    _emailController.dispose();
    _focusNode.dispose();
    _isValid.dispose();
    _error.dispose();
    super.dispose();
  }

  void _onChanged() {
    final email = _emailController.text.trim();
    final valid = isValidEmail(email);
    if (_isValid.value != valid) _isValid.value = valid;
    if (_error.value != null) _error.value = null;
  }

  Future<void> _handleSend() async {
    await widget.onSubmit(_emailController.text.trim());
  }

  /// Exposed so the parent can set an error from the send-code response.
  void setError(String? message) {
    _error.value = message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            height: 22 / 15,
            color: StoryColors.foregroundOf(theme.brightness),
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<String?>(
          valueListenable: _error,
          builder: (context, error, _) {
            return ListenableBuilder(
              listenable: _focusNode,
              builder: (context, _) {
                return TextField(
                  controller: _emailController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  cursorColor: StoryColors.foregroundOf(theme.brightness),
                  style: TextStyle(
                    color: StoryColors.foregroundOf(theme.brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 24 / 16,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: StoryColors.mutedForegroundOf(theme.brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 24 / 16,
                    ),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light
                        ? Colors.white
                        : StoryColors.darkBackground,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: error != null
                            ? StoryColors.destructive
                            : StoryColors.dividerOf(theme.brightness),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: error != null
                            ? StoryColors.destructive
                            : StoryColors.dividerOf(theme.brightness),
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: StoryColors.destructive,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                );
              },
            );
          },
        ),
        ValueListenableBuilder<String?>(
          valueListenable: _error,
          builder: (context, error, _) {
            if (error == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                error,
                style: const TextStyle(
                  color: StoryColors.destructive,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 16 / 12,
                  letterSpacing: 0.04,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        ValueListenableBuilder<bool>(
          valueListenable: _isValid,
          builder: (context, isValid, _) {
            return StoryButton(
              height: 56,
              borderRadius: BorderRadius.circular(12),
              label: widget.isSending ? widget.sendingLabel : widget.sendLabel,
              block: true,
              style: StoryButtonStyle.privy,
              loading: widget.isSending,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 24 / 16,
              ),
              onPressed: widget.isSending || !isValid ? null : _handleSend,
            );
          },
        ),
      ],
    );
  }
}
