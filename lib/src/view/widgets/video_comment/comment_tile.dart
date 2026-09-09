import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../foundation/navigator.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../utils/auth_navigation.dart';
import '../../../utils/format_time.dart';
import '../../../widgets/story_avatar.dart';
import 'comment_action_sheet.dart';
import 'comment_tag_badges.dart';

/// 单条评论 Tile：头像 + 昵称/身份标识 + 正文 + 时间 + 底部点赞/回复操作。
///
/// 布局参考 Figma `Story.fun V2-ui` 节点 80-94928「评论区状态」：
/// - 头像 40px（一级）/ 32px（二级），与正文间留 12px；
/// - 昵称行包含「身份标签」（作者/我/好友/粉丝），与正文间隔 6px；
/// - 正文下方依次叠加「内容元标签」（首评/作者赞过）与时间戳（间隔 4px）；
/// - 底部操作行紧随正文，间隔 12px，包含点赞按钮与回复按钮。
/// - 长按整个 Tile 弹出操作浮层（[CommentActionSheet]），可删除（自己或
///   创作者可删）。
/// - 「回复 @xxx：」前缀仅在二级评论回复「另一条二级评论」时显示；直接回复
///   一级评论的二级评论不显示该前缀（依赖 `parentId != rootId` 判定）。
///
/// [isReply] 为 true 时按二级评论渲染（更小头像、缩进、@回复对象前缀）。
/// 通过 [onLike] / [onReply] 可选地暴露点赞与回复操作；[onDelete] 非空时
/// 允许弹出删除操作。
class CommentTile extends ConsumerStatefulWidget {
  final StoryComment comment;
  final bool isReply;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final bool highlighted;

  /// 点击「举报」时回调；为空则动作浮层不展示「举报」行。
  final VoidCallback? onReport;

  const CommentTile({
    super.key,
    required this.comment,
    this.isReply = false,
    this.onLike,
    this.onReply,
    this.onDelete,
    this.onReport,
    this.highlighted = false,
  });

  @override
  ConsumerState<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<CommentTile> {
  /// 昵称最多展示 10 个字符，超出以「…」结尾（rune 级截断）。
  static String _ellipsizeNickname(String nickname) {
    final runes = nickname.runes.toList();
    if (runes.length <= 10) return nickname;
    return '${String.fromCharCodes(runes.take(10))}…';
  }

  /// 点击头像跳转评论发布者公开主页；无 userId 时不跳转。
  VoidCallback? _openAuthorProfile(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    return () {
      unawaited(
        context.storyPush(RouteNames.publicProfile,
          arguments: {'userId': userId},
          rootNavigator: true),
      );
    };
  }

  /// 长按高亮中：按下时置 true，抬起/取消时复位。
  bool _longPressing = false;

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isLoggedIn = ref.watch(
      authControllerProvider.select((s) => s.isLoggedIn),
    );
    final usernameColor = StoryColors.commentUsernameOf(brightness);
    final contentColor = StoryColors.commentContentOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);
    final avatarSize = widget.isReply ? 32.0 : 40.0;

    final allTags = comment.tags ?? const <String>[];
    final identityTags = allTags
        .where(_CommentTagScope.isIdentity)
        .toList(growable: false);
    final contentMetaTags = allTags
        .where(_CommentTagScope.isContentMeta)
        .toList(growable: false);

    // 「回复 @xxx：」前缀只在回复二级评论时显示（按 parentId != rootId
    // 判定）；直接回复一级评论的二级评论不加前缀。昵称最多展示 10 个
    // 字符（rune 级截断，避免拆坏代理对），超出以省略号结尾。
    final replyToNickname = comment.replyToNickname;
    final replyTo =
        (widget.isReply &&
            comment.parentId != null &&
            comment.parentId != comment.rootId &&
            (replyToNickname?.isNotEmpty ?? false))
        ? _ellipsizeNickname(replyToNickname!)
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: isLoggedIn
          ? (_) => setState(() => _longPressing = true)
          : null,
      onLongPressEnd: isLoggedIn
          ? (_) => setState(() => _longPressing = false)
          : null,
      onLongPressCancel: isLoggedIn
          ? () => setState(() => _longPressing = false)
          : null,
      onLongPress: isLoggedIn ? () => _showActionSheet(ref) : null,
      child: ColoredBox(
        color: _longPressing
            ? StoryColors.commentTileLongPressBgOf(brightness)
            : widget.highlighted
            ? StoryColors.brandTeal.withValues(alpha: 0.10)
            : Colors.transparent,
        child: Padding(
          // 一级评论自持横向边距；二级评论的缩进由 CommentReplySection 提供。
          padding: widget.isReply
              ? const EdgeInsets.symmetric(vertical: StorySpacing.sm)
              : const EdgeInsets.symmetric(
                  horizontal: StorySpacing.base,
                  vertical: StorySpacing.sm,
                ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 点击头像跳转发布者主页；无 userId（匿名等）时不可点。
              GestureDetector(
                onTap: _openAuthorProfile(comment.userId),
                child: StoryAvatar(
                  imageUrl: comment.avatarUrl,
                  userId: comment.userId,
                  fallbackText: comment.nickname ?? '?',
                  size: avatarSize,
                ),
              ),
              const SizedBox(width: StorySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NameRow(
                      nickname:
                          comment.nickname ?? context.l10n.commentsAnonymous,
                      identityTags: identityTags,
                      nicknameColor: usernameColor,
                      fontSize: widget.isReply ? 13.0 : 14.0,
                    ),
                    const SizedBox(height: 6),
                    _ContentBody(
                      content: comment.content ?? '',
                      replyTo: replyTo,
                      contentColor: contentColor,
                      fontSize: widget.isReply ? 14.0 : 15.0,
                      contentMetaTags: contentMetaTags,
                      muted: muted,
                      createdAtMs: comment.createdAt,
                    ),
                    const SizedBox(height: StorySpacing.md),
                    _FooterActions(
                      liked: comment.likedByMe ?? false,
                      likeCount: comment.likeCount ?? 0,
                      muted: muted,
                      onLike: widget.onLike,
                      onReply: widget.onReply,
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

  Future<void> _showActionSheet(WidgetRef ref) async {
    // 无可执行操作（删除/举报）时直接返回，不弹空浮层。
    if (widget.onDelete == null && widget.onReport == null) return;
    // 弹出操作浮层前先校验登录，未登录跳转登录页。
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!mounted) return;
    await CommentActionSheet.show(
      context: context,
      canDelete: widget.onDelete != null,
      onDelete: widget.onDelete,
      onReport: widget.onReport,
    );
  }
}

/// 长按操作项：举报当前评论，跳转举报原因页（scope=COMMENT）。
void openCommentReport(BuildContext context, StoryComment comment) {
  final commentId = comment.commentId;
  if (commentId == null || commentId.isEmpty) return;
  context.storyPush(RouteNames.report, arguments: <String, dynamic>{
      'scope': UgcReportScope.comment,
      'commentId': commentId,
      'userId': comment.userId,
      'targetDisplayName': comment.nickname,
      'targetAvatarUrl': comment.avatarUrl,
    });
}

/// 昵称行：昵称 + 身份标签。
class _NameRow extends StatelessWidget {
  const _NameRow({
    required this.nickname,
    required this.identityTags,
    required this.nicknameColor,
    required this.fontSize,
  });

  final String nickname;
  final List<String> identityTags;
  final Color nicknameColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            nickname,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              height: 20 / fontSize,
              color: nicknameColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 身份标签最多只展示一个（CommentTagBadges 内部按优先级取
        // winner），固有宽度小：不参与 flex 分配，昵称占满剩余空间，
        // 仅在超出父组件宽度时才截断。
        if (identityTags.isNotEmpty) ...[
          const SizedBox(width: StorySpacing.xs),
          CommentTagBadges(tags: identityTags),
        ],
      ],
    );
  }
}

/// 正文区域：正文文本 + 「回复 @xxx」前缀 + 内容元标签 + 时间戳。
class _ContentBody extends StatelessWidget {
  const _ContentBody({
    required this.content,
    required this.replyTo,
    required this.contentColor,
    required this.fontSize,
    required this.contentMetaTags,
    required this.muted,
    required this.createdAtMs,
  });

  final String content;
  final String? replyTo;
  final Color contentColor;
  final double fontSize;
  final List<String> contentMetaTags;
  final Color muted;
  final int? createdAtMs;

  @override
  Widget build(BuildContext context) {
    final hasMetaTags = contentMetaTags.isNotEmpty;
    final hasReplyTo = replyTo != null && replyTo!.isNotEmpty;
    final atColor = StoryColors.commentBadgeNeutralFgOf(
      Theme.of(context).brightness,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (content.isNotEmpty || hasReplyTo)
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
                height: (fontSize + 7) / fontSize,
                color: contentColor,
              ),
              children: [
                if (hasReplyTo)
                  ..._buildReplyPrefix(
                    context,
                    replyTo!,
                    contentColor,
                    atColor,
                  ),
                TextSpan(text: content),
              ],
            ),
          ),
        if (hasMetaTags) ...[
          const SizedBox(height: StorySpacing.xs),
          CommentTagBadges(tags: contentMetaTags),
        ],
        if (createdAtMs != null) ...[
          const SizedBox(height: StorySpacing.xs),
          Text(
            FormatTime.formatRelative(context, createdAtMs),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 16 / 12,
              color: muted,
            ),
          ),
        ],
      ],
    );
  }

  /// 把「回复 @昵称：」拆成多段 span：「回复」「：」保持 [contentColor]，
  /// 「@昵称」用 [atColor]。基于 l10n 原文按 `@` 切分以保留各语言的措辞。
  List<TextSpan> _buildReplyPrefix(
    BuildContext context,
    String nickname,
    Color contentColor,
    Color atColor,
  ) {
    final full = context.l10n.commentsReplyTo(nickname);
    final atIndex = full.indexOf('@');
    if (atIndex == -1) {
      return [
        TextSpan(
          text: full,
          style: TextStyle(color: contentColor),
        ),
      ];
    }
    final afterStart = atIndex + 1 + nickname.length;
    final after = afterStart < full.length ? full.substring(afterStart) : '';
    return [
      TextSpan(
        text: full.substring(0, atIndex),
        style: TextStyle(color: contentColor),
      ),
      TextSpan(
        text: '@$nickname',
        style: TextStyle(color: atColor),
      ),
      TextSpan(
        text: after,
        style: TextStyle(color: contentColor),
      ),
    ];
  }
}

/// 底部操作行：点赞按钮 + 回复按钮。
class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.liked,
    required this.likeCount,
    required this.muted,
    required this.onLike,
    required this.onReply,
  });

  final bool liked;
  final int likeCount;
  final Color muted;
  final VoidCallback? onLike;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          onTap: onLike,
          icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: liked ? StoryColors.likeActive : muted,
          label: '$likeCount',
        ),
        const SizedBox(width: StorySpacing.md),
        if (onReply != null)
          _ActionButton(
            onTap: onReply,
            icon: Icons.chat_bubble_outline_rounded,
            iconWidget: SvgPicture.asset(
              'assets/drama/reply_message_circle.svg',
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(muted, BlendMode.srcIn),
            ),
            iconColor: muted,
            label: context.l10n.commentsReply,
          ),
      ],
    );
  }
}

/// 单个底部按钮：图标 + 文本，与 Figma `Frame 2085664231` 中 `Button` 样式一致。
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.iconWidget,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final Color iconColor;
  final String label;

  /// 自定义图标 Widget（如 SVG）；非空时优先于 [icon] 渲染。
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    final muted = StoryColors.mutedForegroundOf(Theme.of(context).brightness);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget ?? Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: StorySpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 18 / 13,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// 评论标签作用域拆分：身份标签放昵称行，内容元标签放正文下方。
extension _CommentTagScope on String {
  static bool isIdentity(String tag) =>
      tag == 'AUTHOR' || tag == 'ME' || tag == 'FRIEND' || tag == 'FAN';

  static bool isContentMeta(String tag) =>
      tag == 'FIRST' || tag == 'AUTHOR_LIKED';
}
