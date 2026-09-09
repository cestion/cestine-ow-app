import 'package:flutter/material.dart';

import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';

class SecondaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onPressed == null;
    final border = disabled
        ? StoryColors.borderOf(theme.brightness)
        : StoryColors.borderOf(theme.brightness);
    final fg = disabled
        ? StoryColors.buttonDisabledForeground
        : StoryColors.foregroundOf(theme.brightness);
    final content = Container(
      height: 44,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: border),
      ),
      child: Text(label, style: StoryTextStyles.labelLarge(color: fg)),
    );
    if (disabled) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: content,
      ),
    );
  }
}
