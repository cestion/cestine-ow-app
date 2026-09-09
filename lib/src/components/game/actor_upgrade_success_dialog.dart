import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';

/// 显示演员升级成功对话框，样式参考 [ActorMintSuccessDialog]
/// （位于 components/nft/actor_sign_dialog.dart）。
///
/// 升级成功后由 `game_actor_upgrade_dialog.dart` 调用：
/// 先关闭升级底部弹层，再展示该成功对话框，保证用户能明确感知升级结果。
///
/// 参数：
/// - [actorName]  演员名称（缺失显示 '-'）
/// - [nextLevel]  目标等级数值
/// - [levelName]  目标等级名称（群演/配角/主角/巨星/顶流）
/// - [actorCode]  演员编号，例如 `#123`，作为副标题展示（可空）
Future<void> showActorUpgradeSuccessDialog(
  BuildContext context, {
  required String actorName,
  required int nextLevel,
  required String levelName,
  String? actorCode,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ActorUpgradeSuccessDialog(
      actorName: actorName,
      nextLevel: nextLevel,
      levelName: levelName,
      actorCode: actorCode,
    ),
  );
}

/// 演员升级成功对话框 — 圆形成功图标 + 标题 + 演员名 + 目标等级 + 确认按钮。
///
/// 与 [ActorMintSuccessDialog] 布局一致，仅文案与信息字段不同：
///   - 顶部：绿色圆形对勾图标（44x44，StoryColors.success）
///   - 标题：升级成功（gameUpgradeSuccess）
///   - 正文：演员名称
///   - 副标题：升级到 Lv{level} {levelName}（gameUpgradeToLevel）
///   - 编号：演员编号（可选）
///   - 底部：确认按钮（commonConfirm），pill 形态填充当前主题前景色
class ActorUpgradeSuccessDialog extends StatelessWidget {
  final String actorName;
  final int nextLevel;
  final String levelName;
  final String? actorCode;

  const ActorUpgradeSuccessDialog({
    super.key,
    required this.actorName,
    required this.nextLevel,
    required this.levelName,
    this.actorCode,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final displayName = actorName.trim().isNotEmpty ? actorName.trim() : '-';
    final code = actorCode?.trim();
    final showCode = code != null && code.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: StorySpacing.xxxl),
      backgroundColor: StoryColors.cardOf(brightness),
      shape: const RoundedRectangleBorder(borderRadius: StoryRadius.brXl),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: StoryColors.success,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check, color: StoryColors.onOverlay),
            ),
            const SizedBox(height: StorySpacing.md),
            Text(
              l10n.gameUpgradeSuccess,
              style: StoryTextStyles.titleMedium(
                color: StoryColors.foregroundOf(brightness),
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: StorySpacing.sm),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: StoryTextStyles.bodyMedium(
                color: StoryColors.foregroundOf(brightness),
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.gameUpgradeToLevel(nextLevel, levelName),
              textAlign: TextAlign.center,
              style: StoryTextStyles.bodyMedium(
                color: StoryColors.mutedForegroundOf(brightness),
              ),
            ),
            if (showCode) ...[
              const SizedBox(height: 4),
              Text(
                code,
                textAlign: TextAlign.center,
                style: StoryTextStyles.bodySmall(
                  color: StoryColors.mutedForegroundOf(brightness),
                ),
              ),
            ],
            const SizedBox(height: StorySpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: StoryColors.foregroundOf(brightness),
                  foregroundColor: StoryColors.backgroundOf(brightness),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(
                    borderRadius: StoryRadius.brPill,
                  ),
                ),
                child: Text(
                  l10n.commonConfirm,
                  style: StoryTextStyles.bodyMedium(
                    color: StoryColors.backgroundOf(brightness),
                  ).copyWith(fontWeight: FontWeight.bold, height: 20 / 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
