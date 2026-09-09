import 'package:flutter/material.dart';

import '../../styles/story_colors.dart';

/// 高强调主操作按钮。
///
/// 样式：亮色模式为黑底白字；暗色模式为白底黑字。加载中显示圆形进度指示器并禁用点击。
///
/// 通用组件，服务于创建短剧向导（下一步/提交）、铸造 NFT 确认弹窗等场景。
class PrimaryActionButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const PrimaryActionButton({
    super.key,
    required this.label,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final disabled = onPressed == null && !loading;
    final backgroundColor = disabled
        ? StoryColors.buttonDisabledForegroundOf(brightness)
        : (isDark ? Colors.white : StoryColors.darkButtonBg);
    const foregroundColor = StoryColors.onOverlay;
    final accentColor = disabled
        ? StoryColors.onOverlaySubtle
        : (isDark ? const Color(0xFF1C2024) : foregroundColor);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: loading ? null : onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                  color: accentColor,
                ),
              ),
      ),
    );
  }
}
