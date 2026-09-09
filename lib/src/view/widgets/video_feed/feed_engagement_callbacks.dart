import 'package:flutter/foundation.dart';

/// Unified engagement callbacks for feed interaction actions.
///
/// Bundles like / favorite / comment-posted callbacks so chrome widgets
/// accept a single object instead of three separate parameters.
class FeedEngagementCallbacks {
  final Future<bool> Function() onLike;
  final Future<bool> Function() onFavorite;
  final VoidCallback onCommentPosted;

  const FeedEngagementCallbacks({
    required this.onLike,
    required this.onFavorite,
    required this.onCommentPosted,
  });

  /// No-op instance for neighbor pages or disabled states.
  static const FeedEngagementCallbacks empty = FeedEngagementCallbacks(
    onLike: _noopAsync,
    onFavorite: _noopAsync,
    onCommentPosted: _noop,
  );
}

Future<bool> _noopAsync() async => false;
void _noop() {}
