import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/models.dart';
import '../provider/app_providers.dart';
import 'engagement_state.dart';

/// Two-phase hydration of the shared engagement stores for one episode.
///
/// Phase 1 — instant local sync: seed the stores from whatever is already on
/// device (prefetched play payload, loaded drama detail) without touching the
/// network, so UI renders immediately. `seed` only fills missing fields, so a
/// live optimistic value is never clobbered.
///
/// Phase 2 — authoritative refresh: bypass the 24h episode-play cache and
/// overwrite the stores with fresh server data (`applyServer`).
///
/// Series favorite comes from [DramaDetail.favoritedByMe].
/// [DramaPlayResponse.favoritedByMe] is **episode/work-scoped** (player rail)
/// and lands on [episodeEngagementProvider].
class EngagementHydrator {
  EngagementHydrator(this._ref);

  final Ref _ref;

  Future<void> hydrateEpisode({
    required String dramaId,
    required int episodeNo,
    void Function(String episodeId)? onEpisodeResolved,
  }) async {
    final repo = _ref.read(dramaRepositoryProvider);

    // Phase 1 — local-only peek.
    final cached = await repo.peekPrefetchedEpisode(dramaId, episodeNo);
    if (cached?.episodeId != null) {
      _seed(dramaId, episodeNo, cached!);
      onEpisodeResolved?.call(cached.episodeId!);
    }

    // Phase 2 — authoritative refresh.
    final result = await repo.getEpisodeDetail(
      dramaId,
      episodeNo,
      forceRefresh: true,
    );
    final data = result.dataOrNull;
    if (result.isSuccess && data?.episodeId != null) {
      _applyServer(dramaId, episodeNo, data!);
      onEpisodeResolved?.call(data.episodeId!);
    }
  }

  void _seed(String dramaId, int episodeNo, DramaPlayResponse data) {
    final detail = _ref
        .read(dramaDetailProvider(dramaId))
        .asData
        ?.value
        .dataOrNull;
    // Series favorite / counts / rating from cached detail when present.
    // [DramaPlayResponse.favoritedByMe] is episode/work-scoped — do not map it here.
    _ref
        .read(dramaEngagementProvider(dramaId).notifier)
        .seed(
          favoritedByMe: detail?.favoritedByMe,
          favoriteCount: detail?.favoriteCount,
          avgRating: detail?.avgRating,
        );
    _ref
        .read(
          episodeEngagementProvider(
            EpisodeEngagementKey.forEpisode(
              dramaId: dramaId,
              episodeId: data.episodeId!,
              episodeNo: episodeNo,
            ),
          ).notifier,
        )
        .seed(
          likedByMe: data.likedByMe,
          likeCount: data.likeCount,
          commentCount: data.commentCount,
          favoritedByMe: data.favoritedByMe,
          favoriteCount: data.favoriteCount,
        );
  }

  void _applyServer(String dramaId, int episodeNo, DramaPlayResponse data) {
    _ref
        .read(
          episodeEngagementProvider(
            EpisodeEngagementKey.forEpisode(
              dramaId: dramaId,
              episodeId: data.episodeId!,
              episodeNo: episodeNo,
            ),
          ).notifier,
        )
        .applyServer(
          likedByMe: data.likedByMe ?? false,
          likeCount: data.likeCount ?? 0,
          commentCount: data.commentCount ?? 0,
          favoritedByMe: data.favoritedByMe ?? false,
          favoriteCount: data.favoriteCount ?? 0,
        );
  }
}
