import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../widgets/error_handler.dart';
import '../common/story_toast.dart';

/// 演员派遣确认弹窗 — 对齐 Figma node 5792:80668「派遣」。
///
/// 底部抽屉：拖拽指示条 + 标题「派遣演员」+ 灰色演员信息卡片
/// （姓名 + 咖位·等级）+ 描述文字 + 取消（描边）/ 确定（深色填充）双按钮。
/// 确认后自行调用 `gameControllerProvider.deploy`，避免外层业务重复样板。
Future<bool?> showGameDeployConfirmDialog(
  BuildContext context,
  WidgetRef ref,
  MiningActor actor,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: StoryColors.overlayMid,
    builder: (ctx) => _GameDeployConfirmDialog(actor: actor),
  );
}

class _GameDeployConfirmDialog extends ConsumerStatefulWidget {
  final MiningActor actor;

  const _GameDeployConfirmDialog({required this.actor});

  @override
  ConsumerState<_GameDeployConfirmDialog> createState() =>
      _GameDeployConfirmDialogState();
}

class _GameDeployConfirmDialogState
    extends ConsumerState<_GameDeployConfirmDialog> {
  bool _isSubmitting = false;

  /// 咖位名解析（与 web `formatGameActorLevelName` 对齐）：
  /// l10n 静态表覆盖 1~5；未知等级返回 null，调用方仅展示 `Lv$level`。
  String? _resolveLevelName(BuildContext context, WidgetRef ref, int? level) {
    if (level == null) return null;
    final l10n = context.l10n;
    switch (level) {
      case 1:
        return l10n.gameActorLevelName1;
      case 2:
        return l10n.gameActorLevelName2;
      case 3:
        return l10n.gameActorLevelName3;
      case 4:
        return l10n.gameActorLevelName4;
      case 5:
        return l10n.gameActorLevelName5;
    }
    final config = ref.watch(globalConfigProvider);
    return config.whenOrNull(
      data: (result) => result.when(
        success: (c) => c.init?.actorNft?.levels?['$level']?.name,
        failure: (_) => null,
      ),
    );
  }

  /// 副标题「{咖位名} · Lv{level}」；无咖位名时仅「Lv{level}」，
  /// 与 Figma「顶级 · Lv5」保持一致。
  String _buildLevelSubtitle(String? levelName, int? level) {
    if (level == null) return '';
    final lv = 'Lv$level';
    if (levelName == null || levelName.isEmpty) return lv;
    return '$levelName · $lv';
  }

  Future<void> _handleConfirm(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;

    if ((widget.actor.stamina ?? 0) <= 0) {
      StoryToast.error(context, l10n.gameDeployStaminaDepleted);
      return;
    }

    setState(() => _isSubmitting = true);
    final ok = await ref
        .read(gameControllerProvider.notifier)
        .deploy(widget.actor.nftId);
    if (!context.mounted) return;

    if (ok) {
      StoryToast.success(context, l10n.gameDeploy);
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSubmitting = false);
    final err = ref.read(gameControllerProvider).lastError;
    if (err != null) {
      handleApiError(err, ctx: context, rootOverlay: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isActionLoading = _isSubmitting;

    final actorName = widget.actor.displayName.isNotEmpty
        ? widget.actor.displayName
        : '-';
    final actorCode = widget.actor.actorCode;
    final levelName = _resolveLevelName(context, ref, widget.actor.level);
    final levelSubtitle = _buildLevelSubtitle(levelName, widget.actor.level);

    final sheetBg = StoryColors.cardOf(brightness);
    final foreground = StoryColors.foregroundOf(brightness);
    final secondaryText = brightness == Brightness.dark
        ? StoryColors.darkMutedForeground
        : StoryColors.lightMutedForeground;
    final cardBg = brightness == Brightness.dark
        ? StoryColors.darkMuted
        : StoryColors.lightMuted;
    final borderColor = brightness == Brightness.dark
        ? StoryColors.darkDivider
        : StoryColors.lightDivider;
    final confirmBg = StoryColors.actorSignSheetConfirmBgOf(brightness);
    final confirmFg = StoryColors.actorSignSheetConfirmFgOf(brightness);

    return PopScope(
      canPop: !isActionLoading,
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 拖拽指示条
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: StoryColors.actorHeroBadgeBgOf(brightness),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: StorySpacing.base),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StorySpacing.base,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 标题「派遣演员」
                  Text(
                    l10n.gameDeployActor,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 26 / 18,
                      letterSpacing: -0.04,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: StorySpacing.base),
                  // 演员 info 卡
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(StorySpacing.base),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: actorName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 24 / 16,
                                  letterSpacing: 0,
                                  color: foreground,
                                ),
                              ),
                              if (actorCode != null)
                                TextSpan(
                                  text: ' $actorCode',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 20 / 14,
                                    letterSpacing: 0,
                                    color: foreground,
                                  ),
                                ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (levelSubtitle.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            levelSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 16 / 12,
                              letterSpacing: 0.04,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: StorySpacing.base),
                  // 描述文字
                  Text(
                    l10n.gameDeployConfirmDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                      letterSpacing: 0.04,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: StorySpacing.xl),
                  // 双按钮：取消（描边） + 确定（深色填充，flex-1）
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: isActionLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 10,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          l10n.commonCancel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: foreground,
                          ),
                        ),
                      ),
                      const SizedBox(width: StorySpacing.itemGap),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isActionLoading
                              ? null
                              : () => _handleConfirm(context, ref),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: confirmBg,
                            foregroundColor: confirmFg,
                            disabledBackgroundColor: confirmBg,
                            disabledForegroundColor: confirmFg.withValues(
                              alpha: 0.4,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: StorySpacing.base,
                              vertical: 10,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: isActionLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: confirmFg,
                                  ),
                                )
                              : Text(
                                  l10n.commonConfirm,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: confirmFg,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: StorySpacing.base),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
