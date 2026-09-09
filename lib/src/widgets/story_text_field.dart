import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';

enum StoryTextFieldVariant { standard, form }

class StoryTextField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final double labelGap;
  final TextStyle? labelStyle;
  final bool enabled;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final EdgeInsetsGeometry? contentPadding;
  final StoryTextFieldVariant variant;
  final String? errorText;
  final bool showErrorMessage;

  const StoryTextField({
    super.key,
    this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.maxLengthEnforcement,
    this.labelGap = StorySpacing.xs,
    this.labelStyle,
    this.enabled = true,
    this.style,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.contentPadding,
    this.variant = StoryTextFieldVariant.standard,
    this.errorText,
    this.showErrorMessage = true,
  });

  static const BorderRadius _formBorderRadius = BorderRadius.all(
    Radius.circular(16),
  );

  static InputDecoration formDecoration(
    BuildContext context, {
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    BoxConstraints? suffixIconConstraints,
    EdgeInsetsGeometry? contentPadding,
    String counterText = '',
    bool hasError = false,
  }) {
    final brightness = Theme.of(context).brightness;
    final borderColor = hasError
        ? StoryColors.destructive
        : StoryColors.createActorInputBorderOf(brightness);
    final focusedBorderColor = hasError
        ? StoryColors.destructive
        : StoryColors.createActorInputFocusBorderOf(brightness);
    final border = OutlineInputBorder(
      borderRadius: _formBorderRadius,
      borderSide: BorderSide(color: borderColor),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: _formBorderRadius,
      borderSide: BorderSide(color: focusedBorderColor),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        color: StoryColors.createActorInputHintOf(brightness),
      ),
      filled: true,
      fillColor: StoryColors.createActorInputBgOf(brightness),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIconConstraints,
      border: border,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      disabledBorder: border,
      contentPadding: contentPadding ?? const EdgeInsets.all(StorySpacing.base),
      counterText: counterText,
    );
  }

  static Widget wrapFormTheme(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
      child: child,
    );
  }

  InputDecoration _decoration(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final hasError = errorText != null && errorText!.isNotEmpty;
    if (variant == StoryTextFieldVariant.form) {
      return formDecoration(
        context,
        hint: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        suffixIconConstraints: suffixIconConstraints,
        contentPadding: contentPadding,
        hasError: hasError,
      );
    }
    return InputDecoration(
      hintText: hint,
      hintStyle: StoryTextStyles.bodyMedium(
        color: StoryColors.mutedForegroundOf(brightness),
      ),
      filled: true,
      fillColor: StoryColors.mutedOf(brightness),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIconConstraints,
      border: const OutlineInputBorder(
        borderRadius: StoryRadius.brMd,
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: StoryRadius.brMd,
        borderSide: BorderSide(color: StoryColors.brandTeal, width: 1.5),
      ),
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: StorySpacing.md,
            vertical: StorySpacing.md,
          ),
      counterText: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLabel = label != null && label!.isNotEmpty;

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      maxLength: maxLength,
      maxLengthEnforcement: maxLengthEnforcement,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: style ?? theme.textTheme.bodyLarge,
      decoration: _decoration(context),
    );

    final effectiveField = variant == StoryTextFieldVariant.form
        ? StoryTextField.wrapFormTheme(context, field)
        : field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLabel) ...[
          Text(label!, style: labelStyle ?? StoryTextStyles.labelMedium()),
          SizedBox(height: labelGap),
        ],
        effectiveField,
        if (showErrorMessage && errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: StorySpacing.xs),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: StoryColors.destructive,
            ),
          ),
        ],
      ],
    );
  }
}
