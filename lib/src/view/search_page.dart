import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/common/story_toast.dart';
import '../components/content/content_actor_ip_grid_card.dart';
import '../components/content/content_work_grid_card.dart';
import '../components/theater/drama_card.dart';
import '../components/theater/drama_card_vm_mapper.dart';
import '../components/follow/unfollow_confirm_dialog.dart';
import '../components/search/search_history_panel.dart';
import '../components/search/search_user_card.dart';
import '../controller/follow_action_controller.dart';
import '../controller/playlist_continuation.dart';
import '../controller/playlist_continuation_sync.dart';
import '../controller/search_controller.dart';
import '../controller/search_state.dart';
import '../core/result.dart';
import '../l10n/story_l10n.dart';
import '../model/actor_collection_model.dart';
import '../model/drama_play_response_model.dart';
import '../model/follow_models.dart';
import '../model/recommend_search_models.dart';
import '../model/user_search_models.dart';
import '../model/work_content_type.dart';
import '../provider/app_providers.dart';
import '../provider/tab_index_provider.dart';
import '../routes/actor_detail_navigation.dart';
import '../routes/video_feed_playlist_entry_seeds.dart';
import '../routes/route_args.dart';
import '../routes/route_names.dart';
import '../routes/video_feed_navigation.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../utils/actor_data_sync.dart';
import '../widgets/widgets.dart';
import '../foundation/navigator.dart';

/// Global search page — Figma dark `655:103241` / light `655:132839`.
class SearchPage extends ConsumerStatefulWidget {
  final SearchType searchType;
  final String? hintText;

  const SearchPage({
    super.key,
    this.searchType = SearchType.dramas,
    this.hintText,
  });

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(searchControllerProvider.notifier)
          .setActiveTab(widget.searchType, clearIfIdle: true);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit([String? raw]) async {
    final keyword = (raw ?? _controller.text).trim();
    if (keyword != _controller.text.trim()) {
      _controller.text = keyword;
      _controller.selection = TextSelection.collapsed(offset: keyword.length);
    }
    ref.read(searchControllerProvider.notifier).syncKeyword(keyword);
    final ok = await ref
        .read(searchControllerProvider.notifier)
        .search(keyword);
    if (!mounted) return;
    if (!ok && keyword.isNotEmpty) {
      StoryToast.info(context, context.l10n.searchKeywordTooShort);
    }
    FocusScope.of(context).unfocus();
  }

  void _clearInput() {
    _controller.clear();
    ref.read(searchControllerProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  Future<void> _clearHistory() async {
    final cleared = await ref
        .read(searchHistoryControllerProvider.notifier)
        .clearAll();
    if (!mounted || !cleared) return;
    StoryToast.info(context, context.l10n.searchHistoryCleared);
  }

  Future<void> _openLoginThenHome() async {
    final result = await context.storyPushForResult<bool>(RouteNames.login);
    if (!mounted || result != true) return;
    ref.read(tabIndexProvider.notifier).setIndex(StoryTab.theater.index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openUser(UserSearchItem item) async {
    if (item.userId.isEmpty) return;
    if (!ref.read(authControllerProvider).isLoggedIn) {
      await _openLoginThenHome();
      return;
    }
    if (!mounted) return;
    context.storyPush(RouteNames.publicProfile, arguments: {'userId': item.userId});
  }

  Future<void> _onUserRelation(UserSearchItem item) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn) {
      await _openLoginThenHome();
      return;
    }
    if (item.isSelf || item.userId.isEmpty) return;

    final action = ref.read(followActionControllerProvider.notifier);
    final status = item.relationStatus;
    final notifier = ref.read(searchControllerProvider.notifier);

    if (status == FollowRelationStatus.following ||
        status == FollowRelationStatus.mutual) {
      final confirmed = await UnfollowConfirmDialog.show(
        context,
        displayName: item.nickname,
      );
      if (confirmed != true || !mounted) return;
      final previous = status;
      final next = FollowRelationActions.nextAfterUnfollow(status);
      notifier.patchUserRelation(item.userId, next);
      final result = await action.unfollow(item.userId);
      if (!mounted) return;
      if (result.isFailure) {
        notifier.patchUserRelation(item.userId, previous);
      }
      return;
    }

    final previous = status;
    final next = FollowRelationActions.nextAfterFollow(status);
    notifier.patchUserRelation(item.userId, next);
    final result = await action.follow(item.userId);
    if (!mounted) return;
    if (result.isFailure) {
      notifier.patchUserRelation(item.userId, previous);
      // 失败提示（如拉黑关系中无法关注）。
      final err = result.errorOrNull;
      if (err != null) {
        StoryToast.error(context, context.l10nError(err));
      }
    }
  }

  void _openDrama(FeedItem item) {
    unawaited(
      _openSearchPlayback(
        items: ref.read(searchControllerProvider).dramas,
        tapped: item,
        // Search drama tab: always start at ep 1 (do not resume / use card episodeNo).
        resumeTappedDrama: false,
        startAtFirstEpisode: true,
        searchDramaPlaylist: true,
        searchTab: SearchType.dramas,
      ),
    );
  }

  void _openWork(FeedItem item) {
    unawaited(
      _openSearchPlayback(
        items: ref.read(searchControllerProvider).works,
        tapped: item,
        resumeTappedDrama: false,
        startAtFirstEpisode: false,
        searchDramaPlaylist: false,
        searchTab: SearchType.works,
      ),
    );
  }

  Future<void> _openSearchPlayback({
    required List<FeedItem> items,
    required FeedItem tapped,
    required bool resumeTappedDrama,
    required bool startAtFirstEpisode,
    required bool searchDramaPlaylist,
    required SearchType searchTab,
  }) async {
    FocusScope.of(context).unfocus();
    final playlist = <VideoFeedPlaylistEntry>[];
    var initialIndex = -1;
    final seenDramaIds = <String>{};
    final tappedDramaId = tapped.dramaId?.trim();

    for (final item in items) {
      if (searchDramaPlaylist) {
        final id = item.dramaId?.trim() ?? '';
        if (id.isEmpty || !seenDramaIds.add(id)) continue;
      }
      final isTapped = searchDramaPlaylist
          ? item.dramaId?.trim() == tappedDramaId && tappedDramaId != null
          : item == tapped;
      final entry = _playlistEntryFor(
        item,
        resumeDrama: resumeTappedDrama && isTapped,
        startAtFirstEpisode: startAtFirstEpisode,
        expandDramaEpisodes: searchDramaPlaylist,
      );
      if (entry == null) continue;
      if (isTapped) initialIndex = playlist.length;
      playlist.add(entry);
    }

    if (initialIndex < 0 && !searchDramaPlaylist) {
      final tappedEntry = _playlistEntryFor(
        tapped,
        resumeDrama: false,
        startAtFirstEpisode: false,
        expandDramaEpisodes: false,
      );
      if (tappedEntry != null) {
        initialIndex = playlist.length;
        playlist.add(tappedEntry);
      }
    }

    if (initialIndex < 0 || playlist.isEmpty || !mounted) {
      if (mounted) {
        StoryToast.error(context, context.l10n.playerDramaUnavailable);
      }
      return;
    }

    final seenKeys = {for (final e in playlist) e.playbackKey};
    final continuation = CallbackPlaylistContinuation(
      hasMoreCallback: () {
        if (!mounted) return false;
        return ref.read(searchControllerProvider).hasMoreFor(searchTab);
      },
      loadMoreCallback: () => _loadMoreSearchPlaylistEntries(
        searchTab: searchTab,
        searchDramaPlaylist: searchDramaPlaylist,
        startAtFirstEpisode: startAtFirstEpisode,
        seenKeys: seenKeys,
      ),
    );

    await VideoFeedNavigation.openPlaylist(
      context,
      playlist: playlist,
      initialIndex: initialIndex,
      searchDramaPlaylist: searchDramaPlaylist,
      continuation: continuation,
    );
    if (!mounted) return;
    await _revalidateSearchItemAfterPlayback(tapped);
  }

  /// Refreshes only the work that opened playback, then replaces matching
  /// cached search rows by id. This avoids re-running the full keyword search.
  Future<void> _revalidateSearchItemAfterPlayback(FeedItem item) async {
    final repository = ref.read(dramaRepositoryProvider);
    final episodeId = item.episodeId?.trim() ?? '';
    final type = WorkContentType.fromApi(item.contentType);
    final Result<DramaPlayResponse> result;

    if (episodeId.isNotEmpty) {
      result = await repository.getEpisodeDetailByEpisodeId(episodeId);
    } else {
      final dramaId = item.dramaId?.trim() ?? '';
      if (type.isShortVideo || dramaId.isEmpty) return;
      final listedEpisodeNo = item.episodeNo ?? 1;
      result = await repository.getEpisodeDetail(
        dramaId,
        listedEpisodeNo < 1 ? 1 : listedEpisodeNo,
        forceRefresh: true,
      );
    }

    if (!mounted || result.isFailure) return;
    final play = result.dataOrNull;
    if (play == null) return;
    ref.read(searchControllerProvider.notifier).patchWorkEngagement(play);
  }

  Future<Result<PlaylistContinuationPage>> _loadMoreSearchPlaylistEntries({
    required SearchType searchTab,
    required bool searchDramaPlaylist,
    required bool startAtFirstEpisode,
    required Set<String> seenKeys,
  }) async {
    if (!mounted) {
      return Result.success(
        const PlaylistContinuationPage(entries: [], hasMore: false),
      );
    }
    final state = ref.read(searchControllerProvider);
    final items = searchTab == SearchType.dramas ? state.dramas : state.works;
    final page = await syncPlaylistContinuation<FeedItem>(
      items: items,
      hasMore: state.hasMoreFor(searchTab),
      isPageLoading: state.isPageLoading,
      seenKeys: seenKeys,
      toEntry: (item) {
        if (searchDramaPlaylist) {
          final id = item.dramaId?.trim() ?? '';
          if (id.isEmpty) return null;
        }
        return _playlistEntryFor(
          item,
          resumeDrama: false,
          startAtFirstEpisode: startAtFirstEpisode,
          expandDramaEpisodes: searchDramaPlaylist,
        );
      },
      loadMore: () =>
          ref.read(searchControllerProvider.notifier).loadMoreFor(searchTab),
      readItems: () {
        final s = ref.read(searchControllerProvider);
        return searchTab == SearchType.dramas ? s.dramas : s.works;
      },
      readHasMore: () =>
          ref.read(searchControllerProvider).hasMoreFor(searchTab),
      readIsPageLoading: () => ref.read(searchControllerProvider).isPageLoading,
    );
    if (!mounted) {
      return Result.success(
        const PlaylistContinuationPage(entries: [], hasMore: false),
      );
    }
    return Result.success(page);
  }

  VideoFeedPlaylistEntry? _playlistEntryFor(
    FeedItem item, {
    required bool resumeDrama,
    required bool startAtFirstEpisode,
    required bool expandDramaEpisodes,
  }) {
    final type = WorkContentType.fromApi(item.contentType);
    if (type.isShortVideo) {
      final episodeId = item.episodeId?.trim() ?? '';
      if (episodeId.isEmpty) return null;
      return VideoFeedPlaylistEntrySeeds.shortVideoFromFeedItem(
        item,
        episodeId: episodeId,
        title: item.title ?? '',
        coverUrl: item.posterUrl,
        description: item.resolvedEpisodeDescription,
      );
    }

    final dramaId = item.dramaId?.trim() ?? '';
    if (dramaId.isEmpty) return null;
    final hasConcreteEpisode = item.episodeId?.trim().isNotEmpty == true;
    // 搜索结果没有具体 episodeId 时代表整部短剧，需要展开 1...N；
    // 有 episodeId 时只播放该集，由播放器按 ID 校正真实 episodeNo。
    final expandEpisodes = expandDramaEpisodes || !hasConcreteEpisode;
    final listedTotal = switch (item.totalEpisodes) {
      final value? when value > 0 => value,
      _ => null,
    };
    // Mutually exclusive: first-episode entry (search dramas) wins over resume /
    // card episodeNo so works + theater resume paths stay untouched.
    final rawEpisode = expandEpisodes || startAtFirstEpisode
        ? 1
        : hasConcreteEpisode && (item.episodeNo ?? 0) < 1
        ? 1
        : resumeDrama
        ? resumeEpisodeForDrama(ref, dramaId, totalEpisodes: listedTotal ?? 1)
        : (item.episodeNo ?? 1);
    final episodeNo = rawEpisode < 1 ? 1 : rawEpisode;
    final totalEpisodes = listedTotal == null
        ? (expandEpisodes ? null : episodeNo)
        : (episodeNo > listedTotal ? episodeNo : listedTotal);
    return VideoFeedPlaylistEntrySeeds.dramaFromFeedItem(
      item,
      dramaId: dramaId,
      episodeId: expandEpisodes ? null : item.episodeId,
      episodeNo: episodeNo,
      totalEpisodes: totalEpisodes,
      title: item.title ?? '',
      // Series expand keeps drama poster; concrete episode rows prefer firstFrame.
      coverUrl: expandEpisodes ? item.coverUrl : item.posterUrl,
      description: expandEpisodes
          ? item.resolvedDramaDescription
          : item.resolvedEpisodeDescription,
      expandEpisodes: expandEpisodes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final state = ref.watch(searchControllerProvider);
    final history = ref.watch(searchHistoryControllerProvider);
    final pending = ref.watch(
      followActionControllerProvider.select((s) => s.pendingUserIds),
    );

    final draft = _controller.text;
    final showResults = state.hasSearched;
    final showHistory =
        !showResults && draft.trim().isEmpty && history.items.isNotEmpty;

    final hint = widget.hintText?.trim().isNotEmpty == true
        ? widget.hintText!.trim()
        : l10n.searchHint;

    return Scaffold(
      backgroundColor: StoryColors.backgroundOf(brightness),
      body: SafeArea(
        child: Column(
          children: [
            _SearchHeader(
              controller: _controller,
              focusNode: _focusNode,
              hintText: hint,
              actionLabel: l10n.searchAction,
              onBack: () => Navigator.of(context).maybePop(),
              onChanged: (v) {
                ref.read(searchControllerProvider.notifier).syncKeyword(v);
                setState(() {});
              },
              onClear: _clearInput,
              onSubmit: () => _submit(),
            ),
            if (showResults)
              _SearchTabs(
                active: state.activeTab,
                onSelect: (tab) {
                  ref.read(searchControllerProvider.notifier).selectTab(tab);
                },
              ),
            Expanded(
              child: showResults
                  ? _ResultsBody(
                      state: state,
                      pendingUserIds: pending,
                      onLoadMore: () {
                        ref.read(searchControllerProvider.notifier).loadMore();
                      },
                      onRetry: () {
                        final kw = ref.read(searchControllerProvider).keyword;
                        ref.read(searchControllerProvider.notifier).search(kw);
                      },
                      onOpenDrama: _openDrama,
                      onOpenWork: _openWork,
                      onOpenActor: (a) {
                        final id = a.id;
                        if (id == null || id.isEmpty) return;
                        openActorDetail(context, actorId: id, preview: a);
                      },
                      onOpenUser: _openUser,
                      onUserRelation: _onUserRelation,
                    )
                  : showHistory
                  ? SearchHistoryPanel(
                      title: l10n.searchHistory,
                      clearLabel: l10n.searchClear,
                      onClear: _clearHistory,
                      items: history.items,
                      onSelect: (kw) {
                        _controller.text = kw;
                        _submit(kw);
                      },
                      onRemove: (kw) {
                        ref
                            .read(searchHistoryControllerProvider.notifier)
                            .remove(kw);
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String actionLabel;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.actionLabel,
    required this.onBack,
    required this.onChanged,
    required this.onClear,
    required this.onSubmit,
  });

  /// Figma `Shadows/shadow-4` — same for focused / unfocused (no focus ring).
  static const _fieldShadows = [
    // Neutral Alpha/3 #0000330f as 1px outline (Figma spread:1 blur:0)
    BoxShadow(color: Color(0x0F000033), spreadRadius: 1),
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 8), blurRadius: 40),
    BoxShadow(
      color: Color(0x0F000033),
      offset: Offset(0, 12),
      blurRadius: 32,
      spreadRadius: -16,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final hasText = controller.text.isNotEmpty;
    // Figma `Colors/Page&Sheet/white to secondary`: light #fff / dark #212225
    final fieldBg = brightness == Brightness.dark
        ? StoryColors.darkMuted
        : Colors.white;
    final primary = StoryColors.foregroundOf(brightness);
    final tertiary = brightness == Brightness.dark
        ? StoryColors.darkTertiaryText
        : StoryColors.lightTertiaryText;

    return Padding(
      // Figma frame: px 16 / py 4 / gap 12
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 24,
              height: 24,
              child: Icon(Icons.arrow_back_ios_new, size: 16, color: primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              // py 10 + 20 line = 40; keep fixed height for stable layout
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(8),
                // Focused == unfocused: no separate focusedBorder / focus ring.
                boxShadow: _fieldShadows,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.search,
                      onChanged: onChanged,
                      onSubmitted: (_) => onSubmit(),
                      // Figma `primary/primary` cursor
                      cursorColor: StoryColors.brandTealRed,
                      cursorWidth: 1.5,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w400,
                        color: primary,
                      ),
                      decoration: InputDecoration(
                        // Override global filled + lightMuted from InputDecorationTheme.
                        filled: true,
                        fillColor: Colors.transparent,
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: hintText,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                          color: tertiary,
                        ),
                      ),
                    ),
                  ),
                  if (hasText) ...[
                    GestureDetector(
                      onTap: onClear,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: Icon(Icons.close, size: 18, color: tertiary),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  GestureDetector(
                    onTap: onSubmit,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 20, color: primary),
                        Text(
                          actionLabel,
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchTabs extends StatelessWidget {
  final SearchType active;
  final ValueChanged<SearchType> onSelect;

  const _SearchTabs({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final tabs = <(SearchType, String)>[
      (SearchType.dramas, l10n.searchTabDramas),
      (SearchType.works, l10n.searchTabWorks),
      (SearchType.actors, l10n.searchTabActors),
      (SearchType.users, l10n.searchTabUsers),
    ];
    final indicator = brightness == Brightness.dark
        ? Colors.white
        : StoryColors.destructive;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final (type, label) = tabs[index];
          final selected = type == active;
          return GestureDetector(
            onTap: () => onSelect(type),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected
                        ? StoryColors.foregroundOf(brightness)
                        : StoryColors.mutedForegroundOf(brightness),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 3,
                  width: 28,
                  color: selected ? indicator : Colors.transparent,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ResultsBody extends StatelessWidget {
  final SearchState state;
  final Set<String> pendingUserIds;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final ValueChanged<FeedItem> onOpenDrama;
  final ValueChanged<FeedItem> onOpenWork;
  final ValueChanged<ActorCollection> onOpenActor;
  final ValueChanged<UserSearchItem> onOpenUser;
  final ValueChanged<UserSearchItem> onUserRelation;

  const _ResultsBody({
    required this.state,
    required this.pendingUserIds,
    required this.onLoadMore,
    required this.onRetry,
    required this.onOpenDrama,
    required this.onOpenWork,
    required this.onOpenActor,
    required this.onOpenUser,
    required this.onUserRelation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state.isLoading && !_hasAnyItems(state)) {
      return const StoryLoading.centered();
    }
    if (state.lastError != null && !_hasAnyItems(state)) {
      return StoryStateWidget.error(
        message: context.l10nError(state.lastError!),
        actionLabel: l10n.dramaRefresh,
        onAction: onRetry,
        showIcon: false,
      );
    }

    return switch (state.activeTab) {
      SearchType.dramas => _DramaGrid(
        items: state.dramas,
        emptyLabel: l10n.searchEmpty,
        hasMore: state.dramasHasMore,
        isPageLoading: state.isPageLoading,
        onLoadMore: onLoadMore,
        onOpen: onOpenDrama,
      ),
      SearchType.works => _WorkGrid(
        items: state.works,
        emptyLabel: l10n.searchEmpty,
        hasMore: state.worksHasMore,
        isPageLoading: state.isPageLoading,
        onLoadMore: onLoadMore,
        onOpen: onOpenWork,
      ),
      SearchType.actors => _ActorGrid(
        items: state.actors,
        emptyLabel: l10n.searchEmpty,
        hasMore: state.actorsHasMore,
        isPageLoading: state.isPageLoading,
        onLoadMore: onLoadMore,
        onOpen: onOpenActor,
      ),
      SearchType.users => _UserList(
        items: state.users,
        emptyLabel: l10n.searchEmpty,
        hasMore: state.usersHasMore,
        isPageLoading: state.isPageLoading,
        pendingUserIds: pendingUserIds,
        onLoadMore: onLoadMore,
        onOpen: onOpenUser,
        onRelation: onUserRelation,
      ),
    };
  }

  static bool _hasAnyItems(SearchState state) => switch (state.activeTab) {
    SearchType.dramas => state.dramas.isNotEmpty,
    SearchType.works => state.works.isNotEmpty,
    SearchType.actors => state.actors.isNotEmpty,
    SearchType.users => state.users.isNotEmpty,
  };
}

bool _maybeLoadMore({
  required ScrollNotification notification,
  required bool hasMore,
  required bool isPageLoading,
  required VoidCallback onLoadMore,
}) {
  if (!hasMore || isPageLoading) return false;
  if (notification is! ScrollUpdateNotification) return false;
  final metrics = notification.metrics;
  if (metrics.pixels >=
      metrics.maxScrollExtent - StorySpacing.scrollThreshold) {
    onLoadMore();
  }
  return false;
}

Widget _pageLoadingFooter(bool isPageLoading) {
  if (!isPageLoading) return const SizedBox.shrink();
  return const Padding(
    padding: EdgeInsets.symmetric(vertical: StorySpacing.base),
    child: Center(child: StoryLoading()),
  );
}

class _DramaGrid extends StatelessWidget {
  final List<FeedItem> items;
  final String emptyLabel;
  final bool hasMore;
  final bool isPageLoading;
  final VoidCallback onLoadMore;
  final ValueChanged<FeedItem> onOpen;

  const _DramaGrid({
    required this.items,
    required this.emptyLabel,
    required this.hasMore,
    required this.isPageLoading,
    required this.onLoadMore,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: StoryEmptyCard(label: emptyLabel));
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) => _maybeLoadMore(
        notification: n,
        hasMore: hasMore,
        isPageLoading: isPageLoading,
        onLoadMore: onLoadMore,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridWidth =
              constraints.maxWidth - StorySpacing.screenHorizontal * 2;
          final aspect = DramaCard.gridChildAspectRatioFor(gridWidth);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StorySpacing.screenHorizontal,
                  vertical: StorySpacing.sm,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: aspect,
                    crossAxisSpacing: StorySpacing.xs,
                    mainAxisSpacing: ContentWorkGridCard.gridSpacing,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];
                    return RepaintBoundary(
                      key: ValueKey(item.dramaId ?? item.episodeId),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: GridDramaCard(
                          vm: DramaCardVmMapper.fromSearchFeed(
                            item,
                            l10n: context.l10n,
                          ),
                          showPlayCount: true,
                          onTap: () => onOpen(item),
                        ),
                      ),
                    );
                  }, childCount: items.length),
                ),
              ),
              SliverToBoxAdapter(child: _pageLoadingFooter(isPageLoading)),
            ],
          );
        },
      ),
    );
  }
}

class _WorkGrid extends StatelessWidget {
  final List<FeedItem> items;
  final String emptyLabel;
  final bool hasMore;
  final bool isPageLoading;
  final VoidCallback onLoadMore;
  final ValueChanged<FeedItem> onOpen;

  const _WorkGrid({
    required this.items,
    required this.emptyLabel,
    required this.hasMore,
    required this.isPageLoading,
    required this.onLoadMore,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: StoryEmptyCard(label: emptyLabel));
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) => _maybeLoadMore(
        notification: n,
        hasMore: hasMore,
        isPageLoading: isPageLoading,
        onLoadMore: onLoadMore,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridWidth =
              constraints.maxWidth - StorySpacing.screenHorizontal * 2;
          final aspect = ContentWorkGridCard.gridChildAspectRatioFor(gridWidth);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StorySpacing.screenHorizontal,
                  vertical: StorySpacing.sm,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ContentWorkGridCard.gridCrossAxisCount,
                    mainAxisSpacing: ContentWorkGridCard.gridSpacing,
                    crossAxisSpacing: StorySpacing.xs,
                    childAspectRatio: aspect,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];
                    return RepaintBoundary(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ContentWorkGridCard(
                          item: item,
                          onTap: () => onOpen(item),
                        ),
                      ),
                    );
                  }, childCount: items.length),
                ),
              ),
              SliverToBoxAdapter(child: _pageLoadingFooter(isPageLoading)),
            ],
          );
        },
      ),
    );
  }
}

/// Figma 搜索角色 IP 双列紧凑卡（非广场大卡）。
class _ActorGrid extends ConsumerWidget {
  final List<ActorCollection> items;
  final String emptyLabel;
  final bool hasMore;
  final bool isPageLoading;
  final VoidCallback onLoadMore;
  final ValueChanged<ActorCollection> onOpen;

  const _ActorGrid({
    required this.items,
    required this.emptyLabel,
    required this.hasMore,
    required this.isPageLoading,
    required this.onLoadMore,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (items.isEmpty) {
      return Center(child: StoryEmptyCard(label: emptyLabel));
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) => _maybeLoadMore(
        notification: n,
        hasMore: hasMore,
        isPageLoading: isPageLoading,
        onLoadMore: onLoadMore,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridWidth = constraints.maxWidth - StorySpacing.sm * 2;
          final aspect = ContentActorIpGridCard.gridChildAspectRatioFor(
            gridWidth,
          );
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(StorySpacing.sm),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ContentActorIpGridCard.gridCrossAxisCount,
                    mainAxisSpacing: ContentActorIpGridCard.gridSpacing,
                    crossAxisSpacing: ContentActorIpGridCard.gridSpacing,
                    childAspectRatio: aspect,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final actor = items[index];
                    return RepaintBoundary(
                      key: ValueKey(actor.id),
                      child: ContentActorIpGridCard(
                        actor: actor,
                        onTap: () => onOpen(actor),
                        onSign: () => showActorSignFlowWithFreshDetail(
                          context,
                          ref,
                          actor,
                        ),
                        onTrade: () =>
                            StoryToast.info(context, l10n.nftTradeUnavailable),
                      ),
                    );
                  }, childCount: items.length),
                ),
              ),
              SliverToBoxAdapter(child: _pageLoadingFooter(isPageLoading)),
            ],
          );
        },
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<UserSearchItem> items;
  final String emptyLabel;
  final bool hasMore;
  final bool isPageLoading;
  final Set<String> pendingUserIds;
  final VoidCallback onLoadMore;
  final ValueChanged<UserSearchItem> onOpen;
  final ValueChanged<UserSearchItem> onRelation;

  const _UserList({
    required this.items,
    required this.emptyLabel,
    required this.hasMore,
    required this.isPageLoading,
    required this.pendingUserIds,
    required this.onLoadMore,
    required this.onOpen,
    required this.onRelation,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: StoryEmptyCard(label: emptyLabel));
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) => _maybeLoadMore(
        notification: n,
        hasMore: hasMore,
        isPageLoading: isPageLoading,
        onLoadMore: onLoadMore,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(StorySpacing.base),
        itemCount: items.length + (isPageLoading ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: StorySpacing.md),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: StorySpacing.base),
              child: Center(child: StoryLoading()),
            );
          }
          final item = items[index];
          return SearchUserCard(
            item: item,
            actionLoading: pendingUserIds.contains(item.userId),
            onOpenProfile: () => onOpen(item),
            onRelationTap: () => onRelation(item),
          );
        },
      ),
    );
  }
}
