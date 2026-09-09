import 'package:flutter/material.dart';

import '../../styles/story_colors.dart';

/// Personal-center scoped colors from Figma `392:119984` / `392:123026`.
///
/// Kept local to profile — dark `Text/secondary` (#B0B4BA) differs from global
/// [StoryColors.mutedForegroundOf] (#8B8D98).
abstract final class ProfileColors {
  static const Color darkSecondaryText = Color(0xFFB0B4BA);
  static const Color darkCardSurface = Color(0xFF212225);
  static const Color darkThirdlySurface = Color(0xFF171718);
  static const Color darkOutlineBorder = Color(0xFF363A3F);
  static const Color darkAvatarEditBg = Color(0xFFEDEEF0);
  static const Color darkAvatarEditIcon = Color(0xFF111113);

  static Color secondaryText(Brightness b) => b == Brightness.dark
      ? darkSecondaryText
      : StoryColors.lightMutedForeground;

  static Color balanceCardBg(Brightness b) =>
      b == Brightness.dark ? darkCardSurface : StoryColors.lightSheetSecondary;

  static Color addressPillBg(Brightness b) => b == Brightness.dark
      ? darkThirdlySurface
      : StoryColors.lightSheetSecondary;

  static Color walletCardBg(Brightness b) =>
      b == Brightness.dark ? darkThirdlySurface : StoryColors.lightMuted;

  static Color walletActionBg(Brightness b) =>
      b == Brightness.dark ? darkCardSurface : Colors.white;

  static Color outlineBorder(Brightness b) =>
      b == Brightness.dark ? darkOutlineBorder : StoryColors.lightDivider;

  static Color dramaCardBg(Brightness b) =>
      b == Brightness.dark ? darkCardSurface : StoryColors.lightCard;

  static Color dramaCardBorder(Brightness b) =>
      b == Brightness.dark ? darkOutlineBorder : StoryColors.lightDivider;

  /// Figma 个人中心列表画布：亮色纯白，暗色使用页面主背景。
  static Color listBackground(Brightness b) =>
      b == Brightness.dark ? StoryColors.darkBackground : Colors.white;

  static Color avatarEditBg(Brightness b) =>
      b == Brightness.dark ? darkAvatarEditBg : StoryColors.darkButtonBg;

  static Color avatarEditIcon(Brightness b) =>
      b == Brightness.dark ? darkAvatarEditIcon : Colors.white;

  static Color avatarEditBorder(Brightness b) => listBackground(b);

  /// Figma `ip头像` on cover overlay — `Border/secondary-contrast`.
  static const Color coverAvatarRing = Color(0xFFD9D9E0);
  static const double coverAvatarRingWidth = 1.0;

  /// Figma `2400:151305`: follow CTA uses the brand primary in both themes.
  static Color followPrimaryBg(Brightness b) => StoryColors.brandTeal;

  static Color followPrimaryFg(Brightness b) => Colors.white;

  static Color followSecondaryBg(Brightness b) =>
      b == Brightness.dark ? darkCardSurface : StoryColors.lightSheetSecondary;

  static Color followSecondaryFg(Brightness b) => StoryColors.foregroundOf(b);

  /// Outlined profile follow states — Figma `723:87210` (dark) / `872:176514` (light).
  /// 已关注 / 回关 / 互相关注: 1.5px `Border/secondary`, `Text/primary`, no fill.
  static const Color darkFollowOutlinedFg = Color(0xFFEDEEF0);
  static const double followOutlinedBorderWidth = 1.5;

  static Color followOutlinedBorder(Brightness b) => outlineBorder(b);

  static Color followOutlinedFg(Brightness b) =>
      b == Brightness.dark ? darkFollowOutlinedFg : StoryColors.lightForeground;
}
