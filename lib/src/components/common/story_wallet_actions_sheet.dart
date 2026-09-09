import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';

/// 钱包操作类型。
enum WalletAction { deposit, withdraw }

/// 「充值 / 提现」钱包操作 Bottom Sheet（Figma V2 UI）。
///
/// 设计要点：
/// - Sheet 背景：暗 #111113 / 亮 #FFFFFF
/// - 顶部拖拽把手 48×4（暗 #4F5359 / 亮 #C3C5CE）
/// - STORY 标题 18px 粗体
/// - 两个通栏按钮（钱包图标 + 18px 文案）：充值 / 提现
///
/// 独立组件，默认点击后自动关闭并跳转 /deposit、/withdraw；
/// 可通过 [onDeposit] / [onWithdraw] 覆盖行为。
class StoryWalletActionsSheet {
  StoryWalletActionsSheet._();

  static Future<WalletAction?> show({
    required BuildContext context,
    String title = 'STORY',
    String? depositLabel,
    String? withdrawLabel,
    VoidCallback? onDeposit,
    VoidCallback? onWithdraw,
  }) {
    final l10n = context.l10n;
    final resolvedDeposit = depositLabel ?? l10n.drawerDeposit;
    final resolvedWithdraw = withdrawLabel ?? l10n.drawerWithdraw;

    void handle(
      BuildContext sheetContext,
      WalletAction action,
      VoidCallback? custom,
    ) {
      Navigator.of(sheetContext).pop(action);
      if (custom != null) {
        custom();
        return;
      }
      Navigator.of(context).pushNamed(
        action == WalletAction.deposit
            ? RouteNames.deposit
            : RouteNames.withdraw,
      );
    }

    return showModalBottomSheet<WalletAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: StoryColors.overlayMedium,
      builder: (ctx) {
        final brightness = Theme.of(ctx).brightness;
        final isDark = brightness == Brightness.dark;
        final contentColor = StoryColors.contentTextOf(brightness);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? StoryColors.darkBackground : StoryColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: StorySpacing.base,
            right: StorySpacing.base,
            top: 10,
            bottom: MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? StoryColors.darkButtonDisabled
                      : StoryColors.buttonDisabledForeground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: StorySpacing.lg),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: contentColor,
                ),
              ),
              const SizedBox(height: StorySpacing.base),
              _ActionButton(
                label: resolvedDeposit,
                iconAsset: 'assets/wallet/deposit.svg',
                onTap: () =>
                    handle(ctx, WalletAction.deposit, onDeposit),
              ),
              const SizedBox(height: StorySpacing.md),
              _ActionButton(
                label: resolvedWithdraw,
                iconAsset: 'assets/wallet/withdraw.svg',
                onTap: () =>
                    handle(ctx, WalletAction.withdraw, onWithdraw),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.iconAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final contentColor = StoryColors.contentTextOf(brightness);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: isDark
                ? StoryColors.darkButtonBg
                : StoryColors.lightSheetSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  contentColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: StorySpacing.sm),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
