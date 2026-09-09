import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../model/work_content_type.dart';
import '../../../styles/story_colors.dart';
import '../../../widgets/story_tab_bar.dart';

enum WatchHistoryTabsVariant { underline, profileFilter }

/// Shared “短剧 / 作品” selector used by all watch-history surfaces.
class WatchHistoryTabs extends StatelessWidget implements PreferredSizeWidget {
  const WatchHistoryTabs({
    super.key,
    required this.controller,
    required this.foreground,
    this.variant = WatchHistoryTabsVariant.underline,
  });

  final TabController controller;
  final Color foreground;
  final WatchHistoryTabsVariant variant;

  @override
  Size get preferredSize => const Size.fromHeight(42);

  @override
  Widget build(BuildContext context) {
    if (variant == WatchHistoryTabsVariant.profileFilter) {
      return _ProfileFilterTabs(controller: controller);
    }

    return SizedBox(
      height: preferredSize.height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: StoryTabBar(
            controller: controller,
            isScrollable: true,
            showDivider: false,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.only(right: 20),
            indicator: StoryTabIndicator(
              color: foreground,
              width: 16,
              borderRadius: 17,
            ),
            tabs: [
              Tab(height: 32, text: context.l10n.profileTabDramas),
              Tab(height: 32, text: context.l10n.profileTabWorks),
            ],
          ),
        ),
      ),
    );
  }
}

/// Matches the content-type filter used by the profile Favorites tab.
class _ProfileFilterTabs extends StatelessWidget {
  const _ProfileFilterTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final labels = <WorkContentType, String>{
      WorkContentType.shortDrama: context.l10n.profileTabDramas,
      WorkContentType.shortVideo: context.l10n.profileTabWorks,
    };
    const types = WorkContentType.values;

    return SizedBox(
      height: 42,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          itemCount: types.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final type = types[index];
            return _ProfileFilterChip(
              key: ValueKey<String>('watchHistory.tabs.profile.${type.name}'),
              label: labels[type]!,
              selected: controller.index == index,
              onTap: () => controller.animateTo(index),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileFilterChip extends StatelessWidget {
  const _ProfileFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final selectedBackground = brightness == Brightness.light
        ? StoryColors.darkButtonBg
        : StoryColors.foregroundOf(brightness);

    return Material(
      color: selected
          ? selectedBackground
          : StoryColors.actorHeroBadgeBgOf(brightness),
      borderRadius: const BorderRadius.all(Radius.circular(80)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(80)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? StoryColors.backgroundOf(brightness)
                  : StoryColors.foregroundOf(brightness),
              fontSize: 14,
              height: 20 / 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
