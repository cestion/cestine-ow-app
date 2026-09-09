import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/components.dart';
import '../../../controller/comment_controller.dart';
import '../../../controller/engagement_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../utils/auth_navigation.dart';
import '../../../widgets/story_loading.dart';
import 'comment_empty_state.dart';
import 'comment_input_bar.dart';
import 'comment_list_header.dart';
import 'comment_list_view.dart';

/// 评论 Tab：标题栏（评论数） + 列表。
///
/// 输入栏与 emoji picker 均由上层 [CommentEmojiPickerHost] 以浮层方式
/// 统一渲染（输入栏浮在键盘/面板上沿），此处仅透传 picker 可见状态与
/// 输入栏 State 句柄（用于点击列表区域时收起面板/键盘），列表通过
/// [bottomPadding] 预留输入栏遮挡高度。
///
/// 布局参考 Figma `Story.fun V2-ui` 节点 80-94928「评论区状态」顶部
/// `Frame 2085663891`：左侧「评论（N）」标题。
class CommentsTabContent extends ConsumerStatefulWidget {
  final String dramaId;
  final String? episodeId;
  final int? episodeNo;
  final int commentCount;
  final StoryComment? highlightedComment;

  /// EmojiPicker 可见状态，由上层持有。
  final ValueNotifier<bool>? emojiPickerVisible;

  /// 输入栏 State 句柄，供上层在切 Tab 时显式复位输入栏。
  final GlobalKey<CommentInputBarState>? inputBarKey;

  /// 列表滚动控制（宿主传入，发布一级评论后可滚动回顶部）。
  final ScrollController? scrollController;

  /// 列表底部预留高度（浮层输入栏实测高度），避免最后一条评论被
  /// 输入栏遮挡。
  final double bottomPadding;

  /// 键盘/面板实时顶起高度（由宿主帧末上报）。列表底部留白叠加该值，
  /// 键盘展开时末条评论仍可滚动到键盘上方。经 ValueListenableBuilder
  /// 缓存 child 消费，键盘逐帧动画期间只重设 Padding，不重建列表子树。
  final ValueListenable<double>? keyboardInset;

  /// 点击「回复」时回调（宿主借此切换输入栏为回复模式）。
  final ValueChanged<CommentReplyTarget>? onReplyTargetChanged;

  const CommentsTabContent({
    super.key,
    required this.dramaId,
    this.episodeId,
    this.episodeNo,
    required this.commentCount,
    this.highlightedComment,
    this.emojiPickerVisible,
    this.inputBarKey,
    this.scrollController,
    this.bottomPadding = 0,
    this.keyboardInset,
    this.onReplyTargetChanged,
  });

  @override
  ConsumerState<CommentsTabContent> createState() => _CommentsTabContentState();
}

class _CommentsTabContentState extends ConsumerState<CommentsTabContent>
    with AutomaticKeepAliveClientMixin {
  late final CommentArgs _args;

  /// 兜底的键盘顶起高度（宿主未传入时恒 0）。
  static final ValueNotifier<double> _fallbackKeyboardInset = ValueNotifier(0);

  @override
  bool get wantKeepAlive => true;

  EpisodeEngagementKey? get _engagementKey {
    final episodeId = widget.episodeId;
    if (episodeId == null) return null;
    return EpisodeEngagementKey.tryForEpisode(
      dramaId: widget.dramaId,
      episodeId: episodeId,
      episodeNo: widget.episodeNo,
    );
  }

  @override
  void initState() {
    super.initState();
    _args = CommentArgs(
      dramaId: widget.dramaId,
      episodeId: widget.episodeId,
      episodeNo: widget.episodeNo,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _engagementKey;
      if (key != null) {
        ref
            .read(episodeEngagementProvider(key).notifier)
            .seed(commentCount: widget.commentCount);
      }
      ref.read(commentControllerProvider(_args).notifier).loadComments();
    });
  }

  Future<void> _onLikeComment(String commentId) async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!mounted) return;
    final notifier = ref.read(commentControllerProvider(_args).notifier);
    await notifier.toggleCommentLike(commentId);
    if (!mounted) return;
    // 点赞失败提示（如评论已被删除返回 125101「评论不存在」）。
    final error = notifier.lastError;
    if (error != null) {
      StoryToast.error(context, context.l10nError(error), rootOverlay: true);
    }
  }

  /// 点击输入框外区域：收起表情面板、收起键盘，输入栏复位为 idle 布局。
  void _dismissEmojiPicker() {
    final notifier = widget.emojiPickerVisible;
    if (notifier != null && notifier.value) {
      notifier.value = false;
    }
    // resetToIdle 同时 unfocus 收起键盘并切回单行 idle 布局。
    widget.inputBarKey?.currentState?.resetToIdle();
  }

  Future<void> _confirmDeleteComment(StoryComment comment) async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!mounted) return;
    final commentId = comment.commentId;
    if (commentId == null) return;
    final notifier = ref.read(commentControllerProvider(_args).notifier);
    final deleted = await notifier.deleteComment(commentId);
    if (!mounted) return;
    // 删除失败提示（如评论已被删除返回 125101「评论不存在」）。
    final error = notifier.lastError;
    if (!deleted && error != null) {
      StoryToast.error(context, context.l10nError(error), rootOverlay: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLoading = ref.watch(
      commentControllerProvider(_args).select((s) => s.isLoading),
    );
    final comments = ref.watch(
      commentControllerProvider(_args).select((s) => s.comments),
    );
    final highlighted = widget.highlightedComment;
    final highlightedId = highlighted?.commentId?.trim();
    final loadedIndex = highlightedId == null || highlightedId.isEmpty
        ? -1
        : comments.indexWhere((comment) => comment.commentId == highlightedId);
    final displayComments = highlighted == null
        ? comments
        : <StoryComment>[
            loadedIndex >= 0 ? comments[loadedIndex] : highlighted,
            for (var i = 0; i < comments.length; i++)
              if (i != loadedIndex) comments[i],
          ];
    // 优先展示与剧集联动更新的评论总数；未联动时退回 widget.commentCount。
    final key = _engagementKey;
    final liveCount = key == null
        ? null
        : ref.watch(
            episodeEngagementProvider(key).select((s) => s.commentCount),
          );
    final commentCount = liveCount ?? widget.commentCount;
    // 点击内容区（含列表标题）：收起表情面板与键盘，输入栏复位 idle。
    // 手势包住整个 Column——标题区在列表滚动区之外，若不覆盖会出现
    // 「键盘被系统默认失焦收起、emoji 面板却无人收」的割裂状态。
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _dismissEmojiPicker,
      child: Column(
        children: [
          CommentListHeader(commentCount: commentCount),
          Expanded(
            child: ValueListenableBuilder<double>(
              valueListenable: widget.keyboardInset ?? _fallbackKeyboardInset,
              // child 缓存：键盘逐帧动画期间只重设 Padding，
              // 列表子树（含 provider watch）零重建。
              builder: (context, keyboardInset, child) => Padding(
                padding: EdgeInsets.only(
                  bottom: keyboardInset + widget.bottomPadding,
                ),
                child: child,
              ),
              child: isLoading
                  ? const StoryLoading.centered()
                  : CommentListView(
                      comments: displayComments,
                      highlightFirstComment: highlighted != null,
                      args: _args,
                      scrollController: widget.scrollController,
                      onReplyTargetChanged: widget.onReplyTargetChanged,
                      onDeleteComment: _confirmDeleteComment,
                      canDeleteComment: (comment) => ref
                          .read(commentControllerProvider(_args).notifier)
                          .canDeleteComment(comment),
                      emptyBuilder: (_) => const CommentEmptyState(),
                      onLikeComment: _onLikeComment,
                      onLoadMore: () => ref
                          .read(commentControllerProvider(_args).notifier)
                          .loadMoreComments(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
