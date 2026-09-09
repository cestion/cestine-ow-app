import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/story_l10n.dart';
import '../../provider/app_providers.dart';
import '../../styles/story_spacing.dart';

/// Horizontal scrollable category filter tabs.
///
/// Fetches tags from the API and displays them dynamically.
/// The first tab is always "All" (no filter).
class TheaterCategoryTabs extends ConsumerWidget {
  final String? selectedTagId;
  final ValueChanged<String?> onSelected;

  const TheaterCategoryTabs({
    super.key,
    required this.selectedTagId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final tagsAsync = ref.watch(dramaTagsProvider);

    final tags = tagsAsync.value ?? [];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 1 + tags.length, // +1 for "All" tab
        itemBuilder: (context, index) {
          // First tab is always "All"
          if (index == 0) {
            final isActive = selectedTagId == null;
            return GestureDetector(
              onTap: () => onSelected(null),
              child: Container(
                margin: const EdgeInsets.only(right: StorySpacing.lg),
                alignment: Alignment.center,
                child: Text(
                  l10n.theaterCategoryAll,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          // Dynamic tags from API
          final tag = tags[index - 1];
          final tagId = tag.id ?? '';
          final tagName = tag.name ?? '';
          final isActive = selectedTagId == tagId;

          return GestureDetector(
            onTap: () => onSelected(tagId),
            child: Container(
              margin: const EdgeInsets.only(right: StorySpacing.lg),
              alignment: Alignment.center,
              child: Text(
                tagName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
