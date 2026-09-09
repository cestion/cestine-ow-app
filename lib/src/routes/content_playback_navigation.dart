import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/common/story_toast.dart';
import '../core/result.dart';
import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../widgets/story_loading.dart';
import 'route_args.dart';
import 'video_feed_playlist_entry_seeds.dart';
import 'video_feed_navigation.dart';

/// Resolves a drama or standalone-video id into a validated player route.
///
/// Exactly one of [dramaId] and [videoId] must be supplied. Public detail
/// endpoints are used deliberately. Drama navigation checks the status from
/// its detail endpoint; standalone-video navigation requires a successful
/// public detail response with playable media.
class ContentPlaybackNavigation {
  ContentPlaybackNavigation._();

  static Future<bool> open({
    required BuildContext context,
    required WidgetRef ref,
    String? dramaId,
    String? videoId,
    int? episodeNo,
    String? title,
    String? coverUrl,
    String? description,
    String? creatorName,
    String? creatorUserId,
    String? creatorAvatarUrl,
    VideoFeedPlaylistEntry? chrome,
    String? unavailableMessage,
    String? notFoundMessage,
    bool showLoading = true,
    List<VideoFeedPlaylistEntry> playlist = const [],
    int playlistIndex = 0,
  }) async {
    final normalizedDramaId = dramaId?.trim() ?? '';
    final normalizedVideoId = videoId?.trim() ?? '';
    if (normalizedDramaId.isEmpty == normalizedVideoId.isEmpty) {
      _showUnavailable(context);
      return false;
    }

    final operationKey = normalizedDramaId.isNotEmpty
        ? 'content-playback:drama:$normalizedDramaId'
        : 'content-playback:video:$normalizedVideoId';
    final loadingShown = showLoading
        ? StoryLoading.show(context, operationKey: operationKey)
        : false;
    if (showLoading && !loadingShown) return false;

    try {
      return normalizedDramaId.isNotEmpty
          ? await _openDrama(
              context,
              ref,
              dramaId: normalizedDramaId,
              requestedEpisodeNo: episodeNo,
              title: title,
              coverUrl: coverUrl,
              description: description,
              creatorName: creatorName,
              creatorUserId: creatorUserId,
              creatorAvatarUrl: creatorAvatarUrl,
              chrome: chrome,
              unavailableMessage: unavailableMessage,
              notFoundMessage: notFoundMessage,
            )
          : await _openVideo(
              context,
              ref,
              videoId: normalizedVideoId,
              title: title,
              coverUrl: coverUrl,
              description: description,
              creatorName: creatorName,
              creatorUserId: creatorUserId,
              creatorAvatarUrl: creatorAvatarUrl,
              chrome: chrome,
              unavailableMessage: unavailableMessage,
              notFoundMessage: notFoundMessage,
              playlist: playlist,
              playlistIndex: playlistIndex,
            );
    } finally {
      if (loadingShown) {
        StoryLoading.dismiss(operationKey: operationKey);
      }
    }
  }

  static Future<bool> openDrama({
    required BuildContext context,
    required WidgetRef ref,
    required String dramaId,
    int? episodeNo,
    String? title,
    String? coverUrl,
    String? description,
    String? creatorName,
    String? creatorUserId,
    String? creatorAvatarUrl,
    VideoFeedPlaylistEntry? chrome,
    String? unavailableMessage,
    String? notFoundMessage,
    bool showLoading = true,
  }) => open(
    context: context,
    ref: ref,
    dramaId: dramaId,
    episodeNo: episodeNo,
    title: title,
    coverUrl: coverUrl,
    description: description,
    creatorName: creatorName,
    creatorUserId: creatorUserId,
    creatorAvatarUrl: creatorAvatarUrl,
    chrome: chrome,
    unavailableMessage: unavailableMessage,
    notFoundMessage: notFoundMessage,
    showLoading: showLoading,
  );

  static Future<bool> openVideo({
    required BuildContext context,
    required WidgetRef ref,
    required String videoId,
    String? title,
    String? coverUrl,
    String? description,
    String? creatorName,
    String? creatorUserId,
    String? creatorAvatarUrl,
    VideoFeedPlaylistEntry? chrome,
    String? unavailableMessage,
    String? notFoundMessage,
    bool showLoading = true,
    List<VideoFeedPlaylistEntry> playlist = const [],
    int playlistIndex = 0,
  }) => open(
    context: context,
    ref: ref,
    videoId: videoId,
    title: title,
    coverUrl: coverUrl,
    description: description,
    creatorName: creatorName,
    creatorUserId: creatorUserId,
    creatorAvatarUrl: creatorAvatarUrl,
    chrome: chrome,
    unavailableMessage: unavailableMessage,
    notFoundMessage: notFoundMessage,
    showLoading: showLoading,
    playlist: playlist,
    playlistIndex: playlistIndex,
  );

  static Future<bool> _openDrama(
    BuildContext context,
    WidgetRef ref, {
    required String dramaId,
    int? requestedEpisodeNo,
    String? title,
    String? coverUrl,
    String? description,
    String? creatorName,
    String? creatorUserId,
    String? creatorAvatarUrl,
    VideoFeedPlaylistEntry? chrome,
    String? unavailableMessage,
    String? notFoundMessage,
  }) async {
    final repository = ref.read(dramaRepositoryProvider);
    final detailResult = await repository.getDetail(
      dramaId,
      forceRefresh: true,
    );
    if (!context.mounted) return false;
    final detail = detailResult.dataOrNull;
    if (detail == null) {
      _showDetailFailure(
        context,
        detailResult.errorOrNull,
        unavailableMessage: unavailableMessage,
        notFoundMessage: notFoundMessage,
      );
      return false;
    }

    final totalEpisodes = detail.totalEpisodes ?? 0;
    if (_isExplicitlyUnavailable(detail.status) || totalEpisodes < 1) {
      _showUnavailable(context, unavailableMessage);
      return false;
    }

    final targetEpisodeNo = (requestedEpisodeNo ?? 1).clamp(1, totalEpisodes);
    final playResult = await repository.getEpisodeDetail(
      dramaId,
      targetEpisodeNo,
      forceRefresh: true,
    );
    if (!context.mounted) return false;
    final play = playResult.dataOrNull;
    if (play == null) {
      _showDetailFailure(
        context,
        playResult.errorOrNull,
        unavailableMessage: unavailableMessage,
        notFoundMessage: notFoundMessage,
      );
      return false;
    }
    if (play.effectivePlayUrl == null) {
      _showUnavailable(context, unavailableMessage);
      return false;
    }

    // Prefer detail metadata, but keep list-card seeds so the player can show
    // a poster on the first frame when the detail payload omits cover/title.
    final seedTitle = title?.trim() ?? '';
    final seedCover = coverUrl?.trim() ?? '';
    final seedDesc = description?.trim() ?? '';
    final detailTitle = detail.title?.trim() ?? '';
    final detailCover = detail.coverUrl?.trim() ?? '';
    final detailDesc = detail.description?.trim() ?? '';
    final mergedChrome =
        mergePlaybackChrome(
              creatorName: creatorName,
              creatorUserId: creatorUserId,
              creatorAvatarUrl: creatorAvatarUrl,
              chrome: chrome,
            )
            .mergeChrome(
              VideoFeedPlaylistEntrySeeds.fromDramaDetail(
                detail,
                dramaId: dramaId,
              ),
            )
            .mergePlay(play);

    unawaited(
      VideoFeedNavigation.open<void>(
        context,
        dramaId: dramaId,
        episodeNo: targetEpisodeNo,
        title: detailTitle.isNotEmpty ? detailTitle : seedTitle,
        totalEpisodes: totalEpisodes,
        coverUrl: detailCover.isNotEmpty ? detailCover : seedCover,
        episodeCoverUrl: play.posterUrl?.trim().isNotEmpty == true
            ? play.posterUrl
            : (seedCover.isNotEmpty ? seedCover : null),
        description: detailDesc.isNotEmpty ? detailDesc : seedDesc,
        chrome: mergedChrome,
      ),
    );
    return true;
  }

  static Future<bool> _openVideo(
    BuildContext context,
    WidgetRef ref, {
    required String videoId,
    String? title,
    String? coverUrl,
    String? description,
    String? creatorName,
    String? creatorUserId,
    String? creatorAvatarUrl,
    VideoFeedPlaylistEntry? chrome,
    String? unavailableMessage,
    String? notFoundMessage,
    List<VideoFeedPlaylistEntry> playlist = const [],
    int playlistIndex = 0,
  }) async {
    final result = await ref
        .read(dramaRepositoryProvider)
        .getEpisodeDetailByEpisodeId(videoId);
    if (!context.mounted) return false;
    final play = result.dataOrNull;
    if (play == null) {
      _showDetailFailure(
        context,
        result.errorOrNull,
        unavailableMessage: unavailableMessage,
        notFoundMessage: notFoundMessage,
      );
      return false;
    }
    if (play.effectivePlayUrl == null) {
      _showUnavailable(context, unavailableMessage);
      return false;
    }

    // Prefer caller-seeded creator chrome (e.g. creator management). Fall back
    // to play.userId only when the caller did not provide one.
    final mergedChrome = mergePlaybackChrome(
      creatorName: creatorName,
      creatorUserId: creatorUserId,
      creatorAvatarUrl: creatorAvatarUrl,
      chrome: chrome,
    ).mergePlay(play);

    unawaited(
      VideoFeedNavigation.openShortVideo<void>(
        context,
        episodeId: videoId,
        title: title ?? '',
        coverUrl: play.posterUrl?.trim().isNotEmpty == true
            ? play.posterUrl
            : coverUrl,
        description: description,
        chrome: mergedChrome,
        playlist: playlist,
        playlistIndex: playlistIndex,
      ),
    );
    return true;
  }

  static bool _isExplicitlyUnavailable(String? status) {
    final normalized = status?.trim().toUpperCase() ?? '';
    return normalized.isNotEmpty && normalized != 'ONLINE';
  }

  static void _showDetailFailure(
    BuildContext context,
    ApiError? error, {
    String? unavailableMessage,
    String? notFoundMessage,
  }) {
    if (error is NotFoundError) {
      _showUnavailable(context, notFoundMessage ?? unavailableMessage);
      return;
    }
    if (error == null || error is BusinessError || error is ForbiddenError) {
      _showUnavailable(context, unavailableMessage);
      return;
    }
    StoryToast.error(context, context.l10nError(error));
  }

  static void _showUnavailable(BuildContext context, [String? message]) {
    StoryToast.error(context, message ?? context.l10n.playerContentUnavailable);
  }
}
