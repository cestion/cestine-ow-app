import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:story_app/src/view/widgets/drama_detail/drama_comments_tab.dart';
import 'package:story_app/src/view/widgets/drama_detail/drama_stat_card.dart';
import 'package:story_app/src/view/widgets/drama_detail/rating_bottom_sheet.dart';
import 'package:story_app/src/view/widgets/video_comment/comment_emoji_picker_host.dart';
import 'package:story_app/src/view/widgets/video_comment/comment_input_bar.dart';

import '../components/components.dart';
import '../controller/comment_controller.dart';
import '../controller/engagement_state.dart';
import '../core/episode_play_handoff.dart';
import '../core/story_constants.dart';
import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../routes/video_feed_playlist_entry_seeds.dart';
import '../routes/route_args.dart';
import '../routes/video_feed_navigation.dart';
import '../services/playback_entry_warmup.dart';
import '../styles/story_colors.dart';
import '../styles/story_format.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../utils/auth_navigation.dart';
import '../utils/format_number.dart';
import '../widgets/widgets.dart';
import 'widgets/drama_detail/batch_unlock_banner.dart';
import 'widgets/drama_detail/drama_characters_section.dart';
import 'widgets/drama_detail/drama_engagement_bar.dart';

class DramaDetailPage extends ConsumerStatefulWidget {
  final String dramaId;
  final String? coverUrl;
  final bool autoPlayFirstEpisode;
  final List<VideoFeedPlaylistEntry> searchPlaylist;
  final int searchPlaylistIndex;

  /// When false, hides the drama [ContentBadge] next to the title.
  final bool showContentBadge;

  const DramaDetailPage({
    super.key,
    required this.dramaId,
    this.coverUrl,
    this.autoPlayFirstEpisode = false,
    this.searchPlaylist = const [],
    this.searchPlaylistIndex = 0,
    this.showContentBadge = false,
  });

  @override
  ConsumerState<DramaDetailPage> createState() => _DramaDetailPageState();
}

class _DramaDetailPageState extends ConsumerState<DramaDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isDescriptionExpanded = false;
  String? _resolvedEpisodeId;
  bool _didAutoPlayFirstEpisode = false;

  final _commentCtrl = TextEditingController();
  final _emojiPickerVisible = ValueNotifier<bool>(false);
  final _inputBarKey = GlobalKey<CommentInputBarState>();

  /// 评论列表滚动控制：发布一级评论后滚动回顶部展示置顶的新评论。
  final _listScroll = ScrollController();

  /// 当前回复目标；非空时输入栏进入回复模式。
  CommentReplyTarget? _replyTarget;

  CommentArgs _commentArgs(String episodeId) => CommentArgs(
    dramaId: widget.dramaId,
    episodeId: episodeId,
    episodeNo: ref.read(currentDramaEpisodeProvider(widget.dramaId)),
  );

  EpisodeEngagementKey? get _episodeEngagementKey {
    final episodeId = _resolvedEpisodeId;
    if (episodeId == null) return null;
    return EpisodeEngagementKey.tryForEpisode(
      dramaId: widget.dramaId,
      episodeId: episodeId,
      episodeNo: ref.read(currentDramaEpisodeProvider(widget.dramaId)),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resolveCommentEpisode();
      // my-review requires auth; calling it as a guest returns 401 and used
      // to trigger global logout + popToRoot, ejecting users from this page.
      if (ref.read(authControllerProvider).isLoggedIn) {
        ref
            .read(dramaEngagementProvider(widget.dramaId).notifier)
            .loadMyRating();
      }
    });
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
    if (_tabController.index != 2) {
      _emojiPickerVisible.value = false;
      _commentCtrl.clear();
      _inputBarKey.currentState?.resetToIdle();
    }
    // 切 Tab 时同步刷新输入栏浮层显隐（仅评论 Tab 显示）。
    setState(() {});
  }

  Future<void> _postComment() async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;
    // 发送时收起 emoji picker。
    _emojiPickerVisible.value = false;
    final episodeId = _resolvedEpisodeId;
    if (episodeId == null) return;
    final args = _commentArgs(episodeId);
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

  Future<void> _resolveCommentEpisode() async {
    final episodeNo = ref.read(currentDramaEpisodeProvider(widget.dramaId));
    // Two-phase: instant local seed → authoritative server refresh; see
    // [EngagementHydrator]. The page only reacts to the resolved episodeId.
    await ref
        .read(engagementHydratorProvider)
        .hydrateEpisode(
          dramaId: widget.dramaId,
          episodeNo: episodeNo,
          onEpisodeResolved: (episodeId) {
            if (!mounted || _resolvedEpisodeId == episodeId) return;
            setState(() {
              _resolvedEpisodeId = episodeId;
            });
          },
        );
  }

  /// 当前剧集评论是否提交中（驱动输入栏发送按钮 loading 态）。
  bool get _isCommentPosting {
    final episodeId = _resolvedEpisodeId;
    if (episodeId == null) return false;
    return ref.watch(
      commentControllerProvider(
        _commentArgs(episodeId),
      ).select((s) => s.isPosting),
    );
  }

  void _reload() {
    ref.invalidate(dramaDetailProvider(widget.dramaId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resultAsync = ref.watch(dramaDetailProvider(widget.dramaId));

    return resultAsync.when(
      loading: () => AppScaffold(
        title: l10n.dramaDetailTitle,
        body: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildHeroCover(
                coverUrl: widget.coverUrl,
                showLoading: true,
                onTap: null,
              ),
            ),
            Expanded(
              child: StoryStateWidget.loading(message: l10n.dramaDetailLoading),
            ),
          ],
        ),
      ),
      error: (e, _) => AppScaffold(
        title: l10n.dramaDetailTitle,
        body: StoryStateWidget.error(
          message: e.toString(),
          actionLabel: l10n.dramaDetailRetry,
          onAction: _reload,
        ),
      ),
      data: (result) {
        if (result.isFailure) {
          return AppScaffold(
            title: l10n.dramaDetailTitle,
            body: StoryStateWidget.error(
              message: result.errorOrNull!.userMessage,
              actionLabel: l10n.dramaDetailRetry,
              onAction: _reload,
            ),
          );
        }
        final d = result.dataOrNull!;
        final theme = Theme.of(context);
        _maybeAutoPlayFirstEpisode(d);

        return AppScaffold(
          title: d.title ?? l10n.dramaDetailTitle,
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildHeroCover(
                  coverUrl: d.coverUrl ?? widget.coverUrl,
                  showLoading: false,
                  onTap: () => _openPlayer(
                    d,
                    episodeNo: ref.read(
                      currentDramaEpisodeProvider(widget.dramaId),
                    ),
                  ),
                ),
              ),
              ColoredBox(
                color: StoryColors.backgroundOf(theme.brightness),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: StorySpacing.screenHorizontal,
                      ),
                      child: StoryTabBar(
                        controller: _tabController,
                        isScrollable: true,
                        showDivider: false,
                        tabs: [
                          Tab(text: l10n.dramaDetailTabIntro),
                          Tab(text: l10n.dramaDetailTabEpisodes),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.dramaDetailTabComments),
                                _buildCommentCountBadge(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: StoryColors.borderOf(theme.brightness),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CommentEmojiPickerHost(
                  controller: _commentCtrl,
                  emojiPickerVisible: _emojiPickerVisible,
                  // 仅评论 Tab 渲染浮层输入栏；其余 Tab 隐藏。
                  inputBar: _tabController.index == 2
                      ? CommentInputBar(
                          key: _inputBarKey,
                          controller: _commentCtrl,
                          isPosting: _isCommentPosting,
                          onSend: _postComment,
                          emojiPickerVisible: _emojiPickerVisible,
                          replyToNickname: _replyTarget?.replyToNickname,
                          onCancelReply: () =>
                              setState(() => _replyTarget = null),
                        )
                      : null,
                  builder: (context, inputBarHeight, keyboardInset) =>
                      TabBarView(
                        controller: _tabController,
                        children: [
                          _buildInfoTab(d, theme),
                          _buildEpisodesTab(d, theme),
                          _buildCommentsTab(d, inputBarHeight, keyboardInset),
                        ],
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Cover + play affordance only — detail no longer hosts an inline player.
  Widget _buildHeroCover({
    required String? coverUrl,
    required bool showLoading,
    required VoidCallback? onTap,
  }) {
    return ColoredBox(
      color: StoryColors.footer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildCoverImage(coverUrl)),
          if (onTap != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/drama/player_play.svg',
                    width: StorySizes.playerPlayIconWidth,
                    height: StorySizes.playerPlayIconHeight,
                  ),
                ),
              ),
            ),
          if (showLoading)
            const Center(
              child: SizedBox(
                width: StorySizes.loadingSmall,
                height: StorySizes.loadingSmall,
                child: CircularProgressIndicator(
                  strokeWidth: StorySizes.loadingStroke,
                  color: StoryColors.onOverlay,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Search drama card: open episode 1 once. Does not write Hive progress.
  void _maybeAutoPlayFirstEpisode(DramaDetail d) {
    if (!widget.autoPlayFirstEpisode || _didAutoPlayFirstEpisode) return;
    _didAutoPlayFirstEpisode = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_openPlayer(d, episodeNo: 1));
    });
  }

  /// Opens the vertical feed player and syncs the returned episode back.
  Future<void> _openPlayer(DramaDetail d, {required int episodeNo}) async {
    if (!mounted) return;

    // Warm-start like Theater banner: reuse episode play already fetched for
    // comments / engagement so feed entry skips a cold network wait.
    var warmStart = false;
    DramaPlayResponse? cachedPlay;
    try {
      cachedPlay = await ref
          .read(dramaRepositoryProvider)
          .peekPrefetchedEpisode(widget.dramaId, episodeNo);
      if (cachedPlay != null) {
        PlaybackEntryWarmup.primeFrameCacheAround(
          dramaId: widget.dramaId,
          episodeNo: episodeNo,
          episodeIdsByNo: {
            if (cachedPlay.episodeId != null) episodeNo: cachedPlay.episodeId,
          },
        );
        EpisodePlayHandoff.offer(
          dramaId: widget.dramaId,
          episodeNo: episodeNo,
          play: cachedPlay,
          diskWarmed: PlaybackEntryWarmup.isPlayUrlDiskWarmed(
            cachedPlay.effectivePlayUrl,
          ),
        );
        warmStart = true;
      }
    } catch (_) {
      // Best-effort; feed will fetch if handoff is missing.
    }
    if (!mounted) return;

    final chrome = VideoFeedPlaylistEntrySeeds.fromDramaDetail(
      d,
      dramaId: widget.dramaId,
    ).mergePlay(cachedPlay);

    final episodeCover = cachedPlay?.posterUrl?.trim().isNotEmpty == true
        ? cachedPlay!.posterUrl
        : null;

    // Prefer popping back to an existing player for this drama
    // (List → Player → Detail → play again) instead of stacking another feed.
    if (VideoFeedNavigation.isOpen(widget.dramaId)) {
      ref
          .read(currentDramaEpisodeProvider(widget.dramaId).notifier)
          .setEpisode(episodeNo);
      await VideoFeedNavigation.open(
        context,
        dramaId: widget.dramaId,
        episodeNo: episodeNo,
        title: d.title ?? '',
        totalEpisodes: d.totalEpisodes ?? 1,
        coverUrl: d.coverUrl ?? widget.coverUrl,
        episodeCoverUrl: episodeCover,
        description: d.description,
        fromDramaDetail: true,
        searchPlaylist: widget.searchPlaylist,
        searchPlaylistIndex: widget.searchPlaylistIndex,
        searchDramaPlaylist: widget.searchPlaylist.isNotEmpty,
        chrome: chrome,
      );
      return;
    }

    final result = await VideoFeedNavigation.open(
      context,
      dramaId: widget.dramaId,
      episodeNo: episodeNo,
      title: d.title ?? '',
      totalEpisodes: d.totalEpisodes ?? 1,
      coverUrl: d.coverUrl ?? widget.coverUrl,
      episodeCoverUrl: episodeCover,
      description: d.description,
      fromDramaDetail: true,
      warmStart: warmStart,
      searchPlaylist: widget.searchPlaylist,
      searchPlaylistIndex: widget.searchPlaylistIndex,
      searchDramaPlaylist: widget.searchPlaylist.isNotEmpty,
      chrome: chrome,
    );
    if (result is int && mounted) {
      ref
          .read(currentDramaEpisodeProvider(widget.dramaId).notifier)
          .setEpisode(result);
    }
  }

  Widget _buildCoverImage(String? coverUrl) {
    final url = coverUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return StoryCachedImage(
        imageUrl: url,
        memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
          context,
          StoryImageCache.coverDetail,
        ),
        placeholder: const ColoredBox(color: StoryColors.overlaySubtle),
        errorWidget: const Center(
          child: Icon(
            Icons.movie_outlined,
            size: 48,
            color: StoryColors.onOverlay,
          ),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.movie_outlined, size: 48, color: StoryColors.onOverlay),
    );
  }

  Widget _buildInfoTab(DramaDetail d, ThemeData theme) {
    final l10n = context.l10n;
    final completionVal = d.totalCompletedViewCount ?? 0;
    final playCount = StoryFormat.formatCount(completionVal);

    final heatScore =
        formatHeatValue(d.totalHeatValue) ??
        formatHeatValue(
          (d.totalPlayCount ?? 0) + (d.favoriteCount ?? 0) * 10,
        ) ??
        '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.roles != null && d.roles!.isNotEmpty) ...[
            DramaCharactersSection(roles: d.roles!),
            const SizedBox(height: StorySpacing.xs),
          ],
          if (d.title?.isNotEmpty == true ||
              (widget.showContentBadge &&
                  ContentBadgeValue.fromApiValue(d.badge) != null)) ...[
            Builder(
              builder: (context) {
                final titleStyle = TextStyle(
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w700,
                  color: StoryColors.foregroundOf(theme.brightness),
                );
                final hasTitle = d.title?.isNotEmpty == true;
                final hasBadge =
                    widget.showContentBadge &&
                    ContentBadgeValue.fromApiValue(d.badge) != null;
                if (hasTitle && hasBadge) {
                  // Badge sits immediately after the title glyphs (not trailing
                  // the full row), wrapping with the last line of text.
                  return Text.rich(
                    TextSpan(
                      style: titleStyle,
                      children: [
                        TextSpan(text: d.title!),
                        const WidgetSpan(child: SizedBox(width: 8)),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: ContentBadge(
                            badge: d.badge,
                            variant: ContentBadgeVariant.drama,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (hasTitle) {
                  return Text(d.title!, softWrap: true, style: titleStyle);
                }
                return ContentBadge(
                  badge: d.badge,
                  variant: ContentBadgeVariant.drama,
                );
              },
            ),
            const SizedBox(height: StorySpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: DramaStatCard(
                  svgAsset: 'assets/drama/detail_play.svg',
                  label: l10n.dramaDetailCompletion(playCount),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DramaStatCard(
                  svgAsset: 'assets/drama/detail_hot.svg',
                  label: l10n.dramaDetailHeat(heatScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: StorySpacing.xl),
          if (d.description?.isNotEmpty == true) ...[
            Text(
              l10n.dramaDetailSynopsis,
              style: StoryTextStyles.headingMedium(
                color: StoryColors.foregroundOf(theme.brightness),
              ),
            ),
            const SizedBox(height: StorySpacing.xs),
            _ExpandableDescription(
              text: d.description!,
              expanded: _isDescriptionExpanded,
              color: StoryColors.foregroundOf(theme.brightness),
              expandLabel: l10n.dramaDetailExpand,
              collapseLabel: l10n.dramaDetailCollapse,
              onToggle: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
            ),
            const SizedBox(height: StorySpacing.sm),
          ],
          DramaDetailTags(drama: d),
          const SizedBox(height: StorySpacing.sm),
          DramaEngagementBar(
            dramaId: d.id ?? widget.dramaId,
            episodeApiId: _resolvedEpisodeId,
            episodeNo: ref.watch(currentDramaEpisodeProvider(widget.dramaId)),
            onShare: () => StoryShare.shareDrama(
              context: context,
              dramaId: d.id ?? widget.dramaId,
              title: d.title,
              fallbackTitle: l10n.dramaDetailTitle,
            ),
            favoriteCount: d.favoriteCount,
            avgRating: d.avgRating,
            onRate: () => _showRatingBottomSheet(d),
          ),
          const SizedBox(height: StorySpacing.xl),
        ],
      ),
    );
  }

  Widget _buildEpisodesTab(DramaDetail d, ThemeData theme) {
    final l10n = context.l10n;
    final total = d.totalEpisodes ?? 0;
    if (total == 0) {
      return Center(
        child: Text(
          l10n.dramaDetailNoEpisodes,
          style: StoryTextStyles.bodySmall(),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            StorySpacing.screenHorizontal,
            StorySpacing.screenHorizontal,
            StorySpacing.screenHorizontal,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      l10n.dramaDetailTabEpisodes,
                      style: StoryTextStyles.headingMedium(
                        color: StoryColors.foregroundOf(theme.brightness),
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.playerEpisodeTotal(total),
                      style: StoryTextStyles.bodySmall(
                        color: StoryColors.mutedForegroundOf(theme.brightness),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: StorySpacing.md),
                if (d.batchUnlockDiscountRate != null &&
                    d.batchUnlockDiscountRate! > 0) ...[
                  BatchUnlockBanner(d: d, theme: theme),
                  const SizedBox(height: StorySpacing.md),
                ],
              ],
            ),
          ),
        ),
        EpisodePickerListSliver(
          dramaId: widget.dramaId,
          currentEpisode: ref.watch(
            currentDramaEpisodeProvider(widget.dramaId),
          ),
          fallbackCoverUrl: d.coverUrl ?? widget.coverUrl,
          onSelect: (epNo) => _openPlayer(d, episodeNo: epNo),
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

  Future<void> _showRatingBottomSheet(DramaDetail d) async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!mounted) return;
    final l10n = context.l10n;
    StoryBottomSheet.showCommentSheet<void>(
      context: context,
      builder: (_) => RatingBottomSheet(
        initialRating:
            ref.read(dramaEngagementProvider(widget.dramaId)).myRating ?? 0,
        onRated: (rating) async {
          // Store handles optimistic myRating, rollback, and refreshing the
          // authoritative avgRating (detail cache evict + refetch).
          final res = await ref
              .read(dramaEngagementProvider(widget.dramaId).notifier)
              .submitRating(rating, authorUserId: d.userId);
          if (res == null) return; // Mutation already in flight.
          if (res.isSuccess && mounted) {
            StoryToast.success(context, l10n.dramaDetailRatingSuccess(rating));
            // Keep the detail provider consistent for the rest of the page;
            // the refetch hits the cache the store just refreshed.
            ref.invalidate(dramaDetailProvider(widget.dramaId));
          } else if (mounted && res.isFailure) {
            StoryToast.error(context, context.l10nError(res.errorOrNull!));
          }
        },
      ),
    );
  }

  /// Comment count badge next to the comments tab label.
  ///
  /// Reads the shared episode engagement store — the count stays live when a
  /// comment is posted from this page or any other page (e.g. the player).
  Widget _buildCommentCountBadge() {
    final key = _episodeEngagementKey;
    if (key == null) return const SizedBox.shrink();
    final count = ref.watch(
      episodeEngagementProvider(key).select((s) => s.commentCount ?? 0),
    );
    if (count <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: StoryColors.brandTeal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: StoryTextStyles.caption(
              color: StoryColors.brandTeal,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsTab(
    DramaDetail d,
    double inputBarHeight,
    ValueListenable<double> keyboardInset,
  ) {
    return DramaCommentsTab(
      dramaId: widget.dramaId,
      episodeId: _resolvedEpisodeId,
      episodeNo: ref.read(currentDramaEpisodeProvider(widget.dramaId)),
      emojiPickerVisible: _emojiPickerVisible,
      inputBarKey: _inputBarKey,
      scrollController: _listScroll,
      bottomPadding: inputBarHeight,
      keyboardInset: keyboardInset,
      onReplyTargetChanged: _onReplyTargetChanged,
    );
  }
}

/// 简介超过 1 行时才显示展开/收起。
class _ExpandableDescription extends StatelessWidget {
  final String text;
  final bool expanded;
  final Color color;
  final String expandLabel;
  final String collapseLabel;
  final VoidCallback onToggle;

  const _ExpandableDescription({
    required this.text,
    required this.expanded,
    required this.color,
    required this.expandLabel,
    required this.collapseLabel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bodyStyle = StoryTextStyles.bodyMedium(color: color);
    final actionStyle = StoryTextStyles.titleMedium(color: color);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: bodyStyle),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final exceedsOneLine = painter.didExceedMaxLines;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                text,
                style: bodyStyle,
                maxLines: expanded ? null : 1,
                overflow: expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
            if (exceedsOneLine)
              GestureDetector(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    expanded ? collapseLabel : expandLabel,
                    style: actionStyle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
