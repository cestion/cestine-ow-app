import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';

/// 评论身份/状态标识，根据 `StoryComment.tags` 渲染。
///
/// tags 取值：
/// - AUTHOR / ME / FRIEND / FAN —— 身份标识（作者、我、你的好友、你的粉丝）
/// - FIRST / AUTHOR_LIKED —— 状态标识（首评、作者赞过）
///
/// 样式参照 Figma `Story.fun V2-ui`：
/// - 亮色节点 521-72738「展示好友关系/作者」：
///   - AUTHOR：红底 `#E8001B` + 白字
///   - ME / FRIEND / FAN / AUTHOR_LIKED：浅灰底 `#F6F6F6` + 中灰字
///     `#60646C` + 描边 `#D9D9E0`（0.5）
///   - FIRST：品牌红字 `#E50815` + 红色 `#E50815` @5% 底色
/// - 暗色节点 102-107919「展示好友关系/作者」：
///   - AUTHOR：红底 `#E8001B` + 白字（与亮色一致）
///   - ME / FRIEND / FAN / AUTHOR_LIKED：近黑底 `#171718` + 浅灰字
///     `#B0B4BA` + 描边 `#363A3F`（0.5）
///   - FIRST：品牌红字 `#E50815` + 红色 `#E50815` @5% 底色（与亮色一致）
class CommentTagBadges extends StatelessWidget {
  final List<String>? tags;

  const CommentTagBadges({super.key, this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags == null || tags!.isEmpty) return const SizedBox.shrink();
    final brightness = Theme.of(context).brightness;
    // 身份标签同时存在时只展示优先级最高的一个：AUTHOR/ME > FRIEND > FAN
    // （AUTHOR 优先于 ME，避免重复展示「作者」与「我」）；
    // FIRST 与 AUTHOR_LIKED 同时存在时只展示 FIRST。
    final identityWinner = _identityWinner(tags!);
    final hasFirst = tags!.contains('FIRST');
    final badges = <Widget>[];
    for (final tag in tags!) {
      if (identityWinner != null && _isIdentity(tag) && tag != identityWinner) {
        continue;
      }
      if (hasFirst && tag == 'AUTHOR_LIKED') continue;
      final label = _labelFor(context, tag);
      final style = _styleFor(tag, brightness);
      if (label == null || style == null) continue;
      badges.add(_CommentTagBadge(label: label, style: style));
    }
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 2, children: badges);
  }

  static bool _isIdentity(String tag) =>
      tag == 'AUTHOR' || tag == 'ME' || tag == 'FRIEND' || tag == 'FAN';

  static String? _identityWinner(List<String> tags) {
    if (tags.contains('AUTHOR')) return 'AUTHOR';
    if (tags.contains('ME')) return 'ME';
    if (tags.contains('FRIEND')) return 'FRIEND';
    if (tags.contains('FAN')) return 'FAN';
    return null;
  }

  String? _labelFor(BuildContext context, String tag) {
    return switch (tag) {
      'AUTHOR' => context.l10n.commentTagAuthor,
      'ME' => context.l10n.commentTagMe,
      'FRIEND' => context.l10n.commentTagFriend,
      'FAN' => context.l10n.commentTagFan,
      'FIRST' => context.l10n.commentTagFirst,
      'AUTHOR_LIKED' => context.l10n.commentTagAuthorLiked,
      _ => null,
    };
  }

  _CommentTagBadgeStyle? _styleFor(String tag, Brightness brightness) {
    return switch (tag) {
      'AUTHOR' => _CommentTagBadgeStyle(
        background: StoryColors.commentBadgeAuthorBgOf(brightness),
        foreground: StoryColors.commentBadgeAuthorFgOf(brightness),
      ),
      'ME' || 'FRIEND' || 'FAN' || 'AUTHOR_LIKED' => _CommentTagBadgeStyle(
        background: StoryColors.commentBadgeNeutralBgOf(brightness),
        foreground: StoryColors.commentBadgeNeutralFgOf(brightness),
        border: StoryColors.commentBadgeNeutralBorderOf(brightness),
      ),
      'FIRST' => _CommentTagBadgeStyle(
        background: StoryColors.commentBadgeFirstBgOf(brightness),
        foreground: StoryColors.commentBadgeFirstFgOf(brightness),
      ),
      _ => null,
    };
  }
}

/// 单个标签的配色。
class _CommentTagBadgeStyle {
  final Color background;
  final Color foreground;
  final Color? border;

  const _CommentTagBadgeStyle({
    required this.background,
    required this.foreground,
    this.border,
  });
}

class _CommentTagBadge extends StatelessWidget {
  final String label;
  final _CommentTagBadgeStyle style;

  const _CommentTagBadge({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(4),
        border: style.border == null
            ? null
            : Border.all(color: style.border!, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          height: 16 / 11,
          color: style.foreground,
        ),
      ),
    );
  }
}
