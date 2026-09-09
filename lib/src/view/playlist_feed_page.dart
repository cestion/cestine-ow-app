import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/feed_persist_policy.dart';
import '../controller/playlist_continuation.dart';
import '../controller/playlist_feed_expand.dart';
import '../controller/recommend_feed_controller.dart';
import '../core/result.dart';
import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../routes/route_args.dart';
import '../styles/story_colors.dart';
import '../widgets/widgets.dart';
import 'widgets/recommend/recommend_feed_body.dart';

/// Standalone playlist backed by the recommend feed's three-player runtime.
/// Search/profile playlists get the same finger-tracking and adjacent native
/// preload behavior as the theater recommend tab without sharing its provider
/// state. When [VideoFeedArgs.playlistSourceId] is set, the queue can append
/// pages from the parent list via [PlaylistContinuationStore].
class PlaylistFeedPage extends ConsumerStatefulWidget {
  final VideoFeedArgs feedArgs;

  const PlaylistFeedPage({super.key, required this.feedArgs});

  static const int maxExpandedEpisodes = PlaylistFeedExpand.maxExpandedEpisodes;

  /// 将作品队列扁平化为实际滑动页：短视频/具体剧集各占一页，
  /// 整部短剧按 1...N 展开，并把作品索引换算成扁平后的初始页索引。
  static ({List<RecommendFeedItem> items, int initialIndex}) seedFromArgs(
    VideoFeedArgs args, {
    List<VideoFeedPlaylistEntry>? resolvedPlaylist,
  }) =>
      PlaylistFeedExpand.seedFromArgs(args, resolvedPlaylist: resolvedPlaylist);

  static List<RecommendFeedItem> itemsFromArgs(VideoFeedArgs args) =>
      seedFromArgs(args).items;

  /// 只补齐“整部短剧且总集数未知”的条目；已知集数和具体剧集不增加请求。
  /// 解析失败时保留错误页重试，不能静默降级为只播放第 1 集。
  static Future<Result<List<VideoFeedPlaylistEntry>>> resolveEpisodeCounts(
    List<VideoFeedPlaylistEntry> entries, {
    required Future<Result<int>> Function(String dramaId) loadEpisodeCount,
  }) => PlaylistFeedExpand.resolveEpisodeCounts(
    entries,
    loadEpisodeCount: loadEpisodeCount,
  );

  static bool shouldPersistDramaCursor(VideoFeedArgs args) =>
      FeedPersistPolicy.shouldPersistDramaCursor(args);

  @override
  ConsumerState<PlaylistFeedPage> createState() => _PlaylistFeedPageState();
}

class _PlaylistFeedPageState extends ConsumerState<PlaylistFeedPage> {
  Widget? _scopedFeed;
  ApiError? _prepareError;
  bool _preparing = true;
  String? _registeredSourceId;

  @override
  void initState() {
    super.initState();
    _registeredSourceId = widget.feedArgs.playlistSourceId;
    _preparePlaylist();
  }

  @override
  void dispose() {
    PlaylistContinuationStore.instance.unregister(_registeredSourceId);
    super.dispose();
  }

  Future<Result<int>> _loadEpisodeCount(String dramaId) async {
    final repo = ref.read(dramaRepositoryProvider);
    var detailResult = await repo.getDetail(dramaId);
    var detail = detailResult.dataOrNull;
    var count = detail?.totalEpisodes ?? 0;
    if (detailResult.isSuccess && count < 1) {
      detailResult = await repo.getDetail(dramaId, forceRefresh: true);
      detail = detailResult.dataOrNull;
      count = detail?.totalEpisodes ?? 0;
    }
    final error = detailResult.errorOrNull;
    if (error != null) return Result.failure(error);
    if (count < 1) {
      return Result.failure(ApiError.validation('Invalid total episode count'));
    }
    return Result.success(count);
  }

  Future<void> _preparePlaylist() async {
    if (mounted) {
      setState(() {
        _preparing = true;
        _prepareError = null;
        _scopedFeed = null;
      });
    }
    final result = await PlaylistFeedExpand.resolveEpisodeCounts(
      widget.feedArgs.searchPlaylist,
      loadEpisodeCount: _loadEpisodeCount,
    );
    if (!mounted) return;
    final error = result.errorOrNull;
    if (error != null) {
      setState(() {
        _preparing = false;
        _prepareError = error;
      });
      return;
    }
    final seed = PlaylistFeedExpand.seedFromArgs(
      widget.feedArgs,
      resolvedPlaylist: result.dataOrNull!,
    );
    if (seed.items.isEmpty) {
      setState(() {
        _preparing = false;
        _prepareError = ApiError.validation('Empty playback playlist');
      });
      return;
    }
    final continuation = PlaylistContinuationStore.instance.get(
      widget.feedArgs.playlistSourceId,
    );
    final scopedFeed = ProviderScope(
      overrides: [
        recommendFeedControllerProvider.overrideWith(
          () => RecommendFeedController(
            initialItems: seed.items,
            initialIndex: seed.initialIndex,
            continuation: continuation,
          ),
        ),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: false,
          body: RecommendFeedBody(
            isActive: true,
            standalone: true,
            persistDramaCursor: PlaylistFeedPage.shouldPersistDramaCursor(
              widget.feedArgs,
            ),
          ),
        ),
      ),
    );
    setState(() {
      _preparing = false;
      _scopedFeed = scopedFeed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scopedFeed = _scopedFeed;
    if (scopedFeed != null) return scopedFeed;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: _preparing
                    ? const StoryStateWidget.loading()
                    : StoryStateWidget.error(
                        message:
                            _prepareError == null ||
                                _prepareError is ValidationError
                            ? context.l10n.playerDramaUnavailable
                            : context.l10nError(_prepareError!),
                        actionLabel: context.l10n.commonRetry,
                        onAction: _preparePlaylist,
                      ),
              ),
              Positioned(
                left: 4,
                top: 4,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: StoryColors.onOverlay,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
