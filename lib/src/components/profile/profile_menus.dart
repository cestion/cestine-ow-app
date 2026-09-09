import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../foundation/locale_controller.dart';
import '../../provider/app_providers.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../common/story_action_sheet.dart';
import 'profile_menu_item.dart';
import '../../foundation/navigator.dart';

/// Grouped menu section card containing a list of [ProfileMenuItem]s.
class ProfileMenuSection extends StatelessWidget {
  final List<Widget> children;

  const ProfileMenuSection({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.screenHorizontal,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StoryColors.cardOf(Theme.of(context).brightness),
          borderRadius: const BorderRadius.all(
            Radius.circular(StoryRadius.lgValue),
          ),
          border: Border.all(
            color: StoryColors.borderOf(Theme.of(context).brightness),
            width: 0.5,
          ),
        ),
        child: Column(children: children),
      ),
    );
  }
}

/// Menu shown when the user is logged in — wallet, earnings, NFT, favorites.
class ProfileLoggedInMenu extends ConsumerWidget {
  final int watchlistLength;

  const ProfileLoggedInMenu({super.key, required this.watchlistLength});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final solanaAddress = ref.watch(
      authControllerProvider.select((c) => c.solanaAddress),
    );

    return ProfileMenuSection(
      children: [
        ProfileMenuItem(
          icon: Icons.account_balance_wallet_outlined,
          label: l10n.profileMyWallet,
          subtitle: solanaAddress.isNotEmpty
              ? '${solanaAddress.substring(0, 6)}...${solanaAddress.substring(solanaAddress.length - 4)}'
              : l10n.profileWalletCreating,
          iconColor: StoryColors.brandTeal,
          showChevron: false,
        ),
        ProfileMenuItem(
          icon: Icons.savings_outlined,
          label: l10n.profileEarnings,
          iconColor: StoryColors.success,
          onTap: () => context.storyPush(RouteNames.income),
        ),
        ProfileMenuItem(
          icon: Icons.inventory_2_outlined,
          label: l10n.profileMyNft,
          iconColor: StoryColors.info,
          onTap: () {},
        ),
        ProfileMenuItem(
          icon: Icons.favorite_border,
          label: l10n.profileMyFavorites,
          value: '$watchlistLength',
          iconColor: StoryColors.likeActive,
          onTap: () {},
        ),
      ],
    );
  }
}

/// Menu shown when the user is not logged in — same items without wallet data.
class ProfileLoggedOutMenu extends StatelessWidget {
  final int watchlistLength;

  const ProfileLoggedOutMenu({super.key, required this.watchlistLength});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ProfileMenuSection(
      children: [
        ProfileMenuItem(
          icon: Icons.account_balance_wallet_outlined,
          label: l10n.profileMyWallet,
          iconColor: StoryColors.brandTeal,
          onTap: () {},
        ),
        ProfileMenuItem(
          icon: Icons.savings_outlined,
          label: l10n.profileEarnings,
          iconColor: StoryColors.success,
          onTap: () {},
        ),
        ProfileMenuItem(
          icon: Icons.inventory_2_outlined,
          label: l10n.profileMyNft,
          iconColor: StoryColors.info,
          onTap: () {},
        ),
        ProfileMenuItem(
          icon: Icons.favorite_border,
          label: l10n.profileMyFavorites,
          value: '$watchlistLength',
          iconColor: StoryColors.likeActive,
          onTap: () {},
        ),
      ],
    );
  }
}

/// Settings menu — watch history, creator catalog, identity, security, language.
class ProfileSettingsMenu extends StatelessWidget {
  const ProfileSettingsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ProfileMenuSection(
      children: [
        ProfileMenuItem(
          icon: Icons.history,
          label: l10n.profileWatchHistory,
          iconColor: StoryColors.info,
          onTap: () => context.storyPush(RouteNames.watchHistory),
        ),
        ProfileMenuItem(
          icon: Icons.group_outlined,
          label: l10n.profileCreatorCatalog,
          iconColor: StoryColors.brandTeal,
          onTap: () => context.storyPush(RouteNames.creators),
        ),
        ProfileMenuItem(
          icon: Icons.verified_outlined,
          label: l10n.profileIdentityAuth,
          iconColor: StoryColors.warning,
          onTap: () {},
        ),
        ProfileMenuItem(
          icon: Icons.security_outlined,
          label: l10n.profileAccountSecurity,
          onTap: () {},
        ),
        ProfileMenuItem(
          icon: Icons.language,
          label: l10n.profileLanguage,
          value: Localizations.localeOf(context).languageCode == 'zh'
              ? l10n.languageChinese
              : l10n.languageEnglish,
          onTap: () {
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
      ],
    );
  }
}

/// About menu — about us, help & feedback.
class ProfileAboutMenu extends StatelessWidget {
  const ProfileAboutMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ProfileMenuSection(
      children: [
        ProfileMenuItem(
          icon: Icons.info_outline,
          label: l10n.profileAboutUs,
          onTap: () => context.storyPush(RouteNames.about),
        ),
        ProfileMenuItem(
          icon: Icons.help_outline,
          label: l10n.profileHelpFeedback,
          onTap: () {},
        ),
      ],
    );
  }
}
