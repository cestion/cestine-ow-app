import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../provider/theater_home_tab_provider.dart';

/// Top-level home tabs: 短剧 | 推荐.
///
/// [overlay] uses white labels for immersive recommend chrome; otherwise
/// follows the current theme foreground colors.
class TheaterHomeTabs extends StatelessWidget {
  final TheaterHomeTab selected;
  final ValueChanged<TheaterHomeTab> onSelected;
  final bool overlay;

  const TheaterHomeTabs({
    super.key,
    required this.selected,
    required this.onSelected,
    this.overlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final active = overlay
        ? StoryColors.onOverlay
        : StoryColors.foregroundOf(brightness);
    final inactive = overlay
        ? StoryColors.onOverlayMuted
        : StoryColors.mutedForegroundOf(brightness);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TabLabel(
          label: context.l10n.theaterTabShortDrama,
          selected: selected == TheaterHomeTab.shortDrama,
          activeColor: active,
          inactiveColor: inactive,
          onTap: () => onSelected(TheaterHomeTab.shortDrama),
        ),
        const SizedBox(width: StorySpacing.lg),
        _TabLabel(
          label: context.l10n.theaterTabRecommend,
          selected: selected == TheaterHomeTab.recommend,
          activeColor: active,
          inactiveColor: inactive,
          onTap: () => onSelected(TheaterHomeTab.recommend),
        ),
      ],
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _TabLabel({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Keep the label optically centered with the side icons; the underline
    // is overlaid so it does not shift the text upward.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        // Match [TheaterHomeChrome.contentHeight] so labels share the bar center.
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                height: 1.0,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 2,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 3,
                  width: selected ? 20 : 0,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
