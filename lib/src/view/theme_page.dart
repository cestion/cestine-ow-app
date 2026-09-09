import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../foundation/theme_controller.dart';
import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../styles/story_colors.dart';
import '../styles/story_text_styles.dart';
import '../widgets/widgets.dart';

/// 外观主题设置页 — 系统 / 日间 / 夜间（横向三卡片）。
class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentMode = ref.watch(appThemeModeProvider);

    return AppScaffold(
      title: l10n.settingsTheme,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          // IntrinsicHeight + stretch: 文案换行时三张卡片仍保持等高。
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ThemeOptionCard(
                    icon: Icons.contrast,
                    label: l10n.settingsThemeSystem,
                    mode: ThemeMode.system,
                    currentMode: currentMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ThemeOptionCard(
                    icon: Icons.wb_sunny_outlined,
                    label: l10n.settingsThemeLight,
                    mode: ThemeMode.light,
                    currentMode: currentMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ThemeOptionCard(
                    icon: Icons.dark_mode_outlined,
                    label: l10n.settingsThemeDark,
                    mode: ThemeMode.dark,
                    currentMode: currentMode,
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

class _ThemeOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeMode mode;
  final ThemeMode currentMode;

  const _ThemeOptionCard({
    required this.icon,
    required this.label,
    required this.mode,
    required this.currentMode,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isSelected = mode == currentMode;
    final foreground = StoryColors.foregroundOf(brightness);

    return InkWell(
      onTap: () => StoryThemeController.instance.setThemeMode(mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: StoryColors.dividerOf(brightness),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: foreground),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: StoryTextStyles.bodyMedium(color: foreground),
            ),
            const SizedBox(height: 16),
            // Spacer 把指示器压到底部，长文案换行时三张卡片指示器仍对齐。
            const Spacer(),
            _Indicator(selected: isSelected, brightness: brightness),
          ],
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final bool selected;
  final Brightness brightness;

  const _Indicator({required this.selected, required this.brightness});

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: StoryColors.foregroundOf(brightness),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check,
          size: 15,
          color: StoryColors.backgroundOf(brightness),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: StoryColors.mutedForegroundOf(brightness),
          width: 1.5,
        ),
      ),
    );
  }
}
