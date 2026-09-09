import '../routes/route_args.dart';

/// Shared rules for whether playback should update the continue-watching cursor.
abstract final class FeedPersistPolicy {
  FeedPersistPolicy._();

  /// Theater / works / detail resume cursor. Search drama playlist skips this
  /// so opening from search at ep 1 does not overwrite a prior theater position.
  static bool shouldPersistDramaCursor(VideoFeedArgs args) =>
      !args.isShortVideo && !args.searchDramaPlaylist;
}
