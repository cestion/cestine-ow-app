import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/story_toast.dart';
import '../../../controller/playlist_continuation.dart';
import '../../../controller/playlist_continuation_sync.dart';
import '../../../core/result.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/controller_providers.dart';
import '../../../provider/repository_providers.dart';
import '../../../routes/video_feed_playlist_entry_seeds.dart';
import '../../../routes/route_args.dart';
import '../../../routes/video_feed_navigation.dart';
import '../../../styles/story_colors.dart';
import '../../../widgets/story_loading.dart';
import 'watch_history_drama_grid.dart';
import 'watch_history_tabs.dart';
import 'watch_history_work_grid.dart';

export 'watch_history_tabs.dart' show WatchHistoryTabsVariant;

/// Shared watch-history tabs, data lifecycle, grids and playback navigation.
///
/// The standalone page supplies an external [controller] because its tab bar
/// lives in the app bar. Embedded surfaces let this widget own the controller
/// and render [WatchHistoryTabs] above the grids.
class WatchHistoryContent extends ConsumerStatefulWidget {
  const WatchHistoryContent({
    super.key,
    this.controller,
    this.showTabs = true,
    this.isActive = true,
    this.coordinatedWithParentRefresh = false,
    this.selectedType = WorkContentType.shortDrama,
    this.onTypeChanged,
    this.tabForeground,
    this.tabsVariant = WatchHistoryTabsVariant.underline,
  });

  final TabController? controller;
  final bool showTabs;
  final bool isActive;
  final bool coordinatedWithParentRefresh;
  final WorkContentType selectedType;
  final ValueChanged<WorkContentType>? onTypeChanged;
  final Color? tabForeground;
  final WatchHistoryTabsVariant tabsVariant;

  @override
  ConsumerState<WatchHistoryContent> createState() =>
      _WatchHistoryContentState();
}

class _WatchHistoryContentState extends ConsumerState<WatchHistoryContent>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _controller;
  late bool _ownsController;
  late int _lastHandledIndex;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _attachController();
    _scheduleRevalidate(_typeForIndex(_controller.index));
  }

  @override
  void didUpdateWidget(covariant WatchHistoryContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController();
      _attachController();
    }

    final expectedIndex = widget.selectedType.isShortVideo ? 1 : 0;
    if (_controller.index != expectedIndex && !_controller.indexIsChanging) {
      _lastHandledIndex = expectedIndex;
      _controller.index = expectedIndex;
    }

    if (!oldWidget.isActive && widget.isActive) {
      // Parent flips isActive during build — never mutate providers here.
      _scheduleRevalidate(widget.selectedType);
    }
  }

  void _scheduleRevalidate(WorkContentType type) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isActive) return;
      unawaited(_revalidate(type));
    });
  }

  @override
  void dispose() {
    _detachController();
    super.dispose();
  }

  void _attachController() {
    final external = widget.controller;
    _ownsController = external == null;
    _controller =
        external ??
        TabController(
          length: 2,
          initialIndex: widget.selectedType.isShortVideo ? 1 : 0,
          vsync: this,
        );
    _lastHandledIndex = _controller.index;
    _controller.addListener(_handleTabChanged);
  }

  void _detachController() {
    _controller.removeListener(_handleTabChanged);
    if (_ownsController) _controller.dispose();
  }

  void _handleTabChanged() {
    if (_controller.indexIsChanging || _controller.index == _lastHandledIndex) {
      return;
    }
    _lastHandledIndex = _controller.index;
    final type = _typeForIndex(_controller.index);
    widget.onTypeChanged?.call(type);
    if (widget.isActive) _scheduleRevalidate(type);
  }

  WorkContentType _typeForIndex(int index) =>
      index == 0 ? WorkContentType.shortDrama : WorkContentType.shortVideo;

  Future<void> _revalidate(WorkContentType type) {
    return type.isShortVideo
        ? ref.read(watchHistoryVideoControllerProvider.notifier).revalidate()
        : ref.read(watchHistoryDramaControllerProvider.notifier).revalidate();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!widget.isActive) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final dramaState = ref.watch(watchHistoryDramaControllerProvider);
    final videoState = ref.watch(watchHistoryVideoControllerProvider);
    final panels = TabBarView(
      controller: _controller,
      children: [
        WatchHistoryDramaGrid(
          state: dramaState,
          pullToRefreshEnabled: !widget.coordinatedWithParentRefresh,
          onRefresh: () =>
              ref.read(watchHistoryDramaControllerProvider.notifier).refresh(),
          onLoadMore: () =>
              ref.read(watchHistoryDramaControllerProvider.notifier).loadMore(),
          onItemTap: (item) =>
              unawaited(_openDramaPlaylist(dramaState.items, item)),
        ),
        WatchHistoryWorkGrid(
          state: videoState,
          pullToRefreshEnabled: !widget.coordinatedWithParentRefresh,
          onRefresh: () =>
              ref.read(watchHistoryVideoControllerProvider.notifier).refresh(),
          onLoadMore: () =>
              ref.read(watchHistoryVideoControllerProvider.notifier).loadMore(),
          onItemTap: (item) =>
              unawaited(_openVideoPlaylist(videoState.items, item)),
        ),
      ],
    );

    if (!widget.showTabs) return panels;

    return ColoredBox(
      color: StoryColors.appBarBackgroundOf(brightness),
      child: Column(
        children: [
          WatchHistoryTabs(
            controller: _controller,
            foreground:
                widget.tabForeground ?? StoryColors.foregroundOf(brightness),
            variant: widget.tabsVariant,
          ),
          Expanded(child: panels),
        ],
      ),
    );
  }

  VideoFeedPlaylistEntry? _dramaEntry(WatchHistoryDrama item) {
    final dramaId = item.dramaId?.trim() ?? '';
    if (dramaId.isEmpty) return null;
    final episodeNo = switch (item.lastEpisodeNo) {
      final value? when value > 0 => value,
      _ => 1,
    };
    final listedTotal = switch (item.totalEpisodes) {
      final value? when value > 0 => value,
      _ => null,
    };
    final totalEpisodes = listedTotal == null
        ? null
        : (episodeNo > listedTotal ? episodeNo : listedTotal);
    return VideoFeedPlaylistEntry.drama(
      dramaId: dramaId,
      episodeNo: episodeNo,
      totalEpisodes: totalEpisodes,
      title: item.dramaTitle ?? '',
      coverUrl: item.dramaCoverUrl,
      expandEpisodes: true,
    );
  }

  VideoFeedPlaylistEntry? _videoEntry(WatchHistoryVideo item) {
    final episodeId = item.episodeId?.trim() ?? '';
    if (episodeId.isEmpty) return null;
    if (item.contentType.isShortVideo) {
      return VideoFeedPlaylistEntrySeeds.shortVideoFromWatchHistory(
        item,
        episodeId: episodeId,
        title: item.title ?? '',
        coverUrl: item.posterUrl,
        description: item.description,
      );
    }
    final dramaId = item.dramaId?.trim() ?? '';
    if (dramaId.isEmpty) return null;
    final episodeNo = switch (item.episodeNo) {
      final value? when value > 0 => value,
      _ => 1,
    };
    return VideoFeedPlaylistEntry.drama(
      dramaId: dramaId,
      episodeId: episodeId,
      episodeNo: episodeNo,
      totalEpisodes: episodeNo,
      title: item.title ?? '',
      coverUrl: item.posterUrl,
      description: item.description,
      likeCount: item.likeCount,
    );
  }

  Future<void> _openDramaPlaylist(
    List<WatchHistoryDrama> items,
    WatchHistoryDrama tapped,
  ) async {
    final playlist = <VideoFeedPlaylistEntry>[];
    var initialIndex = -1;
    final tappedId = tapped.dramaId?.trim();
    for (final item in items) {
      final entry = _dramaEntry(item);
      if (entry == null) continue;
      if (item.dramaId?.trim() == tappedId && tappedId != null) {
        initialIndex = playlist.length;
      }
      playlist.add(entry);
    }
    if (initialIndex < 0 || playlist.isEmpty) {
      StoryToast.error(context, context.l10n.playerDramaUnavailable);
      return;
    }

    final seenKeys = {for (final e in playlist) e.playbackKey};
    final continuation = CallbackPlaylistContinuation(
      hasMoreCallback: () {
        if (!mounted) return false;
        return ref.read(watchHistoryDramaControllerProvider).hasMore;
      },
      loadMoreCallback: () => _loadMoreDramaEntries(seenKeys: seenKeys),
    );

    await VideoFeedNavigation.openPlaylist(
      context,
      playlist: playlist,
      initialIndex: initialIndex,
      continuation: continuation,
    );
    if (!mounted) return;
    await ref.read(watchHistoryDramaControllerProvider.notifier).refresh();
  }

  Future<void> _openVideoPlaylist(
    List<WatchHistoryVideo> items,
    WatchHistoryVideo tapped,
  ) async {
    String? tappedDramaTitle;
    if (!tapped.contentType.isShortVideo) {
      final dramaId = tapped.dramaId?.trim() ?? '';
      if (dramaId.isNotEmpty) {
        final loadingKey = 'watch-history-title:$dramaId';
        if (!StoryLoading.show(context, operationKey: loadingKey)) return;
        // 兼容观看历史接口返回错误 title 的旧数据：仅在用户点击时请求
        // 短剧详情，并把准确剧名传给播放器，不修改列表或 Provider 数据。
        try {
          final detailResult = await ref
              .read(dramaRepositoryProvider)
              .getDetail(dramaId, forceRefresh: true);
          final detailTitle = detailResult.dataOrNull?.title?.trim() ?? '';
          if (detailTitle.isNotEmpty) tappedDramaTitle = detailTitle;
        } catch (_) {
          // 详情请求异常不拦截播放，继续使用观看历史中的旧 title。
        } finally {
          StoryLoading.dismiss(operationKey: loadingKey);
        }
        if (!mounted) return;
      }
    }

    final playlist = <VideoFeedPlaylistEntry>[];
    var initialIndex = -1;
    final tappedEpisodeId = tapped.episodeId?.trim();
    for (final item in items) {
      final isTapped =
          item.episodeId?.trim() == tappedEpisodeId && tappedEpisodeId != null;
      var entry = _videoEntry(item);
      if (entry == null) continue;
      if (isTapped && tappedDramaTitle != null) {
        entry = VideoFeedPlaylistEntry(
          dramaId: entry.dramaId,
          episodeId: entry.episodeId,
          contentType: entry.contentType,
          episodeNo: entry.episodeNo,
          title: tappedDramaTitle,
          totalEpisodes: entry.totalEpisodes,
          coverUrl: entry.coverUrl,
          description: entry.description,
          expandEpisodes: entry.expandEpisodes,
          creatorName: entry.creatorName,
          creatorUserId: entry.creatorUserId,
          creatorAvatarUrl: entry.creatorAvatarUrl,
          favoritedByMe: entry.favoritedByMe,
          favoriteCount: entry.favoriteCount,
        );
      }
      if (isTapped) {
        initialIndex = playlist.length;
      }
      playlist.add(entry);
    }
    if (initialIndex < 0 || playlist.isEmpty) {
      StoryToast.error(context, context.l10n.playerDramaUnavailable);
      return;
    }

    final seenKeys = {for (final e in playlist) e.playbackKey};
    final continuation = CallbackPlaylistContinuation(
      hasMoreCallback: () {
        if (!mounted) return false;
        return ref.read(watchHistoryVideoControllerProvider).hasMore;
      },
      loadMoreCallback: () => _loadMoreVideoEntries(seenKeys: seenKeys),
    );

    await VideoFeedNavigation.openPlaylist(
      context,
      playlist: playlist,
      initialIndex: initialIndex,
      continuation: continuation,
    );
    if (!mounted) return;
    await ref.read(watchHistoryVideoControllerProvider.notifier).refresh();
  }

  Future<Result<PlaylistContinuationPage>> _loadMoreDramaEntries({
    required Set<String> seenKeys,
  }) async {
    if (!mounted) {
      return Result.success(
        const PlaylistContinuationPage(entries: [], hasMore: false),
      );
    }
    final provider = watchHistoryDramaControllerProvider;
    final state = ref.read(provider);
    final page = await syncPlaylistContinuation<WatchHistoryDrama>(
      items: state.items,
      hasMore: state.hasMore,
      isPageLoading: state.isPageLoading,
      seenKeys: seenKeys,
      toEntry: _dramaEntry,
      loadMore: () => ref.read(provider.notifier).loadMore(),
      readItems: () => ref.read(provider).items,
      readHasMore: () => ref.read(provider).hasMore,
      readIsPageLoading: () => ref.read(provider).isPageLoading,
    );
    if (!mounted) {
      return Result.success(
        const PlaylistContinuationPage(entries: [], hasMore: false),
      );
    }
    return Result.success(page);
  }

  Future<Result<PlaylistContinuationPage>> _loadMoreVideoEntries({
    required Set<String> seenKeys,
  }) async {
    if (!mounted) {
      return Result.success(
        const PlaylistContinuationPage(entries: [], hasMore: false),
      );
    }
    final provider = watchHistoryVideoControllerProvider;
    final state = ref.read(provider);
    final page = await syncPlaylistContinuation<WatchHistoryVideo>(
      items: state.items,
      hasMore: state.hasMore,
      isPageLoading: state.isPageLoading,
      seenKeys: seenKeys,
      toEntry: _videoEntry,
      loadMore: () => ref.read(provider.notifier).loadMore(),
      readItems: () => ref.read(provider).items,
      readHasMore: () => ref.read(provider).hasMore,
      readIsPageLoading: () => ref.read(provider).isPageLoading,
    );
    if (!mounted) {
      return Result.success(
        const PlaylistContinuationPage(entries: [], hasMore: false),
      );
    }
    return Result.success(page);
  }
}

VideoFeedPlaylistEntry? watchHistoryDramaPlaylistEntry(WatchHistoryDrama item) {
  final dramaId = item.dramaId?.trim() ?? '';
  if (dramaId.isEmpty) return null;
  final episodeNo = switch (item.lastEpisodeNo) {
    final value? when value > 0 => value,
    _ => 1,
  };
  final listedTotal = switch (item.totalEpisodes) {
    final value? when value > 0 => value,
    _ => null,
  };
  final totalEpisodes = listedTotal == null
      ? null
      : (episodeNo > listedTotal ? episodeNo : listedTotal);
  return VideoFeedPlaylistEntry.drama(
    dramaId: dramaId,
    episodeNo: episodeNo,
    totalEpisodes: totalEpisodes,
    title: item.dramaTitle ?? '',
    coverUrl: item.dramaCoverUrl,
    expandEpisodes: true,
  );
}

VideoFeedPlaylistEntry? watchHistoryVideoPlaylistEntry(WatchHistoryVideo item) {
  final episodeId = item.episodeId?.trim() ?? '';
  if (episodeId.isEmpty) return null;
  if (item.contentType.isShortVideo) {
    return VideoFeedPlaylistEntrySeeds.shortVideoFromWatchHistory(
      item,
      episodeId: episodeId,
      title: item.title ?? '',
      coverUrl: item.posterUrl,
      description: item.description,
    );
  }
  final dramaId = item.dramaId?.trim() ?? '';
  if (dramaId.isEmpty) return null;
  final episodeNo = switch (item.episodeNo) {
    final value? when value > 0 => value,
    _ => 1,
  };
  return VideoFeedPlaylistEntry.drama(
    dramaId: dramaId,
    episodeId: episodeId,
    episodeNo: episodeNo,
    totalEpisodes: episodeNo,
    title: item.title ?? '',
    coverUrl: item.posterUrl,
    description: item.description,
    likeCount: item.likeCount,
  );
}

Future<void> openWatchHistoryDramaPlaylist(
  BuildContext context,
  WidgetRef ref,
  List<WatchHistoryDrama> items,
  WatchHistoryDrama tapped,
) async {
  final playlist = <VideoFeedPlaylistEntry>[];
  var initialIndex = -1;
  final tappedId = tapped.dramaId?.trim();
  for (final item in items) {
    final entry = watchHistoryDramaPlaylistEntry(item);
    if (entry == null) continue;
    if (item.dramaId?.trim() == tappedId && tappedId != null) {
      initialIndex = playlist.length;
    }
    playlist.add(entry);
  }
  if (initialIndex < 0 || playlist.isEmpty) {
    StoryToast.error(context, context.l10n.playerDramaUnavailable);
    return;
  }

  final seenKeys = {for (final e in playlist) e.playbackKey};
  final continuation = CallbackPlaylistContinuation(
    hasMoreCallback: () => ref.read(watchHistoryDramaControllerProvider).hasMore,
    loadMoreCallback: () => _loadMoreWatchHistoryDramaEntries(ref, seenKeys),
  );

  await VideoFeedNavigation.openPlaylist(
    context,
    playlist: playlist,
    initialIndex: initialIndex,
    continuation: continuation,
  );
  if (!context.mounted) return;
  await ref.read(watchHistoryDramaControllerProvider.notifier).refresh();
}

Future<void> openWatchHistoryVideoPlaylist(
  BuildContext context,
  WidgetRef ref,
  List<WatchHistoryVideo> items,
  WatchHistoryVideo tapped,
) async {
  String? tappedDramaTitle;
  if (!tapped.contentType.isShortVideo) {
    final dramaId = tapped.dramaId?.trim() ?? '';
    if (dramaId.isNotEmpty) {
      final loadingKey = 'watch-history-title:$dramaId';
      if (!StoryLoading.show(context, operationKey: loadingKey)) return;
      try {
        final detailResult = await ref
            .read(dramaRepositoryProvider)
            .getDetail(dramaId, forceRefresh: true);
        final detailTitle = detailResult.dataOrNull?.title?.trim() ?? '';
        if (detailTitle.isNotEmpty) tappedDramaTitle = detailTitle;
      } catch (_) {
      } finally {
        StoryLoading.dismiss(operationKey: loadingKey);
      }
      if (!context.mounted) return;
    }
  }

  final playlist = <VideoFeedPlaylistEntry>[];
  var initialIndex = -1;
  final tappedEpisodeId = tapped.episodeId?.trim();
  for (final item in items) {
    final isTapped =
        item.episodeId?.trim() == tappedEpisodeId && tappedEpisodeId != null;
    var entry = watchHistoryVideoPlaylistEntry(item);
    if (entry == null) continue;
    if (isTapped && tappedDramaTitle != null) {
      entry = VideoFeedPlaylistEntry(
        dramaId: entry.dramaId,
        episodeId: entry.episodeId,
        contentType: entry.contentType,
        episodeNo: entry.episodeNo,
        title: tappedDramaTitle,
        totalEpisodes: entry.totalEpisodes,
        coverUrl: entry.coverUrl,
        description: entry.description,
        expandEpisodes: entry.expandEpisodes,
        creatorName: entry.creatorName,
        creatorUserId: entry.creatorUserId,
        creatorAvatarUrl: entry.creatorAvatarUrl,
        favoritedByMe: entry.favoritedByMe,
        favoriteCount: entry.favoriteCount,
      );
    }
    if (isTapped) {
      initialIndex = playlist.length;
    }
    playlist.add(entry);
  }
  if (initialIndex < 0 || playlist.isEmpty) {
    StoryToast.error(context, context.l10n.playerDramaUnavailable);
    return;
  }

  final seenKeys = {for (final e in playlist) e.playbackKey};
  final continuation = CallbackPlaylistContinuation(
    hasMoreCallback: () => ref.read(watchHistoryVideoControllerProvider).hasMore,
    loadMoreCallback: () => _loadMoreWatchHistoryVideoEntries(ref, seenKeys),
  );

  await VideoFeedNavigation.openPlaylist(
    context,
    playlist: playlist,
    initialIndex: initialIndex,
    continuation: continuation,
  );
  if (!context.mounted) return;
  await ref.read(watchHistoryVideoControllerProvider.notifier).refresh();
}

Future<Result<PlaylistContinuationPage>> _loadMoreWatchHistoryDramaEntries(
  WidgetRef ref,
  Set<String> seenKeys,
) async {
  final provider = watchHistoryDramaControllerProvider;
  final state = ref.read(provider);
  final page = await syncPlaylistContinuation<WatchHistoryDrama>(
    items: state.items,
    hasMore: state.hasMore,
    isPageLoading: state.isPageLoading,
    seenKeys: seenKeys,
    toEntry: watchHistoryDramaPlaylistEntry,
    loadMore: () => ref.read(provider.notifier).loadMore(),
    readItems: () => ref.read(provider).items,
    readHasMore: () => ref.read(provider).hasMore,
    readIsPageLoading: () => ref.read(provider).isPageLoading,
  );
  return Result.success(page);
}

Future<Result<PlaylistContinuationPage>> _loadMoreWatchHistoryVideoEntries(
  WidgetRef ref,
  Set<String> seenKeys,
) async {
  final provider = watchHistoryVideoControllerProvider;
  final state = ref.read(provider);
  final page = await syncPlaylistContinuation<WatchHistoryVideo>(
    items: state.items,
    hasMore: state.hasMore,
    isPageLoading: state.isPageLoading,
    seenKeys: seenKeys,
    toEntry: watchHistoryVideoPlaylistEntry,
    loadMore: () => ref.read(provider.notifier).loadMore(),
    readItems: () => ref.read(provider).items,
    readHasMore: () => ref.read(provider).hasMore,
    readIsPageLoading: () => ref.read(provider).isPageLoading,
  );
  return Result.success(page);
}
