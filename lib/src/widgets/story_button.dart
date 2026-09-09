import 'package:flutter/material.dart';

import '../foundation/story_theme.dart';
import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';

enum StoryButtonStyle { primary, secondary, outline, ghost, destructive, privy }

class StoryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final StoryButtonStyle style;
  final bool loading;
  final bool block;
  final IconData? icon;
  final double? minWidth;
  final double? height;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const StoryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = StoryButtonStyle.primary,
    this.loading = false,
    this.block = false,
    this.icon,
    this.minWidth,
    this.height = 44,
    this.gradient,
    this.borderRadius,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;
    final colors = _resolveColors(context, isDisabled);

    final inner = Container(
      constraints: minWidth != null
          ? BoxConstraints(minWidth: minWidth!)
          : null,
      height: height,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: StorySpacing.base),
      decoration: BoxDecoration(
        color: gradient != null ? null : backgroundColor ?? colors.background,
        gradient: gradient,
        border: colors.border != null && gradient == null
            ? Border.all(color: colors.border!)
            : null,
        borderRadius: borderRadius ?? StoryRadius.brMd,
      ),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textColor ?? colors.foreground, size: 18),
                  const SizedBox(width: StorySpacing.xs),
                ],
                Text(
                  label,
                  style:
                      textStyle?.copyWith(
                        color:
                            textColor ?? textStyle?.color ?? colors.foreground,
                      ) ??
                      StoryTextStyles.labelLarge(
                        color: textColor ?? colors.foreground,
                      ),
                ),
              ],
            ),
    );

    final content = isDisabled
        ? inner
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: borderRadius ?? StoryRadius.brMd,
              child: inner,
            ),
          );

    if (block) {
      return SizedBox(width: double.infinity, child: content);
    }
    return content;
  }

  _ButtonColors _resolveColors(BuildContext context, bool disabled) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final customColors = theme.extension<StoryCustomColors>();
    final surfaceMuted = customColors?.surfaceMuted ?? StoryColors.lightMuted;
    final onSurface = theme.colorScheme.onSurface;

    if (disabled) {
      if (style == StoryButtonStyle.privy) {
        return _ButtonColors(
          background: isLight
              ? StoryColors.privyLightDisabled
              : StoryColors.privyDarkDisabled,
          foreground: isLight
              ? StoryColors.privyLightForeground
              : StoryColors.privyDarkForeground,
        );
      }
      return _ButtonColors(
        background: surfaceMuted,
        foreground: StoryColors.buttonDisabledForeground,
      );
    }
    return switch (style) {
      StoryButtonStyle.primary => const _ButtonColors(
        background: StoryColors.brandTeal,
        foreground: StoryColors.brandTealForeground,
      ),
      StoryButtonStyle.secondary => _ButtonColors(
        background: surfaceMuted,
        foreground: onSurface,
      ),
      StoryButtonStyle.outline => const _ButtonColors(
        background: Colors.transparent,
        foreground: StoryColors.brandTeal,
        border: StoryColors.brandTeal,
      ),
      StoryButtonStyle.ghost => _ButtonColors(
        background: Colors.transparent,
        foreground: onSurface,
      ),
      StoryButtonStyle.destructive => const _ButtonColors(
        background: StoryColors.destructive,
        foreground: StoryColors.onOverlay,
      ),
      StoryButtonStyle.privy => _ButtonColors(
        background: isLight
            ? StoryColors.privyLightNormal
            : StoryColors.privyDarkNormal,
        foreground: isLight
            ? StoryColors.privyLightForeground
            : StoryColors.privyDarkForeground,
      ),
    };
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color? border;

  const _ButtonColors({
    required this.background,
    required this.foreground,
    this.border,
  });
}
