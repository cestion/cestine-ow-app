import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/app_channel.dart';
import '../../core/story_env.dart';
import '../../core/story_sdk.dart';
import '../../foundation/locale_controller.dart';
import '../../foundation/story_launcher.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../utils/format_number.dart';
import '../../widgets/widgets.dart';
import '../../components/components.dart';
import '../../foundation/navigator.dart';

class StoryDrawer extends ConsumerStatefulWidget {
  const StoryDrawer({super.key});

  @override
  ConsumerState<StoryDrawer> createState() => _StoryDrawerState();
}

class _StoryDrawerState extends ConsumerState<StoryDrawer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final isLoggedIn = ref.watch(
      authControllerProvider.select((c) => c.isLoggedIn),
    );
    final profile = ref.watch(authControllerProvider.select((c) => c.profile));
    final solanaAddress = ref.watch(
      authControllerProvider.select((c) => c.solanaAddress),
    );
    final walletBalance = ref.watch(onChainWalletBalanceProvider);
    final storyBalance = walletBalance.storyBalance;
    final usdcBalance = walletBalance.usdcBalance;
    final withdrawConfig = ref.watch(withdrawConfigProvider);

    void handlePageRouteNavigation(
      String route,
      bool requireLogin, {
      Map<String, dynamic>? arguments,
    }) {
      Navigator.of(context).pop(); // Close drawer
      if (requireLogin && !isLoggedIn) {
        unawaited(
          context.storyPush(RouteNames.login),
        );
        return;
      }
      unawaited(
        context.storyPush(route,
          arguments: arguments),
      );
    }

    final boxColor = isDark ? StoryColors.darkMuted : StoryColors.lightMuted;

    return Drawer(
      backgroundColor: StoryColors.backgroundOf(theme.brightness),
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header with Profile
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StorySpacing.screenHorizontal,
                vertical: StorySpacing.md,
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(); // close drawer
                  unawaited(
                    context.storyPush(isLoggedIn
                          ? RouteNames.publicProfile
                          : RouteNames.login),
                  );
                },
                child: Row(
                  children: [
                    isLoggedIn
                        ? StoryAvatar(
                            imageUrl: profile?.avatarUrl,
                            userId: profile?.userId ?? profile?.id,
                            fallbackText: profile?.nickname ?? profile?.email,
                            size: 48,
                          )
                        : SvgPicture.asset(
                            isDark
                                ? 'assets/common/avatar_d.svg'
                                : 'assets/common/avatar.svg',
                            width: 48,
                            height: 48,
                          ),
                    const SizedBox(width: StorySpacing.sm),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn
                                ? (profile?.nickname ??
                                      profile?.email ??
                                      'Story User')
                                : l10n.profileNotLoggedIn,
                            style: StoryTextStyles.headingMedium(
                              color: theme.colorScheme.onSurface,
                            ).copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isLoggedIn) ...[
                            const SizedBox(height: 2),
                            Text(
                              (profile?.nickname != null &&
                                      (profile?.nickname ?? '').isNotEmpty &&
                                      profile?.email != null &&
                                      (profile?.email ?? '').isNotEmpty
                                  ? profile!.email!
                                  : (solanaAddress.isNotEmpty
                                        ? '${solanaAddress.substring(0, 6)}...${solanaAddress.substring(solanaAddress.length - 4)}'
                                        : l10n.drawerEmailAccount)),
                              style: StoryTextStyles.bodySmall(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: StorySpacing.screenHorizontal,
                  vertical: StorySpacing.sm,
                ),
                children: [
                  if (isLoggedIn) ...[
                    // STORY balance row
                    _TokenRow(
                      symbol: 'STORY',
                      balance: storyBalance,
                      tokenConfig:
                          withdrawConfig.svmChainInfo?.tokens?['story'],
                      boxColor: boxColor,
                    ),
                    const SizedBox(height: StorySpacing.sm),
                    // USDC balance row
                    _TokenRow(
                      symbol: 'USDC',
                      balance: usdcBalance,
                      tokenConfig: withdrawConfig.svmChainInfo?.tokens?['usdc'],
                      boxColor: boxColor,
                      storePoints: true,
                    ),
                    const SizedBox(height: StorySpacing.md),
                    StoryButton(
                      label: l10n.drawerBuyStory,
                      style: StoryButtonStyle.outline,
                      block: true,
                      height: 40,
                      onPressed: () {
                        Navigator.of(context).pop();
                        final url = StorySdk.instance.config.env.buyStoryUrl;
                        StoryLauncher.openExternal(url);
                      },
                    ),
                    const SizedBox(height: StorySpacing.sm),
                    // Deposit and Withdraw Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StoryButton(
                          label: l10n.drawerDeposit,
                          minWidth: 131.5,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF05DF72),
                              Color(0xFF00BBA7),
                              Color(0xFF00B8DB),
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          textColor: Colors.white,
                          padding: const EdgeInsets.only(
                            top: 10,
                            right: 16,
                            bottom: 10,
                            left: 16,
                          ),
                          onPressed: () => handlePageRouteNavigation(
                            RouteNames.deposit,
                            true,
                          ),
                        ),
                        StoryButton(
                          label: l10n.drawerWithdraw,
                          style: StoryButtonStyle.outline,
                          minWidth: 131.5,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.only(
                            top: 10,
                            right: 16,
                            bottom: 10,
                            left: 16,
                          ),
                          onPressed: () => handlePageRouteNavigation(
                            RouteNames.withdraw,
                            true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: StorySpacing.sm),
                    const Divider(height: 1, thickness: 0.5),
                  ],

                  const SizedBox(height: StorySpacing.sm),
                  _MenuTile(
                    svgAsset: 'assets/drawer/user.svg',
                    label: l10n.drawerProfile,
                    onTap: () {
                      handlePageRouteNavigation(RouteNames.publicProfile, true);
                    },
                  ),
                  _MenuTile(
                    svgAsset: 'assets/drawer/referral.svg',
                    label: l10n.drawerInvite,
                    onTap: () {
                      handlePageRouteNavigation(RouteNames.invite, true);
                    },
                  ),
                  _MenuTile(
                    svgAsset: 'assets/drawer/token.svg',
                    label: l10n.profileEarnings,
                    onTap: () =>
                        handlePageRouteNavigation(RouteNames.income, true),
                  ),
                  _MenuTile(
                    svgAsset: 'assets/drawer/records.svg',
                    label: l10n.drawerTxHistory,
                    onTap: () {
                      if (!isLoggedIn) {
                        Navigator.of(context).pop(); // close drawer
                        context.storyPush(RouteNames.login);
                        return;
                      }
                      if (solanaAddress.isEmpty) {
                        StoryToast.error(context, l10n.incomeClaimNoWallet);
                        return;
                      }
                      Navigator.of(context).pop(); // close drawer
                      final env = StorySdk.instance.config.env;
                      final cluster = env.isProduction ? '' : '?cluster=devnet';
                      final url =
                          '${StoryEnv.solscanBaseUrl}/$solanaAddress$cluster';
                      StoryLauncher.openExternal(url);
                    },
                  ),
                  _MenuTile(
                    svgAsset: 'assets/drawer/dashboard.svg',
                    label: l10n.drawerFinanceDashboard,
                    onTap: () => handlePageRouteNavigation(
                      RouteNames.financeDashboard,
                      false,
                    ),
                  ),
                  if (!AppChannel.isStore)
                  _MenuTile(
                    svgAsset: 'assets/drawer/receipt.svg',
                    label: l10n.drawerWhitepaper,
                    onTap: () {
                      Navigator.of(context).pop(); // close drawer
                      final url = StorySdk.instance.config.env.whitepaperUrl;
                      StoryLauncher.openExternal(url);
                    },
                  ),
                  _MenuTile(
                    svgAsset: 'assets/drawer/settings.svg',
                    label: l10n.drawerSettings,
                    onTap: () =>
                        handlePageRouteNavigation(RouteNames.settings, false),
                  ),
                  if (isLoggedIn) ...[
                    _MenuTile(
                      svgAsset: 'assets/drawer/logout.svg',
                      label: l10n.profileLogout,
                      showChevron: false,
                      onTap: () {
                        StoryDialog.confirm(
                          context: context,
                          title: l10n.profileLogoutConfirm,
                          cancelLabel: l10n.commonCancel,
                          confirmLabel: l10n.commonConfirm,
                          onConfirm: () async {
                            Navigator.of(context).pop(); // close drawer
                            await ref
                                .read(authControllerProvider.notifier)
                                .logout();
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A balance row for a specific token (STORY / USDC) in the drawer.
class _TokenRow extends StatelessWidget {
  final String symbol;
  final double balance;
  final WalletToken? tokenConfig;
  final Color boxColor;
  final bool storePoints;

  const _TokenRow({
    required this.symbol,
    required this.balance,
    this.tokenConfig,
    required this.boxColor,
    this.storePoints = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStorePoints = storePoints && AppChannel.isStore;
    return Container(
      padding: const EdgeInsets.all(StorySpacing.md),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (isStorePoints)
            const IapPointIcon()
          else
            StoryTokenLogo(token: symbol, imageUrl: tokenConfig?.icon, size: 28),
          const SizedBox(width: StorySpacing.sm),
          Text(
            isStorePoints ? context.l10n.currency : symbol,
            style: StoryTextStyles.labelMedium(
              color: theme.colorScheme.onSurface,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            formatNumber(balance),
            style: StoryTextStyles.labelMedium(
              color: theme.colorScheme.onSurface,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String svgAsset;
  final String label;
  final VoidCallback onTap;
  final bool showChevron;

  const _MenuTile({
    required this.svgAsset,
    required this.label,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SvgPicture.asset(
        svgAsset,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          theme.colorScheme.onSurface,
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: showChevron
          ? SizedBox(
              width: 10,
              height: 20,
              child: SvgPicture.asset(
                'assets/drawer/arrow_right.svg',
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  BlendMode.srcIn,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
