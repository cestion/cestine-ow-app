import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';

/// 列表顶部子标题：左侧「全部评论（N）」，样式参照 Figma `Colors-Text-primary`。
class CommentListHeader extends StatelessWidget {
  const CommentListHeader({super.key, required this.commentCount});

  final int commentCount;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = StoryColors.foregroundOf(brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.base,
        vertical: StorySpacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${context.l10n.commentsTabAllComments}'
          '（${_formatCount(commentCount)}）',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontFamily: 'SF Pro',
            fontWeight: FontWeight.w400,
            height: 1.43,
          ),
        ),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n < 1000) return '$n';
    if (n < 1_000_000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return '${(n / 1_000_000).toStringAsFixed(n % 1_000_000 == 0 ? 0 : 1)}M';
  }
}
