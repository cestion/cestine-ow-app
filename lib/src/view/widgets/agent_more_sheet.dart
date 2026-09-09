import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../foundation/navigator.dart';
import '../../l10n/story_l10n.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';

const _rulesAsset = 'assets/game_v2/agent_more_rules.svg';
const _salaryPoolAsset = 'assets/game_v2/agent_more_salary_pool.svg';
const _historyAsset = 'assets/game_v2/agent_more_history.svg';

Future<void> showAgentMoreSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: StoryColors.overlayMid,
    showDragHandle: false,
    builder: (_) => const AgentMoreSheet(),
  );
}

/// Figma `637:69485`：「更多」bottom sheet — 规则 / 片酬与奖池 / 每周结算记录。
class AgentMoreSheet extends StatelessWidget {
  const AgentMoreSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scaffoldBg = brightness == Brightness.dark
        ? StoryColors.darkBackground
        : StoryColors.lightSheetSecondary;
    final cardColor = StoryColors.cardOf(brightness);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DragHandle(),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MoreItem(
                      iconAsset: _rulesAsset,
                      labelKey: _MoreLabel.rules,
                    ),
                    _MoreDivider(),
                    _MoreItem(
                      iconAsset: _salaryPoolAsset,
                      labelKey: _MoreLabel.salaryAndPool,
                    ),
                    _MoreDivider(),
                    _MoreItem(
                      iconAsset: _historyAsset,
                      labelKey: _MoreLabel.weeklySettlement,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _CancelButton(onTap: () => Navigator.of(context).maybePop()),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Center(
        child: Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: StoryColors.privyLightDisabled,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

enum _MoreLabel { rules, salaryAndPool, weeklySettlement }

class _MoreItem extends StatelessWidget {
  final String iconAsset;
  final _MoreLabel labelKey;

  const _MoreItem({required this.iconAsset, required this.labelKey});

  String _label(BuildContext context) {
    return switch (labelKey) {
      _MoreLabel.rules => context.l10n.agentMoreRules,
      _MoreLabel.salaryAndPool => context.l10n.agentMoreSalaryAndPool,
      _MoreLabel.weeklySettlement => context.l10n.gameSettlementRecords,
    };
  }

  Future<void> _handleTap(BuildContext context) async {
    await Navigator.of(context).maybePop();
    if (!context.mounted) return;
    if (labelKey == _MoreLabel.rules) {
      await context.storyPush(RouteNames.miningRules);
    } else if (labelKey == _MoreLabel.salaryAndPool) {
      await context.storyPush(RouteNames.salaryPool);
    } else if (labelKey == _MoreLabel.weeklySettlement) {
      await context.storyPush(RouteNames.income);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final iconColor = StoryColors.foregroundOf(brightness);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => _handleTap(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  iconAsset,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _label(context),
                style: TextStyle(
                  color: StoryColors.foregroundOf(brightness),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 22 / 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreDivider extends StatelessWidget {
  const _MoreDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 0,
        thickness: 0.5,
        color: StoryColors.dividerOf(Theme.of(context).brightness),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CancelButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: StoryColors.dividerOf(brightness),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                context.l10n.commonCancel,
                style: TextStyle(
                  color: StoryColors.foregroundOf(brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
