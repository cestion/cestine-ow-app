import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../styles/story_colors.dart';

/// 顶部道具余额胶囊，对应 Figma 节点 `2620:133077` / `2620:133083`。
class AgentV3BalanceChip extends StatelessWidget {
  final String asset;
  final String value;
  final double assetWidth;
  final double assetHeight;
  final VoidCallback? onAdd;

  const AgentV3BalanceChip({
    super.key,
    required this.asset,
    required this.value,
    required this.assetWidth,
    required this.assetHeight,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);

    return Container(
      height: 30,
      padding: const EdgeInsets.fromLTRB(6, 1, 3, 1),
      decoration: BoxDecoration(
        color: StoryColors.sheetSecondaryOf(brightness),
        borderRadius: BorderRadius.circular(88),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            asset,
            width: assetWidth,
            height: assetHeight,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 18 / 13,
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: onAdd != null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAdd,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StoryColors.whiteToDarkOf(brightness),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/game_v3/agent_plus.svg',
                  width: 12,
                  height: 12,
                  colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
