import 'package:flutter/material.dart';

import '../controller/playlist_continuation.dart';
import '../model/work_content_type.dart';
import '../foundation/navigator.dart';
import 'route_names.dart';
import 'route_args.dart';

/// Tracks open [VideoFeedPage] routes and opens the player by popping back
/// when the same drama is already on the stack (avoids Player → Detail → Player).
class VideoFeedNavigation {
  VideoFeedNavigation._();

  static final Set<String> _openPlaybackKeys = <String>{};
  static String? _pendingPlaybackKey;
  static int? _pendingEpisodeNo;

  static String _dramaPlaybackKey(String dramaId) =>
      '${WorkContentType.shortDrama.apiValue}:${dramaId.trim()}';

  static void register(VideoFeedArgs args) {
    final key = args.playbackKey;
    if (key.isEmpty) return;
    _openPlaybackKeys.add(key);
  }

  static void unregister(VideoFeedArgs args) {
    _openPlaybackKeys.remove(args.playbackKey);
  }

  /// Backwards-compatible drama lookup used by drama-detail navigation.
  static bool isOpen(String dramaId) =>
      _openPlaybackKeys.contains(_dramaPlaybackKey(dramaId));

  /// Pending episode to activate after [popUntil] reveals an existing player.
  static ({String playbackKey, int episodeNo})? takePendingResume() {
    final key = _pendingPlaybackKey;
    final ep = _pendingEpisodeNo;
    _pendingPlaybackKey = null;
    _pendingEpisodeNo = null;
    if (key == null || ep == null) return null;
    return (playbackKey: key, episodeNo: ep);
  }

  static String? _playbackKeyFromArgs(Object? arguments) {
    if (arguments is Map) {
      final args = VideoFeedArgs.fromMap(Map<String, dynamic>.from(arguments));
      return args.playbackKey.isEmpty ? null : args.playbackKey;
    }
    return null;
  }

  static bool _isPlayerForKey(Route<dynamic> route, String playbackKey) {
    if (route.settings.name?.split('?').first != RouteNames.player) {
      return false;
    }
    return _playbackKeyFromArgs(route.settings.arguments) == playbackKey;
  }

  /// Open the video feed for [dramaId], or pop back to an existing feed page.
  static Future<T?> open<T extends Object?>(
    BuildContext context, {
    required String dramaId,
    required int episodeNo,
    String title = '',
    int totalEpisodes = 1,
    String? coverUrl,
    String? episodeCoverUrl,
    String? description,
    String? creatorName,
    String? creatorUserId,
    String? creatorAvatarUrl,
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
    bool? followedByMe,
    bool fromDramaDetail = false,
    bool warmStart = false,
    List<VideoFeedPlaylistEntry> searchPlaylist = const [],
    int searchPlaylistIndex = 0,
    bool searchDramaPlaylist = false,
    VideoFeedPlaylistEntry? chrome,
  }) async {
    if (dramaId.isEmpty) return null;

    final c = chrome;
    final args = VideoFeedArgs(
      dramaId: dramaId,
      episodeNo: episodeNo,
      title: title,
      totalEpisodes: totalEpisodes,
      coverUrl: coverUrl,
      episodeCoverUrl: episodeCoverUrl,
      description: description,
      creatorName: creatorName ?? c?.creatorName,
      creatorUserId: creatorUserId ?? c?.creatorUserId,
      creatorAvatarUrl: creatorAvatarUrl ?? c?.creatorAvatarUrl,
      likedByMe: likedByMe ?? c?.likedByMe,
      likeCount: likeCount ?? c?.likeCount,
      commentCount: commentCount ?? c?.commentCount,
      favoritedByMe: favoritedByMe ?? c?.favoritedByMe,
      favoriteCount: favoriteCount ?? c?.favoriteCount,
      followedByMe: followedByMe ?? c?.followedByMe,
      actors: c?.actors,
      roles: c?.roles,
      fromDramaDetail: fromDramaDetail,
      warmStart: warmStart,
      searchPlaylist: searchPlaylist,
      searchPlaylistIndex: searchPlaylistIndex,
      searchDramaPlaylist: searchDramaPlaylist,
    );
    return _open<T>(context, args);
  }

  /// Open a standalone short video identified only by [episodeId].
  static Future<T?> openShortVideo<T extends Object?>(
    BuildContext context, {
    required String episodeId,
    String title = '',
    String? coverUrl,
    String? description,
    String? creatorName,
    String? creatorUserId,
    String? creatorAvatarUrl,
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
    bool? followedByMe,
    List<VideoFeedPlaylistEntry> playlist = const [],
    int playlistIndex = 0,
    VideoFeedPlaylistEntry? chrome,
  }) {
    final id = episodeId.trim();
    if (id.isEmpty) return Future<T?>.value();
    final c = chrome;
    return _open<T>(
      context,
      VideoFeedArgs(
        dramaId: '',
        episodeId: id,
        contentType: WorkContentType.shortVideo,
        episodeNo: 1,
        title: title,
        coverUrl: coverUrl,
        description: description,
        creatorName: creatorName ?? c?.creatorName,
        creatorUserId: creatorUserId ?? c?.creatorUserId,
        creatorAvatarUrl: creatorAvatarUrl ?? c?.creatorAvatarUrl,
        likedByMe: likedByMe ?? c?.likedByMe,
        likeCount: likeCount ?? c?.likeCount,
        commentCount: commentCount ?? c?.commentCount,
        favoritedByMe: favoritedByMe ?? c?.favoritedByMe,
        favoriteCount: favoriteCount ?? c?.favoriteCount,
        followedByMe: followedByMe ?? c?.followedByMe,
        actors: c?.actors,
        roles: c?.roles,
        searchPlaylist: playlist,
        searchPlaylistIndex: playlistIndex,
      ),
    );
  }

  /// Open a continuous queue containing any mix of short dramas and
  /// standalone short videos. The queue loops after its final target when
  /// there is no [continuation] (or parent [hasMore] becomes false).
  static Future<T?> openPlaylist<T extends Object?>(
    BuildContext context, {
    required List<VideoFeedPlaylistEntry> playlist,
    int initialIndex = 0,
    bool searchDramaPlaylist = false,
    PlaylistContinuation? continuation,
    PlaylistContinuationStore? continuationStore,
  }) async {
    if (playlist.isEmpty ||
        initialIndex < 0 ||
        initialIndex >= playlist.length) {
      return null;
    }
    final tapped = playlist[initialIndex];
    if (!tapped.isValid) return null;
    final filtered = <VideoFeedPlaylistEntry>[];
    var mappedIndex = 0;
    for (var i = 0; i < playlist.length; i++) {
      final entry = playlist[i];
      if (!entry.isValid) continue;
      if (i == initialIndex) mappedIndex = filtered.length;
      filtered.add(entry);
    }
    final store = continuationStore ?? PlaylistContinuationStore.instance;
    String? sourceId;
    if (continuation != null) {
      sourceId = store.register(continuation);
    }
    final args = tapped.toFeedArgs(
      playlist: filtered,
      playlistIndex: mappedIndex,
      searchDramaPlaylist: searchDramaPlaylist,
      playlistSourceId: sourceId,
    );
    try {
      return await _open<T>(context, args);
    } finally {
      store.unregister(sourceId);
    }
  }

  static Future<T?> _open<T extends Object?>(
    BuildContext context,
    VideoFeedArgs args,
  ) async {
    final playbackKey = args.playbackKey;
    if (playbackKey.isEmpty) return null;

    // Search playlist replaces the current feed route — do not pop-until.
    if (args.searchPlaylist.isEmpty &&
        _openPlaybackKeys.contains(playbackKey)) {
      _pendingPlaybackKey = playbackKey;
      _pendingEpisodeNo = args.episodeNo;
      Navigator.of(context).popUntil(
        (route) => route.isFirst || _isPlayerForKey(route, playbackKey),
      );
      return null;
    }

    return context.storyPushForResult<T>(
      RouteNames.player,
      arguments: args.toMap(),
    );
  }
}
