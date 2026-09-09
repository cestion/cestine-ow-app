import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controller/recommend_feed_controller.dart';
import '../../../core/episode_play_handoff.dart';
import '../../../core/story_constants.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/video_feed_playlist_entry_seeds.dart';
import '../../../routes/video_feed_navigation.dart';
import '../../../widgets/widgets.dart';
import '../drama_detail/drama_detail_sheet.dart';

/// Navigation and bottom sheet helpers for the RecommendFeed.
class RecommendFeedSheets {
  RecommendFeedSheets._();

  /// Shows the full drama detail bottom sheet (synopsis, cast, reviews, etc.).
  static Future<int?> showDramaDetailSheet({
    required BuildContext context,
    required WidgetRef ref,
    required RecommendFeedItem item,
    DramaDetail? detail,
    required DramaDetailSheetTab tab,
    required VoidCallback onSyncLooping,
    required ValueNotifier<bool> playerSheetOpen,
    ValueNotifier<double>? playerSheetHeight,
  }) async {
    if (playerSheetHeight != null) {
      playerSheetHeight.value = StoryConstants.playerOverlaySheetHeight;
    }
    playerSheetOpen.value = true;
    try {
      final ctrl = ref.read(recommendFeedControllerProvider.notifier);
      final selected = await ctrl.holdAutoAdvance(() async {
        onSyncLooping();
        if (!context.mounted) return null;
        final play = ref.read(recommendFeedControllerProvider).currentPlay;
        return DramaDetailSheet.show(
          context: context,
          dramaId: item.dramaId,
          coverUrl: detail?.coverUrl ?? item.posterUrl,
          initialTab: tab,
          episodeNo: play?.episodeNo ?? item.episodeNo,
          episodeId: play?.episodeId,
          contentType: item.workType,
          sheetHeightNotifier: playerSheetHeight,
        );
      });
      if (!context.mounted) return null;
      onSyncLooping();
      // The sheet posts comments and force-refreshes counts straight into the
      // engagement stores; fold them back into the card before it rebuilds.
      ctrl.syncEngagementFromStores();
      return selected;
    } finally {
      playerSheetOpen.value = false;
    }
  }

  /// Opens the drama player or short video player for the given recommend feed item.
  static Future<void> openFullDrama({
    required BuildContext context,
    required WidgetRef ref,
    required RecommendFeedItem item,
    DramaDetail? detail,
    int? episodeNo,
  }) async {
    if (item.workType.isShortVideo) {
      final episodeId = item.episodeId?.trim() ?? '';
      if (episodeId.isEmpty) return;
      if (!context.mounted) return;
      final chrome = VideoFeedPlaylistEntrySeeds.fromRecommendFeedItem(
        item,
        detail: detail,
      );
      await VideoFeedNavigation.openShortVideo(
        context,
        episodeId: episodeId,
        title: detail?.title ?? item.title ?? '',
        coverUrl: item.posterUrl ?? detail?.coverUrl,
        description: detail?.description ?? item.description,
        chrome: chrome,
      );
      return;
    }

    final dramaId = item.dramaId;
    if (dramaId.isEmpty) return;
    final epNo = (episodeNo != null && episodeNo >= 1)
        ? episodeNo
        : (item.episodeNo != null && item.episodeNo! >= 1)
        ? item.episodeNo!
        : 1;

    var warmStart = false;
    DramaPlayResponse? cachedPlay;
    try {
      cachedPlay = await ref
          .read(dramaRepositoryProvider)
          .peekPrefetchedEpisode(dramaId, epNo);
      cachedPlay ??= _recommendPlayHandoff(
        ref: ref,
        item: item,
        dramaId: dramaId,
        episodeNo: epNo,
      );
      if (cachedPlay != null) {
        EpisodePlayHandoff.offer(
          dramaId: dramaId,
          episodeNo: epNo,
          play: cachedPlay,
        );
        warmStart = true;
      }
    } catch (_) {}

    if (!context.mounted) return;
    final chrome = VideoFeedPlaylistEntrySeeds.fromRecommendFeedItem(
      item,
      detail: detail,
      dramaId: dramaId,
      episodeNo: epNo,
    ).mergePlay(cachedPlay);
    await VideoFeedNavigation.open(
      context,
      dramaId: dramaId,
      episodeNo: epNo,
      title: detail?.title ?? item.title ?? '',
      totalEpisodes: detail?.totalEpisodes ?? item.totalEpisodes ?? 1,
      coverUrl: detail?.coverUrl ?? item.coverUrl,
      description: detail?.description ?? item.description,
      warmStart: warmStart,
      chrome: chrome,
    );
  }

  /// Re-use the recommend card's resolved play when opening the same episode
  /// in the full-screen feed (avoids a cold miss on poisoned Hive cache).
  static DramaPlayResponse? _recommendPlayHandoff({
    required WidgetRef ref,
    required RecommendFeedItem item,
    required String dramaId,
    required int episodeNo,
  }) {
    final feed = ref.read(recommendFeedControllerProvider);
    if (feed.currentItem?.playbackId != item.playbackId) return null;
    final play = feed.currentPlay;
    if (play == null) return null;
    final url = play.effectivePlayUrl;
    if (url == null || url.isEmpty) return null;
    if ((play.episodeNo ?? item.resolvedEpisodeNo) != episodeNo) return null;
    if ((play.dramaId ?? item.dramaId).trim() != dramaId) return null;
    return play;
  }

  /// Shows the standalone episode picker sheet (e.g. for playlist feed).
  static Future<int?> showStandaloneEpisodePicker({
    required BuildContext context,
    required WidgetRef ref,
    required RecommendFeedItem item,
    DramaDetail? detail,
    required VoidCallback onSyncLooping,
  }) async {
    final ctrl = ref.read(recommendFeedControllerProvider.notifier);
    final selected = await ctrl.holdAutoAdvance(() async {
      onSyncLooping();
      if (!context.mounted) return null;
      return EpisodePickerSheet.show(
        context: context,
        dramaId: item.dramaId,
        totalEpisodes: detail?.totalEpisodes ?? item.totalEpisodes ?? 1,
        currentEpisode: item.resolvedEpisodeNo,
        fallbackCoverUrl: detail?.coverUrl ?? item.coverUrl,
      );
    });
    if (!context.mounted) return null;
    onSyncLooping();
    return selected;
  }
}
