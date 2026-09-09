import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/story_colors.dart';

class StoryPinInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final bool hasError;
  final bool hasSuccess;

  /// When false, the field cannot gain focus and digits cannot be edited.
  final bool enabled;

  const StoryPinInput({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.hasError = false,
    this.hasSuccess = false,
    this.enabled = true,
  });

  @override
  State<StoryPinInput> createState() => StoryPinInputState();
}

class StoryPinInputState extends State<StoryPinInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode(canRequestFocus: widget.enabled);
    _controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(StoryPinInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _applyEnabled(widget.enabled);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyEnabled(bool enabled) {
    _focusNode.canRequestFocus = enabled;
    if (!enabled) {
      if (_focusNode.hasFocus) _focusNode.unfocus();
    }
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  /// Clears all digits and moves focus back to the input when [enabled].
  void reset() {
    if (!mounted) return;
    _controller.clear();
    widget.onChanged('');
    if (mounted) setState(() {});
    _requestFocusWhenEnabled();
  }

  void _requestFocusWhenEnabled() {
    void focus() {
      if (!mounted || !widget.enabled) return;
      _focusNode.canRequestFocus = true;
      _focusNode.requestFocus();
    }

    if (widget.enabled) {
      focus();
      return;
    }
    // Caller may flip [enabled] in the same frame (verify error → idle).
    WidgetsBinding.instance.addPostFrameCallback((_) => focus());
  }

  void _onControllerChanged() {
    final raw = _controller.text;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    if (clipped != raw) {
      _controller.value = TextEditingValue(
        text: clipped,
        selection: TextSelection.collapsed(offset: clipped.length),
      );
      return;
    }
    // Keep cells in sync even while locked; ignore parent notify when disabled
    // so a clear during verify→error cannot re-enter onChanged mid-lock.
    if (mounted) setState(() {});
    if (!widget.enabled) return;
    widget.onChanged(clipped);
  }

  void _requestFocus() {
    if (!widget.enabled) return;
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = _controller.text;
    final focusedIndex = code.length.clamp(0, widget.length - 1);
    final canFocus = widget.enabled;

    final normalBorderColor = StoryColors.dividerOf(theme.brightness);
    const activeBorderColor = StoryColors.info;
    const errorBorderColor = StoryColors.destructive;
    const successBorderColor = StoryColors.success;

    Color resolveBorderColor({required bool focused}) {
      if (widget.hasError) return errorBorderColor;
      if (widget.hasSuccess) return successBorderColor;
      return focused ? activeBorderColor : normalBorderColor;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canFocus ? _requestFocus : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Invisible field owns keyboard input so backspace clears digits
          // one-by-one (soft keyboard + hardware).
          //
          // Use [readOnly] (not TextField.enabled=false) so re-enabling after
          // a failed verify reliably restores typing / focus.
          SizedBox(
            width: 1,
            height: 1,
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: canFocus,
                readOnly: !canFocus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                enableInteractiveSelection: false,
                showCursor: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
          AutofillGroup(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, (index) {
                final digit = index < code.length ? code[index] : '';
                final focused =
                    canFocus &&
                    _focusNode.hasFocus &&
                    index == focusedIndex &&
                    code.length < widget.length;
                final filledFocused =
                    canFocus &&
                    _focusNode.hasFocus &&
                    code.length == widget.length &&
                    index == widget.length - 1;

                return Container(
                  width: 48,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StoryColors.cardOf(theme.brightness),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: resolveBorderColor(
                        focused: focused || filledFocused,
                      ),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    digit,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
