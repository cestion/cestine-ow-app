import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import 'sheet_drag_handle.dart';

/// 评论操作弹层：长按评论 Tile 后弹出，提供「删除」「举报」等操作。
///
/// 外层结构与 [CommentBottomSheet] 一致：透明背景 Modal BottomSheet + 顶部
/// 拖拽把手 + `backgroundOf` 背景容器（顶部圆角 16）。
///
/// 操作区样式参照 Figma `Story.fun V2-ui` 节点 98-103191「为作品评分」上的
/// 浮层：
/// - 圆角 12 的卡片，暗色背景 `#212225`、亮色为白卡；
/// - 每行高度 56（内边距 16 上下 + 24 图标），行内 16px 水平内边距；
/// - 图标 24px + 文案 15px/22px，删除 w400、举报 w700；
/// - 行间 0.5px 细分隔线（白 6%）。
///
/// 当前仅提供「删除」：自己可删自己的评论，创作者可删所有人评论。
/// 「举报」行通过 [onReport] 预留（提供回调后才显示），等评论举报接口就绪后接入。
class CommentActionSheet {
  CommentActionSheet._();

  /// 展示评论操作弹层。
  ///
  /// [canDelete] 控制是否显示「删除」行；[onReport] 非空时追加「举报」行。
  /// 无任何操作行时直接返回（不弹出空弹层）。
  static Future<void> show({
    required BuildContext context,
    required bool canDelete,
    VoidCallback? onDelete,
    VoidCallback? onReport,
  }) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final sheetBg = isDark ? StoryColors.darkButtonBg : StoryColors.lightCard;
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : StoryColors.lightBorder;
    final fg = StoryColors.foregroundOf(brightness);
    final l10n = context.l10n;
    final radius = BorderRadius.circular(12);

    final rows = <Widget>[
      if (canDelete)
        _ActionRow(
          icon: Icons.delete_outline_rounded,
          iconWidget: SvgPicture.asset(
            'assets/drama/action_trash.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
          ),
          label: l10n.commonDelete,
          color: fg,
          onTap: () {
            Navigator.of(context).pop();
            onDelete?.call();
          },
        ),
      if (onReport != null)
        _ActionRow(
          icon: Icons.error_outline_rounded,
          iconWidget: SvgPicture.asset(
            'assets/drama/action_report.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
          ),
          label: l10n.playerReport,
          color: fg,
          fontWeight: FontWeight.w700,
          onTap: () {
            Navigator.of(context).pop();
            onReport();
          },
        ),
    ];
    if (rows.isEmpty) return Future.value();

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: StoryColors.overlayMedium,
      builder: (sheetCtx) => DecoratedBox(
        decoration: BoxDecoration(
          color: StoryColors.backgroundOf(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StorySheetDragHandle(brightness: brightness),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: sheetBg,
                    borderRadius: radius,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        rows[i],
                        if (i < rows.length - 1)
                          Divider(height: 1, thickness: 0.5, color: divider),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 单行操作项：24px 图标 + 15px 文案，行高 56（16 上下内边距）。
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final FontWeight fontWeight;
  final VoidCallback onTap;

  /// 自定义图标 Widget（如 SVG）；非空时优先于 [icon] 渲染。
  final Widget? iconWidget;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.fontWeight = FontWeight.w400,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            iconWidget ?? Icon(icon, size: 24, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: fontWeight,
                height: 22 / 15,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
