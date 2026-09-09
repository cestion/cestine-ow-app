import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../foundation/locale_controller.dart';
import '../provider/app_providers.dart';
import '../styles/story_colors.dart';
import '../styles/story_text_styles.dart';
import '../widgets/widgets.dart';

/// 语言选择页 — 还原 Figma 语言列表。
class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  // 韩语翻译未就绪，暂不在语言列表展示（l10n 资源保留，随时可恢复）。
  static const List<({String label, Locale locale})> _languages = [
    (label: 'English', locale: Locale('en', 'US')),
    (label: '日本語', locale: Locale('ja', 'JP')),
    (label: 'Türkçe', locale: Locale('tr', 'TR')),
    (label: 'Tiếng Việt', locale: Locale('vi', 'VN')),
    (label: 'Español', locale: Locale('es', 'ES')),
    (label: '简体中文', locale: Locale('zh', 'CN')),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(appLocaleProvider);

    return AppScaffold(
      title: l10n.settingsLanguage,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _languages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final item = _languages[index];
          return _LanguageRow(
            label: item.label,
            selected: item.locale.languageCode == current.languageCode,
            onTap: () => StoryLocaleController.instance.setLocale(item.locale),
          );
        },
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = selected
        ? StoryColors.brandTeal
        : StoryColors.foregroundOf(brightness);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: StoryTextStyles.bodyLarge(color: color).copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, color: StoryColors.brandTeal, size: 20),
          ],
        ),
      ),
    );
  }
}
