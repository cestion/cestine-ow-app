import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../foundation/locale_controller.dart';
import '../../provider/app_providers.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';

import '../../widgets/story_avatar.dart';

/// Search input bar with left avatar and teal border.
class SearchInputBar extends ConsumerWidget {
  final TextEditingController inputController;
  final Future<void> Function(String) onSubmit;
  final ValueChanged<String> onChanged;
  final String keyword;
  final VoidCallback? onAvatarTap;

  const SearchInputBar({
    super.key,
    required this.inputController,
    required this.onSubmit,
    required this.onChanged,
    required this.keyword,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final profile = ref.watch(authControllerProvider.select((c) => c.profile));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.screenHorizontal,
        vertical: StorySpacing.sm,
      ),
      color: isDark ? const Color(0xFF0F1115) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Left user avatar (taps to return to previous page or triggers callback)
            GestureDetector(
              onTap: onAvatarTap ?? () => Navigator.of(context).pop(),
              child: StoryAvatar(
                imageUrl: profile?.avatarUrl,
                userId: profile?.userId ?? profile?.id,
                fallbackText: profile?.nickname ?? profile?.email,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            // Right search input box
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2228)
                      : StoryColors.lightMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: StoryColors.brandTeal),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.search,
                      size: 20,
                      color: isDark
                          ? StoryColors.onOverlaySubtle
                          : StoryColors.lightTertiaryText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        controller: inputController,
                        onSubmitted: onSubmit,
                        onChanged: onChanged,
                        textInputAction: TextInputAction.search,
                        style: StoryTextStyles.bodyMedium(
                          color: isDark
                              ? StoryColors.onOverlay
                              : StoryColors.footer,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.searchHint,
                          hintStyle: StoryTextStyles.bodyMedium(
                            color: isDark
                                ? StoryColors.onOverlay.withValues(alpha: 0.3)
                                : StoryColors.lightTertiaryText,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    if (keyword.isNotEmpty)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: isDark
                              ? StoryColors.onOverlaySubtle
                              : StoryColors.lightTertiaryText,
                        ),
                        onPressed: () {
                          inputController.clear();
                          ref.read(searchControllerProvider.notifier).clear();
                        },
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search history list with clear button.
class SearchHistoryList extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onHistoryTap;
  final VoidCallback onClearHistory;

  const SearchHistoryList({
    super.key,
    required this.history,
    required this.onHistoryTap,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (history.isEmpty) {
      return Center(
        child: Text(l10n.searchPlaceholder, style: StoryTextStyles.bodySmall()),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.searchHistory, style: StoryTextStyles.headingMedium()),
            TextButton(
              onPressed: onClearHistory,
              child: Text(l10n.searchClear),
            ),
          ],
        ),
        const SizedBox(height: StorySpacing.sm),
        Wrap(
          spacing: StorySpacing.sm,
          children: history
              .map(
                (k) => ActionChip(
                  label: Text(k),
                  onPressed: () => onHistoryTap(k),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
