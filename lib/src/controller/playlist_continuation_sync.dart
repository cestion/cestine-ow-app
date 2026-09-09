import '../routes/route_args.dart';
import 'playlist_continuation.dart';

/// Collects playlist entries from [items] that are not yet in [seenKeys].
///
/// Mutates [seenKeys] as entries are accepted so callers can reuse the same
/// set across sync + subsequent pages.
List<VideoFeedPlaylistEntry> collectUnseenPlaylistEntries<T>({
  required Iterable<T> items,
  required Set<String> seenKeys,
  required VideoFeedPlaylistEntry? Function(T item) toEntry,
}) {
  final entries = <VideoFeedPlaylistEntry>[];
  for (final item in items) {
    final entry = toEntry(item);
    if (entry == null) continue;
    if (!seenKeys.add(entry.playbackKey)) continue;
    entries.add(entry);
  }
  return entries;
}

/// Default poll interval while waiting for an in-flight parent `loadMore`.
const Duration kPlaylistContinuationPollInterval = Duration(milliseconds: 50);

/// Default cap for waiting on parent `isPageLoading`.
const Duration kPlaylistContinuationLoadingTimeout = Duration(seconds: 3);

/// Syncs the player queue against the parent list, optionally triggering
/// parent pagination when there is nothing new yet.
///
/// Semantics:
/// 1. Diff the full parent [items] against [seenKeys] (not only the latest
///    `loadMore` tail) so rows appended while the player was open are not
///    skipped.
/// 2. If the diff is empty and the parent still reports [hasMore], wait for
///    an in-flight page load or call [loadMore], then diff again.
/// 3. If still empty, return `hasMore: false` so the player can loop instead
///    of sticking at the tail with `hasMore: true` and empty appends.
Future<PlaylistContinuationPage> syncPlaylistContinuation<T>({
  required List<T> items,
  required bool hasMore,
  required bool isPageLoading,
  required Set<String> seenKeys,
  required VideoFeedPlaylistEntry? Function(T item) toEntry,
  required Future<void> Function() loadMore,
  required List<T> Function() readItems,
  required bool Function() readHasMore,
  required bool Function() readIsPageLoading,
  Duration pollInterval = kPlaylistContinuationPollInterval,
  Duration loadingTimeout = kPlaylistContinuationLoadingTimeout,
}) async {
  var entries = collectUnseenPlaylistEntries(
    items: items,
    seenKeys: seenKeys,
    toEntry: toEntry,
  );
  if (entries.isNotEmpty) {
    return PlaylistContinuationPage(entries: entries, hasMore: hasMore);
  }
  if (!hasMore) {
    return const PlaylistContinuationPage(entries: [], hasMore: false);
  }

  if (isPageLoading) {
    await waitUntilPlaylistParentIdle(
      isPageLoading: readIsPageLoading,
      pollInterval: pollInterval,
      timeout: loadingTimeout,
    );
  } else {
    await loadMore();
  }

  entries = collectUnseenPlaylistEntries(
    items: readItems(),
    seenKeys: seenKeys,
    toEntry: toEntry,
  );
  if (entries.isEmpty) {
    return const PlaylistContinuationPage(entries: [], hasMore: false);
  }
  return PlaylistContinuationPage(entries: entries, hasMore: readHasMore());
}

/// Polls until [isPageLoading] is false or [timeout] elapses.
Future<void> waitUntilPlaylistParentIdle({
  required bool Function() isPageLoading,
  Duration pollInterval = kPlaylistContinuationPollInterval,
  Duration timeout = kPlaylistContinuationLoadingTimeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (isPageLoading()) {
    if (!DateTime.now().isBefore(deadline)) break;
    await Future<void>.delayed(pollInterval);
  }
}
