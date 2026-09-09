// NOTE: StoryTextStyles provides static TextStyle factory methods that mirror
// the styles in StoryThemeTextStyles (lib/src/foundation/theme.dart).
// StoryThemeData in that file is the *canonical source of truth* for the active
// theme.  When you need text styles inside the widget tree and want them to
// react to runtime theme changes, use `Theme.of(context)` and
// `StoryCustomColors` (lib/src/foundation/story_theme.dart) instead of calling
// these factories directly.  StoryTextStyles stays for compile-time convenience
// and contexts that cannot access BuildContext.
import 'package:flutter/material.dart';

import 'story_colors.dart';

class StoryTextStyles {
  StoryTextStyles._();

  static TextStyle _make({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.5,
    double letterSpacing = 0,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle displayLarge({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(
    size: 32,
    weight: FontWeight.w700,
    height: 1.2,
    color: color ?? StoryColors.foregroundOf(brightness),
  );
  static TextStyle displayMedium({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(
    size: 24,
    weight: FontWeight.w700,
    height: 1.3,
    color: color ?? StoryColors.foregroundOf(brightness),
  );
  static TextStyle headingLarge({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(
    size: 20,
    weight: FontWeight.w600,
    height: 1.35,
    color: color ?? StoryColors.foregroundOf(brightness),
  );
  static TextStyle headingMedium({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(
    size: 16,
    weight: FontWeight.w600,
    height: 1.4,
    color: color ?? StoryColors.foregroundOf(brightness),
  );
  static TextStyle titleLarge({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(
    size: 16,
    weight: FontWeight.w500,
    height: 1.4,
    color: color ?? StoryColors.foregroundOf(brightness),
  );
  static TextStyle titleMedium({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(
    weight: FontWeight.w500,
    height: 1.45,
    color: color ?? StoryColors.foregroundOf(brightness),
  );
  static TextStyle bodyLarge({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(color: color ?? StoryColors.foregroundOf(brightness));
  static TextStyle bodyMedium({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(color: color ?? StoryColors.foregroundOf(brightness));
  static TextStyle bodySmall({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(
    size: 12,
    color: color ?? StoryColors.mutedForegroundOf(brightness),
  );
  static TextStyle labelLarge({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(
    weight: FontWeight.w600,
    color: color ?? StoryColors.foregroundOf(brightness),
  );
  static TextStyle labelMedium({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(
    size: 12,
    weight: FontWeight.w600,
    color: color ?? StoryColors.foregroundOf(brightness),
  );
  static TextStyle labelSmall({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(
    size: 10,
    weight: FontWeight.w500,
    letterSpacing: 0.08,
    color: color ?? StoryColors.mutedForegroundOf(brightness),
  );

  static TextStyle caption({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => _make(
    size: 11,
    color: color ?? StoryColors.mutedForegroundOf(brightness),
  );

  static TextStyle bottomNavLabel({
    required bool active,
    required Brightness brightness,
  }) {
    final color = active
        ? StoryColors.foregroundOf(brightness)
        : StoryColors.mutedForegroundOf(brightness);
    return _make(size: 10, height: 1.3, letterSpacing: 0.08, color: color);
  }

  static TextStyle amount({required bool positive}) => _make(
    weight: FontWeight.w600,
    color: positive ? StoryColors.success : StoryColors.destructive,
  );
}
