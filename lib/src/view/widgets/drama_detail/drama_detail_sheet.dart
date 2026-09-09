import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/components.dart';
import '../../../controller/comment_controller.dart';
import '../../../core/story_constants.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_format.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../utils/auth_navigation.dart';
import '../../../utils/format_number.dart';
import '../../../widgets/widgets.dart';
import '../video_comment/comment_bottom_sheet.dart';
import '../video_comment/comment_emoji_picker_host.dart';
import '../video_comment/comment_input_bar.dart';
import '../video_feed/player_sheet_height_reporter.dart';
import 'drama_characters_list.dart';
import 'drama_comments_tab.dart';
import 'rating_bottom_sheet.dart';
import '../../../foundation/navigator.dart';

/// Tabs on the recommend-feed drama overlay (H5 play-detail order).
enum DramaDetailSheetTab { comments, drama, characters }

/// Bottom sheet that reuses drama-detail content: comments, intro/episodes,
/// and characters. Returns a selected episode number, or `null` if dismissed.
class DramaDetailSheet extends ConsumerStatefulWidget {
  final String dramaId;
  final String? coverUrl;
  final DramaDetailSheetTab initialTab;
  final int? episodeNo;
  final String? episodeId;

  /// 内容类型（短视频 / 短剧），默认短剧。用于举报等按类型区分的操作。
  final WorkContentType contentType;

  /// When false, hides the drama [ContentBadge] above the title.
  final bool showContentBadge;

  /// 需要置顶高亮的评论（如从通知跳转进入时）。
  final StoryComment? highlightedComment;

  /// Reports sheet height for player collapse flush alignment.
  final ValueNotifier<double>? sheetHeightNotifier;

  const DramaDetailSheet({
    super.key,
    required this.dramaId,
    this.coverUrl,
    this.initialTab = DramaDetailSheetTab.drama,
    this.episodeNo,
    this.episodeId,
    this.contentType = WorkContentType.shortDrama,
    this.showContentBadge = false,
    this.highlightedComment,
    this.sheetHeightNotifier,
  });

  static Future<int?> show({
    required BuildContext context,
    required String dramaId,
    String? coverUrl,
    DramaDetailSheetTab initialTab = DramaDetailSheetTab.drama,
    int? episodeNo,
    String? episodeId,
    WorkContentType contentType = WorkContentType.shortDrama,
    bool showContentBadge = false,
    StoryComment? highlightedComment,
    ValueNotifier<double>? sheetHeightNotifier,
  }) {
    // 透明背景：弹层主体（固定高度、顶部圆角）由内部 Material 自绘，
    // 让浮层输入栏/emoji picker 可以超出主体高度渲染在键盘上沿。
    // Barrier stays transparent so the player can occupy the band above
    // the sheet; the feed collapses its surface while this route is open.
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (ctx) => DramaDetailSheet(
        dramaId: dramaId,
        coverUrl: coverUrl,
        initialTab: initialTab,
        episodeNo: episodeNo,
        episodeId: episodeId,
        contentType: contentType,
        showContentBadge: showContentBadge,
        highlightedComment: highlightedComment,
        sheetHeightNotifier: sheetHeightNotifier,
      ),
    );
  }

  @override
  ConsumerState<DramaDetailSheet> createState() => _DramaDetailSheetState();
}

class _DramaDetailSheetState extends ConsumerState<DramaDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _resolvedEpisodeId;
  bool _dramaEngagementLoaded = false;

  final _commentCtrl = TextEditingController();
  final _emojiPickerVisible = ValueNotifier<bool>(false);
  final _inputBarKey = GlobalKey<CommentInputBarState>();

  /// 评论列表滚动控制：发布一级评论后滚动回顶部展示置顶的新评论。
  final _listScroll = ScrollController();

  /// 当前回复目标；非空时输入栏进入回复模式。
  CommentReplyTarget? _replyTarget;

  /// 短视频只展示评论 Tab；短剧展示 评论 / 短剧 / 角色 三个 Tab。
  bool get _isShortVideo => widget.contentType.isShortVideo;

  CommentArgs _makeArgs(String episodeId) => CommentArgs(
    dramaId: widget.dramaId,
    episodeId: episodeId,
    episodeNo: widget.episodeNo,
  );

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: _isShortVideo ? 1 : 3,
      vsync: this,
      initialIndex: _isShortVideo ? 0 : widget.initialTab.index,
    );
    _tabs.addListener(_onTabChanged);
    _resolvedEpisodeId = widget.episodeId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Player surfaces already pass episodeId; only resolve when missing.
      if (_resolvedEpisodeId == null) {
        unawaited(_hydrate());
      }
      if (!_isShortVideo && widget.initialTab == DramaDetailSheetTab.drama) {
        _ensureDramaEngagementLoaded();
      }
    });
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _commentCtrl.dispose();
    _listScroll.dispose();
    _emojiPickerVisible.dispose();
    super.dispose();
  }

  /// 切换离开评论 Tab 时重置输入态：收起 emoji picker、隐藏键盘、
  /// 清空输入内容，让输入栏恢复默认（未编辑）状态。
  void _onTabChanged() {
    if (_tabs.index != DramaDetailSheetTab.comments.index) {
      _emojiPickerVisible.value = false;
      _commentCtrl.clear();
      _inputBarKey.currentState?.resetToIdle();
    }
    if (_tabs.index == DramaDetailSheetTab.drama.index) {
      _ensureDramaEngagementLoaded();
    }
    // 切 Tab 时同步刷新输入栏浮层显隐（仅评论 Tab 显示）。
    setState(() {});
  }

  void _ensureDramaEngagementLoaded() {
    if (_dramaEngagementLoaded) return;
    _dramaEngagementLoaded = true;
    if (ref.read(authControllerProvider).isLoggedIn) {
      ref
          .read(dramaEngagementProvider(widget.dramaId).notifier)
          .loadMyRating();
    }
  }

  Future<void> _hydrate() async {
    final episodeNo = widget.episodeNo ?? 1;
    await ref
        .read(engagementHydratorProvider)
        .hydrateEpisode(
          dramaId: widget.dramaId,
          episodeNo: episodeNo,
          onEpisodeResolved: (episodeId) {
            if (!mounted || _resolvedEpisodeId == episodeId) return;
            setState(() => _resolvedEpisodeId = episodeId);
          },
        );
  }

  Future<void> _postComment() async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;
    // 发送时收起 emoji picker。
    _emojiPickerVisible.value = false;
    final episodeId = _resolvedEpisodeId;
    if (episodeId == null) return;
    final args = _makeArgs(episodeId);
    final notifier = ref.read(commentControllerProvider(args).notifier);
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
    if (posted && mounted) {
      _commentCtrl.clear();
      // 发布成功后收起键盘并复位输入栏到初始状态。
      _inputBarKey.currentState?.resetToIdle();
      setState(() => _replyTarget = null);
      // 一级评论置顶后滚动回列表顶部，让新评论可见。
      if (isTopLevel && _listScroll.hasClients) {
        _listScroll.jumpTo(0);
      }
      return;
    }
    // 失败提示（如黑名单拦截 / 服务端返回评论不存在(125101)）。一级评论
    // 无回复组，读 state 级；根评论被 125101 连根移除后组级错误随之丢失，
    // 故回复同样优先读 state 级。
    if (mounted) {
      final error = target == null
          ? notifier.lastError
          : (notifier.lastError ??
                notifier.replyGroupOf(target.rootId)?.lastError);
      if (error != null) {
        StoryToast.error(context, context.l10nError(error), rootOverlay: true);
      }
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final episodeId = _resolvedEpisodeId;
    final isPosting = episodeId == null
        ? false
        : ref.watch(
            commentControllerProvider(
              _makeArgs(episodeId),
            ).select((s) => s.isPosting),
          );
    // 仅评论 Tab 渲染浮层输入栏；其余 Tab 隐藏。
    final inputBar = _tabs.index == DramaDetailSheetTab.comments.index
        ? CommentInputBar(
            key: _inputBarKey,
            controller: _commentCtrl,
            isPosting: isPosting,
            onSend: _postComment,
            emojiPickerVisible: _emojiPickerVisible,
            replyToNickname: _replyTarget?.replyToNickname,
            onCancelReply: () => setState(() => _replyTarget = null),
          )
        : null;

    return CommentEmojiPickerHost(
      controller: _commentCtrl,
      emojiPickerVisible: _emojiPickerVisible,
      dismissOnBackgroundTap: true,
      inputBar: inputBar,
      builder: (context, inputBarHeight, keyboardInset) {
        const sheetH = StoryConstants.playerOverlaySheetHeight;
        Widget sheet = SizedBox(
          height: sheetH,
          width: double.infinity,
          child: Material(
            color: StoryColors.backgroundOf(brightness),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: StorySpacing.sm),
                  child: Center(
                    child: Container(
                      width: StorySizes.dragHandleWidth,
                      height: StorySizes.dragHandleHeight,
                      decoration: BoxDecoration(
                        color: StoryColors.dividerOf(brightness),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                CommentTabHeader(
                  brightness: brightness,
                  controller: _tabs,
                  // 短视频只有单一评论 Tab，隐藏选中态指示条。
                  showIndicator: !_isShortVideo,
                  labels: _isShortVideo
                      ? [l10n.dramaDetailTabComments]
                      : [
                          l10n.dramaDetailTabComments,
                          l10n.theaterTabShortDrama,
                          l10n.dramaDetailTabRoles,
                        ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      DramaCommentsTab(
                        dramaId: widget.dramaId,
                        episodeId: _resolvedEpisodeId,
                        episodeNo: widget.episodeNo,
                        highlightedComment: widget.highlightedComment,
                        emojiPickerVisible: _emojiPickerVisible,
                        inputBarKey: _inputBarKey,
                        scrollController: _listScroll,
                        bottomPadding: inputBarHeight,
                        keyboardInset: keyboardInset,
                        onReplyTargetChanged: _onReplyTargetChanged,
                      ),
                      if (!_isShortVideo) ...[
                        _DramaDetailTabLoader(
                          dramaId: widget.dramaId,
                          coverUrl: widget.coverUrl,
                          episodeNo: widget.episodeNo ?? 1,
                          showContentBadge: widget.showContentBadge,
                          onSelectEpisode: (epNo) =>
                              Navigator.of(context).pop(epNo),
                          onRate: (d) => unawaited(_showRating(d)),
                        ),
                        _CharactersTabLoader(dramaId: widget.dramaId),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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

  Future<void> _showRating(DramaDetail d) async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!mounted) return;
    final l10n = context.l10n;
    StoryBottomSheet.showCommentSheet<void>(
      context: context,
      builder: (_) => RatingBottomSheet(
        initialRating:
            ref.read(dramaEngagementProvider(widget.dramaId)).myRating ?? 0,
        onRated: (rating) async {
          final res = await ref
              .read(dramaEngagementProvider(widget.dramaId).notifier)
              .submitRating(rating, authorUserId: d.userId);
          if (res == null) return;
          if (res.isSuccess && mounted) {
            StoryToast.success(context, l10n.dramaDetailRatingSuccess(rating));
            ref.invalidate(dramaDetailProvider(widget.dramaId));
          } else if (mounted && res.isFailure) {
            StoryToast.error(context, context.l10nError(res.errorOrNull!));
          }
        },
      ),
    );
  }
}

class _DramaDetailTabLoader extends ConsumerWidget {
  final String dramaId;
  final String? coverUrl;
  final int episodeNo;
  final bool showContentBadge;
  final ValueChanged<int> onSelectEpisode;
  final ValueChanged<DramaDetail> onRate;

  const _DramaDetailTabLoader({
    required this.dramaId,
    required this.coverUrl,
    required this.episodeNo,
    required this.showContentBadge,
    required this.onSelectEpisode,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final resultAsync = ref.watch(dramaDetailProvider(dramaId));
    return resultAsync.when(
      loading: () =>
          StoryStateWidget.loading(message: l10n.dramaDetailLoading),
      error: (e, _) => StoryStateWidget.error(
        message: e.toString(),
        actionLabel: l10n.dramaDetailRetry,
        onAction: () => ref.invalidate(dramaDetailProvider(dramaId)),
      ),
      data: (result) {
        if (result.isFailure) {
          return StoryStateWidget.error(
            message: result.errorOrNull!.userMessage,
            actionLabel: l10n.dramaDetailRetry,
            onAction: () => ref.invalidate(dramaDetailProvider(dramaId)),
          );
        }
        final drama = result.dataOrNull!;
        return _DramaTab(
          drama: drama,
          dramaId: dramaId,
          coverUrl: coverUrl,
          episodeNo: episodeNo,
          showContentBadge: showContentBadge,
          onSelectEpisode: onSelectEpisode,
          onRate: () => onRate(drama),
        );
      },
    );
  }
}

class _CharactersTabLoader extends ConsumerWidget {
  final String dramaId;

  const _CharactersTabLoader({required this.dramaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final resultAsync = ref.watch(dramaDetailProvider(dramaId));
    return resultAsync.when(
      loading: () =>
          StoryStateWidget.loading(message: l10n.dramaDetailLoading),
      error: (e, _) => StoryStateWidget.error(
        message: e.toString(),
        actionLabel: l10n.dramaDetailRetry,
        onAction: () => ref.invalidate(dramaDetailProvider(dramaId)),
      ),
      data: (result) {
        if (result.isFailure) {
          return StoryStateWidget.error(
            message: result.errorOrNull!.userMessage,
            actionLabel: l10n.dramaDetailRetry,
            onAction: () => ref.invalidate(dramaDetailProvider(dramaId)),
          );
        }
        return DramaCharactersList(roles: result.dataOrNull!.roles ?? const []);
      },
    );
  }
}

class _DramaTab extends ConsumerWidget {
  /// Cover + title column height. Taller than the old 96 so the favorite
  /// icon+count under the title does not overflow the fixed box.
  static const double _dramaTabCoverHeight = 108;

  final DramaDetail drama;
  final String dramaId;
  final String? coverUrl;
  final int episodeNo;
  final bool showContentBadge;
  final ValueChanged<int> onSelectEpisode;
  final VoidCallback onRate;

  const _DramaTab({
    required this.drama,
    required this.dramaId,
    required this.coverUrl,
    required this.episodeNo,
    this.showContentBadge = false,
    required this.onSelectEpisode,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final completionVal = drama.totalCompletedViewCount ?? 0;
    final playCount = StoryFormat.formatCount(completionVal);
    final heatScore =
        formatHeatValue(drama.totalHeatValue) ??
        formatHeatValue(
          (drama.totalPlayCount ?? 0) + (drama.favoriteCount ?? 0) * 10,
        ) ??
        '0';
    final cover = (drama.coverUrl ?? coverUrl)?.trim();
    final currentEpisode = ref.watch(currentDramaEpisodeProvider(dramaId));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            StorySpacing.screenHorizontal,
            StorySpacing.md,
            StorySpacing.screenHorizontal,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: StoryRadius.brMd,
                      child: SizedBox(
                        width: 72,
                        height: _dramaTabCoverHeight,
                        child: cover != null && cover.isNotEmpty
                            ? StoryCachedImage(
                                imageUrl: cover,
                                width: 72,
                                height: _dramaTabCoverHeight,
                                memCacheWidth:
                                    StoryCachedImage.memCacheForLogicalWidth(
                                      context,
                                      72,
                                    ),
                                placeholder: ColoredBox(
                                  color: StoryColors.mutedOf(brightness),
                                ),
                                errorWidget: ColoredBox(
                                  color: StoryColors.mutedOf(brightness),
                                ),
                              )
                            : ColoredBox(
                                color: StoryColors.mutedOf(brightness),
                              ),
                      ),
                    ),
                    const SizedBox(width: StorySpacing.md),
                    Expanded(
                      child: SizedBox(
                        height: _dramaTabCoverHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: drama.title?.isNotEmpty == true
                                      ? Text(
                                          drama.title!,
                                          softWrap: true,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              StoryTextStyles.headingMedium(
                                                color: StoryColors.foregroundOf(
                                                  brightness,
                                                ),
                                              ).copyWith(
                                                fontWeight: FontWeight.bold,
                                                height: 1.25,
                                              ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                _DramaTabFavoriteButton(
                                  dramaId: dramaId,
                                  episodeNo: episodeNo,
                                  favoriteCount: drama.favoriteCount,
                                  favoritedByMe: drama.favoritedByMe,
                                ),
                                _DramaTabReportButton(
                                  dramaId: dramaId,
                                  drama: drama,
                                ),
                              ],
                            ),
                            if (showContentBadge &&
                                ContentBadgeValue.fromApiValue(drama.badge) !=
                                    null) ...[
                              const SizedBox(height: StorySpacing.xs),
                              ContentBadge(
                                badge: drama.badge,
                                variant: ContentBadgeVariant.drama,
                              ),
                            ],
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      clipBehavior: Clip.hardEdge,
                                      children: [
                                        if (drama.avgRating != null)
                                          _MetaPill(
                                            brightness: brightness,
                                            icon: Icons.star_rounded,
                                            iconColor: StoryColors.warning,
                                            label: drama.avgRating!
                                                .toStringAsFixed(1),
                                          ),
                                        if (drama.totalEpisodes != null)
                                          _MetaPill(
                                            brightness: brightness,
                                            label: l10n.dramaAllEpisodesFull(
                                              drama.totalEpisodes!,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (drama.tags != null &&
                                        drama.tags!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        clipBehavior: Clip.hardEdge,
                                        children: [
                                          for (final tag in drama.tags!)
                                            _MetaPill(
                                              brightness: brightness,
                                              label: tag,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: StorySpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _OverlayStatCard(
                        brightness: brightness,
                        value: playCount,
                        label: l10n.dramaDetailCompletionLabel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OverlayStatCard(
                        brightness: brightness,
                        value: heatScore,
                        label: l10n.dramaDetailHeatLabel,
                      ),
                    ),
                  ],
                ),
                if (drama.description?.isNotEmpty == true) ...[
                  const SizedBox(height: StorySpacing.lg),
                  _OverlaySynopsis(description: drama.description!),
                ],
                const SizedBox(height: StorySpacing.md),
                _OverlayRatingRow(dramaId: dramaId, onRate: onRate),
                const SizedBox(height: StorySpacing.md),
              ],
            ),
          ),
        ),
        EpisodePickerListSliver(
          dramaId: dramaId,
          currentEpisode: currentEpisode == 0 ? episodeNo : currentEpisode,
          fallbackCoverUrl: cover,
          onSelect: onSelectEpisode,
          padding: const EdgeInsets.fromLTRB(
            StorySpacing.screenHorizontal,
            0,
            StorySpacing.screenHorizontal,
            StorySpacing.screenHorizontal,
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final Brightness brightness;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const _MetaPill({
    required this.brightness,
    required this.label,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: StoryColors.dramaOverlayTagBgOf(brightness),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: StoryColors.dramaOverlayStatBorderOf(brightness),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayStatCard extends StatelessWidget {
  final Brightness brightness;
  final String value;
  final String label;

  const _OverlayStatCard({
    required this.brightness,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: StoryColors.dramaOverlayStatBgOf(brightness),
        borderRadius: StoryRadius.brLg,
        border: Border.all(
          color: StoryColors.dramaOverlayStatBorderOf(brightness),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: StoryTextStyles.headingLarge(
              color: StoryColors.foregroundOf(brightness),
            ).copyWith(fontWeight: FontWeight.w700, height: 1.2),
          ),
          Text(
            label,
            style: StoryTextStyles.bodySmall(
              color: StoryColors.mutedForegroundOf(brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlaySynopsis extends StatefulWidget {
  final String description;

  const _OverlaySynopsis({required this.description});

  @override
  State<_OverlaySynopsis> createState() => _OverlaySynopsisState();
}

class _OverlaySynopsisState extends State<_OverlaySynopsis> {
  static const int _collapseThreshold = 40;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final muted = StoryColors.mutedForegroundOf(brightness);
    final showToggle = widget.description.length > _collapseThreshold;
    final text = '${l10n.dramaDetailSynopsisLead}${widget.description}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: _expanded ? null : 2,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: StoryTextStyles.bodyMedium(color: muted),
          ),
        ),
        if (showToggle)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(left: StorySpacing.sm),
              child: Text(
                _expanded ? l10n.dramaDetailCollapse : l10n.dramaDetailExpand,
                style: StoryTextStyles.titleMedium(
                  color: StoryColors.foregroundOf(brightness),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 短剧 Tab 标题行右上角收藏。
class _DramaTabFavoriteButton extends ConsumerWidget {
  final String dramaId;
  final int episodeNo;
  final int? favoriteCount;
  final bool? favoritedByMe;

  const _DramaTabFavoriteButton({
    required this.dramaId,
    required this.episodeNo,
    this.favoriteCount,
    this.favoritedByMe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final eng = ref.watch(dramaEngagementProvider(dramaId));
    final favorited = eng.favoritedByMe ?? favoritedByMe ?? false;
    final iconColor = StoryColors.foregroundOf(brightness);

    return Semantics(
      button: true,
      label: context.l10n.playerFavorite,
      child: GestureDetector(
        onTap: () async {
          if (!await ensureLoggedInOrRedirect(context, ref)) return;
          if (!context.mounted) return;
          final notifier = ref.read(dramaEngagementProvider(dramaId).notifier);
          notifier.seed(
            favoritedByMe: eng.favoritedByMe ?? favoritedByMe,
            favoriteCount: eng.favoriteCount ?? favoriteCount,
          );
          final wasFavorited =
              ref.read(dramaEngagementProvider(dramaId)).favoritedByMe ?? false;
          final result = await notifier.toggleFavorite(episodeNo: episodeNo);
          if (!context.mounted || result == null) return;
          if (result.isFailure) {
            StoryToast.error(context, context.l10nError(result.errorOrNull!));
            return;
          }
          StoryToast.success(
            context,
            wasFavorited
                ? context.l10n.dramaUnfavorited
                : context.l10n.dramaFavorited,
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(left: StorySpacing.sm),
          child: favorited
              ? SvgPicture.asset(
                  'assets/drama/detail_favorite_s.svg',
                  width: 22,
                  height: 22,
                )
              : SvgPicture.asset(
                  'assets/drama/detail_favorite.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
        ),
      ),
    );
  }
}

/// 短剧 Tab 标题行右上角「横向三点」：点击跳转举报页，举报整个短剧
/// （scope=DRAMA，以 dramaId 为目标，不绑定当前剧集）。
class _DramaTabReportButton extends ConsumerWidget {
  final String dramaId;
  final DramaDetail drama;

  const _DramaTabReportButton({required this.dramaId, required this.drama});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final iconColor = StoryColors.foregroundOf(brightness);

    // 自己的作品不显示举报入口。
    final creatorId = drama.userId?.trim() ?? '';
    final myId = ref.watch(
      authControllerProvider.select((c) => c.userId?.trim() ?? ''),
    );
    if (creatorId.isNotEmpty && creatorId == myId) {
      return const SizedBox.shrink();
    }

    return Semantics(
      button: true,
      label: context.l10n.playerReport,
      child: GestureDetector(
        onTap: () async {
          if (!await ensureLoggedInOrRedirect(context, ref)) return;
          if (!context.mounted) return;
          context.storyPush(RouteNames.report, arguments: <String, dynamic>{
              'scope': UgcReportScope.drama,
              'dramaId': dramaId,
              'userId': drama.userId,
              'targetDisplayName': drama.creatorName,
              'targetAvatarUrl': drama.creatorAvatarUrl,
              'contentTitle': drama.title,
              'contentCoverUrl': drama.coverUrl,
            });
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(left: StorySpacing.sm, top: 2),
          child: Icon(Icons.more_horiz, size: 22, color: iconColor),
        ),
      ),
    );
  }
}

class _OverlayRatingRow extends ConsumerWidget {
  final String dramaId;
  final VoidCallback onRate;

  const _OverlayRatingRow({required this.dramaId, required this.onRate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final divider = StoryColors.borderOf(brightness);
    final fg = StoryColors.foregroundOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);
    final myRating = ref.watch(
      dramaEngagementProvider(dramaId).select((s) => s.myRating),
    );
    final rated = myRating != null && myRating > 0;

    return Column(
      children: [
        Divider(height: 1, thickness: 0.5, color: divider),
        GestureDetector(
          onTap: onRate,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: StorySpacing.md),
            child: Row(
              children: [
                Text(
                  l10n.dramaDetailWantToRate,
                  maxLines: 1,
                  softWrap: false,
                  style: StoryTextStyles.bodyMedium(
                    color: fg,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: StorySpacing.sm),
                for (var i = 1; i <= 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      rated && i <= myRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 24,
                      color: rated && i <= myRating ? StoryColors.star : muted,
                    ),
                  ),
                const SizedBox(width: StorySpacing.sm),
                // Trailing status / score: expand so the value sits flush right;
                // long "not rated" copy may ellipsis.
                Expanded(
                  child: Text(
                    rated ? '$myRating' : l10n.dramaDetailNotRated,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: StoryTextStyles.bodyMedium(color: muted),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 0.5, color: divider),
      ],
    );
  }
}
