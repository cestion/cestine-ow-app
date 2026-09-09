import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';

/// Tab 通用空状态：88×88 插画 + 「暂无数据」。
/// 设计来源 Figma 节点 `119:122494`「空状态-通用」。
class CommentEmptyState extends StatelessWidget {
  const CommentEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            isDark ? 'assets/common/empty_d.svg' : 'assets/common/empty.svg',
            width: 88,
            height: 88,
          ),
          const SizedBox(height: StorySpacing.sm),
          Text(
            context.l10n.searchNoData,
            style: StoryTextStyles.bodySmall(
              color: StoryColors.mutedForegroundOf(
                Theme.of(context).brightness,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
