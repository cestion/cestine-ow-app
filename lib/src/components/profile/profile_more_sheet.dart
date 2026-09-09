import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../foundation/locale_controller.dart';
import '../../provider/app_providers.dart';
import '../../routes/route_names.dart';
import '../common/story_action_sheet.dart';
import '../common/story_toast.dart';
import '../../foundation/navigator.dart';

/// Top-right grid entry for profile — hosts menus moved off the main surface.
class ProfileMoreSheet {
  ProfileMoreSheet._();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isLoggedIn = ref.read(authControllerProvider).isLoggedIn;

    return StoryActionSheet.show<void>(
      context: context,
      title: l10n.followMoreTitle,
      style: StoryActionSheetStyle.card,
      items: [
        ActionSheetItem<void>(
          label: l10n.profileEarnings,
          icon: Icons.savings_outlined,
          onTap: (_) {
            context.storyPush(RouteNames.income);
          },
        ),
        ActionSheetItem<void>(
          label: l10n.profileWatchHistory,
          icon: Icons.history,
          onTap: (_) {
            context.storyPush(RouteNames.watchHistory);
          },
        ),
        ActionSheetItem<void>(
          label: l10n.profileCreatorCatalog,
          icon: Icons.group_outlined,
          onTap: (_) {
            context.storyPush(RouteNames.creators);
          },
        ),
        ActionSheetItem<void>(
          label: l10n.profileLanguage,
          icon: Icons.language,
          onTap: (_) {
            StoryActionSheet.show<Locale>(
              context: context,
              title: l10n.languageSelectTitle,
              cancelLabel: l10n.commonCancel,
              items: [
                ActionSheetItem(
                  label: l10n.languageChinese,
                  value: const Locale('zh', 'CN'),
                  onTap: (loc) {
                    if (loc != null) {
                      StoryLocaleController.instance.setLocale(loc);
                    }
                  },
                ),
                ActionSheetItem(
                  label: l10n.languageEnglish,
                  value: const Locale('en', 'US'),
                  onTap: (loc) {
                    if (loc != null) {
                      StoryLocaleController.instance.setLocale(loc);
                    }
                  },
                ),
              ],
            );
          },
        ),
        ActionSheetItem<void>(
          label: l10n.drawerSettings,
          icon: Icons.settings_outlined,
          onTap: (_) {
            context.storyPush(RouteNames.settings);
          },
        ),
        ActionSheetItem<void>(
          label: l10n.profileAboutUs,
          icon: Icons.info_outline,
          onTap: (_) {
            context.storyPush(RouteNames.about);
          },
        ),
        if (isLoggedIn)
          ActionSheetItem<void>(
            label: l10n.profileLogout,
            icon: Icons.logout,
            destructive: true,
            onTap: (_) async {
              await ref.read(authControllerProvider.notifier).logout();
              if (!context.mounted) return;
              StoryToast.show(context, message: l10n.profileLogoutSuccess);
            },
          ),
      ],
    );
  }
}
