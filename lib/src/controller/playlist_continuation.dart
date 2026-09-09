import '../core/result.dart';
import '../routes/route_args.dart';

/// One page of parent-list entries appended onto an external playback queue.
class PlaylistContinuationPage {
  final List<VideoFeedPlaylistEntry> entries;
  final bool hasMore;

  const PlaylistContinuationPage({
    required this.entries,
    required this.hasMore,
  });
}

/// Parent-owned pagination bridge for [PlaylistFeedPage] / external feeds.
///
/// Named routes cannot carry closures, so parents register an instance in
/// [PlaylistContinuationStore] and pass only [playlistSourceId] via
/// [VideoFeedArgs].
abstract class PlaylistContinuation {
  bool get hasMore;

  /// Loads the parent list's next page and returns **new** playlist entries
  /// (already deduped against what the player already holds).
  Future<Result<PlaylistContinuationPage>> loadMore();
}

/// Process-local lookup table for [PlaylistContinuation] by source id.
///
/// Kept free of Flutter/Riverpod so unit tests can construct an isolated
/// instance; production uses [PlaylistContinuationStore.instance].
class PlaylistContinuationStore {
  PlaylistContinuationStore();

  /// Shared store used by navigation and [PlaylistFeedPage].
  static final PlaylistContinuationStore instance = PlaylistContinuationStore();

  final Map<String, PlaylistContinuation> _entries = {};
  int _seq = 0;

  /// Registers [continuation] and returns an opaque source id.
  String register(PlaylistContinuation continuation) {
    final id = 'pls_${++_seq}';
    _entries[id] = continuation;
    return id;
  }

  PlaylistContinuation? get(String? id) {
    final key = id?.trim() ?? '';
    if (key.isEmpty) return null;
    return _entries[key];
  }

  /// Idempotent removal; safe from both route-pop and page dispose.
  void unregister(String? id) {
    final key = id?.trim() ?? '';
    if (key.isEmpty) return;
    _entries.remove(key);
  }

  /// Test helper — clears all registrations.
  void clear() => _entries.clear();

  int get debugLength => _entries.length;
}

/// Callback-backed continuation used by search / profile / creator adapters.
class CallbackPlaylistContinuation implements PlaylistContinuation {
  CallbackPlaylistContinuation({
    required this.hasMoreCallback,
    required this.loadMoreCallback,
  });

  final bool Function() hasMoreCallback;
  final Future<Result<PlaylistContinuationPage>> Function() loadMoreCallback;

  @override
  bool get hasMore => hasMoreCallback();

  @override
  Future<Result<PlaylistContinuationPage>> loadMore() => loadMoreCallback();
}
