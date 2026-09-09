import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/common/story_toast.dart';
import '../../../components/components.dart';
import '../../../components/game/actor_upgrade_success_dialog.dart';
import '../../../core/core.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../services/wallet_ledger.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/format_number.dart';
import '../../../utils/mining_power.dart';
import '../../../utils/wallet_balance_gate.dart';

/// Figma `2797:183316`：升级角色确认弹窗（居中弹层）。
///
/// 与 [GameController]（`gameControllerProvider`）共用耗材获取 / 升级提交 /
/// `isActionLoading` 状态 —— 升级业务逻辑（耗材接口、链上提交、轮询）在 V1/V2
/// 两处完全一致，无需为 V2 另建 controller，仅弹窗 UI 精简为 Figma 稿的样式。
///
/// 调用方需先校验完播 / 耗材前置条件均满足（不满足时应改为展示
/// [showAgentV2UpgradeRequirementsDialog]），本弹窗不再重复渲染这些条件。
Future<bool> showAgentV2UpgradeConfirmDialog(
  BuildContext context,
  WidgetRef ref,
  MiningActor actor,
) async {
  final upgraded = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, _, _) => _AgentV2UpgradeConfirmDialog(actor: actor),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
        child: child,
      ),
    ),
  );
  return upgraded ?? false;
}

class _AgentV2UpgradeConfirmDialog extends ConsumerStatefulWidget {
  final MiningActor actor;

  const _AgentV2UpgradeConfirmDialog({required this.actor});

  @override
  ConsumerState<_AgentV2UpgradeConfirmDialog> createState() =>
      _AgentV2UpgradeConfirmDialogState();
}

class _AgentV2UpgradeConfirmDialogState
    extends ConsumerState<_AgentV2UpgradeConfirmDialog> {
  List<ActorUpgradeMaterial> _materials = [];
  bool _isLoadingMaterials = true;
  bool _isSubmitting = false;
  final Set<int> _selectedTokenIds = {};

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    final materials = await ref
        .read(gameControllerProvider.notifier)
        .getUpgradeMaterials(widget.actor.nftId);
    if (!mounted) return;
    setState(() {
      _materials = materials;
      _isLoadingMaterials = false;
    });
  }

  /// 解析当前等级对应的下一级升级规则，与 [showGameActorUpgradeDialog] 的
  /// `_resolveUpgradeConfig` 对齐：`init.actorNft.levels[level].upgrade`。
  InitActorNftUpgradeConfig? _resolveUpgradeConfig() {
    final level = widget.actor.level;
    if (level == null) return null;
    final config = ref.watch(globalConfigProvider);
    return config.whenOrNull(
      data: (result) => result.when(
        success: (c) => c.init?.actorNft?.levels?['$level']?.upgrade,
        failure: (_) => null,
      ),
    );
  }

  double? _resolveMiningCoefficient(int? level) {
    if (level == null) return null;
    final config = ref.watch(globalConfigProvider);
    return config.whenOrNull(
      data: (result) => result.when(
        success: (c) => c.init?.actorNft?.levels?['$level']?.miningCoefficient,
        failure: (_) => null,
      ),
    );
  }

  String? _resolveLevelName(int? level) {
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

  Future<void> _handleConfirm({
    required int requiredCount,
    required double fee,
    required int? toLevel,
  }) async {
    final l10n = context.l10n;
    final gameState = ref.read(gameControllerProvider);
    final notifier = ref.read(gameControllerProvider.notifier);

    // GameController only enters its loading state after the balance/config
    // preflight. Lock locally before the first await so rapid taps cannot
    // create multiple upgrade orders during that gap.
    if (_isSubmitting || gameState.isActionLoading || toLevel == null) {
      return;
    }
    if (_selectedTokenIds.length != requiredCount) {
      StoryToast.error(context, l10n.gameUpgradeSelectMaterials(requiredCount));
      return;
    }

    setState(() => _isSubmitting = true);
    var didUpgrade = false;
    try {
      SpendTicket? spendTicket;
      if (fee > 0) {
        // Soft-check first so insufficient balance pops the recharge dialog
        // instead of only showing a toast after the optimistic deduction.
        final okBalance = await ensureUsdcBalanceOrShowDialog(
          ref,
          context,
          fee,
        );
        if (!okBalance || !mounted) return;
        spendTicket = await prepareUsdcSpend(
          ref,
          context,
          fee,
          reason: 'actor_upgrade',
        );
        if (spendTicket == null) return;
      }
      final ledger = ref.read(walletLedgerProvider);

      final actor = widget.actor;
      final mainNftTokenId = actor.actorTokenId;
      final actorCollectionId = actor.actorCollectionId;
      final actorNftId = actor.nftId;
      if (mainNftTokenId == null ||
          actorCollectionId == null ||
          actorNftId.isEmpty) {
        if (spendTicket != null && spendTicket.didDeduct) {
          await ledger.reconcile(spendTicket);
        }
        return;
      }

      // 在异步升级请求前解析目标等级名称，避免 await 后 widget 被销毁时访问 ref。
      final targetLevelName = _resolveLevelName(toLevel);

      final ok = await notifier.upgradeActor(
        actorCollectionId: actorCollectionId,
        mainNftTokenId: mainNftTokenId,
        burnNftTokenIds: _selectedTokenIds.toList(),
        actorNftId: actorNftId,
        toLevel: toLevel,
      );

      if (!mounted) {
        if (spendTicket != null && spendTicket.didDeduct) {
          await ledger.reconcile(spendTicket);
        }
        return;
      }

      if (ok) {
        // 将成功结果回传给外层 sheet；sheet 负责强制刷新升级列表。
        didUpgrade = true;
        final rootContext = Navigator.of(context, rootNavigator: true).context;
        Navigator.of(context, rootNavigator: true).pop(true);
        if (rootContext.mounted) {
          if (targetLevelName != null) {
            await showActorUpgradeSuccessDialog(
              rootContext,
              actorName: actor.displayName,
              nextLevel: toLevel,
              levelName: targetLevelName,
              actorCode: actor.actorCode,
            );
          } else {
            StoryToast.success(rootContext, l10n.gameUpgradeSuccess);
          }
        }
        if (spendTicket != null && spendTicket.didDeduct) {
          await ledger.commitSpend(spendTicket);
        }
        return;
      }

      if (spendTicket != null && spendTicket.didDeduct) {
        await ledger.reconcile(spendTicket);
      }
      if (!mounted) return;
      final err = ref.read(gameControllerProvider).lastError;
      StoryToast.error(
        context,
        err == null ? l10n.gameUpgradeFailed : context.l10nError(err),
      );
    } finally {
      if (mounted && !didUpgrade) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final actor = widget.actor;
    final isActionLoading = ref.watch(
      gameControllerProvider.select((s) => s.isActionLoading),
    );
    final isSubmitting = _isSubmitting || isActionLoading;

    final mainMaterial = _materials.isNotEmpty ? _materials.first : null;
    final requirement = mainMaterial?.upgradeRequirement;
    // 升级规则优先取耗材接口返回，缺省回退全局配置 `levels[level].upgrade`
    // （与 [showGameActorUpgradeDialog] 口径一致）。
    final upgradeConfig = _resolveUpgradeConfig();
    final toLevel = requirement?.toLevel ?? upgradeConfig?.toLevel;
    final requiredCount =
        requirement?.requiredMaterialCount ??
        upgradeConfig?.requiredMaterialCount ??
        2;
    final fee = requirement?.fee ?? upgradeConfig?.fee ?? 0;
    final displayName = actor.displayName.isEmpty ? '-' : actor.displayName;
    final code = actor.actorCode?.trim();
    final actorLabel = [
      displayName,
      if (code != null && code.isNotEmpty) code,
    ].join(' ');

    final currentLevel = actor.level ?? 0;
    final targetLevel = toLevel ?? currentLevel + 1;
    final currentSalary = getMiningActorHourlySalary(actor);
    final breakdown = getMiningActorPowerBreakdown(actor);
    final targetCoefficient = _resolveMiningCoefficient(targetLevel);
    final targetSalary = targetCoefficient == null
        ? null
        : truncatePower(
            breakdown.ipPower *
                targetCoefficient *
                breakdown.cpCoefficient *
                breakdown.trust2,
            10,
          );

    final confirmBackground = brightness == Brightness.dark
        ? Colors.white
        : StoryColors.darkButtonBgOf(brightness);
    final confirmForeground = brightness == Brightness.dark
        ? Colors.black
        : Colors.white;
    final confirmDisabledBackground = StoryColors.buttonDisabledForegroundOf(
      brightness,
    );
    final canConfirm =
        !isSubmitting &&
        !_isLoadingMaterials &&
        toLevel != null &&
        _selectedTokenIds.length == requiredCount;

    return PopScope(
      canPop: !isSubmitting,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: const ColoredBox(color: StoryColors.overlayMid),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 0,
                backgroundColor: StoryColors.cardOf(brightness),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ConstrainedBox(
                  key: const ValueKey('agent-v2-upgrade-confirm-card'),
                  constraints: const BoxConstraints(maxWidth: 343),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.agentV3Upgrade,
                          key: const ValueKey('agent-v2-upgrade-confirm-title'),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: StoryColors.foregroundOf(brightness),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 26 / 18,
                            letterSpacing: -0.04,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          actorLabel,
                          key: const ValueKey(
                            'agent-v2-upgrade-confirm-actor-label',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: StoryColors.foregroundOf(brightness),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 20 / 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SalaryChangeCard(
                          currentLevel: currentLevel,
                          targetLevel: targetLevel,
                          currentSalary: currentSalary,
                          targetSalary: targetSalary,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.agentV2UpgradeConfirmSelectMaterials,
                              style: TextStyle(
                                color: StoryColors.foregroundOf(brightness),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 20 / 14,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              l10n.gameUpgradeMaterialCount(
                                _selectedTokenIds.length,
                                requiredCount,
                              ),
                              style: TextStyle(
                                color: StoryColors.foregroundOf(brightness),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 16 / 12,
                                letterSpacing: 0.04,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingMaterials)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else if (_materials.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              l10n.gameUpgradeNoMaterials,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: StoryColors.mutedForegroundOf(
                                  brightness,
                                ),
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            // Figma 展示两行（48px + 8px gap）。候选项较多时
                            // 最多展开六行，充分利用大屏空间；超过后局部滚动，
                            // 避免小屏弹窗越过安全区。
                            height:
                                (_materials.length.clamp(1, 6) * 48 +
                                        (_materials.length.clamp(1, 6) - 1) * 8)
                                    .toDouble(),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: _materials.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final material = _materials[index];
                                final tokenId = material.tokenId;
                                final isSelected =
                                    tokenId != null &&
                                    _selectedTokenIds.contains(tokenId);
                                return _MaterialSelectRow(
                                  key: ValueKey(
                                    'actor-upgrade-material-$tokenId',
                                  ),
                                  material: material,
                                  isSelected: isSelected,
                                  isDisabled: isSubmitting || tokenId == null,
                                  onTap: tokenId == null || isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedTokenIds.remove(tokenId);
                                            } else if (_selectedTokenIds
                                                    .length <
                                                requiredCount) {
                                              _selectedTokenIds.add(tokenId);
                                            }
                                          });
                                        },
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: StoryColors.foregroundOf(
                                      brightness,
                                    ),
                                    disabledForegroundColor:
                                        StoryColors.foregroundOf(
                                          brightness,
                                        ).withValues(alpha: 0.4),
                                    side: BorderSide(
                                      color: StoryColors.dividerOf(brightness),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.commonClose,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      height: 20 / 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  key: const ValueKey(
                                    'agent-v2-upgrade-confirm-button',
                                  ),
                                  onPressed: canConfirm
                                      ? () => _handleConfirm(
                                          requiredCount: requiredCount,
                                          fee: fee,
                                          toLevel: toLevel,
                                        )
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: confirmBackground,
                                    foregroundColor: confirmForeground,
                                    disabledBackgroundColor:
                                        confirmDisabledBackground,
                                    disabledForegroundColor:
                                        StoryColors.onOverlaySubtle,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isSubmitting
                                      ? SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            key: const ValueKey(
                                              'agent-v2-upgrade-confirm-loading',
                                            ),
                                            strokeWidth: 2,
                                            color: confirmForeground,
                                          ),
                                        )
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            l10n.gameUpgradeConfirm,
                                            maxLines: 1,
                                            softWrap: false,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              height: 20 / 14,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 等级 + 片酬变化卡片，与 Figma `I2797:183316;191:43604` 对齐。
class _SalaryChangeCard extends StatelessWidget {
  final int currentLevel;
  final int targetLevel;
  final double currentSalary;
  final double? targetSalary;

  const _SalaryChangeCard({
    required this.currentLevel,
    required this.targetLevel,
    required this.currentSalary,
    required this.targetSalary,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(brightness),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LevelPill(
                level: currentLevel,
                borderColor: StoryColors.mutedForegroundOf(brightness),
                textColor: StoryColors.foregroundOf(brightness),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SvgPicture.asset(
                  'assets/game_v3/actor_upgrade_chevron_right.svg',
                  width: 16,
                  height: 16,
                ),
              ),
              _LevelPill(
                level: targetLevel,
                borderColor: StoryColors.star,
                textColor: StoryColors.star,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${context.l10n.agentV2UpgradeConfirmSalaryLabel} ',
                  style: TextStyle(
                    color: StoryColors.mutedForegroundOf(brightness),
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
                TextSpan(
                  text:
                      '${formatNumber(currentSalary)} → '
                      '${targetSalary == null ? '-' : formatNumber(targetSalary!)}',
                  style: TextStyle(
                    color: StoryColors.foregroundOf(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                  ),
                ),
                TextSpan(
                  text: ' / h',
                  style: TextStyle(
                    color: StoryColors.mutedForegroundOf(brightness),
                    fontSize: 12,
                    height: 16 / 12,
                    letterSpacing: 0.04,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  final int level;
  final Color borderColor;
  final Color textColor;

  const _LevelPill({
    required this.level,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.5),
        borderRadius: BorderRadius.circular(52),
      ),
      child: Text(
        'Lv.$level',
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          letterSpacing: 0.04,
        ),
      ),
    );
  }
}

/// 耗材选择行 — 与 Figma `I198:44157;191:43727` 对齐：边框颜色不随选中状态变化，
/// 仅前导图标切换为实心勾选。
class _MaterialSelectRow extends StatelessWidget {
  final ActorUpgradeMaterial material;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _MaterialSelectRow({
    super.key,
    required this.material,
    required this.isSelected,
    required this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final materialName = material.actorName?.trim() ?? '';
    final materialLevel = material.level;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: StoryColors.dividerOf(brightness)),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                isSelected
                    ? 'assets/game_v3/actor_upgrade_checkbox_on.svg'
                    : 'assets/game_v3/actor_upgrade_checkbox_off.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (materialName.isNotEmpty)
                            Flexible(
                              flex: 3,
                              child: Text(
                                materialName,
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 20 / 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (material.actorId != null) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              flex: 2,
                              child: Text(
                                material.actorId!.startsWith('#')
                                    ? material.actorId!
                                    : '#${material.actorId}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: secondary,
                                  fontSize: 12,
                                  height: 16 / 12,
                                  letterSpacing: 0.04,
                                ),
                              ),
                            ),
                          ],
                          if (materialLevel != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                'Lv$materialLevel',
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: 12,
                                  height: 16 / 12,
                                  letterSpacing: 0.04,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 固定留白将身份信息与等级/体力元数据分组，名称较长时由
                    // Flexible 优先省略，避免编号和等级挤在一起。
                    const SizedBox(width: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (material.stamina != null &&
                            material.staminaLimit != null) ...[
                          const SizedBox(width: 12),
                          SvgPicture.asset(
                            'assets/game_v3/actor_upgrade_bolt.svg',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${material.stamina}/${material.staminaLimit}',
                            style: TextStyle(
                              color: secondary,
                              fontSize: 12,
                              height: 16 / 12,
                              letterSpacing: 0.04,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 升级费用行，与 Figma `I198:44157;191:43780` 对齐。
class _FeeRow extends StatelessWidget {
  final double? fee;

  const _FeeRow({required this.fee});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.gameUpgradeFee,
            style: TextStyle(
              color: StoryColors.foregroundOf(brightness),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 20 / 14,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fee == null ? '-' : formatNumber(fee, 0),
                style: const TextStyle(
                  color: StoryColors.star,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
                ),
              ),
              const SizedBox(width: 6),
              if (AppChannel.isStore)
                const IapPointIcon(size: 12)
              else
                Text(
                  'USDC',
                  style: TextStyle(
                    color: StoryColors.mutedForegroundOf(brightness),
                    fontSize: 12,
                    height: 16 / 12,
                    letterSpacing: 0.04,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
