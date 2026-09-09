import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/components.dart';
import '../../../controller/comment_controller.dart';
import '../../../controller/comment_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../utils/auth_navigation.dart';
import '../../../widgets/story_loading.dart';
import 'comment_tile.dart';

/// 评论列表。空列表时回退到 [emptyBuilder] 或默认文案。
///
/// 列表本身不带内边距（横向间距由子 Widget 自持），
/// 当提供 [args] 时，每条一级评论下方会渲染可展开的二级评论区块，并支持
/// 对一级评论「回复 / 删除」。
///
/// 二级评论被扁平化为外层 ListView 的独立行（而非嵌套在单个 item 的
/// Column 内），因此无论展开后加载多少条回复，滚动时只有视口附近的行会被
/// 构建与布局，避免大量二级评论时整体卡顿。各一级评论的展开状态由本组件
/// 自持（`_expandedRoots`）。
class CommentListView extends ConsumerStatefulWidget {
  final List<StoryComment> comments;
  final ScrollPhysics? physics;

  /// 滚动控制器（宿主传入，发布一级评论后可滚动回顶部）。
  final ScrollController? scrollController;
  final ValueChanged<String>? onLikeComment;
  final WidgetBuilder? emptyBuilder;
  final bool highlightFirstComment;

  /// 关联的评论控制器参数；提供后渲染二级评论区块。
  final CommentArgs? args;

  /// 点击一级评论「回复」时回调（宿主借此切换输入栏为回复模式）。
  final ValueChanged<CommentReplyTarget>? onReplyTargetChanged;

  /// 点击一级评论「删除」时回调。
  final ValueChanged<StoryComment>? onDeleteComment;

  /// 判断某条评论当前用户是否有权删除（自己或创作者）；为 null 时默认可删。
  final bool Function(StoryComment)? canDeleteComment;

  /// 滚动接近底部时回调（宿主借此加载下一页一级评论）。
  final VoidCallback? onLoadMore;

  const CommentListView({
    super.key,
    required this.comments,
    this.physics,
    this.scrollController,
    this.onLikeComment,
    this.emptyBuilder,
    this.highlightFirstComment = false,
    this.args,
    this.onReplyTargetChanged,
    this.onDeleteComment,
    this.canDeleteComment,
    this.onLoadMore,
  });

  @override
  ConsumerState<CommentListView> createState() => _CommentListViewState();
}

/// 扁平行模型：一级评论 / 二级评论 / 加载 / 展开·收起切换。
sealed class _FlatItem {
  const _FlatItem();
}

class _RootItem extends _FlatItem {
  final StoryComment comment;
  const _RootItem(this.comment);
}

class _ReplyItem extends _FlatItem {
  final StoryComment reply;
  final String rootId;
  const _ReplyItem(this.reply, {required this.rootId});
}

enum _ToggleKind { viewReplies, expandMore, collapse }

/// 单个「展开/收起」按钮规格。
class _ToggleSpec {
  final String rootId;
  final _ToggleKind kind;

  /// 「查看回复(N)」时待加载条数。
  final int remainingCount;

  /// 同行的后续按钮置 false 以避免重复横线。
  final bool showLine;

  const _ToggleSpec({
    required this.rootId,
    required this.kind,
    this.remainingCount = 0,
    this.showLine = true,
  });
}

/// 单行单个「展开/收起」按钮。
class _ToggleItem extends _FlatItem {
  final _ToggleSpec spec;
  const _ToggleItem(this.spec);
}

/// 单行多个按钮（「展开更多」+「收起」同行排列）。
class _ToggleRowItem extends _FlatItem {
  final List<_ToggleSpec> specs;
  const _ToggleRowItem(this.specs);
}

class _LoadingItem extends _FlatItem {
  const _LoadingItem();
}

class _CommentListViewState extends ConsumerState<CommentListView> {
  /// 各一级评论的展开状态，key 为一级评论 id。
  final Map<String, bool> _expandedRoots = {};

  /// 一级评论行的 GlobalKey：收起后用于把该评论滚动到视口居中。
  final Map<String, GlobalKey> _rootKeys = {};

  /// 一级评论在滚动内容中的绝对偏移与行高，展开时记录。根行被 ListView
  /// 回收后仍可据此计算居中的滚动目标。
  final Map<String, ({double offset, double height})> _rootScrollOffsets = {};

  GlobalKey _rootKeyFor(String commentId) =>
      _rootKeys.putIfAbsent(commentId, () => GlobalKey());

  /// 计算 [ctx] 所在行在滚动内容中的绝对偏移（行顶相对内容顶的距离）。
  double? _rootContentOffset(BuildContext ctx, ScrollController controller) {
    if (!controller.hasClients) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final scrollableBox =
        Scrollable.of(ctx).context.findRenderObject() as RenderBox?;
    if (scrollableBox == null) return null;
    return controller.offset +
        box.localToGlobal(Offset.zero).dy -
        scrollableBox.localToGlobal(Offset.zero).dy;
  }

  /// 展开前记录根行位置，供收起时定位（此时根行必然已构建）。
  void _recordRootScrollOffset(String rootId) {
    final controller = widget.scrollController;
    final ctx = _rootKeys[rootId]?.currentContext;
    if (controller == null || ctx == null) return;
    final offset = _rootContentOffset(ctx, controller);
    final height = (ctx.findRenderObject() as RenderBox?)?.size.height;
    if (offset == null || height == null) return;
    _rootScrollOffsets[rootId] = (offset: offset, height: height);
  }

  /// 与一级评论头像 (40) + 间距 (12) 对齐，让二级头像落在一级评论正文起始线。
  static const double _kReplyIndent = 52;

  @override
  Widget build(BuildContext context) {
    if (widget.comments.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          Center(
            child: Text(
              context.l10n.commentsEmpty,
              style: StoryTextStyles.bodyMedium(
                color: StoryColors.mutedForegroundOf(
                  Theme.of(context).brightness,
                ),
              ),
            ),
          );
    }

    final items = _buildFlatItems();
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 滚动接近底部时触发加载下一页一级评论（宿主回调内部自带
        // isLoading/hasMore 防重入）。
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter <= StorySpacing.scrollThreshold) {
          widget.onLoadMore?.call();
        }
        return false;
      },
      child: ListView.builder(
        controller: widget.scrollController,
        physics: widget.physics,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (_, i) => _buildItem(items[i]),
      ),
    );
  }

  /// 把一级评论与其展开的二级评论拍平成一行序列，供外层列表虚拟化。
  ///
  /// 返回的只是轻量描述对象（非 Widget 子树），构建成本与加载的回复条数
  /// 成正比但极低；真正的 [CommentTile] 仅在 itemBuilder 对可见行构建。
  List<_FlatItem> _buildFlatItems() {
    final args = widget.args;
    final replyGroups = args == null
        ? const <String, CommentReplyGroup>{}
        : ref.watch(
            commentControllerProvider(args).select((s) => s.replyGroups),
          );
    final justPostedReplies = args == null
        ? const <String, List<StoryComment>>{}
        : ref.watch(
            commentControllerProvider(args).select((s) => s.justPostedReplies),
          );

    final items = <_FlatItem>[];
    for (final comment in widget.comments) {
      final rootId = comment.commentId;
      items.add(_RootItem(comment));
      if (rootId == null || rootId.isEmpty || args == null) continue;

      final group = replyGroups[rootId];
      final featured = comment.featuredReply;
      final hasFeatured = featured != null;
      final featuredId = featured?.commentId;
      final justPostedList =
          justPostedReplies[rootId] ?? const <StoryComment>[];
      // 折叠态外显的刚发布回复（与精选去重）。
      final justPostedShown = justPostedList
          .where((r) => r.commentId != featuredId)
          .toList();

      final replyCount = comment.replyCount ?? 0;
      // 已展示数量 = 精选 + 刚发布回复；剩余即仍需展开加载的条数。
      final shownCount = (hasFeatured ? 1 : 0) + justPostedShown.length;
      final remainingCount = (replyCount - shownCount).clamp(0, replyCount);
      final hasJustPosted = justPostedShown.isNotEmpty;
      // 折叠态下被隐藏的已加载回复 = 回复组内除精选与刚发布（均外显）
      // 之外的条目。刚发布的回复会同时写入回复组与 justPosted 列表，
      // 不能仅凭回复组非空判断还有可展开内容。
      final shownIds = <String?>{
        featuredId,
        for (final r in justPostedShown) r.commentId,
      };
      final hiddenLoadedCount =
          group?.replies.where((r) => !shownIds.contains(r.commentId)).length ??
          0;

      // 只要存在二级评论内容（精选/刚发布/有隐藏回复/更多待加载）就渲染
      // 该区块。
      if (!hasFeatured &&
          !hasJustPosted &&
          hiddenLoadedCount <= 0 &&
          remainingCount <= 0) {
        continue;
      }

      final expanded = _expandedRoots[rootId] ?? false;

      if (!expanded) {
        // 折叠态：精选回复 + 刚发布回复（含回复链）+ 「查看回复(N)」。
        if (hasFeatured) items.add(_ReplyItem(featured, rootId: rootId));
        for (final jp in justPostedShown) {
          items.add(_ReplyItem(jp, rootId: rootId));
        }
        // 还有未外显的回复（待加载或已加载被折叠隐藏）才显示「查看回复」；
        // 全部已外显（如仅刚发布1条回复）则不显示。按钮数字取两者较大
        // 值，避免服务端计数偏小时显示「查看0条回复」。
        if (remainingCount > 0 || hiddenLoadedCount > 0) {
          items.add(
            _ToggleItem(
              _ToggleSpec(
                rootId: rootId,
                kind: _ToggleKind.viewReplies,
                remainingCount: remainingCount > hiddenLoadedCount
                    ? remainingCount
                    : hiddenLoadedCount,
              ),
            ),
          );
        }
      } else {
        // 展开态：精选回复与已加载的回复始终保留展示；回复加载中
        // （首次展开或加载更多）在末尾追加统一的居中加载指示。
        if (hasFeatured) {
          items.add(_ReplyItem(featured, rootId: rootId));
        }
        final loadedReplies =
            group?.replies
                .where((r) => r.commentId != null && r.commentId != featuredId)
                .toList(growable: false) ??
            const <StoryComment>[];
        for (final reply in loadedReplies) {
          items.add(_ReplyItem(reply, rootId: rootId));
        }
        if (group == null || group.isLoading) {
          items.add(const _LoadingItem());
        } else if (group.hasMore) {
          // 同时显示「展开更多」时只保留前者的横线；单独收起时自带横线。
          items.add(
            _ToggleRowItem([
              _ToggleSpec(rootId: rootId, kind: _ToggleKind.expandMore),
              _ToggleSpec(
                rootId: rootId,
                kind: _ToggleKind.collapse,
                showLine: false,
              ),
            ]),
          );
        } else {
          items.add(
            _ToggleItem(
              _ToggleSpec(rootId: rootId, kind: _ToggleKind.collapse),
            ),
          );
        }
      }
    }
    // 翻页加载中：列表尾部追加加载指示（区别于二级评论展开的行内加载）。
    if (args != null) {
      final isLoadingMore = ref.watch(
        commentControllerProvider(args).select((s) => s.isLoadingMore),
      );
      if (isLoadingMore) items.add(const _LoadingItem());
    }
    return items;
  }

  Widget _buildItem(_FlatItem item) {
    return switch (item) {
      _RootItem(:final comment) => _buildRootTile(
        comment,
        highlighted:
            widget.highlightFirstComment &&
            widget.comments.isNotEmpty &&
            identical(comment, widget.comments.first),
      ),
      _ReplyItem(:final reply, :final rootId) => _buildReplyTile(reply, rootId),
      _ToggleItem(:final spec) => _buildToggleItem(spec),
      _ToggleRowItem(:final specs) => _buildToggleRow(specs),
      _LoadingItem() => const StoryLoading.centered(size: 10, strokeWidth: 1),
    };
  }

  Widget _buildRootTile(StoryComment comment, {bool highlighted = false}) {
    final commentId = comment.commentId;
    return CommentTile(
      key: commentId == null ? null : _rootKeyFor(commentId),
      comment: comment,
      highlighted: highlighted,
      onLike: widget.onLikeComment != null && commentId != null
          ? () => widget.onLikeComment!(commentId)
          : null,
      onReply: widget.onReplyTargetChanged != null && commentId != null
          ? () => widget.onReplyTargetChanged!(
              CommentReplyTarget(
                rootId: commentId,
                replyToNickname: comment.nickname ?? '',
              ),
            )
          : null,
      onDelete:
          widget.onDeleteComment != null &&
              commentId != null &&
              (widget.canDeleteComment?.call(comment) ?? true)
          ? () => widget.onDeleteComment!(comment)
          : null,
      onReport: commentId == null || _isOwnComment(comment)
          ? null
          : () => openCommentReport(context, comment),
    );
  }

  Widget _buildReplyTile(StoryComment reply, String rootId) {
    final controller = ref.read(
      commentControllerProvider(widget.args!).notifier,
    );
    return _indent(
      CommentTile(
        key: ValueKey('reply-${reply.commentId}'),
        comment: reply,
        isReply: true,
        onLike: reply.commentId == null
            ? null
            : () async {
                if (!await ensureLoggedInOrRedirect(context, ref)) return;
                await controller.toggleReplyLike(rootId, reply.commentId!);
                if (!mounted) return;
                // 点赞失败提示（如评论已被删除返回 125101）。
                final error = controller.lastError;
                if (error != null) {
                  StoryToast.error(
                    context,
                    context.l10nError(error),
                    rootOverlay: true,
                  );
                }
              },
        onReply: () => _onReplyTarget(reply, rootId),
        onDelete: reply.commentId != null && controller.canDeleteComment(reply)
            ? () => _confirmDeleteReply(reply, rootId)
            : null,
        onReport: reply.commentId == null || _isOwnComment(reply)
            ? null
            : () => openCommentReport(context, reply),
      ),
    );
  }

  /// 是否当前用户自己发布的评论（自己的评论不展示「举报」）。
  bool _isOwnComment(StoryComment comment) {
    final currentUserId = ref.read(authControllerProvider).userId;
    if (currentUserId == null || currentUserId.isEmpty) return false;
    final commentUserId = comment.userId?.trim();
    return commentUserId != null &&
        commentUserId.isNotEmpty &&
        commentUserId == currentUserId;
  }

  Widget _buildToggleItem(_ToggleSpec spec) {
    return _indent(_buildToggleWidget(spec));
  }

  /// 「展开更多」+「收起」同行渲染（与 Figma 尾行一致）。
  Widget _buildToggleRow(List<_ToggleSpec> specs) {
    return _indent(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < specs.length; i++) ...[
            if (i > 0) const SizedBox(width: StorySpacing.sm),
            _buildToggleWidget(specs[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleWidget(_ToggleSpec spec) {
    final controller = ref.read(
      commentControllerProvider(widget.args!).notifier,
    );
    final (label, expanded, onTap) = switch (spec.kind) {
      _ToggleKind.viewReplies => (
        context.l10n.commentsViewReplies(spec.remainingCount),
        false,
        () {
          _recordRootScrollOffset(spec.rootId);
          setState(() => _expandedRoots[spec.rootId] = true);
          // 仅首次展开（回复组未加载）时拉取；收起后重新展开直接展示
          // 已加载的回复，避免重新请求只拿回首屏而丢失已翻页数据。
          final loaded = ref
              .read(commentControllerProvider(widget.args!))
              .replyGroups
              .containsKey(spec.rootId);
          if (!loaded) {
            controller.loadReplies(spec.rootId);
          }
        },
      ),
      _ToggleKind.expandMore => (
        context.l10n.commentsViewMoreReplies,
        false,
        () => controller.loadMoreReplies(spec.rootId),
      ),
      _ToggleKind.collapse => (
        context.l10n.commentsCollapseReplies,
        true,
        () => _collapseRoot(spec.rootId),
      ),
    };
    return _ExpandToggle(
      label: label,
      expanded: expanded,
      onTap: onTap,
      showLine: spec.showLine,
    );
  }

  /// 收起该一级评论的回复，并把该评论滚动到视口居中位置。
  ///
  /// 若根行当前仍构建，直接量测其内容偏移（保证精确）；否则回退到展开时
  /// 记录的偏移（根行被回收时也能正确定位）。
  void _collapseRoot(String rootId) {
    setState(() => _expandedRoots[rootId] = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = widget.scrollController;
      if (controller == null || !controller.hasClients) return;

      final ctx = _rootKeys[rootId]?.currentContext;
      final currentOffset = ctx == null
          ? null
          : _rootContentOffset(ctx, controller);
      final currentHeight =
          (ctx?.findRenderObject() as RenderBox?)?.size.height;
      final recorded = _rootScrollOffsets[rootId];

      final double? contentOffset;
      final double? height;
      if (currentOffset != null && currentHeight != null) {
        contentOffset = currentOffset;
        height = currentHeight;
      } else if (recorded != null) {
        contentOffset = recorded.offset;
        height = recorded.height;
      } else {
        return;
      }

      final target =
          (contentOffset - (controller.position.viewportDimension - height) / 2)
              .clamp(
                controller.position.minScrollExtent,
                controller.position.maxScrollExtent,
              );
      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onReplyTarget(StoryComment reply, String rootId) {
    widget.onReplyTargetChanged?.call(
      CommentReplyTarget(
        rootId: rootId,
        replyToCommentId: reply.commentId,
        replyToNickname: reply.nickname ?? '',
      ),
    );
  }

  Future<void> _confirmDeleteReply(StoryComment reply, String rootId) async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!mounted) return;
    final replyId = reply.commentId;
    if (replyId == null) return;
    final controller = ref.read(
      commentControllerProvider(widget.args!).notifier,
    );
    final deleted = await controller.deleteReply(rootId, replyId);
    final error = controller.replyGroupOf(rootId)?.lastError;
    if (!deleted && error != null && mounted) {
      StoryToast.error(context, context.l10nError(error), rootOverlay: true);
    }
  }

  /// 二级评论区块整体左缩进，对齐一级评论正文起始线。
  Widget _indent(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(
        left: _kReplyIndent + StorySpacing.base,
        right: StorySpacing.base,
      ),
      child: child,
    );
  }
}

/// 「展开/收起」切换按钮：可带 22px 横线前缀 + 文字 + chevron。
class _ExpandToggle extends StatelessWidget {
  final String label;
  final bool expanded;
  final VoidCallback onTap;

  /// 是否在按钮前显示 22px 装饰横线。同行的后续按钮置 false 以避免重复横线。
  final bool showLine;

  const _ExpandToggle({
    required this.label,
    required this.expanded,
    required this.onTap,
    this.showLine = true,
  });

  @override
  Widget build(BuildContext context) {
    final muted = StoryColors.mutedForegroundOf(Theme.of(context).brightness);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: StorySpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLine) ...[
              // 22px 装饰横线，对齐二级评论与切换条视觉锚点。
              Container(
                width: 22,
                height: 1,
                color: muted.withValues(alpha: 0.4),
              ),
              const SizedBox(width: StorySpacing.sm),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 18 / 13,
                color: muted,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: muted,
            ),
          ],
        ),
      ),
    );
  }
}
