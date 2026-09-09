import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/components.dart';
import '../../../controller/comment_controller.dart';
import '../../../controller/engagement_state.dart';
import '../../../core/story_constants.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../utils/auth_navigation.dart';
// 临时隐藏「短剧 / 角色」Tab，import 一并注释，恢复时取消。
// import 'actors_tab_content.dart';
import 'comment_emoji_picker_host.dart';
import 'comment_input_bar.dart';
import 'comments_tab_content.dart';
import 'sheet_drag_handle.dart';
import '../video_feed/player_sheet_height_reporter.dart';

/// 评论区底部弹层。聚合「评论 / 短剧 / 角色」三个 Tab。
/// 设计来源 Figma 节点 `119:122494`「空状态-通用」。
///
/// 弹层内容固定贴底、不随键盘移动；输入栏与 emoji picker 均由
/// [CommentEmojiPickerHost] 以浮层方式渲染在键盘/面板上沿，输入栏
/// 多行展开时向上生长，不挤压评论列表。
class CommentBottomSheet extends ConsumerStatefulWidget {
  final String dramaId;
  final String? episodeId;
  final int? episodeNo;
  final int commentCount;
  final ValueChanged<int>? onCommentCountChanged;
  final StoryComment? highlightedComment;

  /// When set, reports the laid-out sheet height so the player band can
  /// flush against the sheet top (window-based collapse math).
  final ValueNotifier<double>? sheetHeightNotifier;

  const CommentBottomSheet({
    super.key,
    required this.dramaId,
    this.episodeId,
    this.episodeNo,
    required this.commentCount,
    this.onCommentCountChanged,
    this.highlightedComment,
    this.sheetHeightNotifier,
  });

  @override
  ConsumerState<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends ConsumerState<CommentBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _commentCtrl = TextEditingController();
  final _emojiPickerVisible = ValueNotifier<bool>(false);

  /// 评论输入栏句柄，切 Tab 时显式复位到未编辑状态。
  final _inputBarKey = GlobalKey<CommentInputBarState>();

  /// 评论列表滚动控制：发布一级评论后滚动回顶部展示置顶的新评论。
  final _listScroll = ScrollController();

  /// 当前回复目标；非空时输入栏进入回复模式。
  CommentReplyTarget? _replyTarget;

  CommentArgs get _args => CommentArgs(
    dramaId: widget.dramaId,
    episodeId: widget.episodeId,
    episodeNo: widget.episodeNo,
  );

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
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _commentCtrl.dispose();
    _listScroll.dispose();
    _emojiPickerVisible.dispose();
    super.dispose();
  }

  /// 切换离开评论 Tab 时重置输入态：收起 emoji picker、隐藏键盘、
  /// 清空输入内容，让输入栏恢复默认（未编辑）状态。
  void _onTabChanged() {
    if (_tabController.index != 0) {
      _emojiPickerVisible.value = false;
      _commentCtrl.clear();
      _inputBarKey.currentState?.resetToIdle();
    }
  }

  Future<void> _postComment() async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;
    // 发送时收起 emoji picker。
    _emojiPickerVisible.value = false;
    final notifier = ref.read(commentControllerProvider(_args).notifier);
    final target = _replyTarget;
    final isTopLevel = target == null;
    final posted = isTopLevel
        ? await notifier.postComment(content)
        : await notifier.postReply(
            target.rootId,
            content,
            replyToCommentId: target.effectiveReplyToId,
            replyToNickname: target.replyToNickname,
          );
    if (!mounted) return;
    if (!posted) {
      // 失败提示（如黑名单拦截 / 服务端返回评论不存在(125101)）。一级评论
      // 无回复组，读 state 级；根评论被 125101 连根移除后组级错误随之丢失，
      // 故回复同样优先读 state 级。
      final error = target == null
          ? notifier.lastError
          : (notifier.lastError ??
                notifier.replyGroupOf(target.rootId)?.lastError);
      if (error != null) {
        StoryToast.error(context, context.l10nError(error), rootOverlay: true);
      }
      return;
    }
    _commentCtrl.clear();
    // 发布成功后收起键盘并复位输入栏到初始状态。
    _inputBarKey.currentState?.resetToIdle();
    setState(() => _replyTarget = null);
    // 一级评论置顶后滚动回列表顶部，让新评论可见。
    if (isTopLevel && _listScroll.hasClients) {
      _listScroll.jumpTo(0);
    }
    final key = _engagementKey;
    if (key != null && isTopLevel) {
      widget.onCommentCountChanged?.call(
        ref.read(episodeEngagementProvider(key)).commentCount ??
            widget.commentCount + 1,
      );
    }
  }

  Future<void> _onReplyTargetChanged(CommentReplyTarget target) async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!mounted) return;
    setState(() => _replyTarget = target);
    // 进入回复模式后让输入栏获取焦点，键盘自动弹起。
    _inputBarKey.currentState?.requestFocusAndEdit();
  }

  @override
  Widget build(BuildContext context) {
    final isPosting = ref.watch(
      commentControllerProvider(_args).select((s) => s.isPosting),
    );
    return CommentEmojiPickerHost(
      controller: _commentCtrl,
      emojiPickerVisible: _emojiPickerVisible,
      dismissOnBackgroundTap: true,
      inputBar: CommentInputBar(
        key: _inputBarKey,
        controller: _commentCtrl,
        isPosting: isPosting,
        onSend: _postComment,
        emojiPickerVisible: _emojiPickerVisible,
        replyToNickname: _replyTarget?.replyToNickname,
        onCancelReply: () => setState(() => _replyTarget = null),
      ),
      builder: (context, inputBarHeight, keyboardInset) {
        final theme = Theme.of(context);
        final brightness = theme.brightness;
        const sheetH = StoryConstants.playerOverlaySheetHeight;
        Widget sheet = Container(
          height: sheetH,
          width: double.infinity,
          decoration: BoxDecoration(
            color: StoryColors.backgroundOf(brightness),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              StorySheetDragHandle(brightness: brightness),
              CommentTabHeader(
                brightness: brightness,
                controller: _tabController,
                labels: [context.l10n.commentsTabComments],
                showIndicator: false,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    CommentsTabContent(
                      dramaId: widget.dramaId,
                      episodeId: widget.episodeId,
                      episodeNo: widget.episodeNo,
                      commentCount: widget.commentCount,
                      highlightedComment: widget.highlightedComment,
                      emojiPickerVisible: _emojiPickerVisible,
                      inputBarKey: _inputBarKey,
                      scrollController: _listScroll,
                      bottomPadding: inputBarHeight,
                      keyboardInset: keyboardInset,
                      onReplyTargetChanged: _onReplyTargetChanged,
                    ),
                    // 临时隐藏「短剧 / 角色」Tab 内容，恢复时取消注释。
                    // DramasTabContent(dramaId: widget.dramaId),
                    // ActorsTabContent(dramaId: widget.dramaId),
                  ],
                ),
              ),
            ],
          ),
        );
        final heightNotifier = widget.sheetHeightNotifier;
        if (heightNotifier != null) {
          sheet = PlayerSheetHeightReporter(
            heightNotifier: heightNotifier,
            child: sheet,
          );
        }
        return sheet;
      },
    );
  }
}

/// 顶部 Tab 头部：默认评论 / 短剧 / 角色（居中）。
/// 监听 [TabController] 以反映滑动切换的中间态。
class CommentTabHeader extends StatefulWidget {
  const CommentTabHeader({
    super.key,
    required this.brightness,
    required this.controller,
    required this.labels,
    this.showIndicator = true,
  });

  final Brightness brightness;
  final TabController controller;

  /// Tab 文案。
  final List<String> labels;

  /// 是否显示选中态底部指示条。
  final bool showIndicator;

  @override
  State<CommentTabHeader> createState() => _CommentTabHeaderState();
}

class _CommentTabHeaderState extends State<CommentTabHeader> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.controller.index;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CommentTabHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _index = widget.controller.index;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final i = widget.controller.index;
    if (i != _index && mounted) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final divider = StoryColors.dividerOf(widget.brightness);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StorySpacing.base,
        StorySpacing.sm,
        StorySpacing.base,
        0,
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 全宽分割线与指示条底边贴合。
          if (widget.showIndicator)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ColoredBox(
                color: divider,
                child: const SizedBox(height: 1),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < labels.length; i++) ...[
                _CommentTab(
                  label: labels[i],
                  showIndicator: widget.showIndicator,
                  selected: i == _index,
                  brightness: widget.brightness,
                  onTap: () => widget.controller.animateTo(i),
                ),
                if (i < labels.length - 1)
                  const SizedBox(width: StorySpacing.lg),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 评论 Tab 项：16px 文案 + 选中态底部指示条。
/// 样式参照 Figma `Story.fun V2-ui` 节点 119-122225「web+app导航通用」：
/// 选中态 Bold `#EDEEF0` + 16×3 圆角指示条；未选中态 Regular `#B0B4BA`。
class _CommentTab extends StatelessWidget {
  const _CommentTab({
    required this.label,
    required this.brightness,
    this.showIndicator = true,
    this.selected = false,
    this.onTap,
  });

  final Brightness brightness;

  /// 是否显示选中态底部指示条。
  final bool showIndicator;

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? StoryColors.commentTabSelectedFgOf(brightness)
        : StoryColors.commentTabInactiveFgOf(brightness);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              height: 24 / 16,
              color: fg,
            ),
          ),
          if (showIndicator) ...[
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: selected ? fg : Colors.transparent,
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
