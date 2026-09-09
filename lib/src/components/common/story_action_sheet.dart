import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../widgets/story_switch.dart';

enum StoryActionSheetStyle {
  /// Floating iOS-style capsules with margin
  floating,

  /// Card-style anchored to the bottom with grouped list rows (player long-press)
  card,

  /// Figma grouped menu: drag handle, centered title, action card and cancel.
  groupedMenu,
}

class StoryActionSheet {
  StoryActionSheet._();

  /// Show a standard action sheet (bottom sheet with title + items).
  ///
  /// For [StoryActionSheetStyle.card], pass [groups] to render multiple
  /// rounded sections (as in the player long-press menu). When [groups] is
  /// null, [items] are shown as a single section.
  ///
  /// [StoryActionSheetStyle.groupedMenu] maps [title], [items], and the
  /// cancel parameters to the Figma grouped-menu presentation.
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    List<ActionSheetItem<T>> items = const [],
    List<List<ActionSheetItem<T>>>? groups,
    bool showCancel = true,
    String cancelLabel = '',
    StoryActionSheetStyle style = StoryActionSheetStyle.floating,
  }) {
    assert(
      style != StoryActionSheetStyle.groupedMenu || items.isNotEmpty,
      'A grouped menu requires at least one action item.',
    );
    final l10n = context.l10n;
    final resolvedCancel = cancelLabel.isNotEmpty
        ? cancelLabel
        : l10n.commonCancel;

    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      // Keep the player route underneath so recommend/feed surfaces stay mounted.
      useRootNavigator: true,
      isScrollControlled: true,
      barrierColor: style == StoryActionSheetStyle.floating
          ? null
          : StoryColors.overlayMedium,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final brightness = theme.brightness;
        final isDark = brightness == Brightness.dark;

        if (style == StoryActionSheetStyle.card) {
          return _CardActionSheet<T>(
            title: title,
            groups: groups ?? [items],
            showCancel: showCancel,
            cancelLabel: resolvedCancel,
            isDark: isDark,
          );
        }

        if (style == StoryActionSheetStyle.groupedMenu) {
          return _GroupedMenuActionSheet<T>(
            title: title,
            items: items,
            showCancel: showCancel,
            cancelLabel: resolvedCancel,
          );
        }

        // Floating iOS Style (default)
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.sm,
              vertical: StorySpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: StoryColors.cardOf(brightness),
                    borderRadius: StoryRadius.brLg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            StorySpacing.base,
                            StorySpacing.base,
                            StorySpacing.base,
                            StorySpacing.xs,
                          ),
                          child: Text(title, style: StoryTextStyles.caption()),
                        ),
                        Divider(
                          height: 1,
                          color: StoryColors.borderOf(brightness),
                        ),
                      ],
                      ...List.generate(items.length, (i) {
                        final item = items[i];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.of(ctx).pop(item.value);
                                item.onTap?.call(item.value);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: StorySpacing.md,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (item.icon != null) ...[
                                      Icon(
                                        item.icon,
                                        size: 20,
                                        color: item.destructive
                                            ? StoryColors.destructive
                                            : StoryColors.brandTeal,
                                      ),
                                      const SizedBox(width: StorySpacing.sm),
                                    ],
                                    Text(
                                      item.label,
                                      style: StoryTextStyles.titleMedium(
                                        color: item.destructive
                                            ? StoryColors.destructive
                                            : StoryColors.foregroundOf(
                                                brightness,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (i < items.length - 1)
                              Divider(
                                height: 1,
                                color: StoryColors.borderOf(brightness),
                                indent: StorySpacing.xl,
                                endIndent: StorySpacing.xl,
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                if (showCancel) ...[
                  const SizedBox(height: StorySpacing.sm),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    borderRadius: StoryRadius.brLg,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: StorySpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: StoryColors.cardOf(brightness),
                        borderRadius: StoryRadius.brLg,
                      ),
                      child: Center(
                        child: Text(
                          resolvedCancel,
                          style: StoryTextStyles.titleMedium(
                            color: StoryColors.mutedForegroundOf(brightness),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Reusable parameter-driven menu sheet matching Figma `2400:151303`.
class _GroupedMenuActionSheet<T> extends StatelessWidget {
  const _GroupedMenuActionSheet({
    required this.title,
    required this.items,
    required this.showCancel,
    required this.cancelLabel,
  });

  final String? title;
  final List<ActionSheetItem<T>> items;
  final bool showCancel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final sheetBackground = isDark
        ? StoryColors.darkBackground
        : StoryColors.lightSheetSecondary;
    final groupBackground = isDark
        ? StoryColors.darkMuted
        : StoryColors.lightCard;
    final dividerColor = isDark
        ? StoryColors.darkDivider
        : StoryColors.lightSheetSecondary;
    final foreground = StoryColors.foregroundOf(brightness);

    return Container(
      decoration: BoxDecoration(
        color: sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            child: Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: StoryColors.buttonDisabledForegroundOf(brightness),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: 12),
            Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: 18,
                height: 26 / 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.04,
              ),
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              color: groupBackground,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      Divider(height: 0.5, thickness: 0.5, color: dividerColor),
                    _GroupedMenuRow<T>(item: items[i]),
                  ],
                ],
              ),
            ),
          ),
          if (showCancel) ...[
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: StoryColors.dividerOf(brightness),
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: Center(
                    child: Text(
                      cancelLabel,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupedMenuRow<T> extends StatelessWidget {
  const _GroupedMenuRow({required this.item});

  final ActionSheetItem<T> item;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = item.destructive
        ? StoryColors.destructive
        : StoryColors.foregroundOf(brightness);

    return InkWell(
      onTap: () {
        Navigator.of(context).pop(item.value);
        item.onTap?.call(item.value);
      },
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Center(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardActionSheet<T> extends StatefulWidget {
  final String? title;
  final List<List<ActionSheetItem<T>>> groups;
  final bool showCancel;
  final String cancelLabel;
  final bool isDark;

  const _CardActionSheet({
    required this.title,
    required this.groups,
    required this.showCancel,
    required this.cancelLabel,
    required this.isDark,
  });

  @override
  State<_CardActionSheet<T>> createState() => _CardActionSheetState<T>();
}

class _CardActionSheetState<T> extends State<_CardActionSheet<T>> {
  late final Map<String, bool> _switchStates;

  @override
  void initState() {
    super.initState();
    _switchStates = {};
    for (final group in widget.groups) {
      for (final item in group) {
        if (item.isSwitch) {
          _switchStates[_switchKey(item)] = item.switchValue!;
        }
      }
    }
  }

  String _switchKey(ActionSheetItem<T> item) => '${item.label}_${item.value}';

  @override
  Widget build(BuildContext context) {
    final sheetBg = widget.isDark
        ? StoryColors.darkElevatedSurface
        : StoryColors.lightSheetSecondary;
    final groupBg = widget.isDark
        ? StoryColors.darkFillSecondary
        : StoryColors.lightCard;
    final dragHandleColor = widget.isDark
        ? const Color(0xFF3A3A3C)
        : StoryColors.lightSeparatorIos;
    final dividerColor = widget.isDark
        ? const Color(0xFF3A3A3C)
        : StoryColors.lightSeparatorIos;
    final labelColor = widget.isDark
        ? StoryColors.onOverlay
        : StoryColors.darkElevatedSurface;
    final iconColor = widget.isDark
        ? const Color(0xFFEDEEF0)
        : StoryColors.darkElevatedSurface;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          StorySpacing.lg,
          StorySpacing.md,
          StorySpacing.lg,
          StorySpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: dragHandleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: StorySpacing.lg),
            if (widget.title != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: StorySpacing.md),
                child: Text(
                  widget.title!,
                  style: StoryTextStyles.bodyMedium(
                    color: StoryColors.mutedForegroundOf(
                      widget.isDark ? Brightness.dark : Brightness.light,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            for (var g = 0; g < widget.groups.length; g++) ...[
              if (g > 0) const SizedBox(height: StorySpacing.md),
              _ActionGroupCard(
                background: groupBg,
                dividerColor: dividerColor,
                children: [
                  for (var i = 0; i < widget.groups[g].length; i++)
                    _buildRow(
                      context,
                      widget.groups[g][i],
                      labelColor: labelColor,
                      iconColor: iconColor,
                    ),
                ],
              ),
            ],
            if (widget.showCancel) ...[
              const SizedBox(height: StorySpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: dividerColor),
                    foregroundColor: labelColor,
                    minimumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.cancelLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    ActionSheetItem<T> item, {
    required Color labelColor,
    required Color iconColor,
  }) {
    const rowMinHeight = 52.0;
    final labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.25,
      color: item.destructive ? StoryColors.destructive : labelColor,
    );

    final leading = _buildLeading(item, iconColor);

    if (item.isSwitch) {
      final value = _switchStates[_switchKey(item)] ?? item.switchValue!;
      return SizedBox(
        height: rowMinHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
          child: Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: StorySpacing.md),
              ],
              Expanded(child: Text(item.label, style: labelStyle)),
              StorySwitch(
                value: value,
                onChanged: (next) {
                  setState(() => _switchStates[_switchKey(item)] = next);
                  item.onSwitchChanged!(next);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(item.value);
          item.onTap?.call(item.value);
        },
        child: SizedBox(
          height: rowMinHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading,
                  const SizedBox(width: StorySpacing.md),
                ],
                Expanded(child: Text(item.label, style: labelStyle)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildLeading(ActionSheetItem<T> item, Color iconColor) {
    if (item.svgAsset != null) {
      return SvgPicture.asset(
        item.svgAsset!,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }
    if (item.icon != null) {
      return Icon(
        item.icon,
        size: 24,
        color: item.destructive ? StoryColors.destructive : iconColor,
      );
    }
    return null;
  }
}

class _ActionGroupCard extends StatelessWidget {
  final Color background;
  final Color dividerColor;
  final List<Widget> children;

  const _ActionGroupCard({
    required this.background,
    required this.dividerColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.5,
                color: dividerColor,
                indent: StorySpacing.base,
                endIndent: StorySpacing.base,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class ActionSheetItem<T> {
  final String label;
  final T? value;
  final IconData? icon;
  final String? svgAsset;
  final bool destructive;
  final void Function(T? value)? onTap;

  /// When set, renders as a label + switch row instead of a button.
  /// Toggling does not dismiss the sheet.
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;

  const ActionSheetItem({
    required this.label,
    this.value,
    this.icon,
    this.svgAsset,
    this.destructive = false,
    this.onTap,
    this.switchValue,
    this.onSwitchChanged,
  });

  bool get isSwitch => switchValue != null && onSwitchChanged != null;
}
