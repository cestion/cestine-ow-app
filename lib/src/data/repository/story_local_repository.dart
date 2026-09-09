import 'package:hive/hive.dart';

import '../../model/models.dart';

class LocaleInfo {
  final String languageCode;
  final String? countryCode;
  const LocaleInfo({required this.languageCode, this.countryCode});

  @override
  bool operator ==(Object other) =>
      other is LocaleInfo &&
      other.languageCode == languageCode &&
      other.countryCode == countryCode;

  @override
  int get hashCode => Object.hash(languageCode, countryCode);
}

abstract class StoryLocalRepository {
  Future<void> init();
  Box<dynamic> get cacheBox;

  /// Bind local storage to [apiBaseUrl]. When the host changes (overwrite
  /// install / env switch), purge env-scoped Hive + secure data and keep
  /// only device preferences (locale / theme).
  ///
  /// Returns `true` when a purge ran so callers can also reset Privy, etc.
  Future<bool> reconcileEnv(String apiBaseUrl);

  /// Detect reinstall after uninstall: Hive (sandbox) is wiped but iOS
  /// Keychain / Android backup may still hold JWT + wallet keys.
  ///
  /// When the sandbox has no install marker and is empty, clear secure
  /// session leftovers and stamp the marker. When the sandbox already has
  /// data (app update), only write the marker so existing users stay logged in.
  ///
  /// Returns `true` when secure leftovers were cleared (caller should logout Privy).
  Future<bool> reconcileSandboxInstall();

  String? getToken();
  Future<String?> getTokenAsync();
  Future<void> saveToken(String token);
  Future<void> clearToken();

  /// Synchronous access to an in-memory cached JWT token.
  /// Populated by [getTokenAsync], [saveToken], or eagerly during [init].
  /// Returns `null` if no token has been loaded into memory yet.
  String? get cachedToken;

  UserProfile? getUser();
  Future<void> saveUser(UserProfile user);
  Future<void> clearUser();

  List<String> getWatchlist();
  Future<void> addToWatchlist(String dramaId);
  Future<void> removeFromWatchlist(String dramaId);
  Future<bool> toggleWatchlist(String dramaId);
  bool isFavorite(String dramaId);

  List<String> getSearchHistory();
  Future<void> addSearchHistory(String keyword);
  Future<void> removeSearchHistory(String keyword);
  Future<void> clearSearchHistory();

  int getWatchProgress(String dramaId, int episodeNo);
  Future<void> saveWatchProgress(
    String dramaId,
    int episodeNo,
    int milliseconds,
  );
  Future<void> clearWatchProgress(String dramaId, int episodeNo);

  /// Clears all episodes' watch progress for a given drama.
  /// Call after user finishes or explicitly abandons a drama to keep Hive
  /// from accumulating stale `watch_progress_$dramaId` keys indefinitely.
  Future<void> clearAllWatchProgress(String dramaId);

  String? getSolanaWalletAddress();
  Future<String?> getSolanaWalletAddressAsync();
  Future<void> saveSolanaWalletAddress(String address);
  Future<void> clearSolanaWalletAddress();

  String? getEthereumWalletAddress();
  Future<String?> getEthereumWalletAddressAsync();
  Future<void> saveEthereumWalletAddress(String address);
  Future<void> clearEthereumWalletAddress();

  LocaleInfo? getLocale();
  Future<void> setLocale(LocaleInfo locale);

  String getThemeMode();
  Future<void> setThemeMode(String mode);

  /// 读取「创建短剧」本地草稿；无草稿或解析失败返回 null。
  CreateDramaDraft? getCreateDramaDraft();

  /// 保存「创建短剧」本地草稿（覆盖式）。
  Future<void> saveCreateDramaDraft(CreateDramaDraft draft);

  /// 清除「创建短剧」本地草稿。
  Future<void> clearCreateDramaDraft();

  /// 读取「发布视频」本地草稿；无草稿或解析失败返回 null。
  PublishVideoDraft? getPublishVideoDraft();

  /// 保存「发布视频」本地草稿（覆盖式）。
  Future<void> savePublishVideoDraft(PublishVideoDraft draft);

  /// 清除「发布视频」本地草稿。
  Future<void> clearPublishVideoDraft();

  /// Scan Hive for all watch_progress_* keys and return the embedded drama IDs.
  ///
  /// This avoids maintaining a separate index list — data is already written
  /// by [saveWatchProgress]. Returns drama IDs ordered by most-recently
  /// updated (newest first).
  List<String> getWatchHistoryDramaIds();

  /// Returns the last-watched episode number for [dramaId], or null if none.
  int? getLastWatchedEpisode(String dramaId);

  Future<void> vacuumCache();

  /// Deletes regenerable API cache keys (drama/actor/mining/config/…) and
  /// compact the Hive file. Keeps user data (locale, theme, watchlist,
  /// watch progress, search history, drafts).
  Future<void> purgeApiCache();

  /// Returns the on-disk size of the Hive cache file in bytes.
  /// Used by the settings page to display real cache usage.
  Future<int> getCacheFileSize();

  Future<void> dispose();
}
