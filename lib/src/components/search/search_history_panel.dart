import 'package:flutter/material.dart';

import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';

/// Recent search list with per-row delete.
///
/// Figma `655:104742`: outer `px-8 py-12`, title / rows add another `px-8`
/// so text and trailing icons sit 16px from the screen edges.
class SearchHistoryPanel extends StatelessWidget {
  final String title;
  final String? clearLabel;
  final VoidCallback? onClear;
  final List<String> items;
  final ValueChanged<String> onSelect;
  final ValueChanged<String>? onRemove;

  const SearchHistoryPanel({
    super.key,
    required this.title,
    required this.items,
    required this.onSelect,
    this.clearLabel,
    this.onClear,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StorySpacing.sm,
        StorySpacing.md,
        StorySpacing.sm,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StorySpacing.sm,
              StorySpacing.sm,
              StorySpacing.sm,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w400,
                      color: muted,
                    ),
                  ),
                ),
                if (clearLabel != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: muted),
                        const SizedBox(width: 4),
                        Text(
                          clearLabel!,
                          style: TextStyle(
                            fontSize: 16,
                            height: 24 / 16,
                            fontWeight: FontWeight.w400,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: StorySpacing.base),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () => onSelect(item),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: StorySpacing.sm,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              height: 24 / 16,
                              fontWeight: FontWeight.w400,
                              color: fg,
                            ),
                          ),
                        ),
                        const SizedBox(width: StorySpacing.sm),
                        if (onRemove != null)
                          GestureDetector(
                            onTap: () => onRemove!(item),
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: Icon(Icons.close, size: 18, color: muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
