import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../repositories/actor_repository.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';

/// Sort filter row for the NFT actor collection page.
///
/// Figma / IP 市场: 片酬 · 价格 (升降序). Default sort is 片酬.
class NftSortFilters extends StatelessWidget {
  final ActorCollectionSort currentSort;
  final ValueChanged<ActorCollectionSort> onSortChanged;

  const NftSortFilters({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _IpSortPill(
              label: l10n.nftSortLv1Pay,
              isActive: currentSort == ActorCollectionSort.computingPower,
              onTap: () => onSortChanged(ActorCollectionSort.computingPower),
              trailing: _DownChevronIcon(
                color: _IpSortPill.foregroundOf(
                  context,
                  isActive: currentSort == ActorCollectionSort.computingPower,
                ),
              ),
            ),
            const SizedBox(width: StorySpacing.sm),
            _IpSortPill(
              label: l10n.nftSortLowestPrice,
              isActive: currentSort.isPrice,
              onTap: () => onSortChanged(ActorCollectionSort.priceAsc),
              trailing: _PriceSortChevronIcon(
                color: _IpSortPill.foregroundOf(
                  context,
                  isActive: currentSort.isPrice,
                ),
                isDescending: currentSort == ActorCollectionSort.priceDesc,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma pill: px-16 py-6, rounded-80, 14/20 bold.
class _IpSortPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final Widget trailing;
  final VoidCallback onTap;

  const _IpSortPill({
    required this.label,
    required this.isActive,
    required this.trailing,
    required this.onTap,
  });

  static Color backgroundOf(BuildContext context, {required bool isActive}) {
    final brightness = Theme.of(context).brightness;
    if (isActive) {
      return brightness == Brightness.dark
          ? Colors.white
          : StoryColors.darkButtonBg;
    }
    return StoryColors.sheetSecondaryOf(brightness);
  }

  static Color foregroundOf(BuildContext context, {required bool isActive}) {
    final brightness = Theme.of(context).brightness;
    if (isActive) {
      return brightness == Brightness.dark
          ? StoryColors.privyDarkForeground
          : Colors.white;
    }
    return StoryColors.foregroundOf(brightness);
  }

  @override
  Widget build(BuildContext context) {
    final fg = foregroundOf(context, isActive: isActive);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundOf(context, isActive: isActive),
          borderRadius: const BorderRadius.all(Radius.circular(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(width: 4),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Text-link sort button used by the agency workshop.
class NftSortButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDesc;
  final bool showPriceDirection;
  final VoidCallback onTap;

  const NftSortButton({
    super.key,
    required this.label,
    required this.isActive,
    this.isDesc = false,
    this.showPriceDirection = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = StoryColors.foregroundOf(theme.brightness);
    final inactiveColor = StoryColors.mutedForegroundOf(theme.brightness);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.md,
          vertical: StorySpacing.sm,
        ),
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                height: 1,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            if (showPriceDirection) ...[
              const SizedBox(width: 6),
              _PriceSortChevronIcon(
                color: isActive
                    ? StoryColors.priceSortIconSelectedOf(theme.brightness)
                    : StoryColors.priceSortIconUnselectedOf(theme.brightness),
                isDescending: isDesc,
                inactiveColor: StoryColors.priceSortIconUnselectedOf(
                  theme.brightness,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 价格排序双箭头：升序上亮、降序下亮（web `IconFilterSort`）。
class _PriceSortChevronIcon extends StatelessWidget {
  final Color color;
  final bool isDescending;
  final Color? inactiveColor;

  const _PriceSortChevronIcon({
    required this.color,
    required this.isDescending,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final dim = inactiveColor ?? color.withValues(alpha: 0.46);
    final upColor = isDescending ? dim : color;
    final downColor = isDescending ? color : dim;

    return SizedBox(
      width: 12,
      height: 12,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/common/fliter_up.svg',
            width: 10,
            height: 4,
            colorFilter: ColorFilter.mode(upColor, BlendMode.srcIn),
          ),
          const SizedBox(height: 1),
          SvgPicture.asset(
            'assets/common/fliter_down.svg',
            width: 10,
            height: 4,
            colorFilter: ColorFilter.mode(downColor, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }
}

/// 片酬 pill 的下箭头（web `IconFilterChevronDown`）。
class _DownChevronIcon extends StatelessWidget {
  final Color color;

  const _DownChevronIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/common/fliter_down.svg',
      width: 12,
      height: 6,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
