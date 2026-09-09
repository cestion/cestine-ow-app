import 'package:flutter/material.dart';

import '../../core/app_channel.dart';
import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../iap/iap_point_icon.dart';

/// 发行手续费提示条（固定 1 USDC）— Figma 暗 `872:169169` / 亮 `872:169614`。
class IssueFeeRow extends StatelessWidget {
  const IssueFeeRow({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final labelStyle = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: StoryColors.foregroundOf(brightness),
    );
    const valueStyle = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w700,
      color: StoryColors.brandTeal,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.brandTeal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
        child: Row(
          children: [
            Text(l10n.createActorIssueFee, style: labelStyle),
            const Spacer(),
            const Text('1', style: valueStyle),
            const SizedBox(width: 2),
            if (AppChannel.isStore)
              const IapPointIcon(size: 14)
            else
              const Text('USDC', style: valueStyle),
          ],
        ),
      ),
    );
  }
}
