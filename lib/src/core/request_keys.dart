/// Stable string keys for [RequestCoalescer] / [RequestThrottle] / [Debouncer].
///
/// Format: `{domain}.{resource}.{id?}.{variant?}.{cursor?}`
///
/// See `docs/api_request_policy.md`.
abstract final class RequestKeys {
  static const userProfileForce = 'user.profile.force';

  static String userWorkStats(String userId) => 'user.workStats.$userId';

  static String followStats(String userId) => 'user.follow.stats.$userId';

  static String followRelation(String userId) => 'follow.relation.$userId';

  static const followingsHydrate = 'follow.hydrate';

  /// [typeName] / [contentTypeName] should be stable enum `.name` values.
  static String userProfileDramas({
    required String userId,
    required String typeName,
    required String contentTypeName,
    String? mark,
    int pageSize = 20,
  }) =>
      'user.dramas.$userId.$typeName.$contentTypeName.${mark ?? ''}.$pageSize';

  static String dramaEpisodePrefetch(String cacheKey) =>
      'drama.prefetch.$cacheKey';

  /// First-page episode list only. Load-more must not share this key.
  static String dramaEpisodeListFirst(String dramaId) =>
      'drama.episodes.$dramaId.first';

  static const agentV2Config = 'agent.v2.config';

  static const agentV3Sync = 'agent.v3.sync';

  static const walletOnchainResume = 'wallet.onchain.resume';

  static const walletOnchainRefresh = 'wallet.onchain.refresh';

  static const walletOnchainRefreshSilent = 'wallet.onchain.refresh.silent';

  static const globalConfigResume = 'config.global.resume';

  /// Per list-tab silent revalidate gate (use enum `.name`, e.g. `likes`).
  static String profileTabRevalidate(String kindName) =>
      'profile.tab.revalidate.$kindName';

  static const searchQuery = 'search.query';

  static const draftAutosave = 'draft.autosave';

  static const watchHistoryFlush = 'watch.history.flush';
}
