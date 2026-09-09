import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import 'iap_point_icon.dart';

Color _cardColor(Brightness b) =>
    b == Brightness.dark ? StoryColors.darkBackground : StoryColors.lightCard;

Color _titleColor(Brightness b) =>
    b == Brightness.dark ? StoryColors.darkContentText : StoryColors.lightForeground;

/// 购买结果弹窗状态。
enum IapPurchaseDialogStatus { success, failure }

/// Shows the purchase-result dialog (Figma「购买成功」, light 796-147803 /
/// dark 822-152237). Success keeps the current layout; failure swaps the title
/// to「购买失败」and replaces the gained-points row with a plain-text failure
/// reason. Resolves when dismissed; [onDismiss] runs after close.
Future<void> showIapPurchaseResultDialog(
  BuildContext context, {
  required String grantedAmount,
  IapPurchaseDialogStatus status = IapPurchaseDialogStatus.success,
  String? failureReason,
  VoidCallback? onDismiss,
}) {
  final isSuccess = status == IapPurchaseDialogStatus.success;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final brightness = Theme.of(context).brightness;
      void close() {
        Navigator.of(dialogContext).pop();
        onDismiss?.call();
      }

      return Dialog(
        backgroundColor: _cardColor(brightness),
        shape: const RoundedRectangleBorder(borderRadius: StoryRadius.brXxl),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            StorySpacing.base,
            StorySpacing.base,
            StorySpacing.base,
            StorySpacing.base,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 结果徽章：成功 success_symbol / 失败 failure_symbol
              SvgPicture.asset(
                isSuccess
                    ? 'assets/iap/success_symbol.svg'
                    : 'assets/iap/failure_symbol.svg',
                width: 44,
                height: 44,
              ),
              const SizedBox(height: StorySpacing.base),
              // 标题：成功「购买成功」/ 失败「购买失败」
              Text(
                isSuccess
                    ? context.l10n.iapPurchaseSuccess
                    : context.l10n.iapPurchaseFailedTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: _titleColor(brightness),
                ),
              ),
              const SizedBox(height: StorySpacing.xs),
              // 成功：到账点数；失败：纯文本失败原因
              if (isSuccess)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const IapPointIcon(),
                    const SizedBox(width: StorySpacing.xs),
                    Text(
                      context.l10n.iapGainedPoints(grantedAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: _titleColor(brightness),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  failureReason ?? context.l10n.iapPurchaseFailed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: StoryColors.pending, // #F3733F
                  ),
                ),
              const SizedBox(height: StorySpacing.base),
              // 底部确认按钮
              _DialogButton(
                label: context.l10n.iapSuccessConfirm,
                brightness: brightness,
                onTap: close,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.brightness,
    required this.onTap,
  });

  final String label;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Figma「确定」为 ghost 按钮：透明底 + 标题色文字 + 分隔线描边
    final fg = _titleColor(brightness);
    final border = BorderSide(color: StoryColors.dividerOf(brightness));

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: fg,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StoryRadius.lgValue),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: fg,
          ),
        ),
      ),
    );
  }
}
