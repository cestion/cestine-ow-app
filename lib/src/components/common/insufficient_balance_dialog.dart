import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_channel.dart';
import '../../l10n/story_l10n.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../iap/iap_buy_sheet.dart';

/// Insufficient balance prompt dialog (Figma「余额不足」).
///
/// Layout matches the design: centered title, a two-line detail block and a
/// ghost-cancel / filled-recharge button row. Colors resolve per brightness:
///
/// | part        | light            | dark             |
/// |-------------|------------------|------------------|
/// | surface     | `#FFFFFF`        | `#111113`        |
/// | title/body  | `#1C2024`        | `#EDEDF0`        |
/// | prompt      | `#60646C`        | `#B0B4BA`        |
/// | recharge bg | `#212225`        | `#FFFFFF`        |
/// | recharge fg | `#FFFFFF`        | `#111113`        |
class InsufficientBalanceDialog extends StatelessWidget {
  /// Currency/token symbol, e.g. `USDC`.
  final String currency;

  /// Shortfall amount (number only), e.g. `10`.
  final String amount;

  /// Recharge (primary) action label.
  final String confirmLabel;

  /// Cancel (ghost) action label.
  final String cancelLabel;

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isLoading;

  /// Custom title; defaults to the localized「余额不足」.
  final String? title;

  /// Custom first detail line; defaults to the localized
  /// `{currency} 余额不足，你还差 {amount} {currency}`.
  final String? detail;

  /// Custom second prompt line; defaults to「是否前往充值？」.
  final String? prompt;

  const InsufficientBalanceDialog({
    super.key,
    required this.currency,
    required this.amount,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onCancel,
    required this.onConfirm,
    this.isLoading = false,
    this.title,
    this.detail,
    this.prompt,
  });

  /// Shows the dialog and resolves to `true` when the user confirms.
  ///
  /// When [onConfirm] is omitted, confirming navigates to the deposit page
  /// ([RouteNames.deposit]) by default.
  static Future<bool?> show({
    required BuildContext context,
    required String currency,
    required String amount,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    WidgetRef? ref,
  }) {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => InsufficientBalanceDialog(
        currency: currency,
        amount: amount,
        confirmLabel: confirmLabel ?? l10n.insufficientBalanceRecharge,
        cancelLabel: cancelLabel ?? l10n.commonCancel,
        onCancel: () {
          Navigator.of(ctx).pop(false);
          onCancel?.call();
        },
        onConfirm: () {
          Navigator.of(ctx).pop(true);
          if (onConfirm != null) {
            onConfirm();
          } else if (AppChannel.isStore && ref != null) {
            showIapBuySheet(context, ref: ref);
          } else {
            navigator.pushNamed(RouteNames.deposit);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final foreground = StoryColors.contentTextOf(brightness);
    final promptColor = StoryColors.actorIssueCurrentPriceTextOf(brightness);

    return Dialog(
      backgroundColor: StoryColors.whiteToDarkOf(brightness),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 343),
        child: Padding(
          padding: const EdgeInsets.all(StorySpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title ?? l10n.insufficientBalanceTitle,
                textAlign: TextAlign.center,
                style: StoryTextStyles.titleMedium(color: foreground).copyWith(
                  fontSize: 18,
                  height: 26 / 18,
                  letterSpacing: -0.04,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: StorySpacing.lg),
              Column(
                children: [
                  Text(
                    detail ?? l10n.insufficientBalanceDetail(currency, amount),
                    textAlign: TextAlign.center,
                    style: StoryTextStyles.bodyMedium(color: foreground).copyWith(
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                    ),
                  ),
                  const SizedBox(height: StorySpacing.xs),
                  Text(
                    prompt ?? l10n.insufficientBalancePrompt,
                    textAlign: TextAlign.center,
                    style: StoryTextStyles.bodyMedium(color: promptColor).copyWith(
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StorySpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: cancelLabel,
                      onTap: isLoading ? null : onCancel,
                      backgroundColor: Colors.transparent,
                      foregroundColor: foreground,
                    ),
                  ),
                  const SizedBox(width: StorySpacing.md),
                  Expanded(
                    child: _DialogButton(
                      label: confirmLabel,
                      onTap: isLoading ? null : onConfirm,
                      backgroundColor: brightness == Brightness.dark
                          ? StoryColors.privyDarkNormal
                          : StoryColors.privyLightNormal,
                      foregroundColor: brightness == Brightness.dark
                          ? StoryColors.privyDarkForeground
                          : StoryColors.privyLightForeground,
                      loading: isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool loading;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.xxl,
          vertical: StorySpacing.md,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StoryTextStyles.labelLarge(
                  color: foregroundColor,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
