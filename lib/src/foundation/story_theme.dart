import 'package:flutter/material.dart';

import '../styles/story_colors.dart';
import '../styles/story_text_styles.dart';

const _storyTabBarTheme = TabBarThemeData(
  overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
  splashFactory: NoSplash.splashFactory,
);

// ─── Custom design tokens (non-Material-standard colors) ──────────────────

/// Custom design tokens exposed as [ThemeExtension] so every widget can read
/// them via `Theme.of(context).extension<StoryCustomColors>()`.
class StoryCustomColors extends ThemeExtension<StoryCustomColors> {
  final Color success;
  final Color warning;
  final Color info;
  final Color pending;
  final Color star;
  final Color likeActive;
  final Color bookmarkActive;
  final Color border;
  final Color divider;
  final Color surfaceMuted;
  final Color footer;
  final Color footerForeground;
  final Color appBarBackground;

  const StoryCustomColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.pending,
    required this.star,
    required this.likeActive,
    required this.bookmarkActive,
    required this.border,
    required this.divider,
    required this.surfaceMuted,
    required this.footer,
    required this.footerForeground,
    required this.appBarBackground,
  });

  static const light = StoryCustomColors(
    success: StoryColors.success,
    warning: StoryColors.warning,
    info: StoryColors.info,
    pending: StoryColors.pending,
    star: StoryColors.star,
    likeActive: StoryColors.likeActive,
    bookmarkActive: StoryColors.bookmarkActive,
    border: StoryColors.lightBorder,
    divider: StoryColors.lightDivider,
    surfaceMuted: StoryColors.lightMuted,
    footer: StoryColors.footer,
    footerForeground: StoryColors.footerForeground,
    appBarBackground: StoryColors.lightAppBarBg,
  );

  static const dark = StoryCustomColors(
    success: StoryColors.success,
    warning: StoryColors.warning,
    info: StoryColors.info,
    pending: StoryColors.pending,
    star: StoryColors.star,
    likeActive: StoryColors.likeActive,
    bookmarkActive: StoryColors.bookmarkActive,
    border: StoryColors.darkBorder,
    divider: StoryColors.darkDivider,
    surfaceMuted: StoryColors.darkMuted,
    footer: StoryColors.footer,
    footerForeground: StoryColors.footerForeground,
    appBarBackground: StoryColors.darkBackground,
  );

  @override
  StoryCustomColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? pending,
    Color? star,
    Color? likeActive,
    Color? bookmarkActive,
    Color? border,
    Color? divider,
    Color? surfaceMuted,
    Color? footer,
    Color? footerForeground,
    Color? appBarBackground,
  }) => StoryCustomColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    pending: pending ?? this.pending,
    star: star ?? this.star,
    likeActive: likeActive ?? this.likeActive,
    bookmarkActive: bookmarkActive ?? this.bookmarkActive,
    border: border ?? this.border,
    divider: divider ?? this.divider,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    footer: footer ?? this.footer,
    footerForeground: footerForeground ?? this.footerForeground,
    appBarBackground: appBarBackground ?? this.appBarBackground,
  );

  @override
  StoryCustomColors lerp(ThemeExtension<StoryCustomColors>? other, double t) {
    if (other is! StoryCustomColors) return this;
    return StoryCustomColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      star: Color.lerp(star, other.star, t)!,
      likeActive: Color.lerp(likeActive, other.likeActive, t)!,
      bookmarkActive: Color.lerp(bookmarkActive, other.bookmarkActive, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      footer: Color.lerp(footer, other.footer, t)!,
      footerForeground: Color.lerp(
        footerForeground,
        other.footerForeground,
        t,
      )!,
      appBarBackground: Color.lerp(
        appBarBackground,
        other.appBarBackground,
        t,
      )!,
    );
  }
}

// ─── Convenience extensions on BuildContext ───────────────────────────────

extension StoryThemeX on BuildContext {
  StoryCustomColors get storyColors =>
      Theme.of(this).extension<StoryCustomColors>()!;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

TextTheme _buildStoryTextTheme(ColorScheme colorScheme, Brightness brightness) {
  return TextTheme(
    displayLarge: StoryTextStyles.displayLarge(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    displayMedium: StoryTextStyles.displayMedium(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    displaySmall: StoryTextStyles.headingLarge(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    headlineLarge: StoryTextStyles.headingLarge(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    headlineMedium: StoryTextStyles.headingMedium(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    headlineSmall: StoryTextStyles.titleLarge(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    titleLarge: StoryTextStyles.titleLarge(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    titleMedium: StoryTextStyles.titleMedium(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    titleSmall: StoryTextStyles.labelLarge(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    bodyLarge: StoryTextStyles.bodyLarge(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    bodyMedium: StoryTextStyles.bodyMedium(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    bodySmall: StoryTextStyles.bodySmall(
      color: colorScheme.onSurfaceVariant,
      brightness: brightness,
    ),
    labelLarge: StoryTextStyles.labelLarge(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    labelMedium: StoryTextStyles.labelMedium(
      color: colorScheme.onSurface,
      brightness: brightness,
    ),
    labelSmall: StoryTextStyles.labelSmall(
      color: colorScheme.onSurfaceVariant,
      brightness: brightness,
    ),
  );
}

ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colorScheme) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      disabledBackgroundColor: colorScheme.surfaceContainerHighest,
      disabledForegroundColor: colorScheme.onSurfaceVariant,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: StoryTextStyles.labelLarge(color: colorScheme.onPrimary),
    ),
  );
}

TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme) {
  return TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: StoryTextStyles.labelLarge(color: colorScheme.primary),
    ),
  );
}

InputDecorationTheme _buildInputDecorationTheme(ColorScheme colorScheme) {
  final borderRadius = BorderRadius.circular(12);
  final outlineBorder = OutlineInputBorder(
    borderRadius: borderRadius,
    borderSide: BorderSide(color: colorScheme.outline),
  );

  return InputDecorationTheme(
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: StoryTextStyles.bodyMedium(
      color: colorScheme.onSurfaceVariant,
      brightness: colorScheme.brightness,
    ),
    labelStyle: StoryTextStyles.bodyMedium(
      color: colorScheme.onSurfaceVariant,
      brightness: colorScheme.brightness,
    ),
    floatingLabelStyle: StoryTextStyles.labelMedium(
      color: colorScheme.primary,
      brightness: colorScheme.brightness,
    ),
    enabledBorder: outlineBorder,
    focusedBorder: outlineBorder.copyWith(
      borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
    ),
    errorBorder: outlineBorder.copyWith(
      borderSide: BorderSide(color: colorScheme.error),
    ),
    focusedErrorBorder: outlineBorder.copyWith(
      borderSide: BorderSide(color: colorScheme.error, width: 1.5),
    ),
  );
}

// ─── ThemeData factories ─────────────────────────────────────────────────

ThemeData buildLightTheme() {
  // ignore: prefer_const_constructors — ColorScheme.light is a factory, not const
  final colorScheme = ColorScheme.light(
    primary: StoryColors.brandTeal,
    secondary: StoryColors.brandTeal,
    onSurface: StoryColors.lightForeground,
    surfaceContainerHighest: StoryColors.lightMuted,
    onSurfaceVariant: StoryColors.lightMutedForeground,
    error: StoryColors.destructive,
    outline: StoryColors.lightBorder,
    outlineVariant: StoryColors.lightDivider,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    scaffoldBackgroundColor: StoryColors.lightCard,
    cardColor: StoryColors.lightCard,
    dividerColor: StoryColors.lightDivider,
    textTheme: _buildStoryTextTheme(colorScheme, Brightness.light),
    elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
    textButtonTheme: _buildTextButtonTheme(colorScheme),
    inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
    tabBarTheme: _storyTabBarTheme,
    extensions: const [StoryCustomColors.light],
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  // ignore: prefer_const_constructors — ColorScheme.dark is a factory, not const
  final colorScheme = ColorScheme.dark(
    primary: StoryColors.brandTeal,
    secondary: StoryColors.brandTeal,
    onSurface: StoryColors.darkForeground,
    surfaceContainerHighest: StoryColors.darkMuted,
    onSurfaceVariant: StoryColors.darkMutedForeground,
    error: StoryColors.destructive,
    outline: StoryColors.darkBorder,
    outlineVariant: StoryColors.darkDivider,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    scaffoldBackgroundColor: StoryColors.darkStoryBg,
    cardColor: StoryColors.darkBackground,
    dividerColor: StoryColors.darkDivider,
    textTheme: _buildStoryTextTheme(colorScheme, Brightness.dark),
    elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
    textButtonTheme: _buildTextButtonTheme(colorScheme),
    inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
    tabBarTheme: _storyTabBarTheme,
    extensions: const [StoryCustomColors.dark],
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    ),
  );
}
