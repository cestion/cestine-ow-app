import 'package:flutter/material.dart';

import '../../../styles/story_colors.dart';

/// 创建短剧返回时的草稿操作浮层。
///
/// 位置由调用方通过 [CompositedTransformFollower] 锚定到返回按钮；本组件只
/// 负责 Figma 节点 6660:71110 的视觉与两项操作。
class DraftExitMenu extends StatelessWidget {
  final String discardLabel;
  final String saveLabel;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  const DraftExitMenu({
    super.key,
    required this.discardLabel,
    required this.saveLabel,
    required this.onDiscard,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final surface = StoryColors.cardOf(brightness);
    final foreground = StoryColors.foregroundOf(brightness);

    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - 32,
        ),
        child: IntrinsicWidth(
          child: CustomPaint(
            painter: _MenuSurfacePainter(color: surface),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DraftExitMenuItem(
                        icon: const Icon(
                          Icons.keyboard_return,
                          size: 24,
                          color: StoryColors.destructive,
                        ),
                        label: discardLabel,
                        color: StoryColors.destructive,
                        onTap: onDiscard,
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: StoryColors.dividerOf(brightness),
                      ),
                      _DraftExitMenuItem(
                        icon: _FolderMinusIcon(color: foreground),
                        label: saveLabel,
                        color: foreground,
                        onTap: onSave,
                      ),
                    ],
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

class _DraftExitMenuItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DraftExitMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 22 / 15,
                    letterSpacing: 0,
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

class _FolderMinusIcon extends StatelessWidget {
  final Color color;

  const _FolderMinusIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 24, color: color),
          Positioned(
            right: 4,
            bottom: 7,
            child: Container(width: 7, height: 1.5, color: color),
          ),
        ],
      ),
    );
  }
}

class _MenuSurfacePainter extends CustomPainter {
  final Color color;

  const _MenuSurfacePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 8, size.width, size.height - 8),
          const Radius.circular(8),
        ),
      )
      ..moveTo(12, 8)
      ..lineTo(21.5, 0)
      ..lineTo(31, 8)
      ..close();
    canvas.drawShadow(path, StoryColors.shadowTint, 16, false);
    canvas.drawShadow(path, StoryColors.shadowSoft, 20, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MenuSurfacePainter oldDelegate) =>
      oldDelegate.color != color;
}
