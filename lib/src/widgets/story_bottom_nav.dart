import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../foundation/locale_controller.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';

class StoryBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCreateTap;

  /// When true, paint the bar with dark-theme colors regardless of the
  /// ambient [ThemeData] (recommend feed is an immersive black surface).
  final bool forceDark;

  const StoryBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCreateTap,
    this.forceDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = forceDark
        ? Brightness.dark
        : Theme.of(context).brightness;
    final navItems = [
      (
        pageIndex: 0,
        label: context.l10n.navHome,
        svg: 'assets/tabbar/nav_home.svg',
        selectedSvg: 'assets/tabbar/nav_home_s.svg',
      ),
      (
        pageIndex: 1,
        label: context.l10n.navNft,
        svg: 'assets/tabbar/nav_role_ip.svg',
        selectedSvg: 'assets/tabbar/nav_role_ip_s.svg',
      ),
      (
        pageIndex: 2,
        label: context.l10n.navMy,
        svg: 'assets/tabbar/nav_agent.svg',
        selectedSvg: 'assets/tabbar/nav_agent_s.svg',
      ),
      (
        pageIndex: 3,
        label: context.l10n.navProfile,
        svg: 'assets/tabbar/nav_me.svg',
        selectedSvg: 'assets/tabbar/nav_me_s.svg',
      ),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: ColoredBox(
          color: StoryColors.cardOf(brightness).withValues(alpha: 0.95),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: StorySpacing.bottomNavHeight,
              child: Row(
                children: [
                  _NavItem(
                    pageIndex: navItems[0].pageIndex,
                    activeIndex: currentIndex,
                    label: navItems[0].label,
                    svg: navItems[0].svg,
                    selectedSvg: navItems[0].selectedSvg,
                    brightness: brightness,
                    onTap: onTap,
                  ),
                  _NavItem(
                    pageIndex: navItems[1].pageIndex,
                    activeIndex: currentIndex,
                    label: navItems[1].label,
                    svg: navItems[1].svg,
                    selectedSvg: navItems[1].selectedSvg,
                    brightness: brightness,
                    onTap: onTap,
                  ),
                  _CreateItem(onTap: onCreateTap),
                  _NavItem(
                    pageIndex: navItems[2].pageIndex,
                    activeIndex: currentIndex,
                    label: navItems[2].label,
                    svg: navItems[2].svg,
                    selectedSvg: navItems[2].selectedSvg,
                    brightness: brightness,
                    onTap: onTap,
                  ),
                  _NavItem(
                    pageIndex: navItems[3].pageIndex,
                    activeIndex: currentIndex,
                    label: navItems[3].label,
                    svg: navItems[3].svg,
                    selectedSvg: navItems[3].selectedSvg,
                    brightness: brightness,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int pageIndex;
  final int activeIndex;
  final String label;
  final String svg;
  final String selectedSvg;
  final Brightness brightness;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.pageIndex,
    required this.activeIndex,
    required this.label,
    required this.svg,
    required this.selectedSvg,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = pageIndex == activeIndex;
    final iconAsset = active ? selectedSvg : svg;
    final color = active
        ? StoryColors.foregroundOf(brightness)
        : StoryColors.mutedForegroundOf(brightness);
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: GestureDetector(
          key: ValueKey('bottom_nav_tab_$pageIndex'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(pageIndex),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 3, 4, 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  iconAsset,
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: StoryTextStyles.bottomNavLabel(
                    active: active,
                    brightness: brightness,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateItem extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: context.l10n.createDramaSubmit,
        child: GestureDetector(
          key: const ValueKey('bottom_nav_create'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: SvgPicture.asset(
              'assets/tabbar/nav_add.svg',
              width: 42,
              height: 42,
            ),
          ),
        ),
      ),
    );
  }
}
